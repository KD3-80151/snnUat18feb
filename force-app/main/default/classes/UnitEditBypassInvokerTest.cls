@isTest
private class UnitEditBypassInvokerTest {
    @isTest
    static void bypassSoldUnitValidation_allowsCurrentTransactionUpdate() {
        Unit__c unitRecord = new Unit__c(Status__c = 'Sold');
        insert unitRecord;

        UnitEditBypassInvoker.Request requestRecord = new UnitEditBypassInvoker.Request();
        requestRecord.unitId = unitRecord.Id;

        Test.startTest();
        UnitEditBypassInvoker.bypassSoldUnitValidation(
            new List<UnitEditBypassInvoker.Request>{ requestRecord }
        );

        unitRecord.Status__c = 'For Sale';
        update unitRecord;
        Test.stopTest();

        Unit__c refreshedUnit = [
            SELECT Status__c
            FROM Unit__c
            WHERE Id = :unitRecord.Id
        ];
        System.assertEquals('For Sale', refreshedUnit.Status__c);
    }
}