@isTest
public class ReceiptReversalControllerTest {
    
    @testSetup
    static void setupTestData() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        Company__c company = new Company__c(Name = 'Test Company');
        insert company;
        
        Project__c proj = new Project__c(
            Name = 'Test Project',
            Company__c = company.Id
        );
        insert proj;
        
        Tower__c tower = new Tower__c(
            Name = 'Test Tower',
            Project__c = proj.Id,
            Tower_Code__c = 'TT1'
        );
        insert tower;
        
        Floor__c floor = new Floor__c(
            Blocks__c = tower.Id
        );
        insert floor;
        
        Unit__c unit = new Unit__c(
            Floor__c = floor.Id,
            Unit_Name__c = 'Test Unit'
        );
        insert unit;

        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            Unit__c = unit.Id,
            AccountId = testAccount.Id,
            StageName = 'Closed Won',
            CloseDate = Date.today()
        );
        insert testOpportunity;
        
        // Payment schedules required to cover reversal logic
        List<Payment_Schedule__c> psList = new List<Payment_Schedule__c>{
            new Payment_Schedule__c(
                Opportunity__c = testOpportunity.Id,
                Name = 'PS-1',
                Installment_Sequence__c = 1,
                Total_Received_Amount__c = 50
            ),
            new Payment_Schedule__c(
                Opportunity__c = testOpportunity.Id,
                Name = 'PS-2',
                Installment_Sequence__c = 2,
                Total_Received_Amount__c = 100
            )
        };
        insert psList;
        
        // Approved cheque tax invoice receipt required for getRelReceipts + reversal amount logic
        Receipt__c receipt1 = new Receipt__c(
            Receipt_Date__c = Date.today(),
            Amount__c = 100.00,
            TDS_Amount__c = 20.00,
            Bank__c = 'Test Bank',
            Cheque_Number__c = '123456',
            Cheque_Date__c = Date.today(),
            Opportunity__c = testOpportunity.Id,
            Mode_Of_Payment__c = 'Cheque',
            Type__c = 'Tax Invoice',
            Approval_Status__c = 'Approved',
            Status__c = 'Represent'
        );
        insert receipt1;
        
        // Optional tax invoice record so delete branch is also covered
        Tax_Invoice__c ti = new Tax_Invoice__c(
            Receipt__c = receipt1.Id, Payment_Schedule__c = psList[0].Id
        );
        insert ti;
    }
    
    @isTest
    static void testGetRelReceipts() {
        Unit__c unit = [SELECT Id FROM Unit__c LIMIT 1];
        
        Test.startTest();
        ReceiptReversalController.receiptWrapper result = ReceiptReversalController.getRelReceipts(unit.Id);
        Test.stopTest();
    }
    
    @isTest
    static void testSaveReceiptChanges_SameCheque_CoversPaymentScheduleReversal() {
        Date bouncedDate = Date.today();
        String bouncedReason = 'Insufficient Funds';
        
        List<Receipt__c> testReceipts = [SELECT Id FROM Receipt__c];
        
        Test.startTest();
        String resultSame = ReceiptReversalController.saveReceiptChanges(
            testReceipts,
            'Same Cheque',
            bouncedDate,
            bouncedReason
        );
        Test.stopTest();
    }
    
    @isTest
    static void testSaveReceiptChanges_NewCheque_CoversPaymentScheduleReversal() {
        // Reset data by using fresh setup context values in a separate test
        Receipt__c testReceipt = [SELECT Id FROM Receipt__c LIMIT 1];
        
        // Refill payment schedules so this test is independent in expected values
        List<Payment_Schedule__c> psList = [SELECT Id, Total_Received_Amount__c FROM Payment_Schedule__c];
        for (Payment_Schedule__c ps : psList) {
            if (ps.Total_Received_Amount__c == 0) {
                ps.Total_Received_Amount__c = 100;
            } else if (ps.Total_Received_Amount__c == 30) {
                ps.Total_Received_Amount__c = 50;
            }
        }
        update psList;
        
        Test.startTest();
        String resultNew = ReceiptReversalController.saveReceiptChanges(
            new List<Receipt__c>{ new Receipt__c(Id = testReceipt.Id) },
            'New Cheque',
            Date.today(),
            'Insufficient Funds'
        );
        Test.stopTest();
        
    }
}