public withOut sharing class UpdatePaymentScheduleController {
    
    @AuraEnabled(cacheable=true)
    public static List<Payment_Schedule__c> getPaymentSchedules(Id opportunityId) {
        
        if (opportunityId == null) {
            throw new AuraHandledException('Opportunity Id cannot be null.');
        }
            
            return [SELECT Id, Name, Installment__c, Agreement_Value__c, Tax_Amount__c, Pay_Date__c, Due_Date__c 
                    FROM Payment_Schedule__c WHERE Opportunity__c = :opportunityId and Demand_Letter_Sent__c = false and Debit_Payment_Schedule__c = false];
        } 

    @AuraEnabled
    public static void savePaymentSchedule(List<Payment_Schedule__c> paymentSchedules) {
        
        if (paymentSchedules == null || paymentSchedules.isEmpty()) {
            throw new AuraHandledException('The list of payment schedules cannot be null or empty.');
        }
        validateDemandDates(paymentSchedules);
            
            update paymentSchedules;
      
    }

    public static final String FUTURE_DEMAND_DATE_ERROR = 'Demand Date cannot be a future date. Please select today\'s date or a past date.';

    /** Demand Date (Pay_Date__c) must be today or a past date. Shared by the single and bulk Update Due Date screens. */
    public static void validateDemandDates(List<Payment_Schedule__c> paymentSchedules) {
        Date today = Date.today();
        for (Payment_Schedule__c ps : paymentSchedules) {
            // Callers pass partially populated records, so only read fields that are present.
            Map<String, Object> populated = ps.getPopulatedFieldsAsMap();
            Date payDate = populated.containsKey('Pay_Date__c') ? (Date) populated.get('Pay_Date__c') : null;
            String name = populated.containsKey('Name') ? (String) populated.get('Name') : null;
            if (payDate != null && payDate > today) {
                String msg = FUTURE_DEMAND_DATE_ERROR + (String.isNotBlank(name) ? ' (' + name + ')' : '');
                AuraHandledException ex = new AuraHandledException(msg);
                ex.setMessage(msg);
                throw ex;
            }
        }
    }
}