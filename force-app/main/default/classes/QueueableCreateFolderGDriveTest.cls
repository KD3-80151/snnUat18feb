@isTest
public class QueueableCreateFolderGDriveTest {

    @testSetup
    static void setupTestData() {
        Account accCP = new Account(Name = 'Test Channel Partner');
        insert accCP;

        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Contact con = new Contact(FirstName = 'Test', LastName = 'Contact', AccountId = acc.Id);
        insert con;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = acc.Id
        );
        insert opp;
          
        Document__c doc1 = new Document__c();
        doc1.Name='Demand Letter';
        doc1.Opportunity__c = opp.Id;
        doc1.Document_Id__c='123456';
        insert doc1;

        Applicant__c applicant = new Applicant__c(
            Opportunity__c = opp.Id,
            Account__c = acc.Id
        );
        insert applicant;

		Company__c company = new Company__c(Name = 'TestCompany');
        insert company;
        Project__c proj = new Project__c(Name = 'Test Project', Company__c = company.Id);
        insert proj;

        Document__c doc = new Document__c(
            Name = 'Test Document',
            Document_Id__c = '1234',
            Opportunity__c = opp.Id,
            Account__c = acc.Id,
            Applicant__c = applicant.Id
        );
        insert doc;
    }

    // Test Opportunity with Contact FolderId__c = null
    static testMethod void testOpportunityContactFolderNull() {
        Opportunity opp = [SELECT Id, AccountId FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];
        Contact con = [SELECT Id FROM Contact WHERE AccountId = :opp.AccountId LIMIT 1];
        con.FolderId__c = null;
        update con;

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new FolderCreationMock());
        System.enqueueJob(new QueueableCreateFolderGDrive(new List<Id>{opp.Id}));
        Test.stopTest();
    }

    // Test Opportunity with Contact FolderId__c != null and Opp Document_Id__c = null
    static testMethod void testOpportunityContactFolderSet() {
        Opportunity opp = [SELECT Id, AccountId FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];
        Contact con = [SELECT Id FROM Contact WHERE AccountId = :opp.AccountId LIMIT 1];
        con.FolderId__c = 'dummyContactFolderId';
        update con;

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new FolderCreationMock());
        System.enqueueJob(new QueueableCreateFolderGDrive(new List<Id>{opp.Id}));
        Test.stopTest();
    }

    // Test Account (Channel Partner)
    static testMethod void testAccountChannelPartner() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Channel Partner' LIMIT 1];
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new FolderCreationMock());
        System.enqueueJob(new QueueableCreateFolderGDrive(new List<Id>{acc.Id}));
        Test.stopTest();
    }

    // Test Document__c
    static testMethod void testDocument() {
        Document__c doc = [SELECT Id FROM Document__c WHERE Name = 'Test Document' LIMIT 1];
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new FolderCreationMock());
        System.enqueueJob(new QueueableCreateFolderGDrive(new List<Id>{doc.Id}));
        Test.stopTest();
    }

    private class FolderCreationMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"id": "mockFolderId"}');
            System.debug('Mock API Response: ' + res.getBody());  // Debug added to check response
            return res;
        }
    }

    // Test HTTP Callout Mock Registration
    @isTest
    static void testHttpCalloutExecution() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Document__c doc = [SELECT Id FROM Document__c WHERE Name = 'Test Document' LIMIT 1];

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new ForceHttpSendMock());
        System.enqueueJob(new QueueableCreateFolderGDrive(new List<Id>{opp.Id}));
        QueueableCreateFolderGDrive.processData(doc.Id);  // Ensure this happens after setting the mock
        Test.stopTest();
    }

    private class ForceHttpSendMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"id": "forcedFolderId"}');
            System.debug('Forced API Response: ' + res.getBody());  // Debug added to check response
            return res;
        }
    }
    
    @isTest
    static void testDummyMethod() {
        QueueableCreateFolderGDrive.dummy();
    }
}