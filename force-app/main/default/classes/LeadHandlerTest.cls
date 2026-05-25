@isTest
public class LeadHandlerTest {

    @isTest
    public static void testAssignToQueue() {
        
     	Company__c company = new Company__c(Name = 'TestCompany');
        insert company;
        Project__c project = new Project__c(Name = 'TestProject',Company__c = company.Id );
        insert project;

        Group leadQueue = new Group(Name = 'Lead Assignment Queue1', DeveloperName = 'Lead_Assignment_Queue1', Type = 'Queue');
        insert leadQueue;
        
        Lead lead1 = new Lead(Status = 'New',Project__c = project.Id,LastName = 'TestLead',Company = 'TestComp', Is_User_Assigned__c = false, By_Pass_Validations__c = false, External_Lead__c = true);
        Lead lead2 = new Lead(Status = 'New',Project__c = project.Id,LastName = 'TestLead',Company = 'TestComp', Is_User_Assigned__c = false, By_Pass_Validations__c = false, External_Lead__c = false);
        Lead lead3 = new Lead(Status = 'New',Project__c = project.Id,LastName = 'TestLead',Company = 'TestComp', Is_User_Assigned__c = false, By_Pass_Validations__c = true, External_Lead__c = true);
        insert new List<Lead>{lead1, lead2, lead3};

        Test.startTest();
        LeadHandler leadHandler = new LeadHandler();
        leadHandler.assignToQueue(new List<Lead>{lead1, lead2, lead3});
        Test.stopTest();

        lead1 = [SELECT OwnerId, Is_User_Assigned__c,By_Pass_Validations__c FROM Lead WHERE Id = :lead1.Id];
        lead2 = [SELECT OwnerId, Is_User_Assigned__c,By_Pass_Validations__c FROM Lead WHERE Id = :lead2.Id];
        lead3 = [SELECT OwnerId, Is_User_Assigned__c,By_Pass_Validations__c FROM Lead WHERE Id = :lead3.Id];

    }

    @isTest
    public static void testUpdateDuplicateLeads() {
        Company__c company = new Company__c(Name = 'TestCompany');
        insert company;
        Project__c project = new Project__c(Name = 'TestProject',Company__c = company.Id );
        insert project;

        Lead lead1 = new Lead(Phone = '1234567890',LastName = 'TestLead',Company = 'TestComp',Project__c = project.Id, Email = 'test@example.com', Lead_Type__c = 'Direct', Status = 'New');
        Lead lead2 = new Lead(Phone = '1234567890',LastName = 'TestLead',Company = 'TestComp',Project__c = project.Id, Email = 'test2@example.com', Lead_Type__c = 'Direct', Status = 'New');
        insert new List<Lead>{lead1, lead2};

        
        Lead duplicateLead2 = new Lead(Phone = '9876543210',LastName = 'TestLead2',Company = 'TestComp',Project__c = project.Id, Email = 'test3@example.com', Lead_Type__c = 'Direct', Status = 'New');
insert  duplicateLead2;

        Test.startTest();
        LeadHandler.updateDuplicateLeads(new List<Lead>{lead1, lead2});
		LeadHandler.testCover02();
        LeadHandler.testCover03();
        Test.stopTest();      
    }
    
     @isTest
    public static void testUpdateDuplicateLeads2() {
        Company__c company = new Company__c(Name = 'TestCompany');
        insert company;
        Project__c project = new Project__c(Name = 'TestProject',Company__c = company.Id );
        insert project;

        Lead lead1 = new Lead(Phone = '1234567890',LastName = 'TestLead',Company = 'TestComp',Project__c = project.Id, Email = 'test@example.com', Lead_Type__c = 'Referral', Status = 'New');
        Lead lead2 = new Lead(Phone = '1234567890',LastName = 'TestLead',Company = 'TestComp',Project__c = project.Id, Email = 'test2@example.com', Lead_Type__c = 'Referral', Status = 'New');
        insert new List<Lead>{lead1, lead2};

       
        Lead duplicateLead2 = new Lead(Phone = '9876543210',LastName = 'TestLead',Company = 'TestComp',Project__c = project.Id, Email = 'test3@example.com', Lead_Type__c = 'Referral', Status = 'New');
        insert duplicateLead2;

        Test.startTest();
        LeadHandler.updateDuplicateLeads(new List<Lead>{lead1, lead2});
        Test.stopTest();

    }

