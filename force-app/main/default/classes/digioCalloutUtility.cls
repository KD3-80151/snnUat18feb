public without sharing class digioCalloutUtility {
    
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
        // Retrieve custom data
        Digio_Integration__c customData = Digio_Integration__c.getValues('Digio');
        if (customData.Endpoint_URL__c != null && digiDocId != null) {
            // Construct the endpoint URL
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
}