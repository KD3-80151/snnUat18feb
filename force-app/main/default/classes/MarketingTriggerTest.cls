@isTest
public class MarketingTriggerTest {

    @isTest
    static void testMarketingTrigger_Insert() {
        // Create test data for Marketing__c
        Marketing__c marketingRecord = new Marketing__c(
           
            
        );

        
        Test.startTest();
        insert marketingRecord;
        Test.stopTest();

       
    }
}