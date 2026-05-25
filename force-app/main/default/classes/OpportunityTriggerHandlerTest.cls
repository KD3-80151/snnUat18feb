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
    static void testAfterUpdate(){
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
        Opportunity opp2 = new Opportunity(
            Id = opp.Id,
            Name = 'Test opp',
            StageName = 'Prospecting',
            CloseDate = System.today().addDays(-1),
            AccountId = acc.Id,
            Registration_Date__c = Date.today()
        );
        update opp2;
        Map<Id,Opportunity> oppListOld = new Map<Id,Opportunity>();
        oppListOld.put(opp2.Id,opp2);
        Test.startTest();
        opportunityTriggerHandler.afterUpdate(oppList,oppListOld);
        Test.stopTest();
    }
}