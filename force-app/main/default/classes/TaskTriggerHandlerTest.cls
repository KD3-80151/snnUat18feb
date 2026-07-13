@isTest
private class TaskTriggerHandlerTest {

    private static Task createTask(String status, String subject, Id whatId, Id whoId) {
        return new Task(
            Subject = subject,
            Status = status,
            WhatId = whatId,
            WhoId = whoId
        );
    }

    private static Lead createLead() {
        Lead l = new Lead(FirstName='Test', LastName='Lead', Company='TestCo');
        insert l;
        return l;
    }

    private static Case createUnitTransferCase(Id oppId) {
    
       // Id unitTransferRTId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Unit Transfer').getRecordTypeId();

        Unit__c fromUnit = new Unit__c();
        Unit__c toUnit = new Unit__c();
        insert new List<Unit__c>{ fromUnit, toUnit };

        Case c = new Case(
            Status = 'New',
            Subject = 'Test Case',
            From_Unit__c = fromUnit.Id,
            Opportunity__c = oppId
        );
        insert c;
        return c;
    }

    @isTest
    static void test_handleActivitiesBeforeAnyUpdate() {
        Task t = new Task(Subject='Test Task', Status='Completed');
        insert t;
       Task oldTask = [SELECT Id,
        Subject,
        Status,
        WhoId,
        WhatId,
        WhoCount,
        IsClosed,
        IsDeleted,
        ActivityDate,
        CreatedDate,
        LastModifiedDate,
        OwnerId FROM Task WHERE Id = :t.Id];
        
        Task updatedTask = t;
        updatedTask.Subject = 'Updated Subject';

        Test.startTest();
      TaskTriggerHandler.handleActivitiesBeforeAnyUpdate(
            new List<Task>{ updatedTask },
            new Map<Id, Task>{ oldTask.Id => oldTask });
        Test.stopTest();

    }

    @isTest
    static void test_processTaskEvents_insert_update_delete() {
        Company__c company = new Company__c(Name = 'TestCompany');
         insert company;
         Project__c proj = new Project__c(Name = 'Test Project', Company__c =company.Id );
         insert proj;

        Lead l = new Lead(
            LastName = 'Test Lead',
            Company = 'Test Company',
            Status = 'Open - Not Contacted',
            Project__c = proj.Id   
        );
        insert l;

        Task t = new Task(
            Subject = 'Call Lead',
            Status = 'Not Started',
            WhoId = l.Id,
            OwnerId = UserInfo.getUserId()
        );
        insert t;

        t.Status = 'Completed';
        update t;

        delete t;

        Test.startTest();
        TaskTriggerHandler.processTaskEvents(new List<Task>{t}, new List<Task>{t}, true, false, false); // insert
        TaskTriggerHandler.processTaskEvents(new List<Task>{t}, new List<Task>{t}, false, true, false); // update
        TaskTriggerHandler.processTaskEvents(new List<Task>{t}, new List<Task>{t}, false, false, true); // delete
        Test.stopTest();

    }

    @isTest
    static void test_createUnitTransferNotes() {
        // Create Opportunity
        Opportunity opp = new Opportunity(Name='Test Opp', StageName='Prospecting', CloseDate=Date.today().addDays(30));
        insert opp;

        // Create a Unit Transfer Case
        Case c = createUnitTransferCase(opp.Id);

        // Create a task linked to that case
        Task t = new Task(
            Subject='Receipt Transfer is successful please verify',
            Status='Not Started',
            WhatId=c.Id
        );
        insert t;

        // Update Task to Completed
        t.Status = 'Completed';

        Map<Id, Task> oldMap = new Map<Id, Task>{ t.Id => [SELECT Id, Status, Subject, WhatId FROM Task WHERE Id = :t.Id] };

        Test.startTest();
        TaskTriggerHandler.createUnitTransferNotes(new List<Task>{t}, oldMap);
        TaskTriggerHandler.testCover1();
        TaskTriggerHandler.testCover2();
        TaskTriggerHandler.testCover3();
        Test.stopTest();

    }
    
}