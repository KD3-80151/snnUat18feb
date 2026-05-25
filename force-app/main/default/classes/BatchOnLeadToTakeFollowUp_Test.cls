@isTest(SeeAllData=false)
public class BatchOnLeadToTakeFollowUp_Test {
   @testSetup
static void setupData(){
    Company__c comp = new Company__c(Name = 'Test Company');
    insert comp;
    
    Project__c proj = new Project__c(
        Name = 'Test Project',
        Company__c = comp.Id
    );
    insert proj;
    
    Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];
    
    User u = new User(
        FirstName = 'Only',
        LastName = 'ForBatch',
        Email='onlybatch@test.com',
        Username='onlybatch123@test.com',
        Alias='obat',
        TimeZoneSidKey='Asia/Kolkata',
        LocaleSidKey='en_US',
        EmailEncodingKey='UTF-8',
        LanguageLocaleKey='en_US',
        ProfileId = p.Id
    );
    insert u;
    
    User_Tracking__c utPrev = new User_Tracking__c(
        Member__c = u.Id,
        Checkin_Datetime__c = System.now().addDays(-1).addHours(-5),
        Checkout_Datetime__c = System.now().addDays(-1).addHours(-1)
    );
    insert utPrev;
    
    User_Tracking__c utToday = new User_Tracking__c(
        Member__c = u.Id,
        Checkin_Datetime__c = System.now().addHours(-5),
        Checkout_Datetime__c = null
    );
    insert utToday;
    
    Lead lead120 = new Lead(
        LastName='Lead_120',
        Company='C1',
        Project__c=proj.Id,
        OwnerId=u.Id,
        Is_User_Assigned__c=true,
        Lead_Assigned_Date_Time__c=System.now().addHours(-3)  // ~180
    );
    insert lead120;
    
    Lead lead240 = new Lead(
        LastName='Lead_240',
        Company='C2',
        Project__c=proj.Id,
        OwnerId=u.Id,
        Is_User_Assigned__c=true,
        Lead_Assigned_Date_Time__c=System.now().addHours(-4)  // > 180 (~240)
    );
    insert lead240;

    insert new Task(
        Subject = 'Take First Follow Up with Customer - Within 4 Hours',
        Status = 'Open',
        OwnerId = u.Id,
        WhoId = lead120.Id
    );

    insert new Task(
        Subject = 'Take First Follow Up with Customer - Within 24 Hours',
        Status = 'Open',
        OwnerId = u.Id,
        WhoId = lead240.Id
    );
}

    
    @IsTest
    static void testBatchExecution(){
        Test.startTest();
        Database.executeBatch(new BatchOnLeadToTakeFollowUp(), 50);
        Test.stopTest();
        
    }
}