@isTest
public class API_WebsiteLeadCreateTest {

    @testSetup
    static void setupTestData() {
        Group leadQueue = new Group(Name = 'Lead Assignment Queue', DeveloperName = 'Lead_Assignment_Queue1', Type = 'Queue');
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
    }

    private static String buildBody(String firstName, String lastName, String email, String phone, String project) {
        return JSON.serialize(new Map<String, Object>{
            'firstName' => firstName,
            'lastName' => lastName,
            'email' => email,
            'phone' => phone,
            'project' => project,
            'utm_source' => 'Google',
            'utm_medium' => 'CPC',
            'utm_campaign' => 'Test Campaign',
            'utm_term' => 'Lead Generation',
            'lead_source' => 'Website',
            'lead_sub_source' => 'Web',
            'lead_type' => 'Direct'
        });
    }

    private static RestRequest buildRequest(String requestBody, String authHeaderKey, String authHeaderValue) {
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(requestBody);
        req.httpMethod = 'POST';
        req.requestURI = '/services/apexrest/web_lead';
        if (authHeaderKey != null) {
            req.headers.put(authHeaderKey, authHeaderValue);
        }
        return req;
    }

    @isTest
    static void test_API_WebsiteLead_Success() {
        Test.startTest();
        String requestBody = buildBody('John', 'Doe', 'john.doe@example.com', '1234567890', 'Tridasa');

        RestRequest req = buildRequest(requestBody, 'auth-key', System.Label.WebToLead_Authentication_Key);
        RestContext.request = req;

        RestResponse res = new RestResponse();
        RestContext.response = res;

        API_WebsiteLeadCreate.API_WebsiteLead();

        String response = res.responseBody.toString();
        System.assert(response.contains('Success'), 'Expected success response, got: ' + response);
        Test.stopTest();

        List<Lead> leads = [SELECT Id, Phone, Email FROM Lead WHERE Phone = '1234567890'];
        System.assertEquals(1, leads.size(), 'Expected exactly one lead to be inserted.');
    }

    @isTest
    static void test_API_WebsiteLead_MissingAuthKey() {
        Test.startTest();
        String requestBody = buildBody('John', 'Doe', 'john.doe@example.com', '1234567890', 'Tridasa');

        RestRequest req = buildRequest(requestBody, null, null);
        RestContext.request = req;

        RestResponse res = new RestResponse();
        RestContext.response = res;

        API_WebsiteLeadCreate.API_WebsiteLead();

        String response = res.responseBody.toString();
        System.assert(response.contains('Auth-Key is a mandatory field'), 'Expected mandatory auth-key error, got: ' + response);
        Test.stopTest();
    }

    @isTest
    static void test_API_WebsiteLead_InvalidAuthKey() {
        Test.startTest();
        String requestBody = buildBody('John', 'Doe', 'john.doe@example.com', '1234567890', 'Tridasa');

        RestRequest req = buildRequest(requestBody, 'auth-key', 'invalid-key-value');
        RestContext.request = req;

        RestResponse res = new RestResponse();
        RestContext.response = res;

        API_WebsiteLeadCreate.API_WebsiteLead();

        String response = res.responseBody.toString();
        System.assert(response.contains('Auth-Key is incorrect'), 'Expected incorrect auth-key error, got: ' + response);
        Test.stopTest();
    }

    @isTest
    static void test_API_WebsiteLead_AuthKeyHeader_MixedCase() {
        Test.startTest();
        String requestBody = buildBody('John', 'Doe', 'mixedcase@example.com', '2234567890', 'Tridasa');

        RestRequest req = buildRequest(requestBody, 'Auth-Key', System.Label.WebToLead_Authentication_Key);
        RestContext.request = req;

        RestResponse res = new RestResponse();
        RestContext.response = res;

        API_WebsiteLeadCreate.API_WebsiteLead();

        String response = res.responseBody.toString();
        System.assert(response.contains('Success'), 'Expected success response with Auth-Key header, got: ' + response);
        Test.stopTest();
    }

    @isTest
    static void test_API_WebsiteLead_AuthKeyHeader_UpperCase() {
        Test.startTest();
        String requestBody = buildBody('John', 'Doe', 'uppercase@example.com', '3234567890', 'Tridasa');

        RestRequest req = buildRequest(requestBody, 'AUTH-KEY', System.Label.WebToLead_Authentication_Key);
        RestContext.request = req;

        RestResponse res = new RestResponse();
        RestContext.response = res;

        API_WebsiteLeadCreate.API_WebsiteLead();

        String response = res.responseBody.toString();
        System.assert(response.contains('Success'), 'Expected success response with AUTH-KEY header, got: ' + response);
        Test.stopTest();
    }

