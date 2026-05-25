@RestResource(urlMapping='/web_lead')
global without sharing class API_WebsiteLeadCreate {
    
    @HttpPost
    global static void API_WebsiteLead(){
        DateTime currentDateTime        = System.now();
        RestRequest req                 = RestContext.request;
        Blob body                       = req.requestBody;
        String requestString            = body.toString();
        String responseBody;
        
        try {
            Map<String,Object> leadWrap = (Map<String,Object>) JSON.deserializeUntyped(requestString);
            System.debug('leadWrap ==> ' + leadWrap);
            
            if(leadWrap != null){
                String createLeadResponse = createLeadRecord(leadWrap);
                if(createLeadResponse.startsWith('Success')){
                    responseBody = JSON.serialize(new IntegrationWrapper.APIResponseWrapper('Success', createLeadResponse));
                    HTTPUtility.getInstance().createServiceLogger(requestString, responseBody, '/web_lead', 'POST', 200, currentDateTime, currentDateTime, null);
                }else{
                    responseBody = JSON.serialize(new IntegrationWrapper.APIResponseWrapper('Error', createLeadResponse));
                    HTTPUtility.getInstance().createServiceLogger(requestString, responseBody, '/web_lead', 'POST', 400, currentDateTime, currentDateTime, null);
                }
                RestContext.response.responseBody = Blob.valueOf(responseBody);
            }
        } catch (Exception e) {
            System.debug('Error in API_WebsiteLeadCreate ===> ' + e.getMessage());
            System.debug('Line ===> ' + e.getLineNumber());
        }
    }
    
    public static String createLeadRecord(Map<String,Object> leadWrap){
        try {
            String firstName = leadWrap.containsKey('firstName') != null ? (String)leadWrap.get('firstName') : null;
            String lastName  = leadWrap.containsKey('lastName') != null ? (String)leadWrap.get('lastName') : null;
            String email     = leadWrap.containsKey('email') != null ? (String)leadWrap.get('email') : null;
            String phone     = leadWrap.containsKey('phone') != null ? (String)leadWrap.get('phone') : null;
      
            System.debug('firstName ==> ' + firstName);
            
       
            if(lastName == null || lastName == ''){
                return 'Error : Last Name is a mandatory field.';
            }
   
           if(phone == null || phone == ''){
             return 'Error : Phone is a mandatory field.';
            }
            
             String projectName     = leadWrap.containsKey('project') != null ? (String)leadWrap.get('project') : null;

          
           List<Project__c> projectRec = [SELECT Id, Name FROM Project__c Where Name =:projectName LIMIT 1];
            System.debug('projectRec==>'+projectRec);
           if(projectRec.isEmpty()){
               return 'Error: Project does not exist.';
           }
  
            Group leadQueue = [SELECT Id, DeveloperName, Name FROM Group WHERE DeveloperName = 'Lead_Assignment_Queue' LIMIT 1];

          

            
            
            Lead leadToInsert = new Lead(
                FirstName = leadWrap.containsKey('firstName') ? (String)leadWrap.get('firstName') : null,
                LastName = leadWrap.containsKey('lastName') ? (String)leadWrap.get('lastName') : null,
                Email = leadWrap.containsKey('email') ? (String)leadWrap.get('email') : null,
                Phone = leadWrap.containsKey('phone') ? (String)leadWrap.get('phone') : null,
                Company = (String)leadWrap.get('lastName'),
                Project__c = projectRec[0].Id,

                UTM_Source__c = leadWrap.containsKey('utm_source') ? (String)leadWrap.get('utm_source') : null,
                UTM_Campaign__c = leadWrap.containsKey('utm_medium') ? (String)leadWrap.get('utm_medium') : null,
                UTM_Medium__c =  leadWrap.containsKey('utm_campaign') ? (String)leadWrap.get('utm_campaign') : null,
         
                UTM_Term__c = leadWrap.containsKey('utm_term') ? (String)leadWrap.get('utm_term') : null,
                LeadSource = leadWrap.containsKey('lead_source') ? (String)leadWrap.get('lead_source') : null,
           
                Lead_Type__c = leadWrap.containsKey('lead_type') ? (String)leadWrap.get('lead_type') : null,
                External_Lead__c = true,
                OwnerId = leadQueue.Id
            );

           

            List<String> phones = new List<String>();
            List<String> emails = new List<String>();
            Map<String,Lead> leadByEmailMap = new Map<String,Lead>();
            Map<String,Lead> leadByPhoneMap = new Map<String,Lead>();

            if(leadToInsert.Phone != null){
                phones.add(leadToInsert.Phone);
            }
            if(leadToInsert.Email != null){
                emails.add(leadToInsert.Email);
            }
             if(leadToInsert.Alternate_Phone__c != null){
                phones.add(leadToInsert.Alternate_Phone__c);
             }
            // if(leadToInsert.Alternate_Email__c != null){
            //     emails.add(leadToInsert.Alternate_Email__c);
            // }

            if(leadToInsert.Phone != null && !leadByPhoneMap.containsKey(leadToInsert.Phone)){
                leadByPhoneMap.put(leadToInsert.Phone, leadToInsert);
            }
            if(leadToInsert.Email != null && !leadByEmailMap.containsKey(leadToInsert.Email)){
                leadByEmailMap.put(leadToInsert.Email, leadToInsert);
            }
             if(leadToInsert.Alternate_Phone__c != null && !leadByPhoneMap.containsKey(leadToInsert.Alternate_Phone__c)){
                 leadByPhoneMap.put(leadToInsert.Alternate_Phone__c, leadToInsert);
             }
            // if(leadToInsert.Alternate_Email__c != null && !leadByEmailMap.containsKey(leadToInsert.Alternate_Email__c)){
            //     leadByEmailMap.put(leadToInsert.Alternate_Email__c, leadToInsert);
            // }

             
            system.debug('leadByEmailMap ===> ' + leadByEmailMap);
            system.debug('leadByPhoneMap ===> ' + leadByPhoneMap);
            
            List<Lead> duplicateLeads = new List<Lead>();
            List<Lead> leadstoUpdate = new List<Lead>();
            List<Lead> allLeads = [SELECT Id, Email, Phone, Lead_Type__c,Alternate_Email__c,Alternate_Phone__c, CreatedDate, Status, isConverted,LastName,Project__c,LeadSource,Lead_Sub_Source__c FROM Lead];
            System.debug('allLeads==>'+allLeads);
            duplicateLeads = [SELECT Id, Email, Phone, Lead_Type__c,Alternate_Email__c,Alternate_Phone__c, CreatedDate, Status, isConverted,LastName,Project__c,LeadSource,Lead_Sub_Source__c FROM Lead WHERE (Phone IN :phones OR Email IN :emails OR Alternate_Phone__c IN :phones )  ORDER BY CreatedDate DESC];
            System.debug('Duplicate Leads: ' + duplicateLeads);

            List<Lead> leadsToDelete = new List<Lead>();

            if(!duplicateLeads.isEmpty()){
                for(Lead dupLead : duplicateLeads){
                    System.debug('dupLea==>'+dupLead);
                    System.debug('leadByPhoneMap.containsKey(dupLead.Phone)==>'+leadByPhoneMap.containsKey(dupLead.phone));
                    
                    if(dupLead.Lead_Type__c == 'Direct' &&
                       ((dupLead.Phone != null && leadByPhoneMap.containsKey(dupLead.Phone) && leadByPhoneMap.get(dupLead.Phone).Lead_Type__c == 'Direct' && dupLead.Lead_Type__c == 'Direct' ) ||
                        (dupLead.Email != null && leadByEmailMap.containsKey(dupLead.Email) && leadByEmailMap.get(dupLead.Email).Lead_Type__c == 'Direct' && dupLead.Lead_Type__c == 'Direct'))){
                            system.debug('first condition');
                            system.debug('dupLead ===> ' + dupLead);
                            dupLead.Status = 'Re-Enquiry';
                            leadstoUpdate.add(dupLead);
                            system.debug('new lead type ===> ' + leadByPhoneMap.get(dupLead.Phone).Lead_Type__c);
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
                        }
                        if(dupLead.Alternate_Phone__c != null && leadByPhoneMap.containsKey(dupLead.Alternate_Phone__c)){
                             return 'Duplicate Lead created within 60 days found with same Phone Number.';
                         }
                        // if(dupLead.Alternate_Email__c != null && leadByEmailMap.containsKey(dupLead.Alternate_Email__c)){
                        //     return'Duplicate Lead created within 60 days found with same Email.';
                        // }
                    }else{
                        system.debug('else default condition');
                    }
                }
            }
            if(!leadstoUpdate.isEmpty()){
                System.debug('leadstoUpdate: ' + leadstoUpdate);
                update leadstoUpdate; 
                insert leadToInsert;
            }else{
                insert leadToInsert;
                //  CampaignMember member = new CampaignMember(
               //     LeadId=leadToInsert.Id,
               //    CampaignId=CampaignRec[0].Id
              //    );
              //  insert member; 
            }
                     
            return 'Success: Lead created successfully';
            
        } catch (Exception e) {
            System.debug('Error in createLeadRecord ===> ' + e.getMessage());
            System.debug('line ===> ' + e.getLineNumber());
            return 'Error:' + e.getMessage();
        }
    }
}