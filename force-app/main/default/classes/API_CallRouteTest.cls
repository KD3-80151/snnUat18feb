@isTest
public class API_CallRouteTest {

    @testSetup
    static void setupTestData() {
        Group leadQueue = new Group(Name = 'Lead Assignment Queue1', DeveloperName = 'Lead_Assignment_Queue1', Type = 'Queue');
        insert leadQueue;

        Company__c comp = new Company__c(Name = 'Create');
        insert comp;

        Project__c project = new Project__c(
            Name = 'Tridasa',
            Project_Description__c = 'Desc',
            Project_Start_Date__c = Date.newInstance(2025, 7, 1),
            Project_End_Date__c = Date.newInstance(2025, 12, 31),
            Project_Address__c = 'Giss',
            Project_Code__c = '02hjd',
            Project_Status__c = 'Planning',
            Company__c = comp.Id,
            Zone__c = 'East',
            City__c = 'Gid',
            Total_Amount__c = 100,
            Booking_Amount__c = 100,
            Unit_Type__c = '3 BHK'
        );
        insert project;

        Lead userOwnedLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Lead',
            Phone = '9876543210',
            Project__c = project.Id,
            OwnerId = UserInfo.getUserId()
        );
        insert userOwnedLead;

        Lead queueOwnedLead = new Lead(
            FirstName = 'Queue',
            LastName = 'Lead',
            Company = 'Queue Lead',
            Phone = '9000000000',
            Project__c = project.Id
        );
        insert queueOwnedLead;
    }

    private static RestRequest buildRequest(String requestBody) {
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(requestBody);
        req.httpMethod = 'POST';
        req.requestURI = '/services/apexrest/CallRoute';
        return req;
    }

    @isTest
    static void test_getLeadOwner_success() {
        RestRequest req = buildRequest(JSON.serialize(new Map<String, Object>{ 'Phone' => '9876543210' }));
        RestResponse res = new RestResponse();
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        API_CallRoute.getLeadOwner();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
        API_CallRoute.ResponseWrapper wrap = (API_CallRoute.ResponseWrapper) JSON.deserialize(
            RestContext.response.responseBody.toString(),
            API_CallRoute.ResponseWrapper.class
        );
        System.assertEquals('Success', wrap.Status);
        System.assertEquals(UserInfo.getName(), wrap.LeadOwner);
    }

    @isTest
    static void test_getLeadOwner_missingPhone() {
        RestRequest req = buildRequest(JSON.serialize(new Map<String, Object>()));
        RestResponse res = new RestResponse();
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        API_CallRoute.getLeadOwner();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
    }

    @isTest
    static void test_getLeadOwner_leadNotFound() {
        RestRequest req = buildRequest(JSON.serialize(new Map<String, Object>{ 'Phone' => '1111111111' }));
        RestResponse res = new RestResponse();
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        API_CallRoute.getLeadOwner();
        Test.stopTest();

        System.assertEquals(404, RestContext.response.statusCode);
    }

    @isTest
    static void test_getLeadOwner_queueOwnedLead() {
        RestRequest req = buildRequest(JSON.serialize(new Map<String, Object>{ 'Phone' => '9000000000' }));
        RestResponse res = new RestResponse();
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        API_CallRoute.getLeadOwner();
        Test.stopTest();

    }
}