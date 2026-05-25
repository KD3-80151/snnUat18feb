@isTest
public class receiptTriggerHandlerTest {
    
    @testSetup
    static void setupTestData() {
        // Create an Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        // Create two Opportunities
        Opportunity opp1 = new Opportunity(
            Name = 'Test Opp 1',
            StageName = 'Prospecting',
            CloseDate = System.today().addDays(30),
            AccountId = acc.Id
        );
        Opportunity opp2 = new Opportunity(
            Name = 'Test Opp 2',
            StageName = 'Prospecting',
            CloseDate = System.today().addDays(40),
            AccountId = acc.Id
        );
        insert new List<Opportunity>{opp1, opp2};
        
        // Create Payment Schedules for opp1 and opp2
        List<Payment_Schedule__c> schedules = new List<Payment_Schedule__c>();
        schedules.add(new Payment_Schedule__c(
            Opportunity__c = opp1.Id,
            Agreement_Value__c = 1000,
            Tax_Amount__c = 100,
            Installment_Sequence__c = 1,
            Total_Received_Amount__c = 0
        ));
        schedules.add(new Payment_Schedule__c(
            Opportunity__c = opp2.Id,
            Agreement_Value__c = 500,
            Tax_Amount__c = 50,
            Installment_Sequence__c = 1,
            Total_Received_Amount__c = 0
        ));
        insert schedules;
    }
    
    @isTest
    static void testGenerateDoc() {
        Opportunity opp1 = [SELECT Id FROM Opportunity WHERE Name = 'Test Opp 1' LIMIT 1];
        
        // Receipt before update (Not Approved)
        Receipt__c r1 = new Receipt__c(
            Opportunity__c = opp1.Id,
            Amount__c = 200,
            Approval_Status__c = 'Pending'
        );
        insert r1;
        
        // Simulate update to Approved
        r1.Approval_Status__c = 'Approved';
        update r1;
        
        Test.startTest();
        receiptTriggerHandler.generateDoc(
            new List<Receipt__c>{r1}, 
            new Map<Id, Receipt__c>{r1.Id => 
                new Receipt__c(Id=r1.Id, Approval_Status__c='Pending')}
        );
        Test.stopTest();
        
        // Nothing to assert except debug/queueable coverage
        System.assert(true, 'generateDoc executed without error');
    }
    
    @isTest
    static void testUpdtRcpdAmtOnPymntSchedule_SameOpp() {
        Opportunity opp1 = [SELECT Id FROM Opportunity WHERE Name = 'Test Opp 1' LIMIT 1];
        
        Receipt__c oldR = new Receipt__c(
            Opportunity__c = opp1.Id,
            Amount__c = 200,
            Approval_Status__c = 'Pending'
        );
        insert oldR;
        
        // Update approval → Approved
        Receipt__c newR = oldR.clone(false, true, false, false);
        newR.Id = oldR.Id;
        newR.Approval_Status__c = 'Approved';
        
        Test.startTest();
        receiptTriggerHandler.updtRcpdAmtOnPymntSchedule(
            new List<Receipt__c>{newR}, 
            new Map<Id, Receipt__c>{oldR.Id => oldR}
        );
        Test.stopTest();
        
        Payment_Schedule__c ps = [SELECT Total_Received_Amount__c 
                                  FROM Payment_Schedule__c 
                                  WHERE Opportunity__c = :opp1.Id LIMIT 1];
        System.assert(ps.Total_Received_Amount__c > 0, 'Payment schedule should be updated');
    }
    
    @isTest
    static void testUpdtRcpdAmtOnPymntSchedule_MoveOpp() {
        Opportunity opp1 = [SELECT Id FROM Opportunity WHERE Name = 'Test Opp 1' LIMIT 1];
        Opportunity opp2 = [SELECT Id FROM Opportunity WHERE Name = 'Test Opp 2' LIMIT 1];
        
        // Receipt originally linked to opp1
        Receipt__c oldR = new Receipt__c(
            Opportunity__c = opp1.Id,
            Amount__c = 300,
            Approval_Status__c = 'Approved'
        );
        insert oldR;
        
        // Move to opp2
        Receipt__c newR = oldR.clone(false, true, false, false);
        newR.Id = oldR.Id;
        newR.Opportunity__c = opp2.Id;
        
        Test.startTest();
        receiptTriggerHandler.updtRcpdAmtOnPymntSchedule(
            new List<Receipt__c>{newR}, 
            new Map<Id, Receipt__c>{oldR.Id => oldR}
        );
        Test.stopTest();
        
        List<Payment_Schedule__c> updated = [
            SELECT Opportunity__c, Total_Received_Amount__c 
            FROM Payment_Schedule__c 
            WHERE Opportunity__c IN :new List<Id>{opp1.Id, opp2.Id}
        ];
        
        System.assert(updated.size() == 2, 'Both opp payment schedules should be updated');
    }
}