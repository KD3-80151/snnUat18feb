public class salesLeadAssignmentHelper {
    Public Static Map<Id,Assignment_Group__c> rv_MapOfAGIdByAG = new Map<Id,Assignment_Group__c>();
    Public Static Map<Id,List<Assignment_Group_Member__c>> rv_MapOfAGIDByASMList = new Map<Id,List<Assignment_Group_Member__c>>();
    
    Public static void ExecuteSobjectOwnerAssignment(List<Sobject> sObjectList,String GroupId,Id queueId,String type){
        System.debug('sObjectList==>'+sObjectList);
        Integer lastAllocatedId = 0;
        rv_MapOfAGIdByAG = salesLeadAssignmentUtility.GetassigmentGroup(type);
        salesLeadAssignment.GetAssignMentGroupMemberAndAssignmentGroup(type);
        Map<id,List<Assignment_Group_Member__c>> assignmentGroupMembers = salesLeadAssignmentUtility.assignmentGroupMembers();
        
        if (assignmentGroupMembers.containsKey(GroupId) && assignmentGroupMembers.get(GroupId) != null && salesLeadAssignment.rv_MapOfAGIDByASMList.containsKey(GroupId) && salesLeadAssignment.rv_MapOfAGIDByASMList.get(GroupId) != null) {
            if (assignmentGroupMembers.get(GroupId).size() == salesLeadAssignment.rv_MapOfAGIDByASMList.get(GroupId)[0].Last_Allocated_RRID__c) {
                lastAllocatedId = 1;
            } else {
                if (rv_MapOfAGIdByAG.containsKey(GroupId) && rv_MapOfAGIdByAG.get(GroupId) != null) {
                    Integer lastAllocatedRRId = rv_MapOfAGIdByAG.get(GroupId).Last_Allocated_RRid__c != null 
                        ? (Integer) rv_MapOfAGIdByAG.get(GroupId).Last_Allocated_RRid__c + 1
                        : 1;
                    lastAllocatedId = lastAllocatedRRId;
                } else {
                    lastAllocatedId = 1; 
                }
            }
        } else {
            lastAllocatedId = 1; 
        }
        List<Assignment_Group_Member__c> groupMembers = salesLeadAssignment.rv_MapOfAGIDByASMList.get(GroupId);
        Integer totalMembers;
        if(groupMembers!= null){
            totalMembers  = groupMembers.size();
        }
        
        Map<Id,Integer> caseCounts = salesLeadAssignmentUtility.getCaseCount(GroupId);
        System.debug('caseCounts==>'+caseCounts);
        Integer totalCaseCount = 0;
        for (Integer count : caseCounts.values()) {
            totalCaseCount += count;
        }
        Set<Integer> numbers = new Set<Integer>();
        
        System.debug('salesLeadAssignment.rv_MapOfAGIDByASMList.get(GroupId)==>'+salesLeadAssignment.rv_MapOfAGIDByASMList.get(GroupId));
        if(salesLeadAssignment.rv_MapOfAGIDByASMList.get(GroupId) != null){
            for(Assignment_Group_Member__c agm:salesLeadAssignment.rv_MapOfAGIDByASMList.get(GroupId)){
                numbers.add((Integer)agm.Assignment_Id__c);   
            }
            Integer lastRId = lastAllocatedId -1;
            if(rv_MapOfAGIdByAG.get(GroupId) != null){
                if((Integer)rv_MapOfAGIdByAG.get(GroupId).Max_Sobject_Assignment_Count__c > totalCaseCount){
                    for(Sobject objectRec : sObjectList){
                        if (!numbers.contains(lastAllocatedId)) {
                            Integer nextAllocatedId = null;
                            for (Integer number1 : numbers) {
                                if (number1 > lastAllocatedId) {
                                    nextAllocatedId = number1;
                                    break;
                                }
                            }
                            if (nextAllocatedId == null) {
                                lastAllocatedId = 1;
                                if(!numbers.contains(lastAllocatedId)){  
                                    List<Integer> sortedNumbers = new List<Integer>(numbers);
                                    sortedNumbers.sort();
                                    for (Integer number1 : sortedNumbers) {
                                        if (number1 > 1) {
                                            lastAllocatedId = number1;
                                            break;
                                        }
                                    }
                                }
                            } else {
                                lastAllocatedId = nextAllocatedId;
                            }
                        }
                        for(Assignment_Group_Member__c agm : salesLeadAssignment.rv_MapOfAGIDByASMList.get(GroupId)){
                            if(caseCounts.get(agm.Id) == null){
                                caseCounts.put(agm.Id, 0);
                            }
                            if(lastAllocatedId == agm.Assignment_Id__c){
                                if(agm.Max_Sobject_Assignment_Count__c > caseCounts.get(agm.Id) && agm.BreakTime_Started__c == false && !agm.Out_Of_Office__c && agm.Active__c == true){
                                    objectRec.put('OwnerId',agm.Group_Member__c) ;
                                    objectRec.put('Sales_Team_Member__c',agm.Group_Member__c);
                                    objectRec.put('AGM_Related_to__c',agm.Id);
                                    objectRec.put('AG_Related_to__c',agm.Assignment_Group__c);
                                    objectRec.put('Sales_Lead_Assigned_Date_Time__c', Datetime.now());
                                    objectRec.put('Sales_Person_on_Queue__c',True);
                                    
                                    System.debug('objectRec==>'+objectRec);
                                    
                                    Task task = new Task();
                                    task.Subject = 'New Lead Assigned to you, please take follow up.';
                                    task.OwnerId = agm.Group_Member__c;
                                    task.Priority = 'High';
                                    task.WhoId = objectRec.Id;
                                    insert task;
                                    
                                    totalCaseCount +=1;
                                    caseCounts.put(agm.Id, caseCounts.get(agm.Id) + 1);
                                    lastRId = lastAllocatedId;
                                    lastAllocatedId = (assignmentGroupMembers.get(GroupId).size() == lastAllocatedId) ? 1 : lastAllocatedId + 1;
                                    break;
                                }else{
                                    lastAllocatedId = (assignmentGroupMembers.get(GroupId).size() == lastAllocatedId) ? 1 : lastAllocatedId + 1;
                                } 
                            }
                        }
                    }
                    Assignment_Group__c ov_AGTobeUpdated = new Assignment_Group__c();
                    ov_AGTobeUpdated.Id = rv_MapOfAGIdByAG.get(GroupId).Id ;
                    ov_AGTobeUpdated.Last_Allocated_RRid__c = (lastRId == 0) ? 1 : lastRId;  //- 1 == 0 ? totalMembers : lastAllocatedId - 1
                    Database.SaveResult agUpdateResult = Database.update(ov_AGTobeUpdated, false);
                    Database.SaveResult[] sObjectUpdateResults = Database.update(sObjectList, false);
                    System.debug('sObjectUpdateResults==>'+sObjectUpdateResults);
                    
                    if (!agUpdateResult.isSuccess()) {
                        for (Database.Error err : agUpdateResult.getErrors()) {
                            System.debug('Assignment Group update failed: ' + err.getMessage());
                        }
                    }  
                    for (Database.SaveResult result : sObjectUpdateResults) {
                        if (!result.isSuccess()) {
                            for (Database.Error err : result.getErrors()) {
                                System.debug('SObject update failed: ' + err.getMessage());
                            }
                        }
                    }
                }
                
            }
            
        }
    }  
    
    
    
}