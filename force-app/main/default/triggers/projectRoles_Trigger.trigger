trigger projectRoles_Trigger on Project_Roles__c (before insert) {
    if(trigger.IsBefore && trigger.IsInsert){
        projectRoleHandler.showValidationForSystemAdminRele(Trigger.new);
    }
}