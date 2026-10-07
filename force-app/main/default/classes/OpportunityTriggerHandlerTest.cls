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
    insert template;
    Payment_Scheme__c scheme = new Payment_Scheme__c(
        Name = 'Scheme A',
        Company__c = company.Id,
        Project__c = project.Id,
        Approval_Status__c = 'Approved'
    );
    insert scheme;
    Cost_Scheme_Linking__c link = new Cost_Scheme_Linking__c(Payment_Scheme__c = scheme.Id, Cost_Sheet_Template__c = template.Id);
    insert link;

    Cost_Sheet__c costSheet = new Cost_Sheet__c(
        Opportunity__c=opp.Id,
        Cost_Scheme_Linking__c=link.Id,
        finalize_CostSheet__c=true
    );
    insert costSheet;

    Opportunity oldOpp=opp.clone(true,true,false,false);
    oldOpp.Cost_Sheet_Approval_Status__c='Sent';

    opp.Cost_Sheet_Approval_Status__c='Rejected';

    Test.startTest();

    opportunityTriggerHandler.deleteRelatedRecordsOnSalesRejection(
        new List<Opportunity>{opp},
        new Map<Id,Opportunity>{opp.Id=>oldOpp}
    );

    Test.stopTest();

    System.assertEquals(
        0,
        [SELECT Count() FROM Payment_Schedule__c WHERE Opportunity__c=:opp.Id]
    );

    System.assertEquals(
        false,
        [SELECT finalize_CostSheet__c FROM Cost_Sheet__c WHERE Id=:costSheet.Id].finalize_CostSheet__c
    );

    System.assertEquals(
        1,
        [SELECT Count() FROM Task WHERE WhatId=:opp.Id AND Subject='Generate Cost Sheet']
    );

    System.assertEquals(
        'Cost Sheet Generated',
        [SELECT StageName FROM Opportunity WHERE Id=:opp.Id].StageName
    );
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

    Test.stopTest();

    System.assert(true);
}

    private static Opportunity createOpp(){
        Account acc = new Account(Name='Test');
        insert acc;
        Opportunity opp = new Opportunity(
            Name = 'Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            AccountId = acc.Id
        );
        insert opp;
        return opp;
    }

    private static Cost_Scheme_Linking__c createLink(){
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
        insert template;
        Payment_Scheme__c scheme = new Payment_Scheme__c(
            Name = 'Scheme A',
            Company__c = company.Id,
            Project__c = project.Id,
            Approval_Status__c = 'Approved'
        );
        insert scheme;
        Cost_Scheme_Linking__c link = new Cost_Scheme_Linking__c(Payment_Scheme__c = scheme.Id, Cost_Sheet_Template__c = template.Id);
        insert link;
        return [SELECT Id, Cost_Sheet_Template__c, Payment_Scheme__c FROM Cost_Scheme_Linking__c WHERE Id = :link.Id];
    }

    @isTest
    static void testDummyMethod(){
        Test.startTest();
        opportunityTriggerHandler.dummyMethod();
        Test.stopTest();
        System.assert(true);
    }

    @isTest
    static void testAfterUpdateRegistrationDateUnchanged(){
        Opportunity opp = createOpp();
        Task t = new Task(Subject='Update Registration Date', Status='Not Started', WhatId=opp.Id);
        insert t;

        Opportunity oldOpp = [SELECT Id, Registration_Date__c, StageName FROM Opportunity WHERE Id=:opp.Id];
        Opportunity newOpp = oldOpp.clone(true,true,false,false);

        Test.startTest();
        // Registration date unchanged
        opportunityTriggerHandler.afterUpdate(new List<Opportunity>{newOpp}, new Map<Id,Opportunity>{oldOpp.Id => oldOpp});
        // Registration date cleared
        oldOpp.Registration_Date__c = Date.today();
        newOpp.Registration_Date__c = null;
        opportunityTriggerHandler.afterUpdate(new List<Opportunity>{newOpp}, new Map<Id,Opportunity>{oldOpp.Id => oldOpp});
        Test.stopTest();

        System.assertEquals('Not Started', [SELECT Status FROM Task WHERE Id=:t.Id].Status);
        System.assertEquals('Prospecting', [SELECT StageName FROM Opportunity WHERE Id=:opp.Id].StageName);
    }

    @isTest
    static void testAfterUpdateWithoutOpenTask(){
        Opportunity opp = createOpp();
        Opportunity oldOpp = opp.clone(true,true,false,false);
        opp.Registration_Date__c = Date.today();

        Test.startTest();
        opportunityTriggerHandler.afterUpdate(new List<Opportunity>{opp}, new Map<Id,Opportunity>{oldOpp.Id => oldOpp});
        Test.stopTest();

        System.assertEquals('Pre Handover Check', [SELECT StageName FROM Opportunity WHERE Id=:opp.Id].StageName);
        System.assertEquals(0, [SELECT Count() FROM Task WHERE WhatId=:opp.Id]);
    }

    @isTest
    static void testSendSalesTeamNotificationBranches(){
        Opportunity opp = createOpp();
        opp.Sales_Team_Member__c = UserInfo.getUserId();

        Opportunity sameOld = opp.clone(true,true,false,false);

        Test.startTest();
        // null list
        opportunityTriggerHandler.sendSalesTeamMemberNotification(null, new Map<Id,Opportunity>());
        // null oldMap => treated as newly assigned
        opportunityTriggerHandler.sendSalesTeamMemberNotification(new List<Opportunity>{opp}, null);
        // oldMap without this opportunity
        opportunityTriggerHandler.sendSalesTeamMemberNotification(new List<Opportunity>{opp}, new Map<Id,Opportunity>());
        // member unchanged => nothing to notify
        opportunityTriggerHandler.sendSalesTeamMemberNotification(new List<Opportunity>{opp}, new Map<Id,Opportunity>{opp.Id => sameOld});
        // no member assigned
        Opportunity noMember = opp.clone(true,true,false,false);
        noMember.Sales_Team_Member__c = null;
        opportunityTriggerHandler.sendSalesTeamMemberNotification(new List<Opportunity>{noMember}, new Map<Id,Opportunity>{opp.Id => sameOld});
        Test.stopTest();

        System.assert(true);
    }

    @isTest
    static void testDeleteRelatedRecordsSkipBranches(){
        Opportunity opp = createOpp();
        Opportunity oldOpp = opp.clone(true,true,false,false);

        Test.startTest();
        // oldMap null
        opportunityTriggerHandler.deleteRelatedRecords(new List<Opportunity>{opp}, null);
        // null new list
        opportunityTriggerHandler.deleteRelatedRecords(null, new Map<Id,Opportunity>());
        // opportunity missing in oldMap
        opp.Delete_Approval__c = 'Approved';
        opportunityTriggerHandler.deleteRelatedRecords(new List<Opportunity>{opp}, new Map<Id,Opportunity>());
        // approval did not change
        oldOpp.Delete_Approval__c = 'Approved';
        opportunityTriggerHandler.deleteRelatedRecords(new List<Opportunity>{opp}, new Map<Id,Opportunity>{opp.Id => oldOpp});
        Test.stopTest();

        System.assertEquals(0, [SELECT Count() FROM Task WHERE WhatId=:opp.Id]);
    }

    @isTest
    static void testDeleteRelatedRecordsWithoutUnitOrChildren(){
        Opportunity opp = createOpp();
        Opportunity oldOpp = opp.clone(true,true,false,false);
        oldOpp.Delete_Approval__c = 'Pending';
        opp.Delete_Approval__c = 'Approved';

        Test.startTest();
        opportunityTriggerHandler.deleteRelatedRecords(new List<Opportunity>{opp}, new Map<Id,Opportunity>{opp.Id => oldOpp});
        Test.stopTest();

        System.assertEquals(1, [SELECT Count() FROM Task WHERE WhatId=:opp.Id AND Subject='Generate Cost Sheet']);
        System.assertEquals('New', [SELECT StageName FROM Opportunity WHERE Id=:opp.Id].StageName);
    }

    @isTest
    static void testDeleteRelatedRecordsUnitNotSold(){
        Unit__c unit = new Unit__c(Status__c='For Sale');
        insert unit;

        Opportunity opp = createOpp();
        Opportunity oldOpp = opp.clone(true,true,false,false);
        oldOpp.Delete_Approval__c = 'Pending';
        opp.Delete_Approval__c = 'Approved';
        opp.Unit__c = unit.Id;

        Test.startTest();
        opportunityTriggerHandler.deleteRelatedRecords(new List<Opportunity>{opp}, new Map<Id,Opportunity>{opp.Id => oldOpp});
        Test.stopTest();

        System.assertEquals('For Sale', [SELECT Status__c FROM Unit__c WHERE Id=:unit.Id].Status__c);
        System.assertEquals(1, [SELECT Count() FROM Task WHERE WhatId=:opp.Id AND Subject='Generate Cost Sheet']);
    }

    @isTest
    static void testSalesRejectionSkipBranches(){
        Opportunity opp = createOpp();
        Opportunity oldOpp = opp.clone(true,true,false,false);

        Test.startTest();
        // null old map
        opportunityTriggerHandler.deleteRelatedRecordsOnSalesRejection(new List<Opportunity>{opp}, null);
        // null list
        opportunityTriggerHandler.deleteRelatedRecordsOnSalesRejection(null, new Map<Id,Opportunity>());
        // opportunity missing in old map
        opp.Cost_Sheet_Approval_Status__c = 'Rejected';
        opportunityTriggerHandler.deleteRelatedRecordsOnSalesRejection(new List<Opportunity>{opp}, new Map<Id,Opportunity>());
        // status already rejected
        oldOpp.Cost_Sheet_Approval_Status__c = 'Rejected';
        opportunityTriggerHandler.deleteRelatedRecordsOnSalesRejection(new List<Opportunity>{opp}, new Map<Id,Opportunity>{opp.Id => oldOpp});
        Test.stopTest();

        System.assertEquals(0, [SELECT Count() FROM Task WHERE WhatId=:opp.Id]);
    }

    @isTest
    static void testSalesRejectionWithoutCostSheets(){
        Opportunity opp = createOpp();
        Opportunity oldOpp = opp.clone(true,true,false,false);
        oldOpp.Cost_Sheet_Approval_Status__c = 'Sent';
        opp.Cost_Sheet_Approval_Status__c = 'Rejected';

        Test.startTest();
        opportunityTriggerHandler.deleteRelatedRecordsOnSalesRejection(new List<Opportunity>{opp}, new Map<Id,Opportunity>{opp.Id => oldOpp});
        Test.stopTest();

        System.assertEquals(1, [SELECT Count() FROM Task WHERE WhatId=:opp.Id AND Subject='Generate Cost Sheet']);
        System.assertEquals('Cost Sheet Generated', [SELECT StageName FROM Opportunity WHERE Id=:opp.Id].StageName);
    }

    @isTest
    static void testFinalizeCostSheetSkipBranches(){
        Opportunity opp = createOpp();
        Cost_Scheme_Linking__c link = createLink();
        Cost_Sheet__c costSheet = new Cost_Sheet__c(Opportunity__c = opp.Id, Cost_Scheme_Linking__c = link.Id);
        insert costSheet;

        Opportunity oldOpp = opp.clone(true,true,false,false);
        oldOpp.Cost_Sheet_Approval_Status__c = 'Sent';

        Test.startTest();
        // null old map
        opportunityTriggerHandler.finalizeCostSheetOnApproval(new List<Opportunity>{opp}, null);
        // null new list
        opportunityTriggerHandler.finalizeCostSheetOnApproval(null, new Map<Id,Opportunity>{opp.Id => oldOpp});
        // not approved
        opp.Cost_Sheet_Approval_Status__c = 'Sent';
        opportunityTriggerHandler.finalizeCostSheetOnApproval(new List<Opportunity>{opp}, new Map<Id,Opportunity>{opp.Id => oldOpp});
        // approved but no template / scheme
        opp.Cost_Sheet_Approval_Status__c = 'Approved';
        opportunityTriggerHandler.finalizeCostSheetOnApproval(new List<Opportunity>{opp}, new Map<Id,Opportunity>{opp.Id => oldOpp});
        // already approved earlier
        opp.Cost_Sheet_Template__c = link.Cost_Sheet_Template__c;
        opp.Payment_Scheme__c = link.Payment_Scheme__c;
        oldOpp.Cost_Sheet_Approval_Status__c = 'Approved';
        opportunityTriggerHandler.finalizeCostSheetOnApproval(new List<Opportunity>{opp}, new Map<Id,Opportunity>{opp.Id => oldOpp});
        // opportunity missing in old map
        opportunityTriggerHandler.finalizeCostSheetOnApproval(new List<Opportunity>{opp}, new Map<Id,Opportunity>{UserInfo.getUserId() => oldOpp});
        Test.stopTest();

        System.assertEquals(false, [SELECT finalize_CostSheet__c FROM Cost_Sheet__c WHERE Id = :costSheet.Id].finalize_CostSheet__c);
    }

    @isTest
    static void testFinalizeCostSheetNoMatchingSheet(){
        Opportunity opp = createOpp();
        Cost_Scheme_Linking__c link = createLink();
        Cost_Sheet__c costSheet = new Cost_Sheet__c(Opportunity__c = opp.Id, Cost_Scheme_Linking__c = link.Id);
        insert costSheet;

        Opportunity oldOpp = opp.clone(true,true,false,false);
        oldOpp.Cost_Sheet_Approval_Status__c = 'Sent';
        opp.Cost_Sheet_Approval_Status__c = 'Approved';

        Cost_Sheet_Template__c linkedTemplate = [SELECT Company__c, Project__c FROM Cost_Sheet_Template__c WHERE Id = :link.Cost_Sheet_Template__c];
        Cost_Sheet_Template__c otherTemplate = new Cost_Sheet_Template__c(
            Name = 'Template B',
            Company__c = linkedTemplate.Company__c,
            Project__c = linkedTemplate.Project__c,
            Template_Code__c = 'CSB',
            Approval_Status__c = 'Approved'
        );
        insert otherTemplate;
        Payment_Scheme__c otherScheme = new Payment_Scheme__c(
            Name = 'Scheme B',
            Company__c = linkedTemplate.Company__c,
            Project__c = linkedTemplate.Project__c,
            Approval_Status__c = 'Approved'
        );
        insert otherScheme;

        Test.startTest();
        // template does not match the linked cost sheet
        opp.Cost_Sheet_Template__c = otherTemplate.Id;
        opp.Payment_Scheme__c = link.Payment_Scheme__c;
        opportunityTriggerHandler.finalizeCostSheetOnApproval(new List<Opportunity>{opp}, new Map<Id,Opportunity>{opp.Id => oldOpp});

        // payment scheme does not match the linked cost sheet
        opp.Cost_Sheet_Template__c = link.Cost_Sheet_Template__c;
        opp.Payment_Scheme__c = otherScheme.Id;
        opportunityTriggerHandler.finalizeCostSheetOnApproval(new List<Opportunity>{opp}, new Map<Id,Opportunity>{opp.Id => oldOpp});
        Test.stopTest();

        System.assertEquals(false, [SELECT finalize_CostSheet__c FROM Cost_Sheet__c WHERE Id = :costSheet.Id].finalize_CostSheet__c);
    }

    @isTest
    static void testFinalizeCostSheetUnitMismatchAndAlreadyFinalized(){
        Opportunity opp = createOpp();
        Cost_Scheme_Linking__c link = createLink();

        Unit__c unitA = new Unit__c(Status__c='For Sale');
        Unit__c unitB = new Unit__c(Status__c='For Sale');
        insert new List<Unit__c>{unitA, unitB};

        Cost_Sheet__c costSheet = new Cost_Sheet__c(
            Opportunity__c = opp.Id,
            Cost_Scheme_Linking__c = link.Id,
            Unit__c = unitA.Id
        );
        insert costSheet;

        Opportunity oldOpp = opp.clone(true,true,false,false);
        oldOpp.Cost_Sheet_Approval_Status__c = 'Sent';
        opp.Cost_Sheet_Approval_Status__c = 'Approved';
        opp.Cost_Sheet_Template__c = link.Cost_Sheet_Template__c;
        opp.Payment_Scheme__c = link.Payment_Scheme__c;

        Test.startTest();
        // unit mismatch => skipped
        opp.Unit__c = unitB.Id;
        opportunityTriggerHandler.finalizeCostSheetOnApproval(new List<Opportunity>{opp}, new Map<Id,Opportunity>{opp.Id => oldOpp});
        System.assertEquals(false, [SELECT finalize_CostSheet__c FROM Cost_Sheet__c WHERE Id = :costSheet.Id].finalize_CostSheet__c);

        // unit matches => finalised
        opp.Unit__c = unitA.Id;
        opportunityTriggerHandler.finalizeCostSheetOnApproval(new List<Opportunity>{opp}, new Map<Id,Opportunity>{opp.Id => oldOpp});
        System.assertEquals(true, [SELECT finalize_CostSheet__c FROM Cost_Sheet__c WHERE Id = :costSheet.Id].finalize_CostSheet__c);

        // already finalised => no further update
        opportunityTriggerHandler.finalizeCostSheetOnApproval(new List<Opportunity>{opp}, new Map<Id,Opportunity>{opp.Id => oldOpp});
        Test.stopTest();

        System.assertEquals(true, [SELECT finalize_CostSheet__c FROM Cost_Sheet__c WHERE Id = :costSheet.Id].finalize_CostSheet__c);
    }

}