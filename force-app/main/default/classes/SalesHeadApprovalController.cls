public withOut sharing class SalesHeadApprovalController {
    
    @AuraEnabled(cacheable=true)
    public static List<User> fetchUserDetails(){
        try {
            List<User> userList = [SELECT Id, Name, Profile.Name FROM User WHERE IsActive = true AND Profile.Name IN ('Sales Head', 'Sales Executive', 'Sales Manager')];
            return userList;
        } catch (Exception e) {
            System.debug('Error ===> ' + e.getMessage());
            System.debug('Error ===> ' + e.getLineNumber());
            return null;
        }
    }
    
    @AuraEnabled
    public static void approveOrRejectOpp(Id taskId, String approveOrRejectValue, List<Opportunity_Team__c> oppTeamList){
        try {
            if(!oppTeamList.isEmpty() && taskId != null && approveOrRejectValue != null) {
                
                List<Task> tskList = [SELECT Id,WhatId from Task where Id =: taskId LIMIT 1];
                if(tskList[0].WhatId != null){

                    List<ProcessInstanceWorkItem> workItem = [SELECT Id, ProcessInstance.TargetObjectId FROM ProcessInstanceWorkItem WHERE ProcessInstance.TargetObjectId = :tskList[0].WhatId LIMIT 1];
                    if(!workItem.isEmpty()){
                        String action = approveOrRejectValue == 'Approved' ? 'Approve' : 'Reject';
                        Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
                        req.setWorkItemId(workItem[0].Id);
                        req.setAction(action); 
                        req.setComments(approveOrRejectValue);
        
                        Approval.ProcessResult result = Approval.process(req);
                    }

                    List<Opportunity> oppList = [SELECT Id,Sales_Head_approval_Status__c from Opportunity where Id =: tskList[0].WhatId LIMIT 1];
                    oppList[0].Sales_Head_approval_Status__c = approveOrRejectValue;
                    update oppList[0];
                    
                    for(Opportunity_Team__c oppTeam : oppTeamList){
                        oppTeam.Opportunity__c = tskList[0].WhatId;
                    }
                    insert oppTeamList;
                }
                
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}