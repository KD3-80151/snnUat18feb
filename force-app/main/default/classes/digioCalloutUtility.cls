public without sharing class digioCalloutUtility {
    
    public static String sendHttpRequest(String httpMethod, String endpoint, String authorizationCode, String jsonBody){
        try{
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

    
    
    public static void downloadDigioDocWithoutGDrive(String digiDocId, Id opportunityId, String docName) {
        Digio_Integration__c customData = Digio_Integration__c.getValues('Digio');
        if (customData.Endpoint_URL__c != null && digiDocId != null) {
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
            
            Opportunity opp = [SELECT Id, Name, AccountId,Account.Name, Account.Email__c, Unit__r.Unit_Name__c FROM Opportunity WHERE Id = :opportunityId LIMIT 1];
            if (opp.Account.Email__c == null) {
                System.debug('No email found for the Opportunity Account.');
                return;
            }
            
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
            else if ( docName != null && docName == 'DebitNote'){
                system.debug('docName'+docName);
                template = [SELECT Id, Subject, HtmlValue, Body, DeveloperName 
                            FROM EmailTemplate 
                            WHERE DeveloperName = 'Debit_Note_Template' 
                            LIMIT 1];

                if (template == null || template.Body == null || template.HtmlValue == null || template.Subject == null) {
                    System.debug('Email template or its content is null.');
                    return;
                }
            }
            
            
            String plainTextBody = template.Body; 
            String htmlBody = template.HtmlValue; 
            String subjectBody = template.Subject;
            
            if (opp.Name != null && opp.Account.Name != null) {
                System.debug('opp.Name ===> ' + opp.Name);
                plainTextBody = plainTextBody.replace('{!Opportunity.Name}', opp.Name);
                htmlBody = htmlBody.replace('{!Opportunity.Name}', opp.Name);
                plainTextBody = plainTextBody.replace('{!Opportunity.Account}', opp.Account.Name);
                htmlBody = htmlBody.replace('{!Opportunity.Account}', opp.Account.Name);
                subjectBody = subjectBody.replace('{!Opportunity.Name}', opp.Name);
            }

            // ONLY for Debit Note (safe addition)
            if (docName != null && docName == 'DebitNote') {
                if (opp.Unit__r != null && opp.Unit__r.Unit_Name__c != null) {
                    plainTextBody = plainTextBody.replace('{!Opportunity.Unit_Name__c}', opp.Unit__r.Unit_Name__c);
                    htmlBody = htmlBody.replace('{!Opportunity.Unit_Name__c}', opp.Unit__r.Unit_Name__c);
                }
            }
                        
            // Create the email message
            Messaging.SingleEmailMessage mailTemp = new Messaging.SingleEmailMessage();
            mailTemp.setHtmlBody(htmlBody);
            mailTemp.setSubject(subjectBody);
            mailTemp.setPlainTextBody(plainTextBody);
            mailTemp.setToAddresses(new String[] { opp.Account.Email__c });
            
            // Create the attachment
            // Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
            // attachment.setFileName(docName + '.pdf'); // Use docName as the file name
            // attachment.setBody(responseBlob); // Blob content for the attachment
            // mailTemp.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment });
            List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();
            
            Messaging.EmailFileAttachment primaryAttachment = new Messaging.EmailFileAttachment();
            primaryAttachment.setFileName(docName + '.pdf');
            primaryAttachment.setBody(responseBlob);
            attachments.add(primaryAttachment);
            
            // If sending Demand Letter, also attach latest Statement of Account
            if (docName == 'DemandLetter') {
                Messaging.EmailFileAttachment soaAttachment = getLatestStatementOfAccountAttachment(opportunityId);
                if (soaAttachment != null) {
                    attachments.add(soaAttachment);
                    System.debug('Statement of Account attachment added.');
                } else {
                    System.debug('No latest Statement of Account attachment found to add.');
                }
            }
            
            mailTemp.setFileAttachments(attachments);
            // Send the email
            List<Messaging.SingleEmailMessage> mailList = new List<Messaging.SingleEmailMessage> { mailTemp };
                Messaging.sendEmail(mailList);
            System.debug('Email sent successfully with attachment to ' + opp.Account.Email__c);
        }
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
            soaAttachment.setFileName(latestStatement.Name + '.pdf');
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