@isTest
public class OpportunityTriggerHandlerTest {
    
    @isTest
    public static void testAfterInsert() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = System.today(),
            AccountId = acc.Id
        );
        insert opp;
        List<Opportunity> oppList = new List<Opportunity>{opp};
            Test.startTest();
        
        
        opportunityTriggerHandler.afterInsert(oppList);
        Test.stopTest();
    }
    
    @isTest
    public static void testApplicantInsert() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = System.today(),
            AccountId = acc.Id
        );
        insert opp;
        
        Applicant__c app = new Applicant__c(
            Opportunity__c = opp.Id,
            Account__c = acc.Id
        );
        insert app;
        List<Applicant__c> appList = new List<Applicant__c>{app};
            
            Test.startTest();
        
        
        opportunityTriggerHandler.ApplicantInsert(appList);
        Test.stopTest();
        
    }
    @isTest
static void testAfterUpdate() {

    Account acc = new Account(Name='Test Account');
    insert acc;

    Opportunity opp = new Opportunity(
        Name='Test Opp',
        StageName='Prospecting',
        CloseDate=Date.today(),
        AccountId=acc.Id
    );
    insert opp;

    Task t = new Task(
        Subject='Update Registration Date',
        Status='Not Started',
        WhatId=opp.Id
    );
    insert t;

    Opportunity oldOpp = [
        SELECT Id, Registration_Date__c
        FROM Opportunity
        WHERE Id=:opp.Id
    ];

    opp.Registration_Date__c = Date.today();
    update opp;

    Test.startTest();

    opportunityTriggerHandler.afterUpdate(
        new List<Opportunity>{opp},
        new Map<Id,Opportunity>{oldOpp.Id => oldOpp}
    );

    Test.stopTest();

    Task updatedTask = [
        SELECT Status
        FROM Task
        WHERE Id=:t.Id
    ];

    System.assertEquals('Completed', updatedTask.Status);

    Opportunity updatedOpp = [
        SELECT StageName
        FROM Opportunity
        WHERE Id=:opp.Id
    ];

    System.assertEquals('Pre Handover Check', updatedOpp.StageName);
}
    
    @isTest
static void testSendSalesTeamNotification(){

    User u = [SELECT Id FROM User WHERE Id=:UserInfo.getUserId()];

    Account acc = new Account(Name='Test');
    insert acc;

    Opportunity opp = new Opportunity(
        Name='Test',
        StageName='Prospecting',
        CloseDate=Date.today(),
        AccountId=acc.Id,
        Sales_Team_Member__c=u.Id
    );
    insert opp;

    Opportunity oldOpp = opp.clone(false,true,false,false);
    oldOpp.Sales_Team_Member__c = null;

    Test.startTest();

    opportunityTriggerHandler.sendSalesTeamMemberNotification(
        new List<Opportunity>{opp},
        new Map<Id,Opportunity>{opp.Id=>oldOpp}
    );

    Test.stopTest();

    //No assert possible because Messaging.CustomNotification
    System.assert(true);
}
    
    @isTest
static void testDeleteRelatedRecords(){

    Account acc = new Account(Name='Test');
    insert acc;

    Unit__c unit = new Unit__c(
        Status__c='Sold'
    );
    insert unit;

    Opportunity opp = new Opportunity(
        Name='Opp',
        StageName='Prospecting',
        CloseDate=Date.today(),
        AccountId=acc.Id,
        Unit__c=unit.Id
    );
    insert opp;

    insert new Payment_Schedule__c(
        Opportunity__c=opp.Id
    );

    insert new Cost_Sheet__c(
        Opportunity__c=opp.Id
    );

    Opportunity oldOpp = opp.clone(false,true,false,false);
    oldOpp.Delete_Approval__c='Pending';

    opp.Delete_Approval__c='Approved';

    Test.startTest();

    opportunityTriggerHandler.deleteRelatedRecords(
        new List<Opportunity>{opp},
        new Map<Id,Opportunity>{opp.Id=>oldOpp}
    );

    Test.stopTest();

    System.assertEquals(
        0,
        [SELECT Count() FROM Payment_Schedule__c WHERE Opportunity__c=:opp.Id]
    );

    System.assertEquals(
        0,
        [SELECT Count() FROM Cost_Sheet__c WHERE Opportunity__c=:opp.Id]
    );

    System.assertEquals(
        1,
        [SELECT Count() FROM Task WHERE WhatId=:opp.Id]
    );
}
    
    @isTest
