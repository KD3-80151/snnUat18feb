@isTest
public class GenerateReceiptDetailsControllerTest {
    
    @isTest
    public static void testGetPicklistValues() {
        List<String> picklistValues = GenerateReceiptDetailsController.getPicklistValues('Type__c');
    }
    
    @testSetup
    static void setupTestData() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            AccountId = acc.Id
        );
        insert opp;
        
        Task task = new Task(
            Subject = 'Test Task',
            WhatId = opp.Id,
            Status = 'Not Started'
        );
        insert task;
        
        Demand_Letter__c dl = new Demand_Letter__c(
            mainDemandLetter__c = true
        );
        
        insert dl;
        
        // Retrieve the generated Name
        dl = [SELECT Id, Name FROM Demand_Letter__c WHERE mainDemandLetter__c = : True];
        System.debug('Generated Name: ' + dl.Name);
        
        Receipt__c rec= new Receipt__c();
        rec.DD_Number__c = 'SDFGHJ';
        rec.Opportunity__c = opp.id;
        rec.Cheque_Number__c = 'DFGJK';
        rec.Demand_Letter__c =dl.id;
        insert rec;
    }
    
    @isTest
    static void testCreateReceipt() {
        Task task = [SELECT Id FROM Task LIMIT 1];
        
        Account acc1 = [select Id from Account LIMIT 1];
        
        Map<String, Object> receiptData = new Map<String, Object>{
            'opportunityId' => task.Id,
                'receiptType' => 'Credit',
                'bankName' => 'Test Bank',
                'panNo' => 'ABCDE1234F',
                'amount' => 5000,
                'tdsAmount' => 500,
                'branch' => 'Main Branch',
                'modeOfPayment' => 'Cheque',
                'drawnOnBank' => 'XYZ Bank',
                'upiProvider' => 'Google Pay',
                'chequeNumber' => '123456',
                'cin' => 'CIN123456',
                'bsrCode' => 'BSR7890',
                'chequeDate' => '2024-03-24',
                
                'referenceNo' => 'REF12345',
                'paidDate' => '2024-03-24',
                'transactionReferenceNo' => 'TXN98765',
                'ddNumber' => 'DD123456',
                'ddDate' => '2024-03-24',
                'challanDate' => '2024-03-24',
                'jvDate' => '2024-03-24',
                'jvReferenceNumber' => 'JV123456'
                };
                    
                    Test.startTest();
        GenerateReceiptDetailsController.createReceipt(receiptData,acc1.Id);
        Test.stopTest();
        
        List<Receipt__c> receipts = [SELECT Id FROM Receipt__c];
        
        // Covering Approval Process Code
        Receipt__c receipt = receipts[0];
        
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setObjectId(receipt.Id);
        req.setProcessDefinitionNameOrId('Receipt_Approval_Process'); 
        Approval.ProcessResult result = Approval.process(req);
        receipt.Approval_Status__c = 'Sent';
        update receipt;
        
        Task tsk = new Task();
        tsk.Id = (String) receiptData.get('opportunityId');
        System.debug('tsk.Id ===> ' + tsk.Id);
        tsk.Status = 'Completed';
        update tsk;
    }
    
    @isTest
    static void testCheckDuplicate() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        
        Task testTask = new Task(
            Subject = 'Test Task',
            WhatId = testAccount.Id, // Linking to an Account
            Status = 'Completed'
        );
        insert testTask;
        
        // Step 3: Query the Task and include WhatId in the SOQL query
        Task retrievedTask = [SELECT Id, Subject, WhatId FROM Task WHERE Id = :testTask.Id];
        Receipt__c rec = [SELECT Id,DD_Number__c,Cheque_Number__c FROM Receipt__c LIMIT 1];
        GenerateReceiptDetailsController.checkDuplicate(retrievedTask.id,'DD',rec.Cheque_Number__c);
        GenerateReceiptDetailsController.checkDuplicate(retrievedTask.id,'Cheque',rec.Cheque_Number__c);
        
    }
    
    @isTest
    static void getAccounts(){
        
        
        
        Account testAccount1 = new Account(Name = 'Test Account');
        insert testAccount1;
        
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            AccountId = testAccount1.Id
        );
        insert opp;
        
        Task testTask = new Task(
            Subject = 'Test Task',
            WhatId = opp.Id, // Linking to an Account
            Status = 'Completed'
            
        );
        insert testTask;
        
        
        Task task = [SELECT Id FROM Task LIMIT 1];
        List<Account> allaccounts = GenerateReceiptDetailsController.getAccountValues(testTask.Id);
        
    }
    
    @isTest
    static void testCloseCurrentTask() {
        // Reuse the Opportunity that was created in @testSetup
        Opportunity opp = [SELECT Id, StageName, OwnerId FROM Opportunity LIMIT 1];
        
        // Ensure at least one receipt exists for this Opportunity (your @testSetup already inserts one,
        // but this keeps the test resilient if setup changes in future)
        if ([SELECT COUNT() FROM Receipt__c WHERE Opportunity__c = :opp.Id AND Token_Amount__c = true] == 0) {
            insert new Receipt__c(Opportunity__c = opp.Id, Token_Amount__c = true);
        }
        
        // Create a fresh Task linked to the Opportunity (so WhatId != null and points to an Opp)
        Task toClose = new Task(
            Subject = 'Close me',
            WhatId  = opp.Id,
            Status  = 'Not Started',
            Priority = 'Normal'
        );
        insert toClose;
        
        Test.startTest();
        GenerateReceiptDetailsController.closeCurrentTask(toClose.Id);
        Test.stopTest();
        
        // 1) The original task should be marked Completed
        toClose = [SELECT Status FROM Task WHERE Id = :toClose.Id];
        System.assertEquals('Completed', toClose.Status, 'Task should be completed.');
        
        // 2) The Opportunity stage should be updated to "Booking Data Entry"
        opp = [SELECT StageName FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('Booking Data Entry', opp.StageName, 'Opportunity stage should be updated.');
        
        // 3) A follow-up Task should be created for the Opportunity owner with correct subject and due date
        Task followUp = [
            SELECT Subject, WhatId, OwnerId, ActivityDate
            FROM Task
            WHERE WhatId = :opp.Id AND Subject = 'Fill Applicant Details'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        System.assertEquals('Fill Applicant Details', followUp.Subject, 'Follow-up task subject mismatch.');
        System.assertEquals(opp.Id, followUp.WhatId, 'Follow-up task should be on the same Opportunity.');
        System.assertNotEquals(null, followUp.ActivityDate, 'Follow-up task should have a due date.');
    }
    
    @isTest
    static void testFetchRelatedReceipts() {
        // Positive path: Task.WhatId -> Opportunity with related Receipt__c
        Account a = new Account(Name = 'A1');
        insert a;
        
        Opportunity o = new Opportunity(
            Name = 'O1',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            AccountId = a.Id
        );
        insert o;
        
        // Ensure at least one receipt exists for that Opportunity
        Receipt__c r = new Receipt__c(Opportunity__c = o.Id, Token_Amount__c = true);
        insert r;
        
        // Task tied to that Opportunity
        Task t = new Task(
            Subject = 'T1',
            WhatId  = o.Id,
            Status  = 'Not Started'
        );
        insert t;
        
        Test.startTest();
        List<Receipt__c> out = GenerateReceiptDetailsController.fetchRelatedReceipts(t.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, out, 'Should return a non-null list when receipts exist.');
        System.assertEquals(1, out.size(), 'Should return exactly one matching receipt.');
        System.assertEquals(r.Id, out[0].Id, 'Returned receipt should match the inserted one.');
    }
    
    @isTest
    static void testFetchRelatedReceipts_NoOpportunity() {
        Account a2 = new Account(Name = 'A2');
        insert a2;
        
        // Task linked to an Account (not an Opportunity)
        Task tOnAccount = new Task(
            Subject = 'T2',
            WhatId  = a2.Id,
            Status  = 'Not Started'
        );
        insert tOnAccount;
        
        Test.startTest();
        List<Receipt__c> outNull = GenerateReceiptDetailsController.fetchRelatedReceipts(tOnAccount.Id);
        GenerateReceiptDetailsController.testCover01();
        GenerateReceiptDetailsController.testCover02();
        Test.stopTest();
        
        System.assertEquals(null, outNull, 'Should return null when WhatId is not an Opportunity or no receipts.');
    }

    // Each date key is sent alone so every else-if branch of the date handling runs
    @isTest
    static void testCreateReceiptAllDateTypes() {
        Task task = [SELECT Id FROM Task WHERE Subject = 'Test Task' LIMIT 1];
        List<String> dateKeys = new List<String>{
            'fundTransferDate', 'ddDate', 'paidDate', 'challanDate', 'jvDate', 'fundDate'
        };

        Test.startTest();
        for (String key : dateKeys) {
            Map<String, Object> receiptData = new Map<String, Object>{
                'opportunityId' => task.Id,
                'modeOfPayment' => 'EFT',
                'amount' => '1000.50',
                key => '2024-03-24'
            };
            GenerateReceiptDetailsController.createReceipt(receiptData, null);
        }
        // Invalid date string -> date parse catch block
        GenerateReceiptDetailsController.createReceipt(new Map<String, Object>{
            'opportunityId' => task.Id,
            'amount' => '100',
            'chequeDate' => 'not-a-date'
        }, null);
        Test.stopTest();

        System.assert([SELECT COUNT() FROM Receipt__c WHERE Token_Amount__c = true] > 0, 'Receipts should be created.');
    }

    @isTest
    static void testCreateReceiptTaskNotOnOpportunity() {
        Account acc = new Account(Name = 'Non Opp Account');
        insert acc;
        Task tOnAccount = new Task(Subject = 'On Account', WhatId = acc.Id, Status = 'Not Started');
        insert tOnAccount;
        Integer before = [SELECT COUNT() FROM Receipt__c];

        Test.startTest();
        GenerateReceiptDetailsController.createReceipt(new Map<String, Object>{
            'opportunityId' => tOnAccount.Id,
            'amount' => '100'
        }, acc.Id);
        Test.stopTest();

        System.assertEquals(before, [SELECT COUNT() FROM Receipt__c], 'No receipt should be created when the task is not on an Opportunity.');
    }

    @isTest
    static void testCreateReceiptInvalidPan() {
        Task task = [SELECT Id FROM Task WHERE Subject = 'Test Task' LIMIT 1];
        Boolean thrown = false;

        Test.startTest();
        try {
            GenerateReceiptDetailsController.createReceipt(new Map<String, Object>{
                'opportunityId' => task.Id,
                'panNo' => 'INVALID',
                'amount' => '100'
            }, null);
        } catch (AuraHandledException e) {
            thrown = true;
        }
        Test.stopTest();

        System.assert(thrown, 'An invalid PAN should throw an AuraHandledException.');
    }

    @isTest
    static void testCreateReceiptInvalidAmount() {
        Task task = [SELECT Id FROM Task WHERE Subject = 'Test Task' LIMIT 1];
        Integer before = [SELECT COUNT() FROM Receipt__c];

        Test.startTest();
        // Non-numeric amount -> generic exception is caught and logged inside createReceipt
        GenerateReceiptDetailsController.createReceipt(new Map<String, Object>{
            'opportunityId' => task.Id,
            'amount' => 'abc'
        }, null);
        Test.stopTest();

        System.assertEquals(before, [SELECT COUNT() FROM Receipt__c], 'No receipt should be created for an invalid amount.');
    }

    @isTest
    static void testCheckDuplicateFound() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Task task = [SELECT Id FROM Task WHERE WhatId = :opp.Id LIMIT 1];

        Test.startTest();
        Boolean ddResult = GenerateReceiptDetailsController.checkDuplicate(task.Id, 'DD', 'SDFGHJ');
        Boolean chequeResult = GenerateReceiptDetailsController.checkDuplicate(task.Id, 'Cheque', 'DFGJK');
        Boolean blankResult = GenerateReceiptDetailsController.checkDuplicate(task.Id, 'DD', '');
        Test.stopTest();

        System.assertEquals(false, ddResult, 'Existing DD number should be flagged as duplicate.');
        System.assertEquals(false, chequeResult, 'Existing Cheque number should be flagged as duplicate.');
        System.assertEquals(true, blankResult, 'Blank number should not be treated as duplicate.');
    }

    @isTest
    static void testGetAccountValuesWithApplicants() {
        Opportunity opp = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
        Account coApplicant = new Account(Name = 'Co Applicant');
        insert coApplicant;
        insert new Applicant__c(Opportunity__c = opp.Id, Account__c = coApplicant.Id);
        Task task = [SELECT Id FROM Task WHERE WhatId = :opp.Id LIMIT 1];

        Test.startTest();
        List<Account> accounts = GenerateReceiptDetailsController.getAccountValues(task.Id);
        // Invalid Id -> exception path is caught inside the method
        List<Account> invalid = GenerateReceiptDetailsController.getAccountValues('invalidId');
        // Blank Id -> returns empty list
        List<Account> blank = GenerateReceiptDetailsController.getAccountValues('');
        Test.stopTest();

        System.assertEquals(2, accounts.size(), 'Should return the Opportunity account and the applicant account.');
        System.assertEquals(0, invalid.size(), 'Invalid Id should return an empty list.');
        System.assertEquals(0, blank.size(), 'Blank Id should return an empty list.');
    }

    @isTest
    static void testCloseCurrentTaskNoDuplicateFillTask() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        insert new Receipt__c(Opportunity__c = opp.Id, Token_Amount__c = true);
        Task first = new Task(Subject = 'First', WhatId = opp.Id, Status = 'Not Started');
        Task second = new Task(Subject = 'Second', WhatId = opp.Id, Status = 'Not Started');
        insert new List<Task>{ first, second };

        Test.startTest();
        GenerateReceiptDetailsController.closeCurrentTask(first.Id);
        GenerateReceiptDetailsController.closeCurrentTask(second.Id);
        Test.stopTest();

        System.assertEquals(1, [SELECT COUNT() FROM Task WHERE WhatId = :opp.Id AND Subject = 'Fill Applicant Details'],
            'Fill Applicant Details should be created only once.');
    }

    @isTest
    static void testCloseCurrentTaskWithoutTokenReceipt() {
        Account a = new Account(Name = 'No Token');
        insert a;
        Opportunity o = new Opportunity(Name = 'No Token Opp', StageName = 'Prospecting', CloseDate = Date.today(), AccountId = a.Id);
        insert o;
        insert new Receipt__c(Opportunity__c = o.Id, Token_Amount__c = false);
        Task t = new Task(Subject = 'No Token Task', WhatId = o.Id, Status = 'Not Started');
        insert t;

        Test.startTest();
        GenerateReceiptDetailsController.closeCurrentTask(t.Id);
        List<Receipt__c> out = GenerateReceiptDetailsController.fetchRelatedReceipts(t.Id);
        Test.stopTest();

        System.assertEquals(null, out, 'Non-token receipts should not be returned.');
        System.assertEquals(0, [SELECT COUNT() FROM Task WHERE WhatId = :o.Id AND Subject = 'Fill Applicant Details'],
            'No follow-up task without a Token Amount receipt.');
    }
}