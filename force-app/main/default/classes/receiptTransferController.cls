public without sharing class receiptTransferController {
    
    @AuraEnabled(cacheable=true)
    public static List<Project__c> fetchProjectDetails(){
        try {
            List<Project__c> projectList = [SELECT Id,Name from Project__c];
            return projectList.isEmpty() ? null : projectList;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Tower__c> fetchTowerDetails(Id projectId){
        try {
            List<Tower__c> towerList = [SELECT Id,Tower_Code__c from Tower__c where Project__c =: projectId];
            return towerList.isEmpty() ? null : towerList;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Account> fetchAccDetails(Id blockId){
        try {
            List<Account> accList = [SELECT Id,Name from Account where Id IN(SELECT AccountId FROM Opportunity WHERE Unit__r.Floor__r.Blocks__c =: blockId)];
            return accList.isEmpty() ? null : accList;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
public static List<Opportunity> fetchOpportunityDetails(Id blockId) {
    try {
        // Step 1: Get all Floor Ids under the Block
        List<Floor__c> floorList = [
            SELECT Id,Blocks__c 
            FROM Floor__c 
            WHERE Blocks__c = :blockId
        ];
        
        Set<Id> floorIds = new Set<Id>();
        for (Floor__c floor : floorList) {
            floorIds.add(floor.Id);
        }

        if (floorIds.isEmpty()) {
            return new List<Opportunity>();
        }

        // Step 2: Get all Unit Ids under those Floors
        List<Unit__c> unitList = [
            SELECT Id 
            FROM Unit__c 
            WHERE Floor__c IN :floorIds
        ];

        Set<Id> unitIds = new Set<Id>();
        for (Unit__c unit : unitList) {
            unitIds.add(unit.Id);
        }

        if (unitIds.isEmpty()) {
            return new List<Opportunity>();
        }

        // Step 3: Get Opportunities linked to those Units
        List<Opportunity> oppList = [
            SELECT Id, Name, StageName, CloseDate, Unit__c 
            FROM Opportunity 
            WHERE Unit__c IN :unitIds
        ];

        return oppList;

    } catch (Exception e) {
        throw new AuraHandledException('Error fetching opportunities: ' + e.getMessage());
    }
}


    @AuraEnabled
public static oppWrapper fetchOppDetails(Id fromAccountId, Id toAccountId, Id fromOpp, Id toOpp) {
    try {
        System.debug('fromAccountId => ' + fromAccountId);
        System.debug('toAccountId   => ' + toAccountId);
        System.debug('fromOpp       => ' + fromOpp);
        System.debug('toOpp         => ' + toOpp);

        List<Opportunity> fromOppList = new List<Opportunity>();
        List<Opportunity> toOppList = new List<Opportunity>();

 
        if (fromOpp != null) {
            fromOppList = [
                SELECT Id, Name,
                       (SELECT Id, Receipt_Number__c, Amount__c, Mode_Of_Payment__c, CreatedDate, Opportunity__c 
                        FROM Receipts__r)
                FROM Opportunity
                WHERE Id = :fromOpp
            ];
        } 
     
        else if (fromAccountId != null) {
            fromOppList = [
                SELECT Id, Name,
                       (SELECT Id, Receipt_Number__c, Amount__c, Mode_Of_Payment__c, CreatedDate, Opportunity__c 
                        FROM Receipts__r)
                FROM Opportunity
                WHERE AccountId = :fromAccountId
                  AND Id IN (SELECT Opportunity__c FROM Receipt__c)
            ];
        }

        if (toOpp != null) {
            toOppList = [
                SELECT Id, Name, Project__c, Project__r.Name, Unit__r.Unit_Name__c, Unit__c
                FROM Opportunity
                WHERE Id = :toOpp
            ];
        } 
      
        else if (toAccountId != null) {
            toOppList = [
                SELECT Id, Name, Project__c, Project__r.Name, Unit__r.Unit_Name__c, Unit__c
                FROM Opportunity
                WHERE AccountId = :toAccountId
            ];
        }

        oppWrapper wrp = new oppWrapper();
        wrp.fromOppList = fromOppList.isEmpty() ? null : fromOppList;
        wrp.toOppList = toOppList.isEmpty() ? null : toOppList;
        return wrp;

    } catch (Exception e) {
        throw new AuraHandledException('Error in fetchOppDetails: ' + e.getMessage());
    }
}

    public class oppWrapper{
        @AuraEnabled public List<Opportunity> fromOppList{get;set;}
        @AuraEnabled public List<Opportunity> toOppList{get;set;}
    }

    @AuraEnabled
    public static void createTransferLog(List<Receipt_Transfer_Log_LineItem__c> logLineItemList, Receipt_Transfer_Log__c transferLogDetails){
        try {
            if(transferLogDetails != null){
                insert transferLogDetails;

                if(!logLineItemList.isEmpty() && transferLogDetails.Id != null){
                    for(Receipt_Transfer_Log_LineItem__c logLineItem : logLineItemList){
                        logLineItem.Receipt_Transfer_Log__c = transferLogDetails.Id;
                        System.debug(logLineItem);
                    }
                    insert logLineItemList;
                }

                
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}