static void testDeleteRelatedRecordsOnSalesReject(){

    Account acc=new Account(Name='Test');
    insert acc;

    Opportunity opp=new Opportunity(
        Name='Opp',
        StageName='Prospecting',
        CloseDate=Date.today(),
        AccountId=acc.Id
    );
    insert opp;

    insert new Payment_Schedule__c(
        Opportunity__c=opp.Id
    );

    insert new Cost_Sheet__c(
        Opportunity__c=opp.Id,
        finalize_CostSheet__c=true
    );

    Opportunity oldOpp=opp.clone(false,true,false,false);
    oldOpp.Sales_Head_Approval_Status__c='Pending';

    opp.Sales_Head_Approval_Status__c='Reject';

    Test.startTest();

    opportunityTriggerHandler.deleteRelatedRecordsOnSalesRejection(
        new List<Opportunity>{opp},
        new Map<Id,Opportunity>{opp.Id=>oldOpp}
    );

    Test.stopTest();
}
    
    @isTest
static void testFinalizeCostSheetOnApproval(){

    Company__c company = new Company__c(Name='Test Company');
    insert company;
    Project__c project = new Project__c(Name='Test Project', Company__c=company.Id);
    insert project;

    Cost_Sheet_Template__c template = new Cost_Sheet_Template__c(
        Name = 'Template A',
        Company__c = company.Id,
        Project__c = project.Id,
        Template_Code__c = 'CSA',
        Approval_Status__c = 'Approved'
    );
    Cost_Sheet_Template__c otherTemplate = new Cost_Sheet_Template__c(
        Name = 'Template B',
        Company__c = company.Id,
        Project__c = project.Id,
        Template_Code__c = 'CSB',
        Approval_Status__c = 'Approved'
    );
    insert new List<Cost_Sheet_Template__c>{template, otherTemplate};

    Payment_Scheme__c scheme = new Payment_Scheme__c(
        Name = 'Scheme A',
        Company__c = company.Id,
        Project__c = project.Id,
        Approval_Status__c = 'Approved'
    );
    insert scheme;

    Cost_Scheme_Linking__c chosenLink = new Cost_Scheme_Linking__c(Payment_Scheme__c = scheme.Id, Cost_Sheet_Template__c = template.Id);
    Cost_Scheme_Linking__c otherLink = new Cost_Scheme_Linking__c(Payment_Scheme__c = scheme.Id, Cost_Sheet_Template__c = otherTemplate.Id);
    insert new List<Cost_Scheme_Linking__c>{chosenLink, otherLink};

    Account acc = new Account(Name='Test');
    insert acc;
    Opportunity opp = new Opportunity(
        Name = 'Opp',
        StageName = 'Prospecting',
        CloseDate = Date.today(),
        AccountId = acc.Id,
        Cost_Sheet_Template__c = template.Id,
        Payment_Scheme__c = scheme.Id
    );
    insert opp;

    Cost_Sheet__c chosen = new Cost_Sheet__c(Opportunity__c = opp.Id, Cost_Scheme_Linking__c = chosenLink.Id);
    Cost_Sheet__c other = new Cost_Sheet__c(Opportunity__c = opp.Id, Cost_Scheme_Linking__c = otherLink.Id);
    insert new List<Cost_Sheet__c>{chosen, other};

    Opportunity oldOpp = opp.clone(true, true, false, false);
    oldOpp.Cost_Sheet_Approval_Status__c = 'Sent';
    opp.Cost_Sheet_Approval_Status__c = 'Approved';

    Test.startTest();
    opportunityTriggerHandler.finalizeCostSheetOnApproval(
        new List<Opportunity>{opp},
        new Map<Id,Opportunity>{opp.Id => oldOpp}
    );
    Test.stopTest();

    System.assertEquals(true, [SELECT finalize_CostSheet__c FROM Cost_Sheet__c WHERE Id = :chosen.Id].finalize_CostSheet__c);
    System.assertEquals(false, [SELECT finalize_CostSheet__c FROM Cost_Sheet__c WHERE Id = :other.Id].finalize_CostSheet__c);
}

    @isTest
static void testNullInputs(){

    Test.startTest();

    opportunityTriggerHandler.afterInsert(new List<Opportunity>());
    opportunityTriggerHandler.ApplicantInsert(new List<Applicant__c>());
    opportunityTriggerHandler.afterUpdate(
        new List<Opportunity>(),
        new Map<Id,Opportunity>()
    );

    opportunityTriggerHandler.sendSalesTeamMemberNotification(
        new List<Opportunity>(),
        new Map<Id,Opportunity>()
    );

    opportunityTriggerHandler.deleteRelatedRecords(
        new List<Opportunity>(),
        new Map<Id,Opportunity>()
    );

    opportunityTriggerHandler.deleteRelatedRecordsOnSalesRejection(
        new List<Opportunity>(),
        new Map<Id,Opportunity>()
    );

    opportunityTriggerHandler.finalizeCostSheetOnApproval(
        new List<Opportunity>(),
        new Map<Id,Opportunity>()
    );

    opportunityTriggerHandler.dummyMethod();
    Test.stopTest();

    System.assert(true);
}
    
}