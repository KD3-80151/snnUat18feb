@isTest
public class UploadFilesInDriveControllerTest {

    private static void createGoogleDriveIntegration() {
        GoogleDriveIntegration__c googleDrive = new GoogleDriveIntegration__c(
            Name = 'GDrive',
            Refresh_Token__c = 'testRefreshToken',
            Client_Id__c = 'testClientId',
            Client_Secret__c = 'testClientSecret',
            Redirect_URI__c = 'https://example.com/redirect'
        );
        upsert googleDrive;
    }

    @isTest
    public static void testGetFolderId() {
        Event__c testEvent = new Event__c(  folderId__c = 'testFolderId');
        insert testEvent;

        Test.startTest();
        String folderId = UploadFilesInDriveController.getFolderId(testEvent.Id);
        String invalidFolderId = UploadFilesInDriveController.getFolderId('invalidRecordId');
        Test.stopTest();
    }

    @isTest
    public static void testGetAccessToken() {
        createGoogleDriveIntegration();

        Test.startTest();
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setBody('{"access_token":"testAccessToken"}');
        mockResponse.setStatusCode(200);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));

        String accessToken = UploadFilesInDriveController.getAccessToken();
        Test.stopTest();
    }

    public class MockHttpResponseGenerator implements HttpCalloutMock {
    private HttpResponse response;

    public MockHttpResponseGenerator(HttpResponse response) {
        this.response = response;
    }

    public HttpResponse respond(HttpRequest req) {
        if (req.getMethod() == 'POST') {
            if (response == null) {
                response = new HttpResponse();
            }
            response.setHeader('Location', 'https://www.googleapis.com/upload/drive/v3/files/xyz123');
            response.setStatusCode(200);
            response.setBody('{"id":"fileId12345"}');
        }
        return response;
    }
}
    
     @isTest
    public static void testUploadFileToGoogleDrive() {
        String fileName = 'testFile.txt';
        String fileType = 'text/plain';
        String folderId = 'folderIdTest';
        String fileData = EncodingUtil.base64Encode(Blob.valueOf('test file content'));
        String contentRange = 'bytes 0-1023/1024';
        String docId = '001000000000001';

        HttpResponse mockCheckFileResponse = new HttpResponse();
        mockCheckFileResponse.setBody('{"files":[{"id":"fileIdTest","name":"testFile.txt"}]}');
        mockCheckFileResponse.setStatusCode(200);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockCheckFileResponse));

        HttpResponse mockUploadResponse = new HttpResponse();
        mockUploadResponse.setBody('{"id":"fileIdTest"}');
        mockUploadResponse.setStatusCode(200);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockUploadResponse));

        Test.startTest();
        UploadFilesInDriveController.wrapperForResponse response = UploadFilesInDriveController.uploadFileToGoogleDrive(fileName, fileType, folderId, fileData, contentRange, docId);
        Test.stopTest();
    }

    
    @isTest
    public static void testProcessData() {
        String locationValue = 'https://www.googleapis.com/upload/drive/v3/files?uploadType=resumable';
        String fileData = EncodingUtil.base64Encode(Blob.valueOf('test file content'));
        String contentRange = 'bytes 0-1023/1024';
        String docId = '001000000000001';
        String fileName = 'testFile.pdf';

        HttpResponse mockUploadResponse = new HttpResponse();
        mockUploadResponse.setBody('{"id":"fileIdTest"}');
        mockUploadResponse.setStatusCode(200);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockUploadResponse));

        Test.startTest();
        Boolean is308Response = UploadFilesInDriveController.processData(locationValue, fileData, contentRange, docId, fileName);
        Test.stopTest();
    }
    
}