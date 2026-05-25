public without sharing class opportunityApprovalProcess {
    @AuraEnabled
   public static List<User> getCRMUsers() {
       
       try{
           System.debug('users');
            set<Id> crmUserId = new set<Id>(); 
            
           List<Assignment_Group_Member__c> assignmentGroups = [
               SELECT Id, Name, Group_Member__c, Group_Member__r.Name, Assignment_Group__c, 
                   Assignment_Group__r.Name, Active__c, BreakTime_Started__c, Out_Of_Office__c, 
                   Assignment_Id__c, Assignment_Group__r.Last_Allocated_RRid__c 
               FROM Assignment_Group_Member__c 
               WHERE Assignment_Group__r.Name =  'CRM Assignment'
           ];

           System.debug('assignmentGroups==>'+assignmentGroups);

          Integer lastAllocatedId = (assignmentGroups.isEmpty()) ? 0 : assignmentGroups[0].Assignment_Group__r.Last_Allocated_RRid__c.intValue();

           Integer totalMembers = assignmentGroups.size();

           Integer allocation = lastAllocatedId + 1;

       
           if (allocation > totalMembers) {
               allocation = 1;
           }
           System.debug('allocation==>'+allocation);
            

           Assignment_Group_Member__c assignedMember = null;

           Integer attempts = 0;  
           while (attempts < totalMembers) {
               for (Assignment_Group_Member__c assign : assignmentGroups) {
                   
                   if (assign.Active__c == true && assign.BreakTime_Started__c != true && assign.Out_Of_Office__c != true) {
                      
                       if (assign.Assignment_Id__c == allocation) {
                          
                            assignedMember = assign;
                            crmUserId.add(assign.Group_Member__c);
                           break;
                       }
                   }
               }

               if (assignedMember != null) {
                  break;
               }

               allocation++;
               if (allocation > totalMembers) {
                   allocation = 1;
               }
               attempts++; 
           }

           if (assignedMember != null) {
               Assignment_Group__c agToUpdate = [select id,Last_Allocated_RRid__c from Assignment_Group__c where Id =: assignedMember.Assignment_Group__c Limit 1];
               System.debug('allocation-->'+allocation);
                 if (agToUpdate.Last_Allocated_RRid__c != allocation) {
                   String assignmentGroupId = agToUpdate.id;
                   opportunityApprovalProcess.updateAssignmentGroup(assignmentGroupId,allocation);
                   agToUpdate.Last_Allocated_RRid__c = allocation;
                   System.debug('agToUpdate==>'+agToUpdate);
                   update agToUpdate;
                 }
           }
           System.debug('crmUserId==>'+crmUserId);

           List<User>crmUsers = [select id,Name from User where Id =:crmUserId];
           
           System.debug('crmUsers==>'+crmUsers);
           return crmUsers; 

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
       req1.setProcessDefinitionNameOrId('Sales_head_and_CRM_Approval_Process'); // Set the approval process name
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
       // Store the previous owner ID
       Id previousOwnerId = opp.OwnerId;
       System.debug('Previous Owner ID: ' + previousOwnerId);

       // Update the opportunity owner to the new owner
       opp.OwnerId = newOwnerId; // Set new owner
       // opp.CRM_Approval_Status__c = 'Sent'; // Update CRM Approval Status

       // Update the Sales Team Member field to the previous owner
       opp.Sales_Team_Member__c = previousOwnerId; // Set previous owner in Sales Team Member field

       System.debug('Updating Opportunity: ' + opp);
       update opp; // Update the Opportunity record
       System.debug('Opportunity updated successfully');
   }

}