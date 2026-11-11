public class SobjectLoadAssignmentHelper {
    Public Static Map<Id,Assignment_Group__c> rv_MapOfAGIdByAG = new Map<Id,Assignment_Group__c>();
    Public Static Map<Id,List<Assignment_Group_Member__c>> rv_MapOfAGIDByASMList = new Map<Id,List<Assignment_Group_Member__c>>();

    Public static void ExecuteSobjectOwnerAssignment(List<Sobject> sObjectList,String GroupId,Id queueId){
        System.debug('sObjectList==>'+sObjectList);
        rv_MapOfAGIdByAG = SobjectLoadAssignmentUtility.GetassigmentGroup();
        SobjectLoadAssignment.GetAssignMentGroupMemberAndAssignmentGroup();

        Assignment_Group__c groupRec = rv_MapOfAGIdByAG.get(GroupId);
        List<Assignment_Group_Member__c> groupMembers = SobjectLoadAssignment.rv_MapOfAGIDByASMList.get(GroupId);
        if(groupRec == null || groupMembers == null || groupMembers.isEmpty() || sObjectList == null || sObjectList.isEmpty()){
            return;
        }

        Map<Id,Integer> caseCounts = SobjectLoadAssignmentUtility.getCaseCount(GroupId);
        Integer totalCaseCount = 0;
        for (Integer count : caseCounts.values()) {
            totalCaseCount += count;
        }
        if(groupRec.Max_Sobject_Assignment_Count__c == null || (Integer)groupRec.Max_Sobject_Assignment_Count__c <= totalCaseCount){
            return;
        }

        // Members keyed by Assignment Id, walked in ascending order (handles gaps like 2,4,6)
        Map<Integer,Assignment_Group_Member__c> memberByRRId = new Map<Integer,Assignment_Group_Member__c>();
        for(Assignment_Group_Member__c agm : groupMembers){
            if(agm.Assignment_Id__c != null){
                memberByRRId.put((Integer)agm.Assignment_Id__c, agm);
            }
        }
        if(memberByRRId.isEmpty()){
            return;
        }
        List<Integer> sortedRRIds = new List<Integer>(memberByRRId.keySet());
        sortedRRIds.sort();

        // Start from the first member after the last one who actually received a record
        Integer lastAllocatedRRId = groupRec.Last_Allocated_RRid__c != null ? (Integer)groupRec.Last_Allocated_RRid__c : 0;
        Integer nextIndex = 0;
        for(Integer i = 0; i < sortedRRIds.size(); i++){
            if(sortedRRIds[i] > lastAllocatedRRId){
                nextIndex = i;
                break;
            }
        }
        if(sortedRRIds[sortedRRIds.size() - 1] <= lastAllocatedRRId){
            nextIndex = 0;
        }

        List<Sobject> recordsToUpdate = new List<Sobject>();
        List<Integer> assignedRRIds = new List<Integer>();

        for(Sobject objectRec : sObjectList){
            if(totalCaseCount >= (Integer)groupRec.Max_Sobject_Assignment_Count__c){
                break;
            }
            Assignment_Group_Member__c selectedMember;
            for(Integer i = 0; i < sortedRRIds.size(); i++){
                Integer idx = Math.mod(nextIndex + i, sortedRRIds.size());
                Assignment_Group_Member__c agm = memberByRRId.get(sortedRRIds[idx]);
                if(caseCounts.get(agm.Id) == null){
                    caseCounts.put(agm.Id, 0);
                }
                Decimal maxCount = agm.Max_Sobject_Assignment_Count__c != null
                    ? agm.Max_Sobject_Assignment_Count__c
                    : groupRec.Max_Sobject_Assignment_Count__c;
                system.debug('Checking Assignment_Id__c::>>' + agm.Assignment_Id__c + ' caseCount::>>' + caseCounts.get(agm.Id) + ' maxCount::>>' + maxCount);
                if(maxCount > caseCounts.get(agm.Id) && agm.BreakTime_Started__c == false && !agm.Out_Of_Office__c && agm.Active__c == true){
                    selectedMember = agm;
                    nextIndex = Math.mod(idx + 1, sortedRRIds.size());
                    break;
                }
            }
            // Nobody in the group can take more records in this run
            if(selectedMember == null){
                break;
            }
            objectRec.put('OwnerId',selectedMember.Group_Member__c) ;
            objectRec.put('Pre_Sales_Team_Member__c',selectedMember.Group_Member__c);
            objectRec.put('AGM_Related_to__c',selectedMember.Id);
            objectRec.put('AG_Related_to__c',selectedMember.Assignment_Group__c);
            objectRec.put('Is_User_Assigned__c',true);
            objectRec.put('Status','Assigned');
            objectRec.put('Lead_Assigned_Date_Time__c', Datetime.now());
            totalCaseCount += 1;
            caseCounts.put(selectedMember.Id, caseCounts.get(selectedMember.Id) + 1);
            recordsToUpdate.add(objectRec);
            assignedRRIds.add((Integer)selectedMember.Assignment_Id__c);
        }

        if(recordsToUpdate.isEmpty()){
            return;
        }

        // Save records first so a failed save does not consume the member's turn
        Database.SaveResult[] sObjectUpdateResults = Database.update(recordsToUpdate, false);
        Integer lastSavedRRId;
        for (Integer i = 0; i < sObjectUpdateResults.size(); i++) {
            if (sObjectUpdateResults[i].isSuccess()) {
                lastSavedRRId = assignedRRIds[i];
            } else {
                for (Database.Error err : sObjectUpdateResults[i].getErrors()) {
                    System.debug('SObject update failed: ' + recordsToUpdate[i].Id + ' -> ' + err.getMessage());
                }
            }
        }

        if(lastSavedRRId != null){
            Assignment_Group__c ov_AGTobeUpdated = new Assignment_Group__c();
            ov_AGTobeUpdated.Id = groupRec.Id;
            ov_AGTobeUpdated.Last_Allocated_RRid__c = lastSavedRRId;
            Database.SaveResult agUpdateResult = Database.update(ov_AGTobeUpdated, false);
            if (!agUpdateResult.isSuccess()) {
                for (Database.Error err : agUpdateResult.getErrors()) {
                    System.debug('Assignment Group update failed: ' + err.getMessage());
                }
            }
        }
    }
}
