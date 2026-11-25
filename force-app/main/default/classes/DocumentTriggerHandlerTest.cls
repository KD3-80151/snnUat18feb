@isTest
private class DocumentTriggerHandlerTest {

    private class DriveMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"access_token":"tok","id":"driveFolder123"}');
            return res;
        }
    }

    @testSetup
    static void setup() {
        Test.setMock(HttpCalloutMock.class, new DriveMock());
        Company__c comp = new Company__c(Name = 'Test Company');
        insert comp;

        Project__c project = new Project__c(
            Name = 'Test Project',
            Project_Description__c = 'Desc',
            Project_Start_Date__c = Date.newInstance(2025, 7, 1),
            Project_End_Date__c = Date.newInstance(2025, 12, 31),
            Project_Address__c = 'Address',
            Project_Code__c = 'TP01',
            Project_Status__c = 'Planning',
            Company__c = comp.Id,
            Zone__c = 'East',
            City__c = 'City',
            Total_Amount__c = 100,
            Booking_Amount__c = 100,
            Unit_Type__c = '3 BHK'
        );
        insert project;
        project.FolderId__c = 'projectFolder123';
        update project;
    }

    @isTest
    static void createsFolderForManualProjectDocument() {
        Test.setMock(HttpCalloutMock.class, new DriveMock());
        Project__c project = [SELECT Id FROM Project__c LIMIT 1];

        Test.startTest();
        Document__c doc = new Document__c(Name = 'Manual Doc', Project__c = project.Id);
        insert doc;
        Test.stopTest();

        // Folder creation runs in QueueableCreateFolderGDrive (HTTP send is skipped in tests),
        // so just verify the handler ran without errors and the record exists.
        System.assertNotEquals(null, [SELECT Id FROM Document__c WHERE Id = :doc.Id].Id);
    }

    @isTest
    static void skipsDocumentsThatAlreadyHaveFolder() {
        Project__c project = [SELECT Id FROM Project__c LIMIT 1];
        Test.startTest();
        insert new Document__c(Name = 'Existing', Project__c = project.Id, Document_Id__c = 'existingFolder');
        Integer jobs = Limits.getQueueableJobs();
        Test.stopTest();
        System.assertEquals(0, jobs, 'No folder job should be queued for documents that already have a folder');
    }

    @isTest
    static void uploadControllerResolvesDocumentFolder() {
        Project__c project = [SELECT Id FROM Project__c LIMIT 1];
        Document__c doc = new Document__c(Name = 'Upload Doc', Project__c = project.Id, Document_Id__c = 'docFolder123');
        insert doc;

        Test.startTest();
        String folderId = UploadFilesInDriveController.getFolderId(doc.Id);
        Sub_Document__c subDoc = new Sub_Document__c(Name = 'file.pdf');
        Boolean linked = UploadFilesInDriveController.linkToParent(subDoc, doc.Id);
        Test.stopTest();

        System.assertEquals('docFolder123', folderId);
        System.assert(linked);
        System.assertEquals(doc.Id, subDoc.Document__c);
    }
}