    @isTest
    static void test_API_WebsiteLead_MissingLastName() {
        Test.startTest();
        String requestBody = buildBody('John', null, 'john.doe@example.com', '1234567890', 'Tridasa');

        RestRequest req = buildRequest(requestBody, 'auth-key', System.Label.WebToLead_Authentication_Key);
        RestContext.request = req;

        RestResponse res = new RestResponse();
        RestContext.response = res;

        API_WebsiteLeadCreate.API_WebsiteLead();

        String response = res.responseBody.toString();
        System.assert(response.contains('Last Name is a mandatory field'), 'Expected mandatory last name error, got: ' + response);
        Test.stopTest();
    }

    @isTest
    static void test_API_WebsiteLead_MissingPhone() {
        Test.startTest();
        String requestBody = buildBody('John', 'Doe', 'john.doe@example.com', null, 'Tridasa');

        RestRequest req = buildRequest(requestBody, 'auth-key', System.Label.WebToLead_Authentication_Key);
        RestContext.request = req;

        RestResponse res = new RestResponse();
        RestContext.response = res;

        API_WebsiteLeadCreate.API_WebsiteLead();

        String response = res.responseBody.toString();
        System.assert(response.contains('Phone is a mandatory field'), 'Expected mandatory phone error, got: ' + response);
        Test.stopTest();
    }

    @isTest
    static void test_API_WebsiteLead_ProjectNotFound() {
        Test.startTest();
        String requestBody = buildBody('John', 'Doe', 'john.doe@example.com', '1234567890', 'Nonexistent Project');

        RestRequest req = buildRequest(requestBody, 'auth-key', System.Label.WebToLead_Authentication_Key);
        RestContext.request = req;

        RestResponse res = new RestResponse();
        RestContext.response = res;

        API_WebsiteLeadCreate.API_WebsiteLead();

        String response = res.responseBody.toString();
        System.assert(response.contains('Project does not exist'), 'Expected project not found error, got: ' + response);
        Test.stopTest();
    }

   /*
    @isTest
    static void test_API_WebsiteLead_LeadQueueNotFound() {
        delete [SELECT Id FROM Group WHERE DeveloperName = 'Lead_Assignment_Queue'];

        Test.startTest();
        String requestBody = buildBody('John', 'Doe', 'john.doe@example.com', '1234567890', 'Tridasa');

        RestRequest req = buildRequest(requestBody, 'auth-key', System.Label.WebToLead_Authentication_Key);
        RestContext.request = req;

        RestResponse res = new RestResponse();
        RestContext.response = res;

        API_WebsiteLeadCreate.API_WebsiteLead();

        String response = res.responseBody.toString();
        System.assert(response.contains('Error'), 'Expected an error response when the lead queue is missing, got: ' + response);
        Test.stopTest();
    }
*/

    @isTest
    static void test_API_WebsiteLead_DuplicateWithin60Days_Phone() {
        Project__c project = [SELECT Id FROM Project__c WHERE Name = 'Tridasa' LIMIT 1];
        Lead existingLead = new Lead(
            FirstName = 'Existing',
            LastName = 'PhoneMatch',
            Email = 'existing.phone@example.com',
            Phone = '5551234567',
            Company = 'PhoneMatch',
            Project__c = project.Id,
            Lead_Type__c = 'Digital',
            Status = 'Open'
        );
        insert existingLead;

        Test.startTest();
        String requestBody = buildBody('John', 'Doe', 'new.email@example.com', '5551234567', 'Tridasa');

        RestRequest req = buildRequest(requestBody, 'auth-key', System.Label.WebToLead_Authentication_Key);
        RestContext.request = req;

        RestResponse res = new RestResponse();
        RestContext.response = res;

        API_WebsiteLeadCreate.API_WebsiteLead();

        String response = res.responseBody.toString();
        System.assert(response.contains('Duplicate Lead created within 60 days found with same Phone Number'), 'Expected phone duplicate error, got: ' + response);
        Test.stopTest();
    }

