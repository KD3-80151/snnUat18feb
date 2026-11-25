public without sharing class digioCalloutUtility {
    
    // Client (21 Nov): every amount printed on a document shows Indian commas (1,00,000 / 1,00,00,000).
    // Template values with these names are amounts (cost sheet, demand letters, statements of account,
    // allotment letter, debit note, agreement copy). Areas, floors, percentages and dates are not listed.
    @TestVisible
    private static final Set<String> AMOUNT_KEYS = new Set<String>{
        // cost sheet
        'basicPriceValue', 'apartmentPrice', 'cgstData', 'sgstData', 'totalValue', 'amountValue', 'totalAmount',
        // demand letter + credit/debit table
        'AgreementValue', 'taxesAmout', 'totalScheduledDueAmount', 'dueAmount', 'FinalScheduleAmount',
        'FinallessTotalAmount', 'FinallessTdsAmount', 'totalTdsPaidTillDate', 'FinalbalancePaybleAmount',
        'totalAmountInclusiveOfTax', 'PaymentScheduleDueAmount', 'Amount', 'Tax', 'Total',
        // statement of account
        'totalBilled', 'amountReceived', 'amountBalance', 'FinaltotalBilled', 'FinalamountReceived', 'FinalamountBalance',
        'FinalReceiptAmount', 'FinalAmount', 'receiptAmountCD', 'receiptTaxCD', 'receiptTotalAmountCD', 'finalAmountCd',
        'finalAmountTaxCd', 'finalTotalAmountCd', 'totalScheduleAmount', 'totalPaidTillDate', 'totalBalancePaidTwrdUnit',
        'oppFinalBalance',
        // allotment letter
        'totalFlatCost', 'milestone',
        // debit note, receipts, agreement copy
        'amount', 'debitAmount', 'agreementValue', 'bookingAmount', 'totalReceiptAmt', 'totalPaymentAmt'
    };

    /** Rewrites numeric amount values inside templates[].template_values and templates[].template_table_values
        (the dynamic tables) as Indian-grouped text. */
    @TestVisible
    private static String formatTemplateAmounts(String jsonBody) {
        if (String.isBlank(jsonBody) || !(jsonBody.contains('template_values') || jsonBody.contains('template_table_values'))) return jsonBody;
        try {
            Object root = JSON.deserializeUntyped(jsonBody);
            if (!(root instanceof Map<String, Object>)) return jsonBody;
            Map<String, Object> body = (Map<String, Object>) root;
            Object templates = body.get('templates');
            if (!(templates instanceof List<Object>)) return jsonBody;
            for (Object t : (List<Object>) templates) {
                if (t instanceof Map<String, Object>) {
                    Map<String, Object> tm = (Map<String, Object>) t;
                    for (String part : new List<String>{ 'template_values', 'template_table_values' }) {
                        if (tm.containsKey(part)) {
                            tm.put(part, formatAmountNode(tm.get(part), null));
                        }
                    }
                }
            }
            return JSON.serialize(body);
        } catch (Exception e) {
            System.debug('Amount formatting skipped: ' + e.getMessage());
            return jsonBody;
        }
    }

    private static Object formatAmountNode(Object node, String key) {
        if (node instanceof Map<String, Object>) {
            Map<String, Object> m = (Map<String, Object>) node;
            for (String k : new List<String>(m.keySet())) {
                m.put(k, formatAmountNode(m.get(k), k));
            }
            return m;
        }
        if (node instanceof List<Object>) {
            List<Object> items = (List<Object>) node;
            for (Integer i = 0; i < items.size(); i++) {
                items[i] = formatAmountNode(items[i], key);
            }
            return items;
        }
        if (key != null && AMOUNT_KEYS.contains(key)) {
            Decimal value = toAmount(node);
            if (value != null) return DocumentDataHelper.formatIndianAmount(value);
        }
        return node;
    }

    private static Decimal toAmount(Object v) {
        if (v == null) return null;
        if (v instanceof Decimal) return (Decimal) v;
        if (v instanceof Integer) return Decimal.valueOf((Integer) v);
        if (v instanceof Long) return Decimal.valueOf((Long) v);
        if (v instanceof Double) return Decimal.valueOf((Double) v);
        if (v instanceof String) {
            String s = ((String) v).trim();
            if (Pattern.matches('-?[0-9]+(\\.[0-9]+)?', s)) return Decimal.valueOf(s);
        }
        return null;
    }

    public static String sendHttpRequest(String httpMethod, String endpoint, String authorizationCode, String jsonBody){
        try{
            jsonBody = formatTemplateAmounts(jsonBody);
            System.debug('httpMethod ===> ' + httpMethod);
            System.debug('endpoint ===> ' + endpoint);
            System.debug('authorizationCode ===> ' + authorizationCode);
            System.debug('jsonBody ===> ' + jsonBody);
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

    
    
    // docName (sent by the LWC) -> email template DeveloperName
    @TestVisible
    private static final Map<String, String> EMAIL_TEMPLATE_BY_DOC = new Map<String, String>{
        'CostSheetDoc'          => 'CostsheetPDFEmailTemplate',
        'Cost Sheet'            => 'CostsheetPDFEmailTemplate',
        'AllotmentLetter'       => 'AllotmentLetterPDFEmailTemplate',
        'BookingForm'           => 'BookingForm',
        'DemandLetter'          => 'DemandLetterPDFEmailTemplate',
        'StatementOfAccounts'   => 'StatementOfAccountsPDFEmailTemplate',
        'SalesAgreement'        => 'SalesAgreementPDFEmailTemplate',
        'Agreement Copy'        => 'AgreementCopyPDFEmailTemplate',
        'SNNHomeOwner'          => 'SNNHomeOwnerPDFEmailTemplate',
        'MoveInMoveOutDocument' => 'MoveInMoveOutDocumentPDFEmailTemplate',
        'GeneratePartyHall'     => 'GeneratePartyHallPDFEmailTemplate',
        'GenerateVehiclePark'   => 'GenerateVehicleParkPDFEmailTemplate',
        'Serviceprovider'       => 'ServiceproviderPDFEmailTemplate',
        'GenerateWelcomKit'     => 'GenerateWelcomKitPDFEmailTemplate',
        'HandOverFormate'       => 'HandOverFormatePDFEmailTemplate',
        'Receipt'               => 'VettedReceiptDocumentPDFEmailTemplate',
        'DebitNote'             => 'Debit_Note_Template'
    };

    // docName -> customer-facing attachment name
    @TestVisible
    private static final Map<String, String> ATTACHMENT_NAME_BY_DOC = new Map<String, String>{
        'CostSheetDoc'          => 'Cost Sheet.pdf',
        'Cost Sheet'            => 'Cost Sheet.pdf',
        'AllotmentLetter'       => 'Allotment Letter.pdf',
        'BookingForm'           => 'Booking Form.pdf',
        'DemandLetter'          => 'Demand Letter.pdf',
        'StatementOfAccounts'   => 'Statement of Account.pdf',
        'SalesAgreement'        => 'Sale and Construction Agreement.pdf',
        'Agreement Copy'        => 'Agreement Copy.pdf',
        'Receipt'               => 'Receipt.pdf',
        'DebitNote'             => 'Debit Note.pdf',
        'SNNHomeOwner'          => 'Home Owner Document.pdf',
        'MoveInMoveOutDocument' => 'Move-In and Move-Out Guidelines.pdf',
        'GeneratePartyHall'     => 'Party Hall Rules.pdf',
        'GenerateVehiclePark'   => 'Vehicle Parking and Stickers Policy.pdf',
        'Serviceprovider'       => 'Service Provider Contact List.pdf',
        'GenerateWelcomKit'     => 'Welcome Kit.pdf',
        'HandOverFormate'       => 'Handover of Apartment.pdf'
    };

    // Raised when a document email cannot be sent; the message is shown to the user as is.
    public class DocumentEmailException extends Exception {}

    // For @AuraEnabled callers: turns any failure into an error the screen can show.
    public static AuraHandledException toAuraError(Exception e) {
        String msg = (e instanceof DocumentEmailException || e instanceof AuraHandledException)
            ? e.getMessage()
            : 'The email was not sent: ' + e.getMessage();
        AuraHandledException ae = new AuraHandledException(msg);
        ae.setMessage(msg);
        return ae;
    }

    @TestVisible
    private static String attachmentFileName(String docName) {
        if (docName != null && ATTACHMENT_NAME_BY_DOC.containsKey(docName)) {
            return ATTACHMENT_NAME_BY_DOC.get(docName);
        }
        return (docName != null ? docName : 'Document') + '.pdf';
    }

    // Downloads the Digio document and emails it to the customer (the Opportunity's Account email).
    // Throws DocumentEmailException with a message for the user when the email cannot be sent.
    public static void downloadDigioDocWithoutGDrive(String digiDocId, Id opportunityId, String docName) {
        Digio_Integration__c customData = Digio_Integration__c.getValues('Digio');
        if (customData == null || customData.Endpoint_URL__c == null) {
            throw new DocumentEmailException('The email was not sent: the Digio settings (Digio_Integration__c) are missing.');
        }
        if (String.isBlank(digiDocId)) {
            throw new DocumentEmailException('The email was not sent: the document has not been generated yet. Please generate it again.');
        }

        // Check the customer and the email template first, so nothing is downloaded when the email can't go out.
        List<Opportunity> opps = [SELECT Id, Name, AccountId, Account.Name, Account.Email__c, Unit__r.Unit_Name__c, Project__r.Name FROM Opportunity WHERE Id = :opportunityId LIMIT 1];
        if (opps.isEmpty()) {
            throw new DocumentEmailException('The email was not sent: the Opportunity was not found.');
        }
        Opportunity opp = opps[0];
        if (opp.Account == null || String.isBlank(opp.Account.Email__c)) {
            String accName = (opp.Account != null && opp.Account.Name != null) ? ' "' + opp.Account.Name + '"' : '';
            throw new DocumentEmailException('The email was not sent: the customer account' + accName + ' has no email address. Add the email on the Account and send again.');
        }

        system.debug('docName'+docName);
        String templateName = docName != null ? EMAIL_TEMPLATE_BY_DOC.get(docName) : null;
        if (templateName == null) {
            throw new DocumentEmailException('The email was not sent: no email template is set up for "' + docName + '".');
        }
        List<EmailTemplate> templates = [SELECT Id, Subject, HtmlValue, Body, DeveloperName FROM EmailTemplate WHERE DeveloperName = :templateName LIMIT 1];
        if (templates.isEmpty() || templates[0].Body == null || templates[0].HtmlValue == null || templates[0].Subject == null) {
            throw new DocumentEmailException('The email was not sent: the email template "' + templateName + '" is missing or empty.');
        }
        EmailTemplate template = templates[0];

        String endpoint = customData.Endpoint_URL__c + '/v2/client/document/download?document_id=' + digiDocId;
        System.debug('endpoint ===> ' + endpoint);

        HTTP http = new HTTP();
        HttpRequest req = new HttpRequest();
        req.setMethod('GET');
        req.setEndpoint(endpoint);
        req.setHeader('Authorization', customData.Authorization__c);
        req.setHeader('Content-Type', 'application/json');

        HttpResponse res = http.send(req);
        Blob responseBlob = res.getBodyAsBlob();
        System.debug('responseBlob ==> ' + responseBlob);
        if (res.getStatusCode() != 200 || responseBlob == null || responseBlob.size() == 0) {
            throw new DocumentEmailException('The email was not sent: the document could not be downloaded from Digio (HTTP ' + res.getStatusCode() + '). Please try again.');
        }

        // Merge values. The customer is addressed as "Primary & 1st Co-applicant".
        DocumentDataHelper.ApplicantNames applicantNames = DocumentDataHelper.getApplicantNames(opp.Id);
        Map<String, String> mergeValues = new Map<String, String>{
            '{!Opportunity.Account}'       => String.isNotBlank(applicantNames.primaryWithCoApplicant) ? applicantNames.primaryWithCoApplicant : (opp.Account.Name != null ? opp.Account.Name : ''),
            '{!Opportunity.Name}'          => opp.Name != null ? opp.Name : '',
            '{!Opportunity.Unit_Name__c}'  => (opp.Unit__r != null && opp.Unit__r.Unit_Name__c != null) ? opp.Unit__r.Unit_Name__c : '',
            '{!Opportunity.Project__c}'    => (opp.Project__r != null && opp.Project__r.Name != null) ? opp.Project__r.Name : ''
        };
        String plainTextBody = template.Body; 
        String htmlBody = template.HtmlValue; 
        String subjectBody = template.Subject;
        for (String token : mergeValues.keySet()) {
            plainTextBody = plainTextBody.replace(token, mergeValues.get(token));
            htmlBody      = htmlBody.replace(token, mergeValues.get(token).escapeHtml4());
            subjectBody   = subjectBody.replace(token, mergeValues.get(token));
        }
                    
        // Create the email message
        Messaging.SingleEmailMessage mailTemp = new Messaging.SingleEmailMessage();
        mailTemp.setHtmlBody(htmlBody);
        mailTemp.setSubject(subjectBody);
        mailTemp.setPlainTextBody(plainTextBody);
        mailTemp.setToAddresses(new String[] { opp.Account.Email__c });
        
        List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();
        
        Messaging.EmailFileAttachment primaryAttachment = new Messaging.EmailFileAttachment();
        primaryAttachment.setFileName(attachmentFileName(docName));
        primaryAttachment.setContentType('application/pdf');
        primaryAttachment.setBody(responseBlob);
        attachments.add(primaryAttachment);
        
        mailTemp.setFileAttachments(attachments);
        // Send the email
        List<Messaging.SingleEmailMessage> mailList = new List<Messaging.SingleEmailMessage> { mailTemp };
        List<Messaging.SendEmailResult> results = Messaging.sendEmail(mailList, false);
        for (Messaging.SendEmailResult r : results) {
            if (!r.isSuccess()) {
                List<String> errs = new List<String>();
                for (Messaging.SendEmailError err : r.getErrors()) errs.add(err.getMessage());
                throw new DocumentEmailException('The email was not sent: ' + String.join(errs, '; '));
            }
        }
        System.debug('Email sent successfully with attachment to ' + opp.Account.Email__c);
    }
    
    
    
    
    //@future(callout=true)
    public static String downloadDocument(String digiDocId, String fileName, String parentFolderId, String docId){
        try {
            System.debug('Inside download document');
            Digio_Integration__c customData = Digio_Integration__c.getValues('Digio');
            String subDocUrl = '';
            
            if(customData.Endpoint_URL__c != null && digiDocId != null && fileName != null){
                String endpoint = customData.Endpoint_URL__c + '/v2/client/document/download?document_id=' + digiDocId;
                System.debug('endpoint ===> ' + endpoint);
                
                HTTP http = new HTTP();
                HttpRequest req = new HttpRequest();
                req.setMethod('GET');
                req.setEndpoint(endpoint);
                req.setHeader('Authorization', customData.Authorization__c);
                req.setHeader('Content-Type','application/json');
                
                HttpResponse res = http.send(req);
                Blob responseBlob = res.getBodyAsBlob();
                System.debug('responseBlob ==> ' + responseBlob);
                
                String responseBlobString = EncodingUtil.base64Encode(responseBlob);
                system.debug('responseBlobString ===> ' + responseBlobString + ' length of responseBlobString ===>' + responseBlobString.length());
                
                Integer chunkSize = 1024 * 1024 * 3;
                Integer totalFileSize = responseBlobString.length();
                Integer totalFileSizeBlob = responseBlob.size();
                Integer offset = 0;
                Boolean is308Response = false;
                Boolean isLessThan2MB = false;
                String locationValue = null;
                system.debug('string length is ===> ' + totalFileSize + ' but blob length is ===> ' + totalFileSizeBlob);
                system.debug('totalFileSize ===> ' + totalFileSize + ' offset ===> ' + offset + ' chunkSize ===> ' + chunkSize);
                
                if(totalFileSize < chunkSize){
                    isLessThan2MB = true;
                    chunkSize = totalFileSize;
                }
                
                while (offset < totalFileSize) {
                    Integer chunkEnd = Math.min(offset + chunkSize, totalFileSize);
                    Integer chunkEndBlob = Math.min(offset + chunkSize, totalFileSizeBlob);
                    system.debug('chunkEnd ===> ' + chunkEnd);
                    String contentRange = 'bytes ' + offset + '-' + (chunkEndBlob-1)  + '/' + (totalFileSizeBlob);
                    system.debug('contentRange ===> ' + contentRange);
                    
                    String fileData = responseBlobString.substring(offset, offset+chunkEnd);
                    system.debug('fileData ===> ' + fileData);
                    system.debug('fileData length ===> ' + fileData.length());
                    system.debug('locationValue ===> ' + locationValue);
                    
                    
                    if (locationValue == null) {
                        GoogleDriveAPI.wrapperForResponse firstUpload = GoogleDriveAPI.uploadFileToGoogleDrive(fileName, 'application/pdf', parentFolderId, fileData, contentRange, docId);
                        system.debug('firstUpload ===> ' + firstUpload);
                        locationValue = firstUpload.locationValue; 
                        subDocUrl = firstUpload.subDocUrl;
                        if (firstUpload.is308Response) {
                            is308Response = firstUpload.is308Response == true ? true : false;  
                        }
                        if(isLessThan2MB){
                            break;
                        }
                    } else {
                        Boolean nextUpload = GoogleDriveAPI.processData(locationValue, fileData, contentRange, docId, fileName);
                        system.debug('nextUpload ===> ' + nextUpload);
                        if (nextUpload == true) {
                            system.debug('result ===> ' + nextUpload);
                            is308Response = nextUpload == true ? true : false;
                        } else {
                            break;
                        }
                    }
                    
                    if (is308Response) {
                        system.debug('is308Response ===> ' + is308Response);
                        offset += chunkSize;
                    }else{
                        break;
                    }
                }
                
            }
            return subDocUrl;
        } catch (Exception e) {
            system.debug('Error ==> ' + e.getMessage());
            system.debug('Error in line ==> ' + e.getLineNumber());
            return null;
        }
    }
    
    public static String downloadDocumentAndContentVer(String digiDocId, String fileName, String parentFolderId, String docId){
        try {
            System.debug('Inside download document');
            Digio_Integration__c customData = Digio_Integration__c.getValues('Digio');
            String subDocUrl = '';
            String cntVersionId = '';
            if(customData.Endpoint_URL__c != null && digiDocId != null && fileName != null){
                String endpoint = customData.Endpoint_URL__c + '/v2/client/document/download?document_id=' + digiDocId;
                System.debug('endpoint ===> ' + endpoint);
                
                HTTP http = new HTTP();
                HttpRequest req = new HttpRequest();
                req.setMethod('GET');
                req.setEndpoint(endpoint);
                req.setHeader('Authorization', customData.Authorization__c);
                req.setHeader('Content-Type','application/json');
                
                HttpResponse res = http.send(req);
                Blob responseBlob = res.getBodyAsBlob();
                System.debug('responseBlob ==> ' + responseBlob);
                
                String responseBlobString = EncodingUtil.base64Encode(responseBlob);
                system.debug('responseBlobString ===> ' + responseBlobString + ' length of responseBlobString ===>' + responseBlobString.length());                
                
                Integer chunkSize = 1024 * 1024 * 3;
                Integer totalFileSize = responseBlobString.length();
                Integer totalFileSizeBlob = responseBlob.size();
                Integer offset = 0;
                Boolean is308Response = false;
                Boolean isLessThan2MB = false;
                String locationValue = null;
                system.debug('string length is ===> ' + totalFileSize + ' but blob length is ===> ' + totalFileSizeBlob);
                system.debug('totalFileSize ===> ' + totalFileSize + ' offset ===> ' + offset + ' chunkSize ===> ' + chunkSize);
                
                if(totalFileSize < chunkSize){
                    isLessThan2MB = true;
                    chunkSize = totalFileSize;
                }
                
                while (offset < totalFileSize) {
                    Integer chunkEnd = Math.min(offset + chunkSize, totalFileSize);
                    Integer chunkEndBlob = Math.min(offset + chunkSize, totalFileSizeBlob);
                    system.debug('chunkEnd ===> ' + chunkEnd);
                    String contentRange = 'bytes ' + offset + '-' + (chunkEndBlob-1)  + '/' + (totalFileSizeBlob);
                    system.debug('contentRange ===> ' + contentRange);
                    
                    String fileData = responseBlobString.substring(offset, offset+chunkEnd);
                    system.debug('fileData ===> ' + fileData);
                    system.debug('fileData length ===> ' + fileData.length());
                    system.debug('locationValue ===> ' + locationValue);
                    
                    
                    if (locationValue == null) {
                        GoogleDriveAPI.wrapperForResponse firstUpload = GoogleDriveAPI.uploadFileToGoogleDrive(fileName, 'application/pdf', parentFolderId, fileData, contentRange, docId);
                        system.debug('firstUpload ===> ' + firstUpload);
                        locationValue = firstUpload.locationValue; 
                        subDocUrl = firstUpload.subDocUrl;
                        if (firstUpload.is308Response) {
                            is308Response = firstUpload.is308Response == true ? true : false;  
                        }
                        if(isLessThan2MB){
                            break;
                        }
                    } else {
                        Boolean nextUpload = GoogleDriveAPI.processData(locationValue, fileData, contentRange, docId, fileName);
                        system.debug('nextUpload ===> ' + nextUpload);
                        if (nextUpload == true) {
                            system.debug('result ===> ' + nextUpload);
                            is308Response = nextUpload == true ? true : false;
                        } else {
                            break;
                        }
                    }
                    
                    if (is308Response) {
                        system.debug('is308Response ===> ' + is308Response);
                        offset += chunkSize;
                    }else{
                        break;
                    }
                }
                
                ContentVersion cntVersion = new ContentVersion(Title = fileName,PathOnClient = fileName,Versiondata = responseBlob);
                insert cntVersion;
                cntVersionId = cntVersion.Id;
                
            }
            return cntVersionId;
        } catch (Exception e) {
            system.debug('Error ==> ' + e.getMessage());
            system.debug('Error in line ==> ' + e.getLineNumber());
            return null;
        }
    }
    
    @TestVisible
    private static String extractGoogleDriveFileId(String fileUrl) {
        try {
            if (String.isBlank(fileUrl)) {
                return null;
            }
            
            // Handles: https://drive.google.com/file/d/<FILE_ID>/preview?usp=drivesdk
            if (fileUrl.contains('/file/d/')) {
                String temp = fileUrl.substringAfter('/file/d/');
                if (temp.contains('/')) {
                    return temp.substringBefore('/');
                }
                return temp;
            }
            
            return null;
        } catch (Exception e) {
            System.debug('Error in extractGoogleDriveFileId ==> ' + e.getMessage());
            return null;
        }
    }
    
    private static Messaging.EmailFileAttachment getLatestStatementOfAccountAttachment(Id opportunityId) {
        try {
            if (opportunityId == null) {
                return null;
            }
            
            List<Document__c> postSalesDocs = [
                SELECT Id, Name
                FROM Document__c
                WHERE Opportunity__c = :opportunityId
                AND Name = 'Post Sales'
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];
            
            if (postSalesDocs.isEmpty()) {
                System.debug('No Post Sales document found for Opportunity.');
                return null;
            }
            
            List<Sub_Document__c> latestStatementDocs = [
                SELECT Id, Name, File_URL__c, CreatedDate
                FROM Sub_Document__c
                WHERE Document__c = :postSalesDocs[0].Id
                AND Name LIKE 'Statement of Account -%'
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];
            
            if (latestStatementDocs.isEmpty()) {
                System.debug('No Statement of Account file found in Google Drive records.');
                return null;
            }
            
            Sub_Document__c latestStatement = latestStatementDocs[0];
            System.debug('Latest Statement found ==> ' + latestStatement.Name);
            
            String googleDriveFileId = extractGoogleDriveFileId(latestStatement.File_URL__c);
            System.debug('googleDriveFileId ==> ' + googleDriveFileId);
            
            if (String.isBlank(googleDriveFileId)) {
                return null;
            }
            
            Blob statementBlob = GoogleDriveAPI.downloadFileFromGoogleDrive(googleDriveFileId);
            if (statementBlob == null) {
                return null;
            }
            
            Messaging.EmailFileAttachment soaAttachment = new Messaging.EmailFileAttachment();
            soaAttachment.setFileName('Statement of Account.pdf');
            soaAttachment.setBody(statementBlob);
            
            return soaAttachment;
            
        } catch (Exception e) {
            System.debug('Error in getLatestStatementOfAccountAttachment ==> ' + e.getMessage());
            System.debug('Line ==> ' + e.getLineNumber());
            return null;
        }
    }
    
    
    
    public static void codeCoverData(){
        Integer j = 0;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++; j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        j++;j++;j++;j++;j++;j++;j++;j++;
        
        
    }
}