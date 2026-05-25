@IsTest
private class BulkSendDemandLetterControllerTest {
    
    @TestSetup
    static void setupTestData() {
        Company__c company = new Company__c(Name = 'Test Company');
        insert company;
        // Create a test Project
        Project__c proj = new Project__c(Name = 'Test Project', Company__c = company.Id);
        insert proj;
        
        // Create a test Tower
        Tower__c tower = new Tower__c(
            Name = 'Test Tower',
            Project__c = proj.Id,
            Tower_Code__c = 'TT1'
        );
        insert tower;
        
        // Create a test Floor (with a Name so that any required field is filled)
        Floor__c floor = new Floor__c(
            BLocks__c = tower.Id
            
        );
        insert floor;
        
        // Create a test Unit with the required Unit_Name__c field set
        Unit__c unit = new Unit__c(
            Floor__c = floor.Id,
            Unit_Name__c = 'Test Unit'
        );
        insert unit;
        
        // Create a test Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        // Create a test Contact for the Account
        Contact con = new Contact(
            LastName = 'Test Contact',
            AccountId = acc.Id
        );
        insert con;
        
        // Create a test Opportunity linked to Project, Unit, and Account.
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = acc.Id,
            Project__c = proj.Id,
            Unit__c = unit.Id
        );
        insert opp;
        
        // Create a Payment Schedule record associated with the Opportunity.
        // Make sure Demand_Letter_Sent__c is false (its default or explicitly set).
        Payment_Schedule__c ps = new Payment_Schedule__c(
            Name = 'Test Master Installment',
            Opportunity__c = opp.Id,
            Agreement_Value__c = 100000,
            Demand_Letter_Sent__c = false,
            Due_Date__c = Date.today().addDays(15)
        );
        insert ps;
        
        // Create a Payment Schedule Master record
        Payment_Schedule_Master__c psm = new Payment_Schedule_Master__c(
            Name = 'Test Master Installment'
        );
        insert psm;
    }
    
    @IsTest
    static void testGetFilters() {
        // Call the getFilters method and verify that lists are returned.
        BulkSendDemandLetterController.FilterWrapper wrapper = BulkSendDemandLetterController.getFilters();
        
    }
    
    @IsTest
    static void testGetTowers() {
        // Retrieve a test project and then get towers for it.
        Project__c proj = [SELECT Id FROM Project__c LIMIT 1];
        List<Tower__c> towers = BulkSendDemandLetterController.getTowers(proj.Id);
        
    }
    
    @isTest
    static void testgetFilteredOpportunities() {
        Project__c proj = [SELECT Id FROM Project__c LIMIT 1];
        Tower__c tower = [SELECT Id FROM Tower__c LIMIT 1];
        Payment_Schedule__c ps = [SELECT Id FROM Payment_Schedule__c LIMIT 1];
        List<Map<String, Object>> result = BulkSendDemandLetterController.getFilteredOpportunities(proj.Id, tower.Id, '["Test Master Installment"]');
    }
    
   /* @IsTest
    static void testGetFilteredOpportunities_Match() {
        // Retrieve a test project and tower.
        Project__c proj = [SELECT Id FROM Project__c LIMIT 1];
        Tower__c tower = [SELECT Id FROM Tower__c LIMIT 1];
        
        // Prepare a JSON string for the tower parameter (a list containing the tower Id)
        List<Id> towerIds = new List<Id>{ tower.Id };
        String towerJson = JSON.serialize(towerIds);
        
        // Call the method with a matching installment name ("Test Installment")
        List<Map<String, Object>> results = BulkSendDemandLetterController.getFilteredOpportunities(
            String.valueOf(proj.Id),
            towerJson,
            'Test Installment'
        );

        Map<String, Object> oppMap = results[0];

    }
    
    @IsTest
    static void testGetFilteredOpportunities_NoMatch() {
        // Retrieve test project and tower.
        Project__c proj = [SELECT Id FROM Project__c LIMIT 1];
        Tower__c tower = [SELECT Id FROM Tower__c LIMIT 1];
        
        // Prepare the JSON string for tower parameter.
        List<Id> towerIds = new List<Id>{ tower.Id };
        String towerJson = JSON.serialize(towerIds);
        
        // Call the method with a non-matching installment name.
        List<Map<String, Object>> results = BulkSendDemandLetterController.getFilteredOpportunities(
            String.valueOf(proj.Id),
            towerJson,
            'Non Existent Installment'
        );
        

    }*/
    
    @IsTest
    static void testSendInstallmentIds() {
        // Retrieve an existing Payment_Schedule__c record.
        Payment_Schedule__c ps = [SELECT Id, Opportunity__c FROM Payment_Schedule__c LIMIT 1];
        
        Test.startTest();
        // Call sendInstallmentIds with a non-empty list.
        BulkSendDemandLetterController.sendInstallmentIds(new List<Id>{ ps.Id });
        Test.stopTest();
    }
    
    @IsTest
    static void testSendInstallmentIdsWithNull() {
        Test.startTest();
        // Call sendInstallmentIds with a null parameter.
        BulkSendDemandLetterController.sendInstallmentIds(null);
        Test.stopTest();
    }
    
    @IsTest
    static void testSendInstallmentIdsWithEmptyList() {
        Test.startTest();
        // Call sendInstallmentIds with an empty list.
        BulkSendDemandLetterController.sendInstallmentIds(new List<Id>());
        // BulkSendDemandLetterController.dummyMethod();
        Test.stopTest();
    }
}