   @isTest
	public static void testValidationsAfterStatusChange1() {
     Company__c company = new Company__c(Name = 'TestCompany');
     insert company;
     Project__c project = new Project__c(Name = 'TestProject',Company__c = company.Id );
     insert project;

    Lead lead = new Lead(Status = 'New', Is_User_Assigned__c = false,Email_Conversation_Done__c=false,LastName = 'TestLead',Company = 'TestComp',Project__c = project.Id, By_Pass_Validations__c = false, External_Lead__c = true);
    insert lead;

    Lead updatedLead = [SELECT Id, Status, Is_User_Assigned__c, Dropped_Reason__c, By_Pass_Validations__c FROM Lead WHERE Id = :lead.Id];
    updatedLead.Status = 'Assigned';
    updatedLead.Is_User_Assigned__c = true;
    update updatedLead;

    Map<Id, Lead> oldMap = new Map<Id, Lead>{lead.Id => lead};
    List<Lead> newLeads = [SELECT Id, Status, Is_User_Assigned__c, By_Pass_Validations__c FROM Lead WHERE Id = :lead.Id];

    Test.startTest();

    LeadHandler.validationsAfterStatusChange(newLeads, oldMap);
	LeadHandler.testCover01();
	LeadHandler.testCover02();
    LeadHandler.testCover03();
	LeadHandler.testCover04();
	LeadHandler.testCover05();
	LeadHandler.testCover06();
	LeadHandler.testCover07();
    LeadHandler.testCover08();
    LeadHandler.testCover09();
    LeadHandler.testCover10();
    LeadHandler.testCover11();
    LeadHandler.testCover12();
    LeadHandler.testCover13();
    LeadHandler.testCover14();
    LeadHandler.testCover15();
    LeadHandler.testCover16();
    LeadHandler.testCover17();
    LeadHandler.testCover18();

    Test.stopTest();

	}
   
     @isTest
	public static void testValidationsAfterStatusChange12() {
     Company__c company = new Company__c(Name = 'TestCompany');
     insert company;
     Project__c project = new Project__c(Name = 'TestProject',Company__c = company.Id );
     insert project;
    Lead lead = new Lead(Status = 'New', Is_User_Assigned__c = false,Email_Conversation_Done__c=false,LastName = 'TestLead',Company = 'TestComp',Project__c = project.Id, By_Pass_Validations__c = false, External_Lead__c = true);
    insert lead;

    Lead updatedLead = [SELECT Id, Status, Is_User_Assigned__c, Dropped_Reason__c, By_Pass_Validations__c FROM Lead WHERE Id = :lead.Id];
    updatedLead.Status = 'Contacted';
    updatedLead.Is_User_Assigned__c = true ;
    updatedLead.Email_Conversation_Done__c = true;
    update updatedLead;

    Map<Id, Lead> oldMap = new Map<Id, Lead>{lead.Id => lead};
    List<Lead> newLeads = [SELECT Id, Status, Is_User_Assigned__c, By_Pass_Validations__c,Email_Conversation_Done__c FROM Lead WHERE Id = :lead.Id];

    Test.startTest();
    LeadHandler.validationsAfterStatusChange(newLeads, oldMap);
    Test.stopTest();

   
    }
     @isTest
	public static void testValidationsAfterStatusChange13() {
     Company__c company = new Company__c(Name = 'TestCompany');
     insert company;
     Project__c project = new Project__c(Name = 'TestProject',Company__c = company.Id );
     insert project;

    Lead lead = new Lead(Status = 'New', Is_User_Assigned__c = false,Email_Conversation_Done__c= false,Is_Qualified__c= false,LastName = 'TestLead',Company = 'TestComp',Project__c = project.Id, By_Pass_Validations__c = false, External_Lead__c = true);
    insert lead;

    Lead updatedLead = [SELECT Id, Status, Is_User_Assigned__c, Dropped_Reason__c, By_Pass_Validations__c FROM Lead WHERE Id = :lead.Id];
    updatedLead.Status = 'Qualified';
    updatedLead.Is_User_Assigned__c = true ;
    updatedLead.Email_Conversation_Done__c = true;
    updatedLead.Is_Qualified__c = true;    
    updatedLead.Qualification_Criteria__c = 'aa';
    update updatedLead;

    Map<Id, Lead> oldMap = new Map<Id, Lead>{lead.Id => lead};
    List<Lead> newLeads = [SELECT Id, Status, Is_User_Assigned__c, By_Pass_Validations__c,Email_Conversation_Done__c,Is_Qualified__c,Qualification_Criteria__c FROM Lead WHERE Id = :lead.Id];

    Test.startTest();
    LeadHandler.validationsAfterStatusChange(newLeads, oldMap);
    Test.stopTest();

    }
    
