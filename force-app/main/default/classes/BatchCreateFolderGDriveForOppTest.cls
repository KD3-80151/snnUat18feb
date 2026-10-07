@isTest
public class BatchCreateFolderGDriveForOppTest {

    @testSetup
    static void setupTestData() {
        Account acc = new Account(Name = 'Batch Test Account');
        insert acc;

        Contact con = new Contact(FirstName = 'Batch', LastName = 'Contact', AccountId = acc.Id);
        insert con;

        Opportunity opp = new Opportunity(
            Name = 'Batch Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = acc.Id
        );
        insert opp;
    }

    @isTest
    static void testBatchDefaultConstructor() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new FolderCreationMock());
        Database.executeBatch(new BatchCreateFolderGDriveForOpp(), 30);
        Test.stopTest();
    }

    @isTest
    static void testBatchCustomQueryConstructor() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Batch Test Opportunity' LIMIT 1];
        String customQuery = 'SELECT Id FROM Opportunity WHERE Id = \'' + opp.Id + '\'';

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new FolderCreationMock());
        Database.executeBatch(new BatchCreateFolderGDriveForOpp(customQuery), 30);
        Test.stopTest();
    }

    @isTest
    static void testBatchNoMatchingRecords() {
        String emptyQuery = 'SELECT Id FROM Opportunity WHERE Id = null';

        Test.startTest();
        Database.executeBatch(new BatchCreateFolderGDriveForOpp(emptyQuery), 30);
        Test.stopTest();
    }

    private class FolderCreationMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"id": "mockFolderId"}');
            return res;
        }
    }
}
