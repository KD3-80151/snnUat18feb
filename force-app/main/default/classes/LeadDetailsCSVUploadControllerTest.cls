@isTest
public class LeadDetailsCSVUploadControllerTest {
    @isTest
    static void testValidLeadUpload() {

        User testUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        Company__c company = new Company__c(Name = 'TestCompany');
        insert company;
        List<Project__c> projects = new List<Project__c>{
            new Project__c(Name = 'ProjectA', Company__c = company.Id)
        };
        insert projects;
        
        String fileData = 'John Doe,john.doe@example.com,9876543210,ProjectA,Web,Ad';
        List<String> fields = new List<String>{'Name', 'Email', 'Phone', 'Project', 'Lead_Source', 'Lead_Sub_Source'};
        
        Test.startTest();
        String result = LeadDetailsCSVUploadController.uploadLeadRecords(fileData, fields);
        Test.stopTest();
        
        List<Lead> leads = [SELECT LastName, Email, Phone, Project__c FROM Lead];
    }
    
    @isTest
    static void testMandatoryFieldValidation() {
        String fileData = 'Jane,,1234567890,ProjectA,,';
        List<String> fields = new List<String>{'Name', 'Email', 'Phone', 'Project', 'Lead_Source', 'Lead_Sub_Source'};
        
        Test.startTest();
        try {
            LeadDetailsCSVUploadController.uploadLeadRecords(fileData, fields);
        } catch (Exception e) {
        }
        Test.stopTest();
    }
    
    @isTest
    static void testInvalidProject() {
        String fileData = 'Invalid Project,jane.doe@example.com,9876543210,InvalidProject,,';
        List<String> fields = new List<String>{'Name', 'Email', 'Phone', 'Project', 'Lead_Source', 'Lead_Sub_Source'};
        
        Test.startTest();
        String result = LeadDetailsCSVUploadController.uploadLeadRecords(fileData, fields);
        Test.stopTest();
    }
    
    @isTest
    static void testCheckProfile() {
        Test.startTest();
        Boolean isProfileValid = LeadDetailsCSVUploadController.checkProfile();
        Test.stopTest();
    }
}