public with sharing class BatchOnLeadToTakeFollowUp implements Database.Batchable<sObject>{
    
    public Database.QueryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator([SELECT Id,Name,Lead_Assigned_Date_Time__c,Lead_Owner_Manager_Email__c,OwnerId,(SELECT Id,Subject,Agent_Status__c,Customer_Status__c,Status from Tasks order by createdDate desc) from Lead where IsConverted = false and Lead_Assigned_Date_Time__c != null and Is_User_Assigned__c = true]);
    }
    
    public void execute(Database.BatchableContext bc, List<Lead> leadList){
        try{
            System.debug('leadList ===> ' + leadList);
            DateTime currentDateTime = DateTime.now().addHours(5).addMinutes(30); 
            
            List<Task> taskListToInsert = new List<Task>();
            List<Task> taskListToUpdate = new List<Task>();
            Set<Id> ownerIds = new Set<Id>();
            
            for(Lead ld : leadList){
                ownerIds.add(ld.OwnerId);               
            }
            
            Map<Id, User_Tracking__c> userTrackingMapToday = new Map<Id, User_Tracking__c>();
            Map<Id, User_Tracking__c> userTrackingMapPrevious = new Map<Id, User_Tracking__c>();
            List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
            Id emailTemplate4Hrs = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'Take_Followup_in_next_4_hours' LIMIT 1].Id;
            Id emailTemplate24Hrs = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'Take_Followup_in_next_24_hours' LIMIT 1].Id;
            
            if(ownerIds != null){
                System.debug('ownerIds ===> ' + ownerIds);
                //todays user tracking map      
                for (User_Tracking__c tracking : [SELECT Member__c, Checkin_Datetime__c, Checkout_Datetime__c FROM User_Tracking__c WHERE Member__c IN :ownerIds AND Checkin_Datetime__c = Today]) {
                    if (!userTrackingMapToday.containsKey(tracking.Member__c) && tracking.Member__c != null) {
                        userTrackingMapToday.put(tracking.Member__c, tracking);
                    }
                }
                
                List<User_Tracking__c> ursList = [SELECT Member__c, Checkin_Datetime__c, Checkout_Datetime__c FROM User_Tracking__c WHERE Member__c IN :ownerIds AND Checkin_Datetime__c = Today];
                System.debug('ursList ==> ' + ursList);
                
                List<User_Tracking__c> usr = [SELECT Member__c, Checkin_Datetime__c, Checkout_Datetime__c FROM User_Tracking__c WHERE Member__c IN :ownerIds AND Checkin_Datetime__c < Today order by CreatedDate Desc];
                System.debug('usr ==> ' + usr);
                
                for (User_Tracking__c tracking : [SELECT Member__c, Checkin_Datetime__c, Checkout_Datetime__c FROM User_Tracking__c WHERE Member__c IN :ownerIds AND Checkin_Datetime__c < Today order by CreatedDate Desc]) {
                    if (!userTrackingMapPrevious.containsKey(tracking.Member__c) && tracking.Member__c != null) {
                        userTrackingMapPrevious.put(tracking.Member__c, tracking);
                    }
                }
            }
            for(Lead ld : leadList){            
                Datetime ldAssignedTime = ld.Lead_Assigned_Date_Time__c.addHours(5).addMinutes(30);
                Long differenceInMillis = currentDateTime.getTime() - ldAssignedTime.getTime();
                Decimal differenceInMinutes = differenceInMillis / (1000 * 60);
                if(userTrackingMapPrevious.containsKey(ld.OwnerId) && userTrackingMapPrevious.get(ld.OwnerId).Checkout_Datetime__c != null 
                   && ld.Lead_Assigned_Date_Time__c.date() == userTrackingMapPrevious.get(ld.OwnerId).Checkin_Datetime__c.date()){
                       System.debug('Lead was assigned yesterday and has checked out');
                       Long timeDifference = userTrackingMapPrevious.get(ld.OwnerId).Checkout_Datetime__c.getTime() - ld.Lead_Assigned_Date_Time__c.getTime();
                       differenceInMinutes = timeDifference / (1000 * 60);
                       System.debug('differenceInMinutes ===> ' + differenceInMinutes + ' timeDifference ===> ' + timeDifference);
                   }
                if(userTrackingMapToday.containsKey(ld.OwnerId) && userTrackingMapToday.get(ld.OwnerId).Checkout_Datetime__c == null && userTrackingMapToday.get(ld.OwnerId).Checkin_Datetime__c != null){
                    if(userTrackingMapToday.get(ld.OwnerId).Checkin_Datetime__c.date() != ld.Lead_Assigned_Date_Time__c.date()){
                        System.debug('Lead was not assigned yesterday and has checked out');
                        Datetime checkIndateTime = userTrackingMapToday.get(ld.OwnerId).Checkin_Datetime__c.addHours(5).addMinutes(30);
                        Long timeDifference = currentDateTime.getTime() - checkIndateTime.getTime();
                        System.debug(' currentDateTime ===> ' + currentDateTime + ' userTrackingMapToday.get(ld.OwnerId).Checkin_Datetime__c ===>  ' + userTrackingMapToday.get(ld.OwnerId).Checkin_Datetime__c);
                        System.debug('timeDifference ===> ' + timeDifference + '   ===> ' + timeDifference / (1000 * 60) + ' differenceInMinutes ==> ' + differenceInMinutes);
                        
                        differenceInMinutes = differenceInMinutes + (timeDifference / (1000 * 60));
                        System.debug('differenceInMinutes ===> ' + differenceInMinutes);
                    }
                }
                
                List<Task> taskList = ld.Tasks.isEmpty() ? null : ld.Tasks;
                Boolean hasFollowUpTask = false;
                Boolean hasIncompleteCTITask = false;
                Boolean hasCTITask = false;
                
                System.debug('differenceInMinutes ===> ' + differenceInMinutes);
                if(differenceInMinutes >= 120 && differenceInMinutes <= 180 && !ld.Tasks.isEmpty()){
                    if(!taskList.isEmpty()){
                        for(Task tsk : taskList){
                            System.debug('tsk ===> ' + tsk);
                            
                            if(tsk.Subject == 'Take First Follow Up with Customer - Within 24 Hours' && tsk.Status == 'Open'){
                                hasFollowUpTask = false;
                            }else if(tsk.Subject == 'Take First Follow Up with Customer - Within 4 Hours' && tsk.Status == 'Open'){
                                hasFollowUpTask = true;
                            }
                            
                            if(tsk.Subject.contains('CTI') && tsk.Customer_Status__c != 'completed' && tsk.Agent_Status__c != 'completed'){
                                hasIncompleteCTITask = true;
                                hasCTITask = true;
                            }else{
                                hasCTITask = false;
                            }
                            
                            if(hasFollowUpTask && (hasIncompleteCTITask == true || hasCTITask == false)){
                                Task task = new Task(Id = tsk.Id);
                                task.Status = 'Completed';
                                taskListToUpdate.add(task);
                            }
                        }
                    }
                    
                    System.debug(' hasFollowUpTask ===> ' + hasFollowUpTask + ' hasIncompleteCTITask ===>   ' + hasIncompleteCTITask);
                    if(hasFollowUpTask && (hasIncompleteCTITask == true || hasCTITask == false)){
                        Task taskFor24Hours = new Task(Subject = 'Take First Follow Up with Customer - Within 24 Hours', OwnerId = ld.OwnerId, WhoId = ld.Id );
                        System.debug('taskFor24Hours ===> ' + taskFor24Hours);
                        taskListToInsert.add(taskFor24Hours);
                        
                        if(ld.Lead_Owner_Manager_Email__c != null){
                            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                            email.setTemplateId(emailTemplate4Hrs);
                            email.setToAddresses(new String[] { ld.Lead_Owner_Manager_Email__c });
                            email.setWhatId(ld.Id);
                            emails.add(email);
                        }
                        
                    }
                    
                }else if(differenceInMinutes >= 180 && !ld.Tasks.isEmpty()){
                    
                    if(!taskList.isEmpty()){
                        for(Task tsk : taskList){
                            if(tsk.Subject == 'Take First Follow Up with Customer - Within 24 Hours' && tsk.Status == 'Open'){
                                hasFollowUpTask = true;
                            }
                            if(tsk.Subject.contains('CTI') && tsk.Customer_Status__c != 'completed' && tsk.Agent_Status__c != 'completed'){
                                hasIncompleteCTITask = true;
                                hasCTITask = true;
                            }else{
                                hasCTITask = false;
                            }
                            
                            if(hasFollowUpTask && (hasIncompleteCTITask == true || hasCTITask == false)){
                                Task task = new Task(Id = tsk.Id);
                                task.Status = 'Completed';
                                taskListToUpdate.add(task);
                            }
                        }
                    }
                    
                    if(hasFollowUpTask && (hasIncompleteCTITask == true || hasCTITask == false)){
                        Task taskFor24Hours = new Task(Subject = 'Take Follow Up with Customer', OwnerId = ld.OwnerId, WhoId = ld.Id );
                        taskListToInsert.add(taskFor24Hours);
                        
                        if(ld.Lead_Owner_Manager_Email__c != null){
                            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                            email.setTemplateId(emailTemplate24Hrs);
                            email.setToAddresses(new String[] { ld.Lead_Owner_Manager_Email__c });
                            email.setWhatId(ld.Id);
                            emails.add(email);
                        }
                    }
                }
                
            }
            
            if(!taskListToInsert.isEmpty()){
                insert taskListToInsert;
                System.debug('taskListToInsert ===> ' + taskListToInsert);
            }
            
            if(!taskListToUpdate.isEmpty()){
                update taskListToUpdate;
            }
            
            if (!emails.isEmpty()) {
                Messaging.sendEmail(emails);
            }
        }catch(Exception e){
            system.debug('error ===> ' + e.getMessage());
            system.debug('error line ===> ' + e.getLineNumber());
        }
        
    }
    
    public void finish(Database.BatchableContext bc){
        System.debug('Batch - BatchOnLeadToTakeFollowUp ran successfully !!! ');
    }
    
}