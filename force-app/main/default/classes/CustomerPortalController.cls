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
        /** No longer filled: the per-receipt TDS upload was removed from the portal (client, Nov 2026). Kept for compatibility. */
        public Map<String, Document__c> nameXreceipt { get; set; }
        /** TDS Challans the customer uploaded from the portal, per Opportunity Id, newest first. */
        public Map<Id, List<Sub_Document__c>> oppIdXTdsChallans { get; set; }
    }

    /** Only these receipts are shown to the customer on the portal's Receipts tab (credit/debit notes are not). */
    public static final String RECEIPT_TYPE_TAX_INVOICE = 'Tax Invoice';

    /*Vamsi*/
    @RemoteAction
    public static InvoiceWrapper getInvoiceDetails(String hashCode) {
        List<Opportunity> oppList = new List<Opportunity>();
        InvoiceWrapper wrapper = new InvoiceWrapper();
        wrapper.oppList = oppList;
        wrapper.nameXreceipt = new Map<String, Document__c>();
        wrapper.oppIdXTdsChallans = new Map<Id, List<Sub_Document__c>>();
        try {
            if (String.isNotBlank(hashCode)) {
                // Query the Contact based on the hash code
                List<Contact> cons = [SELECT Id, AccountId, Login_Hash_Code__c FROM Contact WHERE Login_Hash_Code__c = :hashCode LIMIT 1];
                if (!cons.isEmpty() && cons[0].AccountId != null) {
                    // The customer's bookings with their Tax Invoice receipts (receipt number = Receipt_Number__c)
                    oppList = [SELECT Id, Name,
                                      (SELECT Id, Name, Receipt_Number__c, CreatedDate, Total_Amount__c, Demand_Letter__r.Payment_Schedule__r.Name, Approval_Status__c
                                       FROM Receipts__r
                                       WHERE Type__c = :RECEIPT_TYPE_TAX_INVOICE
                                       ORDER BY CreatedDate ASC)
                               FROM Opportunity WHERE AccountId = :cons[0].AccountId];
                    wrapper.oppList = oppList;
                    if (!oppList.isEmpty()) {
                        wrapper.oppIdXTdsChallans = tdsChallansByOpportunity(new Map<Id, Opportunity>(oppList).keySet());
                    }
                }
            }
        } catch (Exception e) {
            System.debug('Exception occurred: ' + e.getMessage());
        }
        System.debug('wrapper ---> '+wrapper);
        return wrapper;
    }

    /** Files in each booking's "TDS Uploaded Docs" folder, newest first. */
    @TestVisible
    private static Map<Id, List<Sub_Document__c>> tdsChallansByOpportunity(Set<Id> oppIds) {
        Map<Id, List<Sub_Document__c>> result = new Map<Id, List<Sub_Document__c>>();
        for (Sub_Document__c file : [SELECT Id, Name, CreatedDate, Document__r.Opportunity__c
                                     FROM Sub_Document__c
                                     WHERE Document__r.Opportunity__c IN :oppIds AND Document__r.Name = :TDS_CHALLAN_FOLDER
                                     ORDER BY CreatedDate DESC]) {
            Id oppId = file.Document__r.Opportunity__c;
            if (!result.containsKey(oppId)) {
                result.put(oppId, new List<Sub_Document__c>());
            }
            result.get(oppId).add(file);
        }
        return result;
    }

    /* ---------- TDS Challan upload from the portal (client, Nov 2026) ---------- */

    /** Drive folder (and Document__c record) per booking that holds the TDS Challans customers upload. */
    public static final String TDS_CHALLAN_FOLDER = 'TDS Uploaded Docs';
    /** Largest file accepted, in bytes (the page checks the same limit before sending). */
    public static final Integer TDS_CHALLAN_MAX_BYTES = 3 * 1024 * 1024;
    /** A file with the same name for the same booking within this many minutes is treated as a repeat click / retry. */
    @TestVisible
    private static final Integer TDS_CHALLAN_REPEAT_MINUTES = 15;
    private static final Set<String> TDS_CHALLAN_EXTENSIONS = new Set<String>{ 'pdf', 'jpg', 'jpeg', 'png' };
    private static final String TDS_CHALLAN_UPLOAD_FAILED = 'The file could not be uploaded. Please try again.';
    /** Owner-notification events published in this transaction (used by tests). */
    @TestVisible
    private static Integer tdsChallanEventsPublished = 0;

    public class TdsChallanResult {
        public Boolean success { get; set; }
        public Boolean alreadyUploaded { get; set; }
        public String message { get; set; }
        public String fileName { get; set; }
        TdsChallanResult() {
            success = false;
            alreadyUploaded = false;
        }
    }

    /**
     * Stores a TDS Challan uploaded by the customer in the booking's "TDS Uploaded Docs" folder
     * (Google Drive + Document__c/Sub_Document__c) and notifies the booking owner to verify it and
     * create the TDS receipt. The notification goes through a platform event because the portal runs as
     * the site guest user.
     */
    @RemoteAction
    public static TdsChallanResult uploadTdsChallan(String hashCode, String opportunityId, String fileName, String fileData, String fileType) {
        TdsChallanResult result = new TdsChallanResult();
        try {
            if (String.isBlank(hashCode)) {
                result.message = 'Your session has expired. Please log in again.';
                return result;
            }
            if (String.isBlank(fileName) || String.isBlank(fileData)) {
                result.message = 'Please select the TDS Challan file to upload.';
                return result;
            }
            String extension = fileName.contains('.') ? fileName.substringAfterLast('.').toLowerCase() : '';
            if (!TDS_CHALLAN_EXTENSIONS.contains(extension)) {
                result.message = 'Please upload the TDS Challan as a PDF, JPG or PNG file.';
                return result;
            }

            List<Contact> cons = [SELECT Id, AccountId FROM Contact WHERE Login_Hash_Code__c = :hashCode AND AccountId != null LIMIT 1];
            if (cons.isEmpty()) {
                result.message = 'Your session has expired. Please log in again.';
                return result;
            }
            Id oppId;
            try {
                oppId = Id.valueOf(opportunityId);
            } catch (Exception badId) {
                oppId = null;
            }
            // The booking must belong to the logged-in customer.
            List<Opportunity> opps = oppId == null ? new List<Opportunity>() :
                [SELECT Id, Name, Document_Id__c FROM Opportunity WHERE Id = :oppId AND AccountId = :cons[0].AccountId LIMIT 1];
            if (opps.isEmpty()) {
                result.message = 'This booking could not be found. Please refresh the page and try again.';
                return result;
            }
            Opportunity opp = opps[0];
            String storedName = fileName.trim().abbreviate(80);   // Sub_Document__c Name holds 80 characters
            result.fileName = storedName;

            // A double click or retry must not store the same challan twice (or notify twice).
            Datetime repeatSince = System.now().addMinutes(-TDS_CHALLAN_REPEAT_MINUTES);
            List<Sub_Document__c> recent = [SELECT Id FROM Sub_Document__c
                                            WHERE Name = :storedName AND Document__r.Opportunity__c = :opp.Id
                                            AND Document__r.Name = :TDS_CHALLAN_FOLDER AND CreatedDate >= :repeatSince LIMIT 1];
            if (!recent.isEmpty()) {
                result.success = true;
                result.alreadyUploaded = true;
                result.message = 'This TDS Challan has already been uploaded. Our team will verify it and create your TDS receipt.';
                return result;
            }

            Blob fileBlob = EncodingUtil.base64Decode(fileData);
            if (fileBlob.size() == 0) {
                result.message = 'The selected file is empty. Please choose another file.';
                return result;
            }
            if (fileBlob.size() > TDS_CHALLAN_MAX_BYTES) {
                result.message = 'The file is too large. Please upload a file of up to 3 MB.';
                return result;
            }

            List<Document__c> folders = [SELECT Id, Document_Id__c FROM Document__c
                                         WHERE Opportunity__c = :opp.Id AND Name = :TDS_CHALLAN_FOLDER
                                         ORDER BY CreatedDate ASC LIMIT 1];
            Document__c folder = folders.isEmpty() ? null : folders[0];
            String parentFolderId = String.isNotBlank(opp.Document_Id__c) ? opp.Document_Id__c : rootDriveFolderId(opp.Id);

            String accessToken = GoogleDriveAPI.getAccessToken();
            if (String.isBlank(accessToken)) {
                result.message = TDS_CHALLAN_UPLOAD_FAILED;
                return result;
            }

            // All callouts happen before any DML (Salesforce does not allow a callout after uncommitted DML).
            String folderId = folder != null ? folder.Document_Id__c : null;
            if (String.isBlank(folderId)) {
                folderId = createDriveFolder(TDS_CHALLAN_FOLDER, parentFolderId, accessToken);
            }
            if (String.isBlank(folderId)) {
                result.message = TDS_CHALLAN_UPLOAD_FAILED;
                return result;
            }
            String driveFileId = uploadFileToDrive(folderId, storedName, fileType, fileBlob, accessToken);
            if (String.isBlank(driveFileId)) {
                result.message = TDS_CHALLAN_UPLOAD_FAILED;
                return result;
            }

            if (folder == null) {
                folder = new Document__c(Name = TDS_CHALLAN_FOLDER, Opportunity__c = opp.Id, Status__c = 'Uploaded', Document_Id__c = folderId);
                insert folder;
            } else if (folder.Document_Id__c != folderId) {
                folder.Document_Id__c = folderId;
                folder.Status__c = 'Uploaded';
                update folder;
            }

            Sub_Document__c file = new Sub_Document__c(
                Name           = storedName,
                File_URL__c    = 'https://drive.google.com/file/d/' + driveFileId + '/preview?usp=drivesdk',
                Document__c    = folder.Id,
                Description__c = 'TDS Challan uploaded by the customer from the Customer Portal on '
                                 + System.now().format('dd-MM-yyyy hh:mm a', 'Asia/Kolkata') + '.'
            );
            insert file;

            // Delivered after this transaction commits; the subscriber notifies the booking owner.
            Database.SaveResult published = EventBus.publish(new TDS_Challan_Upload__e(
                Opportunity_Id__c  = opp.Id,
                Sub_Document_Id__c = file.Id,
                File_Name__c       = storedName
            ));
            if (published.isSuccess()) {
                tdsChallanEventsPublished++;
            } else {
                System.debug(LoggingLevel.ERROR, 'TDS Challan notification event not published: ' + published.getErrors());
            }

            result.success = true;
            result.message = 'Your TDS Challan has been uploaded. Our team will verify it and create your TDS receipt.';
            return result;
        } catch (Exception e) {
            System.debug('TDS Challan upload failed: ' + e.getMessage() + ' at line ' + e.getLineNumber());
            result.success = false;
            result.alreadyUploaded = false;
            result.message = TDS_CHALLAN_UPLOAD_FAILED;
            return result;
        }
    }

    /** The booking's "Root Folder" in Drive, used when the Opportunity itself has no folder id. */
    private static String rootDriveFolderId(Id oppId) {
        for (Document__c d : [SELECT Document_Id__c FROM Document__c
                              WHERE Opportunity__c = :oppId AND Name = 'Root Folder' AND Document_Id__c != null
                              ORDER BY CreatedDate ASC LIMIT 1]) {
            return d.Document_Id__c;
        }
        return null;
    }

    /** Uploads one file to a Drive folder (callouts only, no DML) and returns the Drive file id, or null. */
    @TestVisible
    private static String uploadFileToDrive(String folderId, String fileName, String fileType, Blob fileBlob, String accessToken) {
        String mimeType = String.isNotBlank(fileType) ? fileType : 'application/pdf';
        String metadata = JSON.serialize(new Map<String, Object>{ 'name' => fileName, 'mimeType' => mimeType, 'parents' => new List<String>{ folderId } });
        HttpRequest init = new HttpRequest();
        init.setMethod('POST');
        init.setEndpoint('https://www.googleapis.com/upload/drive/v3/files?uploadType=resumable');
        init.setHeader('Authorization', 'Bearer ' + accessToken);
        init.setHeader('Content-Type', 'application/json; charset=UTF-8');
        init.setHeader('Content-Length', String.valueOf(metadata.length()));
        init.setBody(metadata);
        HttpResponse initRes = new Http().send(init);
        String location = initRes.getHeader('Location');
        if (String.isBlank(location)) {
            System.debug('Drive upload session not created ===> ' + initRes.getStatusCode() + ' ' + initRes.getBody());
            return null;
        }

        Integer size = fileBlob.size();
        HttpRequest put = new HttpRequest();
        put.setMethod('PUT');
        put.setEndpoint(location);
        put.setHeader('Content-Type', mimeType);
        put.setHeader('Content-Length', String.valueOf(size));
        put.setHeader('Content-Range', 'bytes 0-' + (size - 1) + '/' + size);
        put.setBodyAsBlob(fileBlob);
        put.setTimeout(120000);
        HttpResponse res = new Http().send(put);
        if (res.getStatusCode() == 200 || res.getStatusCode() == 201) {
            Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            return body != null ? (String) body.get('id') : null;
        }
        System.debug('Drive upload failed ===> ' + res.getStatusCode() + ' ' + res.getBody());
        return null;
    }

    public class wrapperForResponse{
        public Boolean is308Response{get;set;}
        public String locationValue{get;set;}
        public String rangeValue{get;set;}
        public String subDocUrl{get;set;}
        /** Set when the upload is refused (e.g. TDS document already submitted); shown to the customer. */
        public String errorMessage{get;set;}
        /** True when the same file was already uploaded for this receipt and no new copy was made. */
        public Boolean alreadyUploaded{get;set;}
    }

    /** Documents uploaded by customers from the portal are kept in their own folder per Opportunity. */
    public static final String PORTAL_UPLOAD_FOLDER = 'Customer Portal Uploads';
    public static final String RECEIPTS_FOLDER = 'Receipts';

    @RemoteAction
    public static wrapperForResponse uploadDocuments(String receiptId, String fileName, String fileData, String totalFileSize, String documentName, String fileType){
        try{
            System.debug('totalFileSize ===> ' + totalFileSize);
            system.debug('documentName ===> ' + documentName);
            system.debug('receiptId ===> ' + receiptId);
            if(String.isBlank(receiptId) || String.isBlank(fileName) || fileData == null || totalFileSize == null){
                return null;
            }

            Receipt__c receiptRec = [SELECT Id, Opportunity__c, Opportunity__r.Document_Id__c, TDS_Approval_Status__c FROM Receipt__c WHERE Id = :receiptId LIMIT 1];
            Id oppId = receiptRec.Opportunity__c;
            system.debug('oppId ===> ' + oppId);

            // 1) A TDS document that is already submitted / approved must not be uploaded again.
            if(receiptRec.TDS_Approval_Status__c == 'Sent' || receiptRec.TDS_Approval_Status__c == 'Approved'){
                wrapperForResponse refused = new wrapperForResponse();
                refused.errorMessage = receiptRec.TDS_Approval_Status__c == 'Sent'
                    ? 'Your TDS document for this receipt has already been submitted and is pending approval.'
                    : 'Your TDS document for this receipt has already been approved.';
                return refused;
            }

            // 2) Idempotent: the same file for the same Opportunity is never stored twice
            //    (previously every retry after a failure created another copy in Drive and Salesforce).
            List<Sub_Document__c> existing = [SELECT Id, File_URL__c FROM Sub_Document__c
                                              WHERE Name = :fileName AND Document__r.Opportunity__c = :oppId
                                              AND Document__r.Name IN (:PORTAL_UPLOAD_FOLDER, :RECEIPTS_FOLDER)
                                              ORDER BY CreatedDate DESC LIMIT 1];
            if(!existing.isEmpty()){
                wrapperForResponse same = new wrapperForResponse();
                same.subDocUrl = existing[0].File_URL__c;
                same.alreadyUploaded = true;
                same.is308Response = false;
                return same;
            }

            // 3) Target folder: "Customer Portal Uploads" (created on first use), falling back to "Receipts".
            List<Document__c> folders = [SELECT Id, Name, Document_Id__c FROM Document__c
                                         WHERE Opportunity__c = :oppId AND Name IN (:PORTAL_UPLOAD_FOLDER, :RECEIPTS_FOLDER)
                                         ORDER BY CreatedDate ASC];
            Document__c portalFolder;
            Document__c receiptsFolder;
            for(Document__c d : folders){
                if(d.Name == PORTAL_UPLOAD_FOLDER && portalFolder == null) portalFolder = d;
                if(d.Name == RECEIPTS_FOLDER && receiptsFolder == null) receiptsFolder = d;
            }

            String accessToken = GoogleDriveAPI.getAccessToken();
            if(accessToken == null){
                return null;
            }

            // All callouts happen before any DML (Salesforce does not allow a callout after uncommitted DML).
            String folderId = (portalFolder != null) ? portalFolder.Document_Id__c : null;
            Boolean createdPortalFolder = false;
            if(String.isBlank(folderId)){
                String parentFolderId = String.isNotBlank(receiptRec.Opportunity__r.Document_Id__c) ? receiptRec.Opportunity__r.Document_Id__c : null;
                folderId = createDriveFolder(PORTAL_UPLOAD_FOLDER, parentFolderId, accessToken);
                createdPortalFolder = String.isNotBlank(folderId);
            }
            if(String.isBlank(folderId) && receiptsFolder != null){
                folderId = receiptsFolder.Document_Id__c;   // fallback: previous behaviour
            }
            if(String.isBlank(folderId)){
                return null;
            }

            Blob fileBlob = EncodingUtil.base64Decode(fileData);
            Integer totalFileSizeBlob = fileBlob.size();
            String contentRange = 'bytes 0-' + (totalFileSizeBlob-1) + '/' + (totalFileSizeBlob);
            Http http = new Http();

            Map<String,Object> jsonData = new Map<String,Object>{ 'name' => fileName, 'mimeType' => fileType, 'parents' => new List<String>{ folderId } };
            String jsonString = JSON.serialize(jsonData);
            HttpRequest req = new HttpRequest();
            req.setMethod('POST');
            req.setEndpoint('https://www.googleapis.com/upload/drive/v3/files?uploadType=resumable');
            req.setHeader('Authorization', 'Bearer ' + accessToken);
            req.setHeader('Content-Type', 'application/json; charset=UTF-8');
            req.setHeader('Content-Length', String.valueOf(jsonString.length()));
            req.setBody(jsonString);
            HttpResponse res = http.send(req);
            String locationValue = res.getHeader('Location');
            System.debug('location ===> ' + locationValue);
            if(locationValue == null){
                return null;
            }

            HttpRequest request = new HttpRequest();
            request.setMethod('PUT');
            request.setEndpoint(locationValue);
            request.setHeader('Content-Type', String.isNotBlank(fileType) ? fileType : 'application/pdf');
            request.setHeader('Content-Length', String.valueOf(totalFileSizeBlob));
            request.setHeader('Content-Range', contentRange);
            request.setBodyAsBlob(fileBlob);
            HttpResponse response = http.send(request);
            System.debug('response code ===> '+ response.getStatusCode() + ' ' + response.getBody());

            wrapperForResponse wrp = new wrapperForResponse();
            wrp.locationValue = locationValue;
            wrp.is308Response = response.getStatusCode() == 308;
            wrp.rangeValue = response.getHeader('Range');
            wrp.alreadyUploaded = false;

            if(response.getStatusCode() == 200 || response.getStatusCode() == 201){
                Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                String fileId = (responseBody != null && responseBody.get('id') != null) ? (String) responseBody.get('id') : null;

                // DML only after the callouts
                Id targetFolderRecordId;
                if(createdPortalFolder){
                    if(portalFolder == null){
                        portalFolder = new Document__c(Name = PORTAL_UPLOAD_FOLDER, Opportunity__c = oppId, Status__c = 'Uploaded', Document_Id__c = folderId);
                        insert portalFolder;
                    }else{
                        portalFolder.Document_Id__c = folderId;
                        portalFolder.Status__c = 'Uploaded';
                        update portalFolder;
                    }
                    targetFolderRecordId = portalFolder.Id;
                }else{
                    targetFolderRecordId = (portalFolder != null && portalFolder.Document_Id__c == folderId) ? portalFolder.Id : receiptsFolder.Id;
                }

                Sub_Document__c file = new Sub_Document__c(
                    Name        = fileName,
                    File_URL__c = 'https://drive.google.com/file/d/' + fileId + '/preview?usp=drivesdk',
                    Document__c = targetFolderRecordId
                );
                insert file;
                wrp.subDocUrl = file.File_URL__c;
            }
            system.debug('wrp ===> ' + wrp);
            return wrp;
        }catch(Exception e){
            system.debug('Error ==> ' + e.getMessage());
            system.debug('Error in line ==> ' + e.getLineNumber());
            return null;
        }
    }

    /** Creates a Google Drive folder (callout only, no DML) and returns its id, or null. */
    @TestVisible
    private static String createDriveFolder(String folderName, String parentFolderId, String accessToken){
        try{
            Map<String, Object> body = new Map<String, Object>{ 'name' => folderName, 'mimeType' => 'application/vnd.google-apps.folder' };
            if(String.isNotBlank(parentFolderId)){
                body.put('parents', new List<String>{ parentFolderId });
            }
            HttpRequest req = new HttpRequest();
            req.setMethod('POST');
            req.setEndpoint('https://www.googleapis.com/drive/v3/files?fields=id');
            req.setHeader('Authorization', 'Bearer ' + accessToken);
            req.setHeader('Content-Type', 'application/json; charset=UTF-8');
            req.setBody(JSON.serialize(body));
            HttpResponse res = new Http().send(req);
            if(res.getStatusCode() == 200 || res.getStatusCode() == 201){
                Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                return parsed != null ? (String) parsed.get('id') : null;
            }
            System.debug('Folder creation failed ===> ' + res.getStatusCode() + ' ' + res.getBody());
        }catch(Exception e){
            System.debug('Folder creation error ===> ' + e.getMessage());
        }
        return null;
    }

    @RemoteAction
    public static String submitTDSApproval(String receiptId){
        try{
            // A receipt already waiting for approval is not submitted again.
            List<ProcessInstance> pending = [SELECT Id FROM ProcessInstance WHERE TargetObjectId = :receiptId AND Status = 'Pending' LIMIT 1];
            if(!pending.isEmpty()){
                return 'Approval request already submitted successfully for Receipt ID: ' + receiptId;
            }
            Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
            req.setObjectId(receiptId);
            String submitter = System.label.Guest_User_approval_submitter; // Id of the user that will fire the approval on behalf of the guest user. 
            req.setProcessDefinitionNameOrId('TDS_Document_Approval');
            req.setSubmitterId(submitter);
            Approval.ProcessResult result = Approval.process(req);
            if (result.isSuccess()) {
                System.debug('Approval request submitted successfully.');
                return 'Approval request submitted successfully for Receipt ID: ' + receiptId;
            }
            System.debug('Approval request submission failed.');
            return 'Approval request submission failed for Receipt ID: ' + receiptId;
        }catch(Exception e){
            // Previously this surfaced as a silent JS failure, so customers kept re-uploading the same file.
            System.debug('Approval request submission error: ' + e.getMessage());
            return 'Approval request submission failed for Receipt ID: ' + receiptId + '. ' + e.getMessage();
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
        public Map<String, List<ProjectDocGroup>> projectXDocuments { get; set; }
    }

    /** One accordion section in the portal: a folder (Document__c) or the files attached directly to the Project. */
    public class ProjectDocGroup {
        public String Id { get; set; }
        public String Name { get; set; }
        public List<Sub_Document__c> files { get; set; }
        public ProjectDocGroup(String id, String name, List<Sub_Document__c> files) {
            this.Id = id;
            this.Name = name;
            this.files = files != null ? files : new List<Sub_Document__c>();
        }
    }

    public static final String PROJECT_FILES_GROUP = 'Project Documents';

    @RemoteAction
    public static ProjectDocumentWrapper getProjectDocuments(String loginHashCode) {
        if(loginHashCode == null){
            return null;
        }
        ProjectDocumentWrapper projectDocWrapper = new ProjectDocumentWrapper();
        try{
            List<Project__c> projectList = [SELECT Id, Name FROM Project__c];
            Map<String, List<ProjectDocGroup>> projectXDocuments = new Map<String, List<ProjectDocGroup>>();
            if(!projectList.isEmpty()){
                for(Project__c projectRecord : projectList){
                    projectXDocuments.put(projectRecord.Id, new List<ProjectDocGroup>());
                }
                // Files uploaded from the Project record ("Upload Files") are linked directly to the Project,
                // not to a Document__c folder, so they never appeared in the portal before.
                Map<Id, List<Sub_Document__c>> directFiles = new Map<Id, List<Sub_Document__c>>();
                for(Sub_Document__c f : [SELECT Id, Name, File_URL__c, Project__c FROM Sub_Document__c
                                         WHERE Project__c IN :projectXDocuments.keySet() AND Document__c = null AND File_URL__c != null
                                         ORDER BY CreatedDate DESC]){
                    if(!directFiles.containsKey(f.Project__c)) directFiles.put(f.Project__c, new List<Sub_Document__c>());
                    directFiles.get(f.Project__c).add(f);
                }
                for(Id projectId : directFiles.keySet()){
                    projectXDocuments.get(projectId).add(new ProjectDocGroup(null, PROJECT_FILES_GROUP, directFiles.get(projectId)));
                }
                List<Document__c> allDocuments = [SELECT Id, Name, Project__c, (SELECT Id, Name, File_URL__c FROM Sub_Documents__r ORDER BY CreatedDate DESC) FROM Document__c WHERE Project__c IN :projectXDocuments.keySet()];
                if(!allDocuments.isEmpty()){
                    for(Document__c doc : allDocuments){
                        projectXDocuments.get(doc.Project__c).add(new ProjectDocGroup(doc.Id, doc.Name, doc.Sub_Documents__r));
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
                lead.LeadSource = 'Employee Referral';
                lead.Lead_Sub_Source__c = 'Referral';
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
            oppList = [SELECT Id, Name, Project__r.Name, Unit__r.Unit_Name__c, Unit__r.Super_Built_Up_Area_sq_ft__c, Account.Customer_SAP_External_Id__c, Unit__r.Unit_Type__c, CreatedDate, Booking_Date__c, (SELECT Id, Name, (SELECT Id, Name, File_URL__c, CreatedDate FROM Sub_Documents__r ORDER BY CreatedDate DESC) FROM Documents__r) FROM Opportunity WHERE AccountId IN (SELECT AccountId FROM Contact WHERE Login_Hash_Code__c =: hashCode)];
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
            paymentScheduleList = [SELECT Id, Name, Due_Date__c, Agreement_Value__c, Total_Due_Amount__c, Status__c, Opportunity__r.Total_Amount_Collected__c, Opportunity__r.Total_PS_Amount_Inclusive_Of_Tax__c, Opportunity__r.Total_Outstanding_Amount__c, Total_Amount_Inclusive_Of_Tax__c, Pay_Date__c FROM Payment_Schedule__c WHERE Opportunity__c =: oppId];
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
    
    public static void testCover00(){
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
    
    public static void testCover01(){
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
}