public with sharing class GenerateReceiptDetailsController {
    public GenerateReceiptDetailsController() {

    }

    @AuraEnabled
    public static void closeCurrentTask(Id taskId){
        try {
            if(taskId != null) {
                List<Task> task = [SELECT Id,WhatId, Status FROM Task WHERE Id = :taskId LIMIT 1];
                if (!task.isEmpty() && task[0].WhatId != null) {
                    task[0].Status = 'Completed';
                    update task[0];

                    List<Receipt__c> receipts = [SELECT Id,Opportunity__c,Opportunity__r.OwnerId FROM Receipt__c WHERE Opportunity__c = :task[0].WhatId];
                    if(!receipts.isEmpty()){
                        Opportunity opp = new Opportunity();
                        opp.Id = task[0].WhatId;
                        opp.StageName = 'Booking Data Entry';
                        update opp;

                        Task tsk = new Task();
                        tsk.Subject = 'Fill Applicant Details';
                        tsk.OwnerId = receipts[0].Opportunity__r.OwnerId;
                        tsk.Priority = 'High';
                        tsk.WhatId = task[0].WhatId;
                        tsk.ActivityDate = System.Today() + 3;
                        insert tsk;
                    }
                }
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Receipt__c> fetchRelatedReceipts(Id taskId){
        try {
            System.debug('taskId ===> ' + taskId);
            if(taskId != null){
                List<Task> task = [SELECT WhatId FROM Task WHERE Id = :taskId LIMIT 1];
                if(!task.isEmpty() && task[0].WhatId != null){
                    List<Receipt__c> receipts = [SELECT Id FROM Receipt__c WHERE Opportunity__c = :task[0].WhatId];
                    System.debug('receipts ===> ' + receipts);
                    return receipts.isEmpty() ? null : receipts;
                }
            }
            return null;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getPicklistValues(String fieldName) {
        Schema.SObjectField field = Receipt__c.SObjectType.getDescribe().fields.getMap().get(fieldName);
        List<String> picklistValues = new List<String>();
        if (field != null) {
            for (Schema.PicklistEntry entry : field.getDescribe().getPicklistValues()) {
                picklistValues.add(entry.getLabel());
            }
        }
        return picklistValues;
    }


     @AuraEnabled
     public static List<Account> getAccountValues(String taskId) {
        Set<Id> allAccountIds = new Set<Id>();
        List<Account> allAccounts = new List<Account>();
        try{
            System.debug('taskId==>'+taskId);
            if(String.isNotBlank(taskId)){
                List<Task> task = [select Id,WhatId  from Task where Id =:taskId];
                List<Opportunity> oppRecord = [select Id,AccountId  from Opportunity Where Id =:task[0].WhatId Limit 1];
                List<Applicant__c > applicantRecords = [select Id,Opportunity__c,Opportunity__r.AccountId,Opportunity__r.Account.Name,Account__c,Account__r.Name from Applicant__c where Opportunity__c  =: task[0].WhatId];
                if(!oppRecord.isEmpty()){
                    allAccountIds.add(oppRecord[0].AccountId);
                }
                if(!applicantRecords.isEmpty()){
                    for(Applicant__c app : applicantRecords){
                        allAccountIds.add(app.Account__c);
                    }
                }
                if(!allAccountIds.isEmpty()){
                    allAccounts = [select Id,Name from Account Where Id In:allAccountIds];
                    return allAccounts;
                }
            }
        }catch(Exception e){
            System.debug('Message==>'+e.getMessage());
            System.debug('Line Number ==>'+e.getLineNumber());
        }
        return allAccounts;
    }

    @AuraEnabled
    public static void createReceipt(Map<String, Object> receiptData,String accId) {
        try{
            System.debug('receiptData ====> ' + receiptData);
            System.debug('accId==>'+accId);
            Receipt__c receipt = new Receipt__c();
            
            if (receiptData.containsKey('opportunityId') && receiptData.get('opportunityId') != null) {
                String taskId = (String) receiptData.get('opportunityId');
                Task task = [SELECT WhatId FROM Task WHERE Id = :taskId LIMIT 1];
                System.debug('taskId ==>' + taskId);
                System.debug('oppId ==>' + task.WhatId);
                
                if (task.WhatId != null && task.WhatId.getSObjectType() == Opportunity.sObjectType) {
                    receipt.Opportunity__c = task.WhatId;
                } else {
                    system.debug('The provided Task ID does not relate to an Opportunity.');
                    return;
                }
                if(String.isNotBlank(accId)){
                    receipt.Account__c = accId;
                }
            }
            System.debug('Bank--->'+receiptData.get('bank'));
            System.debug('Amount--->'+receiptData.get('amount'));
            
           
            // Demand_Letter__c dl = [SELECT id, Name,mainDemandLetter__c FROM Demand_Letter__c WHERE mainDemandLetter__c = True LIMIT 1];
            // System.debug('dl========>'+dl);
            receipt.Receipt_Date__c = System.Today();
            receipt.Type__c = receiptData.containsKey('receiptType') && receiptData.get('receiptType') != null ? (String) receiptData.get('receiptType') : null;
            receipt.Token_Amount__c = TRUE;
            receipt.Bank__c = receiptData.containsKey('bankName') && receiptData.get('bankName') != null ? (String) receiptData.get('bankName') : null;
            receipt.PAN_TAN_Number__c = receiptData.containsKey('panNo') && receiptData.get('panNo') != null ? (String) receiptData.get('panNo') : null;
            receipt.Amount__c = receiptData.containsKey('amount') && receiptData.get('amount') != null ? Integer.valueOf(receiptData.get('amount')) : null;
            receipt.TDS_Amount__c = receiptData.containsKey('tdsAmount') && receiptData.get('tdsAmount') != null ? Integer.valueOf(receiptData.get('tdsAmount')) : null;
            receipt.Branch__c = receiptData.containsKey('branch') && receiptData.get('branch') != null ? (String) receiptData.get('branch') : null;
            receipt.Mode_of_Payment__c = receiptData.containsKey('modeOfPayment') && receiptData.get('modeOfPayment') != null ? (String) receiptData.get('modeOfPayment') : null;
            receipt.Drawn_on_Bank__c = receiptData.containsKey('drawnOnBank') && receiptData.get('drawnOnBank') != null ? (String) receiptData.get('drawnOnBank') : null;
            receipt.UPI_Provider__c = receiptData.containsKey('upiProvider') && receiptData.get('upiProvider') != null ? (String) receiptData.get('upiProvider') : null;
            receipt.Cheque_Number__c = receiptData.containsKey('chequeNumber') && receiptData.get('chequeNumber') != null ? (String) receiptData.get('chequeNumber') : null;
            receipt.CIN__c = receiptData.containsKey('cin') && receiptData.get('cin') != null ? (String) receiptData.get('cin') : null;
            receipt.BSR_Code__c = receiptData.containsKey('bsrCode') && receiptData.get('bsrCode') != null ? (String) receiptData.get('bsrCode') : null;

            String chequeDateString = receiptData.containsKey('chequeDate') && receiptData.get('chequeDate') != null ? receiptData.get('chequeDate').toString() : null;
            if (chequeDateString != null && chequeDateString.trim() != '') {
                try {
                    receipt.Cheque_Date__c = Date.valueOf(chequeDateString);
                } catch (Exception e) {
                    System.debug('Error parsing Cheque Date: ' + e.getMessage());
                    receipt.Cheque_Date__c = null;
                }
            } else {
                receipt.Cheque_Date__c = null;
            }

            receipt.Reference_Number__c = receiptData.containsKey('referenceNo') && receiptData.get('referenceNo') != null ? (String) receiptData.get('referenceNo') : null;

            String paidDateString = receiptData.containsKey('paidDate') && receiptData.get('paidDate') != null ? receiptData.get('paidDate').toString() : null;
            if (paidDateString != null && paidDateString.trim() != '') {
                try {
                    receipt.Paid_Date__c = Date.valueOf(paidDateString);
                } catch (Exception e) {
                    System.debug('Error parsing Paid Date: ' + e.getMessage());
                    receipt.Paid_Date__c = null;
                }
            } else {
                receipt.Paid_Date__c = null;
            }

            receipt.Transaction_Reference_Number__c = receiptData.containsKey('transactionReferenceNo') && receiptData.get('transactionReferenceNo') != null ? (String) receiptData.get('transactionReferenceNo') : null;
            receipt.DD_Number__c = receiptData.containsKey('ddNumber') && receiptData.get('ddNumber') != null ? (String) receiptData.get('ddNumber') : null;

            String ddDateString = receiptData.containsKey('ddDate') && receiptData.get('ddDate') != null ? receiptData.get('ddDate').toString() : null;
            if (ddDateString != null && ddDateString.trim() != '') {
                try {
                    receipt.DD_Date__c = Date.valueOf(ddDateString);
                } catch (Exception e) {
                    System.debug('Error parsing DD Date: ' + e.getMessage());
                    receipt.DD_Date__c = null;
                }
            } else {
                receipt.DD_Date__c = null;
            }
            String challanDateString = receiptData.containsKey('challanDate') && receiptData.get('challanDate') != null ? receiptData.get('challanDate').toString() : null;
            if (challanDateString != null && challanDateString.trim() != '') {
                try {
                    receipt.Challan_Date__c = Date.valueOf(challanDateString);
                } catch (Exception e) {
                    System.debug('Error parsing challanDate: ' + e.getMessage());
                    receipt.Challan_Date__c = null;
                }
            } else {
                receipt.Challan_Date__c = null;
            }

            String jvDateString = receiptData.containsKey('jvDate') && receiptData.get('jvDate') != null ? receiptData.get('jvDate').toString() : null;
            if (jvDateString != null && jvDateString.trim() != '') {
                try {
                    receipt.JV_Date__c = Date.valueOf(jvDateString);
                } catch (Exception e) {
                    System.debug('Error parsing JV Date: ' + e.getMessage());
                    receipt.JV_Date__c = null;
                }
            } else {
                receipt.JV_Date__c = null;
            }

            receipt.JV_Reference_Number__c = receiptData.containsKey('jvReferenceNumber') && receiptData.get('jvReferenceNumber') != null ? (String) receiptData.get('jvReferenceNumber') : null;
            // receipt.Demand_Letter__c = dl.Id;

            insert receipt;
            Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
            req.setObjectId(receipt.Id);
            req.setProcessDefinitionNameOrId('Receipt_Approval_Process'); 
            Approval.ProcessResult result = Approval.process(req);
            receipt.Approval_Status__c = 'Sent';
            update receipt;
            Task tsk = new Task();
            tsk.Id = (String)receiptData.get('opportunityId');
            System.debug('tsk.Id ===> ' + tsk.Id);
            tsk.Status = 'Completed';
            update tsk;
            System.debug('task ==> ' + tsk);
        }catch(Exception e){
            System.debug('Exception occured--->'+e.getMessage()+'@Line--->'+e.getLineNumber());
        }
    }

    @AuraEnabled
    public static Boolean checkDuplicate(String taskId, String type, String uniqueNumber) {
        System.debug('DD Number or Cheque Number --->'+uniqueNumber);
        if(uniqueNumber != null && uniqueNumber.trim() != '' && taskId != null && taskId != ''){
            List<Receipt__c> receipts = new List<Receipt__c>();
            Task task = [SELECT WhatId FROM Task WHERE Id = :taskId LIMIT 1];
            if(type == 'DD'){
                receipts = [SELECT Id FROM Receipt__c WHERE DD_Number__c = :uniqueNumber AND Opportunity__c = :task.WhatId LIMIT 1];
            }else if(type == 'Cheque'){
                receipts = [SELECT Id FROM Receipt__c WHERE Cheque_Number__c = :uniqueNumber AND Opportunity__c = :task.WhatId LIMIT 1];
            }
            System.debug('receipts.size() ---> '+ receipts.size());
            if(receipts.size() > 0){
                System.debug('Duplicate Record Found');
                return false;
            }
        }
        return true;
    }
}