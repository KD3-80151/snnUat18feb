@isTest
public class RoundRobinController_Test {

    @testSetup
    static void setupTestData() {
        Profile userProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = 'testuser' + Math.random() + '@example.com',
            Alias = 'tuser',
            CommunityNickname = 'tuser',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = userProfile.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;
        Assignment_Group__c testGroup = new Assignment_Group__c(Name = 'Test Group');
        insert testGroup;
        Assignment_Group_Member__c testGroupMember = new Assignment_Group_Member__c(
            Group_Member__c = testUser.Id,
            Assignment_Group__c = testGroup.Id,
            Out_Of_Office__c = false
        );
        insert testGroupMember;
    }

    @isTest
    static void testUserFetchBreakTime() {
         User_Tracking__c tracking = new User_Tracking__c(Member__c = UserInfo.getUserId());
    insert tracking;

    Test.setCreatedDate(tracking.Id, Date.today());
    User_Tracking_Audit__c audit = new User_Tracking_Audit__c(
        User_tracking__c = tracking.Id,
        Breakin_Datetime__c = DateTime.now().addMinutes(-10),
        BreakOut_Datetime__c = DateTime.now()
    );
    insert audit;

    User_Tracking_Audit__c audit2 = new User_Tracking_Audit__c(
        User_tracking__c = tracking.Id,
        Breakin_Datetime__c = DateTime.now().addHours(-1),
        BreakOut_Datetime__c = DateTime.now().addMinutes(-50)
    );
    insert audit2;

    Test.startTest();
    Integer breakTime = RoundRobinController.userFetchBreakTime();
    Test.stopTest();

    }

    @isTest
    static void testUserCheckin() {
        String testUser = userInfo.getUserId();
        
        User_Tracking__c use = new User_Tracking__c();
        use.Member__c = userInfo.getUserId();
        User_Tracking_Audit__c u = new User_Tracking_Audit__c();
        u.BreakOut_Datetime__c = System.today();
        u.Breakin_Datetime__c = System.today();
        insert use;
        insert u;
        Test.setCreatedDate(use.Id, Date.today());
        String result= RoundRobinController.user_checkin(testUser);

    }

    @isTest
    static void testCreateUserTrackingRecord() {
        User testUser = [SELECT Id FROM User WHERE Email = 'testuser@example.com' LIMIT 1];
        Test.startTest();
        Boolean result = RoundRobinController.createUserTrackingRecord(testUser.Id);
        Test.stopTest();
     
        User_Tracking__c tracking = [SELECT Id, Member__c FROM User_Tracking__c WHERE Member__c = :testUser.Id LIMIT 1];
        
    }

    @isTest
    static void testCreateUserAuditTrack() {
        User testUser = [SELECT Id FROM User WHERE Email = 'testuser@example.com' LIMIT 1];
        User_Tracking__c tracking = new User_Tracking__c(Member__c = testUser.Id, Checkin_Datetime__c = DateTime.now());
        insert tracking;
        Test.startTest();
        Boolean result = RoundRobinController.createUserAuditTrack(testUser.Id, 'Break');
        Test.stopTest();
        User_Tracking_Audit__c audit = [SELECT Id FROM User_Tracking_Audit__c WHERE User_tracking__c = :tracking.Id LIMIT 1];
       
    }

    @isTest
    static void testUpdateUserTrackingAudit() {
        User testUser = [SELECT Id FROM User WHERE Email = 'testuser@example.com' LIMIT 1];
        User_Tracking__c tracking = new User_Tracking__c(Member__c = testUser.Id, Checkin_Datetime__c = DateTime.now());
        insert tracking;
        User_Tracking_Audit__c audit = new User_Tracking_Audit__c(
            User_tracking__c = tracking.Id,
            Breakin_Datetime__c = DateTime.now()
        );
        insert audit;
        Test.startTest();
        Boolean result = RoundRobinController.updateUserTrackingAudit(testUser.Id, 'Break');
        Test.stopTest();
     
        User_Tracking_Audit__c updatedAudit = [SELECT BreakOut_Datetime__c FROM User_Tracking_Audit__c WHERE Id = :audit.Id];
      
    }

    @isTest
    static void testUserCheckout() {
        User testUser = [SELECT Id FROM User WHERE Email = 'testuser@example.com' LIMIT 1];
        User_Tracking__c tracking = new User_Tracking__c(Member__c = testUser.Id, Checkin_Datetime__c = DateTime.now());
        insert tracking;
        Test.startTest();
        Boolean result = RoundRobinController.userCheckout(testUser.Id);
        Test.stopTest();
    
        User_Tracking__c updatedTracking = [SELECT Checkout_Datetime__c FROM User_Tracking__c WHERE Id = :tracking.Id];
       
    }
    @isTest
	static void test_createUserTrackingRecord_catch() {
    Test.startTest();
    Boolean result = RoundRobinController.createUserTrackingRecord('invalidId');
    Test.stopTest();
  }
    @isTest
static void test_updateUserTrackingAudit_catch() {
    Test.startTest();
    Boolean result = RoundRobinController.updateUserTrackingAudit(
        UserInfo.getUserId(),
        'breakout'
    );
    Test.stopTest();
}
 @isTest
static void test_userCheckout_catch() {
    try {
        Test.startTest();
        RoundRobinController.userCheckout(UserInfo.getUserId());
        Test.stopTest();
    } catch (Exception e) {
    }
}

}