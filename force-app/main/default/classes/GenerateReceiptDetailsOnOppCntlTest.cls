@isTest
public class GenerateReceiptDetailsOnOppCntlTest {

    @testSetup
    static void setupTestData() {
        Account accMain = new Account(Name = 'Main Account');
        Account accCo   = new Account(Name = 'Co Applicant Account');
        insert new List<Account>{ accMain, accCo };

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            AccountId = accMain.Id
        );
        insert opp;

        Applicant__c app = new Applicant__c(
            Opportunity__c = opp.Id,
            Account__c = accCo.Id
        );
        insert app;

        Receipt__c rec = new Receipt__c(
            Opportunity__c = opp.Id,
            DD_Number__c = 'DD-0001',
            Cheque_Number__c = 'CHQ-0001'
        );
        insert rec;

        Cost_Sheet__c cs = new Cost_Sheet__c(
            Opportunity__c = opp.Id,
            finalize_CostSheet__c = true
        );
        insert cs;

        Pricing_Element_Master__c pem = new Pricing_Element_Master__c(Name = 'Base Price');
        insert pem;

        Pricing_Element__c pe = new Pricing_Element__c(
            Cost_Sheet__c = cs.Id,
            Pricing_Element_Master__c = pem.Id
        );
        insert pe;

        // ADD THIS: for getDebitPaymentSchedules() coverage
        Payment_Schedule__c ps = new Payment_Schedule__c(
            Opportunity__c = opp.Id,
            Debit_Payment_Schedule__c = true,
            Total_Received_Amount__c = 1500
        );
        insert ps;
    }

    private static Map<String, Object> getBaseReceiptData(Id oppId, String uniqueSuffix) {
        return new Map<String, Object>{
            'opportunityId' => oppId,
            'receiptType' => 'Credit',
            'bankName' => 'Test Bank',
            'panNo' => 'ABCDE1234F',
            'amount' => 5000,
            'tdsAmount' => 500,
            'branch' => 'Main Branch',
            'modeOfPayment' => 'Cheque',
            'drawnOnBank' => 'XYZ Bank',
            'upiProvider' => 'Google Pay',
            'chequeNumber' => 'CHQ-' + uniqueSuffix,
            'cin' => 'CIN' + uniqueSuffix,
            'bsrCode' => 'BSR' + uniqueSuffix,
            'referenceNo' => 'REF' + uniqueSuffix,
            'transactionReferenceNo' => 'TXN' + uniqueSuffix,
            'ddNumber' => 'DD-' + uniqueSuffix,
            'jvReferenceNumber' => 'JV' + uniqueSuffix
        };
    }

    @isTest
    static void testGetPicklistValues() {
        Test.startTest();
        List<String> values = GenerateReceiptDetailsOnOppController.getPicklistValues('Type__c');
        Test.stopTest();
        System.assertNotEquals(null, values);
    }

    @isTest
    static void testGetAccountValues() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        List<Account> accts = GenerateReceiptDetailsOnOppController.getAccountValues(opp.Id);
        Test.stopTest();

        System.assert(accts.size() >= 1);
    }

    @isTest
    static void testGetPricingElements() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        List<GenerateReceiptDetailsOnOppController.PricingPaymentSchedWrapper> opts =
            GenerateReceiptDetailsOnOppController.getPricingElements(opp.Id);
        Test.stopTest();

        System.assertEquals(1, opts.size());
        System.assertNotEquals(null, opts[0].value);
    }

    @isTest
    static void testGetDebitPaymentSchedules() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        List<GenerateReceiptDetailsOnOppController.PaymentScheduleOptionWrapper> result =
            GenerateReceiptDetailsOnOppController.getDebitPaymentSchedules(opp.Id);
        Test.stopTest();

    }

    @isTest
    static void testGetDebitPaymentSchedules_NullOppId() {
        Test.startTest();
        List<GenerateReceiptDetailsOnOppController.PaymentScheduleOptionWrapper> result =
            GenerateReceiptDetailsOnOppController.getDebitPaymentSchedules(null);
        Test.stopTest();

        System.assertEquals(0, result.size());
    }

    @isTest
    static void testCreateReceipt_ChequeDateBranch() {
        Opportunity opp = [SELECT Id, AccountId FROM Opportunity LIMIT 1];

        Map<String, Object> receiptData = getBaseReceiptData(opp.Id, '1');
        receiptData.put('chequeDate', '2024-03-24');

        Test.startTest();
        GenerateReceiptDetailsOnOppController.createReceipt(receiptData, opp.AccountId);
        Test.stopTest();

        Receipt__c r = [
            SELECT Id, Cheque_Date__c
            FROM Receipt__c
            WHERE Opportunity__c = :opp.Id AND Reference_Number__c = 'REF1'
            LIMIT 1
        ];
        System.assertEquals(Date.valueOf('2024-03-24'), r.Cheque_Date__c);
    }

    @isTest
    static void testCreateReceipt_FundTransferDateBranch() {
        Opportunity opp = [SELECT Id, AccountId FROM Opportunity LIMIT 1];

        Map<String, Object> receiptData = getBaseReceiptData(opp.Id, '2');
        receiptData.put('fundTransferDate', '2024-03-25');

        Test.startTest();
        GenerateReceiptDetailsOnOppController.createReceipt(receiptData, opp.AccountId);
        Test.stopTest();

        Receipt__c r = [
            SELECT Id, Fund_Transfer_Date__c
            FROM Receipt__c
            WHERE Opportunity__c = :opp.Id AND Reference_Number__c = 'REF2'
            LIMIT 1
        ];
        System.assertEquals(Date.valueOf('2024-03-25'), r.Fund_Transfer_Date__c);
    }

    @isTest
    static void testCreateReceipt_DdDateBranch() {
        Opportunity opp = [SELECT Id, AccountId FROM Opportunity LIMIT 1];

        Map<String, Object> receiptData = getBaseReceiptData(opp.Id, '3');
        receiptData.put('ddDate', '2024-03-26');

        Test.startTest();
        GenerateReceiptDetailsOnOppController.createReceipt(receiptData, opp.AccountId);
        Test.stopTest();

        Receipt__c r = [
            SELECT Id, DD_Date__c
            FROM Receipt__c
            WHERE Opportunity__c = :opp.Id AND Reference_Number__c = 'REF3'
            LIMIT 1
        ];
        System.assertEquals(Date.valueOf('2024-03-26'), r.DD_Date__c);
    }

    @isTest
    static void testCreateReceipt_PaidDateBranch() {
        Opportunity opp = [SELECT Id, AccountId FROM Opportunity LIMIT 1];

        Map<String, Object> receiptData = getBaseReceiptData(opp.Id, '4');
        receiptData.put('paidDate', '2024-03-27');

        Test.startTest();
        GenerateReceiptDetailsOnOppController.createReceipt(receiptData, opp.AccountId);
        Test.stopTest();

        Receipt__c r = [
            SELECT Id, Paid_Date__c
            FROM Receipt__c
            WHERE Opportunity__c = :opp.Id AND Reference_Number__c = 'REF4'
            LIMIT 1
        ];
        System.assertEquals(Date.valueOf('2024-03-27'), r.Paid_Date__c);
    }

    @isTest
    static void testCreateReceipt_ChallanDateBranch() {
        Opportunity opp = [SELECT Id, AccountId FROM Opportunity LIMIT 1];

        Map<String, Object> receiptData = getBaseReceiptData(opp.Id, '5');
        receiptData.put('challanDate', '2024-03-28');

        Test.startTest();
        GenerateReceiptDetailsOnOppController.createReceipt(receiptData, opp.AccountId);
        Test.stopTest();

        Receipt__c r = [
            SELECT Id, Challan_Date__c
            FROM Receipt__c
            WHERE Opportunity__c = :opp.Id AND Reference_Number__c = 'REF5'
            LIMIT 1
        ];
        System.assertEquals(Date.valueOf('2024-03-28'), r.Challan_Date__c);
    }

    @isTest
    static void testCreateReceipt_JvDateBranch() {
        Opportunity opp = [SELECT Id, AccountId FROM Opportunity LIMIT 1];

        Map<String, Object> receiptData = getBaseReceiptData(opp.Id, '6');
        receiptData.put('jvDate', '2024-03-29');

        Test.startTest();
        GenerateReceiptDetailsOnOppController.createReceipt(receiptData, opp.AccountId);
        Test.stopTest();

        Receipt__c r = [
            SELECT Id, JV_Date__c
            FROM Receipt__c
            WHERE Opportunity__c = :opp.Id AND Reference_Number__c = 'REF6'
            LIMIT 1
        ];
        System.assertEquals(Date.valueOf('2024-03-29'), r.JV_Date__c);
    }

    @isTest
    static void testCreateReceipt_FundDateAndAgainstDebitBranch() {
        Opportunity opp = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
        Payment_Schedule__c ps = [
            SELECT Id
            FROM Payment_Schedule__c
            WHERE Opportunity__c = :opp.Id
            LIMIT 1
        ];

        Map<String, Object> receiptData = getBaseReceiptData(opp.Id, '7');
        receiptData.put('fundDate', '2024-03-30');
        receiptData.put('againstDebit', true);
        receiptData.put('paymentScheduleId', ps.Id);

        Test.startTest();
        GenerateReceiptDetailsOnOppController.createReceipt(receiptData, opp.AccountId);
        Test.stopTest();

        Receipt__c r = [
            SELECT Id, Fund_Date__c, Against_Debit__c, Payment_Schedule__c
            FROM Receipt__c
            WHERE Opportunity__c = :opp.Id AND Reference_Number__c = 'REF7'
            LIMIT 1
        ];
        System.assertEquals(Date.valueOf('2024-03-30'), r.Fund_Date__c);
        System.assertEquals(true, r.Against_Debit__c);
        System.assertEquals(ps.Id, r.Payment_Schedule__c);
    }

    @isTest
    static void testCheckDuplicate() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        Boolean ddOk = GenerateReceiptDetailsOnOppController.checkDuplicate(opp.Id, 'DD', 'DD-0001');
        Boolean chqOk = GenerateReceiptDetailsOnOppController.checkDuplicate(opp.Id, 'Cheque', 'CHQ-0001');
        Boolean newOk = GenerateReceiptDetailsOnOppController.checkDuplicate(opp.Id, 'Cheque', 'CHQ-NOT-EXIST');
        Test.stopTest();

        System.assertEquals(false, ddOk);
        System.assertEquals(false, chqOk);
        System.assertEquals(true, newOk);
    }
}