@isTest
public class DocumentCreationHandlerTest {
    
    @isTest
    static void testCreateTdsSubFolder() {
        
        Opportunity opp = new Opportunity(Name = 'Test Opportunity for TDS', StageName = 'Prospecting', CloseDate = System.today());
        insert opp;
        
        Document__c tdsDoc = new Document__c(Name = 'TDS', Opportunity__c = opp.Id);
        insert tdsDoc;
        
        Demand_Letter__c dmL = new Demand_Letter__c();
        insert dmL;
        
        Receipt__c receipt = new Receipt__c( Opportunity__c = opp.Id,Demand_Letter__c =dmL.Id );
        insert receipt;
        
        DocumentCreationHandler.ReceiptFolderWrapper wrapper = new DocumentCreationHandler.ReceiptFolderWrapper();
        wrapper.subFolder = receipt;
        
        Test.startTest();
        DocumentCreationHandler.createTdsSubFolder(new List<DocumentCreationHandler.ReceiptFolderWrapper>{wrapper});
        Test.stopTest();
        
        
        List<Document__c> createdDocs = [SELECT Id, Name, Parent_Document__c, Opportunity__c FROM Document__c WHERE Opportunity__c = :opp.Id];
       
    }

    @isTest
    static void testQueueableJobExecution() {
        // Setup test data
        Opportunity opp = new Opportunity(Name = 'Test Opportunity', StageName = 'Prospecting', CloseDate = System.today());
        insert opp;
        
        Document__c tdsDoc = new Document__c(Name = 'TDS', Opportunity__c = opp.Id);
        insert tdsDoc;
        
        // Create a test for enqueuing job
        List<String> docIds = new List<String>{tdsDoc.Id};
        
        Test.startTest();
        DocumentCreationHandler.queueReceiptSubFolderCreation(docIds);
        Test.stopTest();
    }
 
    
    @isTest
    static void testCreateDocumentsForOpportunity() {
       
        Document_Master__c docMaster = new Document_Master__c(Name = 'Opportunity');
        insert docMaster;

        Document_category__c docCat = new Document_category__c(
            Name = 'Opportunity Doc',
            Document_Master__c = docMaster.Id
        );
        insert docCat;

        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Prospecting',
            CloseDate = System.today()
        );
        insert opp;

        Test.startTest();
        new DocumentCreationHandler().CreateDocuments(new List<SObject>{opp});
        Test.stopTest();

        List<Document__c> docs = [SELECT Id, Name, Opportunity__c FROM Document__c WHERE Opportunity__c = :opp.Id];
        System.assertEquals(1, docs.size(), 'One document should be created for Opportunity');
    }
    

    @isTest
    static void testCreateDocumentsForAccount_ChannelPartner() {
    
        Document_Master__c master = new Document_Master__c(Name = 'Channel Partner');
        insert master;

        Document_category__c cat = new Document_category__c(Name = 'Channel Partner Doc', Document_Master__c = master.Id);
        insert cat;

        Id cpRtId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Channel Partner').getRecordTypeId();

        Account acc = new Account(Name = 'Test Channel Partner', RecordTypeId = cpRtId);
        insert acc;

        Test.startTest();
        new DocumentCreationHandler().CreateDocuments(new List<SObject>{acc});
        Test.stopTest();

        List<Document__c> docs = [SELECT Id, Name, Account__c FROM Document__c WHERE Account__c = :acc.Id];
        System.assertEquals(1, docs.size(), 'One document should be created for Channel Partner Account');
    }


    @isTest
    static void testCreateDocumentsForApplicant() {
  
        Document_Master__c master = new Document_Master__c(Name = 'Customer');
        insert master;

        Document_category__c cat = new Document_category__c(Name = 'Customer Doc', Document_Master__c = master.Id);
        insert cat;

        Id custRtId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
        Account acc = new Account(Name = 'Test Customer', RecordTypeId = custRtId);
        insert acc;

        Applicant__c applicant = new Applicant__c( Account__c = acc.Id);
        insert applicant;

        Test.startTest();
        new DocumentCreationHandler().CreateDocuments(new List<SObject>{applicant});
        Test.stopTest();

        List<Document__c> docs = [SELECT Id, Name, Applicant__c FROM Document__c WHERE Applicant__c = :applicant.Id];
    }


    
    @isTest
    static void testDummyMethod() {
      // DocumentCreationHandler.dummy();
    }
}