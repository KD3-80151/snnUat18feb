@isTest
private class customerFollowUpControllerTest {

    @testSetup
    static void setupData() {
        Opportunity opp = new Opportunity(
            Name = 'Follow Up Test Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert opp;

        insert new Task(
            Subject = 'Take First Follow Up with Customer - Within 4 Hours',
            WhatId = opp.Id,
            Status = 'Open',
            Priority = 'Normal'
        );
    }

    private static Task getTask() {
        return [SELECT Id, WhatId FROM Task WHERE Subject = 'Take First Follow Up with Customer - Within 4 Hours' LIMIT 1];
    }

    private static Boolean saveThrows(String taskId, String response, String title, String remarks, String lossReason) {
        try {
            customerFollowUpController.saveFollowUp(taskId, response, title, remarks, lossReason);
            return false;
        } catch (AuraHandledException e) {
            return true;
        }
    }

    @isTest
    static void testInterested() {
        Task t = getTask();

        Test.startTest();
        String result = customerFollowUpController.saveFollowUp(t.Id, 'Interested', 'Site visit', 'Customer wants a site visit', null);
        Test.stopTest();

        System.assertEquals('Success', result);

        Opportunity opp = [SELECT Customer_Response__c, StageName FROM Opportunity WHERE Id = :t.WhatId];
        System.assertEquals('Interested', opp.Customer_Response__c);
        System.assertEquals('Prospecting', opp.StageName, 'Stage should not change when interested');

        Communication_Notes__c note = [SELECT Title__c, Remarks__c FROM Communication_Notes__c WHERE Opportunity__c = :t.WhatId];
        System.assertEquals('Site visit', note.Title__c);
        System.assertEquals('Customer wants a site visit', note.Remarks__c);

        System.assertEquals('Completed', [SELECT Status FROM Task WHERE Id = :t.Id].Status);
    }

    @isTest
    static void testNotInterested() {
        Task t = getTask();

        Test.startTest();
        String result = customerFollowUpController.saveFollowUp(t.Id, 'Not Interested', null, 'Budget issue', 'Price');
        Test.stopTest();

        System.assertEquals('Success', result);

        Opportunity opp = [SELECT Customer_Response__c, StageName, Loss_Reason__c FROM Opportunity WHERE Id = :t.WhatId];
        System.assertEquals('Not Interested', opp.Customer_Response__c);
        System.assertEquals('Price', opp.Loss_Reason__c);
        System.assertEquals(customerFollowUpController.LOST_STAGE, opp.StageName);

        Communication_Notes__c note = [SELECT Title__c, Remarks__c FROM Communication_Notes__c WHERE Opportunity__c = :t.WhatId];
        System.assertEquals('Not Interested - Price', note.Title__c);
        System.assertEquals('Budget issue', note.Remarks__c);

        System.assertEquals('Completed', [SELECT Status FROM Task WHERE Id = :t.Id].Status);
    }

    @isTest
    static void testValidationErrors() {
        Task t = getTask();

        Test.startTest();
        System.assert(saveThrows(null, 'Interested', 'T', 'R', null), 'Blank task id should fail');
        System.assert(saveThrows(t.Id, null, 'T', 'R', null), 'Missing response should fail');
        System.assert(saveThrows(t.Id, 'Maybe', 'T', 'R', null), 'Invalid response should fail');
        System.assert(saveThrows(t.Id, 'Interested', '', 'R', null), 'Missing title should fail');
        System.assert(saveThrows(t.Id, 'Interested', 'T', ' ', null), 'Missing remarks should fail');
        System.assert(saveThrows(t.Id, 'Not Interested', null, 'R', null), 'Missing loss reason should fail');
        System.assert(saveThrows(t.Id, 'Not Interested', null, '', 'Price'), 'Missing remarks should fail');
        Test.stopTest();

        // Nothing should have been saved
        System.assertEquals(0, [SELECT COUNT() FROM Communication_Notes__c WHERE Opportunity__c = :t.WhatId]);
        System.assertEquals('Open', [SELECT Status FROM Task WHERE Id = :t.Id].Status);
    }

    @isTest
    static void testTaskWithoutOpportunity() {
        Task orphan = new Task(Subject = 'Orphan Task', Status = 'Open', Priority = 'Normal');
        insert orphan;

        Test.startTest();
        System.assert(saveThrows(orphan.Id, 'Interested', 'T', 'R', null), 'Task without WhatId should fail');
        Test.stopTest();
    }

    @isTest
    static void testUnexpectedException() {
        Test.startTest();
        // An invalid Id string makes the SOQL bind fail, covering the generic catch block
        System.assert(saveThrows('invalidId', 'Interested', 'T', 'R', null), 'Invalid id should fail');
        Test.stopTest();
    }
}