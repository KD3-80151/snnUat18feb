public without sharing class assignToSalesTeamController {
    @AuraEnabled(cacheable=false)
    public static List<User> getUsersWithSalesTeamProfile() {
        return [SELECT Id, Name FROM User WHERE Profile.Name IN ('Sales Executive', 'Sales Manager', 'Sales Head')];
    }
    
    @AuraEnabled
    public static void updateLeadOwner(Id leadId, String type) {
        
        System.debug('Updating lead owner with Lead ID: ' + leadId);
        
        Lead lead = [SELECT Id, Name, Email, Phone, OwnerId,Owner.Name, Sales_Team_Member__c FROM Lead WHERE Id = :leadId LIMIT 1];
      
        System.debug('Lead record found: ' + lead);
        
        if (lead != null) {
          //  lead.Sales_Person_on_Queue__c = TRUE;
            lead.Is_User_Assigned__c = TRUE;
          //  lead.OwnerId = newOwnerId;
            
          //  lead.Sales_Team_Member__c =leadQueue.ID;
            System.debug('Lead before update: ' + lead);
            update lead;

            salesLeadAssignment.ExecuteLoadAssignment1(10, type);
            System.debug('Lead successfully updated. New Owner ID: ' + lead.OwnerId);

            // List<Messaging.SingleEmailMessage> emailMessageList = new List<Messaging.SingleEmailMessage>();
            // EmailTemplate template = [SELECT Id, Subject, HtmlValue
            //                             FROM EmailTemplate 
            //                             WHERE DeveloperName = 'Lead_Assignment_Notification_Email_Template' 
            //                             LIMIT 1];
            // system.debug('template ====> '+template);
            // String subject = template.Subject;
            // String emailBody = template.HtmlValue;
            // emailBody = emailBody.replace('{!Lead.OwnerFullName}', newOwner.Name != null ? newOwner.Name : '');
            // emailBody = emailBody.replace('{!Lead.Name}', lead.Name != null ? lead.Name : '');
            // emailBody = emailBody.replace('{!Lead.Email}', lead.Email != null ? lead.Email : '');
            // emailBody = emailBody.replace('{!Lead.Phone}', lead.Phone != null ? lead.Phone : '');
            // emailBody = emailBody.replace('{!Lead.Id}', lead.Id != null ? lead.Id : '');

            // Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            // mail.setToAddresses(new String[] { newOwner.Email });
            // mail.setSubject(subject);
            // mail.setHtmlBody(emailBody);
            // mail.setSaveAsActivity(false);
            // mail.setWhatId(lead.Id);
            // emailMessageList.add(mail);

            // if(!emailMessageList.isEmpty()){
            //     Messaging.sendEmail(emailMessageList);
            // }
            // System.debug('Email sent successfully to ' + newOwner.Email);

          /*  Task task = new Task();
            task.Subject = 'New Lead Assigned to you, please take follow up.';
            task.OwnerId = newOwnerId;
            task.Priority = 'High';
            insert task;
            System.debug('Task inserted successfully');*/
        } else {
            
            System.debug('Error: Lead not found.');
            throw new AuraHandledException('Lead not found.');
        }
    }

    @AuraEnabled(cacheable=false)
    public static Lead getLeadDetails(String leadId) {
        System.debug('Entering getLeadDetails with leadId: ' + leadId);
        try {
            Lead lead = [SELECT Id, Is_Qualified__c FROM Lead WHERE Id = :leadId LIMIT 1];
            System.debug('Fetched lead details: ' + lead);
            return lead;
        } catch (Exception e) {
            System.debug('Error fetching lead details: ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }
}