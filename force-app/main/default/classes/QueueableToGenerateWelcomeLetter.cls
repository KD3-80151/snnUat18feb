public without sharing class QueueableToGenerateWelcomeLetter implements Queueable, Database.AllowsCallouts {

    private Id opportunityId;

    public QueueableToGenerateWelcomeLetter(Id opportunityId) {
        this.opportunityId = opportunityId;
    }

    public void execute(QueueableContext qc) {
        try {
            System.debug('QueueableToGenerateWelcomeLetter START => ' + opportunityId);

            if (opportunityId == null) {
                System.debug('Opportunity Id is null. Exiting queueable.');
                return;
            }

            docwrpperClass result = generateWelcomeLetterDocument(String.valueOf(opportunityId));
            System.debug('QueueableToGenerateWelcomeLetter RESULT => ' + result);

            if (result != null && result.contentVersionIds != null && !result.contentVersionIds.isEmpty()) {
                sendWelcomeLetterEmail(opportunityId, result.contentVersionIds);
            } else {
                System.debug('No ContentVersionIds returned. Skipping email send.');
            }

        } catch (Exception e) {
            System.debug('Error in QueueableToGenerateWelcomeLetter => ' + e.getMessage());
            System.debug('Error line => ' + e.getLineNumber());
        }
    }

    public static docwrpperClass generateWelcomeLetterDocument(String recordId) {
        System.debug('recordId:::>>' + recordId);
        docwrpperClass wrapperRec = new docwrpperClass();

        try {
            if (String.isBlank(recordId)) {
                wrapperRec.message = 'No Opportunity Id provided.';
                return wrapperRec;
            }

            List<Opportunity> oppList = [
                SELECT Id, Name, AccountId, Account.Full_Name__c, Account.Email__c, Account.Phone, Unit__r.Unit_Name__c, Unit__r.Floor__r.Blocks__r.Tower_Code__c, Project__r.Name, Project__r.Bank_Name__c, Project__r.Company__c,
                Project__r.Company__r.Name, Project__r.Company__r.Address__c, Project__r.Company__r.Email__c, Project__r.Company__r.PAN_No__c, Project__r.Account_Name__c, Project__r.Account_Number__c,
                Project__r.Type_of_Account__c, Project__r.Branch__c, Project__r.IFSC_Code__c, Booking_Date__c, (SELECT Id, Account__r.Full_Name__c FROM Applicants__r),
                (SELECT Id, Name, Document_Id__c FROM Documents__r WHERE Name = 'Root Folder' LIMIT 1) FROM Opportunity WHERE Id = :recordId LIMIT 1];

            if (oppList.isEmpty()) {
                wrapperRec.message = 'No Opportunity found for given Id.';
                return wrapperRec;
            }

            Opportunity opp = oppList[0];

            String parentFolderId;
            String docId;
            if (opp.Documents__r != null && !opp.Documents__r.isEmpty()) {
                parentFolderId = opp.Documents__r[0].Document_Id__c;
                docId          = opp.Documents__r[0].Id;
            }

            Digio_Integration__c customData = Digio_Integration__c.getValues('Digio');
            String templateKey = (customData != null) ? customData.Welcome_Letter__c : null;
            system.debug('templateKey::>>' + templateKey);

            if (customData == null || String.isBlank(customData.Authorization__c) || String.isBlank(customData.Endpoint_URL__c) || String.isBlank(templateKey) || String.isBlank(parentFolderId) || String.isBlank(docId)) {
                wrapperRec.message = 'misssing data, please checke ';
                return wrapperRec;
            }

            String endpoint = customData.Endpoint_URL__c + '/v2/client/template/multi_templates/create_sign_request';
            System.debug('endpoint::>>' + endpoint);

            DigioWrapperClass.WelcomeLetterWrapper generateDoc = new DigioWrapperClass.WelcomeLetterWrapper();
            String rawFileName = opp.Name + ' - Welcome Letter ' + String.valueOf(System.now());
            String fileName = rawFileName.length() > 80  ? rawFileName.substring(0, 80) : rawFileName;

            generateDoc.file_name = fileName;

            DigioWrapperClass.signersList signer = new DigioWrapperClass.signersList();
            signer.identifier = 'projects@snnestates.com';
            signer.signer_tag = 'Signer 1';
            signer.name       = 'Snn';
            signer.sign_type  = 'document_review';
            generateDoc.signers = new List<DigioWrapperClass.signersList>{ signer };

            DigioWrapperClass.WelcomeLetterTemplateList tempList = new DigioWrapperClass.WelcomeLetterTemplateList();
            tempList.template_key = templateKey;

            List<String> applicantNames = new List<String>();
            if (opp.Account != null && opp.Account.Full_Name__c != null) {
                applicantNames.add(opp.Account.Full_Name__c);
            }
            if (opp.Applicants__r != null && !opp.Applicants__r.isEmpty()) {
                for (Applicant__c app : opp.Applicants__r) {
                    if (app.Account__r != null && app.Account__r.Full_Name__c != null) {
                        applicantNames.add(app.Account__r.Full_Name__c);
                    }
                }
            }

            String allApplicantDetails = applicantNames.isEmpty() ? '' : String.join(applicantNames, ', ');
            System.debug('allApplicantDetaisl::>>' + allApplicantDetails);

            DigioWrapperClass.WelcomeLetterTemplateValues tempValues = new DigioWrapperClass.WelcomeLetterTemplateValues();
            tempValues.welcomeDate          = System.today().format();
            tempValues.allApplicantDetails  = allApplicantDetails;
            tempValues.unitName             = (opp.Unit__r != null && opp.Unit__r.Unit_Name__c != null) ? opp.Unit__r.Unit_Name__c : '';
            tempValues.towerCode            = (opp.Unit__r != null && opp.Unit__r.Floor__r.Blocks__r.Tower_Code__c != null) ? opp.Unit__r.Floor__r.Blocks__r.Tower_Code__c : '';
            tempValues.projectName          = (opp.Project__r != null && opp.Project__r.Name != null) ? opp.Project__r.Name : '';
            tempValues.companyName          = (opp.Project__r != null && opp.Project__r.Company__c != null) ? opp.Project__r.Company__r.Name : '';
            tempValues.companyAddress       = (opp.Project__r != null && opp.Project__r.Company__c != null) ? opp.Project__r.Company__r.Address__c : '';
            tempValues.companyEmail         = (opp.Project__r != null && opp.Project__r.Company__c != null) ? opp.Project__r.Company__r.Email__c : '';
            tempValues.bookingFormDate      = (opp.Booking_Date__c != null) ? opp.Booking_Date__c.format() : '';
            tempValues.companyPan           = (opp.Project__r != null && opp.Project__r.Company__c != null) ? opp.Project__r.Company__r.PAN_No__c : '';
            tempValues.aosDate              = System.today().format();
            tempValues.projectBankActName   = (opp.Project__r != null && opp.Project__r.Account_Name__c != null) ? opp.Project__r.Account_Name__c : '';
            tempValues.projectAccntNumber   = (opp.Project__r != null && opp.Project__r.Account_Number__c != null) ? opp.Project__r.Account_Number__c : '';
            tempValues.bankType             = (opp.Project__r != null && opp.Project__r.Type_of_Account__c != null) ? opp.Project__r.Type_of_Account__c : '';
            tempValues.bankName             = (opp.Project__r != null && opp.Project__r.Bank_Name__c != null) ? opp.Project__r.Bank_Name__c : '';
            tempValues.bankBranch           = (opp.Project__r != null && opp.Project__r.Branch__c != null) ? opp.Project__r.Branch__c : '';
            tempValues.bankIfsc             = (opp.Project__r != null && opp.Project__r.IFSC_Code__c != null) ? opp.Project__r.IFSC_Code__c : '';
            tempValues.accntName            = (opp.Account != null && opp.Account.Full_Name__c != null) ? opp.Account.Full_Name__c : '';
            tempValues.allotmentDate        = System.today().format();

            tempList.template_values = tempValues;

            // Build table values from custom settings
            List<Legal_Department__c> legalDeptSettings = Legal_Department__c.getAll().values();
            List<Bank_Details__c> bankDetailSettings    = Bank_Details__c.getAll().values();
            system.debug('bankDetailSettings::>>' + bankDetailSettings);

            DigioWrapperClass.WelcomeLetterTableToAdd tableValues = new DigioWrapperClass.WelcomeLetterTableToAdd();

            List<DigioWrapperClass.contactListTableRow> contactRows = new List<DigioWrapperClass.contactListTableRow>();
            for (Legal_Department__c ld : legalDeptSettings) {
                system.debug('getting legaldepartment customsetting');
                DigioWrapperClass.contactListTableRow row = new DigioWrapperClass.contactListTableRow();
                row.deptName   = ld.Name;
                row.csEmailId  = ld.Email_Id__c;
                row.execName   = ld.Executive_Name__c;
                row.cSMobileNo = ld.Mobile_No__c;
                contactRows.add(row);
            }
            tableValues.contactListTable = contactRows;

            List<DigioWrapperClass.bankDetailsRow> bankRows = new List<DigioWrapperClass.bankDetailsRow>();
            for (Bank_Details__c bd : bankDetailSettings) {
                system.debug('getting bankdetails customsetting');
                DigioWrapperClass.bankDetailsRow row = new DigioWrapperClass.bankDetailsRow();
                row.bankNameDetails   = bd.Name;
                row.bankContactPerson = bd.Bank_Contact_Person__c;
                row.bankContacNo     = bd.Bank_Contact_No__c;
                row.bankEmailId       = bd.Bank_Email__c;
                bankRows.add(row);
            }
            tableValues.bankDetailsTable = bankRows;

            tempList.template_table_values = tableValues;

            generateDoc.templates = new List<DigioWrapperClass.WelcomeLetterTemplateList>{ tempList };

            String jsonBody  = Json.serialize(generateDoc);
            system.debug('jsonBody::>>' + jsonBody);
            String digiDocId = digioCalloutUtility.sendHttpRequest('POST', endpoint, customData.Authorization__c, jsonBody);
            wrapperRec.digiDocId = digiDocId;

            if (String.isBlank(digiDocId)) {
                wrapperRec.message = 'Welcome Letter generation failed. Digio Doc Id blank.';
                return wrapperRec;
            }

            Map<String, List<String>> oppIdByContentVersionIds = new Map<String, List<String>>();
            oppIdByContentVersionIds = GoogleDriveAPI.downloadDocument123(digiDocId, fileName, parentFolderId, docId, oppIdByContentVersionIds);

            System.debug('oppIdByContentVersionIds (Welcome Letter) => ' + oppIdByContentVersionIds);

            if (oppIdByContentVersionIds != null && oppIdByContentVersionIds.containsKey(recordId)) {
                List<String> cvIdsStr = oppIdByContentVersionIds.get(recordId);
                List<Id> cvIds = new List<Id>();
                if (cvIdsStr != null) {
                    for (String s : cvIdsStr) {
                        try {
                            cvIds.add((Id)s);
                        } catch (Exception ex) {
                            System.debug('Invalid ContentVersionId in map => ' + s);
                        }
                    }
                }
                wrapperRec.contentVersionIds = cvIds;
                wrapperRec.message = 'Welcome Letter generated successfully.';
            } else {
                wrapperRec.message = 'Welcome Letter generated but ContentVersion creation failed.';
            }

            return wrapperRec;

        } catch (Exception e) {
            System.debug('Error in generateWelcomeLetterDocument ===> ' + e.getMessage());
            System.debug('Error line ===> ' + e.getLineNumber());
            wrapperRec.message = 'Error: ' + e.getMessage();
            return wrapperRec;
        }
    }

    private static void sendWelcomeLetterEmail(Id oppId, List<Id> contentVersionIds) {
        try {
            System.debug('sendWelcomeLetterEmail oppId => ' + oppId);
            System.debug('sendWelcomeLetterEmail contentVersionIds => ' + contentVersionIds);

            Opportunity opp = [SELECT Id, Name, Account.Email__c, Project__r.Name, Welcome_Sent_Date__c FROM Opportunity WHERE Id = :oppId LIMIT 1];
            List<ContentVersion> cvs = [SELECT Id, Title, VersionData, ContentDocumentId FROM ContentVersion WHERE Id IN :contentVersionIds];
            EmailTemplate temp = [SELECT Id, Subject, HtmlValue, Body FROM EmailTemplate WHERE DeveloperName = 'WelcomeLetterPDFEmailTemplate' LIMIT 1];
            OrgWideEmailAddress[] owea = [SELECT Id FROM OrgWideEmailAddress LIMIT 1];

            List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();
            Set<Id> contentDocIdsToDelete = new Set<Id>();

            for (ContentVersion cv : cvs) {
                Messaging.EmailFileAttachment a = new Messaging.EmailFileAttachment();
                a.setFileName(cv.Title + '.pdf');
                a.setBody(cv.VersionData);
                a.setContentType('application/pdf');
                attachments.add(a);

                if (cv.ContentDocumentId != null) contentDocIdsToDelete.add(cv.ContentDocumentId);
            }

            if (opp.Account == null || String.isBlank(opp.Account.Email__c)) {
                System.debug('Account Email is blank. Skipping email send.');
                return;
            }

            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            if (owea != null && !owea.isEmpty()) email.setOrgWideEmailAddressId(owea[0].Id);

            String subject = temp.Subject;
            String htmlBody = temp.HtmlValue.replace('{!Opportunity.Name}', opp.Name);

            email.setSubject(subject);
            email.setToAddresses(new String[]{ opp.Account.Email__c });
            email.setWhatId(opp.Id);
            email.setSaveAsActivity(false);
            email.setHtmlBody(htmlBody);
            email.setFileAttachments(attachments);

            List<Messaging.SendEmailResult> results = Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });
            if (!results.isEmpty() && results[0].isSuccess()) {
                System.debug('Welcome Letter email sent successfully to: ' + opp.Account.Email__c);

                opp.Welcome_Sent_Date__c = System.now();
                update opp;

                if (!contentDocIdsToDelete.isEmpty()) {
                    delete [SELECT Id FROM ContentDocument WHERE Id IN :contentDocIdsToDelete];
                    System.debug('Deleted ContentDocuments => ' + contentDocIdsToDelete);
                }
            } else {
                if (!results.isEmpty()) {
                    for (Messaging.SendEmailError err : results[0].getErrors()) {
                        System.debug('Welcome Letter email failed => ' + err.getMessage());
                    }
                }
            }
        } catch (Exception e) {
            System.debug('Error in sendWelcomeLetterEmail => ' + e.getMessage());
            System.debug('Error line => ' + e.getLineNumber());
        }
    }

    public class docwrpperClass {
        @AuraEnabled public String subDocUrl { get; set; }
        @AuraEnabled public String digiDocId { get; set; }
        @AuraEnabled public String message   { get; set; }
        @AuraEnabled public List<Id> contentVersionIds { get; set; }
    }
}