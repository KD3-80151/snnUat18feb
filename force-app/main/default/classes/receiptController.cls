public withOut sharing class receiptController {

    @AuraEnabled(cacheable=true)
    public static List<Receipt__c> fetchReceipts(Id accId, Id unitId){
        try {
            List<Receipt__c> listReceipts = [SELECT Id, Name, Receipt_Date__c, Amount__c, Unit__c, Unit__r.Name, Account__c, Account__r.Name from Receipt__c where Account__c = :accId and Unit__c = : unitId];
            if(!listReceipts.isEmpty()){
                return listReceipts;
            }
            return null;
        } catch (Exception e) {
            System.debug('Error in fetchReceipts ' + e.getMessage());
            System.debug('Error in line ' + e.getLineNumber());
            return null;
        }
    }

    @AuraEnabled
    public static String createReceipt(Receipt__c receiptRec){
        try {
            if(receiptRec != null){
                insert receiptRec;
                System.debug('receipt id ==> ' + receiptRec.Id);
                return receiptRec.Id;
            }
            return null;
        } catch (Exception e) {
            System.debug('Error in createReceipt ' + e.getMessage());
            System.debug('Error in line ' + e.getLineNumber());
            return e.getMessage();
        } 
    }

    @AuraEnabled(cacheable=true)
    public static Unit__c getUnitDetails(Id accId, Id unitId) {
        try {
            List<Unit__c> unitList;
            if (accId != null) {
                unitList = [SELECT Id, Name, Total__c, Balance__c, Total_Tax__c, Allocated_Tax__c, Balance_Tax__c, Allocated__c, Account__c from Unit__c where Account__c = :accId order by CreatedDate Desc Limit 1];
            } else if (unitId != null) {
                unitList = [SELECT Id, Name, Total__c, Balance__c, Total_Tax__c, Allocated_Tax__c, Balance_Tax__c, Allocated__c, Account__c from Unit__c where Id = :unitId order by CreatedDate Desc Limit 1];
            } 
            System.debug('unitDetails ===> ' + unitList[0]);
            if (!unitList.isEmpty()) {
                return unitList[0];
            }
            return null;
        } catch (Exception e) {
            System.debug('Error in getUnitDetails: ' + e.getMessage());
            System.debug('Error in line ' + e.getLineNumber());
            return null;
        }
    }
    
    @AuraEnabled(cacheable= true)
    public static Map<String, List<String>> getAllPickListVal(Map<String, String> ObjectByField){
        Map<String, List<String>> picklistValByField = new Map<String, List<String>>();
        for(String fields : ObjectByField.keySet()){
            picklistValByField.put(fields, getPicklistValues(ObjectByField.get(fields), fields));
        }
        return picklistValByField;
    }
    
    @AuraEnabled(cacheable= true)
    public static List<String> getPicklistValues(String objName, String fieldName){
        List<String> options = new List<String>();
        Map<String, String> mapPickListValues = new Map<String, String>();
        Schema.SObjectType objSobjectType = Schema.getGlobalDescribe().get(objName);
        Schema.DescribeSObjectResult objDescribeSobject = objSobjectType.getDescribe();
        Map<String, Schema.SObjectField> mapFields = objDescribeSobject.fields.getMap();
        List<Schema.PicklistEntry> lstPickListValues = mapFields.get(fieldName).getDescribe().getPickListValues();
        for (Schema.PicklistEntry objPickList : lstPickListValues) {
            options.add(objPickList.getValue());
        }
        return options;
    }

}