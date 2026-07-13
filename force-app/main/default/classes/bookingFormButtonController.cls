public with sharing class bookingFormButtonController {
    public class ContactNameDTO {
        @AuraEnabled public String accountName;
        @AuraEnabled public String firstName;
        @AuraEnabled public String lastName;
    }
    private static String buildFullName(String firstName, String lastName) {
        String fn = String.isBlank(firstName) ? '' : firstName.trim();
        String ln = String.isBlank(lastName)  ? '' : lastName.trim();
        String full = (fn + ' ' + ln).trim();
        return String.isBlank(full) ? 'Customer' : full;
    }
    
    
    
    @AuraEnabled
    public static createApplicantsWrapper createApplicants(List<Account> applicantList, Id oppId, String profileDataList, String accId, Account primaryApplicant, String contactNamesJson, List<Id> deletedAccountIds){
        try {
            system.debug('applicantList ===> ' + applicantList);
            system.debug('primaryApplicant ===> ' + primaryApplicant);
            system.debug('oppId ===> ' + oppId);
            system.debug('profileDataList ===> ' + profileDataList);
            
            Id customerRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
            
            Map<String,String> accNumberByIdMap         = new Map<String,String>();
            List<String>       contactIds               = new List<String>();
            createApplicantsWrapper wrp                 = new createApplicantsWrapper();
            Map<Id,Id>         accIdByConIdMap          = new Map<Id,Id>();
            
            System.debug('contactNamesJson::>>>' + contactNamesJson);
            List<ContactNameDTO> nameDtos = String.isBlank(contactNamesJson) ? new List<ContactNameDTO>() : (List<ContactNameDTO>) JSON.deserialize(contactNamesJson, List<ContactNameDTO>.class);
            
            Map<String, ContactNameDTO> namesByAccName  = new Map<String, ContactNameDTO>();
            for (ContactNameDTO d : nameDtos) {
                if (d != null && !String.isBlank(d.accountName)) {
                    namesByAccName.put(d.accountName, d);
                }
            }
            
            Map<String,String> profilePicMap            = new Map<String,String>();
            List<Object> rawList                        = new List<Object>();
            if (!String.isBlank(profileDataList)) {
                try {
                    Object parsed = JSON.deserializeUntyped(profileDataList);
                    system.debug('parsed::>>>' + parsed);
                    if (parsed instanceof List<Object>) {
                        rawList = (List<Object>) parsed;
                    }
                } catch (Exception pe) {
                    System.debug('ProfileDataList JSON parse error (ignored): ' + pe.getMessage());
                }
            }
            
            List<Map<String, Object>> dataList = new List<Map<String, Object>>();
            for (Object rawItem : rawList) {
                if (rawItem instanceof Map<String, Object>) {
                    dataList.add((Map<String, Object>) rawItem);
                }
            }
            
            for (Map<String, Object> record : dataList) {
                if (record.containsKey('fileName') && record.containsKey('base64Data')) {
                    String fileName      = (String) record.get('fileName');
                    String base64Data    = (String) record.get('base64Data');
                    String applicantName = (String) record.get('Name');
                    Id contentVersionId  = saveContentVersion(fileName, base64Data);
                    if (contentVersionId != null && !String.isBlank(applicantName)) {
                        profilePicMap.put(applicantName, contentVersionId);
                    }
                }
            }
            
            List<Account>     accountsToUpdate      = new List<Account>();
            List<Contact>     contactsToUpsert      = new List<Contact>();
            List<Applicant__c> applicantsToUpsert   = new List<Applicant__c>();
            
            if (primaryApplicant != null) {
                System.debug('primaryApplicant (incoming) ===> ' + primaryApplicant);
                
                ContactNameDTO p = namesByAccName.get(primaryApplicant.Name);
                if (p != null) {
                    primaryApplicant.Name = String.isBlank(p.accountName) ? buildFullName(p.firstName, p.lastName) : p.accountName;
                } else {
                    primaryApplicant.Name = buildFullName(null, primaryApplicant.Name);
                }
                
                if (!String.isBlank(primaryApplicant.Name)) {
                    primaryApplicant.Profile_Pic_Attachment_Id__c = profilePicMap.get(primaryApplicant.Name);
                }
                primaryApplicant.RecordTypeId = customerRecTypeId;
                
                update primaryApplicant;
                
                accNumberByIdMap.put(primaryApplicant.Name, primaryApplicant.Id);
                accountsToUpdate.add(primaryApplicant);
                
                List<Contact> contactList = [
                    SELECT Id, FirstName, LastName, Email, Phone, Alternate_Email__c, Alternate_Phone__c, Salutation FROM Contact WHERE AccountId = :primaryApplicant.Id ORDER BY CreatedDate ASC LIMIT 1];
                if (!contactList.isEmpty()) {
                    Contact con = contactList[0];
                    
                    if (p != null) {
                        con.FirstName = p.firstName;
                        con.LastName  = String.isBlank(p.lastName) ? 'Customer' : p.lastName;
                    } else {
                        con.FirstName = null;
                        con.LastName  = !String.isBlank(primaryApplicant.Name) ? primaryApplicant.Name : 'Customer';
                    }
                    
                    con.Email                   = primaryApplicant.Email__c;
                    con.AccountId               = primaryApplicant.Id;
                    con.Phone                   = primaryApplicant.Phone;
                    con.Salutation              = primaryApplicant.Salutation__c;
                    con.Alternate_Phone__c      = primaryApplicant.Alternate_Contact_Number__c;
                    con.Profile_Pic_Attachment_Id__c = primaryApplicant.Profile_Pic_Attachment_Id__c;
                    
                    update con;
                    
                    contactIds.add(con.Id);
                    accIdByConIdMap.put(con.AccountId, con.Id);
                }
            }
            
            if (applicantList == null) applicantList = new List<Account>();
            if (!applicantList.isEmpty()) {
                upsert applicantList;
                
                Set<Id> coAccIds = new Set<Id>();
                for (Account app : applicantList) {
                    if (app == null) continue;
                    
                    ContactNameDTO dto = namesByAccName.get(app.Name);
                    if (dto != null) {
                        app.Name = String.isBlank(dto.accountName) ? buildFullName(dto.firstName, dto.lastName) : dto.accountName;
                    } else {
                        app.Name = String.isBlank(app.Name) ? 'Customer' : app.Name;
                    }
                    
                    if (!String.isBlank(app.Name)) {
                        app.Profile_Pic_Attachment_Id__c = profilePicMap.get(app.Name);
                    }
                    app.RecordTypeId = customerRecTypeId;
                    
                    accountsToUpdate.add(app);
                    accNumberByIdMap.put(app.Name, app.Id);
                    
                    if (app.Id != null) coAccIds.add(app.Id);
                }
                
                if (!accountsToUpdate.isEmpty()) {
                    update accountsToUpdate;
                }
                
                Map<Id, Contact> existingConByAcc = new Map<Id, Contact>();
                if (!coAccIds.isEmpty()) {
                    for (Contact c : [SELECT Id, AccountId FROM Contact WHERE AccountId IN :coAccIds ORDER BY CreatedDate ASC]) {
                        if (!existingConByAcc.containsKey(c.AccountId)) {
                            existingConByAcc.put(c.AccountId, c);
                        }
                    }
                }
                
                for (Account app : applicantList) {
                    if (app == null || app.Id == null) continue;
                    
                    ContactNameDTO dto = namesByAccName.get(app.Name);
                    Contact con;
                    if (existingConByAcc.containsKey(app.Id)) {
                        con = existingConByAcc.get(app.Id);
                    } else {
                        con = new Contact();
                        con.AccountId = app.Id;
                    }
                    
                    con.FirstName = (dto != null) ? dto.firstName : null;
                    con.LastName  = (dto != null && !String.isBlank(dto.lastName)) ? dto.lastName : 'Customer';
                    con.Email     = app.Email__c;
                    con.Phone     = app.Phone;
                    con.Alternate_Phone__c = app.Alternate_Contact_Number__c;
                    con.Profile_Pic_Attachment_Id__c = primaryApplicant != null ? primaryApplicant.Profile_Pic_Attachment_Id__c : null;
                    
                    contactsToUpsert.add(con);
                }
                
                if (!contactsToUpsert.isEmpty()) {
                    upsert contactsToUpsert;
                    for (Contact c : contactsToUpsert) {
                        contactIds.add(c.Id);
                        accIdByConIdMap.put(c.AccountId, c.Id);
                    }
                }
                
                Map<Id, Applicant__c> existingAppByAcc = new Map<Id, Applicant__c>();
                if (!coAccIds.isEmpty()) {
                    for (Applicant__c a : [SELECT Id, Account__c FROM Applicant__c WHERE Opportunity__c = :oppId AND Account__c IN :coAccIds]) {
                        existingAppByAcc.put(a.Account__c, a);
                    }
                }
                
                for (Account app : applicantList) {
                    if (app == null || app.Id == null) continue;
                    
                    Applicant__c coApp;
                    if (existingAppByAcc.containsKey(app.Id)) {
                        coApp = existingAppByAcc.get(app.Id);
                    } else {
                        coApp = new Applicant__c();
                    }
                    coApp.Account__c     = app.Id;
                    coApp.Opportunity__c = oppId;
                    
                    applicantsToUpsert.add(coApp);
                }
                
                if (!applicantsToUpsert.isEmpty()) {
                    upsert applicantsToUpsert;
                }
            }
            
           

            if (deletedAccountIds != null && !deletedAccountIds.isEmpty() && oppId != null) {
    System.debug('applicant deleted::>> ' + deletedAccountIds);

    List<Applicant__c> toDelApps = [SELECT Id, Account__c FROM Applicant__c WHERE Opportunity__c = :oppId AND Account__c IN :deletedAccountIds];

    if (!toDelApps.isEmpty()) {
        Set<Id> applicantIds = new Set<Id>();
        for (Applicant__c a : toDelApps) applicantIds.add(a.Id);
        List<Document__c> toDelDocs = [SELECT Id FROM Document__c WHERE Opportunity__c = :oppId AND Applicant__c IN :applicantIds];

        if (!toDelDocs.isEmpty()) delete toDelDocs;
        delete toDelApps;
    }
}





            wrp.accNumberByIdMap = accNumberByIdMap;
            wrp.contactIds       = contactIds;
            return wrp;
            
        } catch (Exception e) {
            System.debug('Error ==> ' + e.getMessage());
            System.debug('Line ==> ' + e.getLineNumber());
            return null;
        }
    }
    
    public class createApplicantsWrapper {
        @AuraEnabled public List<String> contactIds {get; set;}
        @AuraEnabled public Map<String,String> accNumberByIdMap {get; set;}
    }
    
    @AuraEnabled
    public static String uploadDocuments(String accId, String fileName, String fileData, String totalFileSize, String documentName, Id oppId) {
        System.debug('fileData:::>>' + (fileData != null ? 'present' : 'null'));
        System.debug('accId: ' + accId);
        System.debug('totalFileSize:::>>' + totalFileSize);
        System.debug('documentName::>>' + documentName);
        System.debug('fileName: ' + fileName);
        System.debug('oppId:::' + oppId);

        try {
            if (String.isBlank(fileData) || String.isBlank(totalFileSize) || oppId == null) {
                return null;
            }

            Blob blobData = EncodingUtil.base64Decode(fileData);
            Integer totalFileSizeBlob = blobData.size();
            String contentRange = 'bytes 0-' + (totalFileSizeBlob - 1) + '/' + (totalFileSizeBlob);

            Document__c parentDoc = null;
            if (!String.isBlank(accId)) {
                List<Document__c> parentList = [SELECT Id, Name, Document_Id__c, Opportunity__c, Account__c FROM Document__c WHERE Opportunity__c = :oppId AND Account__c = :((Id)accId) AND Parent_Document__c = NULL LIMIT 1];
                if (!parentList.isEmpty()) {
                    parentDoc = parentList[0];
                }
            }

            if (parentDoc == null) {
                List<Document__c> primaryAtOpp = [SELECT Id, Name, Document_Id__c FROM Document__c WHERE Opportunity__c = :oppId AND Parent_Document__c = NULL AND Account__c = NULL AND (Name = 'Primary Applicant' OR Name LIKE 'Primary Applicant%') LIMIT 1];
                if (!primaryAtOpp.isEmpty()) {
                    parentDoc = primaryAtOpp[0];
                    System.debug('Using Opportunity-level Primary Applicant parent: ' + parentDoc);
                }
            }

            if (parentDoc == null) {
                System.debug('No parent Document__c found for this upload.');
                return null;
            }

            List<Document__c> childBuckets = [SELECT Id, Name, Document_Id__c FROM Document__c WHERE Parent_Document__c = :parentDoc.Id AND Name = :documentName LIMIT 1];
            if (childBuckets.isEmpty()) {
                System.debug('No bucket named "' + documentName + '" under the resolved parent; not uploading.');
                return null;
            }

            Document__c childTarget = childBuckets[0];
            if (String.isBlank(childTarget.Document_Id__c)) {
                System.debug('Bucket "' + documentName + '" has no Drive folder id; not uploading.');
                return null;
            }

            GoogleDriveAPI.wrapperForResponse resp =
                GoogleDriveAPI.uploadFileToGoogleDrive(fileName, 'application/pdf', childTarget.Document_Id__c, fileData, contentRange, childTarget.Id);

            return (resp != null && resp.subDocUrl != null) ? resp.subDocUrl : null;

        } catch (QueryException qe) {
            System.debug('QueryException ==> ' + qe.getMessage() + ' at line ' + qe.getLineNumber());
            return null;
        } catch (Exception e) {
            System.debug('Error ==> ' + e.getMessage());
            System.debug('Error in line ==> ' + e.getLineNumber());
            return null;
        }
    }


    @AuraEnabled
    public static Id saveContentVersion(String fileName, String base64Data) {
        Blob fileBlob = EncodingUtil.base64Decode(base64Data);
        ContentVersion contentVersion = new ContentVersion();
        contentVersion.Title = fileName;
        contentVersion.PathOnClient = fileName;
        contentVersion.VersionData = fileBlob;
        insert contentVersion;
        return contentVersion.Id;
    }
    
    
    @AuraEnabled
    public static projectPicklistWrapper getProjectPicklistDetails(String oppId, Map<String, String> ObjectByField, Map<String, String> ObjectByFieldAddress){
        try {
            List<Opportunity> oppRec;
            Map<String, List<String>> picklistValByField;
            Map<String, List<Map<String, String>>> picklistValForAddress;
            
            if (ObjectByField != null) {
                picklistValByField = getAllPickListVal(ObjectByField);
            }
            if (ObjectByFieldAddress != null) {
                picklistValForAddress = getAllPickListValForAddress(ObjectByFieldAddress);
            }
            
            Map<String,String> docUrls = new Map<String,String>();
            Map<String,String> docNames = new Map<String,String>();
            
            if (oppId != null) {
                oppRec = [
                    SELECT Id, AccountId,
                    Project__c, Project__r.Name, Project__r.Company__r.Registration_Number__c,
                    Unit__c, Unit__r.Name, Unit__r.Unit_Name__c, Unit__r.Super_Built_Up_Area_sq_ft__c,
                    Channel_Partner__c, Channel_Partner__r.Name, 
                    (SELECT Id, Name, (SELECT Id, Name, Parent_Document__c, (SELECT Id, Name, File_URL__c, CreatedDate FROM Sub_Documents__r ORDER BY CreatedDate DESC) FROM Documents__r
                                                                   WHERE Parent_Document__c != null)
                                                                  FROM Documents__r
                                                                  WHERE Name LIKE '%Primary Applicant%')
                    FROM Opportunity
                    WHERE Id = :oppId
                    LIMIT 1
                ];
                
                Opportunity opp = oppRec[0];
                system.debug('opp.Documents__r ===> ' + opp.Documents__r);
                
                if (opp.Documents__r != null && !opp.Documents__r.isEmpty()) {
                    for (Document__c pa : opp.Documents__r) {
                        if (pa.Documents__r == null || pa.Documents__r.isEmpty()) continue;
                        
                        for (Document__c childDoc : pa.Documents__r) {
                            if (childDoc.Sub_Documents__r == null || childDoc.Sub_Documents__r.isEmpty()) continue;
                            
                            Sub_Document__c latest = childDoc.Sub_Documents__r[0];
                            String n = (childDoc.Name == null) ? '' : childDoc.Name.toLowerCase();
                            String key;
                            if (n.contains('proof of identity')) key = 'proofOfIdentity';
                            else if (n.contains('proof of address')) key = 'proofOfAddress';
                            else if (n.contains('financial documents')) key = 'financialDocs';
                            else if (n.contains('property documents')) key = 'propertyDocs';
                            else if (n.contains('legal documents')) key = 'legalDocs';
                            else if (n.contains('pre-approval documents') || n.contains('pre approval')) key = 'preApprovalDocs';
                            
                            if (key != null && !docUrls.containsKey(key)) {
                                docUrls.put(key, latest.File_URL__c);
                                docNames.put(key, latest.Name);
                            }
                            System.debug('docUrls:==> ' + docUrls);
                        }
                    }
                }
            }
            
            
            Account accRec = null;
            Contact primaryCon = null;
            system.debug('oppRec::>>' + oppRec + 'oppRec[0].AccountId::>>' + oppRec[0].AccountId);
            if (oppRec != null && !oppRec.isEmpty() && oppRec[0].AccountId != null) {
                accRec = [
                    SELECT Id, Name, Name_of_Authorised_Signatory__c,  W_o_S_o_D_o__c,
                    Type, Date_Of_Birth__c, Spouse_Name__c, Spouse_Date_of_Birth__c, Anniversary_Date__c, Resident_Status__c, Passport_Number__c, Country_of_Residence__c, PAN__c,
                    Permanent_Address__Street__s, Permanent_Address__City__s, Permanent_Address__CountryCode__s,
                    Permanent_Address__StateCode__s, Permanent_Address__PostalCode__s,
                    Address_for_Communication__Street__s, Address_for_Communication__City__s,
                    Address_for_Communication__CountryCode__s, Address_for_Communication__StateCode__s,
                    Address_for_Communication__PostalCode__s,
                    Phone, Alternate_Contact_Number__c, Email__c, Official_Email__c,
                    Industry__c, If_Others_Industry__c, Location__c, Designation__c,
                    Annual_Household_Income__c, Company_Firm_Name__c, Purpose_of_Purchase__c,
                    Source_of_Funding__c, Source_of_Information__c, Work_Function_Role__c, If_Others_Work_Funtion_Role__c,
                    Referral_Name__c, Referral_Project_Name__c, Referral_Unit_Number__c, Referral_Phone_Number__c,
                    (SELECT Id, Salutation, FirstName, LastName FROM Contacts LIMIT 1)
                    FROM Account
                    WHERE Id = :oppRec[0].AccountId
                    LIMIT 1
                ];
                if (accRec != null && accRec.Contacts != null && !accRec.Contacts.isEmpty()) {
                    primaryCon = accRec.Contacts[0];
                }
            }
            
            Map<String, String> defaultVals = new Map<String, String>{
                    'Type'                                      => (accRec != null ? String.valueOf(accRec.get('Type')) : null),
                    'Resident_Status__c'                        => (accRec != null ? String.valueOf(accRec.get('Resident_Status__c')) : null),
                    'Industry__c'                               => (accRec != null ? String.valueOf(accRec.get('Industry__c')) : null),
                    'Designation__c'                            => (accRec != null ? String.valueOf(accRec.get('Designation__c')) : null),
                    'Annual_Household_Income__c'                => (accRec != null ? String.valueOf(accRec.get('Annual_Household_Income__c')) : null),
                    'Purpose_of_Purchase__c'                    => (accRec != null ? String.valueOf(accRec.get('Purpose_of_Purchase__c')) : null),
                    'Source_of_Funding__c'                      => (accRec != null ? String.valueOf(accRec.get('Source_of_Funding__c')) : null),
                    'Work_Function_Role__c'                     => (accRec != null ? String.valueOf(accRec.get('Work_Function_Role__c')) : null),
                    'Source_of_Information__c'                  => (accRec != null ? String.valueOf(accRec.get('Source_of_Information__c')) : null),
                    'Name_of_Authorised_Signatory__c'           => (accRec != null ? String.valueOf(accRec.get('Name_of_Authorised_Signatory__c')) : null),
                    'W_o_S_o_D_o__c'                            => (accRec != null ? String.valueOf(accRec.get('W_o_S_o_D_o__c')) : null),
                    'Date_Of_Birth__c'                          => (accRec != null ? String.valueOf(accRec.get('Date_Of_Birth__c')) : null),
                    'Spouse_Name__c'                            => (accRec != null ? String.valueOf(accRec.get('Spouse_Name__c')) : null),
                    'Spouse_Date_of_Birth__c'                   => (accRec != null ? String.valueOf(accRec.get('Spouse_Date_of_Birth__c')) : null),
                    'Anniversary_Date__c'                       => (accRec != null ? String.valueOf(accRec.get('Anniversary_Date__c')) : null),
                    'Passport_Number__c'                        => (accRec != null ? String.valueOf(accRec.get('Passport_Number__c')) : null),
                    'Country_of_Residence__c'                   => (accRec != null ? String.valueOf(accRec.get('Country_of_Residence__c')) : null),
                    'PAN__c'                                    => (accRec != null ? String.valueOf(accRec.get('PAN__c')) : null),
                    'Permanent_Address__Street__s'              => (accRec != null ? String.valueOf(accRec.get('Permanent_Address__Street__s')) : null),
                    'Permanent_Address__City__s'                => (accRec != null ? String.valueOf(accRec.get('Permanent_Address__City__s')) : null),
                    'Permanent_Address__CountryCode__s'         => (accRec != null ? String.valueOf(accRec.get('Permanent_Address__CountryCode__s')) : null),
                    'Permanent_Address__StateCode__s'           => (accRec != null ? String.valueOf(accRec.get('Permanent_Address__StateCode__s')) : null),
                    'Permanent_Address__PostalCode__s'          => (accRec != null ? String.valueOf(accRec.get('Permanent_Address__PostalCode__s')) : null),
                    
                    'Address_for_Communication__Street__s'      => (accRec != null ? String.valueOf(accRec.get('Address_for_Communication__Street__s')) : null),
                    'Address_for_Communication__City__s'        => (accRec != null ? String.valueOf(accRec.get('Address_for_Communication__City__s')) : null),
                    'Address_for_Communication__CountryCode__s' => (accRec != null ? String.valueOf(accRec.get('Address_for_Communication__CountryCode__s')) : null),
                    'Address_for_Communication__StateCode__s'   => (accRec != null ? String.valueOf(accRec.get('Address_for_Communication__StateCode__s')) : null),
                    'Address_for_Communication__PostalCode__s'  => (accRec != null ? String.valueOf(accRec.get('Address_for_Communication__PostalCode__s')) : null),
                    
                    'Phone'                                     => (accRec != null ? String.valueOf(accRec.get('Phone')) : null),
                    'Alternate_Contact_Number__c'               => (accRec != null ? String.valueOf(accRec.get('Alternate_Contact_Number__c')) : null),
                    'Email__c'                                  => (accRec != null ? String.valueOf(accRec.get('Email__c')) : null),
                    'Official_Email__c'                         => (accRec != null ? String.valueOf(accRec.get('Official_Email__c')) : null),
                    
                    'If_Others_Industry__c'                     => (accRec != null ? String.valueOf(accRec.get('If_Others_Industry__c')) : null),
                    'Location__c'                               => (accRec != null ? String.valueOf(accRec.get('Location__c')) : null),
                    'Company_Firm_Name__c'                      => (accRec != null ? String.valueOf(accRec.get('Company_Firm_Name__c')) : null),
                    'If_Others_Work_Funtion_Role__c'            => (accRec != null ? String.valueOf(accRec.get('If_Others_Work_Funtion_Role__c')) : null),
                    'Referral_Name__c'                          => (accRec != null ? String.valueOf(accRec.get('Referral_Name__c')) : null),
                    'Referral_Project_Name__c'                  => (accRec != null ? String.valueOf(accRec.get('Referral_Project_Name__c')) : null),
                    'Referral_Unit_Number__c'                   => (accRec != null ? String.valueOf(accRec.get('Referral_Unit_Number__c')) : null),
                    'Referral_Phone_Number__c'                  => (accRec != null ? String.valueOf(accRec.get('Referral_Phone_Number__c')) : null)
                    };
                        // Contact picklist
                        // Contact defaults
                        defaultVals.put('Contact_FirstName', (primaryCon != null) ? String.valueOf(primaryCon.FirstName) : null);
            defaultVals.put('Contact_LastName',  (primaryCon != null) ? String.valueOf(primaryCon.LastName)  : null);
            defaultVals.put('Salutation',        (primaryCon != null) ? String.valueOf(primaryCon.Salutation): null);
            
            
            
            projectPicklistWrapper wrp = new projectPicklistWrapper();
            
            wrp.docUrls  = docUrls;
            wrp.docNames = docNames;
            
            
            // === Co-applicants: Applicant__c linked to this Opportunity ===
            List<Applicant__c> appRows = new List<Applicant__c>();
            if (oppId != null) {
                appRows = [
                    SELECT Id, Opportunity__c, Account__c,
                    Account__r.Id, Account__r.Name,  Account__r.Name_of_Authorised_Signatory__c,
                    Account__r.W_o_S_o_D_o__c, Account__r.Type, Account__r.Date_Of_Birth__c, Account__r.Spouse_Name__c, Account__r.Spouse_Date_of_Birth__c,
                    Account__r.Anniversary_Date__c,Account__r.Resident_Status__c, Account__r.Passport_Number__c, Account__r.Country_of_Residence__c, Account__r.PAN__c,
                    Account__r.Permanent_Address__Street__s, Account__r.Permanent_Address__City__s, Account__r.Permanent_Address__CountryCode__s, Account__r.Permanent_Address__StateCode__s,
                    Account__r.Permanent_Address__PostalCode__s, Account__r.Address_for_Communication__Street__s, Account__r.Address_for_Communication__City__s,
                    Account__r.Address_for_Communication__CountryCode__s, Account__r.Address_for_Communication__StateCode__s, Account__r.Address_for_Communication__PostalCode__s, Account__r.Phone, Account__r.Alternate_Contact_Number__c, Account__r.Email__c, Account__r.Official_Email__c,
                    Account__r.Industry__c, Account__r.If_Others_Industry__c, Account__r.Location__c, Account__r.Designation__c, Account__r.Annual_Household_Income__c, Account__r.Company_Firm_Name__c,
                    Account__r.Purpose_of_Purchase__c, Account__r.Source_of_Funding__c, Account__r.Source_of_Information__c, Account__r.Work_Function_Role__c, Account__r.If_Others_Work_Funtion_Role__c,
                    Account__r.Referral_Name__c, Account__r.Referral_Project_Name__c, Account__r.Referral_Unit_Number__c, Account__r.Referral_Phone_Number__c, (
                   SELECT Id, Name, (SELECT Id, Name, Parent_Document__c, (SELECT Id, Name, File_URL__c, CreatedDate FROM Sub_Documents__r ORDER BY CreatedDate DESC)
                              FROM Documents__r
                              WHERE Parent_Document__c != null
                          )
                   FROM Documents__r
               ) FROM Applicant__c WHERE Opportunity__c = :oppId ORDER BY CreatedDate
                ];
            }
            
            Set<Id> coAppAccountIds = new Set<Id>();
            Map<Id, Map<String, String>> coappDocUrlsByAccount = new Map<Id, Map<String, String>>();
            Map<Id, Map<String, String>> coappDocNamesByAccount = new Map<Id, Map<String, String>>();   

            system.debug('appRows::>>' + appRows);
            for (Applicant__c ar : appRows) {
                if (accRec != null && ar.Account__c == accRec.Id) continue; // skip primary account
                if (ar.Account__c != null) coAppAccountIds.add(ar.Account__c);

                Id accId = ar.Account__c;
                if (accId == null) continue;

                Map<String,String> urls = new Map<String,String>();
                Map<String,String> names = new Map<String,String>();

                if (ar.Documents__r != null && !ar.Documents__r.isEmpty()) {
                    for (Document__c parentDoc : ar.Documents__r) {
                        if (parentDoc.Documents__r == null || parentDoc.Documents__r.isEmpty()) continue;

                        for (Document__c childDoc : parentDoc.Documents__r) {
                            if (childDoc.Sub_Documents__r == null || childDoc.Sub_Documents__r.isEmpty()) continue;

                            Sub_Document__c latest = childDoc.Sub_Documents__r[0];
                            String n = (childDoc.Name == null) ? '' : childDoc.Name.toLowerCase();

                            String key;
                            if (n.contains('proof of identity'))         key = 'proofOfIdentity';
                            else if (n.contains('proof of address'))     key = 'proofOfAddress';
                            else if (n.contains('financial'))            key = 'financialDocs';
                            else if (n.contains('property'))             key = 'propertyDocs';
                            else if (n.contains('legal'))                key = 'legalDocs';
                            else if (n.contains('pre-approval') || n.contains('pre approval')) key = 'preApprovalDocs';

                            if (key != null && !urls.containsKey(key)) {
                                urls.put(key, latest.File_URL__c);
                                names.put(key, latest.Name);
                            }
                        }
                    }
                }
                if (!urls.isEmpty() || !names.isEmpty()) {
                    coappDocUrlsByAccount.put(accId, urls);
                    coappDocNamesByAccount.put(accId, names);
                }

            }
            
            wrp.coappDocUrlsByAccount  = coappDocUrlsByAccount;
            wrp.coappDocNamesByAccount = coappDocNamesByAccount;

            Map<Id, Contact> acctToPrimaryContact = new Map<Id, Contact>();
            system.debug('coAppAccountIds::>>' + coAppAccountIds);
            if (!coAppAccountIds.isEmpty()) {
                List<Contact> cands = [
                    SELECT Id, FirstName, LastName, Salutation, AccountId
                    FROM Contact
                    WHERE AccountId IN :coAppAccountIds
                    
                ];
                system.debug('cands::>>' + cands);
                for (Contact c : cands) {
                    if (!acctToPrimaryContact.containsKey(c.AccountId)) {
                        acctToPrimaryContact.put(c.AccountId, c);
                    }
                }
            }
            
            
            List<Map<String,String>> moreApplicants = new List<Map<String,String>>();
            system.debug('accRec::>>' + accRec + 'accRec.Id::>>' + accRec.Id);
            for (Applicant__c ar : appRows) {
                if (accRec != null && ar.Account__c == accRec.Id) continue;
                Account aa = ar.Account__r;
                //Contact  cc = ar.Contact__r;
                
                Map<String,String> m = new Map<String,String>();
                // Same keys as defaultVals so the UI code can reuse mapping:
                m.put('Id',                      aa != null ? String.valueOf(aa.Id) : null);
                m.put('Type',                         aa != null ? String.valueOf(aa.Type) : null);
                m.put('Resident_Status__c',           aa != null ? String.valueOf(aa.Resident_Status__c) : null);
                m.put('Industry__c',                  aa != null ? String.valueOf(aa.Industry__c) : null);
                m.put('Designation__c',               aa != null ? String.valueOf(aa.Designation__c) : null);
                m.put('Annual_Household_Income__c',   aa != null ? String.valueOf(aa.Annual_Household_Income__c) : null);
                m.put('Purpose_of_Purchase__c',       aa != null ? String.valueOf(aa.Purpose_of_Purchase__c) : null);
                m.put('Source_of_Funding__c',         aa != null ? String.valueOf(aa.Source_of_Funding__c) : null);
                m.put('Work_Function_Role__c',        aa != null ? String.valueOf(aa.Work_Function_Role__c) : null);
                m.put('Source_of_Information__c',     aa != null ? String.valueOf(aa.Source_of_Information__c) : null);
                
                m.put('Name_of_Authorised_Signatory__c', aa != null ? String.valueOf(aa.Name_of_Authorised_Signatory__c) : null);
                m.put('W_o_S_o_D_o__c',               aa != null ? String.valueOf(aa.W_o_S_o_D_o__c) : null);
                m.put('Date_Of_Birth__c',             aa != null ? String.valueOf(aa.Date_Of_Birth__c) : null);
                m.put('Spouse_Name__c',               aa != null ? String.valueOf(aa.Spouse_Name__c) : null);
                m.put('Spouse_Date_of_Birth__c',      aa != null ? String.valueOf(aa.Spouse_Date_of_Birth__c) : null);
                m.put('Anniversary_Date__c',          aa != null ? String.valueOf(aa.Anniversary_Date__c) : null);
                m.put('Passport_Number__c',           aa != null ? String.valueOf(aa.Passport_Number__c) : null);
                m.put('Country_of_Residence__c',      aa != null ? String.valueOf(aa.Country_of_Residence__c) : null);
                m.put('PAN__c',                       aa != null ? String.valueOf(aa.PAN__c) : null);
                m.put('Permanent_Address__Street__s',     aa != null ? String.valueOf(aa.Permanent_Address__Street__s) : null);
                m.put('Permanent_Address__City__s',       aa != null ? String.valueOf(aa.Permanent_Address__City__s) : null);
                m.put('Permanent_Address__CountryCode__s',aa != null ? String.valueOf(aa.Permanent_Address__CountryCode__s) : null);
                m.put('Permanent_Address__StateCode__s',  aa != null ? String.valueOf(aa.Permanent_Address__StateCode__s) : null);
                m.put('Permanent_Address__PostalCode__s', aa != null ? String.valueOf(aa.Permanent_Address__PostalCode__s) : null);
                
                m.put('Address_for_Communication__Street__s',      aa != null ? String.valueOf(aa.Address_for_Communication__Street__s) : null);
                m.put('Address_for_Communication__City__s',        aa != null ? String.valueOf(aa.Address_for_Communication__City__s) : null);
                m.put('Address_for_Communication__CountryCode__s', aa != null ? String.valueOf(aa.Address_for_Communication__CountryCode__s) : null);
                m.put('Address_for_Communication__StateCode__s',   aa != null ? String.valueOf(aa.Address_for_Communication__StateCode__s) : null);
                m.put('Address_for_Communication__PostalCode__s',  aa != null ? String.valueOf(aa.Address_for_Communication__PostalCode__s) : null);
                
                m.put('Phone',                        aa != null ? String.valueOf(aa.Phone) : null);
                m.put('Alternate_Contact_Number__c',  aa != null ? String.valueOf(aa.Alternate_Contact_Number__c) : null);
                m.put('Email__c',                     aa != null ? String.valueOf(aa.Email__c) : null);
                m.put('Official_Email__c',            aa != null ? String.valueOf(aa.Official_Email__c) : null);
                
                m.put('If_Others_Industry__c',        aa != null ? String.valueOf(aa.If_Others_Industry__c) : null);
                m.put('Location__c',                  aa != null ? String.valueOf(aa.Location__c) : null);
                m.put('Company_Firm_Name__c',         aa != null ? String.valueOf(aa.Company_Firm_Name__c) : null);
                
                m.put('If_Others_Work_Funtion_Role__c', aa != null ? String.valueOf(aa.If_Others_Work_Funtion_Role__c) : null);
                m.put('Referral_Name__c',               aa != null ? String.valueOf(aa.Referral_Name__c) : null);
                m.put('Referral_Project_Name__c',       aa != null ? String.valueOf(aa.Referral_Project_Name__c) : null);
                m.put('Referral_Unit_Number__c',        aa != null ? String.valueOf(aa.Referral_Unit_Number__c) : null);
                m.put('Referral_Phone_Number__c',       aa != null ? String.valueOf(aa.Referral_Phone_Number__c) : null);
                
                // Contact defaults for names + salutation
                Contact cc = (aa != null) ? acctToPrimaryContact.get(aa.Id) : null;
                m.put('Contact_FirstName', cc != null ? String.valueOf(cc.FirstName)  : null);
                m.put('Contact_LastName',  cc != null ? String.valueOf(cc.LastName)   : null);
                m.put('Salutation',        cc != null ? String.valueOf(cc.Salutation) : null);
                
                
                moreApplicants.add(m);
            }
            wrp.additionalApplicantVals = moreApplicants;
            
            wrp.oppRec = (oppRec != null && !oppRec.isEmpty()) ? oppRec[0] : null;
            wrp.picklistValByField = (picklistValByField == null ? null : picklistValByField);
            wrp.picklistValForAddress = (picklistValForAddress == null ? null : picklistValForAddress);
            wrp.defaultVals = defaultVals;
            wrp.todayDate = System.today();
            return wrp;
            
        } catch (Exception e) {
            System.debug('Error ====> ' + e.getMessage());
            System.debug('line number ====> ' + e.getLineNumber());
            return null;
        }
    }
    
    
    public class projectPicklistWrapper{
        @AuraEnabled public Opportunity oppRec;
        @AuraEnabled public Map<String, List<String>> picklistValByField;
        @AuraEnabled public Map<String, List<Map<String, String>>> picklistValForAddress;
        @AuraEnabled public Map<String, String> defaultVals;
        @AuraEnabled public Date todayDate;
        @AuraEnabled public List<Map<String,String>> additionalApplicantVals;
        @AuraEnabled public Map<String,String> docUrls;
        @AuraEnabled public Map<String,String> docNames;
        @AuraEnabled public Map<Id, Map<String,String>> coappDocUrlsByAccount;
        @AuraEnabled public Map<Id, Map<String,String>> coappDocNamesByAccount;

    }
    
    
    @AuraEnabled(cacheable= true)
    public static Map<String, List<String>> getAllPickListVal(Map<String, String> ObjectByField){
        Map<String, List<String>> picklistValByField = new Map<String, List<String>>();
        for(String fields : ObjectByField.keySet()){
            picklistValByField.put(fields, getPicklistValues(ObjectByField.get(fields), fields));
        }
        return picklistValByField;
    }
    
    @AuraEnabled(cacheable= true)
    public static List<String> getPicklistValues(String objName, String fieldName){
        List<String> options = new List<String>();
        Map<String, String> mapPickListValues = new Map<String, String>();
        Schema.SObjectType objSobjectType = Schema.getGlobalDescribe().get(objName);
        Schema.DescribeSObjectResult objDescribeSobject = objSobjectType.getDescribe();
        Map<String, Schema.SObjectField> mapFields = objDescribeSobject.fields.getMap();
        List<Schema.PicklistEntry> lstPickListValues = mapFields.get(fieldName).getDescribe().getPickListValues();
        for (Schema.PicklistEntry objPickList : lstPickListValues) {
            options.add(objPickList.getValue());
        }
        return options;
    }
    
    @AuraEnabled(cacheable=true)
    public static Map<String, List<Map<String, String>>> getAllPickListValForAddress(Map<String, String> ObjectByField) {
        Map<String, List<Map<String, String>>> picklistValByField = new Map<String, List<Map<String, String>>>();
        
        for (String field : ObjectByField.keySet()) {
            List<Map<String, String>> picklistValues = getPicklistValuesForAddress(ObjectByField.get(field), field);
            picklistValByField.put(field, picklistValues);
        }
        return picklistValByField;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getPicklistValuesForAddress(String objName, String fieldName) {
        List<Map<String, String>> options = new List<Map<String, String>>();
        Schema.SObjectType objSobjectType = Schema.getGlobalDescribe().get(objName);
        Schema.DescribeSObjectResult objDescribeSobject = objSobjectType.getDescribe();
        Map<String, Schema.SObjectField> mapFields = objDescribeSobject.fields.getMap();
        List<Schema.PicklistEntry> lstPickListValues = mapFields.get(fieldName).getDescribe().getPickListValues();
        
        for (Schema.PicklistEntry picklistEntry : lstPickListValues) {
            Map<String, String> picklistItem = new Map<String, String>();
            picklistItem.put('label', picklistEntry.getLabel());
            picklistItem.put('value', picklistEntry.getValue());
            options.add(picklistItem);
        }
        return options;
    }
    
    @AuraEnabled(cacheable= true)
    public static Map<String, List<String>> getFieldDependencies(String objectName, String controllingField, String dependentField)
    {
        Map<String, List<String>> controllingInfo = new Map<String, List<String>>();
        Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectName);
        Schema.DescribeSObjectResult describeResult = objType.getDescribe();
        Schema.DescribeFieldResult controllingFieldInfo = describeResult.fields.getMap().get(controllingField).getDescribe();
        Schema.DescribeFieldResult dependentFieldInfo = describeResult.fields.getMap().get(dependentField).getDescribe();
        List<Schema.PicklistEntry> controllingValues = controllingFieldInfo.getPicklistValues();
        List<Schema.PicklistEntry> dependentValues = dependentFieldInfo.getPicklistValues();
        for(Schema.PicklistEntry currControllingValue : controllingValues){
            controllingInfo.put(currControllingValue.getLabel(), new List<String>());
        }
        for(Schema.PicklistEntry currDependentValue : dependentValues){
            String jsonString = JSON.serialize(currDependentValue);
            MyPickListInfo info = (MyPickListInfo) JSON.deserialize(jsonString, MyPickListInfo.class);
            String hexString = EncodingUtil.convertToHex(EncodingUtil.base64Decode(info.validFor)).toUpperCase();
            Integer baseCount = 0;
            for(Integer curr : hexString.getChars())
            {
                Integer val = 0;
                if(curr >= 65){
                    val = curr - 65 + 10;
                }
                else{
                    val = curr - 48;
                }
                if((val & 8) == 8){
                    controllingInfo.get(controllingValues[baseCount + 0].getLabel()).add(currDependentValue.getLabel());
                }
                if((val & 4) == 4){
                    controllingInfo.get(controllingValues[baseCount + 1].getLabel()).add(currDependentValue.getLabel());
                }
                if((val & 2) == 2){
                    controllingInfo.get(controllingValues[baseCount + 2].getLabel()).add(currDependentValue.getLabel());
                }
                if((val & 1) == 1){
                    controllingInfo.get(controllingValues[baseCount + 3].getLabel()).add(currDependentValue.getLabel());
                }
                baseCount += 4;
            }
        }
        return controllingInfo;
    }
    class MyPickListInfo {
        public String active {get; set;}
        public String defaultValue {get; set;}
        public String label {get; set;}
        public String value {get; set;}
        public String validFor {get; set;}
    }
}