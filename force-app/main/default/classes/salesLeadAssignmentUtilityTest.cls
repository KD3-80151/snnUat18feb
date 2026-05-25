@isTest
public class salesLeadAssignmentUtilityTest {

    // Method to create mock data for the tests
    public static void createTestData() {
        Account acc = new Account(Name = 'testAccs');
        insert acc;
        // Create a test Assignment Group
        Assignment_Group__c ag = new Assignment_Group__c(
            Name = 'Test Assignment Group',
            Type__c = 'Sales',
            isActive__c = true,
            Round_Robin_Queue_Name__c = 'Test Queue',
            Supported_Sobject__c = 'Case' // Set the Supported_Sobject__c field to 'Case'
        );
        insert ag;
        
        // Create a test Group (Queue) for the Round Robin
        Group grp = new Group(
            Name = 'Test Queue',
            Type = 'Queue'
        );
        insert grp;
        
        // Create a test Assignment Group Member
        Assignment_Group_Member__c agm = new Assignment_Group_Member__c(
            Assignment_Group__c = ag.Id,
            Active__c = true
        );
        insert agm;
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = acc.Id, // Link to the test Account
            CloseDate = Date.today().addDays(30), // Set a close date 30 days in the future
            StageName = 'Prospecting', // Opportunity Stage
            Amount = 1000.00 // Test Amount
        );
        
        insert testOpportunity;
        
        // Create a test Case to be associated with the Assignment Group Member
        Case newCase = new Case(
            Subject = 'Test Case',
            Status = 'New',
            Opportunity__c = testOpportunity.Id,
            AGM_Related_to__c = agm.Id
        );
        insert newCase;
    }

    @isTest
    public static void testGetQueuesNameAndId() {
        createTestData(); // Create necessary data
        
        Test.startTest();
        Map<String, Id> result = salesLeadAssignmentUtility.GetQueuesNameAndId();
        Test.stopTest();

    }
    
    @isTest
    public static void testGetassigmentGroup() {
        createTestData(); // Create necessary data
        
        Test.startTest();
        Map<Id, Assignment_Group__c> result = salesLeadAssignmentUtility.GetassigmentGroup('GRE');
        Test.stopTest();

    }
    
    @isTest
    public static void testGetCaseCount() {
        createTestData(); // Create necessary data
        
        // Fetch the first Assignment Group Member and ensure it's populated
        Assignment_Group_Member__c agm = [SELECT Id, Assignment_Group__r.Supported_Sobject__c FROM Assignment_Group_Member__c LIMIT 1];
       
        
        // Now run the actual test
        Test.startTest();
        Map<Id, Integer> caseCount = salesLeadAssignmentUtility.getCaseCount(agm.Assignment_Group__c);
        Test.stopTest();

    }
    
    @isTest
    public static void testAssignmentGroupMembers() {
        createTestData(); // Create necessary data
        
        Test.startTest();
        Map<Id, List<Assignment_Group_Member__c>> result = salesLeadAssignmentUtility.assignmentGroupMembers();
        Test.stopTest();
        
    }
}