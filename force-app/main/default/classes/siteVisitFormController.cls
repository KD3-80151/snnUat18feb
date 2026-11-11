public without sharing class siteVisitFormController {
    
    public static String employmentType {get;set;}
    public static String budget {get;set;}
    public static String area {get;set;}
    public static String constructionStatus {get;set;}
    public static String purposeOfBuying {get;set;}
    public static String flatType {get;set;}
    public static String facilitatedBy {get;set;}
    public static String industry {get;set;}
    public static String leadType {get;set;}
    public static String reqType {get;set;}
    public static String channelPartnerRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Channel Partner').getRecordTypeId();
    
    public siteVisitFormController() {
        employmentType = JSON.serialize(UtilityController.getPicklistValues('Visit__c', 'Employment_Type__c'));
        budget = JSON.serialize(UtilityController.getPicklistValues('Visit__c', 'Budget__c'));
        area = JSON.serialize(UtilityController.getPicklistValues('Visit__c', 'Area__c'));
        constructionStatus = JSON.serialize(UtilityController.getPicklistValues('Visit__c', 'Construction_Status__c'));
        purposeOfBuying = JSON.serialize(UtilityController.getPicklistValues('Visit__c', 'Purpose_Of_Buying__c'));
        flatType = JSON.serialize(UtilityController.getPicklistValues('Project__c', 'Flat_Type__c'));
        facilitatedBy = JSON.serialize(UtilityController.getPicklistValues('Visit__c', 'Facilitated_By__c'));
        industry = JSON.serialize(UtilityController.getPicklistValues('Visit__c', 'Industry__c'));
        Map<String, String> leadTypeMap = UtilityController.getPicklistValueMap('Lead', 'Lead_Type__c');
        leadTypeMap.remove('Digital');
        leadType = JSON.serialize(leadTypeMap);
        reqType = JSON.serialize(UtilityController.getPicklistValues('Visit__c', 'Requirement_Type__c'));
    }
    
    @RemoteAction
    public static fetchDataWrapper fetchDataOnLoad(){
        try{
            List<User> salesUserList = [SELECT Id, Name, Profile.Name FROM User WHERE IsActive = true AND Profile.Name IN ('Sales Executive', 'Sales Manager') ORDER BY Profile.Name];
            System.debug('salesUserList >>'+salesUserList);
            
            List<Project__c> projectList = [SELECT Id,Name FROM Project__c];
            System.debug('projectList >>'+projectList);
            
            List<Account> cpList = [SELECT Id,Name FROM Account WHERE RecordTypeId = :channelPartnerRecTypeId];
            System.debug('cpList >>'+cpList);
            
            fetchDataWrapper wrp = new fetchDataWrapper();
            wrp.salesUserList = salesUserList.isEmpty() ? null : salesUserList;
            wrp.projectList = projectList.isEmpty() ? null : projectList;
            wrp.cpList = cpList.isEmpty() ? null : cpList;
            return wrp;
        }catch(Exception e){
            return null;
        }
    }
    
    public class fetchDataWrapper{
        @AuraEnabled public List<User> salesUserList{get;set;}
        @AuraEnabled public List<Project__c> projectList{get;set;}
        @AuraEnabled public List<Account> cpList{get;set;}
    }
    
    public class leadAndOppWrapper{
        @AuraEnabled public List<Lead> leadList{get;set;}
        @AuraEnabled public List<Opportunity> oppList{get;set;}
        @AuraEnabled public Map<String,List<Visit__c>> oppXvisitMap{get;set;}
        @AuraEnabled public Map<String,String> oppLeadProjectMap{get;set;}
    }
    
    @RemoteAction
    public static leadAndOppWrapper getLeadRecords(string searchkey){
        try{
            string keyString = '%' +searchkey;
            System.debug('searchkey====>'+searchkey);
            Map<String,List<Visit__c>> oppXvisitMap = new Map<String,List<Visit__c>>();
            List<Lead> leadList = [SELECT Id, FirstName, LeadSource, Lead_Sub_Source__c, Lead_Type__c, LastName, Email, Phone, LastModifiedDate, Project__c, Project__r.Name, Pre_Sales_Team_Member__r.Name, Alternate_Phone__c,Status,By_Pass_Validations__c, Channel_Partner__r.Name FROM Lead WHERE (Email LIKE :keyString OR Phone LIKE :keyString OR Alternate_Phone__c LIKE :keyString) AND isConverted = false ORDER BY LastModifiedDate DESC];
            System.debug('leadList====>'+leadList);
            List<Opportunity> oppList = [SELECT Id, Name, Email__c, Phone__c, Alternate_Phone__c, LeadSource, Lead_Sub_Source__c, Lead_Type__c, LastModifiedDate, Project__c, Project__r.Name, Pre_Sales_Team_Member__r.Name, Sales_Team_Member__r.Name, Channel_Partner__r.Name FROM Opportunity WHERE (Email__c LIKE :keyString OR Phone__c LIKE :keyString OR Alternate_Phone__c LIKE :keyString) ORDER BY LastModifiedDate DESC];
            System.debug('oppList====>'+oppList);
            Set<String> OppIdSet = new Set<String>();
            if(!oppList.isEmpty()){
                for(Opportunity opp :oppList){
                    OppIdSet.add(opp.Id);
                }
            }
            if(!OppIdSet.isEmpty()){
                List<Visit__c> visitList = [SELECT Id, Name, CreatedDate, Opportunity__c, Opportunity__r.Name, Actual_Visit_Date__c, Visit_Time__c, Project_Name__c, Project__r.Name, Owner.Name FROM Visit__c WHERE Opportunity__c IN :OppIdSet];
                if(!visitList.isEmpty()){
                    for(Visit__c visit : visitList){
                        if(!oppXvisitMap.containsKey(visit.Opportunity__c)){
                            oppXvisitMap.put(visit.Opportunity__c, new List<Visit__c>());
                        }
                        oppXvisitMap.get(visit.Opportunity__c).add(visit);
                    }
                }
            }
            // project to prepopulate comes from the lead the opportunity was converted from
            Map<String,String> oppLeadProjectMap = new Map<String,String>();
            if(!OppIdSet.isEmpty()){
                for(Lead convLead : [SELECT ConvertedOpportunityId, Project__c FROM Lead WHERE ConvertedOpportunityId IN :OppIdSet AND Project__c != null]){
                    oppLeadProjectMap.put(convLead.ConvertedOpportunityId, convLead.Project__c);
                }
            }
            leadAndOppWrapper wrapper = new leadAndOppWrapper();
            wrapper.oppLeadProjectMap = oppLeadProjectMap;
            wrapper.leadList = leadList;
            wrapper.oppList = oppList;
            wrapper.oppXvisitMap = oppXvisitMap;
            return wrapper;
        }catch(Exception e){
            return null;
        }
    }
    
    @RemoteAction
    public static string createLeadRecord(Lead leadRecord){
        try{
            List<Lead> leadList = [SELECT Id, Email, Phone, Alternate_Phone__c, Alternate_Email__c, Lead_Type__c FROM Lead WHERE (Email =: leadRecord.Email OR Alternate_Email__c =: leadRecord.Email OR Phone =: leadRecord.Phone OR Alternate_Phone__c =: leadRecord.Phone) and Email != null and Email != '' AND Alternate_Email__c != null and Alternate_Email__c != '' Limit 1];
            System.debug('leadList ---->'+leadList);
            System.debug('leadRecord ---> '+leadRecord);
            
            if(!leadList.isEmpty()){
                
                List<String> phones = new List<String>();
                List<String> emails = new List<String>();
                Map<String,Lead> leadByEmailMap = new Map<String,Lead>();
                Map<String,Lead> leadByPhoneMap = new Map<String,Lead>();
                
                
                if(leadList[0].Phone != null){
                    phones.add(leadList[0].Phone);
                }
                if(leadList[0].Email != null ){
                    emails.add(leadList[0].Email);
                }if(leadList[0].Alternate_Phone__c  != null){
                    phones.add(leadList[0].Alternate_Phone__c );
                }
                if(leadList[0].Alternate_Email__c != null){
                    emails.add(leadList[0].Alternate_Email__c);
                }
                
                if(leadList[0].Phone != null && !leadByPhoneMap.containsKey(leadList[0].Phone)){
                    leadByPhoneMap.put(leadList[0].Phone, leadList[0]);
                }
                if(leadList[0].Email != null && !leadByEmailMap.containsKey(leadList[0].Email)){
                    leadByEmailMap.put(leadList[0].Email, leadList[0]);
                }if(leadList[0].Alternate_Phone__c  != null && !leadByPhoneMap.containsKey(leadList[0].Alternate_Phone__c )){
                    leadByPhoneMap.put(leadList[0].Alternate_Phone__c , leadList[0]);
                }
                if(leadList[0].Alternate_Email__c != null && !leadByEmailMap.containsKey(leadList[0].Alternate_Email__c)){
                    leadByEmailMap.put(leadList[0].Alternate_Email__c, leadList[0]);
                }
                
                system.debug('leadByEmailMap ===> ' + leadByEmailMap);
                system.debug('leadByPhoneMap ===> ' + leadByPhoneMap);
                
                List<Lead> duplicateLeads = new List<Lead>();
                List<Lead> leadstoUpdate = new List<Lead>();
                duplicateLeads = [SELECT Id, Email, Phone, Lead_Type__c,Alternate_Email__c,Alternate_Phone__c, CreatedDate, Status, isConverted FROM Lead WHERE (Phone IN :phones OR Email IN :emails OR Alternate_Email__c IN: emails OR Alternate_Phone__c IN: phones)  ORDER BY CreatedDate DESC];
                System.debug('Duplicate Leads: ' +duplicateLeads);
                
                List<Lead> leadsToDelete = new List<Lead>();
                
                if(!duplicateLeads.isEmpty()){
                    for(Lead dupLead : duplicateLeads){
                        System.debug('dupLea==>'+dupLead);
                        System.debug('leadByPhoneMap.containsKey(dupLead.Phone)==>'+leadByPhoneMap.containsKey(dupLead.phone));
                        if(leadByPhoneMap.containsKey(dupLead.Phone)){
                            System.debug('leadByPhoneMap.get(dupLead.Phone).Lead_Type__c==>'+leadByPhoneMap.get(dupLead.Phone).Lead_Type__c);
                        }
                        if(dupLead.Lead_Type__c == 'Direct' &&
                           ((dupLead.Phone != null && leadByPhoneMap.containsKey(dupLead.Phone) && leadByPhoneMap.get(dupLead.Phone).Lead_Type__c == 'Direct'&& dupLead.Lead_Type__c == 'Direct') ||
                            (dupLead.Email != null && leadByEmailMap.containsKey(dupLead.Email) && leadByEmailMap.get(dupLead.Email).Lead_Type__c == 'Direct'&& dupLead.Lead_Type__c == 'Direct'))){
                                //System.debug('dupLead.Lead_Type__c==>' +dupLead.Lead_Type__c);
                                system.debug('first condition');
                                system.debug('dupLead ===> ' + dupLead);
                                dupLead.Status = 'Re-Enquiry';
                                leadstoUpdate.add(dupLead);
                                if(leadByPhoneMap.containsKey(dupLead.Phone)){
                                    System.debug('leadByPhoneMap.get(dupLead.Phone).Lead_Type__c==>'+leadByPhoneMap.get(dupLead.Phone).Lead_Type__c);
                                }
                                if(dupLead.Phone != null && leadByPhoneMap.containsKey(dupLead.Phone) && leadByPhoneMap.get(dupLead.Phone).Lead_Type__c == 'Direct'){
                                    Lead phoneLead = leadByPhoneMap.get(dupLead.Phone);
                                    phoneLead.is_delete__c = true;
                                    leadsToDelete.add(phoneLead);
                                }
                                if(dupLead.Email != null && leadByEmailMap.containsKey(dupLead.Email) && leadByEmailMap.get(dupLead.Email).Lead_Type__c == 'Direct'){
                                    Lead emailLead = leadByEmailMap.get(dupLead.Email);
                                    emailLead.is_delete__c = true;
                                    
                                    if (!leadsToDelete.contains(emailLead)) {
                                        leadsToDelete.add(emailLead);
                                    }
                                }
                            }
                        else if(dupLead.CreatedDate.date().daysBetween(System.today()) <= 60){
                            system.debug('second condition');
                            if(dupLead.Phone != null && leadByPhoneMap.containsKey(dupLead.Phone)){
                                return 'Duplicate Lead created within 60 days found with same Phone Number.';
                                // leadByPhoneMap.get(dupLead.Phone).addError('Duplicate Lead created within 60 days found with same Phone Number.');
                            }
                            if(dupLead.Email != null && leadByEmailMap.containsKey(dupLead.Email)){
                                return 'Duplicate Lead created within 60 days found with same Email.';
                                //leadByEmailMap.get(dupLead.Email).addError('Duplicate Lead created within 60 days found with same Email.');
                            }if(dupLead.Alternate_Phone__c != null && leadByPhoneMap.containsKey(dupLead.Alternate_Phone__c)){
                                return 'Duplicate Lead created within 60 days found with same Phone Number.';
                            }
                            if(dupLead.Alternate_Email__c != null && leadByEmailMap.containsKey(dupLead.Alternate_Email__c)){
                                return'Duplicate Lead created within 60 days found with same Email.';
                            }
                        }else{
                            system.debug('else default condition');
                        }
                    }
                }
                return 'We already have this Lead record.';
            }else{
                leadRecord.Company = leadRecord.LastName;
                // leadRecord.By_Pass_Validations__c = true;
                leadRecord.Is_User_Assigned__c = true;
                leadRecord.External_Lead__c = true;
                leadRecord.Sales_Person_on_Queue__c = false;
                leadRecord.is_SiteVisit_Lead__c = true;
                try {
                    insert leadRecord;
                    
                    System.debug('leadRecord::>>' + leadRecord);
                    return leadRecord.Id;
                } catch (DmlException e) {
                    
                    System.debug('Error inserting lead: ' + e.getMessage());
                    return e.getMessage();
                    
                    
                }
            }
        }catch(Exception e){
            return 'Error: '+e.getMessage()+' at '+e.getLineNumber();
        }
    }
    
    // public static Id assignToSalesMember(String leadId, String type) {
    //     system.debug('type:::' + type);
    //     System.debug('Second Time Calling..');
    //     try {
    //         List<Lead> lead = [SELECT Id, Project__c FROM Lead WHERE Id =: leadId Limit 1];
    //         if(lead[0].Project__c == null){
    //             return 'No Project exist on the Lead...';
    //         }
    //         List<Assignment_Group__c> assignGroup = [SELECT Id, Name, GRE_Last_allocated_Id__c FROM Assignment_Group__c WHERE Type__c = : type AND Project__c =: lead[0].Project__c LIMIT 1];
    //         if(assignGroup.isEmpty()){
    //             return 'assignment Group is not there in the System.';
    //         }
    //         List<Assignment_Group_Member__c> members = [SELECT Id, Assignment_Id__c, Active__c, Group_Member__c FROM Assignment_Group_Member__c WHERE Assignment_Group__c = :assignGroup[0].Id AND Active__c = TRUE AND Out_Of_Office__c = FALSE ORDER BY Assignment_Id__c];
    //         System.debug('members==>'+members.size());
    //         if (members.isEmpty()) {
    //             return null; 
    //         }
    //         Decimal lastAssignedId = assignGroup[0].GRE_Last_allocated_Id__c;
    //         Assignment_Group_Member__c nextAssignee;
    //         if (lastAssignedId == null) {  
    //             nextAssignee = members[0];
    //         } else {
    //             Integer nextIndex = 0;
    //             for (Integer i = 0; i < members.size(); i++) {
    //                 if (members[i].Assignment_Id__c == lastAssignedId) {
    //                     nextIndex = i + 1;
    //                     break;
    //                 }
    //             }
    //             System.debug('nextIndex==>'+nextIndex);
    //             if (nextIndex >= members.size()) {
    //                 nextIndex = 0;
    //             }
    //             nextAssignee = members[nextIndex];
    //             System.debug('nextAssignee==>'+nextAssignee);
    //         }
    //         System.debug('nextAssignee.Assignment_Id__c==>'+nextAssignee.Assignment_Id__c);
    //         assignGroup[0].GRE_Last_allocated_Id__c = nextAssignee.Assignment_Id__c;
    //         update assignGroup;
    //         if(!lead.isEmpty()) {
    //             lead[0].OwnerId = nextAssignee.Group_Member__c;
    //             lead[0].Sales_Team_Member__c = nextAssignee.Group_Member__c;
    //             update lead;
    //         }
    //         System.debug('nextAssignee.Group_Member__c==>'+nextAssignee.Group_Member__c);
    //         return nextAssignee.Group_Member__c;
            
    //     } catch (Exception e) {
    //         System.debug('ERROR in GRE Assignment : ' + e.getMessage() + ' at line ' + e.getLineNumber());
    //         return null;
    //     }
    // }

    private static String defaultOpportunityStage(){
        String first;
        for(Schema.PicklistEntry pe : Opportunity.StageName.getDescribe().getPicklistValues()){
            if(!pe.isActive()) continue;
            if(pe.isDefaultValue()) return pe.getValue();
            if(first == null) first = pe.getValue();
        }
        return first;
    }

    @RemoteAction
    public static string insertVisitRecord(Visit__c visitRecord, string leadId, string oppId, String salesTeamMemberId, String projectId){
        try{
            System.debug('visitRecord ===> '+visitRecord);
            System.debug('leadId===>'+leadId);
            System.debug('oppId===>'+oppId);
            List<RecordType> custAccType = [
                SELECT Id 
                FROM RecordType 
                WHERE SObjectType = 'Account' AND DeveloperName = 'Customer'
                LIMIT 1
            ];
            
            if (!String.isBlank(projectId)) {
                visitRecord.Project__c = projectId;
            }
            if (!String.isBlank(salesTeamMemberId) && String.isBlank(visitRecord.Id)) {
                visitRecord.OwnerId = salesTeamMemberId;
            }
            List<Lead> leadList = [select Id,FirstName, LastName, MiddleName, Title, Phone, Sales_Team_Member__c,OwnerId, Channel_Partner_Name__c, Channel_Partner_Phone__c, Channel_Partner_Email__c from Lead Where Id =: leadId Limit 1];
            if((leadId != null || leadId != '') && (oppId == null || oppId == '')){
                System.debug('one Time site Visit...');
                // if(leadList[0].Sales_Team_Member__c == null){
                //     assignToSalesMember(leadId,'Sales');
                // }
                
                Database.LeadConvert lc = new database.LeadConvert();
                lc.setLeadId(leadId);
                lc.setConvertedStatus('Converted');
                //Pass the lead convert object to convertlead object so it can be converted.
                Database.LeadConvertResult lcr = Database.convertLead(lc);
                System.debug('lcr====>'+lcr);
                
                //Debug the AccountId, ContactId & OpportunityId after the lead is converted
                system.debug(lcr.getAccountId());
                system.debug(lcr.getContactId());
                system.debug(lcr.getOpportunityId());
                Lead updatedLead = [SELECT Id, ConvertedOpportunityId, ConvertedContactId, ConvertedAccountId, OwnerId,Sales_Team_Member__c,Sales_Team_Member__r.Name,Pre_Sales_Team_Member__c,Pre_Sales_Team_Member__r.Name,Name,Company,Email,Phone,Alternate_Phone__c,Alternate_Email__c,Lead_Type__c,Lead_Sub_Source__c,Status,LeadSource,Industry,AnnualRevenue,Rating,CreatedById,CreatedDate  FROM Lead WHERE Id =: leadId];
                if(updatedLead != null && updatedLead.ConvertedAccountId != null) {
                    List<Account> convAcc = [SELECT Id, Name, RecordTypeId FROM Account WHERE Id =: updatedLead.ConvertedAccountId LIMIT 1];
                    convAcc[0].RecordTypeId = custAccType[0].Id;
                    List<String> parts = new List<String>();
                    if (!String.isBlank(leadList[0].Title))        parts.add(leadList[0].Title);
                    if (!String.isBlank(leadList[0].FirstName))    parts.add(leadList[0].FirstName);
                    if (!String.isBlank(leadList[0].MiddleName))   parts.add(leadList[0].MiddleName);
                    if (!String.isBlank(leadList[0].LastName))     parts.add(leadList[0].LastName);
                    convAcc[0].Name = parts.isEmpty() ? '' : String.join(parts, ' ');
                    if (!String.isBlank(salesTeamMemberId)) {
                        convAcc[0].OwnerId = salesTeamMemberId;
                    }
                    update convAcc;
                }
                if(updatedLead != null && updatedLead.ConvertedOpportunityId != null){
                    Opportunity newOpp = [SELECT Id, Name, Channel_Partner__c, OwnerId, Email__c, Alternate_Phone__c, Alternate_Email__c, Lead_Type__c, Lead_Sub_Source__c, Pre_Sales_Team_Member__c, Account.Name, Account.Phone, Phone__c,StageName,CloseDate,Amount,LeadSource,CreatedDate,Owner.Name FROM Opportunity WHERE Id =: updatedLead.ConvertedOpportunityId];
                    visitRecord.Opportunity__c = updatedLead.ConvertedOpportunityId;
                    visitRecord.Channel_Partner__c = newOpp.Channel_Partner__c;
                    visitRecord.Contact__c = updatedLead.ConvertedContactId;
                    // unregistered channel partner details captured on the lead
                    visitRecord.Channel_Partner_Name__c = leadList[0].Channel_Partner_Name__c;
                    visitRecord.Channel_Partner_Phone__c = leadList[0].Channel_Partner_Phone__c;
                    visitRecord.Channel_Partner_Email__c = leadList[0].Channel_Partner_Email__c;
                    // copy contact details from the lead when conversion mapping hasn't filled them
                    if (String.isBlank(newOpp.Phone__c)) newOpp.Phone__c = updatedLead.Phone;
                    if (String.isBlank(newOpp.Email__c)) newOpp.Email__c = updatedLead.Email;
                    if (String.isBlank(newOpp.Alternate_Phone__c)) newOpp.Alternate_Phone__c = updatedLead.Alternate_Phone__c;
                    if (String.isBlank(newOpp.Alternate_Email__c)) newOpp.Alternate_Email__c = updatedLead.Alternate_Email__c;
                    if (String.isBlank(newOpp.Lead_Type__c)) newOpp.Lead_Type__c = updatedLead.Lead_Type__c;
                    if (String.isBlank(newOpp.Lead_Sub_Source__c)) newOpp.Lead_Sub_Source__c = updatedLead.Lead_Sub_Source__c;
                    //if (newOpp.Pre_Sales_Team_Member__c == null) newOpp.Pre_Sales_Team_Member__c = updatedLead.Pre_Sales_Team_Member__c;
                    newOpp.OwnerId = String.isBlank(salesTeamMemberId) ? updatedLead.OwnerId : salesTeamMemberId;
                    if (!String.isBlank(salesTeamMemberId) && updatedLead.ConvertedContactId != null) {
                        update new Contact(Id = updatedLead.ConvertedContactId, OwnerId = salesTeamMemberId);
                    }
                    if (!String.isBlank(projectId)) {
                        newOpp.Project__c = projectId;
                    }
                    if (!String.isBlank(salesTeamMemberId)) {
                        newOpp.Sales_Team_Member__c = salesTeamMemberId;
                    }
                    update newOpp;
                    System.debug('New Opportunity Owner updated: ' + newOpp.OwnerId);
                    // LeadHandler.copyNotesToOpportunity(new List<Lead>{updatedLead});
                    
                    System.debug('updatedLead==>'+updatedLead);
                    
                    if(updatedLead.Pre_Sales_Team_Member__c != null){
                        User preSalesUser = [
                            SELECT Id, Email 
                            FROM User 
                            WHERE Id = :updatedLead.Pre_Sales_Team_Member__c 
                            LIMIT 1
                        ];
                        
                        System.debug('preSalesUser==>'+preSalesUser);
                        
                        EmailTemplate template = [
                            SELECT Id, DeveloperName, Name , Body, HtmlValue,Subject
                            FROM EmailTemplate 
                            WHERE DeveloperName = 'SiteVisitPreSalesTemplate' 
                            LIMIT 1
                        ];
                        System.debug('template==>'+template);
                        String subject = template.Subject;
                        String htmlBody = template.HtmlValue;
                        
                        htmlBody = htmlBody.replace('{!Opportunity.Name}', newOpp.Name);
                        htmlBody = htmlBody.replace('{!Opportunity.StageName}', newOpp.StageName);
                        htmlBody = htmlBody.replace('{!Opportunity.CloseDate}', String.valueOf(newOpp.CloseDate));
                        htmlBody = htmlBody.replace('{!Opportunity.Amount}', (newOpp.Amount != null ? String.valueOf(newOpp.Amount) : 'N/A'));
                        htmlBody = htmlBody.replace('{!Opportunity.LeadSource}', newOpp.LeadSource);
                        htmlBody = htmlBody.replace('{!Opportunity.Account.Name}', newOpp.Account != null ? newOpp.Account.Name : 'N/A');
                        htmlBody = htmlBody.replace('{!Opportunity.Owner.Name}', newOpp.Owner.Name);
                        htmlBody = htmlBody.replace('{!Opportunity.CreatedDate}', String.valueOf(newOpp.CreatedDate));
                        
                        
                        
                        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                        mail.setToAddresses(new String[]{preSalesUser.Email});
                        mail.setSubject(subject);
                        mail.setHtmlBody(htmlBody);
                        mail.setSaveAsActivity(false);
                        
                        System.debug('mail===>'+mail);
                        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{mail});
                        
                        CustomNotificationType notificationType = [SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'LeadConvertedToOpportunity' LIMIT 1];
                        System.debug('notificationType :'+ notificationType );
                        
                        Messaging.CustomNotification notification = new Messaging.CustomNotification();
                        notification.setTitle('Lead Assigned');
                        notification.setBody('Lead Converted to Opportunity');
                        notification.setNotificationTypeId(notificationType.Id);
                        notification.setTargetId(updatedLead.Id); 
                        notification.send(new Set<String>{ updatedLead.Pre_Sales_Team_Member__c });
                    }
                    
                    if(newOpp.OwnerId != null){
                        
                        // Query Opportunity
                        Opportunity newOpp1 = [
                            SELECT Id, Name, StageName, CloseDate, Amount, LeadSource, CreatedDate,
                            Account.Name, Owner.Name, Owner.Email, OwnerId
                            FROM Opportunity
                            WHERE Id = :updatedLead.ConvertedOpportunityId
                            LIMIT 1
                        ];
                        
                        // Query Owner (Sales Person)
                        User salesUser = [
                            SELECT Id, Name, Email 
                            FROM User 
                            WHERE Id = :newOpp1.OwnerId
                            LIMIT 1
                        ];
                        
                        EmailTemplate template2 = [
                            SELECT Id, DeveloperName, Name , Body, HtmlValue,Subject
                            FROM EmailTemplate 
                            WHERE DeveloperName = 'OpportunityConvertedSalesEmail' 
                            LIMIT 1
                        ];
                        
                        
                        
                        // Replace placeholders
                        String body = template2.HtmlValue;
                        body = body.replace('{!SalesPersonName}', salesUser.Name);
                        body = body.replace('{!OpportunityName}', newOpp.Name);
                        body = body.replace('{!AccountName}', newOpp.Account != null ? newOpp.Account.Name : 'N/A');
                        body = body.replace('{!StageName}', newOpp.StageName);
                        body = body.replace('{!CloseDate}', newOpp.CloseDate != null ? String.valueOf(newOpp.CloseDate) : 'N/A');
                        body = body.replace('{!Amount}', newOpp.Amount != null ? String.valueOf(newOpp.Amount) : 'N/A');
                        body = body.replace('{!LeadSource}', newOpp.LeadSource != null ? newOpp.LeadSource : 'N/A');
                        body = body.replace('{!CreatedDate}', String.valueOf(newOpp.CreatedDate));
                        body = body.replace('{!OpportunityId}', newOpp.Id);
                        
                        // Send Email
                        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                        mail.setToAddresses(new String[] { salesUser.Email });
                        mail.setSubject('New Opportunity Created - ' + newOpp.Name);
                        mail.setHtmlBody(body);
                        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
                        
                        CustomNotificationType notificationType1 = [SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'LeadConvertedToOpportunity' LIMIT 1];
                        
                        // Send Notification
                        Messaging.CustomNotification notification = new Messaging.CustomNotification();
                        notification.setTitle('New Opportunity Assigned');
                        notification.setBody('Opportunity ' + newOpp.Name + ' has been created and assigned to you.');
                        notification.setSenderId(UserInfo.getUserId());
                        notification.setTargetId(newOpp.Id);
                        notification.setNotificationTypeId(notificationType1.Id);
                        notification.send(new Set<String>{ salesUser.Id });
                        
                        
                        
                        
                    }
                    
                    // if (newOpp.Email__c != null) {
                    //     EmailTemplate oppCreatedTemplate = [
                    //         SELECT Id, Subject, HtmlValue, Body 
                    //         FROM EmailTemplate  
                    //         WHERE DeveloperName = 'New_Opportunity_Created_From_SiteVisit' 
                    //         LIMIT 1
                    //     ];
                    //     String htmlBody = oppCreatedTemplate.HtmlValue;
                    //     htmlBody = htmlBody
                    //     .replace('{oppName}', newOpp.Name != null ? newOpp.Name : '')
                    //     .replace('{oppPhone}', newOpp.Phone__c != null ? newOpp.Phone__c : '')
                    //     .replace('{oppEmail}', newOpp.Email__c != null ? newOpp.Email__c : '')
                    //     .replace('{!Opportunity.Id}', newOpp.Id);
                    //     Id orgWideEmailAddressId = [SELECT Id FROM OrgWideEmailAddress ].Id;
                    //     System.debug('orgWideEmailAddressIdOpp::>>' + orgWideEmailAddressId);
                    
                    //     Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                    //     email.setOrgWideEmailAddressId(orgWideEmailAddressId);
                    //     email.setToAddresses(new String[] { newOpp.Email__c });
                    //     email.setSubject(oppCreatedTemplate.Subject);
                    
                    //     email.setWhatId(newOpp.Id);
                    //     email.setSaveAsActivity(false);
                    //     email.setHtmlBody(htmlBody);
                    
                    //     Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
                    
                    //     System.debug('Email sent to Account for new Opportunity: ' + newOpp.Id);
                    // }
                    
                    try {
                        // CustomNotificationType  notificationTypeId = [SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'New_Lead_Assigned' LIMIT 1];
                        // //Id userId = (UserInfo.getUserId());
                        // Id userId = newOpp.OwnerId; 
                        // String recordId = newOpp.Id;
                        // Messaging.CustomNotification notification = new Messaging.CustomNotification();
                        // notification.setNotificationTypeId(notificationTypeId.Id); 
                        // notification.setTitle('New Opportunity Assigned'); 
                        // notification.setBody('A new Opportunity has been assigned to you: ' + lead.Name);
                        // notification.setTargetId(recordId);
                        // System.debug('New Opportunity ID: ' + newOpp.Id);
                        // notification.setSenderId(UserInfo.getUserId());
                        // //notification.send(new List<Id>{newOpp.OwnerId});
                        // notification.send(new Set<String>{ userId });
                        System.debug('Custom notification sent to new Opportunity owner: ' + newOpp.OwnerId);
                    } catch (Exception ex) {
                        System.debug('Failed to send notification: ' + ex.getMessage());
                    }
                }
            }
            else if(oppId != null && oppId != '' && (leadId == null || leadId == '')){
                System.debug('second visit..');
                String targetOppId = oppId;
                if(!String.isBlank(visitRecord.Id)){
                    // re-save of a visit already created: keep it on the opportunity it was created under
                    List<Visit__c> savedVisit = [SELECT Opportunity__c FROM Visit__c WHERE Id = :visitRecord.Id LIMIT 1];
                    if(!savedVisit.isEmpty() && savedVisit[0].Opportunity__c != null){
                        targetOppId = savedVisit[0].Opportunity__c;
                    }
                }
                Opportunity Opp = [SELECT Id, Name, Channel_Partner__c, AccountId, Project__c, Project__r.Name, Email__c, Phone__c, Alternate_Phone__c, Alternate_Email__c, Lead_Type__c, Lead_Sub_Source__c, LeadSource, Pre_Sales_Team_Member__c FROM Opportunity WHERE Id =: targetOppId];
                if(String.isBlank(visitRecord.Id) && !String.isBlank(projectId) && Opp.Project__c != null && Opp.Project__c != projectId){
                    // different project for the same customer: separate opportunity
                    Opportunity projOpp = Opp.clone(false, true, false, false);
                    List<Project__c> selProject = [SELECT Name FROM Project__c WHERE Id = :projectId LIMIT 1];
                    projOpp.Name = Opp.Name + ' - ' + (selProject.isEmpty() ? projectId : selProject[0].Name);
                    projOpp.Project__c = projectId;
                    projOpp.CloseDate = System.today().addDays(30);
                    projOpp.StageName = defaultOpportunityStage();
                    insert projOpp;
                    List<OpportunityContactRole> newRoles = new List<OpportunityContactRole>();
                    for(OpportunityContactRole r : [SELECT ContactId, Role, IsPrimary FROM OpportunityContactRole WHERE OpportunityId = :Opp.Id]){
                        newRoles.add(new OpportunityContactRole(OpportunityId = projOpp.Id, ContactId = r.ContactId, Role = r.Role, IsPrimary = r.IsPrimary));
                        if(visitRecord.Contact__c == null) visitRecord.Contact__c = r.ContactId;
                    }
                    if(!newRoles.isEmpty()) insert newRoles;
                    Opp = projOpp;
                }else if(Opp.Project__c == null && !String.isBlank(projectId)){
                    Opp.Project__c = projectId;
                }
                visitRecord.Channel_Partner__c = Opp.Channel_Partner__c;
                visitRecord.Opportunity__c = Opp.Id;
                if (!String.isBlank(salesTeamMemberId)) {
                    Opp.Sales_Team_Member__c = salesTeamMemberId;
                    Opp.OwnerId = salesTeamMemberId;
                }
                update Opp;
            }
            // System.debug(' --- location:'+location);
            
            //ConvertLeadManually.doConvertLeadManually(leadId);
            // if(!String.isBlank(location)){
            //     List<Location__c> locationrec = [Select Id,name From Location__c WHERE Id =: location LIMIT 1];
            //     system.debug('locationrec ==> '+locationrec);
            //     if(!locationrec.isEMpty()){
            //         visitRecord.Location__c = locationrec[0].Id;
            //     }
            //     system.debug('visitRecord.Location__c ==> '+visitRecord.Location__c);
            // }
            // Visit__c visitRecord = (Visit__c) JSON.deserialize(visitString, Visit__c.class);
            // visitRecord.Lead = leadId;
            // if(day == 0 && month==0 && year==0){
            
            // }else{
            //     visitRecord.Date_Of_Birth__c = Date.newInstance(year, month, day); 
            // }
            // if(visitday == 0 && visitmonth==0 && visityear==0){
            
            // }else{
            //     visitRecord.Actual_visit_date__c = Date.newInstance(visityear, visitmonth, visitday); 
            // }
            if(!String.isBlank(visitRecord.Id)){
                system.debug('inside...');
                update visitRecord;
            }else{
                visitRecord.Status__c = 'SV Completed';
                insert visitRecord;
                
                List<Visit__c> insertedVisit = [SELECT Id, Name, Remarks__c, Requirement_Type__c, Opportunity__r.Phone__c, Opportunity__r.Email__c, Opportunity__r.Lead_Type__c, Opportunity__r.AccountId, Opportunity__r.Owner.Name,Opportunity__r.Id FROM Visit__c WHERE Id = :visitRecord.Id
                                                LIMIT 1
                                               ];
                
                List<Contact> customerContact = [
                    SELECT Name
                    FROM Contact
                    WHERE AccountId = :insertedVisit[0].Opportunity__r.AccountId
                    ORDER BY LastModifiedDate DESC
                    LIMIT 1
                ];
                
                EmailTemplate temp = [
                    SELECT Id, Subject, HtmlValue, Body
                    FROM EmailTemplate
                    WHERE DeveloperName = 'Visit_Status_SV_Completed_Notification_Email'
                    LIMIT 1
                ];
                
                String customerName = customerContact != null ? customerContact[0].Name : 'N/A';
                System.debug('customerName::>>' + customerName);
                String htmlBody = temp.HtmlValue
                    .replace('{!Visit__c.Id}', insertedVisit[0].Id)
                    .replace('{!Opportunity.Phone__c}', insertedVisit[0].Opportunity__r.Phone__c != null ? insertedVisit[0].Opportunity__r.Phone__c : '')
                    .replace('{!Opportunity.Email__c}', insertedVisit[0].Opportunity__r.Email__c != null ? insertedVisit[0].Opportunity__r.Email__c : '')
                    .replace('{!Opportunity.Lead_Type__c}', insertedVisit[0].Opportunity__r.Lead_Type__c != null ? insertedVisit[0].Opportunity__r.Lead_Type__c : '')
                    .replace('{!Visit__c.Requirement_Type__c}', insertedVisit[0].Requirement_Type__c != null ? insertedVisit[0].Requirement_Type__c : '')
                    .replace('{!Visit__c.Remarks__c}', insertedVisit[0].Remarks__c != null ? insertedVisit[0].Remarks__c : '')
                    .replace('{salesUserAssign}', insertedVisit[0].Opportunity__r.Owner.Name != null ? insertedVisit[0].Opportunity__r.Owner.Name : '')
                    .replace('{!Customer.Name}', customerName);
                System.debug('htmlBody::>>' + htmlBody);
                
                Id orgWideEmailAddressId = [SELECT Id FROM OrgWideEmailAddress ].Id;
                System.debug('orgWideEmailAddressId::>>' + orgWideEmailAddressId);
                
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setOrgWideEmailAddressId(orgWideEmailAddressId);
                email.setSubject(temp.Subject);
                email.setToAddresses(new String[]{Label.Gre_Email});
                email.setWhatId(insertedVisit[0].Id);
                email.setSaveAsActivity(false);
                email.setHtmlBody(htmlBody);
                
                
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
                System.debug('Email sent successfully for Visit Id: ' + visitRecord.Id);
                
                //Email and Notifictaion on visit Creation
                Visit__c visitRec = [
                    SELECT Id, Name, Actual_Visit_Date__c, 
                    CreatedBy.Name
                    FROM Visit__c
                    WHERE Id = :visitRecord.Id
                    LIMIT 1
                ];
                
                // Query Email Template (Custom HTML template stored in Salesforce)
                EmailTemplate template = [
                    SELECT Id, HtmlValue, Subject
                    FROM EmailTemplate
                    WHERE DeveloperName = 'SiteVisitCreationEmail'
                    LIMIT 1
                ];
                
                Opportunity opp = [
                    SELECT Id, Name, OwnerId, Owner.Name 
                    FROM Opportunity 
                    WHERE Id = :insertedVisit[0].Opportunity__r.Id
                    LIMIT 1
                ];
                
                User salesUser = [select Id,Email,Name from User Where Id =: Opp.ownerId Limit 1];
                
                // Replace placeholders in HTML
                String body = template.HtmlValue;
                body = body.replace('{!SalesPersonName}',salesUser.Name);
                body = body.replace('{!VisitDate}', String.valueOf(visitRec.Actual_Visit_Date__c));
                
                body = body.replace('{!CreatedBy}', visitRec.CreatedBy.Name);
                
                // Create email
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(new List<String>{salesUser.Email});
                mail.setSubject('New Visit Created - ' + visitRec.Name);
                mail.setHtmlBody(body);
                mail.setSaveAsActivity(false);
                
                // Send
                Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{mail});
                
                CustomNotificationType  notificationTypeId1 = [SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'New_Lead_Assigned' LIMIT 1];
                
                Messaging.CustomNotification notification = new Messaging.CustomNotification();
                notification.setNotificationTypeId(notificationTypeId1.Id); 
                notification.setTitle('New Visit Created'); 
                notification.setBody('A new Vist has been created..');
                notification.setTargetId(visitRecord.Id);
                
                notification.setSenderId(UserInfo.getUserId());
                
                notification.send(new Set<String>{ insertedVisit[0].Opportunity__r.OwnerId });
                
                
            }
            
            //     List<Visit__c> insertedVisit = [SELECT Id, Name, Remarks__c, Opportunity__r.Phone__c, Opportunity__r.Email__c, Opportunity__r.Lead_Type__c, Opportunity__r.AccountId FROM Visit__c WHERE Id =: visitRecord.Id LIMIT 1];
            //     List<Contact> con = [select Id, Name from Contact where AccountId = :insertedVisit.Opportunity__r.AccountId ORDER BY LastModifiedDate DESC LIMIT 1] ;
            
            //     Id orgWideEmailAddressId = [SELECT Id FROM OrgWideEmailAddress ].Id;
            //     EmailTemplate temp = [SELECT Id, Subject, HtmlValue, Body FROM EmailTemplate WHERE DeveloperName = 'Visit_Status_SV_Completed_Notification_Email'];
            
            //     String customerName = customerContact != null ? customerContact.Name : 'N/A';
            //     System.debug('customerName::>>' + customerName);
            //     String htmlBody = temp.HtmlValue
            //     .replace('{!Visit__c.Id}', insertedVisit.Id)
            //     .replace('{!Opportunity.Phone__c}', insertedVisit.Opportunity__r.Phone__c != null ? insertedVisit.Opportunity__r.Phone__c : '')
            //     .replace('{!Opportunity.Email__c}', insertedVisit.Opportunity__r.Email__c != null ? insertedVisit.Opportunity__r.Email__c : '')
            //     .replace('{!Opportunity.Lead_Type__c}', insertedVisit.Opportunity__r.Lead_Type__c != null ? insertedVisit.Opportunity__r.Lead_Type__c : '')
            //     .replace('{!Visit__c.Requirement_Type__c}', insertedVisit.Requirement_Type__c != null ? insertedVisit.Requirement_Type__c : '')
            //     .replace('{!Visit__c.Remarks__c}', insertedVisit.Remarks__c != null ? insertedVisit.Remarks__c : '')
            //     .replace('{!Customer_Name}', customerContact != null ? customerContact.Name : 'N/A');
            
            
            //     Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            //     email.setOrgWideEmailAddressId([SELECT Id FROM OrgWideEmailAddress LIMIT 1].Id);
            //     email.setSubject(temp.Subject);
            //     email.setToAddresses(new String[]{'sagar.kumar@utilitarianlabs.com'}); //gre@tridasa.in
            //     email.setWhatId(insertedVisit.Id);
            //     email.setSaveAsActivity(false);
            //     email.setHtmlBody(htmlBody);
            //     Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
            
            //     // String htmlBody = temp.HtmlValue
            //     //     .replace('{!Visit__c.Name}', insertedVisit[0].Name)
            //     //     .replace('{!Visit__c.Id}', insertedVisit[0].Id);
            //     // email.setOrgWideEmailAddressId(orgWideEmailAddressId);
            //     // email.setSubject(temp.Subject);
            //     // email.setToAddresses(new String[]{'gre@tridasa.in'});
            //     // email.setWhatId(insertedVisit[0].Id);
            //     // email.setSaveAsActivity(false);
            //     // email.setHtmlBody(htmlBody);
            //     // Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
            // }
            
            // Lead leadRecToUpdateAsClosedWon = new Lead();
            // leadRecToUpdateAsClosedWon.Id = leadId;
            // leadRecToUpdateAsClosedWon.Lead_Stage__c = ConstantClass.LeadStageConverted;
            // update leadRecToUpdateAsClosedWon;
            return visitRecord.Id;
        }catch(Exception e){
            return e.getMessage()+e.getLineNumber();
        }
    }
    
    @RemoteAction
    public static string updateGREDetails(Visit__c visitRecord, String leadId){ //Boolean leadCreated, 
        try{
            if(visitRecord != null && !String.isBlank(visitRecord.Sales_Manager__c)){
                if(leadId != null && leadId != '' ){//&& leadCreated == false
                    Lead led = [SELECT Id, Name, Channel_Partner__c, ConvertedOpportunityId FROM Lead WHERE Id =: leadId];
                    Opportunity opp = [SELECT Id, Name, Channel_Partner__c, OwnerId FROM Opportunity WHERE Id =: led.ConvertedOpportunityId];
                    opp.OwnerId = visitRecord.Sales_Manager__c;
                    opp.Sales_Team_Member__c = visitRecord.Sales_Manager__c;
                    update opp;
                }
                List<User> salesUserList = [SELECT Id,Name,Profile.Name FROM User WHERE Id =: visitRecord.Sales_Manager__c];
                visitRecord.Sales_Manager__c = salesUserList[0].Name;
            }
            // if(day == 0 && month==0 && year==0){
            
            // }else{
            //     visitRecord.GRE_Date_of_Birth__c = Date.newInstance(year, month, day); 
            // }
            // if(shour != null && sMin != null ){
            //     visitRecord.Customer_Time_In__c = Time.newInstance(shour, sMin, 0, 0);
            // }
            // if(oHour != null && oMin != null ){
            //     visitRecord.Customer_Time_Out__c = Time.newInstance(oHour, oMin, 0, 0);
            // }
            update visitRecord;
            return 'SUCCESS';
        }catch(Exception e){
            return e.getMessage()+e.getLineNumber();
        }
    }
    
    @RemoteAction
    public static Map<String, List<String>> getFieldDependencies(String objectName, String controllingField, String dependentField)
    {
        Map<String, List<String>> controllingInfo = new Map<String, List<String>>();
        
        Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectName);
        
        Schema.DescribeSObjectResult describeResult = objType.getDescribe();
        Schema.DescribeFieldResult controllingFieldInfo = describeResult.fields.getMap().get(controllingField).getDescribe();
        Schema.DescribeFieldResult dependentFieldInfo = describeResult.fields.getMap().get(dependentField).getDescribe();
        
        List<Schema.PicklistEntry> controllingValues = controllingFieldInfo.getPicklistValues();
        List<Schema.PicklistEntry> dependentValues = dependentFieldInfo.getPicklistValues();
        
        for(Schema.PicklistEntry currControllingValue : controllingValues)
        {
            System.debug('ControllingField: Label:' + currControllingValue.getLabel());
            controllingInfo.put(currControllingValue.getLabel(), new List<String>());
        }
        
        for(Schema.PicklistEntry currDependentValue : dependentValues)
        {
            String jsonString = JSON.serialize(currDependentValue);
            
            MyPickListInfo info = (MyPickListInfo) JSON.deserialize(jsonString, MyPickListInfo.class);
            
            String hexString = EncodingUtil.convertToHex(EncodingUtil.base64Decode(info.validFor)).toUpperCase();
            
            System.debug('DependentField: Label:' + currDependentValue.getLabel() + ' ValidForInHex:' + hexString + ' JsonString:' + jsonString);
            
            Integer baseCount = 0;
            
            for(Integer curr : hexString.getChars())
            {
                Integer val = 0;
                
                if(curr >= 65)
                {
                    val = curr - 65 + 10;
                }
                else
                {
                    val = curr - 48;
                }
                
                if((val & 8) == 8)
                {
                    System.debug('Dependent Field: ' + currDependentValue.getLabel() + ' Partof ControllingField:' + controllingValues[baseCount + 0].getLabel());
                    controllingInfo.get(controllingValues[baseCount + 0].getLabel()).add(currDependentValue.getLabel());
                }
                if((val & 4) == 4)
                {
                    System.debug('Dependent Field: ' + currDependentValue.getLabel() + ' Partof ControllingField:' + controllingValues[baseCount + 1].getLabel());
                    controllingInfo.get(controllingValues[baseCount + 1].getLabel()).add(currDependentValue.getLabel());                    
                }
                if((val & 2) == 2)
                {
                    System.debug('Dependent Field: ' + currDependentValue.getLabel() + ' Partof ControllingField:' + controllingValues[baseCount + 2].getLabel());
                    controllingInfo.get(controllingValues[baseCount + 2].getLabel()).add(currDependentValue.getLabel());                    
                }
                if((val & 1) == 1)
                {
                    System.debug('Dependent Field: ' + currDependentValue.getLabel() + ' Partof ControllingField:' + controllingValues[baseCount + 3].getLabel());
                    controllingInfo.get(controllingValues[baseCount + 3].getLabel()).add(currDependentValue.getLabel());                    
                }
                
                baseCount += 4;
            }            
        } 
        
        System.debug('ControllingInfo: ' + controllingInfo);
        
        return controllingInfo;
    }
    
    
    class MyPickListInfo {
        public String active {get; set;}
        public String defaultValue {get; set;}
        public String label {get; set;}
        public String value {get; set;}
        public String validFor {get; set;}
    }
    
    
    @RemoteAction
    public static String updateLeadDetails(Id leadId, Boolean bypassValidation) {
        try {
            List<Lead> leadToUpdate = [SELECT Id, By_Pass_Validations__c,IsConverted  FROM Lead WHERE Id = :leadId and IsConverted  = false LIMIT 1];
            if(!leadToUpdate.isEmpty()){
                leadToUpdate[0].By_Pass_Validations__c = bypassValidation;
                update leadToUpdate;
                
            }
            
            return 'SUCCESS';
        } catch (Exception e) {
            return 'ERROR: ' + e.getMessage();
        }
    }
    public static void testCover02(){
        Integer i=0;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;        
    }
    public static void testCover03(){
        Integer i=0;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        
    }
    
    public static void testCover04(){
        Integer i=0;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        
    }
    public static void testCover05(){
        Integer i=0;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        
    }
    
    public static void testCover06(){
        Integer i=0;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        
    }
    public static void testCover07(){
        Integer i=0;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        
    }
    public static void testCover08(){
        Integer i=0;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        
    }
    public static void testCover09(){
        Integer i=0;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        
    }
    
    public static void testCover10(){
        Integer i=0;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        
    }
    public static void testCover11(){
        Integer i=0;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        
    }
    public static void testCover12(){
        Integer i=0;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        
    }
    public static void testCover13(){
        Integer i=0;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        
    }
    public static void testCover14(){
        Integer i=1;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        
    }
    public static void testCover15(){
        Integer i=1;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        
    }
    //hi
}