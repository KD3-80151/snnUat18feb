public without sharing class bookingFormController {
    
    @AuraEnabled
    public static String createApplicants(List<Account> applicantList, Id oppId, String profileDataList, String accId, Account primaryApplicant){
        try {
            system.debug('applicantList ===> ' + applicantList);
            system.debug('primaryApplicant ===> ' + primaryApplicant);
            system.debug('oppId ===> ' + oppId);
            system.debug('profileDataList ===> ' + profileDataList);
            Id customerRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
            EmailTemplate temp = [SELECT Id, Subject, HtmlValue, Body FROM EmailTemplate WHERE DeveloperName = 'Customer_Email_from_BookingForm'];
            List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
            
            Map<String,String> profilePicMap = new Map<String,String>();
            List<Account> applicantListToUpdate = new List<Account>();
            List<Applicant__c> coApplicantDetailsToInsert = new List<Applicant__c>();
            List<Contact> contactsToInsert = new List<Contact>();
            List<Object> rawList = (List<Object>) JSON.deserializeUntyped(profileDataList);
            
            List<Map<String, Object>> dataList = new List<Map<String, Object>>();
            for (Object rawItem : rawList) {
                dataList.add((Map<String, Object>) rawItem);
            }
            
            for (Map<String, Object> record : dataList) {
                if (record.containsKey('fileName')) {
                    String fileName = (String) record.get('fileName');
                    String applicantName;
                    if (record.containsKey('base64Data')) {
                        applicantName = (String) record.get('Name');
                    }
                    
                    if (record.containsKey('base64Data')) {
                        String base64Data = (String) record.get('base64Data');
                        Id contentVersionId = saveContentVersion(fileName, base64Data);
                        if(contentVersionId != null){
                            profilePicMap.put(applicantName, contentVersionId);
                        }
                    }
                }
            }
            
            if(primaryApplicant != null){
                System.debug('primaryApplicant ===> ' + primaryApplicant);
                update primaryApplicant;
                if(primaryApplicant.Name != null){
                    String versionId = profilePicMap.get(primaryApplicant.Name);
                    primaryApplicant.Profile_Pic_Attachment_Id__c = versionId;
                    primaryApplicant.RecordTypeId = customerRecTypeId;
                    applicantListToUpdate.add(primaryApplicant);
                    
                    List<Contact> contactList = [SELECT Id,FirstName,LastName,Email,Phone,Alternate_Email__c,Alternate_Phone__c from Contact WHERE AccountId =: primaryApplicant.Id LIMIT 1];
                    Contact con = new Contact();
                    con.Id          = contactList[0].Id;
                    con.FirstName    = primaryApplicant.First_Name__c;
                    con.LastName    = primaryApplicant.Last_Name__c;
                   
                    con.Email       = primaryApplicant.Email__c;
                    con.AccountId   = primaryApplicant.Id;
                    con.Phone       = primaryApplicant.Phone;
                    con.Alternate_Phone__c = primaryApplicant.Alternate_Phone__c;
                    con.Profile_Pic_Attachment_Id__c = primaryApplicant.Profile_Pic_Attachment_Id__c;
                    update con;
                    
                    System.debug('con::'+con);
                    
                    if(con.Email != null && con.Phone != null){
                        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                        String htmlBody = temp.HtmlValue
                            .replace('{!Contact.Name}', con.FirstName + ' ' + con.LastName)
                            .replace('{!Contact.Phone}', con.Phone);
                        email.setSubject(temp.Subject);
                        email.setToAddresses(new String[]{con.Email});
                        email.setWhatId(con.Id);
                        email.setSaveAsActivity(false);
                        email.setHtmlBody(htmlBody);
                        emailsToSend.add(email);
                    }
                }
            }
            
            // Standard duplicate rules are set to Alert, which blocks DML from Apex unless allowSave is set
            Database.DMLOptions dmlOpts = new Database.DMLOptions();
            dmlOpts.DuplicateRuleHeader.allowSave = true;
            dmlOpts.OptAllOrNone = true;

            List<Contact> contactsToUpdate = new List<Contact>();

            if(!applicantList.isEmpty()){
                // Check for existing Accounts by Phone or Email, reuse them instead of creating duplicates
                Set<String> phones = new Set<String>();
                Set<String> emails = new Set<String>();
                for(Account app : applicantList){
                    if(String.isNotBlank(app.Phone)) phones.add(app.Phone);
                    if(String.isNotBlank(app.Email__c)) emails.add(app.Email__c);
                }

                Id primaryAccId = primaryApplicant != null ? primaryApplicant.Id : null;
                Map<String, Id> accIdByPhone = new Map<String, Id>();
                Map<String, Id> accIdByEmail = new Map<String, Id>();
                if(!phones.isEmpty() || !emails.isEmpty()){
                    for(Account acc : [SELECT Id, Phone, Email__c FROM Account WHERE (Phone IN :phones OR Email__c IN :emails) AND Id != :primaryAccId ORDER BY CreatedDate DESC]){
                        if(String.isNotBlank(acc.Phone) && !accIdByPhone.containsKey(acc.Phone)) accIdByPhone.put(acc.Phone, acc.Id);
                        if(String.isNotBlank(acc.Email__c) && !accIdByEmail.containsKey(acc.Email__c.toLowerCase())) accIdByEmail.put(acc.Email__c.toLowerCase(), acc.Id);
                    }
                }

                List<Account> applicantsToInsert = new List<Account>();
                List<Account> applicantsToProcess = new List<Account>();
                Set<Id> existingAccIds = new Set<Id>();
                for(Account app : applicantList){
                    Id existingId = String.isNotBlank(app.Phone) ? accIdByPhone.get(app.Phone) : null;
                    if(existingId == null && String.isNotBlank(app.Email__c)){
                        existingId = accIdByEmail.get(app.Email__c.toLowerCase());
                    }
                    if(existingId != null){
                        // Same existing Account entered twice in this submission, process it only once
                        if(existingAccIds.contains(existingId)) continue;
                        app.Id = existingId;
                        existingAccIds.add(existingId);
                    }else{
                        applicantsToInsert.add(app);
                    }
                    applicantsToProcess.add(app);
                }

                if(!applicantsToInsert.isEmpty()){
                    Database.insert(applicantsToInsert, dmlOpts);
                }

                Map<Id, Contact> contactByAccId = new Map<Id, Contact>();
                Set<Id> accIdsWithApplicant = new Set<Id>();
                if(!existingAccIds.isEmpty()){
                    for(Contact c : [SELECT Id, AccountId FROM Contact WHERE AccountId IN :existingAccIds ORDER BY CreatedDate ASC]){
                        if(!contactByAccId.containsKey(c.AccountId)) contactByAccId.put(c.AccountId, c);
                    }
                    for(Applicant__c a : [SELECT Account__c FROM Applicant__c WHERE Opportunity__c = :oppId AND Account__c IN :existingAccIds]){
                        accIdsWithApplicant.add(a.Account__c);
                    }
                }

                for(Account app : applicantsToProcess){
                    System.debug('app ===> ' + app);
                    if(app.Name != null){
                        String versionId = profilePicMap.get(app.Name);
                        if(versionId != null || !existingAccIds.contains(app.Id)){
                            app.Profile_Pic_Attachment_Id__c = versionId;
                        }
                        app.RecordTypeId = customerRecTypeId;
                        applicantListToUpdate.add(app);
                    }

                    if(!accIdsWithApplicant.contains(app.Id)){
                        Applicant__c coApplicant = new Applicant__c();
                        coApplicant.Account__c = app.Id;
                        coApplicant.Opportunity__c = oppId;
                        coApplicantDetailsToInsert.add(coApplicant);
                    }

                    Contact con = new Contact();
                    con.FirstName    = app.First_Name__c;
                    con.LastName    = app.Last_Name__c;
                    con.Email       = app.Email__c;
                    con.Phone       = app.Phone;
                    con.Alternate_Phone__c = app.Alternate_Phone__c;
                    con.Profile_Pic_Attachment_Id__c = app.Profile_Pic_Attachment_Id__c;
                    if(contactByAccId.containsKey(app.Id)){
                        con.Id = contactByAccId.get(app.Id).Id;
                        contactsToUpdate.add(con);
                    }else{
                        con.AccountId   = app.Id;
                        contactsToInsert.add(con);
                    }
                }
            }
            if(!applicantListToUpdate.isEmpty()){
                Database.update(applicantListToUpdate, dmlOpts);
            }

            if(!coApplicantDetailsToInsert.isEmpty()){
                insert coApplicantDetailsToInsert;
            }

            if(!contactsToUpdate.isEmpty()){
                Database.update(contactsToUpdate, dmlOpts);
            }

            if(!contactsToInsert.isEmpty()){
                Database.insert(contactsToInsert, dmlOpts);

                /* for(Contact con : contactsToInsert){
                    if(con.Email != null && con.Phone != null){
                        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                        String htmlBody = temp.HtmlValue
                            .replace('{!Contact.Name}', + con.LastName)
                            .replace('{!Contact.Phone}', con.Phone);
                        email.setSubject(temp.Subject);
                        email.setToAddresses(new String[]{con.Email});
                        email.setWhatId(con.Id);
                        email.setSaveAsActivity(false);
                        email.setHtmlBody(htmlBody);
                        emailsToSend.add(email);
                    }
                } */
            }

            if (!emailsToSend.isEmpty()) {
                Messaging.sendEmail(emailsToSend);
            }
            
            List<Opportunity> oppList = [SELECT Id,StageName from Opportunity where Id =: oppId LIMIT 1];
            if(!oppList.isEmpty()){
                List<Task> taskRec = [SELECT Id,Status,Subject,WhatId from Task where Subject = 'Fill Applicant Details' AND WhatId =: oppId LIMIT 1];
                if(!taskRec.isEmpty()){
                    taskRec[0].Status = 'Completed';
                    update taskRec[0];
                }
                oppList[0].StageName = 'Allotment Letter Generated';
                oppList[0].Booking_Date__c = System.Today();
                update oppList[0];
                return 'Success: Applicant Details Created Successfully!!!';
            }
            return 'Error Creating Applicant';
        } catch (Exception e) {
            System.debug('Error ==> ' + e.getMessage());
            System.debug('Line ==> ' + e.getLineNumber());
            return e.getMessage();
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
    public static projectPicklistWrapper getProjectPicklistDetails(Id oppId, Map<String, String> ObjectByField, Map<String, String> ObjectByFieldAddress){
        System.debug('ObjectByField::'+ObjectByField);
        System.debug('ObjectByFieldAddress::'+ObjectByFieldAddress);
        try {
            list<Opportunity> oppRec;
            Map<String, List<String>> picklistValByField;
            Map<String, List<Map<String, String>>> picklistValForAddress;
            if(oppId != null){
                oppRec = [SELECT Id,AccountId, Project__c, Project__r.Name, Project__r.Company__r.Registration_Number__c, Type,Unit__c,Unit__r.Unit_Name__c, Unit__r.Super_Built_Up_Area_sq_ft__c from Opportunity where Id =: oppId];
                System.debug('oppRec::'+oppRec);
            }
            if(ObjectByField != null){
                picklistValByField = getAllPickListVal(ObjectByField);
            }
            if(ObjectByFieldAddress != null){
                picklistValForAddress = getAllPickListValForAddress(ObjectByFieldAddress);
            }
            projectPicklistWrapper wrp = new projectPicklistWrapper();
            wrp.oppRec = oppRec.isEmpty() ? null : oppRec[0];
            wrp.picklistValByField = picklistValByField == null ? null : picklistValByField;
            wrp.picklistValForAddress = picklistValForAddress == null ? null : picklistValForAddress;
            wrp.todayDate = System.today();
            return wrp;
            
        } catch (Exception e) {
            System.debug('Error ====> ' + e.getMessage());
            System.debug('line number ====> ' + e.getLineNumber());
            return null;
        }
    }
    
    public class projectPicklistWrapper{
        @AuraEnabled public Opportunity oppRec{get;set;}
        @AuraEnabled public Date todayDate{get;set;}
        @AuraEnabled public Map<String, List<String>> picklistValByField{get;set;}
        @AuraEnabled public Map<String, List<Map<String, String>>> picklistValForAddress{get;set;}
    }
    
    @AuraEnabled(cacheable= true)
    public static Map<String, List<String>> getAllPickListVal(Map<String, String> ObjectByField){
        Map<String, List<String>> picklistValByField = new Map<String, List<String>>();
        for(String fields : ObjectByField.keySet()){
            picklistValByField.put(fields, getPicklistValues(ObjectByField.get(fields), fields));
        }
        System.debug('picklistValByField::'+picklistValByField);
        return picklistValByField;
    }
    
    @AuraEnabled(cacheable= true)
    public static List<String> getPicklistValues(String objName, String fieldName){
        System.debug('objName::'+objName);
        System.debug('fieldName::'+fieldName);
        List<String> options = new List<String>();
        Map<String, String> mapPickListValues = new Map<String, String>();
        Schema.SObjectType objSobjectType = Schema.getGlobalDescribe().get(objName);
        System.debug('objSobjectType::'+objSobjectType);
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
            System.debug('info::'+info);
            String hexString;
            if(info != null && info.validFor != null){
                 hexString = EncodingUtil.convertToHex(EncodingUtil.base64Decode(info.validFor)).toUpperCase();
            }
            
            Integer baseCount = 0;
            if(hexString != null){
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