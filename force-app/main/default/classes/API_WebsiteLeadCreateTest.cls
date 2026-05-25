@isTest
public class API_WebsiteLeadCreateTest {
    @isTest
    static void test_API_WebsiteLead_Success() {
        // Setup test data
        // 
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
        
        Lead existingLead = new Lead(
            FirstName = 'John',
            LastName = 'Doe',
            Email = 'john.doe@example.com',
            Phone = '1234567890',
            Company = 'Doe Inc',
            Project__c = project.Id,
            Lead_Type__c = 'Direct',
            Status = 'Open'
        );
        insert existingLead;
        
        
        Campaign campaign = new Campaign(Name = 'Test Campaign');
        insert campaign;
        
        Group leadQueue = new Group(Name = 'Lead Assignment Queue', DeveloperName = 'Lead_Assignment_Queue1', Type = 'Queue');
        insert leadQueue;
        
        Test.startTest();
        // Create mock request body
        String requestBody = JSON.serialize(new Map<String, Object>{
            'firstName' => 'John',
                'lastName' => 'Doe',
                'email' => 'john.doe@example.com',
                'phone' => '1234567890',
                'project' => 'Tridasa',
                'campaign' => 'Test Campaign',
                'utm_source' => 'Google',
                'utm_medium' => 'CPC',
                'utm_campaign' => 'Test Campaign',
                'utm_term' => 'Lead Generation',
                'lead_source' => 'Website',
                'lead_sub_source' => 'Landing Page',
                'lead_type' => 'Direct'
                });
        
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(requestBody);
        req.httpMethod = 'POST';
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;
        
        // Invoke the method
        API_WebsiteLeadCreate.API_WebsiteLead();
        
        // Validate response
        String response = res.responseBody.toString();
        
        Test.stopTest();
    }
    
    @isTest
    static void test_API_WebsiteLead_MissingRequiredFields() {
        Test.startTest();
        // Create mock request body with missing required fields
        String requestBody = JSON.serialize(new Map<String, Object>{
            'lastName' => 'Doe',
                'email' => 'john.doe@example.com',
                'phone' => '1234567890',
                'project' => 'Tridasa',
                'campaign' => 'Test Campaign'
                });
        
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(requestBody);
        req.httpMethod = 'POST';
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;
        
        // Invoke the method
        API_WebsiteLeadCreate.API_WebsiteLead();
        
        // Validate response
        String response = res.responseBody.toString();
        
        Test.stopTest();
    }
    
    @isTest
    static void test_API_WebsiteLead_DuplicateLeadWithin60Days() {
        // Setup test data
        Company__c comp1 = new Company__c(Name = 'Create1');
        insert comp1;
        
        Project__c project = new Project__c(
            Name = 'Snn',
            Project_Description__c = 'Desc',
            Project_Start_Date__c = Date.newInstance(2025, 7, 1),
            Project_End_Date__c = Date.newInstance(2025, 12, 31),
            Project_Address__c = 'Giss',
            Project_Code__c = '02hjde',
            Project_Status__c = 'Planning',
            Company__c = comp1.Id,
            Zone__c = 'East',
            City__c = 'Gid',
            Total_Amount__c = 100,
            Booking_Amount__c = 100,
            Unit_Type__c = '3 BHK'
        );
        insert project;
        Project__c project2 = new Project__c(
            Name = 'Snn2',
            Project_Description__c = 'Descr',
            Project_Start_Date__c = Date.newInstance(2024, 7, 1),
            Project_End_Date__c = Date.newInstance(2026, 12, 31),
            Project_Address__c = 'Gissf',
            Project_Code__c = '02hjdef',
            Project_Status__c = 'Planning',
            Company__c = comp1.Id,
            Zone__c = 'West',
            City__c = 'Gida',
            Total_Amount__c = 1000,
            Booking_Amount__c = 1000,
            Unit_Type__c = '1 BHK'
        );
        insert project2;
        
        Campaign campaign = new Campaign(Name = 'Test Campaign');
        insert campaign;
        
        Group leadQueue = new Group(Name = 'Lead Assignment Queue', DeveloperName = 'Lead_Assignment_Queue3', Type = 'Queue');
        insert leadQueue;
        
        Lead existingLead = new Lead(
            FirstName = 'John',
            LastName = 'Doe',
            Email = 'john.doe@example1.com',
            Phone = '1234567890',
            Company = 'Doe Inc',
            Project__c = project.Id,
            Lead_Type__c = 'Direct',
            Status = 'New'
        );
        insert existingLead;
        
        
        
        Lead existingLead2 = new Lead(
            FirstName = 'John1',
            LastName = 'Doe1',
            Email = '',
            Phone = '1234567891',
            Company = 'Doe Inc2',
            Project__c = project2.Id,
            Lead_Type__c = 'Direct',
            Status = 'New'
        );
        //insert existingLead2;
        
        Test.startTest();
        // Create mock request body for duplicate lead
        String requestBody = JSON.serialize(new Map<String, Object>{
            'firstName' => 'John',
                'lastName' => 'Doe',
                'email' => 'john.doe@example1.com',
                'phone' => '1231567890',
                'project' => 'Tridasa',
                'campaign' => 'Test Campaign',
                'lead_type' => 'Direct'
                });
        
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(requestBody);
        req.httpMethod = 'POST';
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;
        
        // Invoke the method
        API_WebsiteLeadCreate.API_WebsiteLead();
        
        // Validate response
        String response = res.responseBody.toString();
        
        Test.stopTest();
    }
    
    @isTest
    static void test_API_WebsiteLead_ProjectOrCampaignNotFound() {
        Test.startTest();
        // Create mock request body with invalid project and campaign
        String requestBody = JSON.serialize(new Map<String, Object>{
            'firstName' => 'John',
                'lastName' => 'Doe',
                'email' => 'john.doe@example.com',
                'phone' => '1234567890',
                'project' => 'Tridasa',
                'campaign' => 'Nonexistent Campaign',
                'lead_type' => 'Direct'
                });
        
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(requestBody);
        req.httpMethod = 'POST';
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;
        
        // Invoke the method
        API_WebsiteLeadCreate.API_WebsiteLead();
        
        // Validate response
        String response = res.responseBody.toString();
        
        Test.stopTest();
    }
}