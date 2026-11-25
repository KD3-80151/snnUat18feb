/**
 * Tests for the client bug fixes (Nov 2026):
 * project-wise company/bank details, applicant names, Indian amount format,
 * payment-made date, Next Action -> Closed Lost, demand-date validation,
 * document email attachment names and customer-portal uploads.
 */
@isTest
private class SNNClientFixesTest {

    private class DriveMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            HttpResponse res = new HttpResponse();
            String ep = request.getEndpoint();
            if (ep.contains('oauth2')) {
                res.setStatusCode(200);
                res.setBody('{"access_token": "mockToken", "expires_in": 3600}');
            } else if (ep.contains('uploadType=resumable')) {
                res.setStatusCode(200);
                res.setHeader('Location', 'https://mock-upload-location');
            } else if (ep.contains('mock-upload-location')) {
                res.setStatusCode(200);
                res.setBody('{"id": "UploadedFileId"}');
            } else if (ep.contains('/drive/v3/files')) {
                res.setStatusCode(200);
                res.setBody('{"id": "PortalFolderId"}');
            } else {
                res.setStatusCode(200);
                res.setBody('{}');
            }
            return res;
        }
    }

    @TestSetup
    static void setup() {
        Test.setMock(HttpCalloutMock.class, new DriveMock());
        Company__c company = new Company__c(Name = 'SNN Builders Pvt Ltd', Short_Name__c = 'SNNBPL', Address__c = '35/B, JP Nagar, Bengaluru', Email__c = 'info@example.com');
        insert company;
        Project__c project = new Project__c(
            Name = 'Fix Test Project', Company__c = company.Id,
            Account_Name__c = 'SNN Builders Pvt Ltd - Collection', Bank_Name__c = 'IndusInd Bank', Branch__c = 'JP Nagar',
            Account_Number__c = '209384092843', IFSC_Code__c = 'INDB0000226', Type_of_Account__c = 'Current Account'
        );
        insert project;

        Account primary = new Account(Name = 'Ravi Kumar', Salutation__c = 'Mr');
        Account co1 = new Account(Name = 'Asha Rao', Salutation__c = 'Ms');
        Account co2 = new Account(Name = 'Vikram Rao');
        insert new List<Account>{ primary, co1, co2 };

        Opportunity opp = new Opportunity(Name = 'Fix Test Opp', StageName = 'New', CloseDate = Date.today(), AccountId = primary.Id, Project__c = project.Id);
        insert opp;

        insert new List<Applicant__c>{
            new Applicant__c(Opportunity__c = opp.Id, Account__c = co1.Id),
            new Applicant__c(Opportunity__c = opp.Id, Account__c = co1.Id),      // duplicate row must be ignored
            new Applicant__c(Opportunity__c = opp.Id, Account__c = primary.Id),  // primary must never appear as a co-applicant
            new Applicant__c(Opportunity__c = opp.Id, Account__c = co2.Id)
        };
    }

    private static Opportunity testOpp() {
        return [SELECT Id, AccountId, Project__c FROM Opportunity WHERE Name = 'Fix Test Opp' LIMIT 1];
    }

    // ---------------- DocumentDataHelper ----------------

    @isTest
    static void formatsAmountsInIndianSystem() {
        System.assertEquals('1,35,67,543', DocumentDataHelper.formatIndianAmount(13567543));
        System.assertEquals('1,23,45,676', DocumentDataHelper.formatIndianAmount(12345676));
        System.assertEquals('999', DocumentDataHelper.formatIndianAmount(999));
        System.assertEquals('1,000', DocumentDataHelper.formatIndianAmount(1000));
        System.assertEquals('12,34,567.50', DocumentDataHelper.formatIndianAmount(1234567.5));
        System.assertEquals('-1,00,000', DocumentDataHelper.formatIndianAmount(-100000));
        System.assertEquals('25,00,00,00,000', DocumentDataHelper.formatIndianAmount(25000000000L)); // beyond Integer range
        System.assertEquals('0', DocumentDataHelper.formatIndianAmount(null));
        System.assertEquals('05/01/2026', DocumentDataHelper.formatDate(Date.newInstance(2026, 1, 5)));
        System.assertEquals('', DocumentDataHelper.formatDate(null));
    }

    @isTest
    static void ignoresCoApplicantRepeatedUnderAnotherAccount() {
        Opportunity opp = testOpp();
        Account sameNameAgain = new Account(Name = '  asha   RAO ');
        Account primaryAgain = new Account(Name = 'Ravi Kumar');
        insert new List<Account>{ sameNameAgain, primaryAgain };
        insert new List<Applicant__c>{
            new Applicant__c(Opportunity__c = opp.Id, Account__c = sameNameAgain.Id),
            new Applicant__c(Opportunity__c = opp.Id, Account__c = primaryAgain.Id)
        };
        DocumentDataHelper.ApplicantNames n = DocumentDataHelper.getApplicantNames(opp.Id);
        System.assertEquals('Asha Rao, Vikram Rao', n.allCoApplicantNames);
        System.assertEquals('Vikram Rao', n.coApplicant2Name);
    }

    @isTest
    static void printsAadhaarNextToPan() {
        System.assertEquals('ABCDE1234F          Aadhaar No: 1234 5678 9012', DocumentDataHelper.panWithAadhaar('ABCDE1234F', '123456789012'));
        System.assertEquals('ABCDE1234F          Aadhaar No: 1234 5678 9012', DocumentDataHelper.panWithAadhaar(' ABCDE1234F ', '1234-5678-9012'));
        System.assertEquals('-          Aadhaar No: 1234 5678 9012', DocumentDataHelper.panWithAadhaar(null, '1234 5678 9012'));
        System.assertEquals('ABCDE1234F          Aadhaar No: XXXX1234', DocumentDataHelper.panWithAadhaar('ABCDE1234F', 'XXXX1234'));
        System.assertEquals('ABCDE1234F', DocumentDataHelper.panWithAadhaar('ABCDE1234F', null));
        System.assertEquals('', DocumentDataHelper.panWithAadhaar(null, ''));
    }

    @isTest
    static void resolvesProjectCompanyAndBank() {
        Opportunity opp = testOpp();
        DocumentDataHelper.CompanyDetails c = DocumentDataHelper.getCompanyDetailsForOpportunity(opp.Id);
        System.assertEquals('SNN Builders Pvt Ltd', c.companyName);
        System.assertEquals('SNNBPL', c.companyShortName);
        System.assertEquals('35/B, JP Nagar, Bengaluru', c.companyAddress);
        System.assertEquals('209384092843', c.bankAccountNumber);
        System.assertEquals('INDB0000226', c.bankIfscCode);
        System.assertEquals('IndusInd Bank', c.bankName);
        System.assertEquals('SNN Builders Pvt Ltd - Collection', c.bankAccountName);
        System.assertEquals('', DocumentDataHelper.getCompanyDetails(null).companyName);
        System.assertEquals('', DocumentDataHelper.getCompanyDetailsForOpportunity(null).companyName);
    }

    @isTest
    static void buildsApplicantNamesWithoutDuplicates() {
        Opportunity opp = testOpp();
        DocumentDataHelper.ApplicantNames n = DocumentDataHelper.getApplicantNames(opp.Id);
        System.assertEquals('Ravi Kumar', n.primaryName);
        System.assertEquals('Asha Rao', n.coApplicant1Name);
        System.assertEquals('Vikram Rao', n.coApplicant2Name);
        System.assertEquals('Asha Rao, Vikram Rao', n.allCoApplicantNames);
        System.assertEquals('Ravi Kumar & Asha Rao', n.primaryWithCoApplicant);
        System.assertEquals(2, n.coApplicantAccounts.size());

        DocumentDataHelper.ApplicantNames s = DocumentDataHelper.getApplicantNames(opp.Id, true);
        System.assertEquals('Mr. Ravi Kumar', s.primaryName);
        System.assertEquals('Mr. Ravi Kumar & Ms. Asha Rao', s.primaryWithCoApplicant);
        System.assertEquals('Vikram Rao', s.coApplicant2Name, 'No "null." prefix when the salutation is blank');
        System.assertEquals('', DocumentDataHelper.getApplicantNames(null).primaryName);
    }

    @isTest
    static void picksPaymentMadeDateByMode() {
        Date d1 = Date.newInstance(2026, 1, 1), d2 = Date.newInstance(2026, 1, 2), rd = Date.newInstance(2026, 2, 1);
        System.assertEquals(d1, DocumentDataHelper.paymentMadeDate(new Receipt__c(Mode_Of_Payment__c = 'Cheque', Cheque_Date__c = d1, Receipt_Date__c = rd)));
        System.assertEquals(d1, DocumentDataHelper.paymentMadeDate(new Receipt__c(Mode_Of_Payment__c = 'DD', DD_Date__c = d1, Receipt_Date__c = rd)));
        System.assertEquals(d1, DocumentDataHelper.paymentMadeDate(new Receipt__c(Mode_Of_Payment__c = 'JV', JV_Date__c = d1, Receipt_Date__c = rd)));
        System.assertEquals(d1, DocumentDataHelper.paymentMadeDate(new Receipt__c(Mode_Of_Payment__c = 'UPI', Paid_Date__c = d1, Receipt_Date__c = rd)));
        System.assertEquals(d1, DocumentDataHelper.paymentMadeDate(new Receipt__c(Mode_Of_Payment__c = 'TDS', Challan_Date__c = d1, Receipt_Date__c = rd)));
        System.assertEquals(d1, DocumentDataHelper.paymentMadeDate(new Receipt__c(Mode_Of_Payment__c = 'FUNDTRANSFER', Fund_Date__c = d1, Receipt_Date__c = rd)));
        System.assertEquals(d2, DocumentDataHelper.paymentMadeDate(new Receipt__c(Mode_Of_Payment__c = 'EFT', Fund_Transfer_Date__c = d2, Receipt_Date__c = rd)));
        System.assertEquals(rd, DocumentDataHelper.paymentMadeDate(new Receipt__c(Mode_Of_Payment__c = 'Cheque', Receipt_Date__c = rd)), 'Falls back to the receipt date');
        System.assertEquals(null, DocumentDataHelper.paymentMadeDate(null));
    }

    // ---------------- Opportunity Next Action ----------------

    @isTest
    static void notInterestedMovesOpportunityToClosedLost() {
        Opportunity opp = testOpp();
        Test.startTest();
        update new Opportunity(Id = opp.Id, Customer_Response__c = 'Not Interested', Next_Action_Reason__c = 'Budget constraints');
        Test.stopTest();
        System.assertEquals('Closed Lost', [SELECT StageName FROM Opportunity WHERE Id = :opp.Id].StageName);
    }

    @isTest
    static void interestedKeepsStage() {
        Opportunity opp = testOpp();
        update new Opportunity(Id = opp.Id, Customer_Response__c = 'Interested', Next_Action_Reason__c = 'Liked the 3BHK');
        System.assertNotEquals('Closed Lost', [SELECT StageName FROM Opportunity WHERE Id = :opp.Id].StageName);
    }

    @isTest
    static void nextActionRequiresReason() {
        Opportunity opp = testOpp();
        try {
            update new Opportunity(Id = opp.Id, Customer_Response__c = 'Interested');
            System.assert(false, 'Expected the Next Action reason validation to fire');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('reason'), e.getMessage());
        }
    }

    @isTest
    static void followUpComponentCapturesReason() {
        Opportunity opp = testOpp();
        Task t1 = new Task(Subject = 'Take Follow Up with Customer', WhatId = opp.Id);
        Task t2 = new Task(Subject = 'Take Follow Up with Customer', WhatId = opp.Id);
        insert new List<Task>{ t1, t2 };

        Test.startTest();
        customerFollowUpController.saveFollowUp(t1.Id, 'Interested', 'Site visit', 'Wants east facing', null);
        Opportunity afterInterested = [SELECT Customer_Response__c, Next_Action_Reason__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('Interested', afterInterested.Customer_Response__c);
        System.assert(afterInterested.Next_Action_Reason__c.contains('Wants east facing'));

        customerFollowUpController.saveFollowUp(t2.Id, 'Not Interested', null, 'Bought elsewhere', 'Lost to Competitor');
        Test.stopTest();
        Opportunity afterLost = [SELECT StageName, Loss_Reason__c, Next_Action_Reason__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('Closed Lost', afterLost.StageName);
        System.assertEquals('Lost to Competitor', afterLost.Loss_Reason__c);
        System.assert(afterLost.Next_Action_Reason__c.contains('Bought elsewhere'));

        for (String[] bad : new List<String[]>{
                new String[]{ null, 'Interested', 'x', 'y', null },
                new String[]{ t1.Id, 'Maybe', 'x', 'y', null },
                new String[]{ t1.Id, 'Interested', '', '', null },
                new String[]{ t1.Id, 'Not Interested', '', '', '' } }) {
            try {
                customerFollowUpController.saveFollowUp(bad[0], bad[1], bad[2], bad[3], bad[4]);
                System.assert(false, 'Expected an error');
            } catch (AuraHandledException e) {
                System.assert(true);
            }
        }
    }

    // ---------------- Demand date (Update Due Date) ----------------

    @isTest
    static void demandDateCannotBeInTheFuture() {
        Opportunity opp = testOpp();
        Payment_Schedule__c ps = new Payment_Schedule__c(Name = 'On Booking', Opportunity__c = opp.Id);
        insert ps;

        Test.startTest();
        ps.Pay_Date__c = Date.today().addDays(3);
        try {
            UpdatePaymentScheduleController.savePaymentSchedule(new List<Payment_Schedule__c>{ ps });
            System.assert(false, 'Future demand date must be rejected');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('future'), e.getMessage());
        }
        try {
            bulkUpdateDueDateController.saveOppsPaySchedulesSave(JSON.serialize(new List<Map<String, Object>>{
                new Map<String, Object>{ 'Id' => ps.Id, 'Pay_Date__c' => String.valueOf(Date.today().addDays(5)), 'Due_Date__c' => String.valueOf(Date.today().addDays(20)) }
            }));
            System.assert(false, 'Future demand date must be rejected in bulk too');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('future'), e.getMessage());
        }
        try {
            update new Payment_Schedule__c(Id = ps.Id, Pay_Date__c = Date.today().addDays(1));
            System.assert(false, 'Validation rule must block a future demand date');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('future'), e.getMessage());
        }

        ps.Pay_Date__c = Date.today();
        ps.Due_Date__c = Date.today().addDays(15);
        UpdatePaymentScheduleController.savePaymentSchedule(new List<Payment_Schedule__c>{ ps });
        Test.stopTest();
        System.assertEquals(Date.today(), [SELECT Pay_Date__c FROM Payment_Schedule__c WHERE Id = :ps.Id].Pay_Date__c);
    }

    // ---------------- Document emails ----------------

    @isTest
    static void customerFacingAttachmentNames() {
        System.assertEquals('Receipt.pdf', digioCalloutUtility.attachmentFileName('Receipt'));
        System.assertEquals('Demand Letter.pdf', digioCalloutUtility.attachmentFileName('DemandLetter'));
        System.assertEquals('Statement of Account.pdf', digioCalloutUtility.attachmentFileName('StatementOfAccounts'));
        System.assertEquals('Cost Sheet.pdf', digioCalloutUtility.attachmentFileName('Cost Sheet'));
        System.assertEquals('Allotment Letter.pdf', digioCalloutUtility.attachmentFileName('AllotmentLetter'));
        System.assertEquals('Booking Form.pdf', digioCalloutUtility.attachmentFileName('BookingForm'));
        System.assertEquals('Something.pdf', digioCalloutUtility.attachmentFileName('Something'));
        System.assertEquals('CostsheetPDFEmailTemplate', digioCalloutUtility.EMAIL_TEMPLATE_BY_DOC.get('Cost Sheet'), 'The Cost Sheet button name must map to a template');
    }

    // ---------------- Customer portal uploads ----------------

    private static Receipt__c newReceipt(Id oppId, String tdsStatus) {
        Receipt__c r = new Receipt__c(Opportunity__c = oppId, Mode_Of_Payment__c = 'TDS', TDS_Amount__c = 1000, TDS_Approval_Status__c = tdsStatus);
        insert r;
        return r;
    }

    @isTest
    static void portalRefusesUploadWhenTdsAlreadySubmitted() {
        Opportunity opp = testOpp();
        Receipt__c r = newReceipt(opp.Id, 'Sent');
        Test.setMock(HttpCalloutMock.class, new DriveMock());
        Test.startTest();
        CustomerPortalController.wrapperForResponse res = CustomerPortalController.uploadDocuments(
            r.Id, 'tds.pdf', EncodingUtil.base64Encode(Blob.valueOf('pdf')), '3', 'RE', 'application/pdf');
        Test.stopTest();
        System.assertNotEquals(null, res);
        System.assert(String.isNotBlank(res.errorMessage));
        System.assertEquals(0, [SELECT COUNT() FROM Sub_Document__c WHERE Name = 'tds.pdf']);
    }

    @isTest
    static void portalUploadGoesToOwnFolderOnce() {
        Opportunity opp = testOpp();
        Receipt__c r = newReceipt(opp.Id, 'Pending');
        Test.setMock(HttpCalloutMock.class, new DriveMock());
        String data = EncodingUtil.base64Encode(Blob.valueOf('pdf-bytes'));

        Test.startTest();
        CustomerPortalController.wrapperForResponse first = CustomerPortalController.uploadDocuments(r.Id, 'tds.pdf', data, '9', 'RE', 'application/pdf');
        CustomerPortalController.wrapperForResponse second = CustomerPortalController.uploadDocuments(r.Id, 'tds.pdf', data, '9', 'RE', 'application/pdf');
        Test.stopTest();

        System.assertNotEquals(null, first);
        System.assert(String.isNotBlank(first.subDocUrl), 'First upload should store the file');
        System.assertEquals(true, second.alreadyUploaded, 'Retry must not create another copy');
        System.assertEquals(1, [SELECT COUNT() FROM Sub_Document__c WHERE Name = 'tds.pdf'], 'Exactly one copy of the file');
        Document__c folder = [SELECT Name, Document_Id__c FROM Document__c WHERE Opportunity__c = :opp.Id AND Name = :CustomerPortalController.PORTAL_UPLOAD_FOLDER LIMIT 1];
        System.assertEquals('PortalFolderId', folder.Document_Id__c);
        System.assertEquals(folder.Id, [SELECT Document__c FROM Sub_Document__c WHERE Name = 'tds.pdf'].Document__c);
    }

    @isTest
    static void portalApprovalSubmissionNeverThrows() {
        Opportunity opp = testOpp();
        Receipt__c r = newReceipt(opp.Id, 'Pending');
        Test.startTest();
        String first = CustomerPortalController.submitTDSApproval(r.Id);
        String bogus = CustomerPortalController.submitTDSApproval('a0P000000000000AAA');
        Test.stopTest();
        System.assertNotEquals(null, first);
        System.assert(bogus.contains('failed'), bogus);
    }
}