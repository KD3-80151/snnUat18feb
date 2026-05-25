public without sharing class CustomerPortalController {
    public string tabValues {get;set;}
    public static String caseType {get;set;}
    public static String purposeOfBuying {get;set;}
    public static String customerPortalCaseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Customer/CP Portal').getRecordTypeId();

    public CustomerPortalController() {
        list<Customer_Dashboard_Tabs__c> cdTabs = [select name,Tab_Label__c,id,Controller_Name__c,Display_Order__c from Customer_Dashboard_Tabs__c ORDER BY Display_Order__c];
        tabValues = JSON.serialize(cdTabs);
        caseType = JSON.serialize(UtilityController.getPicklistValues('Case','Type'));
        purposeOfBuying = JSON.serialize(UtilityController.getPicklistValues('Visit__c','Purpose_Of_Buying__c'));
    }

    @RemoteAction
    public static List<Case> fetchCases(String hashCode){
        System.debug('Login Hash Code ---> '+hashCode);
        List<Case> caseList = new List<Case>();
        if(hashCode != null){
            Contact con = [SELECT Id, Login_Hash_Code__c FROM Contact WHERE Login_Hash_Code__c =: hashCode];
            if(con != null){
                caseList = [SELECT Id, Subject, SuppliedEmail, SuppliedPhone, Type, Description FROM Case WHERE ContactId =: con.Id];
            }
        }
        return caseList;
    }
    
    @RemoteAction
    public static String checkContact(String phoneNumber) {
        try{
            List<Contact> contacts = New List<Contact>();
            if(phoneNumber != null){
                contacts = [SELECT Id, Phone FROM Contact WHERE Phone =: phoneNumber LIMIT 1];
            }
            System.debug('contacts==>' + contacts);
            if(contacts.size() > 0){
                contacts[0].Login_Hash_Code__c = UtilityController.generateRandomString();
                update contacts;
                return contacts.isEmpty() ? null : contacts[0].Login_Hash_Code__c; // Returns Contact Id if contact exists
            }else{
                return 'failed';
            }
        }catch(Exception e){
            return e.getMessage();
        }
    }
    
    /*vamsi*/
    @RemoteAction
    public static Contact getContactDetail(String hashCode) {
        System.debug('id==>' + hashCode);
        Contact contact = new Contact();
        if(hashCode != null){
            contact = [SELECT Id, FirstName, LastName, Email, Phone, Department, Login_Hash_Code__c, Profile_Pic_Attachment_Id__c, Owner.Name, Owner.Email, Owner.Phone FROM Contact WHERE Login_Hash_Code__c =: hashCode LIMIT 1];
        }
        System.debug('contact==>' + contact);
        return contact;
    }
    
    /*Vamsi*/
    /*@RemoteAction
    public static String saveContactDetails(String hashCode, ContactFormData formData) {
        System.debug('hashCode==>' + hashCode);
        System.debug('formData==>' + formData);
    
        try {
            if (hashCode == null || formData == null) {
                return 'Error: Invalid input';
            }
            
            Contact contactToUpdate = [SELECT Id, FirstName, LastName, Email, Phone, Department ,Login_Hash_Code__c
                                       FROM Contact 
                                       WHERE Login_Hash_Code__c = :hashCode LIMIT 1];
            
            if (contactToUpdate == null) {
                return 'Error: Contact not found';
            }
            
            // Update the contact details
            contactToUpdate.FirstName = formData.firstName;
            contactToUpdate.LastName = formData.lastName;
            contactToUpdate.Email = formData.emailId;
            contactToUpdate.Phone = formData.phoneNumber;
            contactToUpdate.Department = formData.department;
    
            update contactToUpdate;
    
            return 'Success';
        } catch (Exception e) {
            System.debug('Exception occurred: ' + e.getMessage());
            return 'Error: ' + e.getMessage();
        }
    }

    public class ContactFormData {
        @AuraEnabled
        public String firstName;
        @AuraEnabled
        public String lastName;
        @AuraEnabled
        public String emailId;
        @AuraEnabled
        public String phoneNumber;
        @AuraEnabled
        public String department;
    }*/
    
   /*Vamsi*/
    @RemoteAction
    public static String createNewCase(String hashCode, Case cs) {
        try {
            // Check if hashCode is not null
            if (hashCode != null && cs != null) {
                // Query for contact with the matching Login_Hash_Code__c
                Contact con = [SELECT Id, Login_Hash_Code__c FROM Contact WHERE Login_Hash_Code__c =: hashCode LIMIT 1];
                
                // If contact is found
                if (con != null) {
                    cs.RecordTypeId = customerPortalCaseRecordTypeId; // Set the record type to Customer/CP Portal
                    cs.ContactId = con.Id; // Use the standard ContactId field
                    cs.Origin = 'Web';
                    cs.Status = 'New';
                    // Insert the case and return success
                    insert cs;
                    return 'Success';
                } else {
                    return 'Error: Contact not found with the provided hash code.';
                }
            } else {
                return 'Error: Invalid or missing hash code.';
            }
        } catch (Exception e) {
            // Return the error message in case of failure
            return 'Error: ' + e.getMessage();
        }
    }

    public class InvoiceWrapper{
        public List<Opportunity> oppList { get; set; }
        public Map<String, Document__c> nameXreceipt { get; set; }
    }

    /*Vamsi*/
    @RemoteAction
    public static InvoiceWrapper getInvoiceDetails(String hashCode) {
        List<Opportunity> oppList = new List<Opportunity>();
        Map<String,Document__c> nameXreceipt = new Map<String,Document__c>();
        InvoiceWrapper wrapper = new InvoiceWrapper();
        try {
            if (hashCode != null) {
                // Query the Contact based on the hash code
                Contact con = [SELECT Id, AccountId, Login_Hash_Code__c FROM Contact WHERE Login_Hash_Code__c = :hashCode LIMIT 1];
                if (con != null && con.AccountId != null) {
                    // Find the Opportunity associated with the Account
                    oppList = [SELECT Id, Name, (SELECT Id, Name, CreatedDate, Total_Amount__c, Demand_Letter__r.Payment_Schedule__r.Name, Approval_Status__c, TDS_Approval_Status__c FROM Receipts__r) FROM Opportunity WHERE AccountId = :con.AccountId];
                    Set<String> receiptNames = new Set<String>();
                    if(!oppList.isEmpty()){
                        wrapper.oppList = oppList;
                        for(Opportunity opp : oppList){
                            if(opp.Receipts__r != null && !opp.Receipts__r.isEmpty()){
                                for(Receipt__c receipt : opp.Receipts__r){
                                    receiptNames.add(receipt.Name);
                                }
                            }
                        }
                        List<Document__c> relatedDocs = [SELECT Id, Name, Opportunity__c, (SELECT Id, Name, File_URL__c FROM Sub_Documents__r ORDER BY CreatedDate DESC LIMIT 1) FROM Document__c WHERE Name IN :receiptNames];
                        if(relatedDocs != null && !relatedDocs.isEmpty()){
                            for(Document__c doc : relatedDocs){
                                if(!nameXreceipt.containsKey(doc.Name)){
                                    nameXreceipt.put(doc.Name, doc);
                                }
                            }
                        }
                        wrapper.nameXreceipt = nameXreceipt;
                    }
                }
            }
        } catch (Exception e) {
            System.debug('Exception occurred: ' + e.getMessage());
        }
        System.debug('wrapper ---> '+wrapper);
        return wrapper;
    }

    public class wrapperForResponse{
        public Boolean is308Response{get;set;}
        public String locationValue{get;set;}
        public String rangeValue{get;set;}
        public String subDocUrl{get;set;}
    }

    @RemoteAction
    public static wrapperForResponse uploadDocuments(String receiptId, String fileName, String fileData, String totalFileSize, String documentName, String fileType){
        try{
            System.debug('totalFileSize ===> ' + totalFileSize);
            system.debug('documentName ===> ' + documentName);
            system.debug('receiptId ===> ' + receiptId);
            Id oppId;

            if(receiptId != null){
                Receipt__c receiptRec = [SELECT Id, Opportunity__c FROM Receipt__c WHERE Id = :receiptId LIMIT 1];
                oppId = receiptRec.Opportunity__c;
            }
            system.debug('oppId ===> ' + oppId);
            
            if(fileData != null && totalFileSize != null){
                Blob blobData = EncodingUtil.base64Decode(fileData);
                Integer totalFileSizeBlob = blobData.size();
                String contentRange = 'bytes 0-' + (totalFileSizeBlob-1) + '/' + (totalFileSizeBlob);
                System.debug('contentRange ===> ' + contentRange);
                List<Document__c> docList = [SELECT Id,Name,Document_Id__c,Account__c,Account__r.Document_Id__c from Document__c where Name =: 'Receipts' and Opportunity__c = :oppId LIMIT 1];
                system.debug('docList ===> ' + docList);
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

    @RemoteAction
    public static String submitTDSApproval(String receiptId){
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        // req.setComments('Submitting new Receipt document for approval.');
        req.setObjectId(receiptId);
        String submitter = System.label.Guest_User_approval_submitter; // Id of the user that will fire the approval on behalf of the guest user. 
        req.setProcessDefinitionNameOrId('TDS_Document_Approval');
        req.setSubmitterId(submitter);
        Approval.ProcessResult result = Approval.process(req);
        if (result.isSuccess()) {
            System.debug('Approval request submitted successfully.');
            return 'Approval request submitted successfully for Receipt ID: ' + receiptId;
        } else {
            System.debug('Approval request submission failed.');
            return 'Approval request submission failed for Receipt ID: ' + receiptId;
        }
    }

    // Wrapper class to hold the Invoice and the most recent Attachment data
    // public class InvoiceWrapper {
    //     public Invoice__c invoice;
    //     public Attachment recentAttachment; // Correct type is Attachment, not ContentDocumentLink

    //     // Constructor to initialize the wrapper with Invoice and Attachment
    //     public InvoiceWrapper(Invoice__c invoice, Attachment recentAttachment) {
    //         this.invoice = invoice;
    //         this.recentAttachment = recentAttachment;
    //     }
    // }


   /* Vamsi */
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

    /*Vamsi*/
    @RemoteAction
    public static List<CustomerFAQs__c> faqs(){
        try{
            List<CustomerFAQs__c> allCustommerFQS = [select id,Question__c,Answer__c from CustomerFAQs__c];
            System.debug('allCustommerFQS'+allCustommerFQS);
            return allCustommerFQS;

        }catch (Exception e) {
            System.debug('Error at line: ' + e.getLineNumber());
            System.debug('Error message: ' + e.getMessage());
            return null;
        }
    }

    @RemoteAction
    public static String doUploadProfilePic(String hashcode, String attachmentBody, String attachmentName, String fileExtention) {
        system.debug('hashcode==>'+hashcode+'attachmentBody==>'+attachmentBody+'attachmentName==>'+attachmentName);
        Contact channelPartner = [SELECT Id, Login_Hash_Code__c, Profile_Pic_Attachment_Id__c FROM Contact WHERE Login_Hash_Code__c =: hashcode LIMIT 1];
        if(channelPartner != null && attachmentBody != null) {
            ContentVersion conVer = new ContentVersion();
            conVer.ContentLocation = 'S'; // to use S specify this document is in Salesforce, to use E for external files
            conVer.PathOnClient = '/'+System.now()+attachmentName+'.'+fileExtention;// The files name, extension is very important here which will help the file in preview.
            conVer.Title = attachmentName; // Display name of the files
            conVer.VersionData = EncodingUtil.base64Decode(attachmentBody); // converting your binary string to Blog
            conVer.isMajorVersion = false;
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
            
            update new Contact(Id = channelPartner.Id,Profile_Pic_Attachment_Id__c = conVer.Id );
            return conVer.Id;
        }
        return null;
    }

    @RemoteAction
    public static Contact getUserDetails(string hashCode){
        try{
            Contact accRecord = New Contact();
            if(hashCode != null){
                accRecord = [Select Id,Login_Hash_Code__c,Profile_Pic_Attachment_Id__c From Contact WHERE Login_Hash_Code__c =: hashCode];
            }
            return accRecord;
        }catch(Exception e){
            return null;
        }
    }

    public static Id getContentWorkspace() {
        try {
            return [SELECT Id FROM ContentWorkSpace WHERE Name = 'Ondonte Files'].Id;
        }catch(Exception e) {
            System.debug('--- error message'+e.getMessage());
            return null;
        }
    }

    @RemoteAction
    public static String deleteHashCode(String hashCode) {
        try {
            if (hashCode != null) {
                
                Contact conRecord = [SELECT Id, Login_Hash_Code__c, Profile_Pic_Attachment_Id__c 
                                    FROM Contact 
                                    WHERE Login_Hash_Code__c = :hashCode 
                                    LIMIT 1]; 
                
                if (conRecord != null) {
                    conRecord.Login_Hash_Code__c = '';
                    update conRecord;
                }
            }
            return 'Success'; 
        } catch (Exception e) {
            return null; 
        }
    }

    @RemoteAction
    public static List<Blogs__c> getBlogsWithFiles() {
        List<Blogs__c> blogsWithFiles = new List<Blogs__c>();

        try {
            // Fetch all blogs
            blogsWithFiles = [SELECT Id, Name, Topic__c, Description__c, (SELECT File_URL__c FROM Sub_Documents__r ORDER BY CreatedDate DESC LIMIT 1) FROM Blogs__c];

            // Prepare a list of blog IDs to fetch related files
            // Set<Id> blogIds = new Set<Id>();
            // for (Blogs__c blog : blogs) {
            //     blogIds.add(blog.Id);
            // }

            // // Fetch related files using ContentDocumentLink
            // List<ContentDocumentLink> links = [
            //     SELECT ContentDocumentId, LinkedEntityId 
            //     FROM ContentDocumentLink 
            //     WHERE LinkedEntityId IN :blogIds
            // ];

            // // Map to hold ContentDocumentId and its LatestPublishedVersionId
            // Map<Id, String> docIdToUrlMap = new Map<Id, String>();
            // if (!links.isEmpty()) {
            //     // Get all ContentDocumentIds from the links
            //     Set<Id> contentDocIds = new Set<Id>();
            //     for (ContentDocumentLink link : links) {
            //         contentDocIds.add(link.ContentDocumentId);
            //     }

            //     // Fetch the latest published version for all related documents in one query
            //     Map<Id, ContentDocument> docMap = new Map<Id, ContentDocument>([
            //         SELECT Id, LatestPublishedVersionId 
            //         FROM ContentDocument 
            //         WHERE Id IN :contentDocIds     
            //     ]);

            //     // Populate the URL map with the latest published versions
            //     for (ContentDocumentLink link : links) {
            //         ContentDocument doc = docMap.get(link.ContentDocumentId);
            //         if (doc != null) {
            //             // Generate the URL for display
            //             docIdToUrlMap.put(link.LinkedEntityId, '/sfc/servlet.shepherd/version/download/' + doc.LatestPublishedVersionId);
            //         }
            //     }
            // }

            // // Construct the result list with blogs and their respective file URLs
            // for (Blogs__c blog : blogs) {
            //     Map<String, Object> blogData = new Map<String, Object>();
            //     blogData.put('Id', blog.Id);
            //     blogData.put('Topic__c', blog.Topic__c);
            //     blogData.put('Description__c', blog.Description__c);
            //     blogData.put('fileUrl', docIdToUrlMap.get(blog.Id)); // Retrieve the file URL if it exists
            //     blogsWithFiles.add(blogData);
            // }
        } catch (Exception e) {
            System.debug('Error Occurred: ' + e.getMessage() + ' at Line ' + e.getLineNumber());
        }

        return blogsWithFiles;
    }

    public class ProjectDocumentWrapper{
        public List<Project__c> projectList { get; set; }
        public Map<String, List<Document__c>> projectXDocuments { get; set; }
    }

    @RemoteAction
    public static ProjectDocumentWrapper getProjectDocuments(String loginHashCode) {
        if(loginHashCode == null){
            return null;
        }
        ProjectDocumentWrapper projectDocWrapper = new ProjectDocumentWrapper();
        try{
            List<Project__c> projectList = [SELECT Id, Name FROM Project__c];
            Map<String, List<Document__c>> projectXDocuments = new Map<String, List<Document__c>>();
            if(!projectList.isEmpty()){
                for(Project__c projectRecord : projectList){
                    projectXDocuments.put(projectRecord.Id, new List<Document__c>());
                }
                List<Document__c> allDocuments = [SELECT Id, Name, Project__c, (SELECT Id, Name, File_URL__c FROM Sub_Documents__r ORDER BY CreatedDate DESC) FROM Document__c WHERE Project__c IN :projectXDocuments.keySet()];
                if(!allDocuments.isEmpty()){
                    for(Document__c doc : allDocuments){
                        projectXDocuments.get(doc.Project__c).add(doc);
                    }
                }
            }
            projectDocWrapper.projectList = projectList;
            projectDocWrapper.projectXDocuments = projectXDocuments;
            return projectDocWrapper;
        }catch(Exception e){
            System.debug(e.getLineNumber()+'-----get Message----'+e.getMessage());
            return null;
        }
    }

    @RemoteAction
    public static String CreateReferralLead(Lead lead, String hashCode){
        System.debug('CreateReferralLead ---> '+lead);
        if(hashCode == null){
            System.debug('No hashCode  found.');
            return 'No hashCode  found.';
        }
        try{
            System.debug('hashCode ---> '+hashCode);
            Contact con = [SELECT Id, Login_Hash_Code__c, AccountId, Name, Email, Phone FROM Contact WHERE Login_Hash_Code__c =: hashCode];
            if(con != null){
                
                lead.Company = lead.LastName;
                lead.Referred_By__c = con.AccountId;
                lead.Referred_By_Name__c = con.Name;
                lead.Referred_By_Phone__c = con.Phone;
                lead.Referred_By_Email__c = con.Email;
                lead.Lead_Type__c = 'Referral';
                insert lead;
                return 'SUCCESS';
            }else{
                System.debug('No Contact found.');
                return 'No Contact found.';
            }
        }catch(Exception e){
            System.debug('Error: '+e.getMessage()+' at Line '+e.getLineNumber());
            return 'Error: '+e.getMessage();
        }
    }

    public class custDocWrapper {
        public List<Opportunity> oppList { get; set; }
        public Map<Id, List<Document__c>> accIdXDocuments { get; set; }
    }
    @RemoteAction
    public static custDocWrapper fetchCustomerDocs( String hashCode){
        if(hashCode == null){
            System.debug('Login Hash Code is null.');
            return null;
        }
        custDocWrapper custDocWrap = new custDocWrapper();
        try{
            Contact con = [SELECT Id, AccountId, Login_Hash_Code__c FROM Contact WHERE Login_Hash_Code__c =: hashCode];
            if(con != null){
                List<Opportunity> oppList = [SELECT Id, Name, Unit__r.Unit_Name__c, Project__r.Name, Block__c,  AccountId, (SELECT Id, Account__c, Account__r.Id, Account__r.Name FROM Applicants__r) FROM Opportunity WHERE AccountId =: con.AccountId];
                Map<Id, List<Document__c>> accIdXDocuments = new Map<Id, List<Document__c>>();
                List<Document__c> relDocs = new List<Document__c>();
                if(!oppList.isEmpty()){
                    System.debug('oppList ---> '+oppList);
                    for(Opportunity opp: oppList){
                        if(opp.Applicants__r != null){
                            System.debug('opp.Applicants__r ---> '+opp.Applicants__r);
                            for(Applicant__c app: opp.Applicants__r){
                                System.debug('app.Account__c ---> '+app.Account__c);
                                if(!accIdXDocuments.containsKey(app.Account__c)){
                                    accIdXDocuments.put(app.Account__c, new List<Document__c>());
                                }
                            }
                        }
                    }
                    if(!accIdXDocuments.isEmpty()){
                        relDocs = [SELECT Id, Name, Account__c, (SELECT Id, Name, File_URL__c FROM Sub_Documents__r ORDER BY CreatedDate DESC) FROM Document__c WHERE Account__c IN :accIdXDocuments.keySet()];
                    }
                }
                for(Document__c doc: relDocs){
                    accIdXDocuments.get(doc.Account__c).add(doc);
                }
                custDocWrap.oppList = oppList;
                custDocWrap.accIdXDocuments = accIdXDocuments;
            }
        }catch (Exception e){
            System.debug('Error: '+e.getMessage()+' at Line '+e.getLineNumber());
        }
        return custDocWrap;
    }

    public class ProjectWrapper{
        public List<Project__c> projectList { get; set; }
        public Map<Id, List<Project_Updates__c>> projectIdXProjectUpdates { get; set; }
    }
    @RemoteAction
    public static ProjectWrapper fetchProjectsWithUpdates (){
        List<Project__c> projectList = new List<Project__c>();
        List<Project_Updates__c> projectUpdates = new List<Project_Updates__c>();
        Map<Id, List<Project_Updates__c>> projectIdXProjectUpdates = new Map<Id, List<Project_Updates__c>>();
        try{
            projectUpdates = [SELECT Id, Name, Project__c, Description__c,(SELECT Id, Name, File_URL__c, CreatedDate FROM Sub_Documents__r ORDER BY CreatedDate DESC) FROM Project_Updates__c];
            System.debug('projectUpdates ---> '+projectUpdates);
            for(Project_Updates__c projUp: projectUpdates){
                if(!projectIdXProjectUpdates.containsKey(projUp.Project__c)){
                    projectIdXProjectUpdates.put(projUp.Project__c, new List<Project_Updates__c>());
                }
                projectIdXProjectUpdates.get(projUp.Project__c).add(projUp);
            }
            if(!projectIdXProjectUpdates.isEmpty()){
                projectList = [SELECT Id, Name, Project_Address__c, (SELECT Id, Name, File_URL__c, CreatedDate FROM Sub_Documents__r ORDER BY CreatedDate DESC) FROM Project__c WHERE Id IN :projectIdXProjectUpdates.keySet()];
            }
        }catch(Exception e){
            System.debug('Error: '+e.getMessage()+' at Line '+e.getLineNumber());
        }
        ProjectWrapper projectWrapper = new ProjectWrapper();
        projectWrapper.projectList = projectList;
        projectWrapper.projectIdXProjectUpdates = projectIdXProjectUpdates;
        return projectWrapper;
    }

    public class visitXProjectWrapper{
        public List<Visit__c> visitList { get; set; }
        public Map<String, List<Sub_Document__c>> projectXSubDocs { get; set; }
        public Map<String, List<Amenities__c>> projectXamenities { get; set; }
    }
    @RemoteAction
    public static visitXProjectWrapper FetchVisitOnCon(String hashCode) {
        List<Visit__c> visitList;
        Map<String, List<Sub_Document__c>> projectXSubDocs = new Map<String, List<Sub_Document__c>>();
        Map<String, List<Amenities__c>> projectXamenities = new Map<String, List<Amenities__c>>();
        visitXProjectWrapper wrapper = new visitXProjectWrapper();
        try {
            Contact con = [SELECT Id FROM Contact WHERE Login_Hash_Code__c = :hashCode LIMIT 1];
            visitList = [SELECT Id, Actual_Visit_Date__c, Visit_Time__c, CreatedBy.Name, Project__c, Project__r.Name, Project__r.Project_Address__c, Project__r.City__c, Project__r.Project_Type__c, Project__r.Unit_Type__c, Project__r.Project_Status__c, Project__r.Total_Amount__c, Project__r.Booking_Amount__c, Project__r.Area__c, Project__r.Owner.Phone, Status__c, Contact__c FROM Visit__c WHERE Status__c != null AND Contact__c = :con.Id];
            if(!visitList.isEmpty()){
                for(Visit__c visit : visitList){
                    projectXSubDocs.put(visit.Project__c, new List<Sub_Document__c>());
                    projectXamenities.put(visit.Project__c, new List<Amenities__c>());
                }
            }
            if(!projectXSubDocs.isEmpty()){
                List<Sub_Document__c> allSubDocs = [SELECT Id, Name, File_URL__c, Project__c FROM Sub_Document__c WHERE Project__c IN :projectXSubDocs.keySet()];
                if(!allSubDocs.isEmpty()){
                    for(Sub_Document__c subDoc : allSubDocs){
                        projectXSubDocs.get(subDoc.Project__c).add(subDoc);
                    }
                }
            }
            if(!projectXamenities.isEmpty()){
                List<Amenities__c> allAmenities = [SELECT Id, Name, Icon_Name__c, CreatedDate, Project__c FROM Amenities__c WHERE Project__c IN :projectXamenities.keySet() ORDER BY CreatedDate DESC];
                if(!allAmenities.isEmpty()){
                    for(Amenities__c amenity : allAmenities){
                        projectXamenities.get(amenity.Project__c).add(amenity);
                    }
                }
            }
            wrapper.visitList = visitList;
            wrapper.projectXSubDocs = projectXSubDocs;
            wrapper.projectXamenities = projectXamenities;
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
        }
        return wrapper;
    }

    @RemoteAction
    public static String updateVisit(Visit__c visit){
        if(visit != null){
            try{
                update visit;
                return 'Success';
            }catch(Exception e){
                System.debug('Error while updating cancelled visit: ' + e.getMessage() + ' at line: ' + e.getLineNumber());
                return 'Error: '+e.getMessage();
            }
        }else{
            return 'Enter some data.';
        }
    }

    @RemoteAction
    public static Visit__c rescheduleVisit(Visit__c visit, Integer hour, Integer minute){
        System.debug('visit ---> '+visit);
        if(hour != null && minute != null ){
            visit.Visit_Time__c = Time.newInstance(hour, minute, 0, 0);
        }
        try{
            update visit;
            return visit;
        }catch(Exception e){
            System.debug('Error: '+e.getMessage()+' at Line '+e.getLineNumber());
            return null;
        }
    }

    @RemoteAction
    public static List<Opportunity> fetchBookingData(String hashCode){
        if(hashCode == null){
            return null;
        }
        System.debug('Login Hash Code ---> '+hashCode);
        List<Opportunity> oppList = new List<Opportunity>();
        try{
            oppList = [SELECT Id, Name, Project__r.Name, Unit__r.Unit_Name__c, Unit__r.Super_Built_Up_Area_sq_ft__c, Account.Customer_SAP_External_Id__c, Unit__r.Unit_Type__c, CreatedDate, Booking_Date__c, (SELECT Id, Name, (SELECT Id, File_URL__c, CreatedDate FROM Sub_Documents__r ORDER BY CreatedDate DESC LIMIT 1) FROM Documents__r) FROM Opportunity WHERE AccountId IN (SELECT AccountId FROM Contact WHERE Login_Hash_Code__c =: hashCode)];
        }catch(Exception e){
            System.debug('Error: '+e.getMessage()+' at Line '+e.getLineNumber());
        }
        return oppList;
    }

    @RemoteAction
    public static List<Payment_Schedule__c> fetchPaymentSchedules(String oppId){
        System.debug('Opportunity Id ---> '+oppId);
        if(oppId == null){
            return null;
        }
        List<Payment_Schedule__c> paymentScheduleList = new List<Payment_Schedule__c>();
        try{
            paymentScheduleList = [SELECT Id, Name, Due_Date__c, Agreement_Value__c, Total_Due_Amount__c, Status__c, Opportunity__r.Total_Amount_Collected__c, Opportunity__r.Total_Outstanding_Amount__c, Pay_Date__c FROM Payment_Schedule__c WHERE Opportunity__c =: oppId];
        }catch(Exception e){
            System.debug('Error: '+e.getMessage()+' at Line '+e.getLineNumber());
        }
        return paymentScheduleList;
    }

    @RemoteAction
    public static Visit__c saveVisit(String hashCode, Visit__c visit, Integer hour, Integer minute){
        System.debug('visit ---> '+visit);
        if(hashCode == null){
            System.debug('No hashCode  found.');
            return null;
        }
        if(hour != null && minute != null ){
            visit.Visit_Time__c = Time.newInstance(hour, minute, 0, 0);
        }
        try{
            System.debug('hashCode ---> '+hashCode);
            Contact con = [SELECT Id, Login_Hash_Code__c FROM Contact WHERE Login_Hash_Code__c =: hashCode];
            if(con != null){
                visit.Contact__c = con.Id;
                insert visit;
                return visit;
            }else{
                System.debug('No Contact found.');
                return null;
            }
        }catch(Exception e){
            System.debug('Error: '+e.getMessage()+' at Line '+e.getLineNumber());
            return null;
        }
    }

    @RemoteAction
    public static List<Project__c> fetchAllProjects(){
        List<Project__c> projectList = new List<Project__c>();
        try{
            projectList = [SELECT Id, Name, Project_Address__c, Unit_Type__c, Total_Amount__c, Booking_Amount__c, Project_Status__c, Project_Type__c, Area__c, Owner.Phone, (SELECT Id, Name, File_URL__c FROM Sub_Documents__r ORDER BY CreatedDate DESC), (SELECT Id, Name, Icon_Name__c FROM Amenities__r ORDER BY CreatedDate DESC) FROM Project__c];
        }catch(Exception e){
            System.debug('Error: '+e.getMessage()+' at Line '+e.getLineNumber());
        }
        return projectList;
    }

    public class referralWrapper {
        public List<Project__c> projectList {get; set;}
        public List<Lead> leadList {get; set;}
    }
    
    @RemoteAction
    public static referralWrapper getAllData(String hashCode) {
        try{
            referralWrapper wrapper = new referralWrapper();
            List<Project__c> projectList = [SELECT Id, Name FROM Project__c];
            List<Lead> leadList = new List<Lead>();
            wrapper.projectList = projectList;
            System.debug('HashCode ===> ' + hashCode);
            if(hashCode != null && hashCode != '') {
                Contact con = [SELECT Id, Login_Hash_Code__c, AccountId FROM Contact WHERE Login_Hash_Code__c = :hashCode LIMIT 1];
                if(con != null && con.AccountId != null) { leadList = [SELECT Id, Name, Project__r.Name, Phone, Status FROM Lead WHERE Referred_By__c = :con.AccountId]; }
                wrapper.leadList = leadList;
            }
            return wrapper;
        }catch (Exception e){
            System.debug('Error in getBookingDetails: ' + e.getMessage() +'Line Number::'+ e.getLineNumber());
            return null;
        }
    }

    public class crmWrapper {
        public String crmName {get; set;}
        public String crmEmail {get; set;}
        public String crmPhone {get; set;}
    }

    @RemoteAction
    public static crmWrapper getCRMDetails(String hashcode) {
        crmWrapper wrap = new crmWrapper();
        try{
            System.debug('hashcode ---> ' + hashcode);
            List<Contact> con = [SELECT Id, FirstName, LastName, Email, Phone, Department, Login_Hash_Code__c, Profile_Pic_Attachment_Id__c, AccountId FROM Contact WHERE Login_Hash_Code__c =: hashCode LIMIT 1];
            if(con[0] != null && con[0].AccountId != null){
                List<Account> acc = [SELECT Id, Name FROM Account WHERE Id =: con[0].AccountId LIMIT 1];
                if(acc[0] != null){
                    List<Opportunity> oppList = [SELECT Id, Name, Sales_Team_Member__c, Sales_Team_Member__r.Name, Sales_Team_Member__r.Phone, Sales_Team_Member__r.Email FROM Opportunity WHERE AccountId =: acc[0].Id ORDER BY CreatedDate DESC];
                    if(oppList[0] != null){
                        wrap.crmName = oppList[0].Sales_Team_Member__r.Name;
                        wrap.crmEmail = oppList[0].Sales_Team_Member__r.Email;
                        wrap.crmPhone = oppList[0].Sales_Team_Member__r.Phone;
                        System.debug('wrap.crmName ---> ' + wrap.crmName);
                        System.debug('wrap.crmEmail ---> ' + wrap.crmEmail);
                        System.debug('wrap.crmPhone ---> ' + wrap.crmPhone);
                        return wrap;
                    }
                    System.debug('No opp found!');
                    return wrap;
                }
                System.debug('No Account found!');
                return wrap;
            }
            System.debug('No Contact found!');
            return wrap;
        }catch(Exception e){
            System.debug('Error ---> ' + e.getMessage() + ' at Line ---> ' + e.getLineNumber());
            return wrap;
        }
    }
}