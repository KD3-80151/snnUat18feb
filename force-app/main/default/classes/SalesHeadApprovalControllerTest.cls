@isTest
public class SalesHeadApprovalControllerTest {
    
    @testSetup
    static void setupTestData() {
        
        List<Profile> profiles = [SELECT Id, Name FROM Profile WHERE Name IN ('Sales Head', 'Sales Executive', 'Sales Manager')];
        Map<String, Id> profileMap = new Map<String, Id>();
        for (Profile p : profiles) {
            profileMap.put(p.Name, p.Id);
        }

        List<User> testUsers = new List<User>();
        if (profileMap.containsKey('Sales Head')) {
            testUsers.add(new User(
                FirstName = 'Test',
                LastName = 'SalesHead',
                Email = 'test.saleshead@example.com',
                Username = 'test.saleshead@example.com.salesforce',
                Alias = 'tsh',
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                ProfileId = profileMap.get('Sales Head'),
                LanguageLocaleKey = 'en_US'
            ));
        }
        if (profileMap.containsKey('Sales Executive')) {
            testUsers.add(new User(
                FirstName = 'Test',
                LastName = 'SalesExec',
                Email = 'test.salesexec@example.com',
                Username = 'test.salesexec@example.com.salesforce',
                Alias = 'tse',
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                ProfileId = profileMap.get('Sales Executive'),
                LanguageLocaleKey = 'en_US'
            ));
        }
        if (profileMap.containsKey('Sales Manager')) {
            testUsers.add(new User(
                FirstName = 'Test',
                LastName = 'SalesMgr',
                Email = 'test.salesmgr@example.com',
                Username = 'test.salesmgr@example.com.salesforce',
                Alias = 'tsm',
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                ProfileId = profileMap.get('Sales Manager'),
                LanguageLocaleKey = 'en_US'
            ));
        }

        insert testUsers;
        
        Profile salesHeadProfile = [SELECT Id FROM Profile WHERE Name = 'Sales Head' LIMIT 1];

        User approver = new User(
            FirstName = 'Test',
            LastName = 'Approver',
            Email = 'test.approver@example.com',
            Username = 'test.approver@example.com.salesforce',
            Alias = 'tapp',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = salesHeadProfile.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert approver;

        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert testOpp;

        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setObjectId(testOpp.Id);
        req.setNextApproverIds(new List<Id>{ approver.Id });
        Approval.ProcessResult result = Approval.process(req);

        ProcessInstance instance = [SELECT Id FROM ProcessInstance WHERE TargetObjectId = :testOpp.Id LIMIT 1];

        ProcessInstanceWorkItem workItem = [SELECT Id FROM ProcessInstanceWorkItem WHERE ProcessInstanceId = :instance.Id LIMIT 1];

        Task testTask = new Task(
            Subject = 'Approval Task',
            WhatId = testOpp.Id,
            Status = 'Not Started'
        );
        insert testTask;
    }

    @isTest
    static void testApproveOrRejectOpp() {
        Task testTask = [SELECT Id, WhatId FROM Task LIMIT 1];
        ProcessInstanceWorkItem testWorkItem = [SELECT Id FROM ProcessInstanceWorkItem LIMIT 1];
        Opportunity testOpp = [SELECT Id, Sales_Head_approval_Status__c FROM Opportunity LIMIT 1];

        List<Opportunity_Team__c> oppTeamList = new List<Opportunity_Team__c> {
            new Opportunity_Team__c(Opportunity__c = testOpp.Id),
            new Opportunity_Team__c(Opportunity__c = testOpp.Id)
        };

        Test.startTest();
        SalesHeadApprovalController.approveOrRejectOpp(testTask.Id, 'Approved', oppTeamList);
        Test.stopTest();

        Opportunity updatedOpp = [SELECT Sales_Head_approval_Status__c FROM Opportunity WHERE Id = :testOpp.Id];
        List<Opportunity_Team__c> insertedOppTeams = [SELECT Id FROM Opportunity_Team__c WHERE Opportunity__c = :testOpp.Id];
    }
    

    @isTest
    static void testFetchUserDetails() {
        Test.startTest();
        
        List<User> wrapper = SalesHeadApprovalController.fetchUserDetails();
        
        Test.stopTest();
    }
}