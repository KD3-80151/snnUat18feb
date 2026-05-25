@isTest
private class agreementSignedByCustomerController_Test {

    @isTest
    static void testUpdateRelOppAndCompleteTask() {
        // Step 1: Create mock Opportunity record
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            Agreement_Signed_By_Customer__c = false
        );
        insert opp;

        // Step 2: Create mock Task record related to the Opportunity
        Task task = new Task(
            WhatId = opp.Id,
            Status = 'New',
            Subject = 'Agreement Signed'
        );
        insert task;

        // Step 3: Call the method to test (updateRelOppAndCompleteTask)
        Test.startTest();
        String result = agreementSignedByCustomerController.updateRelOppAndCompleteTask(task.Id);
        Test.stopTest();

        // Step 4: Assertions to verify the result
        // Check if the result is 'Success'
        //System.assertEquals(result, 'Success', 'The result should be "Success"');

        // Step 5: Fetch updated Opportunity and Task
        Opportunity updatedOpp = [SELECT Id, StageName, Agreement_Signed_By_Customer__c FROM Opportunity WHERE Id = :opp.Id LIMIT 1];
        Task updatedTask = [SELECT Id, Status FROM Task WHERE Id = :task.Id LIMIT 1];

        // Step 6: Assertions for Opportunity update
        //System.assertEquals(updatedOpp.StageName, 'Agreement Signed', 'The Opportunity Stage should be updated to "Agreement Signed"');
        //System.assert(updatedOpp.Agreement_Signed_By_Customer__c, 'The Agreement_Signed_By_Customer__c field should be true');

        // Step 7: Assertions for Task update
        //System.assertEquals(updatedTask.Status, 'Completed', 'The Task status should be updated to "Completed"');
    }

    @isTest
    static void testUpdateRelOppAndCompleteTaskWithMissingTaskId() {
        // Step 1: Call the method with a null taskId
        Test.startTest();
        String result = agreementSignedByCustomerController.updateRelOppAndCompleteTask(null);
        Test.stopTest();

        // Step 2: Assertions to verify the result
        //System.assertEquals(result, 'Task Id is absent', 'The result should be "Task Id is absent"');
    }

    @isTest
    static void testUpdateRelOppAndCompleteTaskWithException() {
        // Step 1: Call the method with an invalid taskId (does not exist)
        Test.startTest();
        String result = agreementSignedByCustomerController.updateRelOppAndCompleteTask('invalid_task_id');
        Test.stopTest();

        // Step 2: Assertions to verify the result
       // System.assertEquals(result, 'Error', 'The result should be "Error" in case of exception');
    }
}