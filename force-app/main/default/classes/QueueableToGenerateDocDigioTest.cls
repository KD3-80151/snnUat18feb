@isTest
public class QueueableToGenerateDocDigioTest {
    
    @testSetup
    static void setupTestData() {
        
         Digio_Integration__c customSetting = new Digio_Integration__c(
            Name = 'Digio',  
            Authorization__c = 'Basic QUNLMjQxMTIwMTgyOTUyNDc2VThaUjRCSUY3UjFDVTM6V09YVUhRWDNHUUNDSUNBVTk4UzFSUFcxOEkxRVg0NTc=', 
            Endpoint_URL__c = 'https://ext.digio.in:1100'
        );
        insert customSetting;
        
        Account mainAccount = new Account(
            Name = 'Test Main Applicant',
            Email__c = 'Vamsi123@gmail.com'    
        );
        insert mainAccount;
        
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            AccountId = mainAccount.Id
        );
        insert opp;
        
        Unit__c testUnit = new Unit__c(
            Unit_Name__c = 'Unit 101'
        );
        insert testUnit;
        
        // Create a test Demand Letter
        Demand_Letter__c demandLetter = new Demand_Letter__c();
        insert demandLetter;
        
        Document__c doc = new Document__c(
            Name = 'Payment Receipt',
        	Opportunity__c = opp.Id,
            Document_Id__c = 'DOC123'
        );
        insert doc;
        
        Receipt__c receipt = new Receipt__c( 
            Amount__c = 5000,
            Opportunity__c = opp.Id,
            Demand_Letter__c = demandLetter.Id,
            Mode_Of_Payment__c = 'Cheque',
            Reference_Number__c = 'REF12345',
            Cheque_Date__c = Date.today(),
            Bank__c = 'Test Bank'        
        );
        insert receipt;
        
        Applicant__c app = new Applicant__c();
        app.Opportunity__c = opp.Id;
        insert app;
    }

    @isTest
    static void testQueueableToGenerateDocDigio() {
        Test.startTest();

        // Mock HTTP Response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Fetch test Serenity Receipt records
        List<Receipt__c> receipts = [SELECT Id FROM Receipt__c LIMIT 3];
        List<String> receiptIds = new List<String>();
        for (Receipt__c rec : receipts) {
            receiptIds.add(rec.Id);
        }

        // Enqueue the Queueable job
        QueueableToGenerateDocDigio job = new QueueableToGenerateDocDigio(receiptIds);
        System.enqueueJob(job);

        Test.stopTest();
    }

    // Mock HTTP Response Class
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"status":"success","documentId":"DOC123","id":"123"}');
            return res;
        }
    }
}