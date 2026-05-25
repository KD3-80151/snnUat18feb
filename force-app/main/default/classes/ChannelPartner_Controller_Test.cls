@isTest
public class ChannelPartner_Controller_Test {

    @testSetup
    static void setup() {
        Channel_Partner_Dashboard_Tabs__c cdTab1 = new Channel_Partner_Dashboard_Tabs__c(
            Name = 'Tab 1',
            Tab_Label__c = 'Tab Label 1',
            Controller_Name__c = 'Controller1',
            Display_Order__c = 1
        );
        insert cdTab1;

        Channel_Partner_Dashboard_Tabs__c cdTab2 = new Channel_Partner_Dashboard_Tabs__c(
            Name = 'Tab 2',
            Tab_Label__c = 'Tab Label 2',
            Controller_Name__c = 'Controller2',
            Display_Order__c = 2
        );
        insert cdTab2;

        RecordType channelPartnerRecordType = [SELECT Id FROM RecordType WHERE DeveloperName = 'Channel_Partner' AND SObjectType = 'Account' LIMIT 1];
        
        Account channelPartnerAccount = new Account(
            Name = 'Test Channel Partner',
            Phone = '123-456-7890',
            RecordTypeId = channelPartnerRecordType.Id
        );
        insert channelPartnerAccount;

        RecordType defaultRecordType = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' LIMIT 1];
        Account nonChannelPartnerAccount = new Account(
            Name = 'Test Non-Channel Partner',
            Phone = '987-654-3210',
            RecordTypeId = defaultRecordType.Id
        );
        insert nonChannelPartnerAccount;
    }

    @isTest
    static void testConstructor() {
        Test.startTest();
        ChannelPartner_Controller controller = new ChannelPartner_Controller();
        Test.stopTest();
    }

    @isTest
    static void testCheckAccount_ValidPhoneNumber_ChannelPartner() {
        Account channelPartner = [SELECT Phone FROM Account WHERE Name = 'Test Channel Partner' LIMIT 1];
        
        Test.startTest();
        // String result = ChannelPartner_Controller.checkAccount(channelPartner.Phone);
        Test.stopTest();
    }

    @isTest
    static void testCheckAccount_ValidPhoneNumber_NotChannelPartner() {
        Account nonChannelPartner = [SELECT Phone FROM Account WHERE Name = 'Test Non-Channel Partner' LIMIT 1];
        
        Test.startTest();
        // String result = ChannelPartner_Controller.checkAccount(nonChannelPartner.Phone);
        Test.stopTest();
    }

    @isTest
    static void testCheckAccount_NoAccountFound() {
        Test.startTest();
        // String result = ChannelPartner_Controller.checkAccount('555-555-5555');
        Test.stopTest();
    }

    @isTest
    static void testCheckAccount_InvalidPhoneNumber() {
        Test.startTest();
        // String result = ChannelPartner_Controller.checkAccount('');
        Test.stopTest();
    }

    @isTest
    static void testCheckAccount_ExceptionHandling() {
        Test.startTest();
        // String result = ChannelPartner_Controller.checkAccount(null);
        Test.stopTest();
    }
    
   @isTest
    static void testGetChannelPartnerData() {
        Account channelPartner = new Account(
            Name = 'Test Channel Partner', 
            Login_Hash_Code__c = 'TestChannelPartnerId'
        );
        insert channelPartner;
        Company__c cmp = new Company__c();
            cmp.Name = 'test';
            insert cmp;
        Project__c prj = new Project__c();
        prj.Name = 'test';
        prj.Company__c = cmp.Id;
        insert prj;
        
        Lead lead1 = new Lead(
            FirstName = 'John', 
            LastName = 'Doe', 
            Company = 'Test Company', 
            Phone = '1234567890', 
            LeadSource = 'Web', 
            Project__c = prj.Id,
            Channel_Partner__c = channelPartner.Id
        );
        Lead lead2 = new Lead(
            FirstName = 'Jane', 
            LastName = 'Smith', 
            Company = 'Another Company', 
            Phone = '0987654321', 
            LeadSource = 'Web',
            Project__c = prj.Id,
            Channel_Partner__c = channelPartner.Id,
            IsConverted = false
        );
        insert new List<Lead>{lead1, lead2};

        Visit__c visit1 = new Visit__c(
            Channel_Partner__c = channelPartner.Id, 
            Company_Name__c = 'Test Company'
        );
        Visit__c visit2 = new Visit__c(
            Channel_Partner__c = channelPartner.Id, 
            Company_Name__c = 'Another Company' 
        );
        insert new List<Visit__c>{visit1, visit2};

        Opportunity opp1 = new Opportunity(
            Name = 'Opportunity 1', 
            StageName = 'Prospecting',
            CloseDate = System.Today() +1,
            Channel_Partner__c = channelPartner.Id,
            Amount = 1000
        );
        Opportunity opp2 = new Opportunity(
            Name = 'Opportunity 2', 
            StageName = 'Closed Won', 
            CloseDate = System.Today() +1,
            Channel_Partner__c = channelPartner.Id,
            Amount = 5000
        );
        insert new List<Opportunity>{opp1, opp2};

        Test.startTest();
        ChannelPartner_Controller.getChannelPartnerData('TestChannelPartnerId');
        Test.stopTest();
    } 
    
