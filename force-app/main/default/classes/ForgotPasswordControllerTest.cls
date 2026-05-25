@isTest
public class ForgotPasswordControllerTest {
    @isTest
    static void testForgotPassword() {
        // Create a test user
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testusersdfdf@example.com',
            Username = 'testuser1rtetrgrdg@example.com.salesforce',
            Alias = 'tuser',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;
        
        // Instantiate the controller
        Test.startTest();
        ForgotPasswordController controller = new ForgotPasswordController();
        controller.username = testUser.Username;
        PageReference result = controller.forgotPassword();
        Test.stopTest();
        
        
    }
}