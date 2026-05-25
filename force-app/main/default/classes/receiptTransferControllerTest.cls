@isTest
private class receiptTransferControllerTest {
    
    @testSetup
    static void setupTestData() {
		// Setup test data
		Account fromAccount = new Account(Name = 'From Account');
        insert fromAccount;

        Account toAccount = new Account(Name = 'To Account');
        insert toAccount;

        Opportunity fromOpportunity = new Opportunity(
            Name = 'From Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            AccountId = fromAccount.Id
        );
        insert fromOpportunity;

        Opportunity toOpportunity = new Opportunity(
            Name = 'To Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            AccountId = toAccount.Id
        );
        insert toOpportunity;
        
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
            Blocks__c = tower.Id
            
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
    }

    @isTest
    static void testFetchProjectDetails() {
        // Act
        List<Project__c> result = receiptTransferController.fetchProjectDetails();

        // Assert
        System.assertNotEquals(null, result, 'Project list should not be null');
        System.assertEquals(1, result.size(), 'Project list should contain one project');
        System.assertEquals('Test Project', result[0].Name, 'Project name should match');
    }

    @isTest
    static void testFetchTowerDetails() {
        List<Project__c> project = [SELECT ID FROM Project__c];
        // Act
        List<Tower__c> result = receiptTransferController.fetchTowerDetails(project[0].Id);

        // Assert
        System.assertNotEquals(null, result, 'Tower list should not be null');
        System.assertEquals(1, result.size(), 'Tower list should contain one tower');
        System.assertEquals('TT1', result[0].Tower_Code__c, 'Tower code should match');
    }
    
    @isTest
    static void testFetchAccDetails() {
		List<Tower__c> block = [SELECT Id FROM Tower__c];
        String blockId = block[0].Id;

        // Call the method
        Test.startTest();
        List<Account> result = receiptTransferController.fetchAccDetails(blockId);
        Test.stopTest();

        // Assert the results
        System.assertNotEquals(null, result, 'The result should not be null');
        System.assertEquals(1, result.size(), 'There should be one account returned');
        // System.assertEquals(testAccount.Id, result[0].Id, 'The returned account should match the test account');
    }
    
    @isTest
    static void testFetchOpportunityDetails() {
		List<Tower__c> testBlock = [SELECT Id FROM Tower__c];
        Test.startTest();
        List<Opportunity> opportunities = receiptTransferController.fetchOpportunityDetails(testBlock[0].Id);
        Test.stopTest();

        System.assertNotEquals(null, opportunities, 'The returned opportunity list should not be null');
        System.assertEquals(1, opportunities.size(), 'The opportunity list should be 1 as 1 opportunities are created yet');
    }
    
    @isTest
    static void testFetchOppDetails() {
        List<Account> fromAccount = [SELECT ID FROM Account WHERE Name = 'From Account'];
        List<Account> toAccount = [SELECT Id FROM Account WHERE Name = 'To Account'];
        List<Opportunity> fromOpportunity = [SELECT Id FROM Opportunity WHERE Name = 'From Opportunity'];
        List<Opportunity> toOpportunity = [SELECT Id FROM Opportunity WHERE Name = 'To Opportunity'];

        Test.startTest();
        ReceiptTransferController.oppWrapper result1 = ReceiptTransferController.fetchOppDetails(fromAccount[0].Id, toAccount[0].Id, fromOpportunity[0].Id, toOpportunity[0].Id);
        ReceiptTransferController.oppWrapper result2 = ReceiptTransferController.fetchOppDetails(fromAccount[0].Id, toAccount[0].Id, fromOpportunity[0].Id, null);
        ReceiptTransferController.oppWrapper result3 = ReceiptTransferController.fetchOppDetails(fromAccount[0].Id, toAccount[0].Id, null, toOpportunity[0].Id);
        Test.stopTest();

        System.assertNotEquals(null, result1, 'The result should not be null');
    }
    
    @isTest
    static void testCreateTransferLog_withLineItems() {
        // Arrange: Prepare Transfer Log
        List<Project__c> proj = [SELECT Id FROM Project__c];
        List<TOwer__c> block = [SELECT Id FROM Tower__c];
        List<Account> fromAccount = [SELECT ID FROM Account WHERE Name = 'From Account'];
        List<Account> toAccount = [SELECT Id FROM Account WHERE Name = 'To Account'];
        List<Opportunity> fromOpportunity = [SELECT Id FROM Opportunity WHERE Name = 'From Opportunity'];
        List<Opportunity> toOpportunity = [SELECT Id FROM Opportunity WHERE Name = 'To Opportunity'];
        Receipt_Transfer_Log__c transferLog = new Receipt_Transfer_Log__c(
            From_Project__c = proj[0].Id,
            From_Block__c = block[0].Id,
            From_Client__c = fromAccount[0].Id,
            Remarks__c = 'remarks',
            Transfer_Date__c = System.today(),
            To_Project__c = proj[0].Id,
            To_Block__c = block[0].Id,
            To_Client__c = toAccount[0].Id
        );
		List<Receipt__c> receipt = [SELECT Id FROm Receipt__c];
        List<Receipt_Transfer_Log_LineItem__c> logItems = new List<Receipt_Transfer_Log_LineItem__c>{
            new Receipt_Transfer_Log_LineItem__c(
                Receipt__c = receipt[0].Id,
                From_Opportunity__c = fromOpportunity[0].Id,
                To_Opportunity__c = toOpportunity[0].Id
            )
        };

        // Act
        Test.startTest();
        ReceiptTransferController.createTransferLog(logItems, transferLog);
        Test.stopTest();
    }
}