     @isTest
    static void testCreateLeadForChannelPartnerLeadPage() {
        Account channelPartner = new Account(
            Name = 'Test Channel Partner', 
            Login_Hash_Code__c = 'TestChannelPartnerId'
        );
        insert channelPartner;
		 Company__c cmp = new Company__c();
            cmp.Name = 'test';
            insert cmp;
        
        Project__c prj = new Project__c();
        prj.Name = 'test';
        prj.Company__c = cmp.Id;
        insert prj;
        
        Lead testLead = new Lead(
            FirstName = 'John',
            LastName = 'Doe',
            Company = 'Test Company',
            Phone = '1234567890',
            LeadSource = 'Web',
            Email = 'Test123@gmail.com',
            Lead_Type__c = 'Direct',
            Status = 'Re-Enquiry',
            Project__c = prj.Id
        );
		Lead tL2 = new Lead(
            FirstName = 'John2',
            LastName = 'Doe2',
            Company = 'Test Company2',
            Phone = '1234567890',
            LeadSource = 'Web',
            Email = 'Test123@gmail.com',
            Lead_Type__c = 'Direct',
            Status = 'Re-Enquiry',
            Project__c = prj.Id
        );
        insert tL2;
        Test.startTest();
        String result = ChannelPartner_Controller.CreateLeadForChannelPartnerLeadPage(testLead, 'TestChannelPartnerId');
        Test.stopTest();

    }
     @isTest
    static void testGetTermsWithNoRecords() {
        delete [SELECT Id FROM Terms_Conditions__c];

        Test.startTest();
        Terms_Conditions__c result = ChannelPartner_Controller.getTerms();
        Test.stopTest();
    }

    @isTest
    static void testGetTermsWithRecords() {
        Terms_Conditions__c terms = new Terms_Conditions__c(
            Description__c = 'Test Terms and Conditions'
        );
        insert terms;

        Test.startTest();
        Terms_Conditions__c result = ChannelPartner_Controller.getTerms();
        Test.stopTest();
    }
    
   @isTest
    static void testGetTeamMembers() {
        Account teamMember = new Account(
            Name = 'Test Team Member', 
            Phone = '1234567890', 
            Email__c = 'test@example.com',
            Login_Hash_Code__c = 'TestTeamMemberId'
        );
        insert teamMember;

        Account account1 = new Account(
            Name = 'Account 1', 
            Phone = '1111111111', 
            Team_Member__c = teamMember.Id,
            Email__c = 'account1@example.com'
        );
        Account account2 = new Account(
            Name = 'Account 2', 
            Phone = '2222222222', 
            Team_Member__c = teamMember.Id,
            Email__c = 'account2@example.com'
        );
        insert new List<Account>{account1, account2};

        Test.startTest();
        ChannelPartner_Controller.TeamsWrapper result = ChannelPartner_Controller.getTeamMembers('TestTeamMemberId');
        Test.stopTest();
    }
    