    @isTest
    static void test_API_WebsiteLead_DuplicateWithin60Days_Email() {
        Project__c project = [SELECT Id FROM Project__c WHERE Name = 'Tridasa' LIMIT 1];
        Lead existingLead = new Lead(
            FirstName = 'Existing',
            LastName = 'EmailMatch',
            Email = 'duplicate.email@example.com',
            Phone = '5559876543',
            Company = 'EmailMatch',
            Project__c = project.Id,
            Lead_Type__c = 'Digital',
            Status = 'Open'
        );
        insert existingLead;

        Test.startTest();
        String requestBody = buildBody('John', 'Doe', 'duplicate.email@example.com', '5551112222', 'Tridasa');

        RestRequest req = buildRequest(requestBody, 'auth-key', System.Label.WebToLead_Authentication_Key);
        RestContext.request = req;

        RestResponse res = new RestResponse();
        RestContext.response = res;

        API_WebsiteLeadCreate.API_WebsiteLead();

        String response = res.responseBody.toString();
        System.assert(response.contains('Duplicate Lead created within 60 days found with same Email'), 'Expected email duplicate error, got: ' + response);
        Test.stopTest();
    }

    @isTest
    static void test_API_WebsiteLead_DuplicateWithin60Days_AlternatePhone() {
        Project__c project = [SELECT Id FROM Project__c WHERE Name = 'Tridasa' LIMIT 1];
        Lead existingLead = new Lead(
            FirstName = 'Existing',
            LastName = 'AltPhoneMatch',
            Email = 'alt.phone@example.com',
            Phone = '5550001111',
            Alternate_Phone__c = '5553334444',
            Company = 'AltPhoneMatch',
            Project__c = project.Id,
            Lead_Type__c = 'Digital',
            Status = 'Open'
        );
        insert existingLead;

        Test.startTest();
        // New lead's Phone matches the existing lead's Alternate_Phone__c, not its primary Phone/Email.
        String requestBody = buildBody('John', 'Doe', 'no.match@example.com', '5553334444', 'Tridasa');

        RestRequest req = buildRequest(requestBody, 'auth-key', System.Label.WebToLead_Authentication_Key);
        RestContext.request = req;

        RestResponse res = new RestResponse();
        RestContext.response = res;

        API_WebsiteLeadCreate.API_WebsiteLead();

        String response = res.responseBody.toString();
        System.assert(response.contains('Duplicate Lead created within 60 days found with same Phone Number'), 'Expected alternate-phone duplicate error, got: ' + response);
        Test.stopTest();
    }

    @isTest
    static void test_API_WebsiteLead_OldDuplicate_ProceedsToInsert() {
        Project__c project = [SELECT Id FROM Project__c WHERE Name = 'Tridasa' LIMIT 1];
        Lead existingLead = new Lead(
            FirstName = 'Existing',
            LastName = 'OldMatch',
            Email = 'old.match@example.com',
            Phone = '5556667777',
            Company = 'OldMatch',
            Project__c = project.Id,
            Lead_Type__c = 'Digital',
            Status = 'Open'
        );
        insert existingLead;
        // Push the existing lead's CreatedDate outside the 60-day duplicate window.
        Test.setCreatedDate(existingLead.Id, System.now().addDays(-90));

        Test.startTest();
        String requestBody = buildBody('John', 'Doe', 'old.match@example.com', '5556667777', 'Tridasa');

        RestRequest req = buildRequest(requestBody, 'auth-key', System.Label.WebToLead_Authentication_Key);
        RestContext.request = req;

        RestResponse res = new RestResponse();
        RestContext.response = res;

        API_WebsiteLeadCreate.API_WebsiteLead();

        String response = res.responseBody.toString();
        System.assert(response.contains('Success'), 'Expected success since the matching lead is older than 60 days, got: ' + response);
        Test.stopTest();
    }

    @isTest
    static void test_API_WebsiteLead_MalformedJson() {
        Test.startTest();
        RestRequest req = buildRequest('not-valid-json', 'auth-key', System.Label.WebToLead_Authentication_Key);
        RestContext.request = req;

        RestResponse res = new RestResponse();
        RestContext.response = res;

        // The outer try/catch in API_WebsiteLead swallows the JSON parse exception.
        API_WebsiteLeadCreate.API_WebsiteLead();

        System.assertEquals(null, res.responseBody, 'Response body should remain unset when the request body cannot be parsed.');
        Test.stopTest();
    }

    @isTest
    static void test_API_WebsiteLead_NullBody() {
        Test.startTest();
        RestRequest req = buildRequest('null', 'auth-key', System.Label.WebToLead_Authentication_Key);
        RestContext.request = req;

        RestResponse res = new RestResponse();
        RestContext.response = res;

        API_WebsiteLeadCreate.API_WebsiteLead();

        System.assertEquals(null, res.responseBody, 'Response body should remain unset when the deserialized body is null.');
        Test.stopTest();
    }
}