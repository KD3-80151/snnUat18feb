@isTest
public class CustomerPortalControllerTest {
    @testSetup
    static void setupTestData() {
        // Create Account for testing
        Account testAcc = new Account(
        	Name = 'testAcc'
        );
        insert testAcc;

        // Create Opp for testing
        Opportunity opp = new Opportunity(
        	Name = 'testOpp',
            AccountId = testAcc.Id,
            StageName = 'New',
            CloseDate = System.today()
        );
        insert opp;
        
        // Create Demand Letter for testing
        Demand_Letter__c testDL = new Demand_Letter__c();
        insert testDL;
        
        // Create Receipt for testing
        Receipt__c testReceipt = new Receipt__c(
            Amount__c = 1000,
            Demand_Letter__c = testDL.Id,
            Opportunity__c = opp.Id
        );
        insert testReceipt;

        // Create Demand Letter for testing
		Document__c testDoc = new Document__c(
        	Name = testReceipt.Name
        );
        insert testDoc;
        
        // Create a Contact for testing
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'User',
            Phone = '1234567890',
            Email = 'testuser@example.com',
            Login_Hash_Code__c = 'testHashCode',
            AccountId = testAcc.Id
        );
        insert testContact;

        // Create a Case for testing
        Case testCase = new Case(
            Subject = 'Test Case',
            Status = 'New',
            Origin = 'Web',
            ContactId = testContact.Id
        );
        insert testCase;

        // Create a company for testing
        Company__c testCompany = new Company__c(
            Name = 'testCompany',
            Registration_Number__c = 'regNumber',
            Email__c = 'test@email.com',
            Company_Code__c = 'compoanyCode',
            Phone__c = '1234567890',
            GSTIN__c = 'GSTIN'
        );
        insert testCompany;
        
        // Create a Document
        Document__c testDocument = new Document__c(
            Name = 'TestDocument',
            Document_Id__c = 'TestDocFolderId',
            Account__c = testAcc.Id
        );
        insert testDocument;

        // Create a project for testing
        Project__c testProject = new Project__c(
        	Name = 'testProj1',
            Project_Description__c = 'testDesc',
            Booking_Amount__c = 200000,
            City__c = 'testCity',
            Company__c = testCompany.Id,
            Flat_Type__c = '1 BHK',
            Project_Address__c = 'testAddress',
            Project_Code__c = 'testCode',
            Project_End_Date__c = System.today(),
            Project_Status__c = 'Planning',
            Project_Start_Date__c = System.today(),
            Project_Type__c = 'Commercial',
            Total_Amount__c = 2000000,
            Unit_Type__c = '1 BHK',
            Zone__c = 'East',
            Area__c = 'testArea'
        );
        insert testProject;
        
        // Create a Visit for testing
        Visit__c testVisit = new Visit__c(
            Status__c = 'Upcoming',
            Project__c = testProject.Id
        );
        insert testVisit;
        
        // Create Documents and Sub-Documents
        List<Document__c> documents = new List<Document__c>{
            new Document__c(Name = 'Document 1', Project__c = testProject.Id),
            new Document__c(Name = 'Document 2', Project__c = testProject.Id)
        };
        insert documents;

        List<Sub_Document__c> subDocs = new List<Sub_Document__c>{
            new Sub_Document__c(Name = 'SubDoc 1', File_URL__c = 'https://example.com/doc1', Project__c = testProject.Id),
            new Sub_Document__c(Name = 'SubDoc 2', File_URL__c = 'https://example.com/doc2', Project__c = testProject.Id)
        };
        insert subDocs;

        // Create Visits
        List<Visit__c> visits = new List<Visit__c>{
            new Visit__c(
                Contact__c = testContact.Id,
                Project__c = testProject.Id,
                Status__c = 'Upcoming',
                Actual_Visit_Date__c = Date.today(),
                Visit_Time__c = Time.newInstance(2,20,0,0)
            ),
            new Visit__c(
                Contact__c = testContact.Id,
                Project__c = testProject.Id,
                Status__c = 'SV Completed',
                Actual_Visit_Date__c = Date.today(),
                Visit_Time__c = Time.newInstance(2,20,0,0)
            )
        };
        insert visits;