    @isTest
    static void testGetRelatedLeads() {
        Account channelPartner = new Account(
            Name = 'Test Channel Partner', 
            Login_Hash_Code__c = 'TestChannelPartnerId'
        );
        insert channelPartner;
        
        Company__c cmp = new Company__c();
            cmp.Name = 'test';
            insert cmp;
        
        Project__c prj = new Project__c();
        prj.Name = 'test';
        prj.Company__c = cmp.Id;
        insert prj;

        Lead lead1 = new Lead(
            LastName = 'Doe', 
            Phone = '1234567890', 
            Email = 'john.doe@example.com', 
            Channel_Partner__c = channelPartner.Id, 
            Status = 'Open - Not Contacted',
             Company = 'Test Company',
            Project__c = prj.Id,
            IsConverted = false
        );
        Lead lead2 = new Lead(
            LastName = 'Smith', 
            Phone = '0987654321', 
            Email = 'jane.smith@example.com', 
            Channel_Partner__c = channelPartner.Id, 
            Status = 'Open - Not Contacted',
             Company = 'Test Company',
             Project__c = prj.Id,
            IsConverted = false
        );
        insert new List<Lead>{lead1, lead2};

        Test.startTest();
        List<Lead> result = ChannelPartner_Controller.getRelatedLeads(channelPartner.Id);
        Test.stopTest();
    }
    
    @isTest
    static void testGetBrokerageDetails() {
        Brokerage_Calculator__c broker = new Brokerage_Calculator__c(
            Commission_Rate__c = '10.0',  
            GST__c = 18.0,              
            TDS__c = 2.0 ,
            Name = 'test'
        );
        insert broker;

        Test.startTest();
        Brokerage_Calculator__c result = ChannelPartner_Controller.getBrokerageDetails();
        Test.stopTest();
    }
    
   @isTest
    static void testCreateChannelPartnerForChannelPartnerTeamPage() {
        Account channelPartner = new Account(
            Name = 'Test Channel Partner', 
            Login_Hash_Code__c = 'TestChannelPartnerId'
        );
        insert channelPartner;

        Account teamMember = new Account(
            Name = 'Test Team Member', 
            Phone = '1234567890',
            Email__c = 'team@example.com'
        );

        Test.startTest();
        String result = ChannelPartner_Controller.CreateChannelPartnerForChannelPartnerTeamPage(teamMember, 'TestChannelPartnerId');
        String resultNotFound = ChannelPartner_Controller.CreateChannelPartnerForChannelPartnerTeamPage(teamMember, 'InvalidChannelPartnerId');
        Test.stopTest();
    }
    
    @isTest
    static void testGetUserDetails() {
        Account acc = new Account(
            Name = 'Test User', 
            Email__c = 'testuser@example.com', 
            Phone = '1234567890', 
            Department__c = 'Sales', 
            Login_Hash_Code__c = 'TestHashCode'
        );
        insert acc;

        Test.startTest();
        Account result = ChannelPartner_Controller.getUserDetails('TestHashCode');
        Account resultNotFound = ChannelPartner_Controller.getUserDetails('InvalidHashCode');
        Test.stopTest();
    }
    
    @isTest
    static void testFetchCases() {
        Account acc = new Account(
            Name = 'Test Account', 
            Login_Hash_Code__c = 'TestHashCode'
        );
        insert acc;
        Account ac = new Account(
            Name = 'Test Account', 
            Login_Hash_Code__c = 'InvalidHashCode'
        );
        insert ac;

        Case case1 = new Case(
            Subject = 'Test Case 1',
            SuppliedEmail = 'test1@example.com',
            SuppliedPhone = '1234567890',
            Type = 'Inquiry',
            Description = 'Test Case Description 1',
            AccountId = acc.Id
        );

        Case case2 = new Case(
            Subject = 'Test Case 2',
            SuppliedEmail = 'test2@example.com',
            SuppliedPhone = '0987654321',
            Type = 'Support',
            Description = 'Test Case Description 2',
            AccountId = ac.Id
        );

        insert new List<Case>{case1, case2};

        Test.startTest();
        List<Case> result = ChannelPartner_Controller.fetchCases('TestHashCode');
       	ChannelPartner_Controller.fetchCases('InvalidHashCode');
        Test.stopTest();
    }
    
    @isTest
    static void testCreateCase() {
        // Retrieve the RecordTypeId for the Channel Partner Record Type
        String channelPartnerRecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'Channel_Partner' LIMIT 1].Id;

        Account acc = new Account(
            Name = 'Test Channel Partner', 
            Login_Hash_Code__c = 'TestChannelPartnerId',
            RecordTypeId = channelPartnerRecordTypeId
        );
        insert acc;

