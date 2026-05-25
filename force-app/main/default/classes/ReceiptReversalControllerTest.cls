@isTest
public class ReceiptReversalControllerTest {
    
    @testSetup
    static void setupTestData() {
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
    }
    @isTest
    static void testGetRelReceipts() {
		Unit__c unit = [SELECT Id FROM Unit__c LIMIT 1];
        Test.startTest();
        // Call the method
        ReceiptReversalController.receiptWrapper result = ReceiptReversalController.getRelReceipts(unit.Id);
        Test.stopTest();

        // Assertions
        System.assertNotEquals(null, result, 'The result should not be null');
        // System.assertEquals(1, result.relatedReceipts.size(), 'There should be one related receipt');
        // System.assertEquals('Test Receipt', result.relatedReceipts[0].Name, 'The receipt name should match');
    }        
    @isTest
    static void testSaveReceiptChanges() {        
        // Prepare test parameters
        String typeOfChequeSame = 'Same Cheque';
        String typeOfChequeNew = 'New Cheque';
        Date bouncedDate = Date.today();
        String bouncedReason = 'Insufficient Funds';
        List<Receipt__c> testReceipts = [SELECT Id FROM Receipt__c];
        // Test for 'Same Cheque'
        Test.startTest();
        String resultSame = ReceiptReversalController.saveReceiptChanges(testReceipts, typeOfChequeSame, bouncedDate, bouncedReason);
        Test.stopTest();
        
        // Verify results for 'Same Cheque'
        List<Receipt__c> updatedReceiptsSame = [SELECT Bounced_Date__c, Bounced_Reason__c, Status__c FROM Receipt__c WHERE Id IN :testReceipts];
        for (Receipt__c receipt : updatedReceiptsSame) {
            System.assertEquals(bouncedDate, receipt.Bounced_Date__c);
            System.assertEquals(bouncedReason, receipt.Bounced_Reason__c);
            System.assertEquals('Represent', receipt.Status__c);
        }
        System.assertEquals('SUCCESS', resultSame);
    }
    
    @isTest
    static void testNewCheque(){
        // Prepare test parameters
        String typeOfChequeSame = 'Same Cheque';
        String typeOfChequeNew = 'New Cheque';
        Date bouncedDate = Date.today();
        String bouncedReason = 'Insufficient Funds';
		// Test for 'New Cheque'
        List<Receipt__c> testReceipts = [SELECT Id FROM Receipt__c];
        Test.startTest();
        String resultNew = ReceiptReversalController.saveReceiptChanges(testReceipts, typeOfChequeNew, bouncedDate, bouncedReason);
        Test.stopTest();
        
        // Verify results for 'New Cheque'
        List<Receipt__c> updatedReceiptsNew = [SELECT Bounced_Date__c, Bounced_Reason__c, Status__c FROM Receipt__c WHERE Id IN :testReceipts];
        for (Receipt__c receipt : updatedReceiptsNew) {
            System.assertEquals(bouncedDate, receipt.Bounced_Date__c);
            System.assertEquals(bouncedReason, receipt.Bounced_Reason__c);
            System.assertEquals('Bounced/Cancelled', receipt.Status__c);
        }
        System.assertEquals('SUCCESS', resultNew);
    }
}