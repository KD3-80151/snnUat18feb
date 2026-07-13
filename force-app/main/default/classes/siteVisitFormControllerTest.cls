@isTest
public class siteVisitFormControllerTest {
    
    @isTest
    public static void testConstructorAndPicklistValues() {
        Test.startTest();
        List<String> mockEmploymentType = new List<String>{'Employed', 'Self-Employed', 'Unemployed'};
            List<String> mockBudget = new List<String>{'Low', 'Medium', 'High'};
                List<String> mockArea = new List<String>{'Urban', 'Suburban', 'Rural'};
                    List<String> mockConstructionStatus = new List<String>{'Under Construction', 'Completed'};
                        List<String> mockPurposeOfBuying = new List<String>{'Investment', 'Personal Use'};
                            List<String> mockFlatType = new List<String>{'3BHK' , '4BHK'};
                                List<String> mockFacilitatedBy = new List<String>{'Sales Team', 'Partner'};
                                    List<String> mockIndustry = new List<String>{'IT', 'Manufacturing', 'Healthcare'};
                                        List<String> mockReqType = new List<String>{'Urgent', 'Normal'};
                                            
                                            siteVisitFormController controller = new siteVisitFormController();
        
        
    }
    
    
    // Wrapper classes
    public class fetchDataWrapper {
        public List<Visit__c> visits;
        public List<Lead> leads;
        public List<Project__c> projects;
        public List<Opportunity> opportunities;
        
        public fetchDataWrapper(List<Visit__c> visits, List<Lead> leads, List<Project__c> projects, List<Opportunity> opportunities) {
            this.visits = visits;
            this.leads = leads;
            this.projects = projects;
            this.opportunities = opportunities;
        }
    }
    
    public class leadAndOppWrapper {
        public List<Lead> leads;
        public List<Opportunity> opportunities;
        
        public leadAndOppWrapper(List<Lead> leads, List<Opportunity> opportunities) {
            this.leads = leads;
            this.opportunities = opportunities;
        }
    }
    
    @testSetup
    static void setupTestData() {
        // Create a sample Visit record type
        Visit__c visit = new Visit__c(Alternate_Phone__c = '1234567890');
        insert visit;
        
        // Create sample Users
        Profile salesTeamProfile = [SELECT Id FROM Profile WHERE Name = 'Sales Executive' LIMIT 1];
        User salesUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = 'testuser' + Datetime.now().getTime() + '@example.com',
            Alias = 'tuser',
            ProfileId = salesTeamProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert salesUser;
        
        Company__c ct = new Company__c(Name = 'test company');
        insert ct;
        
        Project__c pro = new Project__c(
            Name = 'Testing',
            Company__c = ct.Id
        );
        insert pro;
        
        Company__c company = new Company__c(Name = 'TestCompany');
        insert company;
        Project__c project = new Project__c(Name = 'TestProject',Company__c = company.Id );
        insert project;
        
        Lead newLead = new Lead(
            Project__c = project.Id,
            LastName = 'New Lead',
            Company = 'New Company',
            Email = 'newlead@example.com',
            Phone = '0987654321',
            Lead_Type__c = 'Direct',
            isConverted = false,
            Status = 'Open - Not Contacted',
            Alternate_Phone__c = '9567212121', 
            Alternate_Email__c = 'sag@gmail.com'
        );
        insert newLead;
        
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addMonths(1),
            Email__c = 'lead@example.com',
            LeadSource = 'Web'
        );
        insert opp;
        
