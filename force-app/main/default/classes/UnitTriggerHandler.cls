public without sharing class UnitTriggerHandler {
    public UnitTriggerHandler() {}
    private static Set<Id> bypassUnitIdsForCurrentTransaction = new Set<Id>();

    private static Boolean isSystemAdminUser = null;

    private static Boolean isCurrentUserSystemAdmin() {
        if (isSystemAdminUser == null) {
            isSystemAdminUser = [SELECT Id FROM Profile WHERE Id = :UserInfo.getProfileId() AND Name = 'System Administrator'].size() > 0;
        }
        return isSystemAdminUser;
    }

    public static void preventEditsOnSoldUnits(List<Unit__c> newUnits, Map<Id, Unit__c> oldUnitMap) {
        system.debug('newUnits =====> '+newUnits);
        if (isCurrentUserSystemAdmin()) {
            return;
        }
        for (Unit__c unit : newUnits) {
            Unit__c oldUnit = oldUnitMap.get(unit.Id);
            system.debug('oldUnit =====> '+oldUnit);

            if (bypassUnitIdsForCurrentTransaction.contains(unit.Id)) {
                continue;
            }

            if (oldUnit.Status__c == 'Sold') {
                system.debug('unit.equals(oldUnit) ====> '+unit.equals(oldUnit));
                if (!unit.equals(oldUnit)) {
                    System.debug('Unit has been modified. Adding error.');
                    unit.addError('This record cannot be edited because its status is Sold.');
                }
            }
        }
    }

    public static void allowSoldUnitEditsForCurrentTransaction(Set<Id> unitIds) {
        if (unitIds == null || unitIds.isEmpty()) {
            return;
        }

        bypassUnitIdsForCurrentTransaction.addAll(unitIds);
    }
}