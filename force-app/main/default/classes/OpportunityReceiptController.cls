public with sharing class OpportunityReceiptController {

     @AuraEnabled(cacheable=false)
    public static List<Tax_Invoice__c> getTaxInvoices(Date startDate, Date endDate) {

        if (startDate == null || endDate == null) {
            return new List<Tax_Invoice__c>();
        }

        Datetime startDt = Datetime.newInstance(startDate.year(), startDate.month(), startDate.day(), 0, 0, 0);
        Datetime endExclusive = Datetime.newInstance(endDate.year(), endDate.month(), endDate.day(), 0, 0, 0).addDays(1);

        return [
            SELECT Id, Name, GST_Paid__c, CreatedDate, Payment_Schedule__c, Account__c, 
                Account__r.Name, Payment_Schedule__r.Name, Receipt__c, Receipt__r.Name, 
                CGST_new__c, SGST_new__c, Total_Tax_Amount__c, Received_Amount__c,
                Receipt__r.Receipt_Date__c, Receipt__r.Receipt_Number__c,
                Opportunity__c,Opportunity__r.Name,
                Opportunity__r.Project__c,
                Opportunity__r.Project__r.Name,
                Opportunity__r.Project__r.Company__c,
                Opportunity__r.Project__r.Company__r.Name,
                Opportunity__r.Unit__r.Floor__r.Blocks__c,
                Opportunity__r.Unit__r.Floor__r.Blocks__r.Name
            FROM Tax_Invoice__c
            WHERE CreatedDate >= :startDt
            AND CreatedDate < :endExclusive
            AND GST_Paid__c = false
            ORDER BY CreatedDate DESC
        ];
    }

    @AuraEnabled
    public static void markGSTPaidForInvoices(List<Id> taxInvoiceIds, Date taxPaidDate) {
        system.debug('taxInvoiceIds:::>> ' + taxInvoiceIds);
        if (taxInvoiceIds == null || taxInvoiceIds.isEmpty()) return;

        List<Tax_Invoice__c> taxInvoices = [SELECT Id, GST_Paid__c, Payment_Schedule__c, Payment_Schedule__r.Id, Payment_Schedule__r.Demand_Letter_Sent__c,
                Payment_Schedule__r.GST_Amount_Paid__c, Payment_Schedule__r.GST_Paid__c, Tax_Paid_Date__c FROM Tax_Invoice__c WHERE Id IN :taxInvoiceIds
        ];

        if (taxInvoices.isEmpty()) return;

        for (Tax_Invoice__c ti : taxInvoices) {
            ti.GST_Paid__c = true;
            if (taxPaidDate != null) {
            ti.Tax_Paid_Date__c = taxPaidDate;
        }
        }
        update taxInvoices;

        Map<Id, Payment_Schedule__c> psToUpdate = new Map<Id, Payment_Schedule__c>();

        for (Tax_Invoice__c ti : taxInvoices) {
            if (ti.Payment_Schedule__c == null || ti.Payment_Schedule__r == null) continue;

            Boolean demandSent = (ti.Payment_Schedule__r.Demand_Letter_Sent__c == true);
            Decimal gstAmtPaid = ti.Payment_Schedule__r.GST_Amount_Paid__c;

            Boolean shouldMarkPaid = demandSent || (!demandSent && gstAmtPaid != null && gstAmtPaid == 0) || (!demandSent && gstAmtPaid == null);

            if (shouldMarkPaid) {
                if (!psToUpdate.containsKey(ti.Payment_Schedule__c)) {
                    psToUpdate.put(
                        ti.Payment_Schedule__c,
                        new Payment_Schedule__c(Id = ti.Payment_Schedule__c, GST_Paid__c = true)
                    );
                }
            }
        }

        if (!psToUpdate.isEmpty()) {
            update psToUpdate.values();
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<WrapperOppReceipts> getOpportunityReceipts() {
        Date firstDay = Date.today().toStartOfMonth();
        Date lastDay = Date.today().toStartOfMonth().addMonths(1).addDays(-1);

        List<Receipt__c> receipts = [
            SELECT Id, Opportunity__r.Name,Opportunity__c, Name, Amount__c, Total_GST__c, Amount_Paid_Excluding_TAX__c, CGST__c, SGST__c, Receipt_Date__c, Approval_Status__c, Reference_Number__c, Bank__c
            FROM Receipt__c WHERE Receipt_Date__c >= :firstDay AND Receipt_Date__c <= :lastDay ORDER BY Opportunity__r.Name
        ];

        Map<Id, WrapperOppReceipts> oppMap = new Map<Id, WrapperOppReceipts>();
        Map<Id, Id> receiptToOpp = new Map<Id, Id>();

        for (Receipt__c r : receipts) {
            if (r.Opportunity__c == null) continue;

            if (!oppMap.containsKey(r.Opportunity__c)) {
                oppMap.put(
                    r.Opportunity__c,
                    new WrapperOppReceipts(r.Opportunity__c, r.Opportunity__r.Name)
                );
            }
            oppMap.get(r.Opportunity__c).receipts.add(r);
            receiptToOpp.put(r.Id, r.Opportunity__c);
        }

        if (receiptToOpp.isEmpty()) {
            return oppMap.values();
        }

        List<Tax_Invoice__c> taxInvoices = [
            SELECT Id, Receipt__c, Payment_Schedule__c, Payment_Schedule__r.Id, Payment_Schedule__r.Name, Payment_Schedule__r.Tax_Amount__c, Payment_Schedule__r.Total_Due_Amount__c, Payment_Schedule__r.Tax_Payment_Status_to_Government__c
            FROM Tax_Invoice__c WHERE Receipt__c IN :receiptToOpp.keySet() AND Payment_Schedule__c != null and Payment_Schedule__r.Demand_Letter_Sent__c = true
        ];

        Map<Id, Map<Id, Payment_Schedule__c>> oppToPsMap = new Map<Id, Map<Id, Payment_Schedule__c>>();

        for (Tax_Invoice__c ti : taxInvoices) {
            Id oppId = receiptToOpp.get(ti.Receipt__c);
            System.debug('oppId:::>>' + oppId);
            if (oppId == null) continue;

            WrapperOppReceipts wrap = oppMap.get(oppId);
            if (wrap == null) continue;

            if (!oppToPsMap.containsKey(oppId)) {
                oppToPsMap.put(oppId, new Map<Id, Payment_Schedule__c>());
            }
            Map<Id, Payment_Schedule__c> psMap = oppToPsMap.get(oppId);

            Id psId = ti.Payment_Schedule__c;
            if (psId == null) continue;

            if (!psMap.containsKey(psId)) {
                psMap.put(psId, ti.Payment_Schedule__r);
                wrap.paymentSchedules.add(ti.Payment_Schedule__r);
            }

            if (ti.Payment_Schedule__r.Tax_Amount__c != null) {
                wrap.totalGST += ti.Payment_Schedule__r.Tax_Amount__c;
            }
        }

        return oppMap.values();
    }

    @AuraEnabled
    public static void markGSTPaid(Id oppId) {
        List<Receipt__c> receipts = [SELECT Id, Total_GST__c, Approval_Status__c FROM Receipt__c WHERE Opportunity__c = :oppId  AND Receipt_Date__c = THIS_MONTH];

        for (Receipt__c r : receipts) {
            //r.Approval_Status__c = 'GST Paid'; // ✅ Update field
        }
        update receipts;
    }

    //added by sagar 17/11
    @AuraEnabled
    public static void markAllGSTPaid(){
        Date firstDay = Date.today().toStartOfMonth();
        Date lastDay = Date.today().toStartOfMonth().addMonths(1).addDays(-1);

        list<Receipt__c> receipts = [SELECT Id, Total_GST__c, Approval_Status__c FROM Receipt__c WHERE Receipt_Date__c >= :firstDay AND Receipt_Date__c <= :lastDay];

        if(receipts.isEmpty()){
            return;
        }   

        Set<Id> receiptsIds = new Set<Id>();
        for(Receipt__c rec : receipts){
            receiptsIds.add(rec.Id);
        }

        list<Tax_Invoice__c> latestTaxInvoices = [
            SELECT Id, Payment_Schedule__c, Payment_Schedule__r.GST_Paid__c, Receipt__c FROM Tax_Invoice__c WHERE Receipt__c IN :receiptsIds AND Payment_Schedule__c != null AND CreatedDate  = THIS_MONTH];
        
        if(latestTaxInvoices.isEmpty()){
            return;
        }

        Set<Id> paymentScheduleIds = new Set<Id>();
        for(Tax_Invoice__c taxInv : latestTaxInvoices){
            paymentScheduleIds.add(taxInv.Payment_Schedule__c);
        }

        list<Payment_Schedule__c> paymentSchedulesToUpdate = [
            SELECT Id, GST_Paid__c, Total_Due_Amount__c, Tax_Payment_Status_to_Government__c FROM Payment_Schedule__c WHERE Id IN :paymentScheduleIds];
            system.debug('paymentSchedulesToUpdate:::>> ' + paymentSchedulesToUpdate);
            if(paymentSchedulesToUpdate.isEmpty()){
                return;
            }

        for(Payment_Schedule__c ps : paymentSchedulesToUpdate){
            ps.GST_Paid__c = true;
            if(ps.Total_Due_Amount__c == 0){
                ps.Tax_Payment_Status_to_Government__c = 'Fully Paid';
            }
            else {
                ps.Tax_Payment_Status_to_Government__c = 'Partially Paid';
            }
        }

        if (!paymentSchedulesToUpdate.isEmpty()) {
            update paymentSchedulesToUpdate;
        }
    }

    public class WrapperOppReceipts {
        @AuraEnabled public Id oppId;
        @AuraEnabled public String oppName;
        @AuraEnabled public List<Receipt__c> receipts = new List<Receipt__c>();
        @AuraEnabled public List<Payment_Schedule__c> paymentSchedules = new List<Payment_Schedule__c>();
        @AuraEnabled public Decimal totalGST;

        public WrapperOppReceipts(Id id, String name) {
            oppId = id;
            oppName = name;
            totalGST = 0;
        }
    }
}