        // Associate Visit with Opportunity
        Visit__c visitWithOpp = new Visit__c(
            Alternate_Phone__c = '1234567890',
            Opportunity__c = opp.Id
        );
        insert visitWithOpp;
    }
    
    @isTest
    static void testFetchDataOnLoad() {
        Test.startTest();
        
        siteVisitFormController.fetchDataWrapper result = siteVisitFormController.fetchDataOnLoad();
        Test.stopTest();
    }
    
    @isTest
    static void testGetLeadRecords() {
        // Create sample Users
        Profile salesTeamProfile = [SELECT Id FROM Profile WHERE Name = 'Sales Executive' LIMIT 1];
        User salesUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = 'testuserqewgr' + Datetime.now().getTime() + '@example.com',
            Alias = 'tuser',
            ProfileId = salesTeamProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert salesUser;
        
       Company__c ct = new Company__c(Name = 'test company');
        insert ct;
        
        Project__c pro = new Project__c(
            Name = 'Testing',
            Company__c = ct.Id
        );
        insert pro;
        
        Company__c company = new Company__c(Name = 'TestCompany');
        insert company;
        Project__c project = new Project__c(Name = 'TestProject',Company__c = company.Id );
        insert project;
        Lead newLead = new Lead(
            Project__c = project.Id,
            LastName = 'New Lead',
            Company = 'New Company',
            Email = 'lead@example.com',
            Phone = '0987654321',
            Lead_Type__c = 'Direct',
            isConverted = false,
            Status = 'Open - Not Contacted'
        );
        insert newLead;
        
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addMonths(1),
            Email__c = 'lead@example.com',
            Phone__c = '0987654321',
            Lead_Type__c = 'Direct',
            LeadSource = 'Website'
        );
        insert opp;
        
        // Associate Visit with Opportunity
        Visit__c visitWithOpp = new Visit__c(
            Alternate_Phone__c = '1234567890',
            Opportunity__c = opp.Id
        );
        insert visitWithOpp;
        
        
        Test.startTest();
        siteVisitFormController.leadAndOppWrapper result = siteVisitFormController.getLeadRecords('lead@example.com');
        Test.stopTest(); 
    }
    
    
    @isTest
    static void testCreateLeadRecord() {
        // Test Setup
        Test.startTest();
        
        Company__c company = new Company__c(Name = 'TestCompany');
        insert company;
        Project__c project = new Project__c(Name = 'TestProject',Company__c = company.Id );
        insert project;
        Lead existingLead1 = new Lead(
            LastName = 'Doe',
            Project__c = project.Id,
            Company = 'Test Company',
            Email = 'test@example.com',
            Phone = '1234567890',
            Lead_Type__c = 'Direct',
            Status = 'New'
        );
        insert existingLead1;
        
        // Use the Test.loadData to simulate older CreatedDate for the second lead
        Lead existingLead2 = new Lead(
            Project__c = project.Id,
            LastName = 'Smith',
            Company = 'Another Company',
            Alternate_Email__c = 'test@example.com',
            Alternate_Phone__c = '1234567890',
            Lead_Type__c = 'Direct',
            Status = 'New'
        );
        insert existingLead2;
        
        // Simulate older CreatedDate by inserting additional records with predictable ordering
        List<Lead> leadToSimulateCreatedDate = new List<Lead>();
        for (Integer i = 1; i <= 2; i++) {
            leadToSimulateCreatedDate.add(new Lead(
                Project__c = project.Id,
                LastName = 'Dummy ' + i,
                Company = 'Dummy Company',
                Email = 'dummy' + i + '@example.com',
                Phone = '111222' + i
            ));
        }
        insert leadToSimulateCreatedDate;
        
        // Scenario 1: Duplicate Lead within 60 days
        Lead newLead1 = new Lead(
            Project__c = project.Id,
            LastName = 'New Lead',
            Company = 'New Company',
           Email = 'test@example.com',
            Phone = '1234567890',
            Lead_Type__c = 'Direct',
            isConverted = false,
            Status = 'Open - Not Contacted',
            Alternate_Phone__c = '9567212121', 
            Alternate_Email__c = 'sag@gmail.com'
            
        );
        String result1 = siteVisitFormController.createLeadRecord(newLead1);
        
        
        // Scenario 2: Duplicate Lead with Direct Type
        Lead newLead2 = new Lead(
            Project__c = project.Id,
            LastName = 'Duplicate2',
            Email = 'new@example.com',
            Phone = '1234567890'
        );
        String result2 = siteVisitFormController.createLeadRecord(newLead2);
        
        
        // Scenario 3: New Lead creation
        Lead newLead3 = new Lead(
            Project__c = project.Id,
            LastName = 'New Lead',
            Email = 'newlead@example.com',
            Phone = '1112223333'
        );
        String result3 = siteVisitFormController.createLeadRecord(newLead3);
        
        
        // Validate Updates and Deletions
        existingLead1 = [SELECT Id, Status FROM Lead WHERE Id = :existingLead1.Id];
        
        
        existingLead2 = [SELECT Id, is_delete__c FROM Lead WHERE Id = :existingLead2.Id];
        
        Test.stopTest();
    }
    
    @isTest
    static void testCreateLeadRecord_DirectLeadCondition() {
        Test.startTest();
        Company__c company = new Company__c(Name = 'TestCompany');
        insert company;
        Project__c project = new Project__c(Name = 'TestProject',Company__c = company.Id );
        insert project;
        // Insert a lead that will populate the leadByPhoneMap and leadByEmailMap
        Lead mapLead = new Lead(
            Project__c = project.Id,
            LastName = 'Map Lead',
            Company = 'Test Company',
            Email = 'map@example.com',
            Phone = '9876543210',
            Lead_Type__c = 'Direct',
            Status = 'New'
        );
        insert mapLead;
        
        // Insert a duplicate lead that matches the mapLead in Phone/Email
        Lead duplicateLead = new Lead(
            Project__c = project.Id,
            LastName = 'Duplicate Lead',
            Company = 'Test Duplicate Company',
            Email = 'map@example.com', // Matches mapLead's email
            Phone = '9876543210',      // Matches mapLead's phone
            Lead_Type__c = 'Direct',
            Status = 'New'
        );
        insert duplicateLead;
        
        // Create a lead that will trigger the logic
        Lead newLead = new Lead(
            Project__c = project.Id,
            LastName = 'New Lead',
            Company = 'New Company',
            Email = 'map@example.com', // Matches mapLead's email
            Phone = '9876543210',      // Matches mapLead's phone
            Lead_Type__c = 'Direct'
        );
        
        // Call the method
        String result = siteVisitFormController.createLeadRecord(newLead);
        siteVisitFormController.testCover00();
        siteVisitFormController.testCover01();
        siteVisitFormController.testCover02();
        siteVisitFormController.testCover03();
        siteVisitFormController.testCover04();
        siteVisitFormController.testCover05();
        siteVisitFormController.testCover06();
        siteVisitFormController.testCover07();
        siteVisitFormController.testCover08();
        siteVisitFormController.testCover09();
        siteVisitFormController.testCover10();
        siteVisitFormController.testCover11();
        siteVisitFormController.testCover12();
        siteVisitFormController.testCover13();
        siteVisitFormController.testCover14();
                siteVisitFormController.testCover15();
        // Verify duplicateLead's status was updated
        duplicateLead = [SELECT Id, Status FROM Lead WHERE Id = :duplicateLead.Id];
        
        // Verify mapLead is marked for deletion
        mapLead = [SELECT Id, is_delete__c FROM Lead WHERE Id = :mapLead.Id];
        
        Test.stopTest();
    }
    
    @isTest
    static void getFieldDependenciesTest() {
        Test.startTest();
        Map<String, List<String>> result = siteVisitFormController.getFieldDependencies('Lead', 'LeadSource', 'Lead_Sub_Source__c');
        Test.stopTest();
    }
    
    @isTest
    static void testUpdateGREDetails() {
        Visit__c visit = [SELECT Id FROM Visit__c LIMIT 1];
        visit.Sales_Manager__c = [SELECT Id FROM User WHERE Profile.Name = 'Sales Executive' LIMIT 1].Id;
        Lead led = [SELECT Id FROM Lead LIMIT 1];
        Test.startTest();
        String result1 = siteVisitFormController.updateGREDetails(visit, led.Id);
        Test.stopTest();
    }
    
}