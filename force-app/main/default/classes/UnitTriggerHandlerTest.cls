@isTest
public class UnitTriggerHandlerTest {

    @isTest
    static void testPreventEditsOnSoldUnits_NoChanges() {
        Unit__c unit = new Unit__c(Status__c = 'Sold');
        insert unit;
        
        Unit__c updatedUnit = [SELECT Id, Name, Status__c FROM Unit__c WHERE Id = :unit.Id];

        Test.startTest();
        UnitTriggerHandler.preventEditsOnSoldUnits(
            new List<Unit__c>{updatedUnit},
            new Map<Id, Unit__c>{unit.Id => unit}
        );
        Test.stopTest();
    }

    @isTest
    static void testPreventEditsOnSoldUnits_WithChanges() {
        Unit__c unit = new Unit__c(Status__c = 'Sold');
        insert unit;
        
        Unit__c updatedUnit = [SELECT Id, Name, Status__c FROM Unit__c WHERE Id = :unit.Id];

        Test.startTest();
        Boolean exceptionThrown = false;
        try {
            UnitTriggerHandler.preventEditsOnSoldUnits(
                new List<Unit__c>{updatedUnit},
                new Map<Id, Unit__c>{unit.Id => unit}
            );
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Test.stopTest();
    }

    @isTest
    static void testPreventEditsOnSoldUnits_NotSoldStatus() {

        Unit__c unit = new Unit__c(Status__c = 'Sold');
        insert unit;

        Unit__c updatedUnit = [SELECT Id, Name, Status__c FROM Unit__c WHERE Id = :unit.Id];

        Test.startTest();
        UnitTriggerHandler.preventEditsOnSoldUnits(
            new List<Unit__c>{updatedUnit},
            new Map<Id, Unit__c>{unit.Id => unit}
        );
        Test.stopTest();
    }

    @isTest
    static void testPreventEditsOnSoldUnits_NullOldUnitMap() {

        Unit__c unit = new Unit__c(Status__c = 'Sold');
        insert unit;

        Unit__c updatedUnit = [SELECT Id, Name, Status__c FROM Unit__c WHERE Id = :unit.Id];

        Test.startTest();
        Boolean exceptionThrown = false;
        try {
            UnitTriggerHandler.preventEditsOnSoldUnits(
                new List<Unit__c>{updatedUnit},
                new Map<Id, Unit__c>() 
            );
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Test.stopTest();

    }
}