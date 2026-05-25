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
        if ([SELECT COUNT() FROM Receipt__c WHERE Opportunity__c = :opp.Id] == 0) {
            insert new Receipt__c(Opportunity__c = opp.Id);
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
        Receipt__c r = new Receipt__c(Opportunity__c = o.Id);
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
        Test.stopTest();
        
        System.assertEquals(null, outNull, 'Should return null when WhatId is not an Opportunity or no receipts.');
    }
    
    
    
}