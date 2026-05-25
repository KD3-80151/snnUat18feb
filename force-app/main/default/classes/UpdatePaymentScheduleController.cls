public withOut sharing class UpdatePaymentScheduleController {
    
    @AuraEnabled(cacheable=true)
    public static List<Payment_Schedule__c> getPaymentSchedules(Id opportunityId) {
        
        if (opportunityId == null) {
            throw new AuraHandledException('Opportunity Id cannot be null.');
        }
            
            return [SELECT Id, Name, Installment__c, Agreement_Value__c, Tax_Amount__c, Pay_Date__c, Due_Date__c 
                    FROM Payment_Schedule__c 
                    WHERE Opportunity__c = :opportunityId];
        } 

    @AuraEnabled
    public static void savePaymentSchedule(List<Payment_Schedule__c> paymentSchedules) {
        
        if (paymentSchedules == null || paymentSchedules.isEmpty()) {
            throw new AuraHandledException('The list of payment schedules cannot be null or empty.');
        }
            
            update paymentSchedules;
      
    }
}