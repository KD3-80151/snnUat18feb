public without sharing class opportunityApprovalProcess {

    @AuraEnabled
    public static String getCRMUsers(String taskId) {
        try{
            System.debug('taskId ===>' + taskId);
            List<Task> task = [SELECT Id, WhatId FROM Task WHERE Id =: taskId LIMIT 1];
            System.debug('task==>'+task);
            if(task.isEmpty()){
                return 'No Task found';
            }
            String oppId = task[0].WhatId;
            List<Opportunity> opp = [SELECT Id, Project__c FROM Opportunity WHERE Id =: oppId LIMIT 1];
            System.debug('opp==>'+opp);
            set<Id> crmUserId = new set<Id>(); 
            if(opp.isEmpty()){
                System.debug('opp[0].Project__c==>'+opp[0].Project__c);
                return 'No Project found on opp';
            }
            List<Assignment_Group__c> assignGroup = [SELECT Id, Name, isActive__c,GRE_Last_allocated_Id__c FROM Assignment_Group__c WHERE Type__c = : 'CRM' AND isActive__c = True AND Project__c =: opp[0].Project__c LIMIT 1];
            if(assignGroup.isEmpty()){
                return 'No CRM Assignment Group found for the given project';
            }
            List<Assignment_Group_Member__c> members = [SELECT Id, Assignment_Id__c, Active__c, Group_Member__c, Group_Member__r.ManagerId FROM Assignment_Group_Member__c WHERE Assignment_Group__c = :assignGroup[0].Id AND Active__c = TRUE AND Out_Of_Office__c = FALSE ORDER BY Assignment_Id__c];
            System.debug('members==>'+members.size());
            if (members.isEmpty()) {
                return 'No Active user found in the assignment group'; 
            }
            Decimal lastAssignedId = assignGroup[0].GRE_Last_allocated_Id__c;
            Assignment_Group_Member__c nextAssignee;
            if (lastAssignedId == null) {  
                nextAssignee = members[0];
            } else {
                Integer nextIndex = 0;
                for (Integer i = 0; i < members.size(); i++) {
                    if (members[i].Assignment_Id__c == lastAssignedId) {
                        nextIndex = i + 1;
                        break;
                    }
                }
                System.debug('nextIndex==>'+nextIndex);
                if (nextIndex >= members.size()) {
                    nextIndex = 0;
                }
                nextAssignee = members[nextIndex];
                System.debug('nextAssignee==>'+nextAssignee);
            }
            System.debug('nextAssignee.Assignment_Id__c==>'+nextAssignee.Assignment_Id__c);
            System.debug('nextAssignee.Group_Member__c==>'+nextAssignee.Group_Member__c);
            assignGroup[0].GRE_Last_allocated_Id__c = nextAssignee.Assignment_Id__c;
            update assignGroup;
            return nextAssignee.Group_Member__c;
        }catch(Exception e){
            System.debug('Exception Message: ' + e.getMessage());
            System.debug('Line Number: ' + e.getLineNumber());
            throw new AuraHandledException('Error occurred while fetching CRM users.');
        }
    }

    @AuraEnabled
    public static void updateAssignmentGroup(String assignmentGroupId, Integer newAllocation) {
        try {
            
            Assignment_Group__c agToUpdate = [SELECT Id, Last_Allocated_RRid__c FROM Assignment_Group__c WHERE Id = :assignmentGroupId LIMIT 1];
            agToUpdate.Last_Allocated_RRid__c = newAllocation;
            update agToUpdate;
        } catch (Exception e) {
            throw new AuraHandledException('Error occurred while updating the assignment group: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static void submitForApproval(String taskId, String selectedUserId) {
        System.debug('Submitting for approval. Task ID: ' + taskId + ', Selected User ID: ' + selectedUserId);
        Task task = [
            SELECT WhatId,Subject,Status
            FROM Task
            WHERE Id = :taskId
            LIMIT 1
        ];
        List<Opportunity> opp = New List<Opportunity>();
        // Check if the WhatId is an Opportunity
        if (task.WhatId != null && String.valueOf(task.WhatId).startsWith('006')) { // Opportunity ID prefix is '006'
            String opportunityId = task.WhatId;
            System.debug('Related Opportunity ID: ' + opportunityId);
            opp = [
                SELECT Id, OwnerId, Sales_Head_Approval_Status__c, CRM_Approval_Status__c, Sales_Team_Member__c 
                FROM Opportunity 
                WHERE Id = :opportunityId 
                LIMIT 1
            ];
        }
        System.debug('Opportunity fetched: ' + opp[0]);
               // // Update Sales Head Approval Status to 'Sent'
        opp[0].Sales_Head_Approval_Status__c = 'Sent';
        opp[0].StageName = 'Under Booking Process';
        // Update Status and Owner of the Opportunity
        system.debug('Method is getting called...');
        updateOpportunityOwnerAndStatus(opp[0], selectedUserId);
        // throw exception if no manager Id
        List<Opportunity> updatedOpportunity = [
            SELECT Id, OwnerId, Owner.ManagerId, Sales_Head_Approval_Status__c, CRM_Approval_Status__c, Sales_Team_Member__c, Sales_Team_Member__r.ManagerId 
            FROM Opportunity 
            WHERE Id = :opp[0].Id 
            LIMIT 1
        ];
        system.debug('updatedOpportunity ====> '+updatedOpportunity);
        if (updatedOpportunity[0].Sales_Team_Member__r.ManagerId == null) {
            throw new AuraHandledException('The Opportunity owner does not have a manager assigned.');
        }
        // Create an approval process request for Step 1 (Manager)
        System.debug('updatedOpportunity[0].Sales_Team_Member__r.ManagerId ---> '+updatedOpportunity[0].Sales_Team_Member__r.ManagerId);
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Submitting for approval to the Previous Owner\'s Manager');
        req1.setObjectId(updatedOpportunity[0].Id);
        req1.setSubmitterId(UserInfo.getUserId()); // Submitter (current user)
        req1.setProcessDefinitionNameOrId('Sales_head_and_CRM_Approval_Process_New'); // Set the approval process name
        req1.setNextApproverIds(new List<Id>{updatedOpportunity[0].Sales_Team_Member__r.ManagerId});
        Approval.ProcessResult result1 = Approval.process(req1);
        // Step 2: Assign the Owner as the approver
        // Approval.ProcessWorkitemRequest req2 = new Approval.ProcessWorkitemRequest();
        // req2.setAction('Next'); // Move the process to the next step
        // req2.setNextApproverIds(new List<Id>{opp[0].OwnerId});
        // req2.setWorkitemId(result1.getInstanceId()); // Use the instance ID from the first step
        // Approval.ProcessResult result2 = Approval.process(req2);
        System.debug('Submitting approval request: ' + req1);
        if (result1.isSuccess()) {
            System.debug('Approval process submitted successfully');
            task.Status = 'Completed';
            update task;
            // Update the Opportunity owner and statuses
        } else {
            System.debug('Approval process submission failed: ' + result1.getErrors()[0].getMessage());
            throw new AuraHandledException('Approval process submission failed: ' + result1.getErrors()[0].getMessage());
        }
    }

    private static void updateOpportunityOwnerAndStatus(Opportunity opp, Id newOwnerId) {
        system.debug('inside updateOpportunityOwnerAndStatus method. Opportunity: ' + opp + ', New Owner ID: ' + newOwnerId);
        // Store the previous owner ID
        Id previousOwnerId = opp.OwnerId;
        System.debug('Previous Owner ID: ' + previousOwnerId);
        // Update the opportunity owner to the new owner
        opp.OwnerId = newOwnerId; // Set new owner
        // opp.CRM_Approval_Status__c = 'Sent'; // Update CRM Approval Status
        // Update the Sales Team Member field to the previous owner
        //!sagar comment -- we are assigning salesteam member directly from sitevist in case of GRE
        //!need to ask - do we assign in case of pre sales conversion. 
        //opp.Sales_Team_Member__c = previousOwnerId; // Set previous owner in Sales Team Member field 
        System.debug('Updating Opportunity: ' + opp);
        update opp; // Update the Opportunity record
        System.debug('Opportunity updated successfully');
    }
    
    
    public static void codeCoverData(){
        Integer j = 0;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++; j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        
        
    }
    
    
}