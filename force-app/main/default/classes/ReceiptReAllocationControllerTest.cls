@isTest
private class ReceiptReAllocationControllerTest {
    @isTest
    static void testFetchCompanyDetails() {
        // Arrange
        Company__c company = new Company__c(Name = 'Test Company');
        insert company;

        // Act
        Test.startTest();
        List<Company__c> companies = ReceiptReAllocationController.fetchCompanyDetails();
        Test.stopTest();

        // Assert
        System.assertNotEquals(null, companies);
        System.assertEquals(1, companies.size());
        System.assertEquals('Test Company', companies[0].Name);
    }

    @isTest
    static void testFetchProjectDetails() {
        // Arrange
        Company__c company = new Company__c(Name = 'Test Company');
        insert company;
        
        Project__c project = new Project__c(Name = 'Test Project', Company__c = company.Id);
        insert project;

        // Act
        Test.startTest();
        List<Project__c> projects = ReceiptReAllocationController.fetchProjectDetails(company.Id);
        Test.stopTest();

        // Assert
        System.assertNotEquals(null, projects);
        System.assertEquals(1, projects.size());
        System.assertEquals('Test Project', projects[0].Name);
    }

    @isTest
    static void testFetchBlockDetails() {
        // Arrange
        Company__c company = new Company__c(Name = 'Test Company');
        insert company;

        Project__c project = new Project__c(Name = 'Test Project', Company__c = company.Id);
        insert project;

        Tower__c tower = new Tower__c(Name = 'Test Tower', Project__c = project.Id);
        insert tower;

        // Act
        Test.startTest();
        List<Tower__c> towers = ReceiptReAllocationController.fetchBlockDetails(project.Id);
        Test.stopTest();

        // Assert
        System.assertNotEquals(null, towers);
        System.assertEquals(1, towers.size());
        System.assertEquals('Test Tower', towers[0].Name);
    }
    @isTest
    static void testGetAllClients() {
		// Setup test data
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
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

        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            Unit__c = unit.Id,
            AccountId = testAccount.Id,
            StageName = 'Closed Won',
            CloseDate = Date.today()
        );
        insert testOpportunity;
        List<Receipt__c> testReceipts = new List<Receipt__c>();
        for (Integer i = 0; i < 1; i++) {
            testReceipts.add(new Receipt__c(
				Receipt_Date__c = Date.today(),
                Amount__c = 100.00,
                Bank__c = 'Test Bank',
                Cheque_Number__c = '123456',
                Cheque_Date__c = Date.today(),
                Opportunity__c = testOpportunity.Id
            ));
        }
        insert testReceipts;
        // Create and insert related Opportunities
        List<Opportunity> opportunities = new List<Opportunity>();
        opportunities.add(new Opportunity(Name = 'Test Opportunity 1', StageName = 'Prospecting', CloseDate = Date.today(), Unit__c = unit.Id));
        opportunities.add(new Opportunity(Name = 'Test Opportunity 2', StageName = 'Prospecting', CloseDate = Date.today(), Unit__c = unit.Id));
        insert opportunities;

        // Test the method
        Test.startTest();
        List<ReceiptReAllocationController.clientWrapper> result = ReceiptReAllocationController.getAllClients(tower.Id);
        Test.stopTest();

        // Assert the results
        // System.assertNotEquals(null, result, 'The result should not be null');
        // System.assertEquals(2, result.size(), 'There should be 2 clients returned');
    }
}