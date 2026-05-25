@isTest
public class parkingDetailsTriggerHandlerTest {

    @isTest
    static void testValidateBeforeInsert() {

        Tower__c tower1 = new Tower__c(Name = 'Tower A', Total_Parking__c = 10);
        Tower__c tower2 = new Tower__c(Name = 'Tower B', Total_Parking__c = 5);
        insert new List<Tower__c>{ tower1, tower2 };

        Parking_Details__c existingParking = new Parking_Details__c(
            BLock__c = tower1.Id,
            Parking_Type__c = 'Open',
            Total_Parking__c = 5,
            Available_Parking__c = 5
        );
        insert existingParking;

        Parking_Details__c parking1 = new Parking_Details__c(
            Block__c = tower1.Id,
            Parking_Type__c = 'Open',
            Total_Parking__c = 5,
            Available_Parking__c = null 
        );
        
        Parking_Details__c parking2 = new Parking_Details__c(
            BLock__c = tower1.Id,
            Parking_Type__c = 'Open',
            Total_Parking__c = 6 
        );
        
        Parking_Details__c parking3 = new Parking_Details__c(
            BLock__c = null, 
            Parking_Type__c = 'Open',
            Total_Parking__c = 2
        );
        
        Parking_Details__c parking4 = new Parking_Details__c(
            BLock__c = tower2.Id,
            Parking_Type__c = null, 
            Total_Parking__c = 2
        );

        List<Parking_Details__c> parkingList = new List<Parking_Details__c>{ parking1, parking2, parking3, parking4 };
        Test.startTest();
        try {
            parkingDetailsTriggerHandler.validateBeforeInsert(parkingList);
        } catch (DmlException e) {
            System.debug('DML Exception caught as expected.');
        }
        Test.stopTest();
    }

    @isTest
    static void testValidateBeforeInsertNoErrors() {
        Tower__c validTower = new Tower__c(Name = 'Valid Tower', Total_Parking__c = 20);
        insert validTower;

        Parking_Details__c validParking = new Parking_Details__c(
            BLock__c = validTower.Id,
            Parking_Type__c = 'Open',
            Total_Parking__c = 10,
            Available_Parking__c = 10
        );

        List<Parking_Details__c> parkingList = new List<Parking_Details__c>{ validParking };

        Test.startTest();
        try {
            parkingDetailsTriggerHandler.validateBeforeInsert(parkingList);
        } catch (Exception e) {
            
        }
        Test.stopTest();
    }

    @isTest
    static void testAfterInsert() {
        Test.startTest();
        parkingDetailsTriggerHandler.afterInsert(new List<Parking_Details__c>());
        Test.stopTest();
    }
}