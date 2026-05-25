@isTest
public class PaymentScheduleMasterControllerTest {

    @isTest
    static void testCheckUniqueName_Duplicate() {

        Payment_Schedule_Master__c existing =
            new Payment_Schedule_Master__c(Name = 'PS-001');
        insert existing;

        Map<Id, Payment_Schedule_Master__c> oldMap =
            new Map<Id, Payment_Schedule_Master__c>{
                existing.Id => existing
            };

        Payment_Schedule_Master__c updated =
            new Payment_Schedule_Master__c(
                Id = existing.Id,
                Name = 'PS-001'
            );

        List<Payment_Schedule_Master__c> newList =
            new List<Payment_Schedule_Master__c>{ updated };

        Test.startTest();
        PaymentScheduleMasterController.checkUniqueName(newList, oldMap);
        Test.stopTest();

    }

    @isTest
    static void testCheckUniqueName_NoDuplicate() {

        Payment_Schedule_Master__c ps =
            new Payment_Schedule_Master__c(Name = 'PS-UNIQUE');
        insert ps;

        Map<Id, Payment_Schedule_Master__c> oldMap =
            new Map<Id, Payment_Schedule_Master__c>{
                ps.Id => ps
            };

        ps.Name = 'PS-UNIQUE-NEW';

        Test.startTest();
        PaymentScheduleMasterController.checkUniqueName(
            new List<Payment_Schedule_Master__c>{ ps },
            oldMap
        );
        Test.stopTest();

    }
}