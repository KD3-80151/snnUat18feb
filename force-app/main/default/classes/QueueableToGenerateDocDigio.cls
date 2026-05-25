public without sharing class QueueableToGenerateDocDigio implements Queueable, Database.allowsCallouts {
    private List<String> rcptIds;
    private static Integer jobCount = 0;
    private static final Integer MAX_JOBS = 5; // Set a reasonable limit
    
    public QueueableToGenerateDocDigio(List<String> rcptIds) {
        this.rcptIds = rcptIds;
    }
    public void execute(QueueableContext context) {
        if(!rcptIds.isEmpty() && jobCount < MAX_JOBS){
            jobCount++; // Increment job count
            System.debug('rcptIds1::'+rcptIds);
            String currentDocId = rcptIds.remove(0);
            System.debug('rcptIds2::'+rcptIds);
            generateSerenityReceipt(currentDocId);
            if(!rcptIds.isEmpty()){
                System.enqueueJob(new QueueableToGenerateDocDigio(rcptIds));
            }
        }
    }
    public void generateSerenityReceipt(String rcptId){
        try{
            System.debug('rcptId=>'+rcptId);
            String parentFolderId;
            String docId;
            String subDocUrl = '';
            Receipt__c receiptRecord = [select id,Name,Receipt_Date__c,Opportunity__r.Project__r.Name,Opportunity__c,Mode_Of_Payment__c,Reference_Number__c,Cheque_Date__c,Bank__c,Opportunity__r.Unit__r.Unit_Type__c,Amount__c,Opportunity__r.Unit__r.Floor__r.Blocks__r.Name,Opportunity__r.Unit__r.Unit_Name__c,Opportunity__r.Unit__r.Name,Opportunity__r.Opportunity_Unique_Id__c   from Receipt__c Where Id =: rcptId Limit 1];
            
            List<Opportunity> oppDetails = [SELECT Id,Name,AccountId,Unit__r.Name,Booking_Date__c,(SELECT Id,Document_Id__c from Documents__r where Name = 'Payment Receipt' LIMIT 1) from Opportunity where Id =: receiptRecord.Opportunity__c LIMIT 1];

            if(!oppDetails.isEmpty() && oppDetails[0].Documents__r != null){
                parentFolderId = oppDetails[0].Documents__r[0].Document_Id__c;

                docId = oppDetails[0].Documents__r[0].Id;
            }

            List<Account> mainAccount = [select id,Name,Permanent_Address__c from Account where Id =: oppDetails[0].AccountId Limit 1];
            Account mainApplicant = mainAccount[0];
            List<Applicant__c> applicantList;
            String firstApplicant = mainApplicant.Name;
            
            
            if(receiptRecord != null && receiptRecord.Opportunity__c != null){
                applicantList = [SELECT Id,Name,Primary_Applicant__c,Permanent_Address__c,Permanent_Address__City__s from Applicant__c where Opportunity__c =: receiptRecord.Opportunity__c];
            }
            
            
            List<String> coApplicantList = new List<String>();
            if(!applicantList.isEmpty()){
                for(Applicant__c app : applicantList){
                    if(app.Name != null){
                        coApplicantList.add(app.Name);
                    }
                }
            }
            String coApplicantString = String.join(coApplicantList, ',');
            System.debug('firstApplicant==>'+firstApplicant);
            Digio_Integration__c customData = Digio_Integration__c.getValues('Digio');
            System.debug('customData::'+customData);
            if(firstApplicant != null && customData.Authorization__c != null && customData.Endpoint_URL__c != null){
                
                String endpoint = customData.Endpoint_URL__c + '/v2/client/template/multi_templates/create_sign_request';
                System.debug('endpoint ===> ' + endpoint);
                
                DigioWrapperClass.generateReceipt generateDoc = new DigioWrapperClass.generateReceipt();
                
                Datetime now = System.now();
                String formattedTimestamp = now.format('yyyy-MM-dd HH:mm:ss');
                System.debug('Formatted Timestamp: ' + formattedTimestamp);
                
                String fileName = 'Serenity Receipt - '+ formattedTimestamp;
                generateDoc.file_name = fileName;
                
                DigioWrapperClass.signersList signer = new DigioWrapperClass.signersList();
                signer.identifier = 'projects@snnestates.com';
                signer.signer_tag = 'Signer 1';
                signer.name = 'Snn';
                signer.sign_type = 'document_review';
                
                generateDoc.signers = new List<DigioWrapperClass.signersList>{signer};
                
                DigioWrapperClass.serenityReceiptTemplateList tempList = new DigioWrapperClass.serenityReceiptTemplateList();
                tempList.template_key = customData.Serenity_Receipt_Template_Key__c; //TMP2412121651067607C3XTHJDCVKUGX
                
                DigioWrapperClass.serenityReceiptTemplateValues templateVariables = new DigioWrapperClass.serenityReceiptTemplateValues();
                templateVariables.receiptNo             = receiptRecord.Name != null ? receiptRecord.Name : '';
                templateVariables.receiptDate           = receiptRecord.Receipt_Date__c != null ? String.valueOf(receiptRecord.Receipt_Date__c) : '';
                templateVariables.projectName           = receiptRecord.Opportunity__r.Project__r.Name != null ? receiptRecord.Opportunity__r.Project__r.Name : '';
                templateVariables.customerName          = firstApplicant != null ? firstApplicant : '';
                templateVariables.coApplicantName       = coApplicantList != null && !coApplicantList.isEmpty() ? String.join(coApplicantList, ', '): '';
                templateVariables.amountInWords         = 'Rupees Two Hundred Twenty Only';
                templateVariables.modeOfPayment         = receiptRecord.Mode_Of_Payment__c != null ? receiptRecord.Mode_Of_Payment__c : '';
                templateVariables.referenceNo           = receiptRecord.Reference_Number__c != null ? receiptRecord.Reference_Number__c : '';
                templateVariables.chequeDate            = receiptRecord.Cheque_Date__c != null ? String.valueOf(receiptRecord.Cheque_Date__c) : '';
                templateVariables.bankName              = receiptRecord.Bank__c != null ? receiptRecord.Bank__c : '';
                templateVariables.typeOfUnit            = receiptRecord.Opportunity__r.Unit__r.Unit_Type__c != null ? receiptRecord.Opportunity__r.Unit__r.Unit_Type__c : '';
                templateVariables.flatNo                =   receiptRecord.Opportunity__r.Unit__r.Name != null ? receiptRecord.Opportunity__r.Unit__r.Name : '';
                templateVariables.unitNo                = receiptRecord.Opportunity__r.Unit__r.Unit_Name__c != null ? receiptRecord.Opportunity__r.Unit__r.Unit_Name__c : '';
                templateVariables.blockName             = receiptRecord.Opportunity__r.Unit__r.Unit_Type__c != null ? receiptRecord.Opportunity__r.Unit__r.Unit_Type__c : '';
                templateVariables.amountValues          =  receiptRecord.Amount__c != null  ? String.valueOf(receiptRecord.Amount__c) : '';
                templateVariables.loginUserName         = UserInfo.getName();
                
                if (mainApplicant.Permanent_Address__c != null) {
                    System.Address address = mainApplicant.Permanent_Address__c;
                    templateVariables.clientAddress =
                        (address.getStreet() != null ? address.getStreet() + ', ' : '') +
                        (address.getCity() != null ? address.getCity() + ', ' : '') +
                        (address.getState() != null ? address.getState() + ', ' : '') +
                        (address.getCountry() != null ? address.getCountry() + ', ' : '') +
                        (address.getPostalCode() != null ? address.getPostalCode() : '');
                    
                    templateVariables.clientAddress = templateVariables.clientAddress.trim().endsWith(',')
                        ? templateVariables.clientAddress.substring(0, templateVariables.clientAddress.length() - 1)
                        : templateVariables.clientAddress;
                } else {
                    templateVariables.clientAddress = '';
                }
                
                tempList.template_values = templateVariables;
                generateDoc.templates = new List<DigioWrapperClass.serenityReceiptTemplateList>{tempList};
                system.debug('generateDoc ===> ' + generateDoc);
                system.debug('serialize json ===> ' + Json.serialize(generateDoc));
                String jsonBody = Json.serialize(generateDoc);
                String authorizationValue = 'Basic' + ' ' +EncodingUtil.base64Encode(Blob.valueOf(customData.Client_ID__c + ':' + customData.Client_Secret__c));
                System.debug('authorizationValue==>'+authorizationValue);
                
                String digiDocId = sendHttpRequest('POST', endpoint, authorizationValue, jsonBody);
                System.debug('digiDocId==>'+digiDocId);
                System.debug('fileName==>'+fileName);
                if(digiDocId != null && fileName != null){
                    // subDocUrl = digioCalloutUtility.downloadDocument(digiDocId, fileName, parentFolderId, docId);
                    // System.debug('subDocUrl ===> ' + subDocUrl);
                    if (customData.Endpoint_URL__c != null) {
                        // Construct the endpoint2 URL
                        String endpoint2 = customData.Endpoint_URL__c + '/v2/client/document/download?document_id=' + digiDocId;
                        System.debug('endpoint2 ===> ' + endpoint2);
                        
                        HTTP http = new HTTP();
                        HttpRequest req = new HttpRequest();
                        req.setMethod('GET');
                        req.setEndpoint(endpoint2);
                        req.setHeader('Authorization', customData.Authorization__c);
                        req.setHeader('Content-Type', 'application/json');
                        
                        HttpResponse res = http.send(req);
                        Blob responseBlob = res.getBodyAsBlob();
                        System.debug('responseBlob ==> ' + responseBlob);
                        downloadDigioDocWithoutGDrive(responseBlob,receiptRecord.Opportunity__c,'VettedReceipt');
                    }
                }
            }
        }catch(Exception e){
            system.debug('Error in generateDemandLetterDocument===> ' + e.getMessage());
            system.debug('Error line ===> ' + e.getLineNumber());
        }
    }
    public static String sendHttpRequest(String httpMethod, String endpoint, String authorizationCode, String jsonBody){
        try{
            HTTP http = new HTTP();
            HttpRequest req = new HttpRequest();
            req.setMethod(httpMethod);
            req.setEndpoint(endpoint);
            req.setHeader('Authorization', authorizationCode);
            req.setHeader('Content-Type', 'application/json');
            req.setBody(jsonBody);

            System.debug('req==>'+req);
            
            HttpResponse res = http.send(req);
            String responseBody = res.getBody();
            System.debug('responseBody ===> ' + responseBody);
            
            Map<String,Object> responseMap = (Map<String,Object>) JSON.deserializeUntyped(res.getBody());
            System.debug('responseMap==>'+responseMap);
            if(responseMap != null && responseMap.containsKey('id')){
                String digiDocId = responseMap.get('id') != null ? (String)responseMap.get('id') : null;
                System.debug('digiDocId ===> ' + digiDocId);
                return digiDocId;
            }
            return null;
        }catch(Exception e){
            System.debug('Error ===> ' + e.getMessage());
            System.debug('line ===> ' + e.getLineNumber());
            return null;
        }
    }
    public static void downloadDigioDocWithoutGDrive(Blob responseBlob, Id opportunityId, String docName) {
        // Retrieve custom data
        // Digio_Integration__c customData = Digio_Integration__c.getValues('Digio');
        // if (customData.Endpoint_URL__c != null && digiDocId != null) {
        //     // Construct the endpoint URL
        //     String endpoint = customData.Endpoint_URL__c + '/v2/client/document/download?document_id=' + digiDocId;
        //     System.debug('endpoint ===> ' + endpoint);
            
        //     HTTP http = new HTTP();
        //     HttpRequest req = new HttpRequest();
        //     req.setMethod('GET');
        //     req.setEndpoint(endpoint);
        //     req.setHeader('Authorization', customData.Authorization__c);
        //     req.setHeader('Content-Type', 'application/json');
            
        //     HttpResponse res = http.send(req);
        System.debug('responseBlob ==> ' + responseBlob);
        
        // Query Opportunity and associated Account email
        Opportunity opp = [SELECT Id, Name, AccountId,Account.Name, Account.Email__c FROM Opportunity WHERE Id = :opportunityId LIMIT 1];
        if (opp.Account.Email__c == null) {
            System.debug('No email found for the Opportunity Account.');
            return;
        }

        // Query the email template
        system.debug('docName'+docName);
        EmailTemplate template ;
        if( docName != null && docName == 'CostSheetDoc'){
            system.debug('docName'+docName);
            template = [SELECT Id, Subject, HtmlValue, Body, DeveloperName FROM EmailTemplate WHERE DeveloperName = 'CostsheetPDFEmailTemplate' LIMIT 1];

            if (template == null || template.Body == null || template.HtmlValue == null || template.Subject == null) {
                System.debug('Email template or its content is null.');
                return;
            }

        } else if ( docName != null && docName == 'AllotmentLetter'){
            system.debug('docName'+docName);
            template = [SELECT Id, Subject, HtmlValue, Body, DeveloperName FROM EmailTemplate WHERE DeveloperName = 'AllotmentLetterPDFEmailTemplate' LIMIT 1];

            if (template == null || template.Body == null || template.HtmlValue == null || template.Subject == null) {
                System.debug('Email template or its content is null.');
                return;
            }

        }else if ( docName != null && docName == 'DemandLetter'){
            system.debug('docName'+docName);
            template = [SELECT Id, Subject, HtmlValue, Body, DeveloperName FROM EmailTemplate WHERE DeveloperName = 'DemandLetterPDFEmailTemplate' LIMIT 1];

            if (template == null || template.Body == null || template.HtmlValue == null || template.Subject == null) {
                System.debug('Email template or its content is null.');
                return;
            } 
        }  else if ( docName != null && docName == 'StatementOfAccounts'){
            system.debug('docName'+docName);
            template = [SELECT Id, Subject, HtmlValue, Body, DeveloperName FROM EmailTemplate WHERE DeveloperName = 'StatementOfAccountsPDFEmailTemplate' LIMIT 1];

            if (template == null || template.Body == null || template.HtmlValue == null || template.Subject == null) {
                System.debug('Email template or its content is null.');
                return;
            } 
        }  
        else if ( docName != null && docName == 'SalesAgreement'){
            system.debug('docName'+docName);
            template = [SELECT Id, Subject, HtmlValue, Body, DeveloperName FROM EmailTemplate WHERE DeveloperName = 'SalesAgreementPDFEmailTemplate' LIMIT 1];

            if (template == null || template.Body == null || template.HtmlValue == null || template.Subject == null) {
                System.debug('Email template or its content is null.');
                return;
            } 
        }  
        else if ( docName != null && docName == 'SNNHomeOwner'){
            system.debug('docName'+docName);
            template = [SELECT Id, Subject, HtmlValue, Body, DeveloperName FROM EmailTemplate WHERE DeveloperName = 'SNNHomeOwnerPDFEmailTemplate' LIMIT 1];

            if (template == null || template.Body == null || template.HtmlValue == null || template.Subject == null) {
                System.debug('Email template or its content is null.');
                return;
            } 
        }  
        else if ( docName != null && docName == 'MoveInMoveOutDocument'){
            system.debug('docName'+docName);
            template = [SELECT Id, Subject, HtmlValue, Body, DeveloperName FROM EmailTemplate WHERE DeveloperName = 'MoveInMoveOutDocumentPDFEmailTemplate' LIMIT 1];

            if (template == null || template.Body == null || template.HtmlValue == null || template.Subject == null) {
                System.debug('Email template or its content is null.');
                return;
            } 
        } 
        else if ( docName != null && docName == 'GeneratePartyHall'){
            system.debug('docName'+docName);
            template = [SELECT Id, Subject, HtmlValue, Body, DeveloperName FROM EmailTemplate WHERE DeveloperName = 'GeneratePartyHallPDFEmailTemplate' LIMIT 1];

            if (template == null || template.Body == null || template.HtmlValue == null || template.Subject == null) {
                System.debug('Email template or its content is null.');
                return;
            } 
        }  
        else if ( docName != null && docName == 'GenerateVehiclePark'){
            system.debug('docName'+docName);
            template = [SELECT Id, Subject, HtmlValue, Body, DeveloperName FROM EmailTemplate WHERE DeveloperName = 'GenerateVehicleParkPDFEmailTemplate' LIMIT 1];

            if (template == null || template.Body == null || template.HtmlValue == null || template.Subject == null) {
                System.debug('Email template or its content is null.');
                return;
            } 
        }  
        else if ( docName != null && docName == 'Serviceprovider'){
            system.debug('docName'+docName);
            template = [SELECT Id, Subject, HtmlValue, Body, DeveloperName FROM EmailTemplate WHERE DeveloperName = 'ServiceproviderPDFEmailTemplate' LIMIT 1];

            if (template == null || template.Body == null || template.HtmlValue == null || template.Subject == null) {
                System.debug('Email template or its content is null.');
                return;
            } 
        }   
        else if ( docName != null && docName == 'GenerateWelcomKit'){
            system.debug('docName'+docName);
            template = [SELECT Id, Subject, HtmlValue, Body, DeveloperName FROM EmailTemplate WHERE DeveloperName = 'GenerateWelcomKitPDFEmailTemplate' LIMIT 1];

            if (template == null || template.Body == null || template.HtmlValue == null || template.Subject == null) {
                System.debug('Email template or its content is null.');
                return;
            } 
        }
        else if ( docName != null && docName == 'HandOverFormate'){
            system.debug('docName'+docName);
            template = [SELECT Id, Subject, HtmlValue, Body, DeveloperName FROM EmailTemplate WHERE DeveloperName = 'HandOverFormatePDFEmailTemplate' LIMIT 1];

            if (template == null || template.Body == null || template.HtmlValue == null || template.Subject == null) {
                System.debug('Email template or its content is null.');
                return;
            } 
        }
        else if ( docName != null && docName == 'VettedReceipt'){
            system.debug('docName'+docName);
            template = [SELECT Id, Subject, HtmlValue, Body, DeveloperName FROM EmailTemplate WHERE DeveloperName = 'VettedReceiptDocumentPDFEmailTemplate' LIMIT 1];

            if (template == null || template.Body == null || template.HtmlValue == null || template.Subject == null) {
                System.debug('Email template or its content is null.');
                return;
            } 
        }
        // Ensure template is not null and retrieve template content
        

        String plainTextBody = template.Body; // Retrieve plain text content
        String htmlBody = template.HtmlValue; // Retrieve HTML content
        String subjectBody = template.Subject; // Retrieve subject line

        // Perform placeholder replacements
        if (opp.Name != null && opp.Account.Name != null) {
            System.debug('opp.Name ===> ' + opp.Name);
            plainTextBody = plainTextBody.replace('{!Opportunity.Name}', opp.Name);
            htmlBody = htmlBody.replace('{!Opportunity.Name}', opp.Name);
            plainTextBody = plainTextBody.replace('{!Opportunity.Account}', opp.Account.Name);
            htmlBody = htmlBody.replace('{!Opportunity.Account}', opp.Account.Name);
        }

        // Create the email message
        Messaging.SingleEmailMessage mailTemp = new Messaging.SingleEmailMessage();
        mailTemp.setHtmlBody(htmlBody);
        mailTemp.setSubject(subjectBody);
        mailTemp.setPlainTextBody(plainTextBody);
        mailTemp.setToAddresses(new String[] { opp.Account.Email__c });

        // Create the attachment
        Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
        attachment.setFileName(docName + '.pdf'); // Use docName as the file name
        attachment.setBody(responseBlob); // Blob content for the attachment
        mailTemp.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment });

        // Send the email
        List<Messaging.SingleEmailMessage> mailList = new List<Messaging.SingleEmailMessage> { mailTemp };
        Messaging.sendEmail(mailList);
        System.debug('Email sent successfully with attachment to ' + opp.Account.Email__c);
    }
}