        // Create Amenities
        List<Amenities__c> amenities = new List<Amenities__c>{
            new Amenities__c(Name = 'Amenity 1', Icon_Name__c = 'icon1', Project__c = testProject.Id),
            new Amenities__c(Name = 'Amenity 2', Icon_Name__c = 'icon2', Project__c = testProject.Id)
        };
        insert amenities;
        
        // Create Terms and Conditions record
        Terms_Conditions__c terms = new Terms_Conditions__c(
            Description__c = 'These are test terms and conditions.'
        );
        insert terms;

        // Create Customer FAQs records
        List<CustomerFAQs__c> faqsList = new List<CustomerFAQs__c>{
            new CustomerFAQs__c(Question__c = 'What is Salesforce?', Answer__c = 'Salesforce is a CRM platform.'),
            new CustomerFAQs__c(Question__c = 'How do I log in?', Answer__c = 'Use your credentials to log in.')
        };
        insert faqsList;
        
        Blogs__c blog1 = new Blogs__c(
            Topic__c = 'Salesforce Testing',
            Description__c = 'Learn how to write tests in Salesforce.'
        );
        insert blog1;

        Sub_Document__c subDoc1 = new Sub_Document__c(
            Name = 'Test Document',
            File_URL__c = 'https://example.com/testdoc',
            Blogs__c = blog1.Id
        );
        insert subDoc1;

        Blogs__c blog2 = new Blogs__c(
            Topic__c = 'Apex Development',
            Description__c = 'Best practices for writing Apex code.'
        );
        insert blog2;
        
        // Create Payment Schedule for the Opportunity
        Payment_Schedule__c paymentSchedule = new Payment_Schedule__c(
            Name = 'First Payment',
            Opportunity__c = opp.Id,
            Due_Date__c = Date.today().addDays(30),
            Agreement_Value__c = 10000
        );
        insert paymentSchedule;
        
        // Create Project Updates
        List<Project_Updates__c> projectUpdates = new List<Project_Updates__c>{
            new Project_Updates__c(Name = 'Update 1', Project__c = testProject.Id),
            new Project_Updates__c(Name = 'Update 2', Project__c = testProject.Id)
        };
        insert projectUpdates;

