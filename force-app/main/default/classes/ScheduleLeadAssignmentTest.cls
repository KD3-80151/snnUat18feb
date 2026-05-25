@isTest
public class ScheduleLeadAssignmentTest {

    @isTest
    static void testScheduleLeadAssignment() {
        Company__c company = new Company__c(Name = 'TestCompany');
        insert company;
        Project__c proj = new Project__c(
        	Name = 'Test Project',
            Company__c = company.Id
        );
        insert proj;
        List<Lead> testLeads = new List<Lead>();
        for (Integer i = 0; i < 5; i++) {
            testLeads.add(new Lead(LastName = 'Test Lead ' + i, Company = 'Test Company ' + i, Status = 'Open',Project__c =proj.Id ));
        }
        insert testLeads;
        Test.startTest();

        String jobName = 'TestScheduleJob_' + System.currentTimeMillis();
        ScheduleLeadAssignment.scheduleJob();
        
        CronTrigger cronJob = [SELECT Id, CronJobDetail.Name, State 
                                FROM CronTrigger 
                                WHERE CronJobDetail.Name LIKE 'QABatches_%' LIMIT 1];
       

        List<SchedulableContext> schedulableContexts = new List<SchedulableContext>();
        ScheduleLeadAssignment scheduledJob = new ScheduleLeadAssignment();
        scheduledJob.execute(null); 

        Test.stopTest();
    }

    @isTest
    static void testBatchOnLeadToTakeFollowUp() {
        Company__c company = new Company__c(Name = 'TestCompany');
        insert company;
        Project__c proj = new Project__c(
        	Name = 'Test Proj',
            Company__c = company.Id
        );
        insert proj;
        
        List<Lead> testLeads = new List<Lead>();
        for (Integer i = 0; i < 5; i++) {
            testLeads.add(new Lead(LastName = 'Test Lead ' + i, Company = 'Test Company ' + i, Status = 'Open',Project__c =proj.Id));
        }
        insert testLeads;

        Test.startTest();
        BatchOnLeadToTakeFollowUp batchJob = new BatchOnLeadToTakeFollowUp();
        Database.executeBatch(batchJob);
        Test.stopTest();
    }

    @isTest
    static void testSobjectLoadAssignment() {
        Test.startTest();
        SobjectLoadAssignment.ExecuteLoadAssignment(2); 
        Test.stopTest();

    }
}