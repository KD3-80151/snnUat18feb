public without sharing class ReceiptReAllocationController {
    public ReceiptReAllocationController() {}

    @AuraEnabled(cacheable=true)
    public static List<Company__c> fetchCompanyDetails(){
        try {
            List<Company__c> companyList = [SELECT Id,Name from Company__c];
            return companyList.isEmpty() ? null : companyList;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Project__c> fetchProjectDetails(Id companyId){
        try {
            List<Project__c> projectList = [SELECT Id,Name from Project__c WHERE Company__c =: companyId];
            return projectList.isEmpty() ? null : projectList;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Tower__c> fetchBlockDetails(Id projectId){
        try {
            List<Tower__c> blockList = [SELECT Id,Name from Tower__c WHERE Project__C =: projectId];
            return blockList.isEmpty() ? null : blockList;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<clientWrapper> getAllClients(Id BlockId) {
        if (BlockId == null) {
            throw new AuraHandledException('BlockId cannot be null');
        }
        
        List<clientWrapper> clientList = new List<clientWrapper>();

        List<Opportunity> oppList = [
            SELECT Id, Name, AccountId, Unit__c, Amount, StageName, Account.Name, Agreement_Value__c, Total_Amount_Collected__c, Balance_Total_Due_Amount__c
            FROM Opportunity 
            WHERE Unit__r.Floor__r.Blocks__r.Id = :BlockId
        ];
        
        if (oppList == null || oppList.isEmpty()) {
            return clientList;
        }

        Map<Id, Integer> receiptCountMap = new Map<Id, Integer>();

        List<AggregateResult> receiptCounts = [
            SELECT Opportunity__c opId, COUNT(Id) totalReceipts 
            FROM Receipt__c 
            WHERE Opportunity__c IN :oppList 
            GROUP BY Opportunity__c
        ];
        
        if (receiptCounts != null && !receiptCounts.isEmpty()) {
            for (AggregateResult ar : receiptCounts) {
                if (ar != null && ar.get('opId') != null) {
                    receiptCountMap.put((Id) ar.get('opId'), (Integer) ar.get('totalReceipts'));
                }
            }
        }

        for (Opportunity opp : oppList) {
            if (opp != null) {
                Integer receiptCount = receiptCountMap.containsKey(opp.Id) ? receiptCountMap.get(opp.Id) : 0;
                clientList.add(new clientWrapper(opp, receiptCount));
            }
        }

        system.debug('clientList ===> '+clientList);
        return clientList;
    }

    public class clientWrapper {
        @AuraEnabled public Opportunity oppDetails { get; set; }
        @AuraEnabled public Integer totalNumberOfReceipts { get; set; }
        
        public clientWrapper(Opportunity opp, Integer receiptCount) {
            this.oppDetails = opp;
            this.totalNumberOfReceipts = receiptCount;
        }
    }
}