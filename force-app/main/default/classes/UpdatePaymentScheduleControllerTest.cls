@IsTest
private class UpdatePaymentScheduleControllerTest {
    
    @TestSetup
    static void setup() {
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10)
        );
        insert testOpp;

        List<Payment_Schedule__c> schedules = new List<Payment_Schedule__c>();
        for(Integer i = 0; i < 3; i++) {
            schedules.add(new Payment_Schedule__c(
                Opportunity__c = testOpp.Id,
                Installment__c = i + 1,
                Pay_Date__c = Date.today().addDays(30 * i),
                Agreement_Value__c = 10000,
                Tax_Amount__c = 1000
            ));
        }
        insert schedules;
    }

    @IsTest
    static void testGetPaymentSchedules() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        List<Payment_Schedule__c> schedules = UpdatePaymentScheduleController.getPaymentSchedules(opp.Id);
    }

    @IsTest
    static void testGetPaymentSchedulesWithNullId() {
        try {
            UpdatePaymentScheduleController.getPaymentSchedules(null);
        } catch (Exception e) {
            // Exception handled to cover code path
        }
    }

    @IsTest
    static void testSavePaymentSchedules() {
        List<Payment_Schedule__c> schedules = [SELECT Id,Installment__c FROM Payment_Schedule__c];
        for(Payment_Schedule__c ps : schedules) {
            ps.Installment__c += 1;
        }
        UpdatePaymentScheduleController.savePaymentSchedule(schedules);
    }

    @IsTest
    static void testSavePaymentSchedulesWithEmptyList() {
        try {
            UpdatePaymentScheduleController.savePaymentSchedule(new List<Payment_Schedule__c>());
        } catch (Exception e) {
            // Exception handled to cover code path
        }
    }

    @IsTest
    static void testSavePaymentSchedulesDmlError() {
        Payment_Schedule__c schedule = [SELECT Id FROM Payment_Schedule__c LIMIT 1];
        schedule.Id = null; // Invalidate ID to force DML error
        try {
            UpdatePaymentScheduleController.savePaymentSchedule(new List<Payment_Schedule__c>{schedule});
        } catch (Exception e) {
            // Exception handled to cover DML error path
        }
    }
}