        Case cs = new Case(
            Subject = 'Test Case Subject',
            SuppliedEmail = 'test@example.com',
            SuppliedPhone = '1234567890',
            Type = 'Inquiry',
            Description = 'Test Case Description'
        );

        Test.startTest();
        ChannelPartner_Controller.createCase(cs, 'TestChannelPartnerId');
        ChannelPartner_Controller.createCase(cs, 'InvalidChannelPartnerId');
        ChannelPartner_Controller.createCase(null, 'TestChannelPartnerId');
        ChannelPartner_Controller.createCase(cs, null);
        Test.stopTest();
    }
    
    @isTest
    static void testDoUploadProfilePic() {
        Account acc = new Account(
            Name = 'Test Channel Partner',
            Login_Hash_Code__c = 'TestChannelPartnerId'
        );
        insert acc;

        String attachmentBody = EncodingUtil.base64Encode(Blob.valueOf('Test Profile Pic Data'));
        String attachmentName = 'TestProfilePic';
        String fileExtension = 'jpg';
        String hashcode = 'TestChannelPartnerId';

        Test.startTest();
        String result = ChannelPartner_Controller.doUploadProfilePic(hashcode, attachmentBody, attachmentName, fileExtension);
        Test.stopTest();

        //String resultInvalidHashcode = ChannelPartner_Controller.doUploadProfilePic('InvalidHashCode', attachmentBody, attachmentName, fileExtension);
        String resultNullAttachmentBody = ChannelPartner_Controller.doUploadProfilePic(hashcode, null, attachmentName, fileExtension);
        String resultNullParams = ChannelPartner_Controller.doUploadProfilePic(null, null, null, null);
    }
    
    @isTest
    static void testDoUploadTeamMemberProfilePic() {
        Account acc = new Account(
            Name = 'Test Channel Partner',
            Login_Hash_Code__c = 'TestChannelPartnerId'
        );
        insert acc;

        String attachmentBody = EncodingUtil.base64Encode(Blob.valueOf('Test Profile Pic Data'));
        String attachmentName = 'TestProfilePic';
        String fileExtension = 'jpg';
        String accId = acc.Id;

        Test.startTest();
        String result = ChannelPartner_Controller.doUploadTeamMemberProfilePic(accId, attachmentBody, attachmentName, fileExtension);
        Test.stopTest();

        String resultNullAttachmentBody = ChannelPartner_Controller.doUploadTeamMemberProfilePic(accId, null, attachmentName, fileExtension);
       
    }
    
    @isTest
    static void testGetAllProjectsWithImages() {
        Company__c cmp = new Company__c();
        cmp.Name = 'test';
        insert cmp;
        Project__c project = new Project__c(
            Name = 'Test Project',
            Project_Address__c = '123 Test St',
            Project_Description__c = 'Test Description',
            Project_Type__c = 'Residential',
            Project_Status__c = 'Active',
            Area__c = '1000 sqft',
            Booking_Amount__c = 50000,
            Total_Amount__c = 500000,
            Unit_Type__c = '2 BHK',
            Company__c = cmp.Id
        );
        insert project;
        
        Sub_Document__c subDocument = new Sub_Document__c(
            Name = 'a0V_Test_SubDoc',
            Project__c = project.Id
        );
        insert subDocument;

        Test.startTest();
        List<Project__c> result = ChannelPartner_Controller.getAllProjectsWithImages();
        Test.stopTest();
    }

    @isTest
    static void testNoSubDocuments() {
        
        Company__c cmp = new Company__c();
        cmp.Name = 'test';
        insert cmp;
        
        Project__c project = new Project__c(
            Name = 'Test Project without SubDocuments',
            Project_Address__c = '456 Test St',
            Project_Description__c = 'Test Description',
            Project_Type__c = 'Commercial',
            Project_Status__c = 'Inactive',
            Area__c = '2000 sqft',
            Booking_Amount__c = 70000,
            Total_Amount__c = 700000,
            Unit_Type__c = '1 BHK',
            Company__c = cmp.Id
        );
        insert project;

        Test.startTest();
        List<Project__c> result = ChannelPartner_Controller.getAllProjectsWithImages();
        Test.stopTest();
    }
    
     @isTest
    static void testUploadPdfToEvent() {
        Event__c event = new Event__c(
            Event_Name__c = 'Test Event',
            Event_Date_Time__c = System.Now()
        );
        insert event;
        
        String base64Data = EncodingUtil.base64Encode(Blob.valueOf('Sample PDF content'));
        String fileName = 'TestFile.pdf';
        
        Test.startTest();
        ChannelPartner_Controller.uploadPdfToEvent(event.Id, fileName, base64Data);
        Test.stopTest();
        
        Event__c updatedEvent = [SELECT Id, File_Id__c FROM Event__c WHERE Id = :event.Id LIMIT 1];
        Attachment attachment = [SELECT Id, ParentId, Name FROM Attachment WHERE ParentId = :event.Id LIMIT 1];
    }

    @isTest
    static void testEventNotFound() {
        String base64Data = EncodingUtil.base64Encode(Blob.valueOf('Sample PDF content'));
        String fileName = 'TestFile.pdf';
        
        Test.startTest();
        try {
            String invalidEventId = '001000000000001';
            ChannelPartner_Controller.uploadPdfToEvent(invalidEventId, fileName, base64Data);
        } catch (AuraHandledException e) {
        }
        Test.stopTest();
    }
    
    @isTest
    static void testGetEventDetails() {
        Event__c event = new Event__c(
            Event_Name__c = 'Test Event',
            Event_Date_Time__c = System.Now()
        );
        insert event;
        
        Test.startTest();
        Event__c resultEvent = ChannelPartner_Controller.getEventDetails(event.Id);
        Test.stopTest();
    }
    
      @isTest
    static void testUploadImageToEvent() {
        Event__c event = new Event__c(
            Event_Name__c = 'Test Event',
            Event_Date_Time__c = System.Now()
        );
        insert event;
        
        String base64Data = EncodingUtil.base64Encode(Blob.valueOf('Sample Image content'));
        String fileName = 'TestImage.jpg';
        
        Test.startTest();
        ChannelPartner_Controller.uploadImageToEvent(event.Id, fileName, base64Data);
        Test.stopTest();
        
        Event__c updatedEvent = [SELECT Id, Image_Id__c FROM Event__c WHERE Id = :event.Id LIMIT 1];
        Attachment attachment = [SELECT Id, ParentId, Name FROM Attachment WHERE ParentId = :event.Id LIMIT 1];
    }
    
    @isTest
    static void testGetEventDetailsForSite() {
        Event__c event1 = new Event__c(
            Event_Name__c = 'Test Event 1',
            Event_Date_Time__c = System.now(),
            Event_Venue__c = 'Test Venue 1'
        );
        insert event1;
        
        Event__c event2 = new Event__c(
            Event_Name__c = 'Test Event 2',
            Event_Date_Time__c = System.now().addDays(1),
            Event_Venue__c = 'Test Venue 2'
        );
        insert event2;

        ContentVersion contentVersion1 = new ContentVersion(
            Title = 'Test Document 1',
            PathOnClient = 'TestDocument1.pdf',
            VersionData = Blob.valueOf('Test file content')
        );
        insert contentVersion1;

        List<ContentDocument> contentDocuments1 = [SELECT Id FROM ContentDocument WHERE Id = :contentVersion1.ContentDocumentId LIMIT 1];
        
        if (!contentDocuments1.isEmpty()) {
            ContentDocumentLink cdl1 = new ContentDocumentLink(
                LinkedEntityId = event1.Id,
                ContentDocumentId = contentDocuments1[0].Id,
                ShareType = 'V'
            );
            insert cdl1;
        }
        
        ContentVersion contentVersion2 = new ContentVersion(
            Title = 'Test Document 2',
            PathOnClient = 'TestDocument2.pdf',
            VersionData = Blob.valueOf('Test file content')
        );
        insert contentVersion2;
        
        List<ContentDocument> contentDocuments2 = [SELECT Id FROM ContentDocument WHERE Id = :contentVersion2.ContentDocumentId LIMIT 1];
        
        if (!contentDocuments2.isEmpty()) {
            ContentDocumentLink cdl2 = new ContentDocumentLink(
                LinkedEntityId = event2.Id,
                ContentDocumentId = contentDocuments2[0].Id,
                ShareType = 'V'
            );
            insert cdl2;
        }
        
        Test.startTest();
        List<Event__c> eventList = ChannelPartner_Controller.getEventDetailsForSite();
        Test.stopTest();
    }

    @isTest
    static void testNoEvents() {
        Test.startTest();
        List<Event__c> eventList = ChannelPartner_Controller.getEventDetailsForSite();
        Test.stopTest();
    }
    
    @isTest
    static void testUpdateProfile() {
        Account acc = new Account(
            Name = 'Test Account',
            Phone = '1234567890',
            Email__c = 'test@example.com'
        );
        insert acc;

        acc.Phone = '0987654321';
        acc.Email__c = 'updated@example.com';

        Test.startTest();
        Account updatedAccount = ChannelPartner_Controller.updateProfile(acc);
        Test.stopTest();

        Account result = [SELECT Id, Phone, Email__c FROM Account WHERE Id = :acc.Id LIMIT 1];

        System.assertEquals('0987654321', result.Phone);
        System.assertEquals('updated@example.com', result.Email__c);
    }

    @isTest
    static void testUpdateProfileWithError() {
        Account acc = new Account(Name = 'Invalid Account');
        
        Test.startTest();
        Account updatedAccount = ChannelPartner_Controller.updateProfile(acc);
        Test.stopTest();
        
        System.assert(updatedAccount == null);
    }
    
     @isTest
    static void testGetAllMarketingRecords() {
        Marketing__c marketing1 = new Marketing__c(
            Name__c = 'Test Marketing 1',
            Marketing_URL__c = 'https://example1.com',
            Asset_Type__c = 'Files'
        );
        insert marketing1;

        Marketing__c marketing2 = new Marketing__c(
            Name__c = 'Test Marketing 2',
            Marketing_URL__c = 'https://example2.com',
            Asset_Type__c = 'Files'
        );
        insert marketing2;

        Test.startTest();
        List<Marketing__c> result = ChannelPartner_Controller.getAllMarketingRecords();
        Test.stopTest();

        System.assertNotEquals(0, result.size());
        System.assertEquals('Test Marketing 1', result[0].Name__c);
        System.assertEquals('Test Marketing 2', result[1].Name__c);
    }
    
    @isTest
    static void testLogoutUser() {
        Account acc = new Account(
            Name = 'Test User',
            Login_Hash_Code__c = 'TestLoginHashCode'
        );
        insert acc;

        Test.startTest();
        String result = ChannelPartner_Controller.logoutUser('TestLoginHashCode');
        Test.stopTest();

        Account updatedAcc = [SELECT Id, Login_Hash_Code__c FROM Account WHERE Id = :acc.Id LIMIT 1];
    }

    @isTest
    static void testLogoutUserWithInvalidHashCode() {
        Test.startTest();
        String result = ChannelPartner_Controller.logoutUser('InvalidLoginHashCode');
        Test.stopTest();
    }
    
     @isTest
    static void testFetchVisitOppRecordsAsTeamHead() {
        RecordType channelPartnerRecordType = [SELECT Id FROM RecordType WHERE DeveloperName = 'Channel_Partner' AND SObjectType = 'Account' LIMIT 1];
        
        if (channelPartnerRecordType == null) {
            System.debug('Record Type with DeveloperName "Channel_Partner" not found!');
            return;
        }
        
        Account channelPartnerAccount = new Account(Name = 'Channel Partner Account', RecordTypeId = channelPartnerRecordType.Id);
        insert channelPartnerAccount;

        Account teamMemberAccount = new Account(Name = 'Test Account', RecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' LIMIT 1].Id);
        insert teamMemberAccount;

        User teamMember = new User(
            Alias = 'testusr',
            LastName = 'test',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            Username = 'testuser1@domain.com',
            Email = 'testuser1@domain.com',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert teamMember;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = teamMemberAccount.Id,
            StageName = 'Prospecting',
            CloseDate = System.today(),
            Amount = 1000
        );
        insert opp;

        Visit__c visit = new Visit__c(
            Opportunity__c = opp.Id,
            Channel_Partner__c = channelPartnerAccount.Id,
            Status__c = 'SV Completed'
        );
        insert visit;

        Test.startTest();
        ChannelPartner_Controller.ChannelPartnerWrapper result = ChannelPartner_Controller.FetchVisitOppRecords(true, 'TestHashCode');
        Test.stopTest();
    }

    @isTest
    static void testFetchVisitOppRecordsNotTeamHead() {
        RecordType channelPartnerRecordType = [SELECT Id FROM RecordType WHERE DeveloperName = 'Channel_Partner' AND SObjectType = 'Account' LIMIT 1];
        
        if (channelPartnerRecordType == null) {
            System.debug('Record Type with DeveloperName "Channel_Partner" not found!');
            return;
        }
        
        Account channelPartnerAccount = new Account(Name = 'Channel Partner Account', RecordTypeId = channelPartnerRecordType.Id);
        insert channelPartnerAccount;

        Account teamMemberAccount = new Account(Name = 'Test Account', RecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' LIMIT 1].Id);
        insert teamMemberAccount;

        User teamMember = new User(
            Alias = 'testusr',
            LastName = 'Testing',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            Username = 'testuser2@domain.com',
            Email = 'testuser2@domain.com',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert teamMember;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = teamMemberAccount.Id,
            StageName = 'Prospecting',
            CloseDate = System.today(),
            Amount = 1000
        );
        insert opp;

        Visit__c visit = new Visit__c(
            Opportunity__c = opp.Id,
            Channel_Partner__c = channelPartnerAccount.Id,
            Status__c = 'SV Completed'
        );
        insert visit;

        Test.startTest();
        ChannelPartner_Controller.ChannelPartnerWrapper result = ChannelPartner_Controller.FetchVisitOppRecords(false, 'TestHashCode');
        Test.stopTest();
    }
    
    @isTest
    static void testGetInvoicesAsTeamHead() {
        RecordType channelPartnerRecordType = [SELECT Id FROM RecordType WHERE DeveloperName = 'Channel_Partner' AND SObjectType = 'Account' LIMIT 1];
        Account channelPartnerAccount = new Account(Name = 'Channel Partner Account', RecordTypeId = channelPartnerRecordType.Id);
        insert channelPartnerAccount;

        Account teamMemberAccount = new Account(Name = 'Test Account', RecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' LIMIT 1].Id);
        insert teamMemberAccount;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = teamMemberAccount.Id,
            StageName = 'Prospecting',
            CloseDate = System.today(),
            Amount = 1000
        );
        insert opp;
		
        // Demand_Letter__c dl = new Demand_Letter__c();
        // insert dl;
        
        Receipt__c allInvoice = new Receipt__c(
            Account__c = teamMemberAccount.Id,
            Opportunity__c = opp.Id,
            Approval_Status__c = 'Pending',
            Amount__c = 1000
        );
        insert allInvoice;

        Receipt__c approvedInvoice = new Receipt__c(
            Account__c = teamMemberAccount.Id,
            Opportunity__c = opp.Id,
            Approval_Status__c = 'Approved',
            Amount__c = 500
        );
        insert approvedInvoice;

        User teamMember = new User(
            Alias = 'testusr',
            LastName = 'test',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            Username = 'testuser3@domain.com',
            Email = 'testuser3@domain.com',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert teamMember;

        String loginHashCode = 'TestHashCode';

        teamMemberAccount.Login_Hash_Code__c = loginHashCode;
        update teamMemberAccount;

        Test.startTest();

        ChannelPartner_Controller.getInvoices(true, loginHashCode);

        Test.stopTest();
    }

    @isTest
    static void testGetInvoicesNotTeamHead() {
        RecordType channelPartnerRecordType = [SELECT Id FROM RecordType WHERE DeveloperName = 'Channel_Partner' AND SObjectType = 'Account' LIMIT 1];
        Account channelPartnerAccount = new Account(Name = 'Channel Partner Account', RecordTypeId = channelPartnerRecordType.Id);
        insert channelPartnerAccount;

        Account teamMemberAccount = new Account(Name = 'Test Account', RecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' LIMIT 1].Id);
        insert teamMemberAccount;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = teamMemberAccount.Id,
            StageName = 'Prospecting',
            CloseDate = System.today(),
            Amount = 1000
        );
        insert opp;
		// Demand_Letter__c dl = new Demand_Letter__c();
        // insert dl;
        
        Receipt__c allInvoice = new Receipt__c(
            Account__c = teamMemberAccount.Id,
            Opportunity__c = opp.Id,
            Approval_Status__c = 'Pending',
            Amount__c = 1000
        );
        insert allInvoice;

        Receipt__c approvedInvoice = new Receipt__c(
            Account__c = teamMemberAccount.Id,
            Opportunity__c = opp.Id,
            Approval_Status__c = 'Approved',
            Amount__c = 500
        );
        insert approvedInvoice;

        User teamMember = new User(
            Alias = 'testusr',
            LastName = 'Testing',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            Username = 'testuser4@domain.com',
            Email = 'testuser4@domain.com',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert teamMember;

        String loginHashCode = 'TestHashCode';

        teamMemberAccount.Login_Hash_Code__c = loginHashCode;
        update teamMemberAccount;

        Test.startTest();

		ChannelPartner_Controller.getInvoices(false, loginHashCode);

        Test.stopTest();
    }
    //chenchulakshmi -- 29/12/2025
    @isTest
    static void testSendOTP(){
        Test.startTest();
        ChannelPartner_Controller.sendOTP('8689602601');
        Test.stopTest();
    }
     @isTest
    static void testSendOTP2(){
        Test.startTest();
        ChannelPartner_Controller.sendOTP(null);
        Test.stopTest();
    }
    @isTest
    static void testCheckAccount(){
         Account acc = new Account(Name = 'Test Account',Phone='8689602601', RecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' LIMIT 1].Id);
         insert acc;
        Test.startTest();
        ChannelPartner_Controller.checkAccount('8689602601');
        Test.stopTest();
    }
     @isTest
    static void testCheckAccount2(){
        Test.startTest();
        ChannelPartner_Controller.checkAccount('8689602601');
        Test.stopTest();
    }
    @isTest
    static void testCheckAccount3(){
         Account acc = new Account(Name = 'Test Account',Phone='8689602601');
         insert acc;
        Test.startTest();
        ChannelPartner_Controller.checkAccount('8689602601');
        Test.stopTest();
    }
    @isTest
    static void testCheckAccount4(){
         Account acc = new Account(Name = 'Test Account',Phone='8689602601');
         insert acc;
        Test.startTest();
        ChannelPartner_Controller.checkAccount('');
        Test.stopTest();
    }
    @isTest
    static void testSubmitApproval(){
        Account acc = new Account(Name = 'Test Account',Phone='8689602601');
        insert acc;
        Test.startTest();
        ChannelPartner_Controller.submitApproval(acc.Id);
        Test.stopTest();
    }
	 @isTest
    static void testSubmitAcc(){
        Account acc = new Account(Name = 'Test Account',Phone='8689602601');
        insert acc;
        Test.startTest();
        ChannelPartner_Controller.submitAcc(acc);
        Test.stopTest();
    }
    @isTest
    static void testUploadDocuments(){
        Account acc = new Account(Name = 'Test Account');
    insert acc;
	Document__c doc = new Document__c(Account__c = acc.Id,Name = 'Agreement Copy',Document_Id__c = '1234');
        insert doc;
    // Test parameters
    String accId          = acc.Id;
    String fileName       = 'TestDocument.pdf';
    String fileData       = EncodingUtil.base64Encode(Blob.valueOf('Sample file content')); // Base64
    String totalFileSize  = '102400'; // in bytes: 100KB
    String documentName   = 'Agreement Copy';
    String fileType       = 'pdf';
        
    Test.setMock(HttpCalloutMock.class, new InlineMock());

    Test.startTest();
    ChannelPartner_Controller.wrapperForResponse response =
        ChannelPartner_Controller.uploadDocuments(
            accId,
            fileName,
            fileData,
            totalFileSize,
            documentName,
            fileType
        );
    Test.stopTest();
    }
    @isTest
    static void testGetFieldDependencies(){
        Test.startTest();
        ChannelPartner_Controller.getFieldDependencies('Lead','LeadSource','Lead_Sub_Source__c');
        Test.stopTest();
    }
        
private class InlineMock implements HttpCalloutMock {
    public HttpResponse respond(HttpRequest req) {
        HttpResponse res = new HttpResponse();

        if(req.getEndpoint().contains('oauth2') || req.getEndpoint().contains('token')){
            res.setStatusCode(200);
            res.setBody('{"access_token": "FAKE_TOKEN_123"}');
        }
        
        else if(req.getMethod() == 'POST'){
            res.setStatusCode(200);
            res.setHeader('Location', 'https://google-upload-session-url/mock');
            res.setBody('{"session":"created"}');
        }
        
        else if(req.getMethod() == 'PUT'){
            res.setStatusCode(200);
            res.setBody('{"id":"FAKE_FILE_ID_123"}');
        }

        return res;
    }
}
}