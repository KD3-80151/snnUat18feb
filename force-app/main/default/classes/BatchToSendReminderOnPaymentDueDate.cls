public without Sharing  class BatchToSendReminderOnPaymentDueDate implements Database.Batchable<sObject> {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        Date weekBefore = System.today().addDays(-7);
        return Database.getQueryLocator([SELECT Id, Opportunity__c,Opportunity__r.Name, Opportunity__r.Email__c, Due_Date__c, Name,Agreement_Value__c FROM Payment_Schedule__c WHERE Opportunity__c != NULL AND Due_Date__c =: weekBefore ]);
    }

    public void execute(Database.BatchableContext bc, List<Payment_Schedule__c> paymentSchedules) {
        try {
            Map<Id, List<Payment_Schedule__c>> oppToPaymentsMap = new Map<Id, List<Payment_Schedule__c>>(); 
            Set<Id> oppIds = new Set<Id>();

            for (Payment_Schedule__c ps : paymentSchedules) {
                System.debug('ps ===> ' + ps);
                if (!oppToPaymentsMap.containsKey(ps.Opportunity__c)) {
                    oppToPaymentsMap.put(ps.Opportunity__c, new List<Payment_Schedule__c>());
                }
                oppToPaymentsMap.get(ps.Opportunity__c).add(ps);
                oppIds.add(ps.Opportunity__c);
                System.debug('oppToPaymentsMap ===> ' + oppToPaymentsMap);
            }

            if(oppToPaymentsMap.size() > 0){
                Map<String, List<String>> oppIdByContentVersionIds = new Map<String, List<String>>();
                System.enqueueJob(new QueueableToGenerateDemandLetter(oppToPaymentsMap, oppIdByContentVersionIds));
            }
        } catch (Exception e) {
            System.debug('Error occurred in execute method: ' + e.getMessage());
            System.debug('Line number: ' + e.getLineNumber());
        }
    }

    public void finish(Database.BatchableContext bc) {
        system.debug('Batch executed successfully !!!!');
    }

    
}