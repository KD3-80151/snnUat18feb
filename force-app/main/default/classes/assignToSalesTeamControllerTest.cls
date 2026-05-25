@isTest
private class assignToSalesTeamControllerTest {

    // Test method for getUsersWithSalesTeamProfile
    @isTest
    static void testGetUsersWithSalesTeamProfile() {
        // Step 1: Create test users with relevant profiles
        Profile salesExecutiveProfile = [SELECT Id FROM Profile WHERE Name = 'Sales Executive' LIMIT 1];
        Profile salesManagerProfile = [SELECT Id FROM Profile WHERE Name = 'Sales Manager' LIMIT 1];

        User user1 = new User(
            Username = 'testuser1098765@example.com', 
            Email = 'testuser1@example.com',
            Alias = 'test1', 
            ProfileId = salesExecutiveProfile.Id,
            FirstName = 'Test', 
            LastName = 'User1',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'ISO-8859-1',
            LanguageLocaleKey = 'en_US'
        );
        
        User user2 = new User(
            Username = 'testuser243546576@example.com', 
            Email = 'testuser2@example.com',
            Alias = 'test2', 
            ProfileId = salesManagerProfile.Id,
            FirstName = 'Test', 
            LastName = 'User2',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'ISO-8859-1',
            LanguageLocaleKey = 'en_US'
        );
        
        insert new List<User>{ user1, user2 };

        // Step 2: Start the test context
        Test.startTest();

        // Step 3: Call the Apex method
        List<User> users = assignToSalesTeamController.getUsersWithSalesTeamProfile();

        // Step 4: Stop the test context
        Test.stopTest();

        
    }

    // Test method for updateLeadOwner
    @isTest
    static void testUpdateLeadOwner() {
        
    Profile salesExecutiveProfile1 = [SELECT Id FROM Profile WHERE Name = 'Sales Executive' LIMIT 1];
        
    User newUser = new User(
      Username = 'testusertrsgyf6576@example.com', 
      Email = 'testuser2@example.com',
      Alias = 'test2', 
      ProfileId = salesExecutiveProfile1.Id,
      FirstName = 'Test', 
      LastName = 'User2',
      TimeZoneSidKey = 'America/New_York',
      LocaleSidKey = 'en_US',
      EmailEncodingKey = 'ISO-8859-1',
      LanguageLocaleKey = 'en_US'
       );

	insert newUser;
         Company__c company = new Company__c(Name = 'TestCompany');
		insert company;

		Project__c project = new Project__c(Name = 'TestProject' , Company__c = company.Id );
        insert project;
        // Step 1: Create a Lead record
        Lead testLead = new Lead(
            Project__c = project.Id,
            LastName = 'Test Lead',
            Company = 'Test Company',
            Email = 'testlead@example.com',
            Phone = '1234567890',
            Sales_Team_Member__c = newUser.Id
        );
        insert testLead;

        // Step 2: Create a mock user (Salesperson) for assigning as Lead owner
        Profile salesExecutiveProfile = [SELECT Id FROM Profile WHERE Name = 'Sales Executive' LIMIT 1];
        User newOwner = new User(
            Username = 'newowner@example.com', 
            Email = 'newowner@example.com',
            Alias = 'newowner', 
            ProfileId = salesExecutiveProfile.Id,
            FirstName = 'New', 
            LastName = 'Owner',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'ISO-8859-1',
            LanguageLocaleKey = 'en_US'
        );
        insert newOwner;

        // Step 3: Start the test context
        Test.startTest();

        // Step 4: Call the updateLeadOwner method with the test lead ID
        assignToSalesTeamController.updateLeadOwner(testLead.Id, 'Sales');

        // Step 5: Retrieve the updated lead and assert changes
        Lead updatedLead = [SELECT Id, Sales_Person_on_Queue__c FROM Lead WHERE Id = :testLead.Id LIMIT 1];
     
        // Step 7: Stop the test context
        Test.stopTest();
    }

    // Test method for updateLeadOwner with Lead not found scenario
	@isTest
	static void testUpdateLeadOwner_LeadNotFound() {
    Company__c company = new Company__c(Name = 'TestCompany');
		insert company;

		Project__c project = new Project__c(Name = 'TestProject' , Company__c = company.Id );
        insert project;
        // Step 1: Create a Lead record
        Lead testLead = new Lead(
            Project__c = project.Id,
            LastName = 'Test Lead',
            Company = 'Test Company',
            Email = 'testlead@example.com',
            Phone = '1234567890'
        );
        insert testLead;
    // Step 1: Start the test context
    Test.startTest();

    // Step 2: Call the updateLeadOwner method with an invalid lead ID (non-existing Lead)
    try {
        assignToSalesTeamController.updateLeadOwner(testLead.Id, 'Sales'); // Invalid Lead Id
       
    } catch (AuraHandledException e) {
        System.assertEquals(e.getMessage(), 'Lead not found.', 'Exception message should be "Lead not found."');
    }

    // Step 3: Stop the test context
    Test.stopTest();
}
    // Test method for getLeadDetails
    @isTest
    static void testGetLeadDetails() {
        
        Company__c company = new Company__c(Name = 'TestCompany');
		insert company;

		Project__c project = new Project__c(Name = 'TestProject' , Company__c = company.Id );
        insert project;
        // Step 1: Create a Lead record
        Lead testLead = new Lead(
            Project__c = project.Id,
            LastName = 'Test Lead',
            Company = 'Test Company',
            Email = 'testlead@example.com',
            Phone = '1234567890'
        );
        insert testLead;

        // Step 2: Start the test context
        Test.startTest();

        // Step 3: Call the getLeadDetails method with the test lead ID
        Lead leadDetails = assignToSalesTeamController.getLeadDetails(testLead.Id);

        // Step 4: Stop the test context
        Test.stopTest();

       
    }
    // Test method for getLeadDetails with Lead not found scenario
	@isTest
	static void testGetLeadDetails_LeadNotFound() {
        
      Company__c company = new Company__c(Name = 'TestCompany');
		insert company;

		Project__c project = new Project__c(Name = 'TestProject' , Company__c = company.Id );
        insert project;
        // Step 1: Create a Lead record
        Lead testLead = new Lead(
            Project__c = project.Id,
            LastName = 'Test Lead',
            Company = 'Test Company',
            Email = 'testlead@example.com',
            Phone = '1234567890'
        );
        insert testLead;

    // Step 1: Start the test context
    Test.startTest();

    // Step 2: Call the getLeadDetails method with an invalid lead ID (non-existing Lead)
    try {
        assignToSalesTeamController.getLeadDetails(testLead.Id); // Invalid Lead Id
        
    } catch (AuraHandledException e) {
        System.assertEquals(e.getMessage(), 'Lead not found.', 'Exception message should be "Lead not found."');
    }

    // Step 3: Stop the test context
    Test.stopTest();
}
    
}