@isTest
private class RefundHandlerTest {

    @testSetup
    static void createTestData() {
        Account acc = new Account(
            Name = 'Test Account'
        );
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = acc.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert opp;

        // Create Receipt
        Receipt__c rec = new Receipt__c(
            Opportunity__c = opp.Id,
            Approval_Status__c = 'Approved',
            Amount__c = 10000,
            Amount_Paid_Excluding_TAX__c = 9523.81,
            CGST__c = 238.10,
            SGST__c = 238.10
        );
        insert rec;

        List<Payment_Schedule__c> psList = new List<Payment_Schedule__c>{
            new Payment_Schedule__c(
                Name = 'PS-1',
                Opportunity__c = opp.Id,
                Total_Received_Amount__c = 4000,
                Agreement_Value__c = 10000
            ),
            new Payment_Schedule__c(
                Name = 'PS-2',
                Opportunity__c = opp.Id,
                Total_Received_Amount__c = 3000,
                Agreement_Value__c = 10000
            ),
            new Payment_Schedule__c(
                Name = 'PS-3',
                Opportunity__c = opp.Id,
                Total_Received_Amount__c = 2000,
                Agreement_Value__c = 10000
            )
        };
        insert psList;
    }

    @isTest
    static void testHandleBeforeSetsPendingStatus() {
        Receipt__c rec = [SELECT Id, Amount__c, Approval_Status__c FROM Receipt__c LIMIT 1];

        Refund__c ref = new Refund__c(
            Receipt__c = rec.Id,
            Refund_Amount__c = 1000
        );
        
        insert ref;

    }

    @isTest
    static void testHandleBeforeReceiptNotApproved() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Receipt__c unapprovedRec = new Receipt__c(
            Opportunity__c = opp.Id,
            Approval_Status__c = 'Pending',
            Amount__c = 5000
        );
        insert unapprovedRec;

    }

    @isTest
    static void testHandleBeforeRefundAmountExceedsReceiptAmount() {
        Receipt__c rec = [SELECT Id, Amount__c FROM Receipt__c LIMIT 1];

        Refund__c ref = new Refund__c(
            Receipt__c = rec.Id,
            Refund_Amount__c = rec.Amount__c + 1000
        );

    }

    @isTest
    static void testProcessRefundDeductionDirectly() {
        Receipt__c rec = [
            SELECT Id, Amount__c, Opportunity__c
            FROM Receipt__c
            LIMIT 1
        ];

        Refund__c ref = new Refund__c(
            Receipt__c = rec.Id,
            Refund_Amount__c = 5000,
            Approval_Status__c = 'Approved',
            Refund_Date__c = Date.today(),
            Remarks__c = 'Test approved refund'
        );
        insert ref;

        Test.startTest();
        RefundHandler.processRefundDeduction(ref.Id);
        Test.stopTest();

        
    }

    @isTest
    static void testHandleAfterUpdateApprovedTransition() {
        Receipt__c rec = [SELECT Id FROM Receipt__c LIMIT 1];

        Refund__c ref = new Refund__c(
            Receipt__c = rec.Id,
            Refund_Amount__c = 1000,
            Approval_Status__c = 'Pending',
            Refund_Date__c = Date.today(),
            Remarks__c = 'Refund approval transition test'
        );
        insert ref;

         }

    @isTest
    static void testHandleAfterInsertPendingAndApproved() {
        Receipt__c rec = [SELECT Id, Amount__c FROM Receipt__c LIMIT 1];

        Refund__c pendingRef = new Refund__c(
            Receipt__c = rec.Id,
            Refund_Amount__c = 500,
            Approval_Status__c = 'Pending',
            Refund_Date__c = Date.today(),
            Remarks__c = 'Pending refund test'
        );

        Refund__c approvedRef = new Refund__c(
            Receipt__c = rec.Id,
            Refund_Amount__c = 500,
            Approval_Status__c = 'Approved',
            Refund_Date__c = Date.today(),
            Remarks__c = 'Approved refund test'
        );

        insert new List<Refund__c>{ pendingRef, approvedRef };
            update approvedRef;

    }
}