@isTest
public class BatchToDeleteDuplicateLeadsTest {
    @isTest
    static void testBatchToDeleteDuplicateLeads() {
        Test.startTest();
        Company__c company = new Company__c(Name = 'TestCompany');
        insert company;
        Project__c project = new Project__c(Name = 'TestProject',Company__c = company.Id );
        insert project;

        List<Lead> leadsToInsert = new List<Lead>{
            new Lead(LastName = 'Lead1', Company = 'Company1', Email = 'duplicate@example.com',Project__c = project.Id),
            new Lead(LastName = 'Lead2', Company = 'Company2', Email = 'unique1@example.com',Project__c = project.Id),
            new Lead(LastName = 'Lead3', Company = 'Company3', Email = 'duplicate@example.com',Project__c = project.Id), // Duplicate email
            new Lead(LastName = 'Lead4', Company = 'Company4', Email = 'unique2@example.com',Project__c = project.Id)
        };
        insert leadsToInsert;

        List<Lead> duplicateLeads = [SELECT Id FROM Lead WHERE Email = 'duplicate@example.com'];

        BatchToDeleteDuplicateLeads batchJob = new BatchToDeleteDuplicateLeads(duplicateLeads);
        Database.executeBatch(batchJob);

        Test.stopTest();
        
    }
}