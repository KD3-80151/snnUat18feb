public without sharing class ChannelPartner_Controller {
    public string tabValues {get;set;}
    public static String status {get;set;}
    public static String oppStage {get;set;}
    public static String caseType {get;set;}
    public static String companyType {get;set;}
    public static String msmeValues {get;set;}
    public static String leadSource {get;set;}
    public static String leadSubSource {get;set;}
    public static String focusAreas {get;set;}
    public static String ProductInterest {get;set;}
    public static String BankAccType {get;set;}
    public static String channelPartnerRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Channel Partner').getRecordTypeId();

    public ChannelPartner_Controller(){
        list<Channel_Partner_Dashboard_Tabs__c> cdTabs = [select name,Tab_Label__c,id,Controller_Name__c,Display_Order__c from Channel_Partner_Dashboard_Tabs__c ORDER BY Display_Order__c];
        tabValues = JSON.serialize(cdTabs);
        status = JSON.serialize(UtilityController.getPicklistValuesWithAll('Lead','Status'));
        oppStage = JSON.serialize(UtilityController.getPicklistValuesWithAll('Opportunity','StageName'));
        leadSource = JSON.serialize(UtilityController.getPicklistValues('Lead','LeadSource'));
        leadSubSource = JSON.serialize(UtilityController.getPicklistValues('Lead','Lead_Sub_Source__c'));
        caseType = JSON.serialize(UtilityController.getPicklistValues('Case','Type'));
        companyType = JSON.serialize(UtilityController.getPicklistValues('Account','Company_Type__c'));
        msmeValues = JSON.serialize(UtilityController.getPicklistValues('Account','MSME__c'));
        focusAreas = JSON.serialize(UtilityController.getPicklistValues('Account','Focus_Areas__c'));
        ProductInterest = JSON.serialize(UtilityController.getPicklistValues('Account','Product_of_Interest__c'));
        BankAccType = JSON.serialize(UtilityController.getPicklistValues('Account','Bank_Account_Type__c'));
    }

    public class accountWrapper{
        public Account acc { get; set; }
        public String str { get; set; }
    }
    @RemoteAction
    public static accountWrapper checkAccount(String phoneNumber) {
        accountWrapper wrp = new accountWrapper();
        try{
            List<Account> accountrec = New List<Account>();
            if(phoneNumber != ''){
                accountrec = [SELECT Id, Phone, Team_Member__c, RecordTypeId, Approval_Status__c FROM Account WHERE Phone =: phoneNumber LIMIT 1];
                System.debug('accountrec==>' + accountrec);
                if(accountrec.isEmpty()){
                    wrp.acc = null;
                    wrp.str = 'No Account found';
                    return wrp;
                }
                if(accountrec[0].RecordTypeId != channelPartnerRecTypeId){
                    wrp.acc = null;
                    wrp.str = 'Not Channel Partner Account';
                    return wrp;
                }
                //if(accountrec[0].RecordTypeId == channelPartnerRecTypeId && accountrec[0].Login_Hash_Code__c == null
                accountrec[0].Login_Hash_Code__c = UtilityController.generateRandomString();
                update accountrec;
                wrp.acc = accountrec[0];
                wrp.str = accountrec[0].Login_Hash_Code__c;
                return wrp;
            }else{
                wrp.acc = null;
                wrp.str = 'Please enter a valid phone number';
                return wrp;
            }
            // return accountrec.isEmpty() ? null : accountrec[0].Login_Hash_Code__c; // Returns Contact Id if contact exists
        }catch(Exception e){
            wrp.acc = null;
            wrp.str = e.getMessage();
            return wrp;
        }
    }

    @RemoteAction
    public static String sendOTP(String phone){
        System.debug('phone---> '+phone);
        if(phone != null){
            try{
                String otp = UtilityController.generateOTP();
                System.debug('otp---> '+otp);
                API_SMSIntegration.sendSMS(null, phone, 'CP Portal', otp);
                return otp;
            }catch(Exception e){
                System.debug('Error Occured: ' + e.getMessage() + ' at Line ' + e.getLineNumber());
                return null;
            }
        }else{
            System.debug('No phone provided.');
            return null;
        }
    }

    // Wrapper Class
    public class ChannelPartnerDataWrapper {
        public List<Lead> leads { get; set; }
        public List<Lead> totalLeads { get; set; }
        public List<Visit__c> totalVisits { get; set; }
        public List<Opportunity> AllOpps { get; set; }
        public List <Project__c> allProject { get; set; }

        public ChannelPartnerDataWrapper() {
            leads = new List<Lead>();
            totalLeads = new List<Lead>();
            totalVisits = new List<Visit__c>();
            AllOpps = new List<Opportunity>();
            allProject = new List<Project__c>();
        }
    }

    @RemoteAction
    public static ChannelPartnerDataWrapper getChannelPartnerData(String channelPartnerId) {
        ChannelPartnerDataWrapper dataWrapper = new ChannelPartnerDataWrapper();

        try {
            // Get total leads
            List<Lead> totalLeads = [SELECT Id, CreatedDate, FirstName, LastName, Company, Phone, LeadSource, Channel_Partner__r.Name, Channel_Partner__c, Status
                                    FROM Lead 
                                    WHERE Channel_Partner__r.Login_Hash_Code__c = :channelPartnerId AND Status != 'New'
                                    ORDER BY CreatedDate DESC];

            // Assign using ternary operator
            dataWrapper.totalLeads = (totalLeads != null && !totalLeads.isEmpty()) ? totalLeads : new List<Lead>();


            // Get leads (non-converted)
            List<Lead> leads = [SELECT Id, LastName, Phone, Company, Status, CreatedDate, Channel_Partner__c, Channel_Partner__r.Name, LeadSource, IsConverted, Project__c, Project__r.Name
                                FROM Lead 
                                WHERE Channel_Partner__r.Login_Hash_Code__c = :channelPartnerId
                                ORDER BY CreatedDate DESC];

            // Assign using ternary operator
            dataWrapper.leads = (leads != null && !leads.isEmpty()) ? leads : new List<Lead>();


            // Get total visits
            List<Visit__c> visits = [SELECT Id, Name, Channel_Partner__r.Name, Company_Name__c, Project_Name__c, Channel_Partner__c , Opportunity__c
                                    FROM Visit__c 
                                    WHERE Opportunity__r.Channel_Partner__r.Login_Hash_Code__c = :channelPartnerId
                                    ORDER BY CreatedDate DESC];

            // Assign using ternary operator
            dataWrapper.totalVisits = (visits != null && !visits.isEmpty()) ? visits : new List<Visit__c>();


            // Get opportunities
            List<Opportunity> opportunities = [SELECT Id, Name, StageName, Channel_Partner__r.Name, Project__r.Name, Channel_Partner__r.Login_Hash_Code__c, Channel_Partner__c 
                                                FROM Opportunity 
                                                WHERE Channel_Partner__r.Login_Hash_Code__c = :channelPartnerId
                                                AND StageName NOT IN ('SV Done', 'Cost Sheet Generated', 'Cost Sheet Approved', 'Under Booking Process', 'Under Approval')
                                                ORDER BY CreatedDate DESC];

            // Assign using ternary operator
            dataWrapper.AllOpps = (opportunities != null && !opportunities.isEmpty()) ? opportunities : new List<Opportunity>();

            List<Project__c> projects = [SELECT Id, Name FROM Project__c];
            dataWrapper.allProject = (projects != null && !projects.isEmpty()) ? projects : new List<Project__c>();

        } catch (Exception e) {
            System.debug('Error Occured: ' + e.getMessage() + ' at Line ' + e.getLineNumber());
        }

        System.debug('data found :' +dataWrapper);

        return dataWrapper;
    }

    @RemoteAction
    public static String CreateLeadForChannelPartnerLeadPage(Lead lead, String channelPartnerId){
        if(channelPartnerId != null || channelPartnerId != ''){
            try{
                Account accRecord = [Select Id,Login_Hash_Code__c From Account WHERE Login_Hash_Code__c =: channelPartnerId LIMIT 1];
                lead.Channel_Partner__c = accRecord.Id;
                lead.Company = lead.LastName;
                List<String> phones = new List<String>();
                List<String> emails = new List<String>();
                Map<String,Lead> leadByEmailMap = new Map<String,Lead>();
                Map<String,Lead> leadByPhoneMap = new Map<String,Lead>();
                
                
               
                if(lead.Phone != null){
                    phones.add(lead.Phone);
                }
                if(lead.Email != null){
                    emails.add(lead.Email);
                }
                // if(lead.Alternate_Phone__c != null){
                //     phones.add(lead.Alternate_Phone__c);
                // }
                // if(lead.Alternate_Email__c != null){
                //     emails.add(lead.Alternate_Email__c);
                // }
                if(lead.Phone != null && !leadByPhoneMap.containsKey(lead.Phone)){
                    leadByPhoneMap.put(lead.Phone, lead);
                }
                if(lead.Email != null && !leadByEmailMap.containsKey(lead.Email)){
                    leadByEmailMap.put(lead.Email, lead);
                }
                // if(lead.Alternate_Phone__c != null && !leadByPhoneMap.containsKey(lead.Alternate_Phone__c)){
                //     leadByPhoneMap.put(lead.Alternate_Phone__c, lead);
                // }
                // if(lead.Alternate_Email__c != null && !leadByEmailMap.containsKey(lead.Alternate_Email__c)){
                //     leadByEmailMap.put(lead.Alternate_Email__c, lead);
                // }
                
                system.debug('leadByEmailMap ===> ' + leadByEmailMap);
            	system.debug('leadByPhoneMap ===> ' + leadByPhoneMap);
                 List<Lead> duplicateLeads = new List<Lead>();
            	List<Lead> leadstoUpdate = new List<Lead>();
                
                duplicateLeads = [SELECT Id, Email, Phone, Lead_Type__c,Alternate_Email__c,Alternate_Phone__c, CreatedDate, Status, isConverted FROM Lead WHERE (Phone IN :phones OR Email IN :emails)  ORDER BY CreatedDate DESC];
                System.debug('Duplicate Leads: ' + duplicateLeads);
                List<Lead> leadsToDelete = new List<Lead>();
                if(!duplicateLeads.isEmpty()){
                for(Lead dupLead : duplicateLeads){
                    System.debug('dupLea==>'+dupLead);
                    System.debug('leadByPhoneMap.containsKey(dupLead.Phone)==>'+leadByPhoneMap.containsKey(dupLead.phone));
                    if(leadByPhoneMap.containsKey(dupLead.Phone)){
                        System.debug('leadByPhoneMap.get(dupLead.Phone).Lead_Type__c==>'+leadByPhoneMap.get(dupLead.Phone).Lead_Type__c);
                    }
                    if(dupLead.Lead_Type__c == 'Direct' &&
                       ((dupLead.Phone != null && leadByPhoneMap.containsKey(dupLead.Phone) && leadByPhoneMap.get(dupLead.Phone).Lead_Type__c == 'Direct' && dupLead.Lead_Type__c == 'Direct' ) ||
                        (dupLead.Email != null && leadByEmailMap.containsKey(dupLead.Email) && leadByEmailMap.get(dupLead.Email).Lead_Type__c == 'Direct' && dupLead.Lead_Type__c == 'Direct'))){
                            system.debug('first condition');
                            system.debug('dupLead ===> ' + dupLead);
                            dupLead.Status = 'Re-Enquiry';
                            leadstoUpdate.add(dupLead);
                            
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
                        }
                        if(dupLead.Email != null && leadByEmailMap.containsKey(dupLead.Email)){
                            return 'Duplicate Lead created within 60 days found with same Email.';
                        } 
                        // if(dupLead.Alternate_Phone__c != null && leadByPhoneMap.containsKey(dupLead.Alternate_Phone__c)){
                        //     return 'Duplicate Lead created within 60 days found with same Phone Number.';
                        // }
                        // if(dupLead.Alternate_Email__c != null && leadByEmailMap.containsKey(dupLead.Alternate_Email__c)){
                        //     return 'Duplicate Lead created within 60 days found with same Email.';
                        // }
                    }else{
                        system.debug('else default condition');
                    }
                }
            }
             if(!leadstoUpdate.isEmpty()){
                System.debug('leadstoUpdate: ' + leadstoUpdate);
                update leadstoUpdate;
            }
                lead.Lead_Type__c = 'Channel Partner';
                lead.External_Lead__c = true;
                insert lead;
                return 'SUCCESS';
            }catch (Exception e) {
                System.debug('Error creating lead: ' + e.getMessage());
                return e.getMessage();
            }
        }
        return 'channelPartnerId not found';
    }

    @RemoteAction
    public static Terms_Conditions__c getTerms() {
        try {
            Terms_Conditions__c terms = [SELECT Id, Description__c FROM Terms_Conditions__c LIMIT 1];
            return terms;
        } catch (Exception e) {
            System.debug('Error at line: ' + e.getLineNumber());
            System.debug('Error message: ' + e.getMessage());
            return null;
        }
    }

    // @RemoteAction
    // public static List<Project__c> getAllProjects(){
    //     List<Project__c> allProjects = new List<Project__c>();
    //     try{
    //         allProjects = [SELECT Id, Name, Project_Address__c, Project_Description__c, Project_Type__c, Project_Status__c FROM Project__c];
    //     }catch(Exception e){
    //         System.debug('Error Occured: '+e.getMessage()+ ' at Line '+e.getLineNumber());
    //     }
    //     return allProjects;
    // }

    // @RemoteAction
    // public static Project__c getProjectDetails(String projectId){
    //     Project__c project = new Project__c();
    //     try{
    //         project = [SELECT Id, Name, Project_Address__c, Project_Description__c, Project_Type__c, Project_Status__c, Area__c, Booking_Amount__c, Total_Amount__c, Unit_Type__c FROM Project__c WHERE Id =: projectId LIMIT 1];
    //     }catch(Exception e){
    //         System.debug('Error Occured: '+e.getMessage()+ ' at Line '+e.getLineNumber());
    //     }
    //     return project;
    // }
    public class TeamsWrapper{
        public List<Account> accList = new List<Account>();
        public String maxCount;
    }
    @RemoteAction
    public static TeamsWrapper getTeamMembers(String teamMemberId){
        TeamsWrapper wrapper = new TeamsWrapper();
        List<Account> accountList = new List<Account>();
        String maxTeamMemberCount = '';
        if(teamMemberId != null && teamMemberId != ''){
            try{
                accountList = [SELECT Id, Name, Phone, Team_Member__c, Email__c, Role__c, Department__c, Profile_Pic_Attachment_Id__c  FROM Account WHERE Team_Member__r.Login_Hash_Code__c =: teamMemberId];
                maxTeamMemberCount = System.label.Max_Team_Member_Count;
            }catch(Exception e){
                System.debug('Error Occured: '+e.getMessage()+ ' at Line '+e.getLineNumber());
            }
        }
        wrapper.accList = accountList;
        wrapper.maxCount = maxTeamMemberCount;
        return wrapper;
    }

    @RemoteAction
    public static List<Lead> getRelatedLeads(String channelPartnerId){
        List<Lead> leadList = new List<Lead>();
        try{
            leadList = [SELECT Id, LastName, Phone, Email, isConverted, Channel_Partner__c, Status FROM Lead WHERE isConverted = false AND Channel_Partner__c =: channelPartnerId];
        }catch(Exception e){
            System.debug('Error Occured: '+e.getMessage()+ ' at Line '+e.getLineNumber());
        }
        return leadList;
    }

    @RemoteAction
    public static Brokerage_Calculator__c getBrokerageDetails(){
        Brokerage_Calculator__c broker = new Brokerage_Calculator__c();
        try{
            broker = [SELECT Id, Commission_Rate__c, GST__c, TDS__c FROM Brokerage_Calculator__c LIMIT 1];
        }catch(Exception e){
            System.debug('Error Occured: '+e.getMessage()+ ' at Line '+e.getLineNumber());
        }
        return broker;
    }

    @RemoteAction
    public static String CreateChannelPartnerForChannelPartnerTeamPage(Account acc,  String channelPartnerId){
        if(channelPartnerId != null || channelPartnerId != ''){
            try{
                Account accRecord = [Select Id,Login_Hash_Code__c From Account WHERE Login_Hash_Code__c =: channelPartnerId LIMIT 1];
                acc.Team_Member__c = accRecord.Id;
                acc.RecordTypeId = channelPartnerRecTypeId;
                insert acc;
                //uncommented by me 
                EmailTemplate et = [SELECT Id, HtmlValue, Subject FROM EmailTemplate WHERE DeveloperName = 'Channel_Partner_account_creation_Email_Template'];
                Id orgWideEmailAddressId = [SELECT Id FROM OrgWideEmailAddress ].Id;
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                String htmlBody = et.HtmlValue
                                .replace('{!Account.Name}', + acc.Name);
                mail.setOrgWideEmailAddressId(orgWideEmailAddressId);
                mail.setSubject(et.Subject);
                mail.setToAddresses(new String[]{acc.Email__c});
                mail.setHtmlBody(htmlBody);
                mail.setTemplateId(et.Id);
                mail.setWhatId(acc.Id);
                mail.setSaveAsActivity(false);
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
                return acc.Id;
            }catch (Exception e) {
                System.debug('Error creating account: ' + e.getMessage());
                return e.getMessage();
            }
        }
        return 'channelPartnerId not found';
    }

    @RemoteAction
    public static Account getUserDetails(string hashCode){
        try{
            Account accRecord = New Account();
            if(hashCode != null){
                accRecord = [Select Id, Team_Member__c, Name, Email__c, Phone, Department__c, Login_Hash_Code__c, Profile_Pic_Attachment_Id__c From Account WHERE Login_Hash_Code__c =: hashCode];
            }
            return accRecord;
        }catch(Exception e){
            return null;
        }
    }

    @RemoteAction
    public static List<Case> fetchCases(String hashCode){
        System.debug('Login Hash Code ---> '+hashCode);
        List<Case> caseList = new List<Case>();
        if(hashCode != null){
            Account acc = [SELECT Id, Login_Hash_Code__c FROM Account WHERE Login_Hash_Code__c =: hashCode];
            if(acc != null){
                caseList = [SELECT Id, Subject, SuppliedEmail, SuppliedPhone, Type, Description FROM Case WHERE AccountId =: acc.Id];
            }
        }
        return caseList;
    }

    @RemoteAction
    public static String createCase(Case cs, String channelPartnerId){
        System.debug('channelPartnerId: ' + channelPartnerId);
        if(cs != null && channelPartnerId != null){
            try{
                Account channelPartner = [Select Id, Login_Hash_Code__c From Account WHERE Login_Hash_Code__c =: channelPartnerId AND RecordTypeId = :channelPartnerRecTypeId LIMIT 1];
                System.debug('channelPartner: ' + channelPartner);
                cs.AccountId = channelPartner.Id;
                cs.Origin = 'Web';
                cs.Status = 'New';
                insert cs;
                System.debug('Case created successfully');
                return cs.Id;
            }catch (Exception e) {
                return ('Error creating case: ' + e.getMessage());
            }
        }
        else{
            return 'Input  parameters are null';
        }
    }


    @RemoteAction
    public static String doUploadProfilePic(String hashcode, String attachmentBody, String attachmentName, String fileExtention) {
        system.debug('hashcode==>'+hashcode+'attachmentBody==>'+attachmentBody+'attachmentName==>'+attachmentName);
        Account channelPartner = [Select Id, Login_Hash_Code__c, Profile_Pic_Attachment_Id__c From Account WHERE Login_Hash_Code__c =: hashcode LIMIT 1];
        if(channelPartner != null && attachmentBody != null) {
            try{ContentVersion conVer = new ContentVersion();
            conVer.ContentLocation = 'S'; // to use S specify this document is in Salesforce, to use E for external files
            conVer.PathOnClient = '/'+System.now()+attachmentName+'.'+fileExtention;// The files name, extension is very important here which will help the file in preview.
            conVer.Title = attachmentName; // Display name of the files
            conVer.VersionData = EncodingUtil.base64Decode(attachmentBody); // converting your binary string to Blob
            conVer.isMajorVersion = false;
            conVer.SharingPrivacy = 'P';
            conVer.FirstPublishLocationId = getContentWorkspace();//getOwnerIdOfRecord(userDocId);
            System.debug('--- FirstPublishLocationId '+ conVer.FirstPublishLocationId);
            insert conVer;    //Insert ContentVersion
            
            ContentDistribution cdl = new ContentDistribution();
            cdl.ContentVersionId = conVer.Id;
            cdl.Name = 'PublicShare';
            cdl.RelatedRecordId = channelPartner.Id;
            cdl.PreferencesAllowViewInBrowser = true;
            cdl.PreferencesLinkLatestVersion = true;
            cdl.PreferencesAllowOriginalDownload = true;
            
            insert cdl;
            system.debug('ContentDistribution----'+cdl);
            // First get the Content Document Id from ContentVersion Object
            Id conDoc = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:conVer.Id].ContentDocumentId;
            //create ContentDocumentLink  record 
            ContentDocumentLink conDocLink = New ContentDocumentLink();
            conDocLink.LinkedEntityId = channelPartner.Id; // Specify RECORD ID here i.e Any Object ID (Standard Object/Custom Object)
            conDocLink.ContentDocumentId = conDoc;  //ContentDocumentId Id from ContentVersion
            conDocLink.shareType = 'V';
            insert conDocLink;
            
            update new Account(Id = channelPartner.Id,Profile_Pic_Attachment_Id__c = conVer.Id );
            return conVer.Id; }
            catch(Exception e){
                return ('Error creating case: ' + e.getMessage());
            }
        }
        return null;
    }

    @RemoteAction
    public static String doUploadTeamMemberProfilePic(String accId, String attachmentBody, String attachmentName, String fileExtention) {
        system.debug('accId==>'+accId+'attachmentBody==>'+attachmentBody+'attachmentName==>'+attachmentName);
        Account channelPartner = [Select Id, Login_Hash_Code__c, Profile_Pic_Attachment_Id__c From Account WHERE Id =: accId LIMIT 1];
        if(channelPartner != null && attachmentBody != null) {
            try{ContentVersion conVer = new ContentVersion();
            conVer.ContentLocation = 'S'; // to use S specify this document is in Salesforce, to use E for external files
            conVer.PathOnClient = '/'+System.now()+attachmentName+'.'+fileExtention;// The files name, extension is very important here which will help the file in preview.
            conVer.Title = attachmentName; // Display name of the files
            conVer.VersionData = EncodingUtil.base64Decode(attachmentBody); // converting your binary string to Blog
            conVer.isMajorVersion = false;
            conVer.SharingPrivacy = 'P';
            conVer.FirstPublishLocationId = getContentWorkspace();//getOwnerIdOfRecord(userDocId);
            System.debug('--- FirstPublishLocationId '+ conVer.FirstPublishLocationId);
            insert conVer;    //Insert ContentVersion
            
            ContentDistribution cdl = new ContentDistribution();
            cdl.ContentVersionId = conVer.Id;
            cdl.Name = 'PublicShare';
            cdl.RelatedRecordId = channelPartner.Id;
            cdl.PreferencesAllowViewInBrowser = true;
            cdl.PreferencesLinkLatestVersion = true;
            cdl.PreferencesAllowOriginalDownload = true;
            
            insert cdl;
            system.debug('ContentDistribution----'+cdl);
            // First get the Content Document Id from ContentVersion Object
            Id conDoc = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:conVer.Id].ContentDocumentId;
            //create ContentDocumentLink  record 
            ContentDocumentLink conDocLink = New ContentDocumentLink();
            conDocLink.LinkedEntityId = channelPartner.Id; // Specify RECORD ID here i.e Any Object ID (Standard Object/Custom Object)
            conDocLink.ContentDocumentId = conDoc;  //ContentDocumentId Id from ContentVersion
            conDocLink.shareType = 'V';
            insert conDocLink;
            
            update new Account(Id = channelPartner.Id,Profile_Pic_Attachment_Id__c = conVer.Id );
            return 'Success'; }
            catch(Exception e){
                return ('Error creating case: ' + e.getMessage());
            }
        }
        return null;
    }

    public static Id getContentWorkspace() {
        try {
            return [SELECT Id FROM ContentWorkSpace WHERE Name = 'Ondonte Files'].Id;
        }catch(Exception e) {
            System.debug('--- error message'+e.getMessage());
            return null;
        }
    }

    // @RemoteAction
    // public static String getImageContentDocuments() {
    //     // Query to fetch ContentDocuments linked to the given record ID and are images
    //     // ContentDocumentLink link = [
    //     //     SELECT ContentDocument.Title, ContentDocument.CreatedDate,ContentDocument.Id, ContentDocument.LatestPublishedVersionId FROM ContentDocumentLink where parentId = 'a01Im000000ssH8IAI'
    //     // ];
    //     Attachment link = [
    //             SELECT Id FROM Attachment WHERE parentId = 'a01Im000000ssH8IAI'
    //         ];
    //     // Construct URLs for the images
    //     String imageUrl = '/servlet/servlet.FileDownload?file=' + link.Id;
    //     return imageUrl;
    // }

    // public class ProjectWrapper {
    //     public Project__c project;
    //     public List<String> imageIds;
    // }

