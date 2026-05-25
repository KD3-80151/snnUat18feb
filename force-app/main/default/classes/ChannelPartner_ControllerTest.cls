@isTest
public class ChannelPartner_ControllerTest {
    @testSetup
    static void setupTestData() {
        // Ensure that the RecordType exists in the org
        RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND Name = 'Channel Partner' LIMIT 1];
       

        // Create test data for Channel_Partner_Dashboard_Tabs__c
        List<Channel_Partner_Dashboard_Tabs__c> dashboardTabs = new List<Channel_Partner_Dashboard_Tabs__c>();
        for (Integer i = 1; i <= 3; i++) {
            dashboardTabs.add(new Channel_Partner_Dashboard_Tabs__c(
                Name = 'Tab ' + i,
                Tab_Label__c = 'Tab Label ' + i,
                Controller_Name__c = 'Controller ' + i,
                Display_Order__c = i
            ));
        }
        insert dashboardTabs;
         // Create test Accounts
        Account channelPartnerAccount = new Account(
            Name = 'Channel Partner Account',
            Phone = '1234567890',
            Login_Hash_Code__c = '247839',
            RecordTypeId = rt.Id
        );
        insert channelPartnerAccount;
         Account nonChannelPartnerAccount = new Account(
            Name = 'Non Channel Partner Account',
            Phone = '9876543210'
           
        );
        insert nonChannelPartnerAccount;
    }

    @isTest
    static void testChannelPartnerControllerInitialization() {
        Test.startTest();
        
        // Mock UtilityController's static methods
        //Test.setMock(UtilityControllerMock.class);

        // Instantiate the controller
        ChannelPartner_Controller controller = new ChannelPartner_Controller();

        
        Test.stopTest();
    }

    // Corrected Mock class for UtilityController
    private class UtilityControllerMock implements System.StubProvider {
        public Object handleMethodCall(
            Object stubbedObject,
            String methodName,
            System.Type returnType,
            List<System.Type> parameterTypes,
            List<String> parameterNames,
            List<Object> args
        ) {
            if (methodName == 'getPicklistValuesWithAll') {
                return new Map<String, String>{'Open' => 'Open', 'Closed' => 'Closed'};
            } else if (methodName == 'getPicklistValues') {
                return new Map<String, String>{'Value1' => 'Value1', 'Value2' => 'Value2'};
            }
            return null;
        }
    }
    @isTest
    static void testCheckAccountValidChannelPartner() {
        Test.startTest();
        
        // Call the method with a valid Channel Partner phone number
        ChannelPartner_Controller.accountWrapper result = ChannelPartner_Controller.checkAccount('1234567890');
 
        Test.stopTest();
    }

    @isTest
    static void testCheckAccountNonChannelPartner() {
        Test.startTest();
        
        // Call the method with a non-Channel Partner phone number
        ChannelPartner_Controller.accountWrapper result = ChannelPartner_Controller.checkAccount('9876543210');
 
        Test.stopTest();
    }

    @isTest
    static void testCheckAccountNoAccountFound() {
        Test.startTest();
        
        // Call the method with a phone number that does not exist
        ChannelPartner_Controller.accountWrapper result = ChannelPartner_Controller.checkAccount('5555555555');

        Test.stopTest();
    }

    @isTest
    static void testCheckAccountEmptyPhoneNumber() {
        Test.startTest();
        
        // Call the method with an empty phone number
        ChannelPartner_Controller.accountWrapper result = ChannelPartner_Controller.checkAccount('');
 
        Test.stopTest();
    }

    @isTest
    static void testCheckAccountExceptionHandling() {
        Test.startTest();
        // Simulate an exception by mocking the UtilityController
        //Test.setMock(UtilityControllerMock1.class);
        //ChannelPartner_Controller.accountWrapper result = ChannelPartner_Controller.checkAccount('1234567890');
        // Simulate an exception by passing a phone number that will trigger an error
        ChannelPartner_Controller.accountWrapper result = null;
        try {
            // This can be any logic that triggers an exception within the method.
            // For example, passing invalid input or causing an unexpected query exception.
            result = ChannelPartner_Controller.checkAccount(null); // Passing null will trigger an exception
        } catch (Exception e) {
            System.debug('Result should remain null when an exception occurs.');
        }
        Test.stopTest();
    }

    // Mock class for UtilityController
    private class UtilityControllerMock1 implements System.StubProvider {
        public Object handleMethodCall(
            Object stubbedObject,
            String methodName,
            System.Type returnType,
            List<System.Type> parameterTypes,
            List<String> parameterNames,
            List<Object> args
        ) {
            if (methodName == 'generateRandomString') {
                System.debug('Mocked Exception');
            }
            return null;
        }
    }
   
    // Utility method to create test data
    private static void createTestData() {
        try{
        // Create Account with Login Hash Code
        Account acc = new Account(Name = 'Test Account', Login_Hash_Code__c = 'testHashCode');
        insert acc;
        
        // Create related project and company
        Company__c company = new Company__c(Name = 'TestCompany');
        insert company;
        Project__c project1 = new Project__c(Name = 'Project A', City__c = 'City A', Zone__c = 'East', Company__c = company.Id);
        insert project1;

        // Create a Channel Partner Lead
        Lead lead = new Lead(LastName = 'TestLead', Company = 'Test Company' ,Project__c=project1.Id, Email = 'test@example.com', Phone = '1234567890');
        insert lead;

        // Create some test Visits, Opportunities, and Projects
        Visit__c visit = new Visit__c( Channel_Partner__c = acc.Id);
        insert visit;

        Opportunity opp = new Opportunity(Name = 'Test Opportunity', StageName = 'Prospecting', Channel_Partner__c = acc.Id,CloseDate = System.Today()+20);
        insert opp;

        Project__c project = new Project__c(Name = 'Test Project');
        insert project;

        // Create Terms_Conditions record
        Terms_Conditions__c terms = new Terms_Conditions__c(Description__c = 'Sample Terms and Conditions');
        insert terms;
        }Catch(exception ex) {
            system.debug(ex.getlinenumber());
        }
    }

    // Test getChannelPartnerData method
    @isTest
    static void testGetChannelPartnerData() {
        createTestData();

        // Start test context
        Test.startTest();
        
        // Call the method with the test channel partner ID
        //ChannelPartnerDataWrapper dataWrapper = ChannelPartner_Controller.getChannelPartnerData(channelPartnerIdStr);
		ChannelPartner_Controller.ChannelPartnerDataWrapper dataWrapper = new ChannelPartner_Controller.ChannelPartnerDataWrapper();
        dataWrapper = ChannelPartner_Controller.getChannelPartnerData('testHashCode');
        Test.stopTest();
    }

    // Test CreateLeadForChannelPartnerLeadPage method
    @isTest
    static void testCreateLeadForChannelPartnerLeadPage() {
       // createTestData();
         Account acc = new Account(Name = 'Test Account', Login_Hash_Code__c = 'testHashCode');
        insert acc;
        String channelPartnerIdStr = acc.Id;
		 Company__c company = new Company__c(Name = 'TestCompany');
        insert company;
        Project__c project1 = new Project__c(Name = 'Project A', City__c = 'City A', Zone__c = 'East', Company__c = company.Id);
        insert project1;
        // Create a test lead
        Lead newLead = new Lead(LastName = 'NewLead1', Company = 'New Company' ,Alternate_Phone__c = '', Phone = '9876543210',Project__c=project1.Id, Email = 'newlead@example1.com');
        insert newLead;
        Lead newLead2 = new Lead(LastName = 'NewLead2', Company = 'New Company' ,Lead_Type__c = 'Direct',Alternate_Phone__c = '9876543211', Phone = '9876543212',Project__c=project1.Id, Email = 'newlead@example2.com', Alternate_Email__c = 'newlead@example4.com');
        insert newLead2;
        Lead newLead3 = new Lead(LastName = 'NewLead3', Company = 'New Company' ,Lead_Type__c = 'Direct',Alternate_Phone__c = '9876543211', Phone = '9876543214',Project__c=project1.Id, Email = 'newlead@example3.com', Alternate_Email__c = 'newlead@example5.com');
        // Start test context
        Test.startTest();

        // Call the method with the new lead and test channel partner ID
        String result1 = ChannelPartner_Controller.CreateLeadForChannelPartnerLeadPage(newLead, 'testHashCode');
        String result2 = ChannelPartner_Controller.CreateLeadForChannelPartnerLeadPage(newLead2, 'testHashCode');
        String result3 = ChannelPartner_Controller.CreateLeadForChannelPartnerLeadPage(newLead3, 'testHashCode');
       
        
        // Check if the lead is inserted
        //Lead insertedLead = [SELECT Id, Lead_Type__c FROM Lead WHERE LastName = 'NewLead' LIMIT 1];
        
        
        Test.stopTest();
    }

    // Test getTerms method
    @isTest
    static void testGetTerms() {
        createTestData();

        // Start test context
        Test.startTest();

        // Call the method to get terms
        Terms_Conditions__c terms = ChannelPartner_Controller.getTerms();
      
        
        Test.stopTest();
    }
    
    // Test for getTeamMembers method
    @isTest
    static void testGetTeamMembers() {
        // Insert a sample Account and associated data
        Account testAcc2 = new Account(Name = 'Test Account');
        insert testAcc2;
        Account testAcc = new Account(Name = 'Test Account', Team_Member__c = testAcc2.Id);
        insert testAcc;

        
        // Call the method to be tested
        Test.startTest();
        ChannelPartner_Controller.TeamsWrapper  result = ChannelPartner_Controller.getTeamMembers('Test_Team_Member');
        
        Test.stopTest();

    }

    // Test for getRelatedLeads method
    @isTest
    static void testGetRelatedLeads() {
        // Insert sample Lead and Account data
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
		Company__c company = new Company__c(Name = 'TestCompany');
        insert company;
        Project__c project1 = new Project__c(Name = 'Project A', City__c = 'City A', Zone__c = 'East', Company__c = company.Id);
        insert project1;
        Lead testLead = new Lead(LastName = 'Test Lead',Company='test',Project__c=project1.Id, Status = 'Open', isConverted = false);
        insert testLead;

        // Call the method to be tested
        Test.startTest();
        List<Lead> result = ChannelPartner_Controller.getRelatedLeads(testAccount.Id);
        Test.stopTest();

    }

    // Test for getBrokerageDetails method
    @isTest
    static void testGetBrokerageDetails() {
        // Insert sample Brokerage_Calculator__c record
        Brokerage_Calculator__c testBroker = new Brokerage_Calculator__c(Name = 'Test' ,Commission_Rate__c = 'ten', GST__c = 18.0, TDS__c = 10.0);
        insert testBroker;

        // Call the method to be tested
        Test.startTest();
        Brokerage_Calculator__c result = ChannelPartner_Controller.getBrokerageDetails();
        Test.stopTest();


    }

    // Test for CreateChannelPartnerForChannelPartnerTeamPage method
    @isTest
    static void testCreateChannelPartnerForChannelPartnerTeamPage() {
        // Insert Account record to act as the channel partner
        Account testAccount = new Account(Name = 'Test Account', Login_Hash_Code__c = 'Test_Channel_Partner');
        insert testAccount;

        // Create a new Account to be assigned as a team member
        Account newAcc = new Account(Name = 'New Account');
        
        // Call the method to create a channel partner
        Test.startTest();
        String result = ChannelPartner_Controller.CreateChannelPartnerForChannelPartnerTeamPage(newAcc, 'Test_Channel_Partner');
        Test.stopTest();

       
    } 
    
     // Test for getUserDetails method
    @isTest
    static void testGetUserDetails() {
        // Insert sample Account
        Account testAccount = new Account(
            Name = 'Test User',
            Login_Hash_Code__c = 'TestHashCode',
            Email__c = 'testuser@example.com',
            Phone = '1234567890',
            Department__c = 'Sales',
            Profile_Pic_Attachment_Id__c = 'ProfilePic123'
        );
        insert testAccount;

        // Call the method
        Test.startTest();
        Account result = ChannelPartner_Controller.getUserDetails('TestHashCode');
        Test.stopTest();

    }

    // Test for fetchCases method
    @isTest
    static void testFetchCases() {
        // Insert sample Account
        Account testAccount = new Account(
            Name = 'Test User',
            Login_Hash_Code__c = 'TestHashCode'
        );
        insert testAccount;

        // Insert sample Cases
        Case case1 = new Case(
            Subject = 'Test Case 1',
            AccountId = testAccount.Id,
            SuppliedEmail = 'test1@example.com',
            SuppliedPhone = '1234567890',
            Type = 'Issue',
            Description = 'Test Description 1'
        );
        Case case2 = new Case(
            Subject = 'Test Case 2',
            AccountId = testAccount.Id,
            SuppliedEmail = 'test2@example.com',
            SuppliedPhone = '0987654321',
            Type = 'Request',
            Description = 'Test Description 2'
        );
        insert new List<Case>{case1, case2};

        // Call the method
        Test.startTest();
        List<Case> result = ChannelPartner_Controller.fetchCases('TestHashCode');
        Test.stopTest();

    }

    // Test for createCase method
    @isTest
    static void testCreateCase() {
        // Insert sample Account as channel partner
        Account channelPartner = new Account(
            Name = 'Channel Partner',
            Login_Hash_Code__c = 'ChannelPartnerHash',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Channel Partner').getRecordTypeId()
        );
        insert channelPartner;

        // Create a new Case
        Case newCase = new Case(
            Subject = 'New Case',
            SuppliedEmail = 'newcase@example.com',
            SuppliedPhone = '1231231234',
            Description = 'This is a test case'
        );

        // Call the method
        Test.startTest();
        String result = ChannelPartner_Controller.createCase(newCase, 'ChannelPartnerHash');
        Test.stopTest();

      
    }
    
    @isTest
    static void testDoUploadProfilePic() {
        // Setup test data
        Account testAccount = new Account(
            Name = 'Test Account',
            Login_Hash_Code__c = 'testHash123'
        );
        insert testAccount;

        String attachmentBody = EncodingUtil.base64Encode(Blob.valueOf('Test file content'));
        String attachmentName = 'TestProfilePic';
        String fileExtension = 'jpg';

        Test.startTest();
        String result = ChannelPartner_Controller.doUploadProfilePic(
            testAccount.Login_Hash_Code__c,
            attachmentBody,
            attachmentName,
            fileExtension
        );
        Test.stopTest();

   
      
        ContentVersion cv = [SELECT Id, Title FROM ContentVersion WHERE Id = :result];
            
        Account updatedAccount = [SELECT Profile_Pic_Attachment_Id__c FROM Account WHERE Id = :testAccount.Id];
        
    }
     @isTest
    static void testDoUploadTeamMemberProfilePic() {
        // Setup test data
        Account testAccount = new Account(
            Name = 'Test Team Member',
            Login_Hash_Code__c = 'teamMemberHash'
        );
        insert testAccount;

        String attachmentBody = EncodingUtil.base64Encode(Blob.valueOf('Team Member file content'));
        String attachmentName = 'TeamMemberProfilePic';
        String fileExtension = 'png';

        Test.startTest();
        String result = ChannelPartner_Controller.doUploadTeamMemberProfilePic(
            testAccount.Id,
            attachmentBody,
            attachmentName,
            fileExtension
        );
        Test.stopTest();

        ContentVersion cv = [SELECT Id, Title FROM ContentVersion WHERE Title = :attachmentName];
        
        Account updatedAccount = [SELECT Profile_Pic_Attachment_Id__c FROM Account WHERE Id = :testAccount.Id];
       
    }
     @isTest
    static void testGetContentWorkspace() {
        // Setup: Insert a ContentWorkspace record
        ContentWorkspace workspace = new ContentWorkspace(Name = 'Ondonte Files');
        insert workspace;

        Test.startTest();
        Id workspaceId = ChannelPartner_Controller.getContentWorkspace();
        Test.stopTest();

    }

    @isTest
    static void testGetContentWorkspace_NoWorkspace() {
        // Ensure no ContentWorkspace exists with the specified name
        Test.startTest();
        Id workspaceId = ChannelPartner_Controller.getContentWorkspace();
        Test.stopTest();

    }
     @isTest
    static void testGetAllProjectsWithImages() {
		Company__c company = new Company__c(Name = 'TestCompany');
        insert company;
        // Setup: Create Project__c records with Sub_Documents__r
        Project__c project = new Project__c(
            Name = 'Test Project',
            Project_Address__c = 'Test Address',
            Project_Description__c = 'Test Description',
            Project_Type__c = 'Residential',
            Project_Status__c = 'In Progress',
            Area__c = '1500',
            Booking_Amount__c = 50000,
            Total_Amount__c = 500000,
            Unit_Type__c = '1 BHK',
            Company__c = company.Id
        );
        insert project;

        Sub_Document__c subDoc = new Sub_Document__c(
            Name = 'Test SubDoc',
            File_URL__c = 'http://example.com/testfile',
            Project__c = project.Id
        );
        insert subDoc;

        Test.startTest();
        List<Project__c> projects = ChannelPartner_Controller.getAllProjectsWithImages();
        Test.stopTest();

    }

    @isTest
    static void testGetAllProjectsWithImages_NoProjects() {
        // Ensure no Project__c records exist
        Test.startTest();
        List<Project__c> projects = ChannelPartner_Controller.getAllProjectsWithImages();
        Test.stopTest();

    }
    @isTest
    static void testUploadPdfToEvent() {
        // Setup: Create an Event__c record
        Event__c event = new Event__c();
        insert event;

        String fileName = 'TestFile.pdf';
        String base64Data = EncodingUtil.base64Encode(Blob.valueOf('Test PDF content'));

        Test.startTest();
        ChannelPartner_Controller.uploadPdfToEvent(event.Id, fileName, base64Data);
        Test.stopTest();

    }

   /* @isTest
    static void testUploadPdfToEvent_EventNotFound() {
        // Setup: Invalid event Id
        String invalidEventId = 'a0123456789ABCDE';
        String fileName = 'TestFile.pdf';
        String base64Data = EncodingUtil.base64Encode(Blob.valueOf('Test PDF content'));

        try {
            Test.startTest();
            ChannelPartner_Controller.uploadPdfToEvent(invalidEventId, fileName, base64Data);
            Test.stopTest();
          
        } catch (AuraHandledException e) {
            System.debug('Event record not found for the specified ID.' +e.getMessage());
        }
    }*/
     @isTest
    static void testGetEventDetails_ValidId() {
        // Setup: Insert an Event__c record
        Event__c event = new Event__c( File_Id__c = 'TestFileId');
        insert event;

        Test.startTest();
        Event__c fetchedEvent = ChannelPartner_Controller.getEventDetails(event.Id);
        Test.stopTest();

    }

    @isTest
    static void testGetEventDetails_InvalidId() {
        // Setup: Use an invalid Event__c Id
        Id nonExistentEventId = '001000000000000AAA';

        try {
            Test.startTest();
            ChannelPartner_Controller.getEventDetails(nonExistentEventId);
            Test.stopTest();
            
        } catch (Exception e) {
            System.debug('Exception message should indicate no rows found'+e.getMessage());
        }
    }
    @isTest
    static void testUploadImageToEvent_ValidId() {
        // Setup: Insert an Event__c record
        Event__c event = new Event__c();
        insert event;

        String fileName = 'TestImage.jpg';
        String base64Data = EncodingUtil.base64Encode(Blob.valueOf('Test Image Content'));

        Test.startTest();
        ChannelPartner_Controller.uploadImageToEvent(event.Id, fileName, base64Data);
        Test.stopTest();

        // Verify: Check the attachment and updated Event__c record
        Attachment attachment = [SELECT Id, Name FROM Attachment WHERE ParentId = :event.Id];
       

        Event__c updatedEvent = [SELECT Image_Id__c FROM Event__c WHERE Id = :event.Id];
       
    }

   /* @isTest
    static void testUploadImageToEvent_InvalidId() {
        // Setup: Use an invalid Event__c Id
        Id nonExistentEventId = '001000000000000AAA';
        String fileName = 'InvalidImage.jpg';
        String base64Data = EncodingUtil.base64Encode(Blob.valueOf('Invalid Image Content'));

        try {
            Test.startTest();
            ChannelPartner_Controller.uploadImageToEvent(nonExistentEventId, fileName, base64Data);
            Test.stopTest();
           
        } catch (AuraHandledException e) {
            System.debug('Event record not found for the specified ID.'  +e.getMessage());
        }
    }*/
      @isTest
    static void testGetEventDetailsForSite_WithEvents() {
        // Setup: Create Event__c records with Sub_Documents__r
        Event__c event = new Event__c( Event_Date_Time__c = DateTime.now(), Event_Venue__c = 'Test Venue');
        insert event;

        Sub_Document__c subDoc = new Sub_Document__c(Name = 'Test SubDoc', File_URL__c = 'http://example.com/testfile', Event__c = event.Id);
        insert subDoc;

        Test.startTest();
        List<Event__c> events = ChannelPartner_Controller.getEventDetailsForSite();
        Test.stopTest();

    }

    @isTest
    static void testGetEventDetailsForSite_NoEvents() {
        // Ensure no Event__c records exist
        Test.startTest();
        List<Event__c> events = ChannelPartner_Controller.getEventDetailsForSite();
        Test.stopTest();
    }

    @isTest
    static void testGetEventDetailsForSite_Exception() {
        // Induce an exception by mocking an error in query
        Test.startTest();
        //Test.setMock(StubProvider.class, new StubExceptionQueryMock());
        List<Event__c> events = ChannelPartner_Controller.getEventDetailsForSite();
        Test.stopTest();

        
    }
     @isTest
    static void testUpdateProfile_ValidAccount() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        testAccount.Name = 'Updated Account Name';

        Test.startTest();
        Account updatedAccount = ChannelPartner_Controller.updateProfile(testAccount);
        Test.stopTest();

    }

    @isTest
    static void testUpdateProfile_InvalidAccount() {
        Account invalidAccount = new Account();
        try {
            Test.startTest();
            ChannelPartner_Controller.updateProfile(invalidAccount);
            Test.stopTest();
            
        } catch (Exception e) {
            System.debug('Expected DML exception for invalid account' +e.getMessage());
        }
    }
    @isTest
    static void testGetAllMarketingRecords_ValidRecords() {
        // Insert a test marketing record with sub-documents
        Marketing__c marketing = new Marketing__c(Name__c = 'Test Marketing');
        insert marketing;

        Sub_Document__c subDocument = new Sub_Document__c(Name = 'Test Document', File_URL__c = 'https://example.com', Marketing__c = marketing.Id);
        insert subDocument;

        Test.startTest();
        List<Marketing__c> marketingRecords = ChannelPartner_Controller.getAllMarketingRecords();
        Test.stopTest();

    }
     @isTest
    static void testLogoutUser_ValidLoginHashCode() {
        Account testAccount = new Account(Name = 'Test Account', Login_Hash_Code__c = 'TestHash123');
        insert testAccount;

        Test.startTest();
        String result = ChannelPartner_Controller.logoutUser('TestHash123');
        Test.stopTest();

       
        Account updatedAccount = [SELECT Login_Hash_Code__c FROM Account WHERE Id = :testAccount.Id];
       
    }

    @isTest
    static void testLogoutUser_InvalidLoginHashCode() {
        Test.startTest();
        String result = ChannelPartner_Controller.logoutUser('InvalidHash');
        Test.stopTest();

    }
    @isTest
    static void testSubmitAccApproval_SuccessfulSubmission() {
        // Mock RecordTypeId
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Channel Partner').getRecordTypeId();

        Account testAccount = new Account(Name = 'Test Approval Account');
        insert testAccount;

        Test.startTest();
        String result = ChannelPartner_Controller.submitApproval(testAccount.Id);
        Test.stopTest();

        Account updatedAccount = [SELECT RecordTypeId FROM Account WHERE Id = :testAccount.Id];
      
    }

    /*@isTest
    static void testSubmitAccApproval_NullAccount() {
        Test.startTest();
        String result = ChannelPartner_Controller.submitApproval(null);
        Test.stopTest();

    }*/
    
    @isTest
    static void testSendOTP(){
        Test.startTest();
        String otp = ChannelPartner_Controller.sendOTP('7023377001');
        Test.stopTest();
    }
    
    @isTest
    static void testSubmitAcc(){
        Account testAcc = new Account(Name = 'test');
        Test.startTest();
        String result = ChannelPartner_Controller.submitAcc(testAcc);
        Test.stopTest();
    }
    
    @isTest
    static void testUpload(){
        Account testAcc = new Account(Name = 'test');
        insert testAcc;
        Document__c doc = new Document__c(Name = 'testDoc', Account__c = testAcc.Id);
        insert doc;
        String fileType = 'application/pdf';
        String fileData = EncodingUtil.base64Encode(Blob.valueOf('Sample file content'));
        String contentRange = 'bytes 0-99/100';
        Test.startTest();
        GoogleDriveAPIMock mock = new GoogleDriveAPIMock(200, '{ "id": "sampleFileId" }');
        Test.setMock(HttpCalloutMock.class, mock);
        ChannelPartner_Controller.wrapperForResponse wrap = ChannelPartner_Controller.uploadDocuments((String)testAcc.Id, 'testFile', fileData, contentRange, 'testDoc', fileType);
        Test.stopTest();
    }
    
    private class GoogleDriveAPIMock implements HttpCalloutMock {
        private Integer statusCode;
        private String responseBody;

        public GoogleDriveAPIMock(Integer statusCode, String responseBody) {
            this.statusCode = statusCode;
            this.responseBody = responseBody;
        }

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(statusCode);
            res.setBody(responseBody);
            if (req.getEndpoint().contains('uploadType=resumable')) {
                res.setHeader('Location', 'https://www.googleapis.com/upload/drive/v3/files/resumable-session');
            }
            return res;
        }
    }
    
   	@isTest
	static void testGetInvoices() {
    // Set up test data with minimal relationships to test if recursion is the cause
    Account channelPartner = new Account(Name = 'Channel Partner 1');
    insert channelPartner;
    Account channelPartner1 = new Account(Name = 'Channel Partner 1', Team_Member__c = channelPartner.Id );
    insert channelPartner1;

    Opportunity opportunity1 = new Opportunity(
        Name = 'Opportunity 1',
        StageName = 'Closed Won',
        CloseDate = Date.today(),
        Channel_Partner__c = channelPartner1.Id
    );
    insert opportunity1;
    Demand_Letter__c dl = new Demand_Letter__c();
    insert dl;

    Visit__c visit1 = new Visit__c(Opportunity__c = opportunity1.Id);
    insert visit1;

    Receipt__c receipt1 = new Receipt__c(
        Opportunity__c = opportunity1.Id,
        Amount__c = 500,
        Approval_Status__c = 'Approved',
        Demand_Letter__c = dl.Id
    );
    insert receipt1;

    // Mock parameters
    Boolean isTeamHead = true;
    String hashCode = UserInfo.getUserId();

    // Invoke the method
    Test.startTest();
    ChannelPartner_Controller.InvoicesWrapper result = ChannelPartner_Controller.getInvoices(isTeamHead, hashCode);
    Test.stopTest();

	}
    @isTest
    static void testGetInvoices_NoData() {
        // Scenario: No data in the system

        // Mock parameters
        Boolean isTeamHead = false;
        String hashCode = UserInfo.getUserId();

        // Invoke the method
        Test.startTest();
        ChannelPartner_Controller.InvoicesWrapper result = ChannelPartner_Controller.getInvoices(isTeamHead, hashCode);
        Test.stopTest();

    }
    
	@isTest
    static void testGetMyInvoices() {
        // Step 1: Set up test data
        Account channelPartner1 = new Account(
            Name = 'Test Channel Partner',
            Login_Hash_Code__c = '1234abcd'
        );
        insert channelPartner1;
        Account channelPartner = new Account(
            Name = 'Test Channel Partner',
            Login_Hash_Code__c = '1234abcd',
            Team_Member__c = channelPartner1.Id
        );
        insert channelPartner;
		Opportunity opportunity1 = new Opportunity(
        Name = 'Opportunity 1',
        StageName = 'Closed Won',
        CloseDate = Date.today(),
        Channel_Partner__c = channelPartner.Id
    );
    insert opportunity1;
    Demand_Letter__c dl = new Demand_Letter__c();
    insert dl;
        Receipt__c receipt1 = new Receipt__c(
            Amount__c = 500,
            Approval_Status__c = 'Approved',
           
            Opportunity__c = opportunity1.Id,
            Demand_Letter__c = dl.Id
        );
        insert receipt1;

        Receipt__c receipt2 = new Receipt__c(
            Amount__c = 1500,
            Approval_Status__c = 'Pending',
            
            Opportunity__c = opportunity1.Id,
            Demand_Letter__c = dl.Id
        );
        insert receipt2;

        // Step 2: Mock the hashCode parameter for the remote method call
        String hashCode = '1234abcd';

        // Step 3: Invoke the method
        Test.startTest();
        List<Channel_Partner_Invoice__c> result = ChannelPartner_Controller.getMyInvoices(hashCode);
        Test.stopTest();

    }
	 @isTest
    static void testGetFieldDependencies() {
        
		Company__c company = new Company__c(Name = 'TestCompany');
        insert company;
        Project__c project1 = new Project__c(Name = 'Project A', City__c = 'City A', Zone__c = 'East', Company__c = company.Id);
        insert project1;
        Lead testLead = new Lead(LastName = 'Test Lead',Company='test',Project__c=project1.Id, Status = 'Open', isConverted = false);
        insert testLead;
        System.debug('testLead inserted==>' +testLead.Id);

 
        String objectName = 'Lead';  
        String controllingField = 'LeadSource';  
        String dependentField = 'Lead_Sub_Source__c';  

        // Step 3: Invoke the method
        Test.startTest();
        Map<String, List<String>> result = ChannelPartner_Controller.getFieldDependencies(objectName, controllingField, dependentField);
        Test.stopTest();

      

        // Assuming you expect specific controlling field values, validate them
        if (result != null && result.containsKey('Public')) {
            System.assert(result.get('Public').size() > 0, 'The dependent field list should not be empty for controlling field "Public".');
        }

       
        if (result.containsKey('Private')) {
            List<String> dependentValues = result.get('Private');
            
        }
    }
	 @isTest
    static void testFetchVisitOppRecords() {
        Test.startTest();
        ChannelPartner_Controller.ChannelPartnerWrapper result1 = ChannelPartner_Controller.FetchVisitOppRecords(true, '247839');
        ChannelPartner_Controller.ChannelPartnerWrapper result2 = ChannelPartner_Controller.FetchVisitOppRecords(false, '247839');
        Test.stopTest();
    }
}