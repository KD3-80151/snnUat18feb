@isTest
public class UnitTriggerHandlerTest {

    @testSetup
    static void setup() {
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User adminUser = new User(
            Alias = 'uthadmin',
            Email = 'uth.admin@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Admin',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = adminProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'uth.admin@unittriggerhandlertest.com'
        );
        insert adminUser;

        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User standardUser = new User(
            Alias = 'uthstd',
            Email = 'uth.std@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Standard',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = standardProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'uth.std@unittriggerhandlertest.com'
        );
        insert standardUser;
    }

    @isTest
    static void testPreventEditsOnSoldUnits_NoChanges() {
        Unit__c unit = new Unit__c(Status__c = 'Sold');
        insert unit;

        Unit__c oldUnit = [SELECT Id, Name, Status__c, Description__c FROM Unit__c WHERE Id = :unit.Id];
        Unit__c updatedUnit = oldUnit.clone(true, true, true, true);
        User standardUser = [SELECT Id FROM User WHERE Username = 'uth.std@unittriggerhandlertest.com'];

        System.runAs(standardUser) {
            Test.startTest();
            UnitTriggerHandler.preventEditsOnSoldUnits(
                new List<Unit__c>{updatedUnit},
                new Map<Id, Unit__c>{oldUnit.Id => oldUnit}
            );
            Test.stopTest();
        }

        System.assert(updatedUnit.getErrors().isEmpty(), 'No error should be added when the record is unchanged.');
    }

    @isTest
    static void testPreventEditsOnSoldUnits_WithChanges() {
        Unit__c unit = new Unit__c(Status__c = 'Sold');
        insert unit;

        Unit__c oldUnit = [SELECT Id, Name, Status__c, Description__c FROM Unit__c WHERE Id = :unit.Id];
        Unit__c updatedUnit = oldUnit.clone(true, true, true, true);
        updatedUnit.Description__c = 'Changed description';
        User standardUser = [SELECT Id FROM User WHERE Username = 'uth.std@unittriggerhandlertest.com'];

        System.runAs(standardUser) {
            Test.startTest();
            UnitTriggerHandler.preventEditsOnSoldUnits(
                new List<Unit__c>{updatedUnit},
                new Map<Id, Unit__c>{oldUnit.Id => oldUnit}
            );
            Test.stopTest();
        }

        System.assert(!updatedUnit.getErrors().isEmpty(), 'An error should be added when a Sold unit is modified.');
        System.assertEquals(
            'This record cannot be edited because its status is Sold.',
            updatedUnit.getErrors()[0].getMessage()
        );
    }

    @isTest
    static void testPreventEditsOnSoldUnits_NotSoldStatus() {
        Unit__c unit = new Unit__c(Status__c = 'For Sale');
        insert unit;

        Unit__c oldUnit = [SELECT Id, Name, Status__c, Description__c FROM Unit__c WHERE Id = :unit.Id];
        Unit__c updatedUnit = oldUnit.clone(true, true, true, true);
        updatedUnit.Description__c = 'Changed description';
        User standardUser = [SELECT Id FROM User WHERE Username = 'uth.std@unittriggerhandlertest.com'];

        System.runAs(standardUser) {
            Test.startTest();
            UnitTriggerHandler.preventEditsOnSoldUnits(
                new List<Unit__c>{updatedUnit},
                new Map<Id, Unit__c>{oldUnit.Id => oldUnit}
            );
            Test.stopTest();
        }

        System.assert(updatedUnit.getErrors().isEmpty(), 'No error should be added when the unit was never Sold.');
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

        System.assert(exceptionThrown, 'A NullPointerException is expected when the old unit cannot be found in the map.');
    }

    @isTest
    static void testPreventEditsOnSoldUnits_BypassedForCurrentTransaction() {
        Unit__c unit = new Unit__c(Status__c = 'Sold');
        insert unit;

        Unit__c oldUnit = [SELECT Id, Name, Status__c, Description__c FROM Unit__c WHERE Id = :unit.Id];
        Unit__c updatedUnit = oldUnit.clone(true, true, true, true);
        updatedUnit.Description__c = 'Changed description';
        User standardUser = [SELECT Id FROM User WHERE Username = 'uth.std@unittriggerhandlertest.com'];

        System.runAs(standardUser) {
            Test.startTest();
            UnitTriggerHandler.allowSoldUnitEditsForCurrentTransaction(new Set<Id>{oldUnit.Id});
            UnitTriggerHandler.preventEditsOnSoldUnits(
                new List<Unit__c>{updatedUnit},
                new Map<Id, Unit__c>{oldUnit.Id => oldUnit}
            );
            Test.stopTest();
        }

        System.assert(updatedUnit.getErrors().isEmpty(), 'No error should be added once the unit Id has been bypassed for the transaction.');
    }

    @isTest
    static void testAllowSoldUnitEditsForCurrentTransaction_NullOrEmptySet() {
        Unit__c unit = new Unit__c(Status__c = 'Sold');
        insert unit;

        Unit__c oldUnit = [SELECT Id, Name, Status__c, Description__c FROM Unit__c WHERE Id = :unit.Id];
        Unit__c updatedUnit = oldUnit.clone(true, true, true, true);
        updatedUnit.Description__c = 'Changed description';
        User standardUser = [SELECT Id FROM User WHERE Username = 'uth.std@unittriggerhandlertest.com'];

        System.runAs(standardUser) {
            Test.startTest();
            UnitTriggerHandler.allowSoldUnitEditsForCurrentTransaction(null);
            UnitTriggerHandler.allowSoldUnitEditsForCurrentTransaction(new Set<Id>());
            UnitTriggerHandler.preventEditsOnSoldUnits(
                new List<Unit__c>{updatedUnit},
                new Map<Id, Unit__c>{oldUnit.Id => oldUnit}
            );
            Test.stopTest();
        }

        System.assert(!updatedUnit.getErrors().isEmpty(), 'Passing a null or empty set should not bypass any units.');
    }

    @isTest
    static void testPreventEditsOnSoldUnits_BypassedForSystemAdmin() {
        Unit__c unit = new Unit__c(Status__c = 'Sold');
        insert unit;

        Unit__c oldUnit = [SELECT Id, Name, Status__c, Description__c FROM Unit__c WHERE Id = :unit.Id];
        Unit__c updatedUnit = oldUnit.clone(true, true, true, true);
        updatedUnit.Description__c = 'Changed description';
        User adminUser = [SELECT Id FROM User WHERE Username = 'uth.admin@unittriggerhandlertest.com'];

        System.runAs(adminUser) {
            Test.startTest();
            UnitTriggerHandler.preventEditsOnSoldUnits(
                new List<Unit__c>{updatedUnit},
                new Map<Id, Unit__c>{oldUnit.Id => oldUnit}
            );
            Test.stopTest();
        }

        System.assert(updatedUnit.getErrors().isEmpty(), 'System Administrators should be able to edit Sold units.');
    }
}
