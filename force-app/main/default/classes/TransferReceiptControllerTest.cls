@isTest
private class TransferReceiptControllerTest {

    @isTest
    static void testUpdateReceiptOpportunity_Success() {
          Opportunity opportunity = new Opportunity(
            Name = 'Test Opportunity',
            CloseDate = Date.today(),
            StageName = 'Prospecting'
        );
        insert opportunity;
         
        
           Demand_Letter__c demandLetter = new Demand_Letter__c();
        insert demandLetter;

        Receipt__c receipt = new Receipt__c(Opportunity__c = opportunity.Id,Demand_Letter__c =demandLetter.Id );
        insert receipt;

      

        Test.startTest();
        TransferReceiptController.updateReceiptOpportunity(receipt.Id, opportunity.Id);
        Test.stopTest();

    }

    @isTest
    static void testUpdateReceiptOpportunity_ReceiptNotFound() {

        Opportunity opportunity = new Opportunity(
            Name = 'Test Opportunity',
            CloseDate = Date.today(),
            StageName = 'Prospecting'
        );
        insert opportunity;

        Test.startTest();
        try {
            TransferReceiptController.updateReceiptOpportunity('invalidId', opportunity.Id);
        } catch (AuraHandledException e) {
        }
        Test.stopTest();
    }

    @isTest
    static void testUpdateReceiptOpportunity_MissingParameters() {
          Opportunity opportunity = new Opportunity(
            Name = 'Test Opportunity',
            CloseDate = Date.today(),
            StageName = 'Prospecting'
        );
        insert opportunity;
         
        
           Demand_Letter__c demandLetter = new Demand_Letter__c();
        insert demandLetter;

        Receipt__c receipt = new Receipt__c(Opportunity__c = opportunity.Id,Demand_Letter__c =demandLetter.Id );
        insert receipt;

        Test.startTest();
        try {
            TransferReceiptController.updateReceiptOpportunity(null, receipt.Id);
            
        } catch (AuraHandledException e) {
           
        }
        Test.stopTest();

        
        try {
            TransferReceiptController.updateReceiptOpportunity(receipt.Id, null);
        } catch (AuraHandledException e) {
            
        }
        
    }

    @isTest
    static void testUpdateReceiptOpportunity_Exception() {
           Opportunity opportunity = new Opportunity(
            Name = 'Test Opportunity',
            CloseDate = Date.today(),
            StageName = 'Prospecting'
        );
        insert opportunity;
         
        
           Demand_Letter__c demandLetter = new Demand_Letter__c();
        insert demandLetter;

        Receipt__c receipt = new Receipt__c(Opportunity__c = opportunity.Id,Demand_Letter__c =demandLetter.Id );
        insert receipt;

        delete receipt;

        Test.startTest();
        try {
            TransferReceiptController.updateReceiptOpportunity(receipt.Id, 'dummyOpportunityId');
        } catch (AuraHandledException e) {
        }
        Test.stopTest();
    }
}