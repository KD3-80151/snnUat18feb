@isTest
private class editPricingOnOpportunityControllerTest {
    @testSetup
    static void setup() {
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User adminUser = new User(
            Alias = 'adminusr',
            Email = 'admin@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Admin',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = adminProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'adminusr@test.com'
        );
        insert adminUser;
        
        Profile userProfile = [SELECT Id FROM Profile WHERE Name != 'System Administrator' AND Name != 'Admin' LIMIT 1];
        User normalUser = new User(
            Alias = 'normusr',
            Email = 'normal@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Normal',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = userProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'normalusr@test.com'
        );
        insert normalUser;
        
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'New',
            CloseDate = Date.today().addDays(10),
            Cost_Sheet_Approval_Status__c = 'Pending',
            Cost_Sheet_Finalised__c = true
        );
        insert testOpp;
        
        Opportunity testOpp1 = new Opportunity(
            Name = 'Test Opportunity 1',
            StageName = 'Closed Won', // Stage NOT in the expected list
            CloseDate = Date.today().addDays(10),
            Cost_Sheet_Approval_Status__c = 'Pending',
            Cost_Sheet_Finalised__c = true
        );
        insert testOpp1;
        
        Opportunity testOpp2 = new Opportunity(
            Name = 'Test Opportunity 2',
            StageName = 'New',
            CloseDate = Date.today().addDays(10),
            Cost_Sheet_Approval_Status__c = 'Approved', // Approved to trigger return '3'
            Cost_Sheet_Finalised__c = true
        );
        insert testOpp2;
        
        Cost_Sheet__c costSheet = new Cost_Sheet__c(
            Opportunity__c = testOpp.Id,
            finalize_CostSheet__c = true
        );
        insert costSheet;
        
        Pricing_Element__c pricingElement = new Pricing_Element__c(
            Cost_Sheet__c = costSheet.Id,
            Unit__c = 'LS',
            Quantity__c = 1,
            Rate__c = 100,
            Amount__c = 100,
            Tax_Amount__c = 10,
            Discount_Amount__c = 5,
            PE_Type__c = 'Formula'
        );
        insert pricingElement;
    }
    
    @isTest
    static void testGetAccess() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        User adminUser = [SELECT Id FROM User WHERE Username = 'adminusr@test.com' LIMIT 1];
        System.runAs(adminUser) {
            Test.startTest();
            String result = editPricingOnOpportunityController.getAccess(testOpp.Id);
            Test.stopTest();
            
        }
    }
    
    @isTest
    static void testGetAccess_Returns2() {
        Opportunity testOpp = [SELECT Id FROM Opportunity WHERE StageName = 'Closed Won' LIMIT 1];
        User adminUser = [SELECT Id FROM User WHERE Username = 'adminusr@test.com' LIMIT 1];
        System.runAs(adminUser) {
            Test.startTest();
            String result = editPricingOnOpportunityController.getAccess(testOpp.Id);
            Test.stopTest();
            System.assertEquals('2', result);
        }
    }
    
    @isTest
    static void testGetAccess_Returns3() {
        Opportunity testOpp = [SELECT Id FROM Opportunity WHERE Cost_Sheet_Approval_Status__c = 'Approved' LIMIT 1];
        User normalUser = [SELECT Id FROM User WHERE Username = 'normalusr@test.com' LIMIT 1];
        System.runAs(normalUser) {
            Test.startTest();
            String result = editPricingOnOpportunityController.getAccess(testOpp.Id);
            Test.stopTest();
            System.assertEquals('3', result);
        }
    }
    
    @isTest
    static void testGetPricingElements() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        List<Cost_Sheet__c> costSheets = editPricingOnOpportunityController.getPricingElements(testOpp.Id);
        Test.stopTest();
        
    }
    
    @isTest
    static void testSavePricingElements() {
        Pricing_Element__c pricingElement = [SELECT Id, Rate__c FROM Pricing_Element__c LIMIT 1];
        pricingElement.Rate__c = 200;
        List<Pricing_Element__c> pricingElements = new List<Pricing_Element__c>{pricingElement};
            
            Test.startTest();
        editPricingOnOpportunityController.savePricingElements(pricingElements);
        Test.stopTest();
        
        Pricing_Element__c updatedElement = [SELECT Id, Rate__c FROM Pricing_Element__c WHERE Id = :pricingElement.Id];
        
    }
    @isTest
    static void testCreateOpportunity() {
        // Create original Account
        Account oldAcc = new Account(Name = 'Old Account');
        insert oldAcc;
        
        // Create new Account to be updated
        Account newAcc = new Account(Name = 'New Account');
        insert newAcc;
        
        // Create Opportunity linked to old account
        Opportunity opp = new Opportunity(
            Name = 'Opportunity to Transfer',
            StageName = 'New',
            CloseDate = Date.today().addDays(10),
            AccountId = oldAcc.Id,
            Cost_Sheet_Finalised__c = true
        );
        insert opp;
        
        Test.startTest();
        String updatedOppId = editPricingOnOpportunityController.createOpportunity(newAcc.Id, opp.Id);
        Test.stopTest();
        
        Opportunity updatedOpp = [SELECT Id, AccountId, Previous_Opportunity__c FROM Opportunity WHERE Id = :updatedOppId];
        System.assertEquals(newAcc.Id, updatedOpp.AccountId, 'Account should be updated to new account');
        System.assertEquals(oldAcc.Id, updatedOpp.Previous_Opportunity__c, 'Previous_Opportunity__c should store old account ID');
        
        // Optional: Verify that note is created
        List<ContentNote> notes = [SELECT Id, Title FROM ContentNote WHERE Title LIKE 'Ownership Transferred%' LIMIT 1];
        System.assert(!notes.isEmpty(), 'Ownership transfer note should be created');
    }
    @isTest
    static void testCreateContactFromAccount() {
        // Step 1: Create an Account with required fields
        Account testAcc = new Account(
            Name = 'Test Account',
            Phone = '1234567890',
            Website = 'https://example.com',
            Email__c = 'test@example.com'
        );
        insert testAcc;
        
        // Step 2: Call the method
        Test.startTest();
        Id contactId = editPricingOnOpportunityController.createContactFromAccount(testAcc.Id);
        Test.stopTest();
        
        // Step 3: Validate the Contact was created correctly
        Contact createdCon = [SELECT Id, LastName, Email, Phone FROM Contact WHERE Id = :contactId];
        System.assertEquals(testAcc.Name, createdCon.LastName);
        System.assertEquals(testAcc.Email__c, createdCon.Email);
        System.assertEquals(testAcc.Phone, createdCon.Phone);
    }
    
}