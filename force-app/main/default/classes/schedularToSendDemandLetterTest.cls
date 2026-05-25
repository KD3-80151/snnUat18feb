@isTest
public class schedularToSendDemandLetterTest {

    @isTest
    public static void testSchedulerExecution() {

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Closed Won',
            CloseDate = System.today()
        );
        insert opp;

        Payment_Schedule__c paymentSchedule1 = new Payment_Schedule__c(
            Opportunity__c = opp.Id,
            Due_Date__c = System.today().addDays(-7), 
            Agreement_Value__c = 1000,
            Name = 'Payment 1'
        );
        Payment_Schedule__c paymentSchedule2 = new Payment_Schedule__c(
            Opportunity__c = opp.Id,
            Due_Date__c = System.today().addDays(-7), 
            Agreement_Value__c = 2000,
            Name = 'Payment 2'
        );

        insert new List<Payment_Schedule__c>{paymentSchedule1, paymentSchedule2};

        Test.startTest();

        String cronExpression = '0 0 0 1 1 ? *'; 
        schedularToSendDemandLetter scheduler = new schedularToSendDemandLetter();
        System.schedule('Test Demand Letter Scheduler', cronExpression, scheduler);

        Test.stopTest();

    }
}