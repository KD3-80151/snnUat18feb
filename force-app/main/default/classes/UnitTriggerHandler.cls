public without sharing class UnitTriggerHandler {
    public UnitTriggerHandler() {}

    public static void preventEditsOnSoldUnits(List<Unit__c> newUnits, Map<Id, Unit__c> oldUnitMap) {
        system.debug('newUnits =====> '+newUnits);
        for (Unit__c unit : newUnits) {
            Unit__c oldUnit = oldUnitMap.get(unit.Id);
            system.debug('oldUnit =====> '+oldUnit);

            if (oldUnit.Status__c == 'Sold') {
                system.debug('unit.equals(oldUnit) ====> '+unit.equals(oldUnit));
                if (!unit.equals(oldUnit)) {
                    System.debug('Unit has been modified. Adding error.');
                    unit.addError('This record cannot be edited because its status is Sold.');
                }
            }
        }
    }
}