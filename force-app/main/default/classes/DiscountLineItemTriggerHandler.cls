public without sharing class DiscountLineItemTriggerHandler {

    public static void handleDiscountLineItemRole(List<Discount_LineItem__c> newRecords, List<Discount_LineItem__c> oldRecords) {

        Set<Id> discountMasterIds = new Set<Id>();
        Set<Id> projectIds = new Set<Id>();

        for (Discount_LineItem__c lineItem : newRecords) {
            if (lineItem.Discount_Master__c != null) {
                discountMasterIds.add(lineItem.Discount_Master__c);
            }
        }

        Map<Id, Id> discountMasterToProjectMap = new Map<Id, Id>();
        if (!discountMasterIds.isEmpty()) {
            List<Discount_Master__c> discountMasters = [
                SELECT Id, Project__c FROM Discount_Master__c WHERE Id IN :discountMasterIds
            ];

            for (Discount_Master__c discountMaster : discountMasters) {
                discountMasterToProjectMap.put(discountMaster.Id, discountMaster.Project__c);
                if (discountMaster.Project__c != null) {
                    projectIds.add(discountMaster.Project__c);
                }
            }
        }

        Map<Id, Set<String>> projectRolesMap = new Map<Id, Set<String>>();
        if (!projectIds.isEmpty()) {
            List<Project_Roles__c> projectRoles = [
                SELECT Id, Project__c, Role__c 
                FROM Project_Roles__c 
                WHERE Project__c IN :projectIds
            ];

            for (Project_Roles__c role : projectRoles) {
                if (role.Project__c != null && role.Role__c != null) {
                    if (!projectRolesMap.containsKey(role.Project__c)) {
                        projectRolesMap.put(role.Project__c, new Set<String>());
                    }
                    projectRolesMap.get(role.Project__c).add(role.Role__c);
                }
            }
        }

        if (newRecords != null && !newRecords.isEmpty()) {

            if (oldRecords == null) {
                for (Discount_LineItem__c lineItem : newRecords) {
                    if (lineItem.Discount_Master__c != null && lineItem.Roles__c != null) {
                        Id projectId = discountMasterToProjectMap.get(lineItem.Discount_Master__c);

                        if (projectId != null) {
                            Set<String> validRoles = projectRolesMap.get(projectId);
                            if (validRoles == null || !validRoles.contains(lineItem.Roles__c)) {
                                lineItem.addError('The Role value must match a role in the related Project roles.');
                            }
                        }
                    }
                }
            } else {
                for (Integer i = 0; i < newRecords.size(); i++) {
                    Discount_LineItem__c newLineItem = newRecords[i];
                    Discount_LineItem__c oldLineItem = oldRecords[i];

                    if (newLineItem.Discount_Master__c != null && newLineItem.Roles__c != null) {
                        Id projectId = discountMasterToProjectMap.get(newLineItem.Discount_Master__c);

                        if (projectId != null && newLineItem.Roles__c != oldLineItem.Roles__c) {
                            Set<String> validRoles = projectRolesMap.get(projectId);

                            if (validRoles == null || !validRoles.contains(newLineItem.Roles__c)) {
                                newLineItem.addError('The Role value must match a role in the related Project roles.');
                            }
                        }
                    }
                }
            }
        }
    }
}