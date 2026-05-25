public with sharing class PaymentScheduleMasterController {

    public static void checkUniqueName(List<Payment_Schedule_Master__c> newList, Map<Id, Payment_Schedule_Master__c> oldMap) {
        Set<String> nameSet = new Set<String>();

        for (Payment_Schedule_Master__c record : newList) {
            if (record.Name != null && (oldMap == null || oldMap.get(record.Id) == null || record.Name.trim() != oldMap.get(record.Id).Name.trim())) {
                nameSet.add(record.Name.trim());
            }
        }

        if (nameSet.isEmpty()) return;

        Map<String, Payment_Schedule_Master__c> existingRecords = new Map<String, Payment_Schedule_Master__c>();
        List<Payment_Schedule_Master__c> existingList = [SELECT Id, Name FROM Payment_Schedule_Master__c WHERE Name IN :nameSet];
        for (Payment_Schedule_Master__c existing : existingList) {
            existingRecords.put(existing.Name.trim(), existing);
        }

        for (Payment_Schedule_Master__c record : newList) {
            String nameTrimmed = record.Name != null ? record.Name.trim() : null;
            if (nameTrimmed != null && existingRecords.containsKey(nameTrimmed)) {
                Payment_Schedule_Master__c existing = existingRecords.get(nameTrimmed);
                if (record.Id != existing.Id) {
                    record.addError('A record with this Name already exists. Name must be unique.');
                }
            }
        }
    }
}