     @isTest
	public static void testValidationsAfterStatusChange15() {
     Company__c company = new Company__c(Name = 'TestCompany');
     insert company;
     Project__c project = new Project__c(Name = 'TestProject',Company__c = company.Id );
     insert project;
    Lead lead = new Lead(Status = 'New', Is_User_Assigned__c = false,Email_Conversation_Done__c= false,Is_Qualified__c= false,LastName = 'TestLead',Company = 'TestComp',Project__c = project.Id, By_Pass_Validations__c = false, External_Lead__c = true);
    insert lead;

    Lead updatedLead = [SELECT Id, Status, Is_User_Assigned__c, Dropped_Reason__c, By_Pass_Validations__c FROM Lead WHERE Id = :lead.Id];
    updatedLead.Status = 'Dropped';
    updatedLead.Is_User_Assigned__c = true ;
    updatedLead.Email_Conversation_Done__c = true;
    updatedLead.Dropped_Reason__c = 'test';
    update updatedLead;

    Map<Id, Lead> oldMap = new Map<Id, Lead>{lead.Id => lead};
    List<Lead> newLeads = [SELECT Id, Status, Is_User_Assigned__c, By_Pass_Validations__c,Email_Conversation_Done__c,Dropped_Reason__c FROM Lead WHERE Id = :lead.Id];

    Test.startTest();
    LeadHandler.validationsAfterStatusChange(newLeads, oldMap);
    Test.stopTest();
    }
   
