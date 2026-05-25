@isTest
public class ProjectUpdateHandlerTest {

    private class GoogleHttpMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
         
            if (req.getEndpoint().contains('oauth2')) {
                res.setStatusCode(200);
                res.setBody('{"access_token":"testAccessToken"}');
            }
           
            else if (req.getEndpoint().contains('drive')) {
                res.setStatusCode(200);
                res.setBody('{"id":"subfolder123"}');
            }
            else {
                res.setStatusCode(400);
                res.setBody('{"error":"Bad Request"}');
            }
            return res;
        }
    }

    @testSetup
    static void setupTestData() {
       
        GoogleDriveIntegration__c gDrive = new GoogleDriveIntegration__c(
            Name = 'GDrive',
            Refresh_Token__c = 'dummyRefresh',
            Client_Id__c = 'dummyClient',
            Client_Secret__c = 'dummySecret',
            Redirect_URI__c = 'https://dummy.com'
        );
        insert gDrive;

        Company__c company = new Company__c(Name='Test Company');
        insert company;
        
        Project__c project = new Project__c(
            Name = 'Test Project',
            Company__c=company.Id,
            FolderId__c = 'parentFolder123'
        );
        insert project;

        Project_Updates__c updateProp = new Project_Updates__c(
            Name = 'Initial Update',
            Project__c = project.Id
        );
        insert updateProp;
    }

    @isTest
    static void testGetAccessToken() {
        Test.setMock(HttpCalloutMock.class, new GoogleHttpMock());

        Test.startTest();
        String token = ProjectUpdateHandler.getAccessToken();
        Test.stopTest();

        System.assertEquals('testAccessToken', token, 'Access token should match mock value');
    }

    @isTest
    static void testUpdateProjectUpdateFolderId() {
        Test.setMock(HttpCalloutMock.class, new GoogleHttpMock());

        Project__c proj = [SELECT Id FROM Project__c LIMIT 1];

        Test.startTest();
        ProjectUpdateHandler.updateProjectUpdateFolderId(proj.Id);
        Test.stopTest();

        Project_Updates__c updateProp = [
            SELECT Id, FolderId__c FROM Project_Updates__c
            WHERE Project__c = :proj.Id
            LIMIT 1
        ];
        System.assertEquals('subfolder123', updateProp.FolderId__c, 'FolderId__c should be set from mock response');
    }

    @isTest
    static void testUpdateProjectUpdateFolderId_NoProjectUpdate() {
        Test.setMock(HttpCalloutMock.class, new GoogleHttpMock());
		
        Company__c company = new Company__c(Name='Test Company');
        insert company;
        Project__c proj = new Project__c(Name = 'Empty Project', FolderId__c = 'parentFolder456', Company__c = company.Id);
        insert proj;

        Test.startTest();
        ProjectUpdateHandler.updateProjectUpdateFolderId(proj.Id);
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM Project_Updates__c WHERE Project__c = :proj.Id], 'No updates should exist');
    }
}