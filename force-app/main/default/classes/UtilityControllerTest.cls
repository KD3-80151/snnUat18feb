@IsTest
public class UtilityControllerTest {
    
    @isTest
    static void testGetPicklistValues() {
        
        String objectApiName = 'Account'; 
        String fieldName = 'Industry'; 

        Test.startTest();
        List<String> picklistValues = UtilityController.getPicklistValues(objectApiName, fieldName);
        Test.stopTest();

    }

    @isTest
    static void testGetPicklistValuesWithAll() {
        String objectApiName = 'Account'; 
        String fieldName = 'Industry'; 

        Test.startTest();
        List<String> picklistValuesWithAll = UtilityController.getPicklistValuesWithAll(objectApiName, fieldName);
        Test.stopTest();

    }

    @isTest
    static void testGenerateRandomString() {
        Test.startTest();
        String randomString = UtilityController.generateRandomString();
        Test.stopTest();
    }

    @isTest
    static void testGenerateOTP() {
        Test.startTest();
        String otp = UtilityController.generateOTP();
        Test.stopTest();
    }
}