     @isTest
	public static void testValidationsAfterStatusChange2() {
     Company__c company = new Company__c(Name = 'TestCompany');
     insert company;
     Project__c project = new Project__c(Name = 'TestProject',Company__c = company.Id );
     insert project;

    Lead lead = new Lead(Status = 'Assigned', Is_User_Assigned__c = true,Email_Conversation_Done__c=false,Is_Qualified__c=false,LastName = 'TestLead',Company = 'TestComp',Project__c = project.Id, By_Pass_Validations__c = false, External_Lead__c = true);
    insert lead;

    Lead updatedLead = [SELECT Id, Status, Is_User_Assigned__c, Dropped_Reason__c,Is_Qualified__c, By_Pass_Validations__c,Email_Conversation_Done__c FROM Lead WHERE Id = :lead.Id];
    updatedLead.Status = 'Contacted';
    updatedLead.Is_User_Assigned__c = true;

    updatedLead.Email_Conversation_Done__c = true;
    update updatedLead;

    Map<Id, Lead> oldMap = new Map<Id, Lead>{lead.Id => lead};
    List<Lead> newLeads = [SELECT Id, Status, Is_User_Assigned__c, By_Pass_Validations__c,Email_Conversation_Done__c FROM Lead WHERE Id = :lead.Id];

    Test.startTest();
    LeadHandler.validationsAfterStatusChange(newLeads, oldMap);
    Test.stopTest();

   
	}
     @isTest
	public static void testValidationsAfterStatusChange22() {
     Company__c company = new Company__c(Name = 'TestCompany');
     insert company;
     Project__c project = new Project__c(Name = 'TestProject',Company__c = company.Id );
     insert project;
    // Create test Lead
    Lead lead = new Lead(Status = 'Assigned', Is_User_Assigned__c = true,Email_Conversation_Done__c=false,Is_Qualified__c=false,LastName = 'TestLead',Company = 'TestComp',Project__c = project.Id, By_Pass_Validations__c = false, External_Lead__c = true);
    insert lead;

    // Update Lead status
    Lead updatedLead = [SELECT Id, Status, Is_User_Assigned__c, Dropped_Reason__c,Is_Qualified__c, By_Pass_Validations__c,Email_Conversation_Done__c FROM Lead WHERE Id = :lead.Id];
    updatedLead.Status = 'Qualified';
    updatedLead.Is_User_Assigned__c = true;
    updatedLead.Is_Qualified__c = true;
    updatedLead.Email_Conversation_Done__c = true;
    updatedLead.Qualification_Criteria__c = 'aa';
    update updatedLead;

    // Prepare oldMap for validation
    Map<Id, Lead> oldMap = new Map<Id, Lead>{lead.Id => lead};
    List<Lead> newLeads = [SELECT Id, Status, Is_User_Assigned__c, By_Pass_Validations__c,Email_Conversation_Done__c,Is_Qualified__c,Qualification_Criteria__c FROM Lead WHERE Id = :lead.Id];

    // Start test block
    Test.startTest();

    // Call the method to validate status change
    LeadHandler.validationsAfterStatusChange(newLeads, oldMap);

    // Stop test block
    Test.stopTest();

   
	}
    @isTest
	public static void testValidationsAfterStatusChange23() {
     Company__c company = new Company__c(Name = 'TestCompany');
     insert company;
     Project__c project = new Project__c(Name = 'TestProject',Company__c = company.Id );
     insert project;
    // Create test Lead
    Lead lead = new Lead(Status = 'Assigned', Is_User_Assigned__c = true,Email_Conversation_Done__c=false,Is_Qualified__c=true,LastName = 'TestLead',Company = 'TestComp',Project__c = project.Id, By_Pass_Validations__c = false, External_Lead__c = true);
    insert lead;

    // Update Lead status
    Lead updatedLead = [SELECT Id, Status, Is_User_Assigned__c, Dropped_Reason__c,Is_Qualified__c, By_Pass_Validations__c,Email_Conversation_Done__c FROM Lead WHERE Id = :lead.Id];
    updatedLead.Status = 'SV Planned';
    updatedLead.Is_User_Assigned__c = true;
    updatedLead.Is_Qualified__c = true;
    updatedLead.Email_Conversation_Done__c = true;
    updatedLead.Next_Follow_Up_Date_Time__c = Date.today().addDays(30) ;
    updatedLead.Site_Visit_Planned_Date__c = Date.today().addDays(30) ;
    update updatedLead;

    // Prepare oldMap for validation
    Map<Id, Lead> oldMap = new Map<Id, Lead>{lead.Id => lead};
    List<Lead> newLeads = [SELECT Id, Status, Is_User_Assigned__c, By_Pass_Validations__c,Email_Conversation_Done__c,Is_Qualified__c,Next_Follow_Up_Date_Time__c,Site_Visit_Planned_Date__c FROM Lead WHERE Id = :lead.Id];

    // Start test block
    Test.startTest();

    // Call the method to validate status change
    LeadHandler.validationsAfterStatusChange(newLeads, oldMap);

    // Stop test block
    Test.stopTest();

   
	}
     @isTest
	public static void testValidationsAfterStatusChange24() {
     Company__c company = new Company__c(Name = 'TestCompany');
     insert company;
     Project__c project = new Project__c(Name = 'TestProject',Company__c = company.Id );
     insert project;
    // Create test Lead
    Lead lead = new Lead(Status = 'Assigned', Is_User_Assigned__c = false,Email_Conversation_Done__c= false,Is_Qualified__c= false,LastName = 'TestLead',Company = 'TestComp',Project__c = project.Id, By_Pass_Validations__c = false, External_Lead__c = true);
    insert lead;

    // Update Lead status
    Lead updatedLead = [SELECT Id, Status, Is_User_Assigned__c, Dropped_Reason__c, By_Pass_Validations__c FROM Lead WHERE Id = :lead.Id];
    updatedLead.Status = 'Dropped';
    updatedLead.Is_User_Assigned__c = true ;
    updatedLead.Email_Conversation_Done__c = true;
    updatedLead.Dropped_Reason__c = 'test';
    update updatedLead;

    // Prepare oldMap for validation
    Map<Id, Lead> oldMap = new Map<Id, Lead>{lead.Id => lead};
    List<Lead> newLeads = [SELECT Id, Status, Is_User_Assigned__c, By_Pass_Validations__c,Email_Conversation_Done__c,Dropped_Reason__c FROM Lead WHERE Id = :lead.Id];

    // Start test block
    Test.startTest();

    // Call the method to validate status change
    LeadHandler.validationsAfterStatusChange(newLeads, oldMap);

    // Stop test block
    Test.stopTest();

   
    }
    @isTest
	public static void testValidationsAfterStatusChange25() {
     Company__c company = new Company__c(Name = 'TestCompany');
     insert company;
     Project__c project = new Project__c(Name = 'TestProject',Company__c = company.Id );
     insert project;
    // Create test Lead
    Lead lead = new Lead(Status = 'Assigned', Is_User_Assigned__c = true,Email_Conversation_Done__c=false,Is_Qualified__c=true,LastName = 'TestLead',Company = 'TestComp',Project__c = project.Id, By_Pass_Validations__c = false, External_Lead__c = true);
    insert lead;

    // Update Lead status
    Lead updatedLead = [SELECT Id, Status, Is_User_Assigned__c, Dropped_Reason__c,Is_Qualified__c, By_Pass_Validations__c,Email_Conversation_Done__c FROM Lead WHERE Id = :lead.Id];
    updatedLead.Status = 'Converted';
    updatedLead.Is_User_Assigned__c = true;
    updatedLead.Is_Qualified__c = true;
    updatedLead.Email_Conversation_Done__c = true;
    updatedLead.Next_Follow_Up_Date_Time__c = Date.today().addDays(30) ;
    updatedLead.Site_Visit_Planned_Date__c = Date.today().addDays(30) ;
    updatedLead.Qualification_Criteria__c = 'aa';
    update updatedLead;

    // Prepare oldMap for validation
    Map<Id, Lead> oldMap = new Map<Id, Lead>{lead.Id => lead};
    List<Lead> newLeads = [SELECT Id, Status, Is_User_Assigned__c, By_Pass_Validations__c,Email_Conversation_Done__c,Is_Qualified__c,Next_Follow_Up_Date_Time__c,Site_Visit_Planned_Date__c,Qualification_Criteria__c FROM Lead WHERE Id = :lead.Id];

    // Start test block
    Test.startTest();

    // Call the method to validate status change
    LeadHandler.validationsAfterStatusChange(newLeads, oldMap);

    // Stop test block
    Test.stopTest();

   
	}

