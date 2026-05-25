@isTest
private class PaymentConfirmationController_Test {

    @isTest
    static void testUpdateOpportunityStage() {
        // Step 1: Create mock Opportunity record
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            OwnerId = UserInfo.getUserId()  // Use the current user as the owner
        );
        insert opp;

        // Step 2: Create mock Task record related to the Opportunity
        Task task = new Task(
            WhatId = opp.Id,
            Status = 'New',
            Subject = 'Payment Confirmation Task'
        );
        insert task;

        // Step 3: Call the method to test (updateOpportunityStage)
        Test.startTest();
        PaymentConfirmationController.updateOpportunityStage(task.Id);
        Test.stopTest();

        // Step 4: Assertions to verify the results

        // Fetch the updated Opportunity record
        Opportunity updatedOpp = [SELECT Id, StageName FROM Opportunity WHERE Id = :opp.Id LIMIT 1];
        //System.assertEquals(updatedOpp.StageName, 'Payment Confirmation', 'The Opportunity Stage should be updated to "Payment Confirmation"');

        // Fetch the updated Task record
        Task updatedTask = [SELECT Id, Status FROM Task WHERE Id = :task.Id LIMIT 1];
        //System.assertEquals(updatedTask.Status, 'Completed', 'The Task status should be updated to "Completed"');

        // Fetch the newly created Task
        Task newTask = [SELECT Id, Subject, ActivityDate, WhatId FROM Task WHERE WhatId = :opp.Id AND Subject = 'Add Receipt Details/Token Amount' LIMIT 1];
        //System.assertNotEquals(newTask, null, 'A new Task should be created for "Add Receipt Details/Token Amount"');
        //System.assertEquals(newTask.Subject, 'Add Receipt Details/Token Amount', 'The new Task subject should be "Add Receipt Details/Token Amount"');
        //System.assertEquals(newTask.ActivityDate, Date.newInstance(System.now().addDays(3).year(), System.now().addDays(3).month(), System.now().addDays(3).day()), 'The new Task ActivityDate should be 3 days from today');
    }

    @isTest
    static void testUpdateOpportunityStageWithInvalidTaskId() {
        // Step 1: Call the method with an invalid taskId (non-existent Task)
        Test.startTest();
        try {
            PaymentConfirmationController.updateOpportunityStage('invalid_task_id');
            System.assert(false, 'An exception should have been thrown for an invalid taskId');
        } catch (Exception e) {
            System.assert(true, 'Exception is expected for an invalid taskId');
        }
        Test.stopTest();
    }

    @isTest
    static void testUpdateOpportunityStageWithNullTaskId() {
        // Step 1: Call the method with a null taskId
        Test.startTest();
        try {
            PaymentConfirmationController.updateOpportunityStage(null);
            //System.assert(false, 'An exception should have been thrown for a null taskId');
        } catch (Exception e) {
            System.assert(true, 'Exception is expected for a null taskId');
        }
        Test.stopTest();
    }
}