//     @RemoteAction
// public static List<ProjectWrapper> getAllProjectsWithImages() {
//     List<ProjectWrapper> projectsWithImages = new List<ProjectWrapper>();
//     try {
//         // Fetch all Projects
//         List<Project__c> projects  = [SELECT Id, Name, Project_Address__c, Project_Description__c, Project_Type__c, Project_Status__c, Area__c, Booking_Amount__c, Total_Amount__c, Unit_Type__c FROM Project__c];
        
//         // Check if there are any projects
//         if (!projects.isEmpty()) {
//             // Fetch all Sub-Documents associated with these Projects
//             List<Sub_Document__c> links = [SELECT Id, File_URL__c, Project__c FROM Sub_Document__c WHERE Project__c IN :projects];
            
//             // Map to store project Ids and their associated image URLs
//             Map<Id, List<String>> projectImagesMap = new Map<Id, List<String>>();
            
//             // If there are any links (Sub-Documents), process them
//             if (!links.isEmpty()) {
//                 for (Sub_Document__c docLink : links) {
//                     // Initialize the list of image URLs for each project
//                     if (!projectImagesMap.containsKey(docLink.Project__c)) {
//                         projectImagesMap.put(docLink.Project__c, new List<String>());
//                     }
//                     // Add the file URL (Image URL) to the list
//                     projectImagesMap.get(docLink.Project__c).add(docLink.File_URL__c);
//                 }
                