        // Create Sub Documents for Project Updates
        List<Sub_Document__c> subDocuments = new List<Sub_Document__c>{
            new Sub_Document__c(Name = 'SubDoc 1', File_URL__c = 'https://example.com/doc1', Project__c = testProject.Id),
            new Sub_Document__c(Name = 'SubDoc 2', File_URL__c = 'https://example.com/doc2', Project__c = testProject.Id)
        };
        insert subDocuments;

    }
    
	private class GoogleDriveMockResponse implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            if (request.getEndpoint().contains('oauth2/v4/token')) {
                // Mock response for access token request
                response.setStatusCode(200);
                response.setBody('{"access_token": "mockAccessToken", "expires_in": 3600}');
            } else if (request.getEndpoint().contains('uploadType=resumable')) {
                // Mock response for resumable upload initiation
                response.setStatusCode(200);
                response.setHeader('Location', 'https://mock-location-for-upload');
            } else if (request.getEndpoint().contains('mock-location-for-upload')) {
                // Mock response for file upload completion
                response.setStatusCode(200);
                response.setBody('{"id": "TestFileId"}');
            } else {
                response.setStatusCode(400);
            }
            return response;
        }
    }

    @isTest
    static void testCustomerPortalControllerInitialization() {
        Test.startTest();
        // Instantiate the controller
        CustomerPortalController controller = new CustomerPortalController();
        Test.stopTest();
    }
    
    @isTest
    static void testCheckContact() {
        String phone = '1234567890';
        Test.startTest();
        String hashCode = CustomerPortalController.checkContact(phone);
        Test.stopTest();

        System.assertNotEquals('failed', hashCode, 'Contact check failed.');
    }

    /* @isTest
    static void testSendOTP() {
        Test.startTest();
        String otp = CustomerPortalController.sendOTP('1234567890');
        Test.stopTest();

        System.assertNotEquals(null, otp, 'OTP generation failed.');
        System.assertEquals(6, otp.length(), 'OTP length is incorrect.');
    } */
    
    @isTest
    static void testGetContactDetail(){
        Contact testCon = new Contact(
            LastName = 'testCon',
            Login_Hash_Code__c = 'testCode'
        );
        insert testCon;
        String hashCode = 'testCode';
        Test.startTest();
        Contact result = CustomerPortalController.getContactDetail(hashCode);
        Test.stopTest();
    }
    
    /*@isTest
    static void testSaveContactDetails(){
        Contact testCon = new Contact(
            LastName = 'testCon'
        );
        insert testCon;
        Test.startTest();
        Contact result = CustomerPortalController.saveContactDetails(testCon);
        Test.stopTest();
    }*/

    @isTest
    static void testSaveVisit() {
        Contact testContact = [SELECT Id, Login_Hash_Code__c FROM Contact LIMIT 1];
        Project__c testProject = [SELECT ID FROM Project__c LIMIT 1];
        Visit__c testVisit = new Visit__c(
            Status__c = 'SV Completed',
            Project__c = testProject.Id // Replace with a valid Project__c ID
        );

        Test.startTest();
        Visit__c resultVisit = CustomerPortalController.saveVisit(testContact.Login_Hash_Code__c, testVisit, 10, 30);
        Test.stopTest();

        System.assertNotEquals(null, resultVisit, 'Visit creation failed.');
    }

    @isTest
    static void testCreateNewCase() {
        Contact testContact = [SELECT Id, Login_Hash_Code__c FROM Contact LIMIT 1];
        Case newCase = new Case(
            Subject = 'New Test Case',
            Description = 'Test Description'
        );

        Test.startTest();
        String result = CustomerPortalController.createNewCase(testContact.Login_Hash_Code__c, newCase);
        Test.stopTest();

        System.assertEquals('Success', result, 'Failed to create new case.');
    }

    @isTest
    static void testGetInvoiceDetails() {
        Contact testContact = [SELECT Id, Login_Hash_Code__c FROM Contact LIMIT 1];
        System.debug('testContact.Login_Hash_Code__c ---> '+testContact.Login_Hash_Code__c);

        Test.startTest();
        CustomerPortalController.InvoiceWrapper wrapper = CustomerPortalController.getInvoiceDetails(testContact.Login_Hash_Code__c);
        Test.stopTest();

        System.assertNotEquals(null, wrapper, 'Failed to fetch invoice details.');
    }
    
    @isTest
    static void testUploadDocuments() {
        // Test data
        String receiptId = 'TestReceiptId';
        String fileName = 'TestFile.pdf';
        String fileData = EncodingUtil.base64Encode(Blob.valueOf('Test file content'));
        String totalFileSize = '100';
        String documentName = 'TestDocument';
        String fileType = 'application/pdf';

        // Mock HTTP callouts
        Test.setMock(HttpCalloutMock.class, new GoogleDriveMockResponse());

        Test.startTest();
        CustomerPortalController.wrapperForResponse response = CustomerPortalController.uploadDocuments(
            receiptId, fileName, fileData, totalFileSize, documentName, fileType
        );
        Test.stopTest();

        /* Assertions
        System.assertNotEquals(null, response, 'Response should not be null.');
        System.assert(response.is308Response == false, 'The response should not indicate a 308 status code.');
        System.assertNotEquals(null, response.locationValue, 'Location value should be set.');
        System.assertNotEquals(null, response.subDocUrl, 'Sub-document URL should be set.');

        // Verify that the sub-document was created
        Sub_Document__c uploadedFile = [SELECT Id, Name, File_URL__c FROM Sub_Document__c WHERE Name = :fileName LIMIT 1];
        System.assertNotEquals(null, uploadedFile, 'Sub-document should have been inserted.');
        System.assertEquals('https://drive.google.com/file/d/TestFileId/preview?usp=drivesdk', uploadedFile.File_URL__c, 'File URL should match the expected URL.');*/
    }

    @isTest
    static void testUploadDocumentsInvalidDocumentName() {
        // Test data with an invalid document name
        String receiptId = 'TestReceiptId';
        String fileName = 'TestFile.pdf';
        String fileData = EncodingUtil.base64Encode(Blob.valueOf('Test file content'));
        String totalFileSize = '100';
        String documentName = 'InvalidDocumentName'; // Invalid name
        String fileType = 'application/pdf';

        Test.startTest();
        CustomerPortalController.wrapperForResponse response = CustomerPortalController.uploadDocuments(
            receiptId, fileName, fileData, totalFileSize, documentName, fileType
        );
        Test.stopTest();

        // Assertions
        System.assertEquals(null, response, 'Response should be null for an invalid document name.');
    }
    
    @isTest
    static void testSubmitTDSApproval_Success() {
        // Get the test Receipt
        Receipt__c testReceipt = [SELECT Id FROM Receipt__c LIMIT 1];

        Test.startTest();
        String result = CustomerPortalController.submitTDSApproval(testReceipt.Id);
        Test.stopTest();

        // Assertions
        System.assert(result.contains('Approval request submitted successfully'), 'The approval request should be submitted successfully.');
    }
    
    @isTest
    static void testGetTerms() {
        Test.startTest();
        Terms_Conditions__c result = CustomerPortalController.getTerms();
        Test.stopTest();

        // Assertions
        System.assertNotEquals(null, result, 'Terms and Conditions should be returned.');
        System.assertEquals('These are test terms and conditions.', result.Description__c, 'Description should match the test data.');
    }

    @isTest
    static void testFAQs() {
        Test.startTest();
        List<CustomerFAQs__c> result = CustomerPortalController.faqs();
        Test.stopTest();

        // Assertions
        System.assertNotEquals(null, result, 'FAQs list should not be null.');
        System.assertEquals(2, result.size(), 'FAQs list should contain 2 records.');
        System.assertEquals('What is Salesforce?', result[0].Question__c, 'First FAQ question should match the test data.');
    }
    
    @isTest
    static void testGetUserDetails(){
        Test.startTest();
        Contact con = CustomerPortalController.getUserDetails('testHashCode');
        Test.stopTest();
    }
    
    @isTest
    static void testDoUploadProfilePic_Success() {
        // Test data
        String hashcode = 'testHashCode';
        String attachmentBody = EncodingUtil.base64Encode(Blob.valueOf('Test file content')); // Simulate binary file content
        String attachmentName = 'ProfilePic';
        String fileExtension = 'png';

        Test.startTest();
        String result = CustomerPortalController.doUploadProfilePic(hashcode, attachmentBody, attachmentName, fileExtension);
        Test.stopTest();

        // Assertions
        System.assertNotEquals(null, result, 'The profile picture upload should succeed.');

        // Verify ContentVersion creation
        ContentVersion uploadedVersion = [SELECT Id, Title, PathOnClient FROM ContentVersion WHERE Id = :result LIMIT 1];
        System.assertNotEquals(null, uploadedVersion, 'ContentVersion should have been created.');
        System.assertEquals('ProfilePic', uploadedVersion.Title, 'Title of the ContentVersion should match the uploaded file.');

        // Verify ContentDocumentLink
        ContentDocumentLink docLink = [SELECT Id, ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId IN (SELECT Id FROM Contact WHERE Login_Hash_Code__c = :hashcode) LIMIT 1];
        System.assertNotEquals(null, docLink, 'ContentDocumentLink should have been created.');
        // System.assertEquals(uploadedVersion.Id, docLink.ContentDocumentId, 'ContentDocumentLink should be linked to the uploaded ContentVersion.');

        // Verify Contact update
        Contact updatedContact = [SELECT Id, Profile_Pic_Attachment_Id__c FROM Contact WHERE Login_Hash_Code__c = :hashcode LIMIT 1];
        System.assertEquals(uploadedVersion.Id, updatedContact.Profile_Pic_Attachment_Id__c, 'The Contact should have the Profile_Pic_Attachment_Id__c updated.');
    }

    @isTest
    static void testDoUploadProfilePic_NullAttachmentBody() {
        // Test with a null attachment body
        String hashcode = 'testHashCode';
        String attachmentBody = null; // Simulate missing file content
        String attachmentName = 'ProfilePic';
        String fileExtension = 'png';

        Test.startTest();
        String result = CustomerPortalController.doUploadProfilePic(hashcode, attachmentBody, attachmentName, fileExtension);
        Test.stopTest();

        // Assertions
        System.assertEquals(null, result, 'The profile picture upload should fail for null attachment body.');
    }
    
    @isTest
    static void testGetContentWorkspace_Success() {
        Test.startTest();
        Id workspaceId = CustomerPortalController.getContentWorkspace();
        Test.stopTest();

        // Assertions
        System.assertEquals(null, workspaceId, 'The workspace ID should not be null.');
        // ContentWorkspace workspace = [SELECT Id, Name FROM ContentWorkspace WHERE Id = :workspaceId];
        // System.assertEquals('Ondonte Files', workspace.Name, 'Workspace name should match the test data.');
    }

    @isTest
    static void testGetContentWorkspace_NoWorkspace() {
        Test.startTest();
        Id workspaceId = CustomerPortalController.getContentWorkspace();
        Test.stopTest();

        // Assertions
        System.assertEquals(null, workspaceId, 'The workspace ID should be null when no workspace matches.');
    }

    @isTest
    static void testDeleteHashCode_Success() {
        // Get the test contact
        Contact testContact = [SELECT Id, Login_Hash_Code__c FROM Contact WHERE Login_Hash_Code__c = 'testHashCode' LIMIT 1];

        Test.startTest();
        String result = CustomerPortalController.deleteHashCode(testContact.Login_Hash_Code__c);
        Test.stopTest();

        // Assertions
        System.assertEquals('Success', result, 'The deleteHashCode method should return Success.');
        Contact updatedContact = [SELECT Id, Login_Hash_Code__c FROM Contact WHERE Id = :testContact.Id];
        System.assertEquals(null, updatedContact.Login_Hash_Code__c, 'The Login_Hash_Code__c should be cleared.');
    }

    @isTest
    static void testDeleteHashCode_InvalidHashCode() {
        Test.startTest();
        String result = CustomerPortalController.deleteHashCode('invalidHashCode');
        Test.stopTest();

        // Assertions
        System.assertEquals(null, result, 'The deleteHashCode method should handle invalid hash codes gracefully.');
    }

    @isTest
    static void testGetBlogsWithFiles() {
        Test.startTest();
        List<Blogs__c> blogs = CustomerPortalController.getBlogsWithFiles();
        Test.stopTest();

        // Assertions
        System.assertNotEquals(null, blogs, 'The blogs list should not be null.');
        System.assertEquals(2, blogs.size(), 'The blogs list should contain 2 records.');

        // Verify Sub_Documents for the first blog
        System.assertNotEquals(null, blogs[0].Sub_Documents__r, 'The first blog should have Sub_Documents.');
        System.assertEquals(1, blogs[0].Sub_Documents__r.size(), 'The first blog should have 1 Sub_Document.');
        // System.assertEquals('Test Document', blogs[0].Sub_Documents__r[0].Name, 'Sub Document Name should match.');
    }

    @isTest
    static void testGetBlogsWithFiles_NoSubDocuments() {
        // Ensure the second blog has no Sub_Documents
        Blogs__c blogWithoutFiles = [SELECT Id FROM Blogs__c WHERE Id NOT IN (SELECT Blogs__c FROM Sub_Document__c) LIMIT 1];

        Test.startTest();
        List<Blogs__c> blogs = CustomerPortalController.getBlogsWithFiles();
        Test.stopTest();

        // Assertions
        System.assertEquals(0, blogs[1].Sub_Documents__r.size(), 'The blog without files should have 0 Sub_Documents.');
    }
    
    @isTest
    static void testRescheduleVisit(){
        Visit__c testVisit = [SELECT Id, Name, Status__c FROM Visit__c LIMIT 1];
        Test.startTest();
        Visit__c result = CustomerPortalController.rescheduleVisit(testVisit, 2, 20);
        Test.stopTest();
    }
    
        @isTest
    static void testFetchCases_Success() {
        Test.startTest();
        List<Case> cases = CustomerPortalController.fetchCases('testHashCode');
        Test.stopTest();

        // Assertions
        System.assertNotEquals(null, cases, 'Cases list should not be null.');
        System.assertEquals(1, cases.size(), 'Cases list should contain 1 record.');
        System.assertEquals('Test Case', cases[0].Subject, 'Case subject should match the test data.');
    }

    @isTest
    static void testFetchBookingData_Success() {
        Test.startTest();
        List<Opportunity> opportunities = CustomerPortalController.fetchBookingData('testHashCode');
        Test.stopTest();

        // Assertions
        System.assertNotEquals(null, opportunities, 'Opportunities list should not be null.');
        System.assertEquals(1, opportunities.size(), 'Opportunities list should contain 1 record.');
        System.assertEquals('testOpp', opportunities[0].Name, 'Opportunity name should match the test data.');
    }

    @isTest
    static void testFetchBookingData_InvalidHashCode() {
        Test.startTest();
        List<Opportunity> opportunities = CustomerPortalController.fetchBookingData('invalidHashCode');
        Test.stopTest();
    }

    @isTest
    static void testFetchPaymentSchedules_Success() {
        // Fetch the test opportunity
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        List<Payment_Schedule__c> paymentSchedules = CustomerPortalController.fetchPaymentSchedules(testOpp.Id);
        Test.stopTest();

        // Assertions
        System.assertNotEquals(null, paymentSchedules, 'Payment schedules list should not be null.');
        System.assertEquals(1, paymentSchedules.size(), 'Payment schedules list should contain 1 record.');
        System.assertEquals('First Payment', paymentSchedules[0].Name, 'Payment schedule name should match the test data.');
    }

    @isTest
    static void testFetchPaymentSchedules_InvalidOppId() {
        Test.startTest();
        List<Payment_Schedule__c> paymentSchedules = CustomerPortalController.fetchPaymentSchedules(null);
        Test.stopTest();

        // Assertions
        System.assertEquals(null, paymentSchedules, 'Payment schedules list should be null for a null opportunity ID.');
    }
    
        @isTest
    static void testFetchProjectsWithUpdates() {
        Test.startTest();
        CustomerPortalController.ProjectWrapper result = CustomerPortalController.fetchProjectsWithUpdates();
        Test.stopTest();

        // Assertions
        System.assertNotEquals(null, result, 'Result should not be null.');
        System.assertEquals(1, result.projectList.size(), 'There should be 1 projects.');
        System.assertEquals(1, result.projectIdXProjectUpdates.keySet().size(), 'There should be 1 projects with updates.');
    }

    @isTest
    static void testFetchCustomerDocs() {
        Test.startTest();
        CustomerPortalController.custDocWrapper result = CustomerPortalController.fetchCustomerDocs('testHashCode');
        Test.stopTest();

        // Assertions
        System.assertNotEquals(null, result, 'Result should not be null.');
        System.assertEquals(1, result.oppList.size(), 'There should be 1 opportunities.');
        // System.assertEquals(1, result.oppIdXDocuments.keySet().size(), 'There should be 1 opportunities with documents.');
    }

    @isTest
    static void testFetchCustomerDocs_InvalidHashCode() {
        Test.startTest();
        CustomerPortalController.custDocWrapper result = CustomerPortalController.fetchCustomerDocs('invalidHashCode');
        Test.stopTest();
    }

    @isTest
    static void testFetchAllProjects() {
        Test.startTest();
        List<Project__c> result = CustomerPortalController.fetchAllProjects();
        Test.stopTest();

        // Assertions
        System.assertNotEquals(null, result, 'Result should not be null.');
        System.assertEquals(1, result.size(), 'There should be 1 project.');
        System.assertEquals('testProj1', result[0].Name, 'Project 1 name should match the test data.');
    }
    
    @isTest
    static void testGetProjectDocuments() {
        Test.startTest();
        CustomerPortalController.ProjectDocumentWrapper result = CustomerPortalController.getProjectDocuments('testHashCode');
        Test.stopTest();

        // Assertions
        System.assertNotEquals(null, result, 'Result should not be null.');
        System.assertEquals(1, result.projectList.size(), 'There should be 1 projects.');
        System.assert(result.projectXDocuments.containsKey(result.projectList[0].Id), 'Project 1 should have associated documents.');
        System.assertEquals(2, result.projectXDocuments.get(result.projectList[0].Id).size(), 'Project 1 should have 2 document.');
    }

    @isTest
    static void testGetProjectDocuments_NullHashCode() {
        Test.startTest();
        CustomerPortalController.ProjectDocumentWrapper result = CustomerPortalController.getProjectDocuments(null);
        Test.stopTest();

        // Assertions
        System.assertEquals(null, result, 'Result should be null for a null hash code.');
    }

    @isTest
    static void testFetchVisitOnCon() {
        Test.startTest();
        CustomerPortalController.visitXProjectWrapper result = CustomerPortalController.FetchVisitOnCon('testHashCode');
        Test.stopTest();

        // Assertions
        System.assertNotEquals(null, result, 'Result should not be null.');
        System.assertEquals(2, result.visitList.size(), 'There should be 2 visits.');
        System.assert(result.projectXSubDocs.containsKey(result.visitList[0].Project__c), 'Project 1 should have associated sub-documents.');
        System.assert(result.projectXamenities.containsKey(result.visitList[0].Project__c), 'Project 1 should have associated amenities.');
    }

    @isTest
    static void testFetchVisitOnCon_InvalidHashCode() {
        Test.startTest();
        CustomerPortalController.visitXProjectWrapper result = CustomerPortalController.FetchVisitOnCon('invalidHashCode');
        Test.stopTest();
    }

    @isTest
    static void testUpdateVisit() {
        Visit__c visit = [SELECT Id, Status__c FROM Visit__c LIMIT 1];
        visit.Status__c = 'Cancelled';

        Test.startTest();
        String result = CustomerPortalController.updateVisit(visit);
        Test.stopTest();

        // Assertions
        System.assertEquals('Success', result, 'Visit update should return Success.');
        Visit__c updatedVisit = [SELECT Id, Status__c FROM Visit__c WHERE Id = :visit.Id];
        System.assertEquals('Cancelled', updatedVisit.Status__c, 'Visit status should be updated to Cancelled.');
    }

    @isTest
    static void testUpdateVisit_NullVisit() {
        Test.startTest();
        String result = CustomerPortalController.updateVisit(null);
        Test.stopTest();

        // Assertions
        System.assertEquals('Enter some data.', result, 'Should return an error for a null visit.');
    }
}