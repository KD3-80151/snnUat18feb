public without sharing class QueueableToSendDemandLetterEmails implements Queueable, Database.AllowsCallouts {
    
    private Map<String, List<String>> oppIdByContentVersionIds;
    private Set<Id> processedPaymentScheduleIds;
    
    public QueueableToSendDemandLetterEmails(Map<String, List<String>> oppIdByContentVersionIds, Set<Id> processedPaymentScheduleIds) {
        this.oppIdByContentVersionIds = (oppIdByContentVersionIds != null) ? oppIdByContentVersionIds : new Map<String, List<String>>();
        this.processedPaymentScheduleIds = (processedPaymentScheduleIds != null) ? processedPaymentScheduleIds : new Set<Id>();
    }
    
    public void execute(QueueableContext qc) {
        try {
            System.debug('QueueableToSendDemandLetterEmails started ==> ' + oppIdByContentVersionIds);
            System.debug('processedPaymentScheduleIds ==> ' + processedPaymentScheduleIds);
            
            if (oppIdByContentVersionIds == null || oppIdByContentVersionIds.isEmpty()) {
                System.debug('No content versions available to email.');
                return;
            }
            
            EmailTemplate temp = [SELECT Id, Subject, HtmlValue, Body FROM EmailTemplate WHERE DeveloperName = 'Payments_Schedule' LIMIT 1];
            
            List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
            List<Id> oppIdList = new List<Id>();
            List<Id> cntIds = new List<Id>();
            
            for (String oppId1 : oppIdByContentVersionIds.keySet()) {
                oppIdList.add((Id)oppId1);
                List<String> cntVerList = oppIdByContentVersionIds.get(oppId1);
                if (cntVerList != null && !cntVerList.isEmpty()) {
                    for (String cnt : cntVerList) {
                        cntIds.add((Id)cnt);
                    }
                }
            }
            
            List<Opportunity> oppList = [SELECT Id, Email__c, Account.Email__c, Name, Account.Name FROM Opportunity WHERE Id IN :oppIdList];
            List<ContentVersion> contentVersionList = [SELECT Id, Title, VersionData, FileExtension, ContentDocumentId FROM ContentVersion WHERE Id IN :cntIds];
            
            Map<String, ContentVersion> cntIdByRecMap = new Map<String, ContentVersion>();
            List<Id> contentDocIds = new List<Id>();
            
            for (ContentVersion cnt : contentVersionList) {
                cntIdByRecMap.put(cnt.Id, cnt);
                if (cnt.ContentDocumentId != null) {
                    contentDocIds.add(cnt.ContentDocumentId);
                }
            }
            
            Map<String, Opportunity> oppIdByEmailMap = new Map<String, Opportunity>();
            for (Opportunity opp : oppList) {
                oppIdByEmailMap.put(String.valueOf(opp.Id), opp);
            }
            
            List<OrgWideEmailAddress> oweaList = [SELECT Id, Address FROM OrgWideEmailAddress WHERE Address = 'projects@snnestates.com' LIMIT 1];
            
            for (String oppId1 : oppIdByContentVersionIds.keySet()) {
                List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();
                
                List<String> contentVerIdList = oppIdByContentVersionIds.get(oppId1);
                if (contentVerIdList != null && !contentVerIdList.isEmpty()) {
                    for (String cntId : contentVerIdList) {
                        ContentVersion contentVersion = cntIdByRecMap.get(cntId);
                        if (contentVersion != null) {
                            Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
                            attachment.setFileName(contentVersion.Title + '.pdf');
                            attachment.setBody(contentVersion.VersionData);
                            attachment.setContentType('application/pdf');
                            attachments.add(attachment);
                        }
                    }
                }
                
                Messaging.EmailFileAttachment soaAttachment = getLatestStatementOfAccountAttachment((Id)oppId1);
                if (soaAttachment != null) {
                    attachments.add(soaAttachment);
                    System.debug('Statement of Account attachment added for opp ==> ' + oppId1);
                } else {
                    System.debug('No Statement of Account attachment found for opp ==> ' + oppId1);
                }
                
                Opportunity opp = oppIdByEmailMap.get(oppId1);
                if (opp != null && opp.Account != null && opp.Account.Email__c != null) {
                    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                    
                    String htmlBody = temp.HtmlValue;
                    if (opp.Account.Name != null) {
                        htmlBody = htmlBody.replace('{!Opportunity.Name}', opp.Account.Name);
                    }
                    
                    email.setSubject(temp.Subject);
                    email.setToAddresses(new String[]{ opp.Account.Email__c });
                    email.setHtmlBody(htmlBody);
                    
                    if (!oweaList.isEmpty()) {
                        email.setOrgWideEmailAddressId(oweaList[0].Id);
                    }
                    
                    email.setFileAttachments(attachments);
                    emailsToSend.add(email);
                    
                    System.debug('Total attachments for opp ==> ' + oppId1 + ' ::: ' + attachments.size());
                }
            }
            
            if (!emailsToSend.isEmpty()) {
                Messaging.SendEmailResult[] results = Messaging.sendEmail(emailsToSend);
                System.debug('Emails sent. First status ==> ' + results[0].isSuccess());
            }
            
            if (!contentDocIds.isEmpty()) {
                delete [SELECT Id FROM ContentDocument WHERE Id IN :contentDocIds];
            }
            
            processPostEmailWork(processedPaymentScheduleIds);
            
        } catch (Exception e) {
            System.debug('Error in QueueableToSendDemandLetterEmails ==> ' + e.getMessage());
            System.debug('Line ==> ' + e.getLineNumber());
            System.debug('Stack ==> ' + e.getStackTraceString());
        }
    }
    
    private static void processPostEmailWork(Set<Id> paymentScheduleIds) {
        try {
            if (paymentScheduleIds == null || paymentScheduleIds.isEmpty()) {
                System.debug('No processed payment schedules found for post email work.');
                return;
            }
            
            List<Payment_Schedule__c> payList = [SELECT Id, Opportunity__c, Opportunity__r.AccountId, Agreement_Value__c, Total_Due_Amount__c, Total_Amount_Inclusive_Of_Tax__c, Tax_Amount__c, Demand_Letter_Sent__c, Tax_Invoice_Created__c FROM Payment_Schedule__c WHERE Id IN :paymentScheduleIds AND Demand_Letter_Sent__c = false];
            
            List<Payment_Schedule__c> paymentsToUpdate = new List<Payment_Schedule__c>();
            List<Demand_Letter__c> demandLettersToInsert = new List<Demand_Letter__c>();
            List<Tax_Invoice__c> taxInvoicesToInsert = new List<Tax_Invoice__c>();
            
            for (Payment_Schedule__c pay : payList) {
                demandLettersToInsert.add(new Demand_Letter__c(Payment_Schedule__c = pay.Id));
                
                pay.Demand_Letter_Sent__c = true;
                pay.Tax_Invoice_Created__c = true;
                paymentsToUpdate.add(pay);
                
                Decimal invoiceBaseAmount = 0;
                Boolean usedTotalDue = false;
                
                if (pay.Total_Due_Amount__c != null && pay.Total_Due_Amount__c > 0) {
                    invoiceBaseAmount = pay.Total_Due_Amount__c;
                    system.debug('invoiceBaseAmount ==> ' + invoiceBaseAmount);
                    usedTotalDue = true;
                } else if (pay.Agreement_Value__c != null) {
                    invoiceBaseAmount = pay.Total_Amount_Inclusive_Of_Tax__c;
                }
                
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
                if(pay.Total_Due_Amount__c != null && pay.Total_Due_Amount__c != 0){
                    taxInvoicesToInsert.add(new Tax_Invoice__c(
                    Payment_Schedule__c = pay.Id,
                    Opportunity__c      = pay.Opportunity__c,
                    Received_Amount__c  = invoiceBaseAmount,
                    CGST__c             = cgstAmt,
                    SGST__c             = sgstAmt,
                    Account__c          = pay.Opportunity__r.AccountId
                ));
                }
                
            }
            
            if (!demandLettersToInsert.isEmpty()) {
                insert demandLettersToInsert;
            }
            if (!paymentsToUpdate.isEmpty()) {
                update paymentsToUpdate;
            }
            if (!taxInvoicesToInsert.isEmpty()) {
                insert taxInvoicesToInsert;
            }
            
        } catch (Exception e) {
            System.debug('Error in processPostEmailWork ==> ' + e.getMessage());
            System.debug('Line ==> ' + e.getLineNumber());
            System.debug('Stack ==> ' + e.getStackTraceString());
        }
    }
    
    private static String extractGoogleDriveFileId(String fileUrl) {
        try {
            if (String.isBlank(fileUrl)) {
                return null;
            }
            
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
            
            List<Document__c> postSalesDocs = [SELECT Id, Name FROM Document__c WHERE Opportunity__c = :opportunityId AND Name = 'Post Sales' ORDER BY CreatedDate DESC LIMIT 1];
            
            if (postSalesDocs.isEmpty()) {
                System.debug('No Post Sales document found for Opportunity ==> ' + opportunityId);
                return null;
            }
            
            List<Sub_Document__c> latestStatementDocs = [SELECT Id, Name, File_URL__c, CreatedDate FROM Sub_Document__c WHERE Document__c = :postSalesDocs[0].Id AND Name LIKE 'Statement of Account -%' ORDER BY CreatedDate DESC LIMIT 1];
            
            if (latestStatementDocs.isEmpty()) {
                System.debug('No Statement of Account file found for Opportunity ==> ' + opportunityId);
                return null;
            }
            
            Sub_Document__c latestStatement = latestStatementDocs[0];
            String googleDriveFileId = extractGoogleDriveFileId(latestStatement.File_URL__c);
            
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
            soaAttachment.setContentType('application/pdf');
            
            return soaAttachment;
            
        } catch (Exception e) {
            System.debug('Error in getLatestStatementOfAccountAttachment ==> ' + e.getMessage());
            System.debug('Line ==> ' + e.getLineNumber());
            System.debug('Stack ==> ' + e.getStackTraceString());
            return null;
        }
    }
}