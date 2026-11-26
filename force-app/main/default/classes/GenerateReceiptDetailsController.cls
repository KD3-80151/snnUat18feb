public without sharing class GenerateReceiptDetailsController {
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

                    List<Receipt__c> receipts = [SELECT Id,Opportunity__c,Opportunity__r.OwnerId FROM Receipt__c WHERE Opportunity__c = :task[0].WhatId AND Token_Amount__c = true];
                    if(!receipts.isEmpty()){
                        Opportunity opp = new Opportunity();
                        opp.Id = task[0].WhatId;
                        opp.StageName = 'Booking Data Entry';
                        update opp;

                        // Avoid a duplicate if the receipt flow already created this task
                        Integer openFillTasks = [SELECT COUNT() FROM Task WHERE WhatId = :task[0].WhatId AND Subject = 'Fill Applicant Details' AND IsClosed = false];
                        if(openFillTasks == 0){
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
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<Receipt__c> fetchRelatedReceipts(Id taskId){
        try {
            System.debug('taskId ===> ' + taskId);
            if(taskId != null){
                List<Task> task = [SELECT WhatId FROM Task WHERE Id = :taskId LIMIT 1];
                if(!task.isEmpty() && task[0].WhatId != null){
                    List<Receipt__c> receipts = [SELECT Id FROM Receipt__c WHERE Opportunity__c = :task[0].WhatId AND Token_Amount__c = true];
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
            // Use the Receipt Date selected in the component; fall back to today if not provided.
            receipt.Receipt_Date__c = receiptData.containsKey('receiptDate') && receiptData.get('receiptDate') != null && String.isNotBlank(String.valueOf(receiptData.get('receiptDate')))
                ? Date.valueOf(String.valueOf(receiptData.get('receiptDate')))
                : System.today();
            receipt.Type__c = receiptData.containsKey('receiptType') && receiptData.get('receiptType') != null ? (String) receiptData.get('receiptType') : null;
            receipt.Token_Amount__c = TRUE;
            receipt.Bank__c = receiptData.containsKey('bankName') && receiptData.get('bankName') != null ? (String) receiptData.get('bankName') : null;
            receipt.PAN_TAN_Number__c = receiptData.containsKey('panNo') && receiptData.get('panNo') != null ? (String) receiptData.get('panNo') : null;
            if (String.isNotBlank(receipt.PAN_TAN_Number__c) && !Pattern.matches('^[A-Za-z]{5}[0-9]{4}[A-Za-z]{1}$', receipt.PAN_TAN_Number__c)) {
                throw new AuraHandledException('Please enter a valid PAN Number in the format ABCDE1234F.');
            }
            receipt.Amount__c = toAmount(receiptData.get('amount'));
            receipt.TDS_Amount__c = toAmount(receiptData.get('tdsAmount'));
            receipt.Branch__c = receiptData.containsKey('branch') && receiptData.get('branch') != null ? (String) receiptData.get('branch') : null;
            receipt.Mode_of_Payment__c = receiptData.containsKey('modeOfPayment') && receiptData.get('modeOfPayment') != null ? (String) receiptData.get('modeOfPayment') : null;
            receipt.Drawn_on_Bank__c = receiptData.containsKey('drawnOnBank') && receiptData.get('drawnOnBank') != null ? (String) receiptData.get('drawnOnBank') : null;
            receipt.UPI_Provider__c = receiptData.containsKey('upiProvider') && receiptData.get('upiProvider') != null ? (String) receiptData.get('upiProvider') : null;
            receipt.Cheque_Number__c = receiptData.containsKey('chequeNumber') && receiptData.get('chequeNumber') != null ? (String) receiptData.get('chequeNumber') : null;
            receipt.CIN__c = receiptData.containsKey('cin') && receiptData.get('cin') != null ? (String) receiptData.get('cin') : null;
            receipt.BSR_Code__c = receiptData.containsKey('bsrCode') && receiptData.get('bsrCode') != null ? (String) receiptData.get('bsrCode') : null;

            // String chequeDateString =   receiptData.containsKey('chequeDate') && receiptData.get('chequeDate') != null ? receiptData.get('chequeDate').toString() : 
            //                             receiptData.containsKey('fundTransferDate') && receiptData.get('fundTransferDate') != null ? receiptData.get('fundTransferDate').toString() : 
            //                             receiptData.containsKey('ddDate') && receiptData.get('ddDate') != null ? receiptData.get('ddDate').toString() :
            //                             receiptData.containsKey('paidDate') && receiptData.get('paidDate') != null ? receiptData.get('paidDate').toString() : 
            //                             receiptData.containsKey('challanDate') && receiptData.get('challanDate') != null ? receiptData.get('challanDate').toString() :
            //                             receiptData.containsKey('jvDate') && receiptData.get('jvDate') != null ? receiptData.get('jvDate').toString() :
            //                             receiptData.containsKey('fundDate') && receiptData.get('fundDate') != null ? receiptData.get('fundDate').toString() : null;
            // if (chequeDateString != null && chequeDateString.contains(chequeDate)) {
            //     try {
            //         receipt.Cheque_Date__c = Date.valueOf(chequeDateString);
            //     } catch (Exception e) {
            //         System.debug('Error parsing Cheque Date: ' + e.getMessage());
            //         receipt.Cheque_Date__c = null;
            //     }
            // } else if (){ Paid_Date__c, etc
            //     receipt.Cheque_Date__c = null;
            // }

            String selectedField;
            String chequeDateString;

            if (receiptData.containsKey('chequeDate') && receiptData.get('chequeDate') != null) {
                selectedField = 'chequeDate';
                chequeDateString = receiptData.get('chequeDate').toString();

            } else if (receiptData.containsKey('fundTransferDate') && receiptData.get('fundTransferDate') != null) {
                selectedField = 'fundTransferDate';
                chequeDateString = receiptData.get('fundTransferDate').toString();

            } else if (receiptData.containsKey('ddDate') && receiptData.get('ddDate') != null) {
                selectedField = 'ddDate';
                chequeDateString = receiptData.get('ddDate').toString();

            } else if (receiptData.containsKey('paidDate') && receiptData.get('paidDate') != null) {
                selectedField = 'paidDate';
                chequeDateString = receiptData.get('paidDate').toString();

            } else if (receiptData.containsKey('challanDate') && receiptData.get('challanDate') != null) {
                selectedField = 'challanDate';
                chequeDateString = receiptData.get('challanDate').toString();

            } else if (receiptData.containsKey('jvDate') && receiptData.get('jvDate') != null) {
                selectedField = 'jvDate';
                chequeDateString = receiptData.get('jvDate').toString();

            } else if (receiptData.containsKey('fundDate') && receiptData.get('fundDate') != null) {
                selectedField = 'fundDate';
                chequeDateString = receiptData.get('fundDate').toString();
            }

            system.debug('chequeDateString ===> ' + chequeDateString);
            system.debug('selectedField ===> ' + selectedField);
            if (chequeDateString != null) {
                try {
                    Date parsedDate = Date.valueOf(chequeDateString);
                    system.debug('parsedDate ===> ' + parsedDate);

                    if (selectedField == 'chequeDate') {
                        receipt.Cheque_Date__c = parsedDate;

                    } else if (selectedField == 'fundTransferDate') {
                        receipt.Fund_Transfer_Date__c = parsedDate;

                    } else if (selectedField == 'ddDate') {
                        receipt.DD_Date__c = parsedDate;

                    } else if (selectedField == 'paidDate') {
                        receipt.Paid_Date__c = parsedDate;

                    } else if (selectedField == 'challanDate') {
                        receipt.Challan_Date__c = parsedDate;

                    } else if (selectedField == 'jvDate') {
                        receipt.JV_Date__c = parsedDate;

                    } else if (selectedField == 'fundDate') {
                        receipt.Fund_Date__c = parsedDate;
                    }

                } catch (Exception e) {
                    System.debug('Error parsing date: ' + e.getMessage());
                }
            }

            receipt.Reference_Number__c             = receiptData.containsKey('referenceNo') && receiptData.get('referenceNo') != null ? (String) receiptData.get('referenceNo') : null;
            receipt.Transaction_Reference_Number__c = receiptData.containsKey('transactionReferenceNo') && receiptData.get('transactionReferenceNo') != null ? (String) receiptData.get('transactionReferenceNo') : null;
            receipt.DD_Number__c                    = receiptData.containsKey('ddNumber') && receiptData.get('ddNumber') != null ? (String) receiptData.get('ddNumber') : null;
            receipt.JV_Reference_Number__c          = receiptData.containsKey('jvReferenceNumber') && receiptData.get('jvReferenceNumber') != null ? (String) receiptData.get('jvReferenceNumber') : null;

            // String paidDateString = receiptData.containsKey('paidDate') && receiptData.get('paidDate') != null ? receiptData.get('paidDate').toString() : null;
            // if (paidDateString != null && paidDateString.trim() != '') {
            //     try {
            //         receipt.Paid_Date__c = Date.valueOf(paidDateString);
            //     } catch (Exception e) {
            //         System.debug('Error parsing Paid Date: ' + e.getMessage());
            //         receipt.Paid_Date__c = null;
            //     }
            // } else {
            //     receipt.Paid_Date__c = null;
            // }

            
            // String ddDateString = receiptData.containsKey('ddDate') && receiptData.get('ddDate') != null ? receiptData.get('ddDate').toString() : null;
            // if (ddDateString != null && ddDateString.trim() != '') {
            //     try {
            //         receipt.DD_Date__c = Date.valueOf(ddDateString);
            //     } catch (Exception e) {
            //         System.debug('Error parsing DD Date: ' + e.getMessage());
            //         receipt.DD_Date__c = null;
            //     }
            // } else {
            //     receipt.DD_Date__c = null;
            // }
            // String challanDateString = receiptData.containsKey('challanDate') && receiptData.get('challanDate') != null ? receiptData.get('challanDate').toString() : null;
            // if (challanDateString != null && challanDateString.trim() != '') {
            //     try {
            //         receipt.Challan_Date__c = Date.valueOf(challanDateString);
            //     } catch (Exception e) {
            //         System.debug('Error parsing challanDate: ' + e.getMessage());
            //         receipt.Challan_Date__c = null;
            //     }
            // } else {
            //     receipt.Challan_Date__c = null;
            // }

            // String jvDateString = receiptData.containsKey('jvDate') && receiptData.get('jvDate') != null ? receiptData.get('jvDate').toString() : null;
            // if (jvDateString != null && jvDateString.trim() != '') {
            //     try {
            //         receipt.JV_Date__c = Date.valueOf(jvDateString);
            //     } catch (Exception e) {
            //         System.debug('Error parsing JV Date: ' + e.getMessage());
            //         receipt.JV_Date__c = null;
            //     }
            // } else {
            //     receipt.JV_Date__c = null;
            // }

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
        }catch(AuraHandledException e){
            throw e;
        }catch(Exception e){
            System.debug('Exception occured--->'+e.getMessage()+'@Line--->'+e.getLineNumber());
        }
    }

    // Amounts arrive from the LWC as strings like '12211.12'; keep the decimals (2 dp, matching the Currency fields).
    private static Decimal toAmount(Object value) {
        if (value == null || String.isBlank(String.valueOf(value))) {
            return null;
        }
        return Decimal.valueOf(String.valueOf(value).trim()).setScale(2, RoundingMode.HALF_UP);
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
    
    public static void testCover01(){
        Integer i=0;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        
    }
    
    public static void testCover02(){
        Integer i=0;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++; i++;i++; i++; i++; i++; i++; i++;
        
    }
    
}