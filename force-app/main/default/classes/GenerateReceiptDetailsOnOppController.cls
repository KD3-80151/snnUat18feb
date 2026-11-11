public without sharing class GenerateReceiptDetailsOnOppController {

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


    public class PricingPaymentSchedWrapper{
        @AuraEnabled public String label;
        @AuraEnabled public String value;

        public PricingPaymentSchedWrapper(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }

    public class PaymentScheduleOptionWrapper{
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        @AuraEnabled public Decimal totalDueAmount;

        public PaymentScheduleOptionWrapper(String label, String value, Decimal totalDueAmount) {
            this.label = label;
            this.value = value;
            this.totalDueAmount = totalDueAmount;
        }
    }

    @AuraEnabled
    public static List<PricingPaymentSchedWrapper> getPricingElements(Id oppId){
        try {
            list<PricingPaymentSchedWrapper> pEOptions = new list<PricingPaymentSchedWrapper>();
            if(oppId == null) return pEOptions;

            list<Pricing_Element_Master__c> peMasterList = [SELECT Id, Name FROM Pricing_Element_Master__c];

            for (Pricing_Element_Master__c peMaster : peMasterList) {
                pEOptions.add(new PricingPaymentSchedWrapper(peMaster.Name, peMaster.Id));
            }
            System.debug('pEOptions is '+pEOptions);
            System.debug('pEOptions is '+pEOptions.size());
            return pEOptions;
        } catch (Exception e) {
            System.debug('Error mesage is '+e.getMessage());
            System.debug('Error line is '+e.getLineNumber());
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<PaymentScheduleOptionWrapper> getDebitPaymentSchedules(Id oppId){
        try {
            List<PaymentScheduleOptionWrapper> scheduleOptions = new List<PaymentScheduleOptionWrapper>();
            if (oppId == null) {
                return scheduleOptions;
            }

            List<Payment_Schedule__c> debitSchedules = [
                SELECT Id, Name, Total_Due_Amount__c
                FROM Payment_Schedule__c
                WHERE Opportunity__c = :oppId
                AND Debit_Payment_Schedule__c = true
                AND Total_Due_Amount__c > 0
                ORDER BY CreatedDate DESC
            ];

            for (Payment_Schedule__c ps : debitSchedules) {
                String totalDue = ps.Total_Due_Amount__c != null ? String.valueOf(ps.Total_Due_Amount__c) : '0';
                scheduleOptions.add(new PaymentScheduleOptionWrapper(ps.Name + ' - Total Due: ' + totalDue, ps.Id, ps.Total_Due_Amount__c));
            }

            return scheduleOptions;
        } catch (Exception e) {
            System.debug('Error in getDebitPaymentSchedules ==> ' + e.getMessage());
            System.debug('Error line ==> ' + e.getLineNumber());
            throw new AuraHandledException(e.getMessage());
        }
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
            if (String.isNotBlank(receipt.PAN_TAN_Number__c) && !Pattern.matches('^[A-Za-z]{5}[0-9]{4}[A-Za-z]{1}$', receipt.PAN_TAN_Number__c)) {
                throw new AuraHandledException('Please enter a valid PAN Number in the format ABCDE1234F.');
            }
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
            receipt.Credit_Debit_Note_Date__c = receiptData.containsKey('creditDebitDate') && receiptData.get('creditDebitDate') != null ?  Date.valueOf((String)receiptData.get('creditDebitDate')) : null;
            receipt.Description__c = receiptData.containsKey('description') && receiptData.get('description') != null ? (String) receiptData.get('description') : null;
            

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

            receipt.Reference_Number__c = receiptData.containsKey('referenceNo') && receiptData.get('referenceNo') != null ? (String) receiptData.get('referenceNo') : null;
            receipt.Transaction_Reference_Number__c = receiptData.containsKey('transactionReferenceNo') && receiptData.get('transactionReferenceNo') != null ? (String) receiptData.get('transactionReferenceNo') : null;
            receipt.DD_Number__c = receiptData.containsKey('ddNumber') && receiptData.get('ddNumber') != null ? (String) receiptData.get('ddNumber') : null;
            receipt.JV_Reference_Number__c = receiptData.containsKey('jvReferenceNumber') && receiptData.get('jvReferenceNumber') != null ? (String) receiptData.get('jvReferenceNumber') : null;

            if(receiptData.containsKey('pricingElementId') && receiptData.get('pricingElementId') != null){
                receipt.Pricing_Element_Master__c = (String)receiptData.get('pricingElementId');
            }

            if(receiptData.containsKey('paymentScheduleId') && receiptData.get('paymentScheduleId') != null){
                receipt.Payment_Schedule__c = (String)receiptData.get('paymentScheduleId');
            }

            if(receiptData.containsKey('againstDebit') && receiptData.get('againstDebit') != null){
                receipt.Against_Debit__c = (Boolean) receiptData.get('againstDebit');
            }
            if(
                receiptData.containsKey('againstDebit') &&
                receiptData.get('againstDebit') != null &&
                String.valueOf(receiptData.get('againstDebit')) == 'true' &&
                receiptData.containsKey('paymentScheduleId') &&
                receiptData.get('paymentScheduleId') != null
            ){
                receipt.Payment_Schedule__c = (String)receiptData.get('paymentScheduleId');
            }

            
            if(receiptData.containsKey('taxMasterCgst') && receiptData.get('taxMasterCgst') != null){
                receipt.Tax_Master_CGST__c = (String)receiptData.get('taxMasterCgst');
            }

            if(receiptData.containsKey('taxMasterSgst') && receiptData.get('taxMasterSgst') != null){
                receipt.Tax_Master_SGST__c = (String)receiptData.get('taxMasterSgst');
            }

            Boolean hasTaxMasterCgst = receiptData.containsKey('taxMasterCgst') && receiptData.get('taxMasterCgst') != null;
            Boolean hasTaxMasterSgst = receiptData.containsKey('taxMasterSgst') && receiptData.get('taxMasterSgst') != null;

            if (receipt.Type__c == 'Credit' && hasTaxMasterCgst && hasTaxMasterSgst) {
                receipt.Tax_Invoice_Included__c = true;
            }


            System.debug('receipt==>'+receipt);
            insert receipt;
            System.debug('After Insertipn Of receipt==>'+receipt);

                try {
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setObjectId(receipt.Id);
        req.setProcessDefinitionNameOrId('Receipt_Approval_Process');
        Approval.ProcessResult result = Approval.process(req);

        receipt.Approval_Status__c = 'Sent';
        update receipt;

        } catch (Exception ex) {
            receipt.Approval_Status__c = 'Approval Failed';
            update receipt;

            throw new AuraHandledException('Receipt created but approval failed: ' + ex.getMessage());
        }

        } catch (AuraHandledException e) {
            throw e;
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