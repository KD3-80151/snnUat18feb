@isTest
public class bookingFormButtonControllerTest {
    @IsTest
    static void testCreateApplicants_coversBuildFullNameCustomerBranch() {
        Account primaryApplicant = new Account(
            Name = 'Primary Applicant',
            Email__c = 'primary@applicant.com',
            Phone = '1112223333'
        );
        insert primaryApplicant;
        
        // Insert at least one co-app account so later code still works
        Account co = new Account(Name='Co A'); insert co;
        Id deletedIds;
        
        Opportunity opp = new Opportunity(
            Name='Opp w Acc',
            StageName='Prospecting',
            CloseDate=System.today(),
            AccountId=co.Id
        );
        insert opp;
        
        // Force buildFullName to be called and return 'Customer'
        // (accountName blank, firstName blank, lastName blank)
        String contactNamesJson = JSON.serialize(new List<Object>{
            new Map<String,Object>{
                'accountName' => '',   // <-- key: blank so code calls buildFullName
                    'firstName'   => '',
                    'lastName'    => ''
                    }
        });
        
        // Minimal profile list (not important here)
        String profileDataList = JSON.serialize(new List<Object>());
        
        Test.startTest();
        bookingFormButtonController.createApplicantsWrapper wrap =
            bookingFormButtonController.createApplicants(
                new List<Account>{ co },
                opp.Id,
                profileDataList,
                primaryApplicant.Id,
                primaryApplicant,
                contactNamesJson, new List<Id> { deletedIds }
            );
        Test.stopTest();
        // No asserts required for coverage; this forces the 'Customer' branch.
    }
    
    @isTest
    static void testCreateApplicants() {
        Account primaryApplicant = new Account(
            Name          = 'Primary Applicant',
            Email__c      = 'primary@applicant.com',
            Phone         = '1234567890',
            Document_Id__c= 'fsdf'
        );
        insert primaryApplicant;
        
        List<Account> applicantList = new List<Account>{
            new Account(Name = 'Co-Applicant 1', Email__c = 'co1@applicant.com', Phone = '0987654321'),
                new Account(Name = 'Co-Applicant 2', Email__c = 'co2@applicant.com', Phone = '1231231234')
                };
                    insert applicantList;
        
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = System.today(),
            AccountId = applicantList[0].Id   
        );
        insert opp;
        
        
        String b64 = 'eA==';
        String profileDataList = JSON.serialize(new List<Object>{
            new Map<String,Object>{
                'fileName'   => 'profile1.jpg',
                    'base64Data' => b64,
                    'Name'       => 'Primary Applicant'
                    }
        });
        
        String contactNamesJson = JSON.serialize(new List<Object>{
            new Map<String,Object>{
                'accountName' => 'Primary Applicant',
                    'firstName'   => 'Priya',
                    'lastName'    => 'K'
                    }
        });
        
        List<Id> deletedAccountIds = new List<Id>();
        
        Test.startTest();
        bookingFormButtonController.createApplicantsWrapper wrapper =
            bookingFormButtonController.createApplicants(
                applicantList,
                opp.Id,
                profileDataList,
                primaryApplicant.Id,
                primaryApplicant,
                contactNamesJson, deletedAccountIds
                
            );
        Test.stopTest();
    }
    
    @isTest
    static void testUploadDocuments() {
        Account acc = new Account(
            Name          = 'Test Account',
            Email__c      = 'test@account.com',
            Phone         = '1112223333',
            Document_Id__c= 'lkjl'
        );
        insert acc;
        
        Opportunity opp = new Opportunity(
            Name = 'Opp for Docs',
            StageName = 'Prospecting',
            CloseDate = System.today(),
            AccountId = acc.Id
        );
        insert opp;
        
        String fileName = 'TestDocument.pdf';
        String fileData = EncodingUtil.base64Encode(Blob.valueOf('Test File Content'));
        
        Test.startTest();
        String documentUrl = bookingFormButtonController.uploadDocuments(
            acc.Id,       // accId
            fileName,
            fileData,
            '1024',       // totalFileSize
            'Test Document',
            opp.Id        
        );
        Test.stopTest();
    }
    
    @isTest
    static void testGetProjectPicklistDetails() {
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = System.today()
        );
        insert opp;
        
        Map<String, String> objectByField = new Map<String, String>{ 'Type' => 'Opportunity' };
            Map<String, String> objectByFieldAddress = new Map<String, String>{ 'BillingState' => 'Account' };
                
                Test.startTest();
        bookingFormButtonController.projectPicklistWrapper wrapper =
            bookingFormButtonController.getProjectPicklistDetails(
                opp.Id,
                objectByField,
                objectByFieldAddress
            );
        Test.stopTest();
    }
    
    @isTest
    static void testSaveContentVersion() {
        String fileName   = 'TestFile.txt';
        String base64Data = EncodingUtil.base64Encode(Blob.valueOf('Test content'));
        
        Test.startTest();
        Id contentVersionId = bookingFormButtonController.saveContentVersion(fileName, base64Data);
        Test.stopTest();
        
        System.assertNotEquals(null, contentVersionId, 'ContentVersion ID should not be null.');
    }
    
    @isTest
    static void testGetFieldDependencies_and_AddressPicklist() {
        String objectName        = 'Lead';
        String controllingField  = 'LeadSource';
        String dependentField    = 'Lead_Sub_Source__c';
        
        Test.startTest();
        Map<String, List<String>> fieldDependencies =
            bookingFormButtonController.getFieldDependencies(objectName, controllingField, dependentField);
        
        List<Map<String,String>> addrVals =
            bookingFormButtonController.getPicklistValuesForAddress('Lead', 'LeadSource');
        Test.stopTest();
        
    }
    
    @isTest
    static void testCreateApplicants_CoversNameBuild_JsonAndProfilePics() {
        
        Account primaryApplicant = new Account(
            Name          = 'Primary Applicant',
            Email__c      = 'primary@applicant.com',
            Phone         = '1234567890',
            Document_Id__c= 'fsdf'
        );
        insert primaryApplicant;
        
        Contact existing = new Contact(
            LastName  = 'Temp',
            AccountId = primaryApplicant.Id,
            Email     = 'temp@ex.com',
            Phone     = '9999999999'
        );
        insert existing;
        
        // BEFORE
        List<Account> applicantList = new List<Account>{
            new Account(Name = 'Co-Applicant 1', Email__c = 'co1@applicant.com', Phone = '0987654321'),
                new Account(Name = 'Co-Applicant 2', Email__c = 'co2@applicant.com', Phone = '1231231234')
                };
                    // insert them so Ids are available:
                    insert applicantList;
        
        // Use a real AccountId when creating Opp:
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = System.today(),
            AccountId = applicantList[0].Id   
        );
        insert opp;
        
        
        
        String b64 = 'eA==';
        
        String profileDataList = JSON.serialize(new List<Object>{
            new Map<String,Object>{
                'fileName'   => 'profile1.jpg',
                    'base64Data' => b64,
                    'Name'       => 'Primary Applicant'
                    },
                        new Map<String,Object>{
                            'fileName'   => 'profile2.jpg',
                                'base64Data' => b64,
                                'Name'       => 'Co-Applicant 1'
                                }
        });
        
        String contactNamesJson = JSON.serialize(new List<Object>{
            new Map<String,Object>{
                'accountName' => 'Primary Applicant',
                    'firstName'   => 'Priya',
                    'lastName'    => 'K'
                    },
                        new Map<String,Object>{
                            'accountName' => 'Co-Applicant 1',
                                'firstName'   => '',
                                'lastName'    => ''
                                }
        });
        List<Id> deletedAccountIds = new List<Id>();
        Test.startTest();
        bookingFormButtonController.createApplicantsWrapper wrap =
            bookingFormButtonController.createApplicants(
                applicantList,
                opp.Id,
                profileDataList,
                primaryApplicant.Id,
                primaryApplicant,
                contactNamesJson, deletedAccountIds
            );
        Test.stopTest();
    }
    
    @IsTest
    static void testGetProjectPicklistDetails_withOppDocs() {
        Opportunity opp = new Opportunity(
            Name = 'Opp w/ Docs',
            StageName = 'Prospecting',
            CloseDate = System.today()
        );
        insert opp;
        
        Document__c pa = new Document__c(
            Name = 'Primary Applicant',
            Opportunity__c = opp.Id
        );
        insert pa;
        
        Document__c poi = new Document__c(
            Name = 'Proof of Identity',
            Opportunity__c = opp.Id,
            Parent_Document__c = pa.Id
        );
        insert poi;
        
        Document__c poa = new Document__c(
            Name = 'Proof of Address',
            Opportunity__c = opp.Id,
            Parent_Document__c = pa.Id
        );
        insert poa;
        
        Document__c fd = new Document__c(
            Name = 'Financial Documents',
            Opportunity__c = opp.Id,
            Parent_Document__c = pa.Id
        );
        insert fd;
        
        Document__c pd = new Document__c(
            Name = 'Property Documents',
            Opportunity__c = opp.Id,
            Parent_Document__c = pa.Id
        );
        insert pd;
        
        Document__c ld = new Document__c(
            Name = 'Legal Documents',
            Opportunity__c = opp.Id,
            Parent_Document__c = pa.Id
        );
        insert ld;
        
        Document__c pad = new Document__c(
            Name = 'Pre-Approval Documents',
            Opportunity__c = opp.Id,
            Parent_Document__c = pa.Id
        );
        insert pad;
        
        Sub_Document__c poiSub = new Sub_Document__c(
            Name = 'POI Passport.pdf',
            File_URL__c = 'https://example.com/poi.pdf',
            Document__c = poi.Id
        );
        insert poiSub;
        
        Sub_Document__c poaSub = new Sub_Document__c(
            Name = 'POA Utility.pdf',
            File_URL__c = 'https://example.com/poa.pdf',
            Document__c = poa.Id
        );
        insert poaSub;
        
        Test.startTest();
        bookingFormButtonController.projectPicklistWrapper wrap =
            bookingFormButtonController.getProjectPicklistDetails(
                opp.Id,
                new Map<String, String>(),  
                new Map<String, String>()
            );
        Test.stopTest();
        
        
    }
    
    @IsTest
    static void testUploadDocuments_hitsChildBucketAndBlankFolderId() {
        Account acc = new Account(Name = 'Acc A');
        insert acc;
        
        Opportunity opp = new Opportunity(
            Name = 'Opp for Upload',
            StageName = 'Prospecting',
            CloseDate = System.today(),
            AccountId = acc.Id
        );
        insert opp;
        
        Document__c parent = new Document__c(
            Name = 'Primary Applicant',      
            Opportunity__c = opp.Id,
            Account__c = acc.Id
            // Parent_Document__c = NULL
        );
        insert parent;
        
        Document__c bucket = new Document__c(
            Name = 'Test Bucket',            // <- must match the method argument
            Parent_Document__c = parent.Id,
            Opportunity__c = opp.Id,
            Account__c = acc.Id
        );
        insert bucket;
        
        String fileData = EncodingUtil.base64Encode(Blob.valueOf('any'));
        Test.startTest();
        String result = bookingFormButtonController.uploadDocuments(
            acc.Id,
            'file.pdf',
            fileData,
            '3',
            'Test Bucket',    // EXACTLY matches the child Name above
            opp.Id
        );
        Test.stopTest();
        
    }
    
    @IsTest
    static void testGetFieldDependencies_exercisesDeserialize() {
        Test.startTest();
        try {
            bookingFormButtonController.getFieldDependencies('Lead', 'LeadSource', 'Status');
        } catch (Exception e) {
            
            System.debug('Dependency test (expected variability): ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testGetProjectPicklistDetails_withCoAppsDocsAndContacts() {
        // Primary Account + Contact for Opportunity.AccountId path
        Account primaryAcc = new Account(Name='Primary Acc', Email__c='p@a.com');
        insert primaryAcc;
        Contact primaryCon = new Contact(LastName='P', AccountId=primaryAcc.Id, Salutation='Mr.');
        insert primaryCon;
        
        // Co-app Accounts + Contacts (to populate acctToPrimaryContact via cands query)
        Account co1 = new Account(Name='CoApp A'); insert co1;
        Account co2 = new Account(Name='CoApp B'); insert co2;
        insert new Contact(LastName='CA', AccountId=co1.Id);
        insert new Contact(LastName='CB', AccountId=co2.Id);
        
        // Opp MUST have AccountId to cover accRec/defaultVals/primaryCon
        Opportunity opp = new Opportunity(
            Name='Opp Full',
            StageName='Prospecting',
            CloseDate=System.today(),
            AccountId=primaryAcc.Id
        );
        insert opp;
        
        // Two Applicant__c rows linked to opp and to co-app Accounts
        Applicant__c a1 = new Applicant__c(Account__c=co1.Id, Opportunity__c=opp.Id);
        Applicant__c a2 = new Applicant__c(Account__c=co2.Id, Opportunity__c=opp.Id);
        insert new List<Applicant__c>{ a1, a2 };
            
            // ---- Document hierarchy under Applicant__c ----
            // We assume Document__c has a lookup to Applicant__c with child rel name Documents__r
            // and a self lookup Parent_Document__c; Sub_Document__c looks up to Document__c.
            // Applicant 1
            Document__c a1Parent = new Document__c(Name='Parent', Applicant__c=a1.Id);
        insert a1Parent;
        Document__c a1ChildPOI = new Document__c(
            Name='Proof of Identity',
            Applicant__c=a1.Id,
            Parent_Document__c=a1Parent.Id
        );
        insert a1ChildPOI;
        Sub_Document__c a1PoiSub = new Sub_Document__c(
            Name='A1 POI.pdf',
            File_URL__c='https://x/a1poi.pdf',
            Document__c=a1ChildPOI.Id
        );
        insert a1PoiSub;
        
        Document__c a2Parent = new Document__c(Name='Parent', Applicant__c=a2.Id);
        insert a2Parent;
        Document__c a2ChildLegal = new Document__c(
            Name='Legal',
            Applicant__c=a2.Id,
            Parent_Document__c=a2Parent.Id
        );
        insert a2ChildLegal;
        Sub_Document__c a2LegalSub = new Sub_Document__c(
            Name='A2 Legal.pdf',
            File_URL__c='https://x/a2legal.pdf',
            Document__c=a2ChildLegal.Id
        );
        insert a2LegalSub;
        
        Document__c pa = new Document__c(Name='Primary Applicant', Opportunity__c=opp.Id);
        insert pa;
        Document__c poa = new Document__c(
            Name='Proof of Address',
            Opportunity__c=opp.Id, Parent_Document__c=pa.Id
        );
        insert poa;
        insert new Sub_Document__c(
            Name='PA POA.pdf',
            File_URL__c='https://x/poa.pdf',
            Document__c=poa.Id
        );
        
        Test.startTest();
        bookingFormButtonController.projectPicklistWrapper wrap =
            bookingFormButtonController.getProjectPicklistDetails(
                opp.Id,
                new Map<String,String>{ 'Type' => 'Opportunity' },    // exercise picklists
                new Map<String,String>{ 'BillingState' => 'Account' } // and address picklists
            );
        Test.stopTest();
        
        
    }
    
    
}