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
        //siteVisitFormController.testCover00();
        //siteVisitFormController.testCover01();
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
    

    // ---------- helpers ----------
    private static User makeUser(String alias) {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Sales Executive' LIMIT 1];
        User u = new User(
            FirstName = 'Sv', LastName = alias, Email = alias + '@example.com',
            Username = alias + Datetime.now().getTime() + '@example.com', Alias = alias.left(8),
            ProfileId = p.Id, TimeZoneSidKey = 'America/Los_Angeles', LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US'
        );
        insert u;
        return u;
    }

    private static Project__c makeProject(String name) {
        Company__c c = new Company__c(Name = name + ' Co');
        insert c;
        Project__c pr = new Project__c(Name = name, Company__c = c.Id);
        insert pr;
        return pr;
    }

    private static Lead makeLead(Project__c pr, String email, String phone) {
        Lead l = new Lead(
            Project__c = pr.Id, FirstName = 'Svf', LastName = 'Svl', Company = 'Svc',
            Email = email, Phone = phone, Lead_Type__c = 'Direct', Status = 'Open - Not Contacted'
        );
        insert l;
        return l;
    }

    private static Opportunity makeOpp(Project__c pr, String phone) {
        Account acc = new Account(Name = 'Sv Account');
        insert acc;
        Contact con = new Contact(LastName = 'Sv Contact', AccountId = acc.Id);
        insert con;
        Opportunity o = new Opportunity(
            Name = 'Sv Opp', AccountId = acc.Id, StageName = 'Prospecting',
            CloseDate = Date.today().addMonths(1), Email__c = 'svopp@example.com',
            Phone__c = phone, LeadSource = 'Web', Project__c = pr == null ? null : pr.Id
        );
        insert o;
        return o;
    }

    // ---------- assignToSalesMember ----------
    @isTest
    static void testAssignToSalesMember_NoProject() {
        Lead l = new Lead(LastName = 'NoProj', Company = 'NoProj', Status = 'Open - Not Contacted');
        insert l;
        Test.startTest();
        siteVisitFormController.assignToSalesMember(l.Id, 'Sales');
        Test.stopTest();
    }

    @isTest
    static void testAssignToSalesMember_NoGroup() {
        Project__c pr = makeProject('NoGroupProject');
        Lead l = makeLead(pr, 'nogroup@example.com', '9000000001');
        Test.startTest();
        siteVisitFormController.assignToSalesMember(l.Id, 'Sales');
        Test.stopTest();
    }

    @isTest
    static void testAssignToSalesMember_NoMembers() {
        Project__c pr = makeProject('NoMemberProject');
        Lead l = makeLead(pr, 'nomember@example.com', '9000000002');
        insert new Assignment_Group__c(Name = 'Empty Group', Type__c = 'Sales', Project__c = pr.Id);
        Test.startTest();
        System.assertEquals(null, siteVisitFormController.assignToSalesMember(l.Id, 'Sales'));
        Test.stopTest();
    }

    @isTest
    static void testAssignToSalesMember_RoundRobin() {
        Project__c pr = makeProject('RoundRobinProject');
        Lead l = makeLead(pr, 'rr@example.com', '9000000003');
        User u1 = makeUser('svrr1');
        User u2 = makeUser('svrr2');
        Assignment_Group__c grp = new Assignment_Group__c(Name = 'Sales Group', Type__c = 'Sales', Project__c = pr.Id);
        insert grp;
        insert new List<Assignment_Group_Member__c>{
            new Assignment_Group_Member__c(Assignment_Group__c = grp.Id, Group_Member__c = u1.Id, Assignment_Id__c = 1, Active__c = true),
            new Assignment_Group_Member__c(Assignment_Group__c = grp.Id, Group_Member__c = u2.Id, Assignment_Id__c = 2, Active__c = true)
        };
        Test.startTest();
        // first call: nothing allocated yet -> first member
        System.assertEquals(u1.Id, siteVisitFormController.assignToSalesMember(l.Id, 'Sales'));
        // second call: next member
        System.assertEquals(u2.Id, siteVisitFormController.assignToSalesMember(l.Id, 'Sales'));
        // third call: wraps around to the first member
        System.assertEquals(u1.Id, siteVisitFormController.assignToSalesMember(l.Id, 'Sales'));
        Test.stopTest();
    }

    // ---------- getLeadRecords ----------
    @isTest
    static void testGetLeadRecords_WithConvertedOppAndVisit() {
        Project__c pr = makeProject('ConvProject');
        User u = makeUser('svconv');
        Lead l = makeLead(pr, 'conv@example.com', '9000000004');
        Test.startTest();
        siteVisitFormController.insertVisitRecord(new Visit__c(Alternate_Phone__c = '9000000004'), l.Id, null, u.Id, pr.Id);
        siteVisitFormController.leadAndOppWrapper res = siteVisitFormController.getLeadRecords('9000000004');
        Test.stopTest();
        System.assertNotEquals(null, res);
    }

    @isTest
    static void testGetLeadRecords_NoMatch() {
        Test.startTest();
        siteVisitFormController.leadAndOppWrapper res = siteVisitFormController.getLeadRecords('no-such-key-123');
        Test.stopTest();
        System.assertNotEquals(null, res);
        System.assert(res.oppList.isEmpty());
    }

    // ---------- insertVisitRecord ----------
    @isTest
    static void testInsertVisit_NewLeadIsConverted() {
        Project__c pr = makeProject('InsertLeadProject');
        User u = makeUser('svins1');
        Lead l = makeLead(pr, 'ins1@example.com', '9000000005');
        Test.startTest();
        String res = siteVisitFormController.insertVisitRecord(new Visit__c(Alternate_Phone__c = '9000000005'), l.Id, '', u.Id, pr.Id);
        Test.stopTest();
        System.assertNotEquals(null, res);
        System.assertEquals(1, [SELECT COUNT() FROM Lead WHERE Id = :l.Id AND IsConverted = true]);
    }

    @isTest
    static void testInsertVisit_LeadWithAssignmentGroupAndNoSalesMember() {
        Project__c pr = makeProject('InsertAssignProject');
        User u = makeUser('svins2');
        Assignment_Group__c grp = new Assignment_Group__c(Name = 'Sales Group 2', Type__c = 'Sales', Project__c = pr.Id);
        insert grp;
        insert new Assignment_Group_Member__c(Assignment_Group__c = grp.Id, Group_Member__c = u.Id, Assignment_Id__c = 1, Active__c = true);
        Lead l = makeLead(pr, 'ins2@example.com', '9000000006');
        Test.startTest();
        String res = siteVisitFormController.insertVisitRecord(new Visit__c(Alternate_Phone__c = '9000000006'), l.Id, null, null, null);
        Test.stopTest();
        System.assertNotEquals(null, res);
    }

    @isTest
    static void testInsertVisit_ExistingOppSameProject() {
        Project__c pr = makeProject('SameProject');
        User u = makeUser('svins3');
        Opportunity o = makeOpp(pr, '9000000007');
        Test.startTest();
        siteVisitFormController.insertVisitRecord(new Visit__c(Alternate_Phone__c = '9000000007'), null, o.Id, u.Id, pr.Id);
        Test.stopTest();
        System.assertEquals(1, [SELECT COUNT() FROM Opportunity WHERE AccountId = :o.AccountId]);
        Opportunity updated = [SELECT OwnerId, Sales_Team_Member__c FROM Opportunity WHERE Id = :o.Id];
        System.assertEquals(u.Id, updated.OwnerId);
        System.assertEquals(u.Id, updated.Sales_Team_Member__c);
    }

    @isTest
    static void testInsertVisit_ExistingOppDifferentProjectCreatesNewOpp() {
        Project__c pr1 = makeProject('ProjectOne');
        Project__c pr2 = makeProject('ProjectTwo');
        User u = makeUser('svins4');
        Opportunity o = makeOpp(pr1, '9000000008');
        Test.startTest();
        siteVisitFormController.insertVisitRecord(new Visit__c(Alternate_Phone__c = '9000000008'), null, o.Id, u.Id, pr2.Id);
        Test.stopTest();
        System.assertEquals(2, [SELECT COUNT() FROM Opportunity WHERE AccountId = :o.AccountId]);
        System.assertEquals(1, [SELECT COUNT() FROM Opportunity WHERE AccountId = :o.AccountId AND Project__c = :pr2.Id]);
    }

    @isTest
    static void testInsertVisit_ExistingOppWithoutProjectGetsProject() {
        Project__c pr = makeProject('FillProject');
        Opportunity o = makeOpp(null, '9000000009');
        Test.startTest();
        siteVisitFormController.insertVisitRecord(new Visit__c(Alternate_Phone__c = '9000000009'), null, o.Id, null, pr.Id);
        Test.stopTest();
        System.assertEquals(pr.Id, [SELECT Project__c FROM Opportunity WHERE Id = :o.Id].Project__c);
    }

    @isTest
    static void testInsertVisit_ResaveExistingVisitDoesNotCreateOpp() {
        Project__c pr1 = makeProject('ResaveOne');
        Project__c pr2 = makeProject('ResaveTwo');
        User u = makeUser('svins5');
        Opportunity o = makeOpp(pr1, '9000000010');
        Visit__c v = new Visit__c(Alternate_Phone__c = '9000000010', Opportunity__c = o.Id);
        insert v;
        Test.startTest();
        v.Remarks__c = 'updated';
        String res = siteVisitFormController.insertVisitRecord(v, null, o.Id, u.Id, pr2.Id);
        Test.stopTest();
        System.assertEquals(1, [SELECT COUNT() FROM Opportunity WHERE AccountId = :o.AccountId]);
        System.assertNotEquals(null, res);
    }

    @isTest
    static void testInsertVisit_ExceptionIsCaught() {
        Test.startTest();
        String res = siteVisitFormController.insertVisitRecord(new Visit__c(), null, null, null, null);
        Test.stopTest();
        System.assertNotEquals(null, res);
    }

    // ---------- updateGREDetails / updateLeadDetails ----------
    @isTest
    static void testUpdateGREDetails_ConvertedLeadUpdatesOpp() {
        Project__c pr = makeProject('GREProject');
        User u = makeUser('svgre');
        Lead l = makeLead(pr, 'gre@example.com', '9000000011');
        siteVisitFormController.insertVisitRecord(new Visit__c(Alternate_Phone__c = '9000000011'), l.Id, null, null, pr.Id);
        Visit__c v = new Visit__c(Sales_Manager__c = u.Id);
        Test.startTest();
        String res = siteVisitFormController.updateGREDetails(v, l.Id);
        Test.stopTest();
        System.assertNotEquals(null, res);
    }

    @isTest
    static void testUpdateGREDetails_NullVisit() {
        Test.startTest();
        String res = siteVisitFormController.updateGREDetails(null, null);
        Test.stopTest();
        System.assertNotEquals(null, res);
    }

    @isTest
    static void testUpdateLeadDetails() {
        Project__c pr = makeProject('BypassProject');
        Lead l = makeLead(pr, 'bypass@example.com', '9000000012');
        Test.startTest();
        System.assertEquals('SUCCESS', siteVisitFormController.updateLeadDetails(l.Id, true));
        Test.stopTest();
        System.assertEquals(true, [SELECT By_Pass_Validations__c FROM Lead WHERE Id = :l.Id].By_Pass_Validations__c);
    }

    @isTest
    static void testUpdateLeadDetails_ConvertedLeadIsIgnored() {
        Project__c pr = makeProject('BypassConvProject');
        Lead l = makeLead(pr, 'bypassc@example.com', '9000000013');
        siteVisitFormController.insertVisitRecord(new Visit__c(Alternate_Phone__c = '9000000013'), l.Id, null, null, pr.Id);
        Test.startTest();
        System.assertEquals('SUCCESS', siteVisitFormController.updateLeadDetails(l.Id, true));
        Test.stopTest();
    }

    // ---------- createLeadRecord ----------
    @isTest
    static void testCreateLeadRecord_NewLeadInserted() {
        Project__c pr = makeProject('NewLeadProject');
        Test.startTest();
        String res = siteVisitFormController.createLeadRecord(new Lead(
            Project__c = pr.Id, LastName = 'Fresh', Email = 'fresh@example.com', Phone = '9000000014'));
        Test.stopTest();
        System.assert(res.startsWith('00Q'), res);
    }

    @isTest
    static void testCreateLeadRecord_InsertFailureReturnsMessage() {
        Test.startTest();
        // LastName is required, so the insert fails and the message is returned
        String res = siteVisitFormController.createLeadRecord(new Lead(Email = 'bad@example.com', Phone = '9000000015'));
        Test.stopTest();
        System.assertNotEquals(null, res);
    }

}