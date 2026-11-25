@isTest
private class CreditDebitNoteServiceTest {

    @testSetup
    static void setup() {
        Account acc = new Account(Name = 'Note Test Customer');
        insert acc;
        Opportunity opp = new Opportunity(Name = 'Note Test Opp', StageName = 'Prospecting', CloseDate = System.today().addDays(30), AccountId = acc.Id);
        insert opp;
        insert new List<Payment_Schedule__c>{
            new Payment_Schedule__c(Opportunity__c = opp.Id, Name = 'Instalment 1', Agreement_Value__c = 100000, Tax_Amount__c = 5000, Installment_Sequence__c = 1, Total_Received_Amount__c = 0),
            new Payment_Schedule__c(Opportunity__c = opp.Id, Name = 'Instalment 2', Agreement_Value__c = 100000, Tax_Amount__c = 5000, Installment_Sequence__c = 2, Total_Received_Amount__c = 0)
        };
        insert new List<Tax_Master__c>{
            new Tax_Master__c(Name = 'CGST-9', Short_Name__c = 'CGST-9', Tax_Type__c = 'CGST', Tax__c = 9, Taxable__c = 100, Active__c = true),
            new Tax_Master__c(Name = 'SGST-9', Short_Name__c = 'SGST-9', Tax_Type__c = 'SGST', Tax__c = 9, Taxable__c = 100, Active__c = true)
        };
        insert new Pricing_Element_Master__c(Name = 'Club House');
    }

    private static Opportunity opp() {
        return [SELECT Id, AccountId FROM Opportunity WHERE Name = 'Note Test Opp' LIMIT 1];
    }

    private static Receipt__c newNote(String type, Decimal amount, Boolean withGst) {
        Receipt__c r = new Receipt__c(
            Opportunity__c = opp().Id,
            Type__c = type,
            Amount__c = amount,
            Approval_Status__c = 'Sent',
            Pricing_Element_Master__c = [SELECT Id FROM Pricing_Element_Master__c LIMIT 1].Id
        );
        if (withGst) {
            r.Tax_Master_CGST__c = [SELECT Id FROM Tax_Master__c WHERE Tax_Type__c = 'CGST' LIMIT 1].Id;
            r.Tax_Master_SGST__c = [SELECT Id FROM Tax_Master__c WHERE Tax_Type__c = 'SGST' LIMIT 1].Id;
            r.Tax_Invoice_Included__c = (type == 'Credit');
        }
        insert r;
        return r;
    }

    private static void approve(Receipt__c r) {
        update new Receipt__c(Id = r.Id, Approval_Status__c = 'Approved');
    }

    // ---- point 7: debit note approval creates its payment schedule line and its GST / tax invoice
    @isTest
    static void debitApprovalCreatesScheduleAndTaxInvoice() {
        Receipt__c debit = newNote('Debit', 10000, true);
        Test.startTest();
        approve(debit);
        Test.stopTest();

        Payment_Schedule__c ps = [SELECT Id, Debit_Note__c, Agreement_Value__c, Tax_Amount__c, Tax_Invoice_Created__c FROM Payment_Schedule__c WHERE Debit_Payment_Schedule__c = true];
        System.assertEquals(debit.Id, ps.Debit_Note__c);
        System.assertEquals(10000, ps.Agreement_Value__c);
        System.assertEquals(1800, ps.Tax_Amount__c);
        List<Tax_Invoice__c> inv = [SELECT Receipt__c, Payment_Schedule__c, Received_Amount__c, CGST__c, SGST__c FROM Tax_Invoice__c];
        System.assertEquals(1, inv.size(), 'one tax invoice on debit note approval');
        System.assertEquals(ps.Id, inv[0].Payment_Schedule__c);
        System.assertEquals(11800, inv[0].Received_Amount__c);
        System.assertEquals(900, inv[0].CGST__c);
        System.assertEquals(900, inv[0].SGST__c);
    }

