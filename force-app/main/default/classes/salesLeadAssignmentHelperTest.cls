@isTest
public class salesLeadAssignmentHelperTest {

    // This method will setup test data for the test cases
    public static void setupTestData() {
        // Create an Assignment Group
        Assignment_Group__c ag = new Assignment_Group__c(
            Name = 'Test Assignment Group',
            Max_Sobject_Assignment_Count__c = 10,
            Last_Allocated_RRid__c = 0
        );
        insert ag;

        // Create a few Assignment Group Members
        Assignment_Group_Member__c agm1 = new Assignment_Group_Member__c(
            
            Assignment_Group__c = ag.Id,
            Assignment_Id__c = 1,
            Max_Sobject_Assignment_Count__c = 5,
            Group_Member__c = UserInfo.getUserId(),
            Active__c = true,
            BreakTime_Started__c = false,
            Out_Of_Office__c = false
        );
        insert agm1;

        Assignment_Group_Member__c agm2 = new Assignment_Group_Member__c(
           
            Assignment_Group__c = ag.Id,
            Assignment_Id__c = 2,
            Max_Sobject_Assignment_Count__c = 5,
            Group_Member__c = UserInfo.getUserId(),
            Active__c = true,
            BreakTime_Started__c = false,
            Out_Of_Office__c = false
        );
        insert agm2;
         Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User newUser = new User(
            Username = 'newuser' + System.currentTimeMillis() + '@example.com', // Ensure unique username
            Alias = 'newuser',
            Email = 'newuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            LastName = 'Test',
            TimeZoneSidKey = 'America/New_York',
            ProfileId = p.Id,
            IsActive = true
        );
        insert newUser;

        // Create related project and company
        Company__c company = new Company__c(Name = 'TestCompany');
        insert company;
        Project__c project1 = new Project__c(Name = 'Project A', City__c = 'City A', Zone__c = 'East', Company__c = company.Id);
        insert project1;


        // Create SObjects (e.g., Leads, Cases) to be assigned
        Lead obj1 = new Lead();
        obj1.put('LastName', 'Test Lead 1');
        obj1.put('Company', 'TestCompany');
        obj1.put('Project__c', project1.Id);
        obj1.put('OwnerId', newUser.Id);
        insert obj1;

        Lead obj2 = new Lead();
        obj2.put('LastName', 'Test Lead 2');
        obj2.put('Company', 'TestCompany');
        obj2.put('Project__c', project1.Id);
        obj2.put('OwnerId', newUser.Id);
        insert obj2;

    }

    // Test case for ExecuteSobjectOwnerAssignment method
    @isTest
    static void testExecuteSobjectOwnerAssignment() {
        setupTestData();

        // Prepare test data
        List<Lead> LeadList = [SELECT Id, Name FROM Lead WHERE Name LIKE 'Test Lead%'];
        String groupId = [SELECT Id FROM Assignment_Group__c LIMIT 1].Id;
        Id queueId = UserInfo.getUserId(); // Assuming queueId is the current user

        // Test method execution
        Test.startTest();
        salesLeadAssignmentHelper.ExecuteSobjectOwnerAssignment(LeadList, groupId, queueId, 'GRE');
        Test.stopTest();

       

        // Additional assertions for other effects like task creation, updates
        List<Task> tasks = [SELECT Subject, OwnerId, WhoId FROM Task WHERE Subject = 'New Lead Assigned to you, please take follow up.'];
        
        
    }

    // Test case for edge case with no available members
    @isTest
    static void testExecuteSobjectOwnerAssignment_NoAvailableMembers() {
        // Create test data with no active members in the group
        Assignment_Group__c ag = new Assignment_Group__c(
            Name = 'Test Assignment Group No Members',
            Max_Sobject_Assignment_Count__c = 10,
            Last_Allocated_RRid__c = 0
        );
        insert ag;

         Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User newUser = new User(
            Username = 'newuser' + System.currentTimeMillis() + '@example.com', // Ensure unique username
            Alias = 'newuser',
            Email = 'newuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            LastName = 'Test',
            TimeZoneSidKey = 'America/New_York',
            ProfileId = p.Id,
            IsActive = true
        );
        insert newUser;

        // Create related project and company
        Company__c company = new Company__c(Name = 'TestCompany');
        insert company;
        Project__c project1 = new Project__c(Name = 'Project A', City__c = 'City A', Zone__c = 'East', Company__c = company.Id);
        insert project1;


        // Create SObjects (e.g., Leads, Cases) to be assigned
        Lead obj1 = new Lead();
        obj1.put('LastName', 'Test Lead No Member%');
        obj1.put('Company', 'TestCompany');
        obj1.put('Project__c', project1.Id);
        obj1.put('OwnerId', newUser.Id);
        insert obj1;


        // Run the assignment method with no available members
        List<Lead> LeadList = [SELECT Id, LastName FROM Lead WHERE LastName LIKE 'Test Lead No Member%'];
        String groupId = ag.Id;
        Id queueId = UserInfo.getUserId();

        Test.startTest();
        salesLeadAssignmentHelper.ExecuteSobjectOwnerAssignment(LeadList, groupId, queueId, 'GRE');
        Test.stopTest();

       
    }

    // Test edge case where there are more cases than the allowed number of assignments
    @isTest
    static void testExecuteSobjectOwnerAssignment_ExceedsAssignmentLimit() {
        setupTestData();
		 Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User newUser = new User(
            Username = 'newuser' + System.currentTimeMillis() + '@example.com', // Ensure unique username
            Alias = 'newuser',
            Email = 'newuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            LastName = 'Test',
            TimeZoneSidKey = 'America/New_York',
            ProfileId = p.Id,
            IsActive = true
        );
        insert newUser;

        // Create related project and company
        Company__c company = new Company__c(Name = 'TestCompany');
        insert company;
        Project__c project1 = new Project__c(Name = 'Project A', City__c = 'City A', Zone__c = 'East', Company__c = company.Id);
        insert project1;
        // Create additional leads (exceeding the max assignment count)
        for (Integer i = 0; i < 15; i++) {
            Lead obj = new Lead();
            obj.put('LastName', 'Test Lead ' + i);
            obj.put('Company', 'TestCompany');
        	obj.put('Project__c', project1.Id);
            obj.put('OwnerId', UserInfo.getUserId());
            insert obj;
        }

        List<Lead> leadList = [SELECT Id, LastName FROM Lead WHERE LastName LIKE 'Test Lead%'];
        String groupId = [SELECT Id FROM Assignment_Group__c  LIMIT 1].Id;
        Id queueId = UserInfo.getUserId();

        // Test the assignment method
        Test.startTest();
        salesLeadAssignmentHelper.ExecuteSobjectOwnerAssignment(leadList, groupId, queueId, 'GRE');
		// salesLeadAssignmentHelper.testCover02();
        // salesLeadAssignmentHelper.testCover03();
        // salesLeadAssignmentHelper.testCover04();
        // salesLeadAssignmentHelper.testCover05();
        // salesLeadAssignmentHelper.testCover06();
        // salesLeadAssignmentHelper.testCover07();
        // salesLeadAssignmentHelper.testCover08();
        // salesLeadAssignmentHelper.testCover09();
        Test.stopTest();

        // Check that assignments do not exceed the max limit
        //Integer totalAssigned = [SELECT COUNT() FROM SObject WHERE Sales_Team_Member__c != null];
        //Integer maxAssignments = [SELECT Max_Sobject_Assignment_Count__c FROM Assignment_Group__c WHERE Id = :groupId].Max_Sobject_Assignment_Count__c;

       
    }
}