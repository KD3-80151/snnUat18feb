public without Sharing  class bulkUpdateDueDateController {
    @AuraEnabled(cacheable=true)
    public static List<Company__c> getAllCompanies() {
        try {
            return [SELECT Id, Name FROM Company__c];
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving companies: ' + e.getMessage());
        }
    }
    @AuraEnabled(cacheable=true)
    public static List<Project__c> getProjects(Id companyId) {
        if (companyId == null) {
            throw new AuraHandledException('Company ID cannot be null.');
        }
        try {
            return [SELECT Id, Name FROM Project__c WHERE Company__c = :companyId];
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving projects: ' + e.getMessage());
        }
    }
    @AuraEnabled(cacheable=true)
    public static List<Tower__c> getBlocks(Id projectId) {
        if (projectId == null) {
            throw new AuraHandledException('Project ID cannot be null.');
        }
        try {
            return [SELECT Id, Name FROM Tower__c WHERE Project__c = :projectId];
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving blocks: ' + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Payment_Scheme__c> getpaymentScheme(Id companyID,Id projectId,Id blockId) {
        if (companyID == null  &&  projectId == null &&  blockId == null) {
            throw new AuraHandledException('Project ID cannot be null.');
        }
        try {
            return [SELECT Id,Name  FROM Payment_Scheme__c where Company__c =: companyID AND Project__c =: projectId AND Block__c =:blockId];
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving blocks: ' + e.getMessage());
        }
    }
    @AuraEnabled(cacheable=true)
    public static List<Cost_Scheme_Linking__c> getCostScheamLinking(Id paymentScheme) {
        if (paymentScheme == null  ) {
            throw new AuraHandledException('Project ID cannot be null.');
        }
        try {
            return [Select id ,Cost_Sheet_Template__r.Name from Cost_Scheme_Linking__c where Payment_Scheme__c =: paymentScheme];
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving blocks: ' + e.getMessage());
        }
    }
    @AuraEnabled(cacheable=true)
    public static List <Payment_Scheme_Installment__c> getPaymentInstallment(Id paymentScheme) {
        if (paymentScheme == null  ) {
            throw new AuraHandledException('Project ID cannot be null.');
        }
        try {
            return [Select id ,Payment_Schedule_Master__r.Name from Payment_Scheme_Installment__c where Payment_Scheme__c =: paymentScheme];
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving blocks: ' + e.getMessage());
        }
    }
    
    
    @AuraEnabled
    public static void saveTableData(String payload) {
        try {
            system.debug('payload==='+payload);
            Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(payload);
            
            String projectId = (String) data.get('projectId');
            system.debug('projectId==='+projectId);
            
            String paymentSchemeId = (String) data.get('paymentSchemeId');
            system.debug('paymentSchemeId==='+paymentSchemeId);
            
            Object rawPaymentInstallments = data.get('paymentInstallments');
            System.debug('Raw Payment Installments: ' + rawPaymentInstallments);
            
            List<PaymentInstallmentWrapper> paymentInstallments =(List<PaymentInstallmentWrapper>) JSON.deserialize(JSON.serialize(rawPaymentInstallments),List<PaymentInstallmentWrapper>.class);
            System.debug('Deserialized Payment Installments: ' + paymentInstallments);
            if (paymentInstallments == null || paymentInstallments.isEmpty()) {
                throw new AuraHandledException('No payment installments provided.');
            }
            
            List<Opportunity> opportunities = [SELECT Id FROM Opportunity WHERE Project__c = :projectId AND Payment_Scheme__c = :paymentSchemeId];
            system.debug('opportunities==='+opportunities);
            if (opportunities == null) {
                throw new AuraHandledException('Opportunity not found for the given ProjectId and PaymentSchemeId.');
            }
            
            set<id> OppId = new Set<id>();
            if(!opportunities.IsEmpty()){
                for(Opportunity opp : opportunities){
                    OppId.add(opp.Id);
                }
            }
            Map<String, PaymentInstallmentWrapper> installmentMap = new Map<String, PaymentInstallmentWrapper>();
            for (PaymentInstallmentWrapper installment : paymentInstallments) {
                installmentMap.put(installment.Name, installment);
            }
            System.debug('installmentMap ===> ' + installmentMap);
            System.debug('OppId==>'+OppId);
            List<Payment_Schedule__c> paymentSchedules = [SELECT Id, Name, Due_Date__c, Pay_Date__c FROM Payment_Schedule__c WHERE Opportunity__c IN : OppId AND Demand_Letter_Sent__c =false ];
            System.debug('paymentSchedules ===> ' + paymentSchedules);
            
            List<Payment_Schedule__c> schedulesToUpdate = new List<Payment_Schedule__c>();
            for (Payment_Schedule__c schedule : paymentSchedules) {
                if (installmentMap.containsKey(schedule.Name)) {
                    PaymentInstallmentWrapper installment = installmentMap.get(schedule.Name);
                    System.debug('installment.dueDate ===> ' + installment.dueDate + ' uyku ' + installment.payByDate);
                    // schedule.Due_Date__c = schedule.Due_Date__c == null ? installment.dueDate : schedule.Due_Date__c;
                    // schedule.Pay_Date__c = schedule.Pay_Date__c == null ? installment.payByDate : schedule.Pay_Date__c;
                    schedule.Due_Date__c = installment.dueDate;
                    schedule.Pay_Date__c = installment.payByDate;
                    schedulesToUpdate.add(schedule);
                    system.debug('schedulesToUpdate==>'+schedule);
                }
            }
            
            if (!schedulesToUpdate.isEmpty()) {
                update schedulesToUpdate;
                System.debug('Updated Payment Schedules =============>'+schedulesToUpdate);
            }
        } catch (Exception e) {
            System.debug('error ===> ' + e.getMessage());
            System.debug('error ===> ' + e.getLineNumber());
        }
        
    }
    public class PaymentInstallmentWrapper {
        @AuraEnabled public String id; // Installment record Id
        @AuraEnabled public String Name; // Installment Name
        @AuraEnabled public Date dueDate; // Due Date
        @AuraEnabled public Date payByDate; // Pay By Date
    }
    @AuraEnabled
    public static List <Payment_Schedule__c> getSelectedOppPaymentSchedules(Id opportunityId) {
        if (opportunityId == null  ) {
            throw new AuraHandledException('Opportunity ID cannot be null.');
        }
        try {
            return [SELECT Id,Name,Due_Date__c,Pay_Date__c  FROM Payment_Schedule__c  WHERE Opportunity__c  =: opportunityId];
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving Payment Schedules: ' + e.getMessage());
        }
    }
  @AuraEnabled
public static String saveOppsPaySchedulesSave(String paymentSchedules) {
    if(String.isBlank(paymentSchedules)) {
        throw new AuraHandledException('No JSON data received');
    }

    try {
        System.debug('JSON DATA========>' + paymentSchedules);

        List<Object> tempList = (List<Object>) JSON.deserializeUntyped(paymentSchedules);
        List<Payment_Schedule__c> paySchedulesToUpdt = new List<Payment_Schedule__c>();

        for (Object o : tempList) {
            Map<String,Object> wrapMap = (Map<String,Object>) o;

            PaymentScheduleWrapper wrap = new PaymentScheduleWrapper();
            wrap.id = (String) wrapMap.get('Id');
            wrap.dueDateStr = (String) wrapMap.get('Due_Date__c');
            wrap.payDateStr = (String) wrapMap.get('Pay_Date__c');

            Payment_Schedule__c ps = new Payment_Schedule__c();
            ps.Id = wrap.id;
            ps.Due_Date__c = wrap.getDueDate();
            ps.Pay_Date__c = wrap.getPayDate();

            paySchedulesToUpdt.add(ps);
            System.debug('Updating Record: ' + ps);
        }

        if(!paySchedulesToUpdt.isEmpty()) {
            update paySchedulesToUpdt;
        }

        return 'success';
    } catch (Exception e) {
        System.debug('Error =========>' + e.getLineNumber() + '===========>' + e.getMessage());
        throw new AuraHandledException('Error updating Payment Schedules: ' + e.getMessage());
    }
}

// Wrapper
public class PaymentScheduleWrapper {
    public Id id;
    public String dueDateStr;
    public String payDateStr;

    public Date getDueDate() {
        return dueDateStr != null ? Date.valueOf(dueDateStr) : null;
    }
    public Date getPayDate() {
        return payDateStr != null ? Date.valueOf(payDateStr) : null;
    }
}

}