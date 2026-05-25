@isTest
public class folderFileManagerControllerTest {

    @isTest
    static void testCreateFolder() {
        // Create test data
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert testOpp;

        // Call the method
        Test.startTest();
        Boolean result = folderFileManagerController.createFolder('Test Folder', testOpp.Id);
        Test.stopTest();
    }
    
    @isTest
    static void testCreateFolder1() {
        // Create test data
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert testOpp;

        // Call the method
        Test.startTest();
        Boolean result = folderFileManagerController.createFolder(null, testOpp.Id);
        Test.stopTest();
    }
    

    @isTest
    static void testGetDocuments() {
        // Create test data
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert testOpp;

        Document__c doc = new Document__c(
            Name = 'Test Document',
            Opportunity__c = testOpp.Id
        );
        insert doc;

        // Call the method
        Test.startTest();
        List<Document__c> documents = folderFileManagerController.getDocuments(testOpp.Id);
        Test.stopTest();
    }

    @isTest
    static void testCreateFolderOnGDrive() {
        // Create test data
        Document__c doc1 = new Document__c(
            Name = 'Test Document 1'
        );
        Document__c doc2 = new Document__c(
            Name = 'Test Document 2'
        );
        insert new List<Document__c>{doc1, doc2};

        // Mock the GoogleDriveAPI (optional)
        Test.startTest();
        folderFileManagerController.createFolderOnGDrive(new List<sObject>{doc1, doc2});
        Test.stopTest();
    }
}