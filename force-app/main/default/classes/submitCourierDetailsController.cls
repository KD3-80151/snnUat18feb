public without sharing class submitCourierDetailsController {

    @AuraEnabled(cacheable=true)
    public static Opportunity getOppDetails(String taskId){
        System.debug('Task id: '+taskId);
        try {
            if(String.isBlank(taskId)){
                return null;
            }
            Task tsk = [SELECT Id, WhatId FROM Task WHERE Id = :taskId LIMIT 1];
            if(tsk != null && tsk.WhatId != null && tsk.Whatid.getSObjectType().getDescribe().getName() == 'Opportunity'){
                List<Opportunity> oppList = [SELECT Id,Company__c,Docket_Number__c,Courier_Date__c from Opportunity where Id = :tsk.WhatId LIMIT 1];
                System.debug('Opp data'+oppList);
                if(!oppList.isEmpty()){
                    return oppList[0];
                }
            }
            return null;
        } catch (Exception e) {
            System.debug('Error in getOppDetails ===> ' + e.getMessage());
            System.debug('Line number ===> ' + e.getLineNumber());
            return null;
        }
    }


    @AuraEnabled
    public static void saveOppResult(Date courierDateValue, String oppId, String courierCompanyValue,String courierDocketNumber, String taskId){

        try{
            System.debug('courierDateValue ===> ' + courierDateValue + ' oppId = ' + oppId);
            System.debug('courierCompanyValue ===> ' + courierCompanyValue);
            System.debug('courierDocketNumber ===> ' + courierDocketNumber);

            List<Messaging.SingleEmailMessage> emailMessageList = new List<Messaging.SingleEmailMessage>();

            Opportunity oppRec = [SELECT Id,AccountId, Name, Email__c, OwnerId, StageName, Company__c, Docket_Number__c, Courier_Date__c from Opportunity where Id =: oppId LIMIT 1];
            Contact conRec = [select id,AccountId,FirstName,LastName,Name FROM Contact WHERE AccountId = :oppRec.AccountId ORDER BY CreatedDate DESC LIMIT 1 ];
            oppRec.Company__c = courierCompanyValue;
            oppRec.Docket_Number__C = courierDocketNumber;
            oppRec.Courier_Date__c = courierDateValue;
            if(oppRec != null){
                update oppRec;
            }

            if(oppRec.Email__c != null){
                EmailTemplate template = [SELECT Id, Subject, HtmlValue FROM EmailTemplate WHERE DeveloperName = 'Send_Courier_Details_to_Customer' LIMIT 1];
                system.debug('template ====> '+template);

                String subject = template.Subject;
                subject = subject.replace('{!Opportunity.Name}', oppRec.Name != null ? oppRec.Name : '');

                String emailBody = template.HtmlValue;
                emailBody = emailBody.replace('{!Opportunity.Name}', conRec.Name != null ? conRec.Name : '');
                emailBody = emailBody.replace('{!Opportunity.Courier_Date__c}', oppRec.Courier_Date__c != null ? oppRec.Courier_Date__c.format() : '');
                emailBody = emailBody.replace('{!Opportunity.Company__c}', oppRec.Company__c != null ? oppRec.Company__c : '');
                emailBody = emailBody.replace('{!Opportunity.Docket_Number__c}', oppRec.Docket_Number__C != null ? oppRec.Docket_Number__C : '');

                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(new String[] { oppRec.Email__c });
                mail.setSubject(subject);
                mail.setHtmlBody(emailBody);
                mail.setSaveAsActivity(false);
                mail.setWhatId(oppRec.Id);
                emailMessageList.add(mail);

                if(!emailMessageList.isEmpty()){
                Messaging.sendEmail(emailMessageList);
                }
                System.debug('Email sent successfully to ' + oppRec.Email__c);
            }
            

            oppRec.StageName = 'Agreement Sent To Customer';
            update oppRec;

            Task tsk = new Task();
            tsk.Id = taskId;
            tsk.Status = 'Completed';
            update tsk;

            Task newTask = new Task();
            newTask.Subject = 'Agreement Signed By Customer';
            newTask.Priority = 'High';   
            newTask.OwnerId = oppRec.OwnerId;
            newTask.WhatId = oppId;
            insert newTask;
        }catch(Exception error){
            System.debug('Error in saveOppResult ===> ' + error.getMessage());
            System.debug('Line number ===> ' + error.getLineNumber());
        }

    }

}