    // ---- point 7: a payment against that debit line does not create a second invoice for the same GST
    @isTest
    static void paymentAgainstDebitDoesNotDuplicateInvoice() {
        Receipt__c debit = newNote('Debit', 10000, true);
        approve(debit);
        Payment_Schedule__c ps = [SELECT Id FROM Payment_Schedule__c WHERE Debit_Payment_Schedule__c = true];
        Receipt__c pay = new Receipt__c(Opportunity__c = opp().Id, Type__c = 'Tax Invoice', Amount__c = 11800, Approval_Status__c = 'Sent',
                                        Against_Debit__c = true, Payment_Schedule__c = ps.Id, Mode_Of_Payment__c = 'UPI');
        insert pay;
        Test.startTest();
        approve(pay);
        Test.stopTest();
        System.assertEquals(1, [SELECT COUNT() FROM Tax_Invoice__c WHERE Payment_Schedule__c = :ps.Id]);
        System.assertEquals(11800, [SELECT Total_Received_Amount__c FROM Payment_Schedule__c WHERE Id = :ps.Id].Total_Received_Amount__c);
    }

    // ---- point 2: cancelling an approved debit note removes its line and invoice
    @isTest
    static void cancelApprovedDebitNote() {
        Receipt__c debit = newNote('Debit', 10000, true);
        approve(debit);
        CreditDebitNoteService.NoteSummary s = CreditDebitNoteService.getNoteSummary(debit.Id);
        System.assert(s.canCancel, s.message);
        System.assertEquals('Debit Note', s.entryType);
        System.assert(s.entryNumber.contains('DN-'), s.entryNumber);

        Test.startTest();
        CreditDebitNoteService.cancelNote(debit.Id, 'Raised by mistake');
        Test.stopTest();

        Receipt__c after = [SELECT Status__c, Cancellation_Reason__c, Cancelled_Date__c, Cancelled_By__c, Note_Status__c FROM Receipt__c WHERE Id = :debit.Id];
        System.assertEquals('Cancelled', after.Status__c);
        System.assertEquals('Cancelled', after.Note_Status__c);
        System.assertEquals('Raised by mistake', after.Cancellation_Reason__c);
        System.assertEquals(System.today(), after.Cancelled_Date__c);
        System.assertEquals(UserInfo.getUserId(), after.Cancelled_By__c);
        System.assertEquals(0, [SELECT COUNT() FROM Payment_Schedule__c WHERE Debit_Payment_Schedule__c = true]);
        System.assertEquals(0, [SELECT COUNT() FROM Tax_Invoice__c]);
    }

    @isTest
    static void cancelDebitBlockedWhenPaid() {
        Receipt__c debit = newNote('Debit', 10000, false);
        approve(debit);
        Payment_Schedule__c ps = [SELECT Id FROM Payment_Schedule__c WHERE Debit_Payment_Schedule__c = true];
        ps.Total_Received_Amount__c = 5000;
        update ps;
        try {
            CreditDebitNoteService.cancelNote(debit.Id, 'test');
            System.assert(false, 'expected an error');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('already been received'), e.getMessage());
        }
        System.assertEquals(null, [SELECT Status__c FROM Receipt__c WHERE Id = :debit.Id].Status__c);
    }

    @isTest
    static void cancelBlockedWhenGstPaid() {
        Receipt__c debit = newNote('Debit', 10000, true);
        approve(debit);
        Tax_Invoice__c inv = [SELECT Id FROM Tax_Invoice__c LIMIT 1];
        inv.GST_Paid__c = true;
        update inv;
        CreditDebitNoteService.NoteSummary s = CreditDebitNoteService.getNoteSummary(debit.Id);
        System.assert(!s.canCancel);
        System.assert(s.message.contains('GST'), s.message);
    }

    // ---- point 2: cancelling an approved credit note takes the amount back from the instalments
    @isTest
    static void cancelApprovedCreditNoteReversesSchedule() {
        Receipt__c credit = newNote('Credit', 10000, true);
        approve(credit);
        Payment_Schedule__c ps1 = [SELECT Id, Total_Received_Amount__c, Credit_Note_Allocation__c FROM Payment_Schedule__c WHERE Installment_Sequence__c = 1];
        System.assertEquals(11800, ps1.Total_Received_Amount__c);
        System.assert(ps1.Credit_Note_Allocation__c.contains(String.valueOf(credit.Id)));

        Test.startTest();
        CreditDebitNoteService.cancelNote(credit.Id, 'Wrong amount');
        Test.stopTest();

        ps1 = [SELECT Total_Received_Amount__c, Credit_Note_Allocation__c FROM Payment_Schedule__c WHERE Id = :ps1.Id];
        System.assertEquals(0, ps1.Total_Received_Amount__c);
        System.assertEquals(null, ps1.Credit_Note_Allocation__c);
        System.assertEquals(0, [SELECT COUNT() FROM Tax_Invoice__c WHERE Receipt__c = :credit.Id]);
    }

    // credit notes approved before 21 Nov have no allocation record: the tax invoices are used
    @isTest
    static void cancelLegacyCreditNoteUsesTaxInvoices() {
        Receipt__c credit = newNote('Credit', 10000, true);
        approve(credit);
        Payment_Schedule__c ps1 = [SELECT Id FROM Payment_Schedule__c WHERE Installment_Sequence__c = 1];
        ps1.Credit_Note_Allocation__c = null;
        update ps1;
        CreditDebitNoteService.cancelNote(credit.Id, 'Legacy');
        System.assertEquals(0, [SELECT Total_Received_Amount__c FROM Payment_Schedule__c WHERE Id = :ps1.Id].Total_Received_Amount__c);
    }

    @isTest
    static void cancelPendingNoteAndAgainNotAllowed() {
        Receipt__c credit = newNote('Credit', 5000, false);
        CreditDebitNoteService.cancelNote(credit.Id, 'Not needed');
        System.assertEquals('Cancelled', [SELECT Status__c FROM Receipt__c WHERE Id = :credit.Id].Status__c);

        // approving a cancelled note changes nothing
        approve(credit);
        System.assertEquals(0, [SELECT Total_Received_Amount__c FROM Payment_Schedule__c WHERE Installment_Sequence__c = 1].Total_Received_Amount__c);

        try {
            CreditDebitNoteService.cancelNote(credit.Id, 'again');
            System.assert(false, 'expected an error');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('already cancelled'), e.getMessage());
        }
        try {
            CreditDebitNoteService.cancelNote(credit.Id, '  ');
            System.assert(false, 'expected an error');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('reason'), e.getMessage());
        }
    }

    @isTest
    static void receiptIsNotANote() {
        Receipt__c r = new Receipt__c(Opportunity__c = opp().Id, Type__c = 'Tax Invoice', Amount__c = 100);
        insert r;
        CreditDebitNoteService.NoteSummary s = CreditDebitNoteService.getNoteSummary(r.Id);
        System.assert(!s.canCancel);
        System.assertEquals('Receipt', [SELECT Entry_Type__c FROM Receipt__c WHERE Id = :r.Id].Entry_Type__c);
    }

    @isTest
    static void legacyDebitScheduleIsFound() {
        Receipt__c debit = newNote('Debit', 10000, false);
        approve(debit);
        Payment_Schedule__c ps = [SELECT Id FROM Payment_Schedule__c WHERE Debit_Payment_Schedule__c = true];
        ps.Debit_Note__c = null;
        update ps;
        Receipt__c note = [SELECT Id, Opportunity__c, Amount__c, CreatedDate, Pricing_Element_Master__r.Name FROM Receipt__c WHERE Id = :debit.Id];
        System.assertEquals(ps.Id, CreditDebitNoteService.findDebitSchedule(note).Id);
    }

    // ---- point 3 / 4: unit transfer checks
    @isTest
    static void unitTransferBlockedByOpenNotes() {
        Receipt__c debit = newNote('Debit', 10000, false);
        Unit__c fromUnit = new Unit__c();
        Unit__c toUnit = new Unit__c(Status__c = 'For Sale');
        insert new List<Unit__c>{ fromUnit, toUnit };
        Id rt = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Unit_Transfer').getRecordTypeId();
        Case c = new Case(RecordTypeId = rt, Subject = 'Transfer', Status = 'New', Opportunity__c = opp().Id, From_Unit__c = fromUnit.Id, To_Unit__c = toUnit.Id);

        Database.SaveResult blocked = Database.insert(c, false);
        System.assert(!blocked.isSuccess(), 'unit transfer must be blocked while a note is open');
        System.assert(blocked.getErrors()[0].getMessage().contains('credit/debit notes'), blocked.getErrors()[0].getMessage());

        CreditDebitNoteService.cancelNote(debit.Id, 'Before unit transfer');
        Database.SaveResult ok = Database.insert(c, false);
        System.assert(ok.isSuccess(), String.valueOf(ok.getErrors()));
    }

    @isTest
    static void unitTransferNeedsScheduleOnNewBooking() {
        Opportunity newOpp = new Opportunity(Name = 'New Unit Opp', StageName = 'Prospecting', CloseDate = System.today().addDays(30), AccountId = opp().AccountId);
        insert newOpp;
        Unit__c fromUnit = new Unit__c();
        Unit__c toUnit = new Unit__c(Status__c = 'For Sale');
        insert new List<Unit__c>{ fromUnit, toUnit };
        Id rt = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Unit_Transfer').getRecordTypeId();
        Case c = new Case(RecordTypeId = rt, Subject = 'Transfer', Status = 'New', Opportunity__c = opp().Id, From_Unit__c = fromUnit.Id, To_Unit__c = toUnit.Id);
        insert c;

        c.To_Opportunity__c = newOpp.Id;
        Database.SaveResult blocked = Database.update(c, false);
        System.assert(!blocked.isSuccess(), 'new booking without payment schedule must be rejected');
        System.assert(blocked.getErrors()[0].getMessage().contains('payment schedule is not generated'), blocked.getErrors()[0].getMessage());

        insert new Cost_Sheet__c(Opportunity__c = newOpp.Id, Unit__c = toUnit.Id, finalize_CostSheet__c = true);
        insert new Payment_Schedule__c(Opportunity__c = newOpp.Id, Name = 'Booking', Agreement_Value__c = 1000, Tax_Amount__c = 50, Installment_Sequence__c = 1, Total_Received_Amount__c = 0);
        Database.SaveResult ok = Database.update(c, false);
        System.assert(ok.isSuccess(), String.valueOf(ok.getErrors()));
    }

    @isTest
    static void openNotesListIgnoresCancelledAndRejected() {
        Receipt__c a = newNote('Credit', 100, false);
        Receipt__c b = newNote('Debit', 100, false);
        update new Receipt__c(Id = b.Id, Approval_Status__c = 'Rejected');
        Map<Id, List<Receipt__c>> open = CreditDebitNoteService.openNotesByOpportunity(new Set<Id>{ opp().Id });
        System.assertEquals(1, open.get(opp().Id).size());
        System.assertEquals(a.Id, open.get(opp().Id)[0].Id);
    }

    // ---- point 5: CGST box accepts only CGST, SGST box only SGST
    @isTest
    static void taxMasterTypesAreChecked() {
        Tax_Master__c cgst = [SELECT Id FROM Tax_Master__c WHERE Tax_Type__c = 'CGST' LIMIT 1];
        Tax_Master__c sgst = [SELECT Id FROM Tax_Master__c WHERE Tax_Type__c = 'SGST' LIMIT 1];
        try {
            GenerateReceiptDetailsOnOppController.validateTaxMasters(new Receipt__c(Tax_Master_CGST__c = sgst.Id, Tax_Master_SGST__c = sgst.Id));
            System.assert(false, 'expected an error');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('CGST'), e.getMessage());
        }
        try {
            GenerateReceiptDetailsOnOppController.validateTaxMasters(new Receipt__c(Tax_Master_CGST__c = cgst.Id, Tax_Master_SGST__c = cgst.Id));
            System.assert(false, 'expected an error');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('SGST'), e.getMessage());
        }
        GenerateReceiptDetailsOnOppController.validateTaxMasters(new Receipt__c(Tax_Master_CGST__c = cgst.Id, Tax_Master_SGST__c = sgst.Id));
    }

    // ---- point 15: a receipt without an amount is refused with a clear message
    @isTest
    static void receiptWithoutAmountIsRefused() {
        Map<String, Object> data = new Map<String, Object>{ 'opportunityId' => String.valueOf(opp().Id), 'receiptType' => 'Tax Invoice', 'modeOfPayment' => 'UPI' };
        try {
            GenerateReceiptDetailsOnOppController.createReceipt(data, null);
            System.assert(false, 'expected an error');
        } catch (AuraHandledException e) {
            System.assertEquals('Please enter the Amount.', e.getMessage());
        }
        data.put('modeOfPayment', 'TDS');
        try {
            GenerateReceiptDetailsOnOppController.createReceipt(data, null);
            System.assert(false, 'expected an error');
        } catch (AuraHandledException e) {
            System.assertEquals('Please enter the TDS Amount.', e.getMessage());
        }
        System.assertEquals(0, [SELECT COUNT() FROM Receipt__c]);
    }

    // ---- point 8: entry number nomenclature
    @isTest
    static void entryNumberUsesNoteNomenclature() {
        Receipt__c credit = newNote('Credit', 100, false);
        Receipt__c debit = newNote('Debit', 100, false);
        Receipt__c c = [SELECT Name, Receipt_Number__c, Entry_Type__c, Note_Status__c FROM Receipt__c WHERE Id = :credit.Id];
        Receipt__c d = [SELECT Name, Receipt_Number__c, Entry_Type__c FROM Receipt__c WHERE Id = :debit.Id];
        System.assert(c.Receipt_Number__c.endsWith('CN-' + c.Name.replace('RE - ', '')), c.Receipt_Number__c);
        System.assert(d.Receipt_Number__c.endsWith('DN-' + d.Name.replace('RE - ', '')), d.Receipt_Number__c);
        System.assertEquals('Credit Note', c.Entry_Type__c);
        System.assertEquals('Debit Note', d.Entry_Type__c);
        System.assertEquals('Sent', c.Note_Status__c);
    }

    // ---- point 11: Indian commas on document amounts
    @isTest
    static void documentAmountsGetIndianCommas() {
        Map<String, Object> values = new Map<String, Object>{
            'totalAmount' => 12345678.5,
            'floorNumber' => 12,
            'superBuiltupArea' => 1250,
            'customerName' => 'A',
            'statementOfAccountTable' => new List<Object>{ new Map<String, Object>{ 'totalBilled' => 100000, 'particularData' => 'Booking' } },
            'Total' => 'Total'
        };
        Map<String, Object> tables = new Map<String, Object>{ 'costSheetTable' => new List<Object>{ new Map<String, Object>{ 'amountValue' => 2500000.75, 'breakup' => '10%' } } };
        String body = JSON.serialize(new Map<String, Object>{ 'file_name' => 'x', 'templates' => new List<Object>{ new Map<String, Object>{ 'template_key' => 'T', 'template_values' => values, 'template_table_values' => tables } } });
        Map<String, Object> out = (Map<String, Object>) JSON.deserializeUntyped(digioCalloutUtility.formatTemplateAmounts(body));
        Map<String, Object> tv = (Map<String, Object>) ((Map<String, Object>) ((List<Object>) out.get('templates'))[0]).get('template_values');
        System.assertEquals('1,23,45,678.50', tv.get('totalAmount'));
        System.assertEquals(12, tv.get('floorNumber'));
        System.assertEquals(1250, tv.get('superBuiltupArea'));
        System.assertEquals('Total', tv.get('Total'));
        Map<String, Object> row = (Map<String, Object>) ((List<Object>) tv.get('statementOfAccountTable'))[0];
        System.assertEquals('1,00,000', row.get('totalBilled'));
        Map<String, Object> tt = (Map<String, Object>) ((Map<String, Object>) ((List<Object>) out.get('templates'))[0]).get('template_table_values');
        Map<String, Object> csRow = (Map<String, Object>) ((List<Object>) tt.get('costSheetTable'))[0];
        System.assertEquals('25,00,000.75', csRow.get('amountValue'));
        System.assertEquals('10%', csRow.get('breakup'));
        System.assertEquals('not json', digioCalloutUtility.formatTemplateAmounts('not json'));
    }
}