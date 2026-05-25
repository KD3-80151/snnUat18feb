public without Sharing  class BulkSendDemandLetterController {
    public BulkSendDemandLetterController() {}
    
    public class FilterWrapper {
        @AuraEnabled public List<Project__c> projects;
        @AuraEnabled public List<Payment_Schedule_Master__c> installments;
    }
    
    @AuraEnabled(cacheable=true)
    public static FilterWrapper getFilters() {
        FilterWrapper wrapper = new FilterWrapper();
        wrapper.projects = [SELECT Id, Name FROM Project__c ORDER BY Name];
        wrapper.installments = [SELECT Id, Name FROM Payment_Schedule_Master__c ORDER BY Name];
        return wrapper;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Tower__c> getTowers(Id projectId) {
        return [SELECT Id, Name, Tower_Code__c FROM Tower__c WHERE Project__c = :projectId ORDER BY Name];
    }

    @AuraEnabled
    public static List<Map<String, Object>> getFilteredOpportunities(String projectId, String tower, String installmentName) {
        system.debug('projectId === ' + projectId);
        system.debug('tower === ' + tower);
        system.debug('installmentName === ' + installmentName);
        
        List<String> installmentNameList = (List<String>) JSON.deserialize(installmentName, List<String>.class);
        List<Opportunity> opportunities = [
       SELECT Id, Name, Project__c, Unit__r.Floor__r.Blocks__c, Unit__r.Name,
       Account.Id, Account.Name,  
       (SELECT Id, Name, Agreement_Value__c,Total_Due_Amount__c, Tax_Amount__c FROM Payment_Schedules__r WHERE Demand_Letter_Sent__c = false AND Due_Date__c = :Date.today().addDays(15))
       FROM Opportunity WHERE Project__c = :projectId AND Unit__r.Floor__r.Blocks__c = :tower];
        system.debug('opportunities === ' + opportunities);
        
        Set<Id> accountIds = new Set<Id>();
        for (Opportunity opp : opportunities) {
            if (opp.AccountId != null) {
                accountIds.add(opp.AccountId);
            }
        }
        
        Map<Id, Contact> accountToContactMap = new Map<Id, Contact>();
        if (!accountIds.isEmpty()) {
            List<Contact> contacts = [SELECT Id, Name, AccountId FROM Contact WHERE AccountId IN :accountIds];
            for (Contact contact : contacts) {
                accountToContactMap.put(contact.AccountId, contact);
            }
        }
        
        List<Map<String, Object>> filteredOpportunities = new List<Map<String, Object>>();
        
        // for (Opportunity opp : opportunities) {
        //     system.debug('Processing Opportunity: ' + opp.Id + ', ' + opp.Name);
        //     if (opp.Payment_Schedules__r != null && !opp.Payment_Schedules__r.isEmpty()) {
        //         Boolean hasInstallment = false;
        //         String matchingInstallmentName = null;
        //         Id matchingInstallmentId = null;
        //         Decimal installmentAgreementAmount = 0;
        //         for (Payment_Schedule__c ps : opp.Payment_Schedules__r) {
        //             system.debug('Checking Payment Schedule: ' + ps.Name);
        //             if (ps.Name != null && installmentName != null) {
        //                 if (ps.Name.trim().equalsIgnoreCase(installmentName.trim())) {
        //                     hasInstallment = true;
        //                     matchingInstallmentName = ps.Name;
        //                     matchingInstallmentId = ps.Id;
        //                     installmentAgreementAmount = ps.Agreement_Value__c;
        //                     break;
        //                 }
        //             }
        //         }
                
        //         if (hasInstallment) {
        //             Map<String, Object> opportunityMap = new Map<String, Object>();
        //             opportunityMap.put('Id', opp.Id);
        //             opportunityMap.put('UnitName', opp.Unit__r.Name);
        //             opportunityMap.put('InstallmentName', matchingInstallmentName);
        //             opportunityMap.put('InstallmentId', matchingInstallmentId); // Add Installment ID
        //             opportunityMap.put('InstallmentAgreementAmount', installmentAgreementAmount);
                    
        //             Contact associatedContact = accountToContactMap.get(opp.AccountId);
        //             opportunityMap.put('ContactName', associatedContact != null ? associatedContact.Name : null);
                    
        //             filteredOpportunities.add(opportunityMap);
        //             system.debug('Added to filteredOpportunities: ' + opportunityMap);
        //         }
        //     } else {
        //         system.debug('No related Payment Schedules for Opportunity: ' + opp.Id);
        //     }
        // }
        for (Opportunity opp : opportunities) {
            system.debug('Processing Opportunity: ' + opp.Id + ', ' + opp.Name);
             System.debug('Payment Schedules Count: ' + (opp.Payment_Schedules__r != null ? opp.Payment_Schedules__r.size() : 0));
            if (opp.Payment_Schedules__r != null && !opp.Payment_Schedules__r.isEmpty()) {
                
           
                for (Payment_Schedule__c ps : opp.Payment_Schedules__r) {
                    system.debug('Checking Payment Schedule: ' + ps.Name);
                    if (ps.Name != null && installmentNameList.contains(ps.Name.trim())) {
                         Map<String, Object> opportunityMap = new Map<String, Object>();
                        if(ps.Total_Due_Amount__c > 0){
                            
                            opportunityMap.put('Id', opp.Id);
                            opportunityMap.put('UnitName', opp.Unit__r.Name);
                            opportunityMap.put('InstallmentName', ps.Name);
                            opportunityMap.put('InstallmentId', ps.Id);
                            opportunityMap.put('InstallmentAgreementAmount', ps.Agreement_Value__c);
                            
                            Contact associatedContact = accountToContactMap.get(opp.AccountId);
                            opportunityMap.put('ContactName', associatedContact != null ? associatedContact.Name : null);
                            
                            filteredOpportunities.add(opportunityMap);

                        }
                        
                       
                        system.debug('Added to filteredOpportunities: ' + opportunityMap);
                    }
                }
            } else {
                system.debug('No related Payment Schedules for Opportunity: ' + opp.Id);
            }
        }
        
        system.debug('filteredOpportunities === ' + filteredOpportunities);
        return filteredOpportunities;
    }
    @AuraEnabled
    public static  void sendInstallmentIds(List<Id> installmentIds) {
        
        System.debug('Installment IDs received: ' + installmentIds);
        List<Payment_Schedule__c> paymentSchedules;
        if(installmentIds != null){
            
            paymentSchedules = [Select id,Opportunity__c,Tax_Amount__c,Agreement_Value__c from Payment_Schedule__c where Id IN :installmentIds ];
            
            Map<Id, List<Payment_Schedule__c>> oppToPaymentsMap = new Map<Id, List<Payment_Schedule__c>>();
            for (Payment_Schedule__c ps : paymentSchedules) {
                System.debug('ps ===> ' + ps);
                if (!oppToPaymentsMap.containsKey(ps.Opportunity__c)) {
                    oppToPaymentsMap.put(ps.Opportunity__c, new List<Payment_Schedule__c>());
                }
                oppToPaymentsMap.get(ps.Opportunity__c).add(ps);
                System.debug('oppToPaymentsMap ===> ' + oppToPaymentsMap);
            }
            
            System.debug('oppToPaymentsMap.size() ===> '+ oppToPaymentsMap.size());
            if(oppToPaymentsMap.size() > 0){
                System.debug('inside oppMap');
                Map<String, List<String>> oppIdByContentVersionIds = new Map<String, List<String>>();
                System.enqueueJob(new QueueableToGenerateDemandLetter(oppToPaymentsMap, oppIdByContentVersionIds));
            }
            
        }
        
    }
}