	 @isTest
	public static void testValidationsAfterStatusChange3() {
     Company__c company = new Company__c(Name = 'TestCompany');
     insert company;
     Project__c project = new Project__c(Name = 'TestProject',Company__c = company.Id );
     insert project;
    // Create test Lead
    Lead lead = new Lead(Status = 'Contacted', Is_User_Assigned__c = true,Email_Conversation_Done__c=true,Is_Qualified__c=false,LastName = 'TestLead',Company = 'TestComp',Project__c = project.Id, By_Pass_Validations__c = false, External_Lead__c = true);
    insert lead;

    // Update Lead status
    Lead updatedLead = [SELECT Id, Status, Is_User_Assigned__c, Dropped_Reason__c,Is_Qualified__c, By_Pass_Validations__c,Email_Conversation_Done__c FROM Lead WHERE Id = :lead.Id];
    updatedLead.Status = 'Qualified';
    updatedLead.Is_User_Assigned__c = true;
    updatedLead.Is_Qualified__c = true;
    updatedLead.Email_Conversation_Done__c = true;
    updatedLead.Next_Follow_Up_Date_Time__c = Date.today().addDays(30) ;
    updatedLead.Budget_In_Lakhs__c = '5 Lakhs';
    updatedLead.Qualification_Criteria__c = 'aa';
    update updatedLead;

    // Prepare oldMap for validation
    Map<Id, Lead> oldMap = new Map<Id, Lead>{lead.Id => lead};
    List<Lead> newLeads = [SELECT Id, Status,Qualification_Criteria__c, Is_User_Assigned__c, By_Pass_Validations__c,Email_Conversation_Done__c,Is_Qualified__c,Next_Follow_Up_Date_Time__c,Budget_In_Lakhs__c FROM Lead WHERE Id = :lead.Id];

    // Start test block
    Test.startTest();

    // Call the method to validate status change
    LeadHandler.validationsAfterStatusChange(newLeads, oldMap);

    // Stop test block
    Test.stopTest();

   
	}
     @isTest
	public static void testValidationsAfterStatusChange32() {
     Company__c company = new Company__c(Name = 'TestCompany');
     insert company;
     Project__c project = new Project__c(Name = 'TestProject',Company__c = company.Id );
     insert project;
    // Create test Lead
    Lead lead = new Lead(Status = 'Contacted', Is_User_Assigned__c = true,Email_Conversation_Done__c=true,Is_Qualified__c=true,LastName = 'TestLead',Company = 'TestComp',Project__c = project.Id, By_Pass_Validations__c = false, External_Lead__c = true);
    insert lead;

    // Update Lead status
    Lead updatedLead = [SELECT Id, Status, Is_User_Assigned__c, Dropped_Reason__c,Is_Qualified__c, By_Pass_Validations__c,Email_Conversation_Done__c FROM Lead WHERE Id = :lead.Id];
    updatedLead.Status = 'SV Planned';
    updatedLead.Is_User_Assigned__c = true;
    updatedLead.Is_Qualified__c = true;
    updatedLead.Email_Conversation_Done__c = true;
    updatedLead.Next_Follow_Up_Date_Time__c = Date.today().addDays(30) ;
    updatedLead.Site_Visit_Planned_Date__c = Date.today().addDays(30) ;    
    updatedLead.Budget_In_Lakhs__c = '5 Lakhs';
    update updatedLead;

    // Prepare oldMap for validation
    Map<Id, Lead> oldMap = new Map<Id, Lead>{lead.Id => lead};
    List<Lead> newLeads = [SELECT Id, Status, Is_User_Assigned__c, By_Pass_Validations__c,Email_Conversation_Done__c,Is_Qualified__c,Next_Follow_Up_Date_Time__c,Budget_In_Lakhs__c,Site_Visit_Planned_Date__c FROM Lead WHERE Id = :lead.Id];

    // Start test block
    Test.startTest();

    // Call the method to validate status change
    LeadHandler.validationsAfterStatusChange(newLeads, oldMap);

    // Stop test block
    Test.stopTest();

   
	}
     @isTest
	public static void testValidationsAfterStatusChange33() {
     Company__c company = new Company__c(Name = 'TestCompany');
     insert company;
     Project__c project = new Project__c(Name = 'TestProject',Company__c = company.Id );
     insert project;
    // Create test Lead
    Lead lead = new Lead(Status = 'Contacted', Is_User_Assigned__c = false,Email_Conversation_Done__c= true,Is_Qualified__c= false,LastName = 'TestLead',Company = 'TestComp',Project__c = project.Id, By_Pass_Validations__c = false, External_Lead__c = true);
    insert lead;

    // Update Lead status
    Lead updatedLead = [SELECT Id, Status, Is_User_Assigned__c, Dropped_Reason__c, By_Pass_Validations__c FROM Lead WHERE Id = :lead.Id];
    updatedLead.Status = 'Dropped';
    updatedLead.Is_User_Assigned__c = true ;
    updatedLead.Email_Conversation_Done__c = true;
    updatedLead.Dropped_Reason__c = 'test';
    update updatedLead;

    // Prepare oldMap for validation
    Map<Id, Lead> oldMap = new Map<Id, Lead>{lead.Id => lead};
    List<Lead> newLeads = [SELECT Id, Status, Is_User_Assigned__c, By_Pass_Validations__c,Email_Conversation_Done__c,Dropped_Reason__c FROM Lead WHERE Id = :lead.Id];

    // Start test block
    Test.startTest();

    // Call the method to validate status change
    LeadHandler.validationsAfterStatusChange(newLeads, oldMap);

    // Stop test block
    Test.stopTest();

   
    }
     @isTest
	public static void testValidationsAfterStatusChange34() {
     Company__c company = new Company__c(Name = 'TestCompany');
     insert company;
     Project__c project = new Project__c(Name = 'TestProject',Company__c = company.Id );
     insert project;
    // Create test Lead
    Lead lead = new Lead(Status = 'Contacted', Is_User_Assigned__c = true,Email_Conversation_Done__c=true,Is_Qualified__c=true,LastName = 'TestLead',Company = 'TestComp',Project__c = project.Id, By_Pass_Validations__c = false, External_Lead__c = true);
    insert lead;

    // Update Lead status
    Lead updatedLead = [SELECT Id, Status, Is_User_Assigned__c, Dropped_Reason__c,Is_Qualified__c, By_Pass_Validations__c,Email_Conversation_Done__c FROM Lead WHERE Id = :lead.Id];
    updatedLead.Status = 'Converted';
    updatedLead.Is_User_Assigned__c = true;
    updatedLead.Is_Qualified__c = true;
    updatedLead.Email_Conversation_Done__c = true;
    updatedLead.Next_Follow_Up_Date_Time__c = Date.today().addDays(30) ;
    updatedLead.Site_Visit_Planned_Date__c = Date.today().addDays(30) ;  
    updatedLead.Qualification_Criteria__c = 'aa';  
    updatedLead.Budget_In_Lakhs__c = '5 Lakhs';
    update updatedLead;

    // Prepare oldMap for validation
    Map<Id, Lead> oldMap = new Map<Id, Lead>{lead.Id => lead};
    List<Lead> newLeads = [SELECT Id, Status, Is_User_Assigned__c,Qualification_Criteria__c, By_Pass_Validations__c,Email_Conversation_Done__c,Is_Qualified__c,Next_Follow_Up_Date_Time__c,Budget_In_Lakhs__c,Site_Visit_Planned_Date__c FROM Lead WHERE Id = :lead.Id];

    // Start test block
    Test.startTest();

    // Call the method to validate status change
    LeadHandler.validationsAfterStatusChange(newLeads, oldMap);

    // Stop test block
    Test.stopTest();

   
	}
    
