public without sharing class projectRoleHandler {
    public static void showValidationForSystemAdminRele(List<Project_Roles__c> proRoleList){
        system.debug('proRoleList=='+proRoleList);
        set<id> projectId = new  set<id>();
        for(Project_Roles__c projectRole : proRoleList){
            projectId.add(projectRole.Project__c);
        }
        
        List<Project_Roles__c> projecROleList =[Select id,Role__c from Project_Roles__c Where Project__c IN:projectId AND  Role__c ='System Administrator'];
        if (!projecROleList.isEmpty()) {
            for (Project_Roles__c projectRole : proRoleList) {
                if (projectRole.Role__c == 'System Administrator') {
                    projectRole.addError('System Administrator Record Already Available in the system');
                }
            }
        }
        
        
    }
}