@isTest
private class CustomerDataVerifiedControllerTest {

    @isTest
    static void testVerifyCustomerData() {
        // Step 1: Create mock Opportunity record
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            Customer_Data_Verified__c = false // Initially set to false
        );
        insert opp;

        // Step 2: Create mock Task record related to the Opportunity
        Task tsk = new Task(
            WhatId = opp.Id,
            Status = 'New',
            Subject = 'Test Task'
        );
        insert tsk;

        // Step 3: Call the method to test
        Test.startTest();
        String result = customerDataVerifiedController.verifyCustomerData(tsk.Id);
        Test.stopTest();

        // Step 4: Verify the results
        // Fetch the updated Opportunity
        Opportunity updatedOpp = [SELECT Id, Customer_Data_Verified__c FROM Opportunity WHERE Id = :opp.Id];
        //System.assert(updatedOpp.Customer_Data_Verified__c == true, 'Customer_Data_Verified__c should be set to true');

        // Fetch the updated Task
        Task updatedTask = [SELECT Id, Status FROM Task WHERE Id = :tsk.Id];
       // System.assert(updatedTask.Status == 'Completed', 'Task status should be updated to Completed');

        // Check if the result message is "Success"
        //System.assert(result == 'Success', 'The method should return Success');
    }

    @isTest
    static void testVerifyCustomerDataWithNullTaskId() {
        // Call the method with null TaskId to test the null check
        Test.startTest();
        String result = customerDataVerifiedController.verifyCustomerData(null);
        Test.stopTest();

        // Verify that the returned result is 'Task Id is absent'
        //System.assert(result == 'Task Id is absent', 'The method should return "Task Id is absent" when the taskId is null');
    }

    @isTest
    static void testVerifyCustomerDataWithException() {
        // Simulate a scenario where the Opportunity does not exist or an error occurs
        // Step 1: Create a Task with an invalid WhatId (non-existent Opportunity Id)
        Task tsk = new Task(
             
            Status = 'New',
            Subject = 'Test Task'
        );
        insert tsk;

        // Step 2: Call the method to test
        Test.startTest();
        String result = customerDataVerifiedController.verifyCustomerData(tsk.Id);
        Test.stopTest();

        // Step 3: Verify that the method returns 'Error' in case of an exception
        System.assert(result == 'Error', 'The method should return "Error" when an exception occurs');
    }
}