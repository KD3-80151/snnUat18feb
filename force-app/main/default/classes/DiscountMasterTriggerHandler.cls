public without sharing class DiscountMasterTriggerHandler {
    
    public static void checkActiveDiscountMaster(List<Discount_Master__c> newRecords, List<Discount_Master__c> oldRecords) {
        if (newRecords == null || newRecords.isEmpty()) {
            return;
        }

        Set<Id> projectIds = new Set<Id>();
        
        for (Discount_Master__c dm : newRecords) {
            if (dm.Active__c && dm.Project__c != null) {
                projectIds.add(dm.Project__c);
            }
        }

        if (projectIds.isEmpty()) {
            return;
        }
		
        List<Discount_Master__c> dmList = [SELECT Id, Project__c FROM Discount_Master__c WHERE Project__c IN :projectIds AND Active__c = true];
        
        Map<Id, Discount_Master__c> activeDiscountMasters = new Map<Id, Discount_Master__c>();
        for (Discount_Master__c dm : dmList) {
            if (dm.Project__c != null) {
                activeDiscountMasters.put(dm.Project__c, dm);
            }
        }

        for (Discount_Master__c newDm : newRecords) {
            if (newDm.Active__c && newDm.Project__c != null && activeDiscountMasters.containsKey(newDm.Project__c)) {
                newDm.addError('There can only be one active Discount Master for a Project.');
            }
        }

        if (oldRecords != null && !oldRecords.isEmpty()) {
            for (Integer i = 0; i < newRecords.size(); i++) {
                Discount_Master__c newDm = newRecords[i];
                Discount_Master__c oldDm = oldRecords[i];
                if (newDm.Active__c && !oldDm.Active__c && newDm.Project__c != null && activeDiscountMasters.containsKey(newDm.Project__c)) {
                    newDm.addError('There can only be one active Discount Master for a Project.');
                }
            }
        }
    }
    
   public static void showValidationForSameDiscountMaster(List<Discount_Master__c> discountMasterList) {
    system.debug('discountMasterList==' + discountMasterList);

    Set<Id> projectIds = new Set<Id>();
    Set<Id> pricingIds = new Set<Id>();
    for (Discount_Master__c disMaster : discountMasterList) {
        projectIds.add(disMaster.Project__c);
        pricingIds.add(disMaster.Pricing_Element_Master__c);
    }

    List<Discount_Master__c> existingDMList = [
        SELECT Id, Active__c, Pricing_Element_Master__c, Project__c 
        FROM Discount_Master__c 
        WHERE Project__c IN :projectIds AND Active__c = true
    ];

    Map<Id, Set<Id>> activePricingMap = new Map<Id, Set<Id>>();
    for (Discount_Master__c existingDM : existingDMList) {
        if (!activePricingMap.containsKey(existingDM.Project__c)) {
            activePricingMap.put(existingDM.Project__c, new Set<Id>());
        }
        activePricingMap.get(existingDM.Project__c).add(existingDM.Pricing_Element_Master__c);
    }

    for (Discount_Master__c disMaster : discountMasterList) {
        if (disMaster.Active__c == true && 
            activePricingMap.containsKey(disMaster.Project__c) && 
            activePricingMap.get(disMaster.Project__c).contains(disMaster.Pricing_Element_Master__c)) {
            disMaster.addError('An active Discount Master record with this Pricing Element already exists for the project.');
        }
    }
}
   public static void showValidationForSameDiscountMasterAfterActive(List<Discount_Master__c> discountMasterList, Map<Id, Discount_Master__c> oldDiscountMasterMap) {
    Set<Id> projectIds = new Set<Id>();
    Set<Id> pricingElementIds = new Set<Id>();

    for (Discount_Master__c newDismaster : discountMasterList) {
        Discount_Master__c oldRec = oldDiscountMasterMap.get(newDismaster.Id);
        if (newDismaster.Active__c == true && newDismaster.Pricing_Element_Master__c != null) {
            projectIds.add(newDismaster.Project__c);
            pricingElementIds.add(newDismaster.Pricing_Element_Master__c);
        }
    }

    List<Discount_Master__c> existingDiscountList = [
        SELECT Id, Project__c, Pricing_Element_Master__c, Active__c 
        FROM Discount_Master__c 
        WHERE Pricing_Element_Master__c IN :pricingElementIds 
              AND Project__c IN :projectIds 
              AND Active__c = true
    ];

    for (Discount_Master__c newDismaster : discountMasterList) {
        if (newDismaster.Active__c == true && newDismaster.Pricing_Element_Master__c != null) {
            for (Discount_Master__c existingDM : existingDiscountList) {
                if (newDismaster.Id != existingDM.Id && 
                    newDismaster.Project__c == existingDM.Project__c && 
                    newDismaster.Pricing_Element_Master__c == existingDM.Pricing_Element_Master__c) {
                    newDismaster.addError('Only one active Discount Master is allowed for the same Pricing Element and Project.');
                }
            }
        }
    }
}

}