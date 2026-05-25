@isTest
public class LeadTaskController_Test {
    
    @testSetup
    static void setup() {
        // Insert a Lead record
        
         Company__c company = new Company__c(Name = 'Test Company');
         insert company;

      Project__c newpr = new Project__c(Name = 'Test', Company__c = company.Id, Active__c = true);
   
        insert newpr;
        Lead lead = new Lead(
            LastName = 'Test Lead',
            Company = 'Test Company',
            Status = 'New',
            Project__c = newpr.id
        );
        insert lead;
        
        // Insert related Task records
        Task task1 = new Task(
            WhoId = lead.Id,
            Status = 'Not Started',
            Priority = 'Normal',
            Subject = 'Follow-up'
        );
        
        Task task2 = new Task(
            WhoId = lead.Id,
            Status = 'Completed',
            Priority = 'High',
            Subject = 'Initial Contact'
        );
        
        insert new List<Task>{task1, task2};
    }
    
    @isTest
    static void testGetRelatedTasks() {
        // Get the lead inserted in the setup
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];
        
        // Start the test and call the method
        Test.startTest();
        List<Task> relatedTasks = LeadTaskController.getRelatedTasks(testLead.Id);
        Test.stopTest();
        
      
    }
}