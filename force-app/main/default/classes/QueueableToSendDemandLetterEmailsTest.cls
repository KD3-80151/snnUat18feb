@IsTest
private class QueueableToSendDemandLetterEmailsTest {
    
    private class GoogleDriveMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            String endpoint = req.getEndpoint();
            
            if (endpoint != null && endpoint.contains('oauth2')) {
                res.setStatusCode(200);
                res.setHeader('Content-Type', 'application/json');
                res.setBody('{"access_token":"mock_access_token","token_type":"Bearer","expires_in":3600}');
                return res;
            }
            
            if (endpoint != null && endpoint.contains('drive/v3/files/') && endpoint.contains('alt=media')) {
                res.setStatusCode(200);
                res.setHeader('Content-Type', 'application/pdf');
                res.setBodyAsBlob(Blob.valueOf('Mock Statement Of Account PDF'));
                return res;
            }
            
            res.setStatusCode(400);
            res.setBody('Unexpected endpoint: ' + endpoint);
            return res;
        }
    }
    
    @testSetup
    static void setupData() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),
            AccountId = acc.Id,
            Email__c = 'customer@test.com'
        );
        insert opp;
        
        Document__c postSalesDoc = new Document__c(
            Name = 'Post Sales',
            Opportunity__c = opp.Id
        );
        insert postSalesDoc;
        
        Sub_Document__c subDoc = new Sub_Document__c(
            Name = 'Statement of Account - 2026-03-16 10:00:00',
            Document__c = postSalesDoc.Id,
            File_URL__c = 'https://drive.google.com/file/d/1ABCDEF1234567890XYZ/preview?usp=drivesdk'
        );
        insert subDoc;
        
        Payment_Schedule__c pay = new Payment_Schedule__c(
            Name = 'PS-001',
            Opportunity__c = opp.Id,
            Demand_Letter_Sent__c = false,
            Tax_Invoice_Created__c = false,
            Agreement_Value__c = 1000,
            Tax_Amount__c = 100
        );
        insert pay;
    }
    
    @IsTest
    static void testQueueableSuccess() {
        Test.setMock(HttpCalloutMock.class, new GoogleDriveMock());
        
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        ContentVersion cv = new ContentVersion(
            Title = 'Demand Letter - Test',
            PathOnClient = 'DemandLetterTest.pdf',
            VersionData = Blob.valueOf('Mock Demand Letter PDF')
        );
        insert cv;
        
        cv = [
            SELECT Id, ContentDocumentId, Title
            FROM ContentVersion
            WHERE Id = :cv.Id
            LIMIT 1
        ];
        
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        
        Payment_Schedule__c pay = new Payment_Schedule__c(
            Name = 'PS-001',
            Opportunity__c = opp.Id,
            Demand_Letter_Sent__c = false,
            Tax_Invoice_Created__c = false,
            Agreement_Value__c = 1000,
            Tax_Amount__c = 100
        );
        insert pay;
        
        Map<String, List<String>> oppIdByContentVersionIds = new Map<String, List<String>>();
        oppIdByContentVersionIds.put((String)opp.Id, new List<String>{ (String)cv.Id });
        
        Set<Id> processedPaymentScheduleIds = new Set<Id>();
        processedPaymentScheduleIds.add(pay.Id);
            Test.startTest();
        System.enqueueJob(new QueueableToSendDemandLetterEmails(oppIdByContentVersionIds,processedPaymentScheduleIds ));
        Test.stopTest();
        
    }
    
    @IsTest
    static void testQueueableNoStatementAttachment() {
        Test.setMock(HttpCalloutMock.class, new GoogleDriveMock());
        
        Account acc = new Account(Name = 'Second Account');
        insert acc;
        
        Opportunity opp = new Opportunity(
            Name = 'Second Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(5),
            AccountId = acc.Id,
            Email__c = 'second@test.com'
        );
        insert opp;
        
        Payment_Schedule__c pay = new Payment_Schedule__c(
            Name = 'PS-002',
            Opportunity__c = opp.Id,
            Demand_Letter_Sent__c = false,
            Tax_Invoice_Created__c = false,
            Agreement_Value__c = 2000,
            Tax_Amount__c = 200
        );
        insert pay;
        
        ContentVersion cv = new ContentVersion(
            Title = 'Demand Letter - Test 2',
            PathOnClient = 'DemandLetterTest2.pdf',
            VersionData = Blob.valueOf('Mock Demand Letter PDF 2')
        );
        insert cv;
        
        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];
        
        Map<String, List<String>> oppIdByContentVersionIds = new Map<String, List<String>>();
        oppIdByContentVersionIds.put((String)opp.Id, new List<String>{ (String)cv.Id });
        Set<Id> processedPaymentScheduleIds = new Set<Id>();
        processedPaymentScheduleIds.add(pay.Id);
        
        Test.startTest();
        System.enqueueJob(new QueueableToSendDemandLetterEmails(oppIdByContentVersionIds, processedPaymentScheduleIds));
        Test.stopTest();
        
        Payment_Schedule__c updatedPay = [
            SELECT Id, Demand_Letter_Sent__c, Tax_Invoice_Created__c
            FROM Payment_Schedule__c
            WHERE Id = :pay.Id
            LIMIT 1
        ];
        System.assertEquals(true, updatedPay.Demand_Letter_Sent__c);
        System.assertEquals(true, updatedPay.Tax_Invoice_Created__c);
    }
    
   @IsTest
    static void testQueueableEmptyInput() {
        Test.startTest();
        System.enqueueJob(
            new QueueableToSendDemandLetterEmails(
                new Map<String, List<String>>(), new Set<Id>()));
        Test.stopTest();
    }
}