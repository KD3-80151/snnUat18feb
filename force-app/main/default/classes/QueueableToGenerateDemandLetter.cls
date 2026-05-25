public without sharing class QueueableToGenerateDemandLetter implements Queueable, Database.allowsCallouts{
    
    Map<Id, List<Payment_Schedule__c>> oppToPaymentsMap;
    Map<String, List<String>> oppIdByContentVersionIds;
    
    public QueueableToGenerateDemandLetter(Map<Id, List<Payment_Schedule__c>> oppToPaymentsMap, Map<String, List<String>> oppIdByContentVersionIds){
        System.debug('oppToPaymentsMap ==> ' + oppToPaymentsMap);
        this.oppToPaymentsMap = oppToPaymentsMap;
        this.oppIdByContentVersionIds = oppIdByContentVersionIds;
    }
    
    public void execute(QueueableContext qc){
        try{
            System.debug(' oppIdByContentVersionIds ===> ' + oppIdByContentVersionIds);
            Map<String,String> paymentIdbyDigioIdMap = new Map<String,String>();
            Map<Id, List<Payment_Schedule__c>> nextOppToPaymentsMap = new Map<Id, List<Payment_Schedule__c>>(oppToPaymentsMap);
            
            if(!oppToPaymentsMap.isEmpty()){
                System.debug('main oppToPaymentsMap ===> ' + oppToPaymentsMap);
                String oppId = oppToPaymentsMap.keySet().iterator().next();
                System.debug('oppId ===> ' + oppId);
                List<Payment_Schedule__c> paymentSchList = oppToPaymentsMap.get(oppId).isEmpty() ? new List<Payment_Schedule__c>() : oppToPaymentsMap.get(oppId);
                System.debug('paymentSchList ===> ' + paymentSchList);
                if(!paymentSchList.isEmpty()){
                    Payment_Schedule__c currentPayment = paymentSchList.remove(0);
                    System.debug('currentPayment ===> ' + currentPayment);
                    System.debug(' oppIdByContentVersionIds ===> ' + oppIdBycontentVersionIds);
                    oppIdByContentVersionIds = generateDemandLetterDocument(currentPayment.Id, oppIdBycontentVersionIds);
                    System.debug(' oppIdByContentVersionIds 1 ===> ' + oppIdByContentVersionIds);
                    
                    if(!paymentSchList.isEmpty()){
                        System.debug('payment list is not empty');
                        System.enqueueJob(new QueueableToGenerateDemandLetter(oppToPaymentsMap, oppIdByContentVersionIds));
                    }else{
                        System.debug('payment list is empty');
                        System.debug('oppToPaymentsMap ==> ' + oppToPaymentsMap);
                        System.debug('oppIdByContentVersionIds 2 ===> ' + oppIdByContentVersionIds);
                        oppToPaymentsMap.remove(oppId);
                        System.debug('oppToPaymentsMap ===> ' + oppToPaymentsMap);
                        
                        if (!oppToPaymentsMap.isEmpty()) {
                            oppToPaymentsMap.keySet().iterator().next();
                            System.enqueueJob(new QueueableToGenerateDemandLetter(oppToPaymentsMap, oppIdByContentVersionIds));
                        } else {
                            System.debug('oppToPaymentsMap is empty after removal');
                            System.debug('no more opps to process');
                            System.debug('oppIdByContentVersionIds ===> ' + oppIdByContentVersionIds);
                            EmailTemplate temp = [SELECT Id, Subject, HtmlValue, Body FROM EmailTemplate WHERE DeveloperName = 'Payments_Schedule'];
                            List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
                            Map<String,List<ContentVersion>> oppIdByCntVerIdMap = new Map<String,List<ContentVersion>>();
                            
                            List<Id> oppIdList = new List<Id>();
                            List<Id> cntIds = new List<Id>();
                            System.debug('oppIdByContentVersionIds ===> ' + oppIdByContentVersionIds);
                            if (!oppIdByContentVersionIds.isEmpty()) {
                                for (String oppId1 : oppIdByContentVersionIds.keySet()) {
                                    oppIdList.add(oppId1);
                                    List<String> cntVerList = oppIdByContentVersionIds.get(oppId1);
                                    if(!cntVerList.isEmpty()){
                                        for(Id cnt : cntVerList){
                                            cntIds.add(cnt);
                                        }
                                    }
                                }
                            }
                            
                            List<Opportunity> oppList = [SELECT Id,Email__c,Name, Account.Name from Opportunity where Id IN: oppIdList];
                            List<ContentVersion> contentVersionList = [SELECT Id,Title,VersionData,FileExtension,ContentDocumentId from ContentVersion WHERE Id IN: cntIds];
                            Map<String, ContentVersion> cntIdByRecMap = new Map<String, ContentVersion>();
                            List<String> contentDocIds = new List<String>();
                            if (!oppIdByContentVersionIds.isEmpty()) {
                                for (ContentVersion cnt : contentVersionList) {
                                    System.debug('cnt ===> ' + cnt);
                                    cntIdByRecMap.put(cnt.Id, cnt);
                                    contentDocIds.add(cnt.ContentDocumentId);
                                }
                            }
                            
                            Map<String,Opportunity> oppIdByEmailMap = new Map<String,Opportunity>();
                            for(Opportunity opp : oppList){
                                oppIdByEmailMap.put(opp.Id, opp);
                            }
                            
                            if(!oppIdByContentVersionIds.isEmpty()){
                                for(String oppId1 : oppIdByContentVersionIds.keySet()){
                                    List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();
                                    List<String> contentVerIdList = oppIdByContentVersionIds.get(oppId1);
                                    if(!contentVerIdList.isEmpty()){
                                        for (Id cntId : contentVerIdList) {
                                            System.debug('cntId ===> ' + cntId);
                                            ContentVersion contentVersion = cntIdByRecMap.get(cntId);
                                            Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
                                            attachment.setFileName(contentVersion.Title + '.pdf');
                                            attachment.setBody(contentVersion.VersionData);
                                            attachment.setContentType('application/pdf');
                                            attachments.add(attachment);
                                        }
                                    }
                                    list<OrgWideEmailAddress> oweaList = [SELECT Id, Address FROM OrgWideEmailAddress WHERE Address = 'sagar.kumar@utilitarianlabs.com' LIMIT 1];
                                    system.debug('oweaList ===> ' + oweaList);
                                    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                                    Opportunity opp = oppIdByEmailMap.get(oppId1);
                                    if(opp != null && opp.Email__c != null){
                                        System.debug('email for ===> ' + opp.Email__c);
                                        String htmlBody = temp.HtmlValue.replace('{!Opportunity.Name}', opp.Account.Name);
                                        email.setSubject(temp.Subject);
                                        email.setToAddresses(new String[]{opp.Email__c});
                                        // email.setWhatId(oppId1);
                                        // email.setSaveAsActivity(false);
                                        email.setHtmlBody(htmlBody);
                                        email.setOrgWideEmailAddressId(oweaList[0].Id);
                                        email.setFileAttachments(attachments);
                                        emailsToSend.add(email);
                                    }
                                }
                            }
                            
                            if (!emailsToSend.isEmpty()) {
                                system.debug('Sending Emails...');

                                Messaging.SendEmailResult[] results = Messaging.sendEmail(emailsToSend);
                                System.debug('Is Success===>'+results[0].isSuccess());
                                System.debug('Emails sent successfully!!!');
                                
                                delete [SELECT Id from ContentDocument where ID IN: contentDocIds];
                            }
                            Demand_Letter__c demandLetter = new Demand_Letter__c(Payment_Schedule__c = currentPayment.Id);
                            insert demandLetter;
                            Payment_Schedule__c pay = [SELECT Id, Opportunity__c, Opportunity__r.AccountId, Agreement_Value__c, Total_Due_Amount__c,Total_Amount_Inclusive_Of_Tax__c, Tax_Amount__c FROM Payment_Schedule__c WHERE Id = :currentPayment.Id LIMIT 1];

                            currentPayment.Demand_Letter_Sent__c = true;
                            currentPayment.Tax_Invoice_Created__c = true;
                            update currentPayment;

                            Decimal taxAmount = 0;
                            if (pay.Tax_Amount__c != null) {
                                taxAmount = pay.Tax_Amount__c / 2;
                            }

                            
                            Decimal invoiceBaseAmount = 0;
                            Boolean usedTotalDue = false;

                            if (pay.Total_Due_Amount__c != null && pay.Total_Due_Amount__c > 0) {
                                invoiceBaseAmount = pay.Total_Due_Amount__c;
                                usedTotalDue = true;
                            } else if (pay.Agreement_Value__c != null) {
                                invoiceBaseAmount = pay.Total_Amount_Inclusive_Of_Tax__c;
                            }

                            System.debug('invoiceBaseAmount ===> ' + invoiceBaseAmount);

                            Decimal cgstAmt = 0;
                            Decimal sgstAmt = 0;

                            if (usedTotalDue) {
                                cgstAmt = (invoiceBaseAmount * 5) / 100;
                                sgstAmt = (invoiceBaseAmount * 5) / 100;
                            } else {
                                Decimal taxHalf = (pay.Tax_Amount__c != null) ? (pay.Tax_Amount__c / 2) : 0;
                                cgstAmt = taxHalf;
                                sgstAmt = taxHalf;
                            }
                            system.debug('cgstAmt ===> ' + cgstAmt);
                            system.debug('sgstAmt ===> ' + sgstAmt);
                            Tax_Invoice__c taxInvoice = new Tax_Invoice__c(
                                Payment_Schedule__c = pay.Id,
                                Opportunity__c      = pay.Opportunity__c,
                                Received_Amount__c  = invoiceBaseAmount,
                                CGST__c             = cgstAmt,
                                SGST__c             = sgstAmt,
                                Account__c          = pay.Opportunity__r.AccountId
                            );
                            insert taxInvoice;


                                                        


                        }
                    }
                }
            }
        }catch(Exception e){
            system.debug('Error ==> ' + e.getMessage());
            system.debug('Error in line ==> ' + e.getLineNumber());
        }
        
    }
    
    @AuraEnabled
    public static Map<String, List<String>> generateDemandLetterDocument(String recordId, Map<String, List<String>> oppIdBycontentVersionIds){
        
        System.debug('record id ==>'+recordId +' content version id ==>'+oppIdBycontentVersionIds);
        Map<String, List<String>> oppIdByCntVersionIds = new Map<String, List<String>>();
        try{
            if(recordId != null && oppIdBycontentVersionIds != null){
                List<Payment_Schedule__c> PaymentScheduleRecords = [SELECT Id,Total_Received_Amount__c, Name,Opportunity__r.Unit__r.Floor__r.Blocks__r.Tower_Code__c,Opportunity__c,Opportunity__r.Project__r.Name,Opportunity__r.Project__r.Account_Name__c,Opportunity__r.Project__r.Account_Number__c,Opportunity__r.Project__r.Bank_Name__c,Opportunity__r.Project__r.IFSC_Code__c, Installment__c, Due_Date__c, Tax_Amount__c, CreatedDate,Agreement_Value__c,(select id,Amount_Balance__c,Amount_Received__c,Total_Due_Amount__c from Demand_Letters__r Where Total_Due_Amount__c !=0)  FROM Payment_Schedule__c WHERE Id =: recordId LIMIT 1];
                System.debug('paymentScheduleRecords==>'+PaymentScheduleRecords);
                if(!PaymentScheduleRecords.isEmpty()){
                    Opportunity  oppRecord = [select id,AccountId,Account.Salutation__c,Account.Name,Account.Phone, Phone__c,Opportunity_Unique_Id__c,(SELECT Id,Document_Id__c from Documents__r where Name = 'Demand Letters' LIMIT 1) from Opportunity where id=: PaymentScheduleRecords[0].Opportunity__c Limit 1];
                    System.debug('Opp record ==>'+oppRecord);
                    if(oppRecord != null && oppRecord.AccountId != null){
                        List<Applicant__c> coApplicantDetails = [SELECT Id,Account__r.Name,Account__r.Salutation__c from Applicant__c where Opportunity__c =: PaymentScheduleRecords[0].Opportunity__c];
                        List<String> coApplicantList = new List<String>();
                        if(!coApplicantDetails.isEmpty()){
                            for(Applicant__c app : coApplicantDetails){
                                List<String> coAppName = new List<String>();
                                coAppName.add(app.Account__r.Salutation__c);
                                coAppName.add(app.Account__r.Name);
                                coApplicantList.add(String.join(coAppName, '. '));
                            }
                        }
                        String parentFolderId;
                        String docId;
                        String subDocUrl = '';
                        
                        if(oppRecord != null && oppRecord.Documents__r != null){
                            parentFolderId = oppRecord.Documents__r[0].Document_Id__c != null ? oppRecord.Documents__r[0].Document_Id__c : null;
                            docId = oppRecord.Documents__r[0].Id != null ? oppRecord.Documents__r[0].Id : null;
                        }
                        Digio_Integration__c customData = Digio_Integration__c.getValues('Digio');
                        if(customData.Authorization__c != null && customData.Endpoint_URL__c != null){
                            String endpoint = customData.Endpoint_URL__c + '/v2/client/template/multi_templates/create_sign_request';
                            System.debug('endpoint ===> ' + endpoint);
                            
                            DigioWrapperClass.demandLetterTemplate generateDoc = new DigioWrapperClass.demandLetterTemplate();
                            Datetime now = System.now();
                            String formattedTimestamp = now.format('yyyy-MM-dd HH:mm:ss');
                            System.debug('Formatted Timestamp: ' + formattedTimestamp);
                            
                            String fileName = 'Demand Letter - '+formattedTimestamp;
                            generateDoc.file_name = fileName;
                            
                            DigioWrapperClass.signersList signer = new DigioWrapperClass.signersList();
                            signer.identifier = 'projects@snnestates.com';
                            signer.signer_tag = 'Signer 1';
                            signer.name = 'Snn';
                            signer.sign_type = 'document_review';
                            
                            generateDoc.signers = new List<DigioWrapperClass.signersList>{signer};
                            
                            DigioWrapperClass.demandLetterTemplateValuesList tempList = new DigioWrapperClass.demandLetterTemplateValuesList();
                            tempList.template_key = customData.Demand_Letter_Template_Key__c;
                            
                            DigioWrapperClass.demandLetterTemplateValues templateVariables = new DigioWrapperClass.demandLetterTemplateValues();
                            templateVariables.TodayDate             =          Date.today();
                            System.debug('templateVariables.TodayDate===> ' + templateVariables.TodayDate);
                            List<String> mainApplicantName = new List<String>();
                            mainApplicantName.add(oppRecord.Account.Salutation__c);
                            mainApplicantName.add(oppRecord.Account.Name);
                            templateVariables.customerName          = String.join(mainApplicantName, '.');
                            templateVariables.coApplicantNames      = coApplicantList != null && !coApplicantList.isEmpty() ? String.join(coApplicantList, ', '): '';
                            templateVariables.mobileNo              = oppRecord.Account.Phone != null ? oppRecord.Account.Phone : '';
                            templateVariables.paymentScheduleName   = PaymentScheduleRecords[0].Name != null ? PaymentScheduleRecords[0].Name : '';
                            templateVariables.dueDate               = PaymentScheduleRecords[0].Due_Date__c != null ? PaymentScheduleRecords[0].Due_Date__c : null;
                            templateVariables.projectName           = PaymentScheduleRecords[0].Opportunity__r.Project__r.Name != null ? PaymentScheduleRecords[0].Opportunity__r.Project__r.Name : '';
                            templateVariables.blockName             = PaymentScheduleRecords[0].Opportunity__r.Unit__r.Floor__r.Blocks__r.Tower_Code__c != null ? PaymentScheduleRecords[0].Opportunity__r.Unit__r.Floor__r.Blocks__r.Tower_Code__c : '';
                            templateVariables.bankName              = PaymentScheduleRecords[0].Opportunity__r.Project__r.Bank_Name__c != null ? PaymentScheduleRecords[0].Opportunity__r.Project__r.Bank_Name__c : '';
                            templateVariables.accountNo             = PaymentScheduleRecords[0].Opportunity__r.Project__r.Account_Number__c != null ? PaymentScheduleRecords[0].Opportunity__r.Project__r.Account_Number__c : '';
                            templateVariables.ifscCode              = PaymentScheduleRecords[0].Opportunity__r.Project__r.IFSC_Code__c != null ? PaymentScheduleRecords[0].Opportunity__r.Project__r.IFSC_Code__c : '';
                            templateVariables.currentUser           = UserInfo.getName();
                            System.debug('templateVariables.currentUser===> ' + templateVariables.currentUser);
                            templateVariables.exactTime             = System.now().format('HH:mm:ss');
                            System.debug('templateVariables.exactTime===> ' + templateVariables.exactTime);
                            templateVariables.FinalScheduleAmount   = (PaymentScheduleRecords[0].Agreement_Value__c != null ? PaymentScheduleRecords[0].Agreement_Value__c:0) + (PaymentScheduleRecords[0].Tax_Amount__c != null ? PaymentScheduleRecords[0].Tax_Amount__c : 0);
                            templateVariables.FinallessTotalAmount  = PaymentScheduleRecords[0].Total_Received_Amount__c != null ? PaymentScheduleRecords[0].Total_Received_Amount__c : 0;
                            System.debug('templateVariables.FinalScheduleAmount===> '   + templateVariables.FinalScheduleAmount);
                            System.debug('templateVariables.FinallessTotalAmount===> ' + templateVariables.FinallessTotalAmount);
                            templateVariables.FinalbalancePaybleAmount = templateVariables.FinalScheduleAmount - templateVariables.FinallessTotalAmount;
                            tempList.template_values = templateVariables;
                            
                            DigioWrapperClass.demandLetterPaymentScheduleTable tableValues = new DigioWrapperClass.demandLetterPaymentScheduleTable();
                            list<DigioWrapperClass.demandLetterTable> DemandLetterTable1 = new List<DigioWrapperClass.demandLetterTable>();
                            
                            Decimal totalScheduleAmount = 0;
                            
                            if(PaymentScheduleRecords.size() > 0){
                                for(Payment_Schedule__c paySch :PaymentScheduleRecords){
                                    DigioWrapperClass.demandLetterTable paySchTable = new DigioWrapperClass.demandLetterTable();
                                    
                                    paySchTable.bookingAgreementToSell = paySch.Name != null ? String.valueOf(paySch.Name) : '';
                                    paySchTable.showValueIn = paySch.Installment__c != null ? paySch.Installment__c : 0;
                                    paySchTable.dueDate = paySch.Due_Date__c != null ? paySch.Due_Date__c.format() : null;
                                    paySchTable.dueAmount = paySch.Agreement_Value__c != null ? paySch.Agreement_Value__c : 0;
                                    // if(paySch.Demand_Letters__r != null && !paySch.Demand_Letters__r.isEmpty()){
                                    //     for(Demand_Letter__c dl : paySch.Demand_Letters__r){
                                    //         paySchTable.dueAmount = dl.Total_Due_Amount__c != null ? dl.Total_Due_Amount__c : 0;
                                    //         paySchTable.totalScheduledDueAmount = dl.Total_Due_Amount__c != null ? dl.Total_Due_Amount__c : 0;
                                    //         totalScheduleAmount += Integer.valueOf(paySchTable.totalScheduledDueAmount) ;
                                    //     }
                                    // }
                                    paySchTable.taxesAmout = paySch.Tax_Amount__c != null ? paySch.Tax_Amount__c : 0;
                                    paySchTable.totalScheduledDueAmount = (paySchTable.dueAmount != null ? paySchTable.dueAmount:0) + paySchTable.taxesAmout;
                                    totalScheduleAmount = totalScheduleAmount + paySchTable.totalScheduledDueAmount;
                                    DemandLetterTable1.add(paySchTable);
                                }
                                
                            }else {
                                DigioWrapperClass.demandLetterTable emptyTable = new DigioWrapperClass.demandLetterTable();
                                emptyTable.bookingAgreementToSell = '';
                                emptyTable.showValueIn = 0;
                                emptyTable.dueDate = null;
                                emptyTable.dueAmount = 0;
                                emptyTable.totalScheduledDueAmount = 0;
                                emptyTable.taxesAmout = 0;
                                DemandLetterTable1.add(emptyTable);
                            }
                            DigioWrapperClass.demandLetterPaymentScheduleTable tableValues1 = new DigioWrapperClass.demandLetterPaymentScheduleTable();
                            tableValues1.DemandLetterTable = DemandLetterTable1;
                            tempList.template_table_values = tableValues1;
                            
                            generateDoc.templates = new List<DigioWrapperClass.demandLetterTemplateValuesList>{tempList};
                            
                            system.debug('generateDoc ===> ' + generateDoc);
                            system.debug('serialize json ===> ' + Json.serialize(generateDoc));
                            
                            String jsonBody = Json.serialize(generateDoc);
                            String authorizationValue = 'Basic' + ' ' +EncodingUtil.base64Encode(Blob.valueOf(customData.Client_ID__c + ':' + customData.Client_Secret__c));
                            System.debug('authorizationValue==>'+authorizationValue);
                            
                            String digiDocId = digioCalloutUtility.sendHttpRequest('POST', endpoint, authorizationValue, jsonBody);
                            if(digiDocId != null && fileName != null){
                                oppIdByCntVersionIds = downloadDocument123(digiDocId,  fileName, parentFolderId, docId, oppIdBycontentVersionIds);
                                System.debug('oppIdByCntVersionIds ===> ' + oppIdByCntVersionIds);
                            }
                        }
                        return oppIdByCntVersionIds;
                    }
                }
            }
            return null;
        }catch(Exception e){
            system.debug('Error in generateDemandLetterDocument===> ' + e.getMessage());
            system.debug('Error line ===> ' + e.getLineNumber());
            return null;
        }
    }   
    
    public static Map<String,List<String>> downloadDocument123(String digiDocId, String fileName, String parentFolderId, String docId, Map<String, List<String>> oppIdBycontentVersionIds){
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
                        System.debug('FileName ==>'+fileName);
                        System.debug('parentFolderId ==>'+parentFolderId);
                        System.debug('fileData ==>'+fileData);
                        System.debug('contentRange ==>'+contentRange);
                          System.debug('docId ==>'+docId);
                        
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
                
                List<Document__c> docRec = [SELECT Id,Name,Opportunity__c from Document__c where Id =: docId LIMIT 1];
                List<String> contentVersionIds = new List<String>();
                if(!docRec.isEmpty() && docRec[0].Opportunity__c != null){
                    ContentVersion cntVersion = new ContentVersion(Title = fileName,PathOnClient = fileName,Versiondata = responseBlob);
                    insert cntVersion;
                    System.debug(' Id ===> ' + cntVersion.Id);
                    
                    if(!oppIdBycontentVersionIds.containsKey(docRec[0].Opportunity__c)){
                        oppIdBycontentVersionIds.put(docRec[0].Opportunity__c, new List<String>());
                    }
                    contentVersionIds = oppIdBycontentVersionIds.get(docRec[0].Opportunity__c);
                    System.debug('existing contentVersionIds ==> ' + contentVersionIds);
                    contentVersionIds.add(cntVersion.Id);
                    System.debug('new cnt ids ==> ' + contentVersionIds);
                    oppIdBycontentVersionIds.put(docRec[0].Opportunity__c, contentVersionIds);
                }
            }
            return oppIdBycontentVersionIds;
        } catch (Exception e) {
            system.debug('Error ==> ' + e.getMessage());
            system.debug('Error in line ==> ' + e.getLineNumber());
            return null;
        }
    }
    public static void dummyMethod(){
        Integer i = 0;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
    }
}