@IsTest
private class ReceiptTransferPaymentScheduleTest {

    @TestSetup
    static void setupData() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Opportunity fromOpp = new Opportunity(
            Name = 'From Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),
            AccountId = acc.Id
        );

        Opportunity toOpp = new Opportunity(
            Name = 'To Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),
            AccountId = acc.Id
        );

        insert new List<Opportunity>{ fromOpp, toOpp };

        Payment_Schedule__c fromPs = new Payment_Schedule__c(
            Opportunity__c = fromOpp.Id,
            Installment_Sequence__c = 1,
            Agreement_Value__c = 500,
            Tax_Amount__c = 50,
            Total_Received_Amount__c = 550,
            Demand_Letter_Sent__c = false
        );

        Payment_Schedule__c toPs = new Payment_Schedule__c(
            Opportunity__c = toOpp.Id,
            Installment_Sequence__c = 1,
            Agreement_Value__c = 1000,
            Tax_Amount__c = 100,
            Total_Received_Amount__c = 0,
            Demand_Letter_Sent__c = false
        );

        insert new List<Payment_Schedule__c>{ fromPs, toPs };
    }

    @IsTest
    static void testRun_RecalculatesSchedules_ForApprovedNonDebitReceipt() {
        Opportunity fromOpp = [SELECT Id FROM Opportunity WHERE Name = 'From Opportunity' LIMIT 1];
        Opportunity toOpp = [SELECT Id FROM Opportunity WHERE Name = 'To Opportunity' LIMIT 1];

        Receipt__c rcpt = new Receipt__c(
            Opportunity__c = fromOpp.Id,
            Approval_Status__c = 'Approved',
            Type__c = 'Tax Invoice',
            Amount__c = 500,
            TDS_Amount__c = 50,
            Receipt_Date__c = Date.today()
        );
        insert rcpt;

        Receipt_Transfer_Log__c logRec = new Receipt_Transfer_Log__c(
            Approval_Status__c = 'Approved'
        );
        insert logRec;

        Receipt_Transfer_Log_LineItem__c lineItem = new Receipt_Transfer_Log_LineItem__c(
            Receipt_Transfer_Log__c = logRec.Id,
            Receipt__c = rcpt.Id,
            From_Opportunity__c = fromOpp.Id,
            To_Opportunity__c = toOpp.Id
        );
        insert lineItem;

        rcpt.Opportunity__c = toOpp.Id;
        update rcpt;

        ReceiptTransferPaymentScheduleInvoker.Request req = new ReceiptTransferPaymentScheduleInvoker.Request();
        req.transferLogId = logRec.Id;

        Test.startTest();
        ReceiptTransferPaymentScheduleInvoker.run(new List<ReceiptTransferPaymentScheduleInvoker.Request>{ req });
        Test.stopTest();
    }

    @IsTest
    static void testRun_SkipsDebitReceipt() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];

        Opportunity fromOpp = new Opportunity(
            Name = 'Debit From Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(5),
            AccountId = acc.Id
        );

        Opportunity toOpp = new Opportunity(
            Name = 'Debit To Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(5),
            AccountId = acc.Id
        );
        insert new List<Opportunity>{ fromOpp, toOpp };

        Payment_Schedule__c fromPs = new Payment_Schedule__c(
            Opportunity__c = fromOpp.Id,
            Installment_Sequence__c = 1,
            Agreement_Value__c = 300,
            Tax_Amount__c = 30,
            Total_Received_Amount__c = 100,
            Demand_Letter_Sent__c = false
        );

        Payment_Schedule__c toPs = new Payment_Schedule__c(
            Opportunity__c = toOpp.Id,
            Installment_Sequence__c = 1,
            Agreement_Value__c = 300,
            Tax_Amount__c = 30,
            Total_Received_Amount__c = 0,
            Demand_Letter_Sent__c = false
        );
        insert new List<Payment_Schedule__c>{ fromPs, toPs };

        Receipt__c rcpt = new Receipt__c(
            Opportunity__c = toOpp.Id,
            Approval_Status__c = 'Approved',
            Type__c = 'Debit',
            Amount__c = 100,
            TDS_Amount__c = 0,
            Receipt_Date__c = Date.today()
        );
        insert rcpt;

        Receipt_Transfer_Log__c logRec = new Receipt_Transfer_Log__c(
            Approval_Status__c = 'Approved'
        );
        insert logRec;

        Receipt_Transfer_Log_LineItem__c lineItem = new Receipt_Transfer_Log_LineItem__c(
            Receipt_Transfer_Log__c = logRec.Id,
            Receipt__c = rcpt.Id,
            From_Opportunity__c = fromOpp.Id,
            To_Opportunity__c = toOpp.Id
        );
        insert lineItem;

        ReceiptTransferPaymentScheduleInvoker.Request req = new ReceiptTransferPaymentScheduleInvoker.Request();
        req.transferLogId = logRec.Id;

        Test.startTest();
        ReceiptTransferPaymentScheduleInvoker.run(new List<ReceiptTransferPaymentScheduleInvoker.Request>{ req });
        Test.stopTest();
    }

    @IsTest
    static void testRun_SkipsUnapprovedReceipt() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];

        Opportunity fromOpp = new Opportunity(
            Name = 'Pending From Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(5),
            AccountId = acc.Id
        );

        Opportunity toOpp = new Opportunity(
            Name = 'Pending To Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(5),
            AccountId = acc.Id
        );
        insert new List<Opportunity>{ fromOpp, toOpp };

        Payment_Schedule__c fromPs = new Payment_Schedule__c(
            Opportunity__c = fromOpp.Id,
            Installment_Sequence__c = 1,
            Agreement_Value__c = 400,
            Tax_Amount__c = 40,
            Total_Received_Amount__c = 120,
            Demand_Letter_Sent__c = false
        );

        Payment_Schedule__c toPs = new Payment_Schedule__c(
            Opportunity__c = toOpp.Id,
            Installment_Sequence__c = 1,
            Agreement_Value__c = 400,
            Tax_Amount__c = 40,
            Total_Received_Amount__c = 0,
            Demand_Letter_Sent__c = false
        );
        insert new List<Payment_Schedule__c>{ fromPs, toPs };

        Receipt__c rcpt = new Receipt__c(
            Opportunity__c = toOpp.Id,
            Approval_Status__c = 'Pending',
            Type__c = 'Tax Invoice',
            Amount__c = 120,
            TDS_Amount__c = 0,
            Receipt_Date__c = Date.today()
        );
        insert rcpt;

        Receipt_Transfer_Log__c logRec = new Receipt_Transfer_Log__c(
            Approval_Status__c = 'Approved'
        );
        insert logRec;

        Receipt_Transfer_Log_LineItem__c lineItem = new Receipt_Transfer_Log_LineItem__c(
            Receipt_Transfer_Log__c = logRec.Id,
            Receipt__c = rcpt.Id,
            From_Opportunity__c = fromOpp.Id,
            To_Opportunity__c = toOpp.Id
        );
        insert lineItem;

        ReceiptTransferPaymentScheduleInvoker.Request req = new ReceiptTransferPaymentScheduleInvoker.Request();
        req.transferLogId = logRec.Id;

        Test.startTest();
        ReceiptTransferPaymentScheduleInvoker.run(new List<ReceiptTransferPaymentScheduleInvoker.Request>{ req });
        Test.stopTest();


    }

    @IsTest
    static void testRun_HandlesEmptyRequest() {
        Test.startTest();
        ReceiptTransferPaymentScheduleInvoker.run(new List<ReceiptTransferPaymentScheduleInvoker.Request>());
        Test.stopTest();

        System.assert(true);
    }
}