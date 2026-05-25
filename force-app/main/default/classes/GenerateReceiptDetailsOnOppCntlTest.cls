@isTest
public class GenerateReceiptDetailsOnOppCntlTest {
    
    @isTest
    public static void testGetPicklistValues() {
        List<String> picklistValues = GenerateReceiptDetailsOnOppController.getPicklistValues('Type__c');
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
        
        dl = [SELECT Id, Name FROM Demand_Letter__c WHERE mainDemandLetter__c = : True];
        System.debug('Generated Name: ' + dl.Name);
        
        Receipt__c rec= new Receipt__c();
        rec.DD_Number__c = 'SDFGHJ';
        rec.Opportunity__c = opp.Id; // Fix: Assign correct Opportunity Id
        rec.Cheque_Number__c = 'DFGJK';
        rec.Demand_Letter__c = dl.Id;
        insert rec;
    }
    
    @isTest
    static void testCreateReceipt() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1]; // Fix: Use Opportunity ID
        
         Account acc1 = [select Id from Account LIMIT 1];
        
        Map<String, Object> receiptData = new Map<String, Object>{
            'opportunityId' => opp.Id, // Fix: Assign correct Opportunity ID
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
        GenerateReceiptDetailsOnOppController.createReceipt(receiptData,acc1.Id);
        Test.stopTest();
        
        List<Receipt__c> receipts = [SELECT Id FROM Receipt__c];
        
        if (!receipts.isEmpty()) {
            Receipt__c receipt = receipts[0];
            System.debug('Submitting Receipt for Approval: ' + receipt.Id);
            
            Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
            req.setObjectId(receipt.Id);
            req.setProcessDefinitionNameOrId('Receipt_Approval_Process'); 
            Approval.ProcessResult result = Approval.process(req);
            
            //System.assert(result.isSuccess(), 'Approval Process Failed');
            
            receipt = [SELECT Id, Approval_Status__c FROM Receipt__c WHERE Id = :receipt.Id];
            //System.assertEquals('Sent', receipt.Approval_Status__c, 'Approval Status not updated');
        }
    }
    
    @isTest
    static void testCheckDuplicate() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Task testTask = new Task(
            Subject = 'Test Task',
            WhatId = opp.Id, // Correct reference to Opportunity
            Status = 'Completed'
        );
        insert testTask;
        
        Task retrievedTask = [SELECT Id, Subject, WhatId FROM Task WHERE Id = :testTask.Id];
        Receipt__c rec = [SELECT Id, DD_Number__c, Cheque_Number__c FROM Receipt__c LIMIT 1];
        
        GenerateReceiptDetailsOnOppController.checkDuplicate(retrievedTask.Id, 'DD', rec.Cheque_Number__c);
        GenerateReceiptDetailsOnOppController.checkDuplicate(retrievedTask.Id, 'Cheque', rec.Cheque_Number__c);
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
        List<Account> allaccounts = GenerateReceiptDetailsOnOppController.getAccountValues(testTask.Id);
        
    }
}