//                 // Wrap Project and Image URLs
//                 for (Project__c project : projects) {
//                     ProjectWrapper wrapper = new ProjectWrapper();
//                     wrapper.project = project;
//                     wrapper.imageIds = projectImagesMap.get(project.Id) != null ? projectImagesMap.get(project.Id) : new List<String>();
//                     projectsWithImages.add(wrapper);
//                 }
//             }
//         }
//     } catch (Exception e) {
//         System.debug('Error Occurred: ' + e.getMessage() + ' at Line ' + e.getLineNumber());
//     }
//     System.debug('image urls'+projectsWithImages);
//     return projectsWithImages;
// }

@RemoteAction
public static List<Project__c> getAllProjectsWithImages(){
    List<Project__c> projects = new List<Project__c>();
    try{
        projects  = [SELECT Id, Name, Project_Address__c, Project_Description__c, Project_Type__c, Project_Status__c, Area__c, Booking_Amount__c, Total_Amount__c, Unit_Type__c, (SELECT Id, Name, File_URL__c FROM Sub_Documents__r), (SELECT Id, Name, Icon_Name__c FROM Amenities__r ORDER BY CreatedDate DESC) FROM Project__c];
    }catch(Exception e){
        System.debug('Error Occured: '+e.getMessage()+ ' at Line '+e.getLineNumber());
    }
    System.debug('Project with Sub doc'+projects);
    return projects;
}


    //eventUploadPdf
    @AuraEnabled
    public static void uploadPdfToEvent(Id eventId, String fileName, String base64Data) {
        try {
            // Fetch the Event__c record
            Event__c eventRecord = [SELECT Id, File_Id__c FROM Event__c WHERE Id = :eventId LIMIT 1];
            
            if (eventRecord != null) {
                // Insert the attachment for the event
                Attachment attachment = new Attachment();
                attachment.ParentId = eventId; // The Event__c record Id
                attachment.Name = fileName;
                attachment.Body = EncodingUtil.base64Decode(base64Data);
                insert attachment;
                
                // Update the File_Id__c field on the Event__c record
                eventRecord.File_Id__c = attachment.Id;
                update eventRecord;
            } else {
                throw new AuraHandledException('Event record not found for the specified ID.');
            }
        } catch (DmlException e) {
            throw new AuraHandledException('Error uploading file: ' + e.getMessage());
        } catch (Exception e) {
            throw new AuraHandledException('Error uploading file: ' + e.getMessage());
        }
    }

    @RemoteAction
    public static String uploadAttachment(String recordId, String fileName, String base64Data) {
        System.debug('recordId ===> ' + recordId);
        System.debug('fileName ===> ' + fileName);
        System.debug('base64Data ===> ' + base64Data);
        if(recordId != null || recordId != ''){
            try{
                Attachment attachment = new Attachment();
                attachment.ParentId = recordId; // The SObject record Id
                attachment.Name = fileName;
                attachment.Body = EncodingUtil.base64Decode(base64Data);
                insert attachment;
                return 'Success';
            }catch(Exception e){
                System.debug('Error while uploading attachment ---> ' + e.getMessage() + ' at Line ---> ' + e.getLineNumber());
                return 'Error';
            }
        }
        return 'No record Id found';
    }

    @AuraEnabled(cacheable=true)
    public static Event__c getEventDetails(Id eventId) {
        return [SELECT Id, File_Id__c FROM Event__c WHERE Id = :eventId LIMIT 1];
    }

    //eventUploadImage
    @AuraEnabled
    public static void uploadImageToEvent(Id eventId, String fileName, String base64Data) {
        try {
            Event__c eventRecord = [SELECT Id, Image_Id__c FROM Event__c WHERE Id = :eventId LIMIT 1];
            
            if (eventRecord != null) {
                // Insert the image as an attachment
                Attachment attachment = new Attachment();
                attachment.ParentId = eventId;
                attachment.Name = fileName;
                attachment.Body = EncodingUtil.base64Decode(base64Data);
                insert attachment;

                // Update the Image_Id__c field on the Event__c record
                eventRecord.Image_Id__c = attachment.Id;
                update eventRecord;
            } else {
                throw new AuraHandledException('Event record not found for the specified ID.');
            }
        } catch (DmlException e) {
            throw new AuraHandledException('Error uploading image: ' + e.getMessage());
        }
    }

    @RemoteAction
    public static List<Event__c> getEventDetailsForSite() {
        try {
            List<Event__c> eventList = [SELECT Id, Image_Id__c,File_Id__c,Name__c,Name,Event_Date_Time__c,Event_Venue__c, (SELECT Id, Name, File_URL__c FROM Sub_Documents__r ORDER BY CreatedDate) FROM Event__c];
            if(!eventList.isEmpty()){
                return eventList;
            }
            return null;
        } catch (Exception e) {
            System.debug(' Error in fetching events ===> ' + e.getMessage() + ' Line No: ' + e.getLineNumber());
            return null;
        }
    }

    @RemoteAction
    public static Account updateProfile(Account acc){
        try{
            update acc;
            return acc;
        }catch(Exception e){
            System.debug('Error Occured: '+e.getMessage()+ ' at Line '+e.getLineNumber());
            return null;
        }
    }

    @RemoteAction
    public static List<Marketing__c> getAllMarketingRecords(){
        // marketingDetails wrapper = new marketingDetails();
        List<Marketing__c> allMarketings = new List<Marketing__c>();
        // Map<String, List<String>> marketingIdXfileId = new Map<String, List<String>>();
        try{
            allMarketings = [SELECT Id, Name__c, Marketing_URL__c, Asset_Type__c, (SELECT Id, File_URL__c FROM Sub_Documents__r ORDER BY CreatedDate DESC LIMIT 1) FROM Marketing__c];
            
        }catch(Exception e){
            System.debug('Error Occured: '+e.getMessage()+ ' at Line: '+e.getLineNumber());
        }
        return allMarketings;
    }

    @RemoteAction 
    public static String logoutUser(String loginHashCode) {
        // Invalidate the session to log out the user
        try{
            // ApexPages.currentPage().getHeaders().put('Location', '/apex/ProductPage');
            // ApexPages.currentPage().getHeaders().put('Location', '/secur/logout.jsp');
            // ApexPages.currentPage().setRedirect(true);
            List<Account> acc = new List<Account>();
            if(loginHashCode!=null){
                acc = [SELECT Id, Login_Hash_Code__c FROM Account WHERE Login_Hash_Code__c = :loginHashCode LIMIT 1];
            }
            if(!acc.isEmpty()){
                acc[0].Login_Hash_Code__c = '';
                update acc;
                return 'Success';
            }
            return 'Error';
        }catch(Exception e){
            System.debug('Error Occured: '+e.getMessage()+ ' at Line '+e.getLineNumber());
            return 'Error message: '+e.getMessage()+' at Line '+e.getLineNumber();
        }
    }

    @RemoteAction
    public static String submitApproval(String accId){
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        // req.setComments('Submitting new Account record for approval.');
        req.setObjectId(accId);
        String submitter = System.label.Guest_User_approval_submitter; // Id of the user that will fire the approval on behalf of the guest user. 
        req.setProcessDefinitionNameOrId('Account_Approval_Process');
        req.setSubmitterId(submitter);
        Approval.ProcessResult result = Approval.process(req);
        if (result.isSuccess()) {
            System.debug('Approval request submitted successfully.');
            return 'Approval request submitted successfully for Account ID: ' + accId;
        } else {
            System.debug('Approval request submission failed.');
            return 'Approval request submission failed for Account ID: ' + accId;
        }
    }

    @RemoteAction
    public static String submitAcc(Account acc){
        try{
            if(acc != null){
                acc.RecordTypeId = channelPartnerRecTypeId;
                insert acc;
                return acc.Id;
            }else{
                return 'Account data not available to insert.';
            }
        }catch(Exception e){
            return e.getMessage();
        }
    }

    public class wrapperForResponse{
        public Boolean is308Response{get;set;}
        public String locationValue{get;set;}
        public String rangeValue{get;set;}
        public String subDocUrl{get;set;}
    }

    @RemoteAction
    public static wrapperForResponse uploadDocuments(String accId, String fileName, String fileData, String totalFileSize, String documentName, String fileType){
        try{
            System.debug('totalFileSize ===> ' + totalFileSize);
            if(fileData != null && accId != null && totalFileSize != null){
                Blob blobData = EncodingUtil.base64Decode(fileData);
                Integer totalFileSizeBlob = blobData.size();
                String contentRange = 'bytes 0-' + (totalFileSizeBlob-1) + '/' + (totalFileSizeBlob);
                System.debug('contentRange ===> ' + contentRange);
                List<Document__c> docList = [SELECT Id,Name,Document_Id__c,Account__c,Account__r.Document_Id__c from Document__c where Name =: documentName AND Account__c =: accId LIMIT 1];
                if(!docList.isEmpty()){
                    // GoogleDriveAPI.wrapperForResponse result = GoogleDriveAPI.uploadFileToGoogleDrive(fileName,'application/pdf',docList[0].Document_Id__c,fileData,contentRange,docList[0].Id);
                    try{
                        // String fileType = 'application/pdf';
                        String folderId = docList[0].Document_Id__c;
                        String docId = docList[0].Id;
                        system.debug('fileName ===> ' + fileName);
                        system.debug('fileType ===> ' + fileType);
                        system.debug('folderId ===> ' + folderId);
                        System.debug('fileData length ===> ' + fileData.length());
                        String locationValue = '';
                        String subDocUrl = '';
                        
                        if(fileName != null && fileData != null){
                            List<String> folderList = (folderId != null || folderId != '') ? new List<String>{folderId} : new List<String>();
                            system.debug('folderList ===> ' + folderList);
                            Map<String,Object> jsonData = new Map<String,Object>();
                            jsonData.put('name',fileName);
                            jsonData.put('mimeType',fileType);
                            if(!folderList.isEmpty()){
                                jsonData.put('parents', folderList);
                            }
                            String jsonString = JSON.serialize(jsonData);
                            System.debug('jsonString length ===> ' + jsonString.length());
                            Integer jsonStringLength = jsonString.length();
                            
                            String accessToken = GoogleDriveAPI.getAccessToken();
                            String endpoint = 'https://www.googleapis.com/upload/drive/v3/files?uploadType=resumable';
                            
                            Http http = new Http();
                            
                            if(accessToken != null){
                                HttpRequest req = new HttpRequest();
                                req.setMethod('POST');
                                req.setEndpoint(endpoint);
                                req.setHeader('Authorization', 'Bearer ' + accessToken);
                                req.setHeader('Content-Type', 'application/json; charset=UTF-8');
                                req.setHeader('Content-Length', String.valueOf(jsonStringLength));
                                req.setBody(jsonString);
                                
                                HttpResponse res = http.send(req);
                                locationValue = res.getHeader('Location') != null ? res.getHeader('Location') : null;
                                System.debug('location ===> ' + locationValue);
                                system.debug('contentRange ==> ' + contentRange);
                                
                                if(locationValue != null){
                                    Blob fileBlob = EncodingUtil.base64Decode(fileData);
                                    system.debug('fileBlob ===> ' + fileBlob);
                                    Integer fileDataStringLength = fileBlob.size();
                                    system.debug('fileDataStringLength ===> ' + fileDataStringLength);
                                    HttpRequest request = new HttpRequest();
                                    request.setMethod('PUT');
                                    request.setEndpoint(locationValue);
                                    request.setHeader('Content-Type', 'application/pdf');
                                    request.setHeader('Content-Length', String.valueOf(fileDataStringLength));
                                    request.setHeader('Content-Range', contentRange);
                                    //request.setBody(fileData);
                                    request.setBodyAsBlob(fileBlob);
                                    
                                    system.debug('request ==> ' + request);
                                    
                                    HttpResponse response = http.send(request);
                                    System.debug('response ===> '+ response);
                                    System.debug('response code ===> '+ response.getBody());
                                    
                                    String range = response.getHeader('Range') != null ? response.getHeader('Range') : null;
                                    System.debug('range ===> ' + range);
                                    Boolean is308Response = response.getStatusCode() == 308 ? true: false;
                                    
                                    if(response.getStatusCode() == 200 || response.getStatusCode() == 201){
                                        Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                                        System.debug('responseBody ===> ' + responseBody);
                                        if(responseBody != null){
                                            String fileId = responseBody.get('id') != null ? (String) responseBody.get('id') : null;
                                            System.debug('fileId ===> ' + fileId);
                                            String fileUrl = 'https://drive.google.com/file/d/' + fileId + '/preview?usp=drivesdk';
                                            Sub_Document__c file = new Sub_Document__c();
                                            file.Name        = fileName;
                                            file.File_URL__c = fileUrl;
                                            file.Document__c = docId;
                                            insert file;
                                            System.debug('file ===> ' + file);
                                            subDocUrl = file.File_URL__c;
                                        }
                                    }
                                    
                                    wrapperForResponse wrp = new wrapperForResponse();
                                    wrp.locationValue = locationValue;
                                    wrp.is308Response = is308Response;
                                    wrp.rangeValue = range;
                                    wrp.subDocUrl = subDocUrl;
                                    system.debug('wrp ===> ' + wrp);
                                    
                                    return wrp;
                                }
                            }
                        }
                        return null;
                    }catch(Exception e){
                        system.debug('Error ==> ' + e.getMessage());
                        system.debug('Error in line ==> ' + e.getLineNumber());
                        return null;
                    }
                }
            }
            return null;
        }catch(Exception e){
            system.debug('Error ==> ' + e.getMessage());
            system.debug('Error in line ==> ' + e.getLineNumber());
            return null;
        }
    }

    public class cpData {
        public String Name { get; set; }
        public String Project { get; set; }
        public String Company { get; set; }
    }
    public class InvoicesWrapper {
        public List<Channel_Partner_Invoice__c> AllInvoices { get; set; }
        public List<Channel_Partner_Invoice__c> ApprovedInvoices { get; set; }
        // public List<AggregateResult> siteVisit { get; set; }
        // public List<AggregateResult> oppAmountList { get; set; }
        // public List<AggregateResult> unitSoldList { get; set; }
        // public Map<Id, Integer> opportunityCounts { get; set; }
        // public Map<Id, Decimal> opportunityAmounts { get; set; }
        // public Map<Id, Integer> visitCounts { get; set; }
        // public Map<Id, cpData> cpDataMap { get; set; }
    }
    @RemoteAction
    public Static InvoicesWrapper getInvoices(Boolean teamHead, String hashCode) {
        InvoicesWrapper wrapper = new InvoicesWrapper();
        // Map<Id, cpData> cpDataMap = new Map<Id, cpData>();
        try{


            // FOR ALL COUNTS OF OPPORTUNITIES
            // Query 1: Direct Relationship
            // List<AggregateResult> directOppCounts = [
            //     SELECT Channel_Partner__c, COUNT(Id) 
            //     FROM Opportunity 
            //     WHERE Channel_Partner__c != null 
            //     GROUP BY Channel_Partner__c
            // ];
            // // Query 2: Indirect Relationship via Channel Partner
            // List<AggregateResult> indirectOppCounts = [
            //     SELECT Channel_Partner__r.Team_Member__c, COUNT(Id) 
            //     FROM Opportunity 
            //     WHERE Channel_Partner__c != null AND Channel_Partner__r.Team_Member__c != null 
            //     GROUP BY Channel_Partner__r.Team_Member__c
            // ];
            // System.debug('indirectOppCounts==>' +indirectOppCounts);
            // // Combine results
            // Map<Id, Integer> opportunityCounts = new Map<Id, Integer>();
            // // Process direct counts
            // for (AggregateResult result : directOppCounts) {
            //     Id cpId = (Id) result.get('Channel_Partner__c');
            //     Integer count = (Integer) result.get('expr0');
            //     opportunityCounts.put(cpId, count);
            // }
            // // Process indirect counts
            // for (AggregateResult result : indirectOppCounts) {
            //     Id teamMemberId = (Id) result.get('Team_Member__c'); // Channel_Partner__r.Team_Member__c alias
            //     Integer count = (Integer) result.get('expr0');
                
            //     // Add counts to existing value if already in map
            //     if (opportunityCounts.containsKey(teamMemberId)) {
            //         opportunityCounts.put(teamMemberId, opportunityCounts.get(teamMemberId) + count);
            //     } else {
            //         opportunityCounts.put(teamMemberId, count);
            //     }
            // }
            // // Output combined counts
            // for (Id teamMemberId : opportunityCounts.keySet()) {
            //     System.debug('Channel Partner: ' + teamMemberId + ', Total Opportunities: ' + opportunityCounts.get(teamMemberId));
            // }
            // List<Account> opportunityCountCPs = [SELECT Id, Name FROM Account WHERE Id IN :opportunityCounts.keySet()];
            // if(!opportunityCountCPs.isEmpty()){
            //     for(Account acc : opportunityCountCPs){
            //         if(!cpDataMap.containsKey(acc.Id)){
            //             cpData cpInfo = new cpData();
            //             cpInfo.Name = acc.Name;
            //             cpDataMap.put(acc.Id,cpInfo);
            //         }
            //     }
            // }


            // // FOR ALL COUNTS OF VISITS
            // // Query 1: Direct Relationship
            // List<AggregateResult> directVisitCounts = [
            //     SELECT Opportunity__r.Channel_Partner__c, COUNT(Id) 
            //     FROM  Visit__c
            //     WHERE Opportunity__c != null AND Opportunity__r.Channel_Partner__c != null
            //     GROUP BY Opportunity__r.Channel_Partner__c
            // ];
            // System.debug('directVisitCounts==>' +directVisitCounts);
            // // Query 2: Indirect Relationship via Channel Partner
            // List<AggregateResult> indirectVisitCounts = [
            //     SELECT Opportunity__r.Channel_Partner__r.Team_Member__c, COUNT(Id) 
            //     FROM Visit__c 
            //     WHERE Opportunity__c != null AND Opportunity__r.Channel_Partner__c != null AND Opportunity__r.Channel_Partner__r.Team_Member__c != null 
            //     GROUP BY Opportunity__r.Channel_Partner__r.Team_Member__c
            // ];
            // System.debug('indirectVisitCounts==>' +indirectVisitCounts);
            // // Combine results
            // Map<Id, Integer> visitCounts = new Map<Id, Integer>();
            // // Process direct counts
            // for (AggregateResult result : directVisitCounts) {
            //     Id cpId = (Id) result.get('Channel_Partner__c');
            //     Integer count = (Integer) result.get('expr0');
            //     visitCounts.put(cpId, count);
            // }
            // // Process indirect counts
            // for (AggregateResult result : indirectVisitCounts) {
            //     Id teamMemberId = (Id) result.get('Team_Member__c'); // Opportunity__r.Channel_Partner__r.Team_Member__c alias
            //     Integer count = (Integer) result.get('expr0');
                
            //     // Add counts to existing value if already in map
            //     if (visitCounts.containsKey(teamMemberId)) {
            //         visitCounts.put(teamMemberId, visitCounts.get(teamMemberId) + count);
            //     } else {
            //         visitCounts.put(teamMemberId, count);
            //     }
            // }
            // // Output combined counts
            // for (Id teamMemberId : visitCounts.keySet()) {
            //     System.debug('Channel Partner: ' + teamMemberId + ', Total Opportunities: ' + visitCounts.get(teamMemberId));
            // }
            // List<Account> visitCountCPs = [SELECT Id, Name FROM Account WHERE Id IN :visitCounts.keySet()];
            // if(!visitCountCPs.isEmpty()){
            //     for(Account acc : visitCountCPs){
            //         if(!cpDataMap.containsKey(acc.Id)){
            //             cpData cpInfo = new cpData();
            //             cpInfo.Name = acc.Name;
            //             cpDataMap.put(acc.Id,cpInfo);
            //         }
            //     }
            // }


            // // FOR TOTAL SUM OF OUTSTANDING AMOUNT OF OPPORTUNITIES
            // // Query 1: Direct Relationship
            // List<AggregateResult> directCounts = [
            //     SELECT Channel_Partner__c, SUM(Total_Outstanding_Amount__c) 
            //     FROM Opportunity 
            //     WHERE Channel_Partner__c != null 
            //     GROUP BY Channel_Partner__c
            // ];
            // // Query 2: Indirect Relationship via Channel Partner
            // List<AggregateResult> indirectCounts = [
            //     SELECT Channel_Partner__r.Team_Member__c, SUM(Total_Outstanding_Amount__c) 
            //     FROM Opportunity 
            //     WHERE Channel_Partner__c != null AND Channel_Partner__r.Team_Member__c != null 
            //     GROUP BY Channel_Partner__r.Team_Member__c
            // ];
            // System.debug('indirectCounts==>' +indirectCounts);
            // // Combine results
            // Map<Id, Decimal> opportunityAmounts = new Map<Id, Decimal>();
            // // Process direct counts
            // for (AggregateResult result : directCounts) {
            //     Id cpId = (Id) result.get('Channel_Partner__c');
            //     Decimal amount = (Decimal) result.get('expr0'); // Use Decimal instead of Integer
            //     opportunityAmounts.put(cpId, amount);
            // }
            // // Process indirect counts
            // for (AggregateResult result : indirectCounts) {
            //     Id teamMemberId = (Id) result.get('Team_Member__c');
            //     Decimal amount = (Decimal) result.get('expr0'); // Use Decimal instead of Integer
            //     // Add amounts to existing value if already in map
            //     if (opportunityAmounts.containsKey(teamMemberId)) {
            //         opportunityAmounts.put(teamMemberId, opportunityAmounts.get(teamMemberId) + amount);
            //     } else {
            //         opportunityAmounts.put(teamMemberId, amount);
            //     }
            // }
            // // Output combined amounts
            // for (Id key : opportunityAmounts.keySet()) {
            //     System.debug('Channel Partner: ' + key + ', Total Outstanding Amount: ' + opportunityAmounts.get(key));
            // }
            // List<Account> opportunityAmountCP = [SELECT Id FROM Account WHERE Id IN :opportunityAmounts.keySet()];
            // if(!opportunityAmountCP.isEmpty()){
            //     for(Account acc : opportunityAmountCP){
            //         if(!cpDataMap.containsKey(acc.Id)){
            //             cpData cpInfo = new cpData();
            //             cpInfo.Name = acc.Name;
            //             cpDataMap.put(acc.Id,cpInfo);
            //         }
            //     }
            // }


            // Lists to store the records
            List<Channel_Partner_Invoice__c> AllInvoicesRec;
            List<Channel_Partner_Invoice__c> ApprovedInvoicesRec;
            // List<AggregateResult> siteVisit = [SELECT Opportunity__r.Channel_Partner__r.Team_Member__c, COUNT(Id) FROM Visit__c WHERE Opportunity__c != null AND Opportunity__r.Channel_Partner__c != null AND Opportunity__r.Channel_Partner__r.Team_Member__c != null GROUP BY Opportunity__r.Channel_Partner__r.Team_Member__c ORDER BY COUNT(Id) DESC];
            // List<AggregateResult> unitSoldList = [SELECT Channel_Partner__r.Team_Member__c, COUNT(Id) FROM Opportunity WHERE Channel_Partner__c != null AND Channel_Partner__r.Team_Member__c != null GROUP BY Channel_Partner__r.Team_Member__c ORDER BY COUNT(Id) DESC];
            // List<AggregateResult> oppAmountList = [SELECT Channel_Partner__r.Team_Member__c, SUM(Total_Outstanding_Amount__c) FROM Opportunity WHERE Channel_Partner__c != null AND Channel_Partner__r.Team_Member__c != null GROUP BY Channel_Partner__r.Team_Member__c ORDER BY SUM(Total_Outstanding_Amount__c) DESC];
            /* if(teamHead == true){
                System.debug('Inside Team Head: ' + hashCode);
                // Fetch the records
                AllInvoicesRec = [SELECT Id, IsDeleted, Name, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, Opportunity__c, Approval_Status__c, Mode_Of_Payment__c, Receipt_Date__c, Amount__c, Amount_In_Base_Currency__c, Cheque_Date__c, Cheque_Number__c, TDS_Amount__c, CIN__c, Challan_Date__c, BSR_Code__c, Bank__c, Branch__c, Type__c, PAN_TAN_Number__c, Reference_Number__c, AY__c, Maintenance_Receipt__c, JV_Date__c, JV_Reference_Number__c, Remarks__c, Fund_Transfer_Date__c, Bank_Name__c, Transaction_Reference_Number__c, Tax_Type__c, Fin_Tax__c, Paid_Date__c, UPI_Provider__c, Drawn_on_Bank__c, Preview__c, Unit__c, DD_Number__c, DD_Date__c, Opportunity__r.Channel_Partner__r.Name, Opportunity__r.Project__r.Name, Opportunity__r.Account.Name FROM Receipt__c WHERE Opportunity__r.Channel_Partner__r.Team_Member__r.Login_Hash_Code__c =:hashCode OR Opportunity__r.Channel_Partner__r.Login_Hash_Code__c =: hashCode];
                System.debug('All Invoices: ' + AllInvoicesRec);
                ApprovedInvoicesRec = [SELECT Id, IsDeleted, Name, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById , Opportunity__c, Approval_Status__c, Mode_Of_Payment__c, Receipt_Date__c, Amount__c, Amount_In_Base_Currency__c, Cheque_Date__c, Cheque_Number__c, TDS_Amount__c, CIN__c, Challan_Date__c, BSR_Code__c, Bank__c, Branch__c, Type__c, PAN_TAN_Number__c, Reference_Number__c, AY__c, Maintenance_Receipt__c, JV_Date__c, JV_Reference_Number__c, Remarks__c, Fund_Transfer_Date__c, Bank_Name__c, Transaction_Reference_Number__c, Tax_Type__c, Fin_Tax__c, Paid_Date__c, UPI_Provider__c, Drawn_on_Bank__c, Preview__c, Unit__c, DD_Number__c, DD_Date__c, Opportunity__r.Channel_Partner__r.Name, Opportunity__r.Project__r.Name, Opportunity__r.Account.Name FROM Receipt__c WHERE (Opportunity__r.Channel_Partner__r.Team_Member__r.Login_Hash_Code__c =:hashCode OR Opportunity__r.Channel_Partner__r.Login_Hash_Code__c =: hashCode) AND Approval_Status__c = 'Approved'];
                System.debug('Approved Invoices: ' + ApprovedInvoicesRec);
            }
            else{
                AllInvoicesRec = [SELECT Id, IsDeleted, Name, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, Opportunity__c, Approval_Status__c, Mode_Of_Payment__c, Receipt_Date__c, Amount__c, Amount_In_Base_Currency__c, Cheque_Date__c, Cheque_Number__c, TDS_Amount__c, CIN__c, Challan_Date__c, BSR_Code__c, Bank__c, Branch__c, Type__c, PAN_TAN_Number__c, Reference_Number__c, AY__c, Maintenance_Receipt__c, JV_Date__c, JV_Reference_Number__c, Remarks__c, Fund_Transfer_Date__c, Bank_Name__c, Transaction_Reference_Number__c, Tax_Type__c, Fin_Tax__c, Paid_Date__c, UPI_Provider__c, Drawn_on_Bank__c, Preview__c, Unit__c, DD_Number__c, DD_Date__c, Opportunity__r.Channel_Partner__r.Name, Opportunity__r.Project__r.Name, Opportunity__r.Account.Name FROM Receipt__c WHERE Opportunity__r.Channel_Partner__r.Login_Hash_Code__c =:hashCode];
                ApprovedInvoicesRec = [SELECT Id, IsDeleted, Name, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, Opportunity__c, Approval_Status__c, Mode_Of_Payment__c, Receipt_Date__c, Amount__c, Amount_In_Base_Currency__c, Cheque_Date__c, Cheque_Number__c, TDS_Amount__c, CIN__c, Challan_Date__c, BSR_Code__c, Bank__c, Branch__c, Type__c, PAN_TAN_Number__c, Reference_Number__c, AY__c, Maintenance_Receipt__c, JV_Date__c, JV_Reference_Number__c, Remarks__c, Fund_Transfer_Date__c, Bank_Name__c, Transaction_Reference_Number__c, Tax_Type__c, Fin_Tax__c, Paid_Date__c, UPI_Provider__c, Drawn_on_Bank__c, Preview__c, Unit__c, DD_Number__c, DD_Date__c, Opportunity__r.Channel_Partner__r.Name, Opportunity__r.Project__r.Name, Opportunity__r.Account.Name FROM Receipt__c WHERE Opportunity__r.Channel_Partner__r.Login_Hash_Code__c =:hashCode AND Approval_Status__c = 'Approved'];
            } */
            AllInvoicesRec = [SELECT Id, Name, CreatedDate, Approval_Status__c, Channel_Partner__r.Name, Customer__r.Name, Channel_Partner__r.Channel_Partner_Id__c, Agreement_Value__c, Opportunity__r.Name, Project__r.Name, Project__r.Company__r.Name, Brokerage__c, Invoice_value_without_GST__c, GST_Amount__c, GST__c, Invoice_value_with_GST__c, TDS__c, Unit__r.Unit_Name__c FROM Channel_Partner_Invoice__c WHERE Channel_Partner__r.Login_Hash_Code__c = : hashCode ];
            ApprovedInvoicesRec = [SELECT Id, Name, CreatedDate, Approval_Status__c, Channel_Partner__r.Name, Customer__r.Name, Channel_Partner__r.Channel_Partner_Id__c, Agreement_Value__c, Opportunity__r.Name, Project__r.Name, Project__r.Company__r.Name, Brokerage__c, Invoice_value_without_GST__c, GST_Amount__c, GST__c, Invoice_value_with_GST__c, TDS__c, Unit__r.Unit_Name__c FROM Channel_Partner_Invoice__c WHERE Channel_Partner__r.Login_Hash_Code__c = : hashCode AND Approval_Status__c = 'Approved'];
            // Assign the lists to the wrapper
            wrapper.AllInvoices = (AllInvoicesRec.isEmpty()) ? new List<Channel_Partner_Invoice__c>() : AllInvoicesRec;
            wrapper.ApprovedInvoices = (ApprovedInvoicesRec.isEmpty()) ? new List<Channel_Partner_Invoice__c>() : ApprovedInvoicesRec;
            // wrapper.siteVisit = (siteVisit.isEmpty()) ? new List<AggregateResult>() : siteVisit;
            // wrapper.oppAmountList = (oppAmountList.isEmpty()) ? new List<AggregateResult>() : oppAmountList;
            // wrapper.unitSoldList = (unitSoldList.isEmpty()) ? new List<AggregateResult>() : unitSoldList;
            // wrapper.opportunityCounts = (opportunityCounts.isEmpty()) ? new Map<Id,Integer>() : opportunityCounts;
            // wrapper.opportunityAmounts = (opportunityAmounts.isEmpty()) ? new Map<Id,Decimal>() : opportunityAmounts;
            // wrapper.visitCounts = (visitCounts.isEmpty()) ? new Map<Id,Integer>() : visitCounts;
            // wrapper.cpDataMap = (cpDataMap.isEmpty()) ? new Map<Id,cpData>() : cpDataMap;
            // System.debug('All Invoices List ===>' + wrapper.AllInvoices);
            // System.debug('All Approved  Invoices List ===>' + wrapper.ApprovedInvoices);
            // System.debug('Site Visit List ===>' + wrapper.visitCounts);
            // System.debug('Opp Amount List ===>' + wrapper.opportunityAmounts);
            // System.debug('Units Sold List ===>' + wrapper.opportunityCounts);
        }catch(Exception e){
            System.debug('Exception occurred: ' + e.getMessage());
        }
        return wrapper;
    }

    @RemoteAction
    public static List<Channel_Partner_Invoice__c> getMyInvoices(String hashCode){
        System.debug('hashCode => ' + hashCode);//
        List<Channel_Partner_Invoice__c> AllInvoicesRec = new List<Channel_Partner_Invoice__c>();
        try{
            AllInvoicesRec = [SELECT Id, Name, CreatedDate, Approval_Status__c, Channel_Partner__r.Name, Customer__r.Name, Channel_Partner__r.Channel_Partner_Id__c, Agreement_Value__c, Opportunity__r.Name, Project__r.Name, Project__r.Company__r.Name, Brokerage__c, Invoice_value_without_GST__c, GST_Amount__c, GST__c, Invoice_value_with_GST__c, TDS__c, Unit__r.Unit_Name__c FROM Channel_Partner_Invoice__c WHERE Channel_Partner__r.Login_Hash_Code__c = : hashCode ];
        }catch(Exception e){
            System.debug('Exception occurred: ' + e.getMessage());
        }
        return AllInvoicesRec;
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
    public Static ChannelPartnerWrapper FetchVisitOppRecords(Boolean teamHead, String hashCode) {
        ChannelPartnerWrapper wrapper = new ChannelPartnerWrapper();
        try{
            // Lists to store the records
            List<Visit__c> visitRecords;
            List<Opportunity> oppRecords;
            if(teamHead == true){
                System.debug('Inside Team Head: ' + hashCode);
                // Fetch the records
                visitRecords = [SELECT Status__c, Id, OwnerId, IsDeleted, Name, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, SystemModstamp, LastActivityDate, LastViewedDate, LastReferencedDate, Area__c, Budget__c, Construction_Status__c, Employment_Type__c, Purpose_Of_Buying__c, Facilitated_By__c, Walkin_Source__c, Actual_Visit_Date__c, Alternate_Phone__c, Channel_Partner__c, City__c, Company_Name__c, Date_Of_Birth__c, Industry__c, Lead__c, Locality__c, Office_Address__c, Opportunity__c, Pincode__c, Residential_Address__c, Sales_Manager__c, Project_Name__c, Office_PinCode__c,Channel_Partner__r.Name FROM Visit__c WHERE Opportunity__r.Account.Team_Member__r.Login_Hash_Code__c =:hashCode];
                System.debug('visitRecords: ' + visitRecords);
                oppRecords = [SELECT Id, IsDeleted, AccountId, IsPrivate, Name, Description, StageName, Amount, Probability, ExpectedRevenue, TotalOpportunityQuantity, CloseDate, Type, NextStep, LeadSource, IsWon, IsClosed, ForecastCategory, ForecastCategoryName, CampaignId, HasOpportunityLineItem, Pricebook2Id, OwnerId, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, SystemModstamp, LastActivityDate, PushCount, LastStageChangeDate, FiscalQuarter, FiscalYear, Fiscal, ContactId, LastViewedDate, LastReferencedDate, SyncedQuoteId, ContractId, HasOpenActivity, HasOverdueTask, LastAmountChangedHistoryId, LastCloseDateChangedHistoryId, Budget_Confirmed__c, Discovery_Completed__c, ROI_Analysis_Completed__c, Loss_Reason__c, Alternate_Email__c, Alternate_Phone__c, Channel_Partner__c, Email__c, Next_Follow_Up_Date_Time__c, Opportunity_Unique_Id__c, Phone__c, Pre_Sales_Team_Member__c, Project__c, Sales_Team_Member__c, Document_Id__c, Sales_Head_approval_Status__c, Unit__c, CRM_Approval_Status__c, Cost_Sheet_Template__c, Payment_Scheme__c, Agreement_Tax_Amount__c, Agreement_Value__c, Other_Charges__c, Other_Tax_Amount__c, Balance_Total_Due_Amount__c, Balance_Due_Amount_as_per_DL__c, Cost_Sheet_Approval_Status__c, Total_Amount_Collected__c, Total_Outstanding_Amount__c, Outstanding_Balance__c, Courier_Date__c, Docket_Number__c, Company__c, Applicant_Details_Confirmed_By_Customer__c, Customer_Data_Verified__c, Agreement_Signed_By_Customer__c FROM Opportunity WHERE Account.Team_Member__r.Login_Hash_Code__c =:hashCode];
                System.debug('oppRecords: ' + oppRecords);
            }
            else{
                visitRecords = [SELECT Status__c, Id, OwnerId, IsDeleted, Name, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, SystemModstamp, LastActivityDate, LastViewedDate, LastReferencedDate, Area__c, Budget__c, Construction_Status__c, Employment_Type__c, Purpose_Of_Buying__c, Facilitated_By__c, Walkin_Source__c, Actual_Visit_Date__c, Alternate_Phone__c, Channel_Partner__c, City__c, Company_Name__c, Date_Of_Birth__c, Industry__c, Lead__c, Locality__c, Office_Address__c, Opportunity__c, Pincode__c, Residential_Address__c, Sales_Manager__c, Project_Name__c, Office_PinCode__c,Channel_Partner__r.Name FROM Visit__c WHERE Opportunity__r.Account.Login_Hash_Code__c =:hashCode];
                oppRecords = [SELECT Id, IsDeleted, AccountId, IsPrivate, Name, Description, StageName, Amount, Probability, ExpectedRevenue, TotalOpportunityQuantity, CloseDate, Type, NextStep, LeadSource, IsWon, IsClosed, ForecastCategory, ForecastCategoryName, CampaignId, HasOpportunityLineItem, Pricebook2Id, OwnerId, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, SystemModstamp, LastActivityDate, PushCount, LastStageChangeDate, FiscalQuarter, FiscalYear, Fiscal, ContactId, LastViewedDate, LastReferencedDate, SyncedQuoteId, ContractId, HasOpenActivity, HasOverdueTask, LastAmountChangedHistoryId, LastCloseDateChangedHistoryId, Budget_Confirmed__c, Discovery_Completed__c, ROI_Analysis_Completed__c, Loss_Reason__c, Alternate_Email__c, Alternate_Phone__c, Channel_Partner__c, Email__c, Next_Follow_Up_Date_Time__c, Opportunity_Unique_Id__c, Phone__c, Pre_Sales_Team_Member__c, Project__c, Sales_Team_Member__c, Document_Id__c, Sales_Head_approval_Status__c, Unit__c, CRM_Approval_Status__c, Cost_Sheet_Template__c, Payment_Scheme__c, Agreement_Tax_Amount__c, Agreement_Value__c, Other_Charges__c, Other_Tax_Amount__c, Balance_Total_Due_Amount__c, Balance_Due_Amount_as_per_DL__c, Cost_Sheet_Approval_Status__c, Total_Amount_Collected__c, Total_Outstanding_Amount__c, Outstanding_Balance__c, Courier_Date__c, Docket_Number__c, Company__c, Applicant_Details_Confirmed_By_Customer__c, Customer_Data_Verified__c, Agreement_Signed_By_Customer__c FROM Opportunity WHERE Account.Login_Hash_Code__c =:hashCode];
            }
            // Assign the lists to the wrapper
            wrapper.visitList = (visitRecords.isEmpty()) ? new List<Visit__c>() : visitRecords;
            wrapper.oppList = (oppRecords.isEmpty()) ? new List<Opportunity>() : oppRecords;
            System.debug('Vist List ===>' + wrapper.visitList);
            System.debug('Opp List ===>' + wrapper.oppList);
        }catch(Exception e){
            System.debug('Exception occurred: ' + e.getMessage());
        }
        return wrapper;
    }
    public class ChannelPartnerWrapper {
        public List<Opportunity> oppList { get; set; }
        public List<Visit__c> visitList { get; set; }
        public List<Receipt__c> AllInvoices { get; set; }
        public List<Receipt__c> ApprovedInvoices { get; set; }
    }
}