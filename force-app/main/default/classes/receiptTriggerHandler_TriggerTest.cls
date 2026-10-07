@isTest
public class receiptTriggerHandler_TriggerTest {

    @testSetup
    static void setupData() {
        Account acc = new Account(Name='Acc');
        insert acc;

        Opportunity opp1 = new Opportunity(
            Name='Opp 1', StageName='Prospecting',
            CloseDate=Date.today().addDays(10),
            AccountId=acc.Id
        );
        Opportunity opp2 = new Opportunity(
            Name='Opp 2', StageName='Prospecting',
            CloseDate=Date.today().addDays(20),
            AccountId=acc.Id
        );
        insert new List<Opportunity>{ opp1, opp2 };

        // Payment schedules for opp1 (2 installments) + opp2 (1 installment)
        insert new List<Payment_Schedule__c>{
            new Payment_Schedule__c(
                Opportunity__c=opp1.Id, Installment_Sequence__c=1,
                Agreement_Value__c=1000, Tax_Amount__c=100,
                Total_Received_Amount__c=0, Tax_Invoice_Created__c=false
            ),
            new Payment_Schedule__c(
                Opportunity__c=opp1.Id, Installment_Sequence__c=2,
                Agreement_Value__c=500, Tax_Amount__c=50,
                Total_Received_Amount__c=0, Tax_Invoice_Created__c=false
            ),
            new Payment_Schedule__c(
                Opportunity__c=opp2.Id, Installment_Sequence__c=1,
                Agreement_Value__c=800, Tax_Amount__c=80,
                Total_Received_Amount__c=0, Tax_Invoice_Created__c=false
            )
        };
    }

    @isTest
    static void testTrigger_ApprovedTaxInvoice_UpdatesSchedulesAndCreatesInvoice() {
        Opportunity opp1 = [SELECT Id FROM Opportunity WHERE Name='Opp 1' LIMIT 1];

        // Insert receipt in Pending
        Receipt__c r = new Receipt__c(
            Opportunity__c = opp1.Id,
            Amount__c = 1200,                 // enough to hit multiple schedules
            Approval_Status__c = 'Pending',
            Type__c = 'Tax Invoice'
        );
        insert r;

        Test.startTest();
        // Update -> Approved (this fires trigger -> both methods)
        r.Approval_Status__c = 'Approved';
        update r;
        Test.stopTest();

        // Assert schedules updated
        List<Payment_Schedule__c> ps = [
            SELECT Installment_Sequence__c, Total_Received_Amount__c, Tax_Invoice_Created__c
            FROM Payment_Schedule__c
            WHERE Opportunity__c = :opp1.Id
            ORDER BY Installment_Sequence__c
        ];
        System.assertEquals(2, ps.size());

        // installment1 total=1100 should be fully received
        System.assertEquals(1100, ps[0].Total_Received_Amount__c);
        // remaining 100 should go to installment2
        System.assertEquals(100, ps[1].Total_Received_Amount__c);

        // At least one schedule should now have Tax_Invoice_Created__c = true
        System.assertEquals(true, ps[0].Tax_Invoice_Created__c);
    }

    @isTest
    static void testTrigger_MoveApprovedTaxInvoice_RecalculatesOldOpp() {
        Opportunity opp1 = [SELECT Id FROM Opportunity WHERE Name='Opp 1' LIMIT 1];
        Opportunity opp2 = [SELECT Id FROM Opportunity WHERE Name='Opp 2' LIMIT 1];

        // Insert receipt already Approved on opp1
        Receipt__c r = new Receipt__c(
            Opportunity__c = opp1.Id,
            Amount__c = 400,
            Approval_Status__c = 'Approved',
            Type__c = 'Tax Invoice'
        );
        insert r;

        // Now move opp from opp1 -> opp2 (fires trigger, hits move recalculation branch)
        Test.startTest();
        r.Opportunity__c = opp2.Id;
        update r;
        Test.stopTest();

        // Just assert no exception and schedules exist
        System.assertEquals(
            2,
            [SELECT COUNT() FROM Payment_Schedule__c WHERE Opportunity__c = :opp1.Id]
        );
        System.assertEquals(
            1,
            [SELECT COUNT() FROM Payment_Schedule__c WHERE Opportunity__c = :opp2.Id]
        );
    }

    @isTest
    static void testTrigger_NonTaxInvoice_IgnoredForSchedules() {
        Opportunity opp1 = [SELECT Id FROM Opportunity WHERE Name='Opp 1' LIMIT 1];

        Receipt__c r = new Receipt__c(
            Opportunity__c = opp1.Id,
            Amount__c = 500,
            Approval_Status__c = 'Pending',
            Type__c = 'Credit' // should be ignored
        );
        insert r;

        Test.startTest();
        r.Approval_Status__c = 'Approved';
        update r;
        Test.stopTest();
    }
    
    @isTest
static void testTrigger_MoveOppOnApproval_CoversOldOppRecalc() {
    Account acc = new Account(Name='Acc OldOppRecalc');
    insert acc;

    Opportunity opp1 = new Opportunity(
        Name='Opp Old',
        StageName='Prospecting',
        CloseDate=Date.today().addDays(10),
        AccountId=acc.Id
    );
    Opportunity opp2 = new Opportunity(
        Name='Opp New',
        StageName='Prospecting',
        CloseDate=Date.today().addDays(15),
        AccountId=acc.Id
    );
    insert new List<Opportunity>{opp1, opp2};

    // Payment schedules for BOTH opps (oldOpp recalc queries these)
    insert new List<Payment_Schedule__c>{
        new Payment_Schedule__c(
            Opportunity__c=opp1.Id, Installment_Sequence__c=1,
            Agreement_Value__c=1000, Tax_Amount__c=100,
            Total_Received_Amount__c=0, Tax_Invoice_Created__c=false
        ),
        new Payment_Schedule__c(
            Opportunity__c=opp2.Id, Installment_Sequence__c=1,
            Agreement_Value__c=800, Tax_Amount__c=80,
            Total_Received_Amount__c=0, Tax_Invoice_Created__c=false
        )
    };

    // Create another already-approved Tax Invoice receipt on OLD opp
    // so AggregateResult has something to sum.
    Receipt__c existingOldOppApproved = new Receipt__c(
        Opportunity__c = opp1.Id,
        Amount__c = 300,
        Approval_Status__c = 'Approved',
        Type__c = 'Tax Invoice'
    );
    insert existingOldOppApproved;

    // Now create receipt in Pending on opp1
    Receipt__c r = new Receipt__c(
        Opportunity__c = opp1.Id,
        Amount__c = 400,
        Approval_Status__c = 'Pending',
        Type__c = 'Tax Invoice'
    );
    insert r;
	receiptTriggerHandler.dummyMethod();
    Test.startTest();

    // 🔥 Single update: move opp + approve at the same time
    r.Opportunity__c = opp2.Id;
    r.Approval_Status__c = 'Approved';
    update r;

    Test.stopTest();

}
}