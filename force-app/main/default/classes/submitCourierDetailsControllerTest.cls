@isTest
public class submitCourierDetailsControllerTest {

    private static void createTestData() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = acc.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            Email__c = 'test@example.com'
        );
        insert opp;

        Contact con = new Contact(
            FirstName = 'Test',
            LastName = 'User',
            AccountId = acc.Id
        );
        insert con;

        Task task = new Task(
            Subject = 'Test Task',
            Status = 'Not Started',
            WhatId = opp.Id
        );
        insert task;
    }

    @isTest
    static void testGetOppDetails() {
        createTestData();

        Task task = [SELECT Id FROM Task WHERE Subject = 'Test Task' LIMIT 1];

        Test.startTest();
        try {
            Opportunity opp = submitCourierDetailsController.getOppDetails(task.Id);
        } catch (Exception e) {
            System.debug('Exception occurred: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testSaveOppResultOffline() {
        createTestData();

        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];
        Task task = [SELECT Id FROM Task WHERE Subject = 'Test Task' LIMIT 1];

        Test.startTest();
        try {
            submitCourierDetailsController.saveOppResult(
                Date.today(), 
                opp.Id, 
                'Courier Company', 
                'Docket12345', 
                task.Id
            );
        } catch (Exception e) {
            System.debug('Exception occurred: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testSaveOppResultOnline() {
        createTestData();

        // Create a test user to run EmailTemplate DML separately
        User testUser = [SELECT Id FROM User WHERE IsActive = TRUE LIMIT 1];

        Id emailTemplateId;
        System.runAs(testUser) {
            EmailTemplate template = new EmailTemplate(
                Name = 'Send Courier Details',
                DeveloperName = 'Send_Courier_Details_to_Customer',
                HtmlValue = 'Dear {!Opportunity.Name}, your courier is on the way.',
                Subject = 'Courier Details for {!Opportunity.Name}',
                FolderId = UserInfo.getUserId(),
                TemplateType = 'Custom'
            );
            insert template;
            emailTemplateId = template.Id;
        }

        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];
        Task task = [SELECT Id FROM Task WHERE Subject = 'Test Task' LIMIT 1];

        Test.startTest();
        try {
            submitCourierDetailsController.saveOppResult(
                Date.today(), 
                opp.Id, 
                'Courier Company', 
                'Docket12345', 
                task.Id
            );
        } catch (Exception e) {
            System.debug('Exception occurred: ' + e.getMessage());
        }
        Test.stopTest();
    }
}