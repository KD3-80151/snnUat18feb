public class GenerateReceiptDetailsOnOppController {

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
     public static List<Account> getAccountValues(String oppId) {
        Set<Id> allAccountIds = new Set<Id>();
        List<Account> allAccounts = new List<Account>();
        try{
            System.debug('oppId==>'+oppId);
            if(String.isNotBlank(oppId)){
                List<Opportunity> oppRecord = [select Id,AccountId  from Opportunity Where Id =:oppId Limit 1];
                List<Applicant__c > applicantRecords = [select Id,Opportunity__c,Opportunity__r.AccountId,Opportunity__r.Account.Name,Account__c,Account__r.Name from Applicant__c where Opportunity__c  =: oppId];
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
        try {
            System.debug('receiptData ====> ' + receiptData);
            System.debug('accId ====> ' + accId);

            Receipt__c receipt = new Receipt__c();

            if (receiptData.containsKey('opportunityId') && receiptData.get('opportunityId') != null) {
                String oppId = (String) receiptData.get('opportunityId');
                System.debug('oppId ==>' + oppId);
                receipt.Opportunity__c = oppId;
                if(String.isNotBlank(accId)){
                    receipt.Account__c = accId;
                }
            }
            
           
            // Demand_Letter__c dl = [SELECT id, Name,mainDemandLetter__c FROM Demand_Letter__c WHERE  mainDemandLetter__c = True LIMIT 1];
            // System.debug('dl========>'+dl);
            receipt.Receipt_Date__c = System.Today();
            receipt.Type__c = receiptData.containsKey('receiptType') && receiptData.get('receiptType') != null ? (String) receiptData.get('receiptType') : null;
            //receipt.Token_Amount__c = TRUE;
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
            receipt.Fund_Transfer_Date__c = receiptData.containsKey('fundDate') && receiptData.get('fundDate') != null ?  Date.valueOf((String)receiptData.get('fundDate')) : null;

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
            System.debug('receipt==>'+receipt);
            insert receipt;
            System.debug('After Insertipn Of receipt==>'+receipt);

            Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
            req.setObjectId(receipt.Id);
            req.setProcessDefinitionNameOrId('Receipt_Approval_Process');
            Approval.ProcessResult result = Approval.process(req);
            receipt.Approval_Status__c = 'Sent';
            update receipt;

        } catch (Exception e) {
            System.debug('Exception occurred--->' + e.getMessage() + '@Line--->' + e.getLineNumber());
        }
    }

    @AuraEnabled
    public static Boolean checkDuplicate(String oppId, String type, String uniqueNumber) {
        System.debug('DD Number or Cheque Number --->'+uniqueNumber);
        if(uniqueNumber != null && uniqueNumber.trim() != '' && oppId != null && oppId != ''){
            List<Receipt__c> receipts = new List<Receipt__c>();
            if(type == 'DD'){
                receipts = [SELECT Id FROM Receipt__c WHERE DD_Number__c = :uniqueNumber AND Opportunity__c = :oppId LIMIT 1];
            }else if(type == 'Cheque'){
                receipts = [SELECT Id FROM Receipt__c WHERE Cheque_Number__c = :uniqueNumber AND Opportunity__c = :oppId LIMIT 1];
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