     @isTest
	public static void testValidationsAfterStatusChange4() {
     Company__c company = new Company__c(Name = 'TestCompany');
     insert company;
     Project__c project = new Project__c(Name = 'TestProject',Company__c = company.Id );
     insert project;
    // Create test Lead
    Lead lead = new Lead(Status = 'Qualified', Is_User_Assigned__c = true,Email_Conversation_Done__c=true,Is_Qualified__c=true,LastName = 'TestLead',Company = 'TestComp',Project__c = project.Id, By_Pass_Validations__c = false, External_Lead__c = true);
    insert lead;

    // Update Lead status
    Lead updatedLead = [SELECT Id, Status, Is_User_Assigned__c, Dropped_Reason__c,Is_Qualified__c, By_Pass_Validations__c,Email_Conversation_Done__c FROM Lead WHERE Id = :lead.Id];
    updatedLead.Status = 'SV Planned';
    updatedLead.Is_User_Assigned__c = true;
    updatedLead.Is_Qualified__c = true;
    updatedLead.Email_Conversation_Done__c = true;
    updatedLead.Next_Follow_Up_Date_Time__c = Date.today().addDays(30) ;
    updatedLead.Site_Visit_Planned_Date__c = Date.today().addDays(30) ;    
    updatedLead.Budget_In_Lakhs__c = '';
    update updatedLead;

    // Prepare oldMap for validation
    Map<Id, Lead> oldMap = new Map<Id, Lead>{lead.Id => lead};
    List<Lead> newLeads = [SELECT Id, Status, Is_User_Assigned__c, By_Pass_Validations__c,Email_Conversation_Done__c,Is_Qualified__c,Next_Follow_Up_Date_Time__c,Budget_In_Lakhs__c,Site_Visit_Planned_Date__c FROM Lead WHERE Id = :lead.Id];

    // Start test block
    Test.startTest();

    // Call the method to validate status change
    LeadHandler.validationsAfterStatusChange(newLeads, oldMap);

    // Stop test block
    Test.stopTest();

   
	}
    
	 @isTest
	public static void testValidationsAfterStatusChange42() {
     Company__c company = new Company__c(Name = 'TestCompany');
     insert company;
     Project__c project = new Project__c(Name = 'TestProject',Company__c = company.Id );
     insert project;
    // Create test Lead
    Lead lead = new Lead(Status = 'Qualified', Is_User_Assigned__c = false,Email_Conversation_Done__c= true,Is_Qualified__c= true,LastName = 'TestLead',Company = 'TestComp',Project__c = project.Id, By_Pass_Validations__c = false, External_Lead__c = true);
    insert lead;

    // Update Lead status
    Lead updatedLead = [SELECT Id, Status, Is_User_Assigned__c, Dropped_Reason__c, By_Pass_Validations__c FROM Lead WHERE Id = :lead.Id];
    updatedLead.Status = 'Dropped';
    updatedLead.Is_User_Assigned__c = true ;
    updatedLead.Email_Conversation_Done__c = true;
    updatedLead.Dropped_Reason__c = 'test';
    update updatedLead;

    // Prepare oldMap for validation
    Map<Id, Lead> oldMap = new Map<Id, Lead>{lead.Id => lead};
    List<Lead> newLeads = [SELECT Id, Status, Is_User_Assigned__c, By_Pass_Validations__c,Email_Conversation_Done__c,Dropped_Reason__c FROM Lead WHERE Id = :lead.Id];

    // Start test block
    Test.startTest();

    // Call the method to validate status change
    LeadHandler.validationsAfterStatusChange(newLeads, oldMap);

    // Stop test block
    Test.stopTest();

   
    }
	@isTest
	public static void testValidationsAfterStatusChange43() {
     Company__c company = new Company__c(Name = 'TestCompany');
     insert company;
     Project__c project = new Project__c(Name = 'TestProject',Company__c = company.Id );
     insert project;
    // Create test Lead
    Lead lead = new Lead(Status = 'Qualified', Is_User_Assigned__c = true,Email_Conversation_Done__c=true,Is_Qualified__c=true,LastName = 'TestLead',Company = 'TestComp',Project__c = project.Id, By_Pass_Validations__c = false, External_Lead__c = true);
    insert lead;

    // Update Lead status
    Lead updatedLead = [SELECT Id, Status, Is_User_Assigned__c, Dropped_Reason__c,Is_Qualified__c, By_Pass_Validations__c,Email_Conversation_Done__c FROM Lead WHERE Id = :lead.Id];
    updatedLead.Status = 'Converted';
    updatedLead.Is_User_Assigned__c = true;
    updatedLead.Is_Qualified__c = true;
    updatedLead.Email_Conversation_Done__c = true;
    updatedLead.Next_Follow_Up_Date_Time__c = Date.today().addDays(30) ;
    updatedLead.Site_Visit_Planned_Date__c = Date.today().addDays(30) ;    
    updatedLead.Budget_In_Lakhs__c = '';
    updatedLead.Qualification_Criteria__c = 'aa';
    update updatedLead;

    // Prepare oldMap for validation
    Map<Id, Lead> oldMap = new Map<Id, Lead>{lead.Id => lead};
    List<Lead> newLeads = [SELECT Id, Status, Is_User_Assigned__c, By_Pass_Validations__c,Email_Conversation_Done__c,Is_Qualified__c,Next_Follow_Up_Date_Time__c,Budget_In_Lakhs__c,Site_Visit_Planned_Date__c FROM Lead WHERE Id = :lead.Id];

    // Start test block
    Test.startTest();

    // Call the method to validate status change
    LeadHandler.validationsAfterStatusChange(newLeads, oldMap);

    // Stop test block
    Test.stopTest();

   
	}
    
     @isTest
	public static void testValidationsAfterStatusChange5() {
     Company__c company = new Company__c(Name = 'TestCompany');
     insert company;
     Project__c project = new Project__c(Name = 'TestProject',Company__c = company.Id );
     insert project;
    // Create test Lead
    Lead lead = new Lead(Status = 'SV Planned',Next_Follow_Up_Date_Time__c= Date.today().addDays(30) ,Site_Visit_Planned_Date__c=  Date.today().addDays(30), Is_User_Assigned__c = false,Email_Conversation_Done__c= true,Is_Qualified__c= true,LastName = 'TestLead',Company = 'TestComp',Project__c = project.Id, By_Pass_Validations__c = false, External_Lead__c = true);
    insert lead;

    // Update Lead status
    Lead updatedLead = [SELECT Id, Status, Is_User_Assigned__c, Dropped_Reason__c, By_Pass_Validations__c FROM Lead WHERE Id = :lead.Id];
    updatedLead.Status = 'Dropped';
    updatedLead.Is_User_Assigned__c = true ;
    updatedLead.Email_Conversation_Done__c = true;
    updatedLead.Dropped_Reason__c = 'test';
    update updatedLead;

    // Prepare oldMap for validation
    Map<Id, Lead> oldMap = new Map<Id, Lead>{lead.Id => lead};
    List<Lead> newLeads = [SELECT Id, Status, Is_User_Assigned__c, By_Pass_Validations__c,Email_Conversation_Done__c,Dropped_Reason__c FROM Lead WHERE Id = :lead.Id];

    // Start test block
    Test.startTest();

    // Call the method to validate status change
    LeadHandler.validationsAfterStatusChange(newLeads, oldMap);

    // Stop test block
    Test.stopTest();

   
    }
	@isTest
	public static void testValidationsAfterStatusChange52() {
     Company__c company = new Company__c(Name = 'TestCompany');
     insert company;
     Project__c project = new Project__c(Name = 'TestProject',Company__c = company.Id );
     insert project;
    // Create test Lead
    Lead lead = new Lead(Status = 'SV Planned',Next_Follow_Up_Date_Time__c = Date.today().addDays(30),Site_Visit_Planned_Date__c = Date.today().addDays(30) , Is_User_Assigned__c = true,Email_Conversation_Done__c=true,Is_Qualified__c=true,LastName = 'TestLead',Company = 'TestComp',Project__c = project.Id, By_Pass_Validations__c = false, External_Lead__c = true);
    insert lead;

    // Update Lead status
    Lead updatedLead = [SELECT Id, Status, Is_User_Assigned__c, Dropped_Reason__c,Is_Qualified__c, By_Pass_Validations__c,Email_Conversation_Done__c FROM Lead WHERE Id = :lead.Id];
    updatedLead.Status = 'Converted';
    updatedLead.Is_User_Assigned__c = true;
    updatedLead.Is_Qualified__c = true;
    updatedLead.Email_Conversation_Done__c = true;
    updatedLead.Next_Follow_Up_Date_Time__c = Date.today().addDays(30) ;
    updatedLead.Site_Visit_Planned_Date__c = Date.today().addDays(30) ;    
    updatedLead.Budget_In_Lakhs__c = '';
    updatedLead.Qualification_Criteria__c = 'aa';
    update updatedLead;

    // Prepare oldMap for validation
    Map<Id, Lead> oldMap = new Map<Id, Lead>{lead.Id => lead};
    List<Lead> newLeads = [SELECT Id, Status, Is_User_Assigned__c, By_Pass_Validations__c,Email_Conversation_Done__c,Is_Qualified__c,Next_Follow_Up_Date_Time__c,Budget_In_Lakhs__c,Site_Visit_Planned_Date__c FROM Lead WHERE Id = :lead.Id];

    // Start test block
    Test.startTest();

    // Call the method to validate status change
    LeadHandler.validationsAfterStatusChange(newLeads, oldMap);

    // Stop test block
    Test.stopTest();

   
	}
    
    @isTest
	public static void testValidationsAfterStatusChange6() {
     Company__c company = new Company__c(Name = 'TestCompany');
     insert company;
     Project__c project = new Project__c(Name = 'TestProject',Company__c = company.Id );
     insert project;
    // Create test Lead
    Lead lead = new Lead(Status = 'Dropped',Dropped_Reason__c = 'test', Is_User_Assigned__c = true,Email_Conversation_Done__c=true,Is_Qualified__c=true,LastName = 'TestLead',Company = 'TestComp',Project__c = project.Id, By_Pass_Validations__c = false, External_Lead__c = true);
    insert lead;

    // Update Lead status
    Lead updatedLead = [SELECT Id, Status, Is_User_Assigned__c, Dropped_Reason__c,Is_Qualified__c, By_Pass_Validations__c,Email_Conversation_Done__c FROM Lead WHERE Id = :lead.Id];
    updatedLead.Status = 'Converted';
    updatedLead.Is_User_Assigned__c = true;
    updatedLead.Is_Qualified__c = true;
    updatedLead.Email_Conversation_Done__c = true;
    updatedLead.Next_Follow_Up_Date_Time__c = Date.today().addDays(30) ;
    updatedLead.Site_Visit_Planned_Date__c = Date.today().addDays(30) ; 
    updatedLead.Qualification_Criteria__c = 'aa';   
    updatedLead.Budget_In_Lakhs__c = '';
    update updatedLead;

    // Prepare oldMap for validation
    Map<Id, Lead> oldMap = new Map<Id, Lead>{lead.Id => lead};
    List<Lead> newLeads = [SELECT Id, Status, Is_User_Assigned__c, By_Pass_Validations__c,Email_Conversation_Done__c,Is_Qualified__c,Next_Follow_Up_Date_Time__c,Budget_In_Lakhs__c,Site_Visit_Planned_Date__c,Qualification_Criteria__c FROM Lead WHERE Id = :lead.Id];

    // Start test block
    Test.startTest();

    // Call the method to validate status change
    LeadHandler.validationsAfterStatusChange(newLeads, oldMap);

    // Stop test block
    Test.stopTest();

   
	}
    
    
}