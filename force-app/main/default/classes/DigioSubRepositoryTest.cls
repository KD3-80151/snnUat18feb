@isTest
public class DigioSubRepositoryTest {

   @isTest
    public static void testGenerateVehicleParkingDocument() {
        Digio_Integration__c customData = new Digio_Integration__c(
            Name = 'Digio',
            Endpoint_URL__c = 'https://api.digio.in',  // Passed the Endpoint URL here
            Authorization__c = 'Bearer someAuthCode',
            Vehicle_Parking_And_Stickers_Policy__c = 'templateKey'
        );
        insert customData;
        
        Opportunity opp = new Opportunity(Name = 'Test Opp', StageName = 'Prospecting', CloseDate = Date.today());
        insert opp;
        
        Document__c doc = new Document__c(
            Name = 'Post Sales',
            Opportunity__c = opp.Id,
            Document_Id__c = 'parentFolderId'
        );
        insert doc;
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        DigioSubRepository.generateVehicleParkingDocument(opp.Id);
        
        Test.stopTest();
    }
    
    @isTest
    public static void testGenerateServiceProviderContactsListDoc() {
        Digio_Integration__c customData = new Digio_Integration__c(
            Name = 'Digio',
            Endpoint_URL__c = 'https://api.digio.in',  // Passed the Endpoint URL here
            Authorization__c = 'Bearer someAuthCode',
            Contact_Service_List_Template_Key__c = 'templateKey'
        );
        insert customData;
        
        Opportunity opp = new Opportunity(Name = 'Test Opp', StageName = 'Prospecting', CloseDate = Date.today());
        insert opp;
        
        Document__c doc = new Document__c(
            Name = 'Post Sales',
            Opportunity__c = opp.Id,
            Document_Id__c = 'parentFolderId'
        );
        insert doc;
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        DigioSubRepository.generateServiceProviderContactsListDoc(opp.Id);
        
        Test.stopTest();
    }
    
    @isTest
    public static void testGenerateMoveInMoveOutDocument() {
        Digio_Integration__c customData = new Digio_Integration__c(
            Name = 'Digio',
            Endpoint_URL__c = 'https://api.digio.in',  // Passed the Endpoint URL here
            Authorization__c = 'Bearer someAuthCode',
            MoveIn_MoveOut_Template_Key__c = 'templateKey'
        );
        insert customData;
        Account acc= new Account();
        acc.Name = 'test';
        insert acc;
        Opportunity opp = new Opportunity(Name = 'Test Opp', StageName = 'Prospecting', CloseDate = Date.today(), AccountId = acc.Id);
        insert opp;
        
        Document__c doc = new Document__c(
            Name = 'Post Sales',
            Opportunity__c = opp.Id,
            Document_Id__c = 'parentFolderId'
        );
        insert doc;
        
        Contact contact = new Contact(LastName = 'John Doe', AccountId = opp.AccountId, Email = 'john.doe@example.com', Phone = '1234567890');
        insert contact;
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        DigioSubRepository.generateMoveInMoveOutDocument(opp.Id);
        
        Test.stopTest();
    }

    @isTest
    public static void testGeneratePartyHallRulesDocument() {
        Digio_Integration__c customData = new Digio_Integration__c(
            Name = 'Digio',
            Endpoint_URL__c = 'https://api.digio.in',  // Passed the Endpoint URL here
            Authorization__c = 'Bearer someAuthCode',
            Party_Hall_Rules_Temaplate_Key__c = 'templateKey'
        );
        insert customData;
        
        Account acc = new Account();
        acc.Name = 'test';
        insert acc;
        Opportunity opp = new Opportunity(Name = 'Test Opp', StageName = 'Prospecting', CloseDate = Date.today(), AccountId = acc.Id);
        insert opp;
        
        Document__c doc = new Document__c(
            Name = 'Post Sales',
            Opportunity__c = opp.Id,
            Document_Id__c = 'parentFolderId'
        );
        insert doc;
        
        Contact contact = new Contact(LastName = 'John Doe', AccountId = opp.AccountId, Email = 'john.doe@example.com', Phone = '1234567890', Alternate_Phone__c = '0987654321');
        insert contact;
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        DigioSubRepository.generatePartyHallRulesDocument(opp.Id);
        
        Test.stopTest();
    }

    public class MockHttpResponseGenerator implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            
            if (req.getEndpoint().contains('/v2/client/template/multi_templates/create_sign_request')) {
                res.setStatusCode(200);
                res.setBody('{"id": "digiDocId-12345", "status": "success"}');
                res.setHeader('Content-Type', 'application/json');
            } else if (req.getEndpoint().contains('/v2/client/document/download')) {
                res.setStatusCode(200);
                res.setHeader('Location', 'https://www.googleapis.com/upload/drive/v3/files/xyz123');
                res.setBody('{"file": "sample data"}');
            } else {
                res.setStatusCode(404);
                res.setBody('Not Found');
            }
            
            res.setHeader('Content-Type', 'application/json');
            return res;
        }
    }
}