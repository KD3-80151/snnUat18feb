@isTest
public class TaskAuraHelperTest {
    @isTest
    static void testGetCurrentTaskRecord() {
        
        Task_Master__c taskMaster = new Task_Master__c(
            Object_Type__c = 'Opportunity',
            Task_Subject__c = 'Test Task Subject',
            Action_Type__c = 'Component',
            Action_URL__c = 'http://testactionurl.com'
        );
        insert taskMaster;

        Task testTask = new Task(
            Subject = 'Test Task',
            Remarks__c = 'Test Remarks',
            Description = 'Test Description',
            Current_Task_Status__c = 'New',
            Status = 'Not Started',
            WhoId = null, 
            WhatId = null, 
            ActivityDate = System.today(),
            Task_Master_del__c = taskMaster.Id
        );
        insert testTask;

        Test.startTest();
        Task result = TaskAuraHelper.getCurrentTaskRecord(testTask.Id);
        Test.stopTest();
    }

    @isTest
    static void testGetCurrentTaskRecordInvalidId() {
        Test.startTest();
        Task result = TaskAuraHelper.getCurrentTaskRecord(null);
        Test.stopTest();
    }
}