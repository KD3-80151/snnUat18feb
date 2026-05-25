@isTest
public class opportunityApprovalProcessTest {

    
    private static User createTestUser(String alias, Id managerId) {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User u = new User(
            FirstName = 'Test',
            LastName = alias,
            Email = alias + '@test.com',
            Username = alias + '@test.com' + System.currentTimeMillis(),
            Alias = alias.substring(0, Math.min(alias.length(), 8)),
            TimeZoneSidKey = 'GMT',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id,
            ManagerId = managerId
        );
        insert u;
        return u;
    }

    @isTest
    static void testGetCRMUsersAndUpdateAssignmentGroup() {
        
        User manager = createTestUser('manager1', null);
       
        User crmUser = createTestUser('crmuser1', manager.Id);

        
        Assignment_Group__c ag = new Assignment_Group__c(
            Name = 'CRM Assignment',
            Last_Allocated_RRid__c = 0
        );
        insert ag;

        
        Assignment_Group_Member__c agm = new Assignment_Group_Member__c(
            Assignment_Group__c = ag.Id,
            Group_Member__c = crmUser.Id,
            Active__c = true,
            BreakTime_Started__c = false,
            Out_Of_Office__c = false,
            Assignment_Id__c = 1
        );
        insert agm;

        //Test.startTest();
        //List<User> users = opportunityApprovalProcess.getCRMUsers();
        //Test.stopTest();

      
        Test.startTest();
        List<User> users = opportunityApprovalProcess.getCRMUsers();
        opportunityApprovalProcess.updateAssignmentGroup(ag.Id, 1);
        Test.stopTest();

        Assignment_Group__c updatedAg = [SELECT Last_Allocated_RRid__c FROM Assignment_Group__c WHERE Id = :ag.Id];
        System.assertEquals(1, updatedAg.Last_Allocated_RRid__c, 'Assignment group should be updated');
    }

    @isTest
    static void testSubmitForApproval_Success() {
        User manager = createTestUser('manager2', null);
        User crmUser = createTestUser('crmuser2', manager.Id);

        
        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),
            OwnerId = crmUser.Id
        );
        insert opp;

        Task t = new Task(
            Subject = 'Approval Task',
            WhatId = opp.Id,
            Status = 'Open'
        );
        insert t;

        Test.startTest();
       
        opportunityApprovalProcess.submitForApproval(t.Id, crmUser.Id);
        Test.stopTest();

        Task updatedTask = [SELECT Status FROM Task WHERE Id = :t.Id];
        System.assertEquals('Completed', updatedTask.Status, 'Task should be marked completed after approval');
    }

    @isTest
    static void testSubmitForApproval_Exception_NoManager() {
        // Create CRM user with NO manager
        User crmUser = createTestUser('crmuser3', null);

        Opportunity opp = new Opportunity(
            Name = 'Opp Without Manager',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(5),
            OwnerId = crmUser.Id
        );
        insert opp;

        Task t = new Task(
            Subject = 'Approval Task',
            WhatId = opp.Id,
            Status = 'Open'
        );
        insert t;

        Boolean exceptionThrown = false;
        try {
            Test.startTest();
            opportunityApprovalProcess.submitForApproval(t.Id, crmUser.Id);
            Test.stopTest();
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }

        System.assertEquals(true, exceptionThrown, 'Should throw exception if manager is missing');
    }
}