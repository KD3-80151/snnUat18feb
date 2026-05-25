@isTest
private class projectRoleHandlerTest {
    @isTest
    static void testShowValidationForSystemAdminRele() {
        Company__c company = new Company__c(Name = 'Test Company');
        insert company;
        // Create a Project__c record
        Project__c project = new Project__c(Name = 'Test Project', Company__c = company.Id);
        insert project;

        // Create Project_Roles__c records
        Project_Roles__c role1 = new Project_Roles__c(Project__c = project.Id, Role__c = 'System Administrator');
        Project_Roles__c role2 = new Project_Roles__c(Project__c = project.Id, Role__c = 'Sales Head');
        insert new List<Project_Roles__c> { role1, role2 };

        // Prepare the list to test
        List<Project_Roles__c> proRoleList = new List<Project_Roles__c>();
        proRoleList.add(new Project_Roles__c(Project__c = project.Id, Role__c = 'System Administrator'));
        proRoleList.add(new Project_Roles__c(Project__c = project.Id, Role__c = 'Sales Executive'));

        Test.startTest();
        projectRoleHandler.showValidationForSystemAdminRele(proRoleList);
        Test.stopTest();

        // Verify the validation error
        for (Project_Roles__c projectRole : proRoleList) {
            if (projectRole.Role__c == 'System Administrator') {
                System.assert(projectRole.getErrors().size() > 0, 'Expected an error for System Administrator role');
                System.assertEquals('System Administrator Record Already Available in the system', projectRole.getErrors()[0].getMessage(), 'Error message did not match');
            }
        }
    }
}