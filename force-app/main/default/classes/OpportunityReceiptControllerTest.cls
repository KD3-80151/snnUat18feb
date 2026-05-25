@isTest
public class OpportunityReceiptControllerTest {
    @testSetup
    static void testData(){
        Opportunity opp = new Opportunity(Name = 'testOpp',StageName = 'New',CloseDate = Date.today());
        insert opp;
        Payment_Schedule__c p = new Payment_Schedule__c(Name = 'test',Opportunity__c = opp.Id,Demand_Letter_Sent__c = true,Tax_Amount__c = 100000);
        insert p;
        Receipt__c r = new Receipt__c(Opportunity__c = opp.Id,Receipt_Date__c = Date.today());
        insert r;
        Tax_Invoice__c t = new Tax_Invoice__c(GST_Paid__c = false,Payment_Schedule__c = p.Id,Tax_Paid_Date__c = Date.today(),Receipt__c = r.Id);
        insert t;
       
    }
 	@isTest
    static void testGetTaxInvoices(){
        
        Test.startTest();
        OpportunityReceiptController.getTaxInvoices(Date.today(),Date.today());
        Test.stopTest();
        
    }
    @isTest
    static void testGetTaxInvoices2(){
        Test.startTest();
        OpportunityReceiptController.getTaxInvoices(Date.today(),null);
        Test.stopTest();
        
    }
    @isTest
    static void testMarkGSTPaidForInvoices(){
        List<Tax_Invoice__c> taxList = [SELECT Id FROM Tax_Invoice__c LIMIT 1];
        List<Id> taxId = new List<Id>();
        taxId.add(taxList[0].Id);
        Test.startTest();
        OpportunityReceiptController.markGSTPaidForInvoices(taxId,Date.today());
        Test.stopTest();
    }
    @isTest
    static void testGetOpportunityReceipts(){
        Test.startTest();
        OpportunityReceiptController.getOpportunityReceipts();
        Test.stopTest();
    }
    @isTest
    static void testMarkGSTPaid(){
        Id opp = [SELECT Id FROM Opportunity LIMIT 1].Id;
        Test.startTest();
        OpportunityReceiptController.markGSTPaid(opp);
        Test.stopTest();
    }
    @isTest
    static void testMarkAllGSTPaid(){
        Test.startTest();
        OpportunityReceiptController.markAllGSTPaid();
   		Test.stopTest();     
    }
}