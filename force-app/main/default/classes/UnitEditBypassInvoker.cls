public without sharing class UnitEditBypassInvoker {
    public class Request {
        @InvocableVariable(required=true)
        public Id unitId;
    }

    @InvocableMethod(label='Bypass Sold Unit Edit Validation' description='Allows the specified sold Unit records to be updated in the current transaction.')
    public static void bypassSoldUnitValidation(List<Request> requests) {
        if (requests == null || requests.isEmpty()) {
            return;
        }

        Set<Id> unitIds = new Set<Id>();
        for (Request requestRecord : requests) {
            if (requestRecord != null && requestRecord.unitId != null) {
                unitIds.add(requestRecord.unitId);
            }
        }

        if (!unitIds.isEmpty()) {
            UnitTriggerHandler.allowSoldUnitEditsForCurrentTransaction(unitIds);
        }
    }
}