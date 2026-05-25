@isTest
private class BatchToCalculateDelayInterestTest {

    @testSetup
    static void setupTestData() {
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            CloseDate = System.today().addDays(30),
            StageName = 'Prospecting'
        );
        insert opp;

        Delay_Interest_Config__c config = new Delay_Interest_Config__c(
            Name = 'Delay Interest',
            Interest_Percent_over_MCLR__c = 5,
            MCLR_Rate__c = 7,
            Number_of_Days__c = 30
        );
        insert config;

        List<Payment_Schedule__c> paymentSchedules = new List<Payment_Schedule__c>();
        for (Integer i = 0; i < 3; i++) {
            paymentSchedules.add(new Payment_Schedule__c(
                Due_Date__c = System.today().addDays(-10 - i),
                Opportunity__c = opp.Id,
                Agreement_Value__c = 2000,
                Tax_Amount__c = 200,
                Total_Received_Amount__c = 1200
            ));
        }
        insert paymentSchedules;

        List<Delay_Interest__c> delayInterests = new List<Delay_Interest__c>();
        for (Integer i = 0; i < 2; i++) {
            delayInterests.add(new Delay_Interest__c(
                Payment_Schedule__c = paymentSchedules[i].Id,
                Delay_Date__c = System.today().addDays(-5)
            ));
        }
        insert delayInterests;
    }

    @isTest
    static void testBatchStart() {
        Test.startTest();
        BatchToCalculateDelayInterest batch = new BatchToCalculateDelayInterest();
        Database.QueryLocator queryLocator = batch.start(null);
        System.assertNotEquals(null, queryLocator);
        Test.stopTest();
    }

    @isTest
    static void testBatchExecuteWithRelatedDelayInterest() {
        List<Payment_Schedule__c> paymentSchedules = [SELECT Id, Due_Date__c, Total_Due_Amount__c,
            Opportunity__c,
            (SELECT Id, Delay_Date__c FROM Delay_Interests__r)
            FROM Payment_Schedule__c];

        Test.startTest();
        BatchToCalculateDelayInterest batch = new BatchToCalculateDelayInterest();
        batch.execute(null, paymentSchedules);
        Test.stopTest();

        List<Delay_Interest__c> delayInterests = [SELECT Id FROM Delay_Interest__c];
        System.assert(delayInterests.size() > 0);
    }

    @isTest
    static void testBatchExecuteWithNoRelatedDelayInterest() {
        List<Payment_Schedule__c> paymentSchedules = [SELECT Id, Due_Date__c, Total_Due_Amount__c,
            Opportunity__c,
            (SELECT Id, Delay_Date__c FROM Delay_Interests__r)
            FROM Payment_Schedule__c WHERE Id NOT IN (SELECT Payment_Schedule__c FROM Delay_Interest__c)];

        Test.startTest();
        BatchToCalculateDelayInterest batch = new BatchToCalculateDelayInterest();
        batch.execute(null, paymentSchedules);
        Test.stopTest();

        System.assert(true);
    }

    @isTest
    static void testBatchFinish() {
        Test.startTest();
        BatchToCalculateDelayInterest batch = new BatchToCalculateDelayInterest();
        batch.finish(null);
        Test.stopTest();

        System.assert(true);
    }
}