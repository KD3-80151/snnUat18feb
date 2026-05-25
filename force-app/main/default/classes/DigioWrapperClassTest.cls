@isTest
public class DigioWrapperClassTest {

    @testSetup
    static void setupData() {
        DigioWrapperClass.agreementCopyWrapper wrapper = new DigioWrapperClass.agreementCopyWrapper();
        wrapper.file_name = 'AgreementFile.pdf';

        // Signer
        DigioWrapperClass.signersList signer = new DigioWrapperClass.signersList();
        signer.identifier = '1';
        signer.signer_tag = 'S1';
        signer.name = 'John Doe';
        signer.sign_type = 'esign';
        wrapper.signers = new List<DigioWrapperClass.signersList>{ signer };

        // Template values
        DigioWrapperClass.agreementCopyTemplateValues values = new DigioWrapperClass.agreementCopyTemplateValues();
        values.currentDay = 'Test';
        values.currentYear = 25;
        values.currentYearWords = 'test';
        values.currentDate = 'test';
        values.priAppName = 'Applicant1';
        values.priAppSoWo = 'test';
        values.priAppAge = 'test';
        values.priAppPan = 'test';
        values.priAppAadhar = 'test';
        values.priAppEmail = 'test@example.com';
        values.secAppSoWo = 'test';
        values.secAppAge = 'test';
        values.secAppName = 'test';
        values.secAppPan = 'test';
        values.secAppAadhar = 'test';
        values.secAppEmail = 'test';
        values.unitNumber = 'test';
        values.projectName = 'Phoenix Group';
        values.agreementValue = 11;
        values.agreementValueWords = 'test';
        values.carParkingDetails = 'test';
        values.bookingAmount = 11;
        values.bookingAmountWords = 'test';
        values.chequeNo = 'test';
        values.chequeDate = 'test';
        values.bankName = 'test';
        values.branchName = 'test';
        values.receiptDate = 'test';
        values.totalReceiptAmt = 11;
        values.accountNumber = 'test';
        values.ifscCode = 'test';
        values.accbankName = 'test';
        values.priAppAddress = 'test';
        values.unitType = 'test';
        values.floorName = 'test';
        values.blockName = 'test';
        values.superBuiltupArea = 'test';
        values.totalPaymentAmt = 11;

        // Receipt row
        DigioWrapperClass.receiptData rec = new DigioWrapperClass.receiptData();
        rec.sl = 1;
        rec.receiptNo = 'R1';
        rec.receiptDate = Date.today();
        rec.receiptBank = 'HDFC';
        rec.Amount = 1000;

        // Payment row
        DigioWrapperClass.paySchData pay = new DigioWrapperClass.paySchData();
        pay.Name = 'Booking';
        pay.amount = 2000;

        DigioWrapperClass.agreementCopyDynamicTable table = new DigioWrapperClass.agreementCopyDynamicTable();
        table.receipt = new List<DigioWrapperClass.receiptData>{ rec };
        table.payment = new List<DigioWrapperClass.paySchData>{ pay };

        DigioWrapperClass.agreementCopyTemplateList template = new DigioWrapperClass.agreementCopyTemplateList();
        template.template_key = 'TEMPLATE1';
        template.template_values = values;
        template.template_table_values = table;

        wrapper.templates = new List<DigioWrapperClass.agreementCopyTemplateList>{ template };

        System.assertEquals('AgreementFile.pdf', wrapper.file_name);
        System.assertEquals('John Doe', wrapper.signers[0].name);
        System.assertEquals('Phoenix Group', wrapper.templates[0].template_values.projectName);
        System.assertEquals(1000, wrapper.templates[0].template_table_values.receipt[0].Amount);
        DigioWrapperClass.debitNoteTemplateValues v1 = new DigioWrapperClass.debitNoteTemplateValues();
        v1.allApplicantNames = 'Test';
        v1.mainApplicantPinCode = 'Test';
        v1.unitNumber = 'Test';
        v1.todayDate = System.today();
        v1.projectName = 'Test';
        v1.blockName = 'Test';
        v1.debitAmount = 11;
        v1.currentUser = 'Test';
        v1.debitNoteDescription = 'Test';
        v1.nextPaymentSchName = 'Test';
        DigioWrapperClass.debitNoteTemplateList l1 = new DigioWrapperClass.debitNoteTemplateList();
        l1.template_key = 'TEMPLATE1';
        l1.template_values = v1;
        DigioWrapperClass.generateDebitNoteWrapper test1 = new DigioWrapperClass.generateDebitNoteWrapper();
        test1.signers = new List<DigioWrapperClass.signersList>{ signer };
        test1.display_on_page = 'FIRST';
        test1.expire_in_days = '1';
        test1.file_name = 'test';
        test1.templates = new List<DigioWrapperClass.debitNoteTemplateList> {l1};
        test1.send_sign_link = false;
        test1.notify_signers = false;
        DigioWrapperClass.vehicleParkingTemplateList l2 = new DigioWrapperClass.vehicleParkingTemplateList();
        l2.template_key = 'test';
        DigioWrapperClass.generateVehicleParkingWrapper test2 = new DigioWrapperClass.generateVehicleParkingWrapper();
        test2.signers = new List<DigioWrapperClass.signersList>{ signer };
        test2.display_on_page = 'FIRST';
        test2.expire_in_days = '1';
        test2.file_name = 'test';
        test2.templates = new List<DigioWrapperClass.vehicleParkingTemplateList> {l2};
        test2.send_sign_link = false;
        test2.notify_signers = false;
        DigioWrapperClass.serviceContactsTemplateList l3= new DigioWrapperClass.serviceContactsTemplateList();
        l3.template_key = 'test';
        DigioWrapperClass.generateContactListWrapper test3 = new DigioWrapperClass.generateContactListWrapper();
        test3.signers = new List<DigioWrapperClass.signersList>{ signer };
        test3.display_on_page = 'FIRST';
        test3.expire_in_days = '1';
        test3.file_name = 'test';
        test3.templates = new List<DigioWrapperClass.serviceContactsTemplateList> {l3};
        test3.send_sign_link = false;
        test3.notify_signers = false;
        DigioWrapperClass.partyHallRulesTemplateValues v4 = new DigioWrapperClass.partyHallRulesTemplateValues();
        v4.ResidentPhone = 'test';
        v4.ResidentName = 'test';
        v4.ResidentAltPhone = 'test';
        v4.OppBookingDate = System.today();
        v4.UnitNumber = 'test';
        DigioWrapperClass.partyHallRulesTemplateList l4 = new DigioWrapperClass.partyHallRulesTemplateList();
        l4.template_key = 'test';
        l4.template_values = v4;
        DigioWrapperClass.generatePartyHallRulesWrapper test4 = new DigioWrapperClass.generatePartyHallRulesWrapper();
        test4.signers = new List<DigioWrapperClass.signersList>{ signer };
        test4.display_on_page = 'FIRST';
        test4.expire_in_days = '1';
        test4.file_name = 'test';
        test4.templates = new List<DigioWrapperClass.partyHallRulesTemplateList> {l4};
        test4.send_sign_link = false;
        test4.notify_signers = false;
        DigioWrapperClass.moveInOutTemplateValues v5 = new DigioWrapperClass.moveInOutTemplateValues();
        v5.ContactMobile = 'test';
        v5.ResidentName = 'test';
        v5.ContactEmail = 'test';
        v5.ApplicationDate = System.today();
        v5.UnitNumber = 'test';
        DigioWrapperClass.moveInOutTemplateList l5 = new DigioWrapperClass.moveInOutTemplateList();
        l5.template_key = 'test';
        l5.template_values = v5;
        DigioWrapperClass.generateMoveInOutWrapper test5 = new DigioWrapperClass.generateMoveInOutWrapper();
        test5.signers = new List<DigioWrapperClass.signersList>{ signer };
        test5.display_on_page = 'FIRST';
        test5.expire_in_days = '1';
        test5.file_name = 'test';
        test5.templates = new List<DigioWrapperClass.moveInOutTemplateList> {l5};
        test5.send_sign_link = false;
        test5.notify_signers = false;
        DigioWrapperClass.paymentScheduleList ll6 = new DigioWrapperClass.paymentScheduleList();
        ll6.totalDue = 11;
        ll6.totalPayment = 11;
        ll6.balanceDue = 11;
        ll6.dueDate = System.today();
        DigioWrapperClass.demandDynamicTable t6 = new DigioWrapperClass.demandDynamicTable();
        t6.paymentSchedule = new List<DigioWrapperClass.paymentScheduleList>{ll6};
        DigioWrapperClass.demandTemplateValues v6 = new DigioWrapperClass.demandTemplateValues();
        v6.UnitNumber = 'test';
        v6.PaymentScheduleDueDate = System.today();
        v6.PaymentScheduleDueAmount = 11;
        v6.Address1 = 'test';
        v6.TowerName = 'test';
        v6.todayDate = 'test';
        v6.balanceAmountInWords = 'test';
        v6.ProjectName = 'test';
        v6.CoAppicantNames = 'test';
        v6.MainAppicantName = 'test';
        v6.TridasaFullName = 'test';
        v6.PaymentScheduleName = 'test';
        DigioWrapperClass.demandTemplateList l6 = new DigioWrapperClass.demandTemplateList();
        l6.template_key = 'test';
        l6.template_values = v6;
        l6.template_table_values = t6;
        DigioWrapperClass.generateDemandLetter test6 = new DigioWrapperClass.generateDemandLetter();
        test6.signers = new List<DigioWrapperClass.signersList>{ signer };
        test6.display_on_page = 'FIRST';
        test6.expire_in_days = '1';
        test6.file_name = 'test';
        test6.templates = new List<DigioWrapperClass.demandTemplateList> {l6};
        test6.send_sign_link = false;
        test6.notify_signers = false;
        DigioWrapperClass.paymentScheduleTable ll7 = new DigioWrapperClass.paymentScheduleTable();
        ll7.SlNo = 11;
        ll7.installment = 'test';
        ll7.sequence = 'test';
        ll7.milestone = 11;
        ll7.amount = 11;
        DigioWrapperClass.allotmentLetterDynamicTable t7 = new DigioWrapperClass.allotmentLetterDynamicTable();
        t7.paymentScheduleTable = new List<DigioWrapperClass.paymentScheduleTable>{ll7};
        DigioWrapperClass.allotmentLetterTemplateValues v7 = new DigioWrapperClass.allotmentLetterTemplateValues();
        v7.applicantName = 'test';
        v7.coApplicantName = 'test';
        v7.addressName = 'test';
        v7.pinCodeNumber = 'test';
        v7.emailId = 'test';
        v7.phoneNumber = 'test';
        v7.SNNEStateFelicity = 'test';
        v7.bloackName = 'test';
        v7.companyName = 'test';
        v7.companyAddress = 'test';
        v7.floorName = 11;
        v7.apartmentNo = 'test';
        v7.apartmentTypeName = 'test';
        v7.saleableAreaName = 11;
        v7.carParkingDetails = 'test';
        v7.loginUserName = 'test';
        v7.totalFlatCost = 11;
        DigioWrapperClass.allotmentLetterTemplateList l7 = new DigioWrapperClass.allotmentLetterTemplateList();
        l7.template_key = 'test';
        l7.template_values = v7;
        l7.template_table_values = t7;
        DigioWrapperClass.generateAllotmentLetter test7 = new DigioWrapperClass.generateAllotmentLetter();
        test7.signers = new List<DigioWrapperClass.signersList>{ signer };
        test7.display_on_page = 'FIRST';
        test7.expire_in_days = '1';
        test7.file_name = 'test';
        test7.templates = new List<DigioWrapperClass.allotmentLetterTemplateList> {l7};
        test7.send_sign_link = false;
        test7.notify_signers = false;
        DigioWrapperClass.serenityReceiptTemplateValues v8 = new DigioWrapperClass.serenityReceiptTemplateValues();
        v8.receiptNo = 'test';
        v8.receiptDate = 'test';
        v8.projectName = 'test';
        v8.customerName = 'test';
        v8.coApplicantName = 'test';
        v8.clientAddress = 'test';
        v8.amountInWords = 'test';
        v8.modeOfPayment = 'test';
        v8.referenceNo = 'test';
        v8.chequeDate = 'test';
        v8.bankName = 'test';
        v8.typeOfUnit = 'test';
        v8.flatNo = 'test';
        v8.unitNo = 'test';
        v8.blockName = 'test';
        v8.amountValues = 'test';
        v8.loginUserName = 'test';
        v8.exactTime = 'test';
        v8.todayDate = System.today();
        v8.companyName = 'test';
        v8.companyAddress = 'test';
        v8.companyEmail = 'test';
        DigioWrapperClass.serenityReceiptTemplateList l8 = new DigioWrapperClass.serenityReceiptTemplateList();
        l8.template_key = 'test';
        l8.template_values = v8;
        DigioWrapperClass.generateReceipt test8 = new DigioWrapperClass.generateReceipt();
        test8.signers = new List<DigioWrapperClass.signersList>{ signer };
        test8.display_on_page = 'FIRST';
        test8.expire_in_days = '1';
        test8.file_name = 'test';
        test8.templates = new List<DigioWrapperClass.serenityReceiptTemplateList> {l8};
        test8.send_sign_link = false;
        test8.notify_signers = false;
        DigioWrapperClass.statementOfReceiptTotal llllll9 = new DigioWrapperClass.statementOfReceiptTotal();
        llllll9.Finalamount = 11;
        DigioWrapperClass.statementOfReceipt lllll9 = new DigioWrapperClass.statementOfReceipt();
        lllll9.receiptNo = 'test';
        lllll9.receiptDate = 'test';
        lllll9.instrumentNo = 'test';
        lllll9.instrumentDate = 'test';
        lllll9.paymentCategory = 'test';
        lllll9.bankName = 'test';
        lllll9.amount = 11;
        DigioWrapperClass.statementOfScheduleTable llll9 = new DigioWrapperClass.statementOfScheduleTable();
        llll9.Total = 'test';
        llll9.FinaltotalBilled = 11;
        llll9.FinalamountReceived = 11;
        llll9.FinalamountBalance = 11;
        DigioWrapperClass.statementOfAccountTable lll9 = new DigioWrapperClass.statementOfAccountTable();
        lll9.particularData = 'test';
        lll9.totalBilled = 11;
        lll9.amountReceived = 11;
        lll9.amountBalance = 11;  
        DigioWrapperClass.accountScheduleDynamicTable ll9 = new DigioWrapperClass.accountScheduleDynamicTable();
        ll9.statementOfAccountTable = new List<DigioWrapperClass.statementOfAccountTable>{lll9};
        ll9.statementOfScheduleTable = new List<DigioWrapperClass.statementOfScheduleTable>{llll9};
        ll9.statementOfReceipt = new List<DigioWrapperClass.statementOfReceipt>{lllll9};
        ll9.statementOfReceiptTotal = new List<DigioWrapperClass.statementOfReceiptTotal>{llllll9};
        DigioWrapperClass.accountTemplateValues v9 = new DigioWrapperClass.accountTemplateValues();
        v9.TodayDate = 'test';
        v9.customerName = 'test';
        v9.customerAddress = 'test';
        v9.projectName = 'test';
        v9.unitNo = 'test';
        v9.blockNo = 'test';
        v9.generatedTime = 'test';
        v9.userName = 'test';
        v9.oppFinalBalance = 11;
        DigioWrapperClass.accountStatementTemplateList l9 = new DigioWrapperClass.accountStatementTemplateList();
        l9.template_key = 'test';
        l9.template_values = v9;
        l9.template_table_values = ll9;
        DigioWrapperClass.generateStatement test9 = new DigioWrapperClass.generateStatement();
        test9.signers = new List<DigioWrapperClass.signersList>{ signer };
        test9.display_on_page = 'FIRST';
        test9.expire_in_days = '1';
        test9.file_name = 'test';
        test9.templates = new List<DigioWrapperClass.accountStatementTemplateList> {l9};
        test9.send_sign_link = false;
        test9.notify_signers = false;
        DigioWrapperClass.demandLetterTotal llll0 = new DigioWrapperClass.demandLetterTotal();
        llll0.FinalScheduleAmount = 11;
        llll0.FinallessTotalAmount = 11;
        llll0.FinallessTdsAmount = 11;
        llll0.FinalbalancePaybleAmount = 11;
        DigioWrapperClass.demandLetterTable lll0 = new DigioWrapperClass.demandLetterTable();
        lll0.bookingAgreementToSell = 'test';
        lll0.showValueIn = 11;
        lll0.dueDate = 'test';
        lll0.dueAmount = 11;
        lll0.taxesAmout = 11;
        lll0.totalScheduledDueAmount = 11;
        DigioWrapperClass.demandLetterPaymentScheduleTable ll0 = new DigioWrapperClass.demandLetterPaymentScheduleTable();
        ll0.DemandLetterTable = new List<DigioWrapperClass.demandLetterTable>{lll0};
        ll0.DemandLetterTotalTable = new List<DigioWrapperClass.demandLetterTotal>{llll0};
        DigioWrapperClass.demandLetterTemplateValues v0 = new DigioWrapperClass.demandLetterTemplateValues();
        v0.TodayDate = System.today();
        v0.customerName = 'test';
        v0.customerAddress = 'test';
        v0.customerPincode = 'test';
        v0.mobileNo = 'test';
        v0.SubjectName = 'test';
        v0.projectName = 'test';
        v0.bankName = 'test';
        v0.accountNo = 'test';
        v0.ifscCode = 'test';
        v0.dueDate = System.today();
        v0.currentUser = 'test';
        v0.exactTime = 'test';
        v0.coApplicantNames = 'test';
        v0.paymentScheduleName = 'test';
        v0.blockName = 'test';
        v0.loggedInUser = 'test';
        v0.FinalScheduleAmount = 11;
        v0.FinallessTotalAmount = 11;
        v0.FinallessTdsAmount = 11;
        v0.FinalbalancePaybleAmount = 11;
        DigioWrapperClass.demandLetterTemplateValuesList l0 = new DigioWrapperClass.demandLetterTemplateValuesList();
        l0.template_key = 'test';
        l0.template_values = v0;
        l0.template_table_values = ll0;
        DigioWrapperClass.demandLetterTemplate test0 = new DigioWrapperClass.demandLetterTemplate();
        test0.signers = new List<DigioWrapperClass.signersList>{ signer };
        test0.display_on_page = 'FIRST';
        test0.expire_in_days = '1';
        test0.file_name = 'test';
        test0.templates = new List<DigioWrapperClass.demandLetterTemplateValuesList> {l0};
        test0.send_sign_link = false;
        test0.notify_signers = false;
        DigioWrapperClass.costSheetTable llll10 = new DigioWrapperClass.costSheetTable();
        llll10.breakup = 'test';
        llll10.paymentSchedule = 'test';
        llll10.installDate = System.today();
        llll10.amountValue = 11;
        DigioWrapperClass.costSheetAssociationTable lll10 = new DigioWrapperClass.costSheetAssociationTable();
        lll10.floorRise = 'test';
        lll10.amount = 11;
        DigioWrapperClass.costSheetPaymentTable ll10 = new DigioWrapperClass.costSheetPaymentTable();
        ll10.costSheetAssociation = new List<DigioWrapperClass.costSheetAssociationTable>{lll10};
        ll10.costSheetTable = new List<DigioWrapperClass.costSheetTable>{llll10};
        DigioWrapperClass.costSheetTemplateValues v10 = new DigioWrapperClass.costSheetTemplateValues();
        v10.unitNo = 'test';
        v10.typeOfUnit = 'test';
        v10.floorNumber = 11;
        v10.superBuiltupArea = 11;
        v10.basicPrice = 11;
        v10.apartmentPrice = 11;
        v10.cgstData = 11;
        v10.sgstData = 11;
        v10.totalValue = 11;
        v10.totalAmount = 11;
        v10.addressDetail = 'test';
        v10.customerName = 'test';
        v10.projectName = 'test';
        DigioWrapperClass.costSheetTemplateValuesList l10 = new DigioWrapperClass.costSheetTemplateValuesList();
        l10.template_key = 'test';
        l10.template_values = v10;
        l10.template_table_values = ll10;
        DigioWrapperClass.costSheetTemplate test10 = new DigioWrapperClass.costSheetTemplate();
        test10.signers = new List<DigioWrapperClass.signersList>{ signer };
        test10.display_on_page = 'FIRST';
        test10.expire_in_days = '1';
        test10.file_name = 'test';
        test10.templates = new List<DigioWrapperClass.costSheetTemplateValuesList> {l10};
        test10.send_sign_link = false;
        test10.notify_signers = false;
        // new DigioWrapperClass.saleConsAgreement();
        // new DigioWrapperClass.getWelcomeKit();
        // new DigioWrapperClass.getHomeOwners();
        // new DigioWrapperClass.getHandOver();
    }

    @isTest
    static void testDataSheetWrapper() {
        DigioWrapperClass.dataSheetFormatWrapper ds = new DigioWrapperClass.dataSheetFormatWrapper();
        ds.file_name = 'DataSheet.pdf';

        DigioWrapperClass.signersList signer = new DigioWrapperClass.signersList();
        signer.identifier = '2';
        signer.name = 'Jane Doe';
        signer.sign_type = 'esign';
        signer.signer_tag = 'S2';
        ds.signers = new List<DigioWrapperClass.signersList>{ signer };

        DigioWrapperClass.dataSheetTemplateValues val = new DigioWrapperClass.dataSheetTemplateValues();
        val.app1Name = 'Applicant1';
        val.app1Email = 'app1@example.com';
        val.blockAndUnitNo = 'Block A - 101';
        val.app2Name = 'test';
        val.app3Name = 'test';
        val.app4Name = 'test';
        val.app5Name = 'test';
        val.app6Name = 'test';
        val.app1SoDoWo = 'test';
        val.app2SoDoWo = 'test';
        val.app3SoDoWo = 'test';
        val.app4SoDoWo = 'test';
        val.app5SoDoWo = 'test';
        val.app6SoDoWo = 'test';
        val.app1Age = 'test';
        val.app2Age = 'test';
        val.app3Age = 'test';
        val.app4Age = 'test';
        val.app5Age = 'test';
        val.app6Age = 'test';
        val.app1Dob = System.today();
        val.app2Dob = System.today();
        val.app3Dob = System.today();
        val.app4Dob = System.today();
        val.app5Dob = System.today();
        val.app6Dob = System.today();
        val.app1Pan = 'test';
        val.app2Pan = 'test';
        val.app3Pan = 'test';
        val.app4Pan = 'test';
        val.app5Pan = 'test';
        val.app6Pan = 'test';
        val.app2Email = 'test';
        val.app3Email = 'test';
        val.app4Email = 'test';
        val.app5Email = 'test';
        val.app6Email = 'test';
        val.app1Address = 'test';
        val.app2Address = 'test';
        val.app3Address = 'test';
        val.app4Address = 'test';
        val.app5Address = 'test';
        val.app6Address = 'test';
        val.unitType = 'test';
        val.priAppNumber = 'test';
        val.superBuiltupArea = 11;
        val.carParking = 'test';
        val.twoWheeler = 11;
        val.basicPrice = 11;
        val.floorRise = 11;
        val.premiumCharges = 11;

        DigioWrapperClass.dataSheetTemplateList temp = new DigioWrapperClass.dataSheetTemplateList();
        temp.template_key = 'DS1';
        temp.template_values = val;

        ds.templates = new List<DigioWrapperClass.dataSheetTemplateList>{ temp };

        System.assertEquals('DataSheet.pdf', ds.file_name);
        System.assertEquals('Applicant1', ds.templates[0].template_values.app1Name);
    }

    @isTest
    static void testReceiptWrapper() {
        DigioWrapperClass.generateVettedReceipt rcpt = new DigioWrapperClass.generateVettedReceipt();
        rcpt.file_name = 'Receipt.pdf';

        DigioWrapperClass.signersList signer = new DigioWrapperClass.signersList();
        signer.identifier = '2';
        signer.name = 'Jane Doe';
        signer.sign_type = 'esign';
        signer.signer_tag = 'S2';
        rcpt.signers = new List<DigioWrapperClass.signersList>{ signer };

        DigioWrapperClass.receiptTemplateValues vals = new DigioWrapperClass.receiptTemplateValues();
        vals.ProjectName = 'Phoenix Group';
        vals.companyName = 'test';
        vals.mainReceiptAmountInWords = 'test';
        vals.custName = 'Customer1';
        vals.custwebsite = 'test';
        vals.today1 = System.today();
        vals.fAmt = 11;
        vals.mainReceiptDate = System.today();
        vals.phoneNo = 'test';
        vals.unitNumber = 'A101';
        vals.mainReceiptAmount = 10000;
        vals.receiptCinNo = 'test';
        vals.companyAddress = 'test';
        vals.receiptNo = 'test';
        vals.floorNumber = 'test';
        vals.custId = 'test';
        vals.custEmailId = 'test';
        vals.towerName = 'test';
        vals.mainReceiptBank = 'test';
        vals.reraNumber = 'test';

        DigioWrapperClass.receiptTableList row = new DigioWrapperClass.receiptTableList();
        row.instrumentMode = 'Cheque';
        row.receiptDate = Date.today();
        row.instrumentNo = '1234';
        row.receiptBank = 'SBI';
        row.receiptAmount = 10000;
        row.receiptCgst = 500;
        row.receiptSgst = 500;
        row.receiptTotalAmount = 11000;

        DigioWrapperClass.receiptDynamicTable dynTable = new DigioWrapperClass.receiptDynamicTable();
        dynTable.receiptTable = new List<DigioWrapperClass.receiptTableList>{ row };

        DigioWrapperClass.receiptTemplateList temp = new DigioWrapperClass.receiptTemplateList();
        temp.template_key = 'RC1';
        temp.template_values = vals;
        temp.template_table_values = dynTable;

        rcpt.templates = new List<DigioWrapperClass.receiptTemplateList>{ temp };

        System.assertEquals('Customer1', rcpt.templates[0].template_values.custName);
        System.assertEquals(11000, rcpt.templates[0].template_table_values.receiptTable[0].receiptTotalAmount);
    }

    @isTest
    static void testSaleConsAgreement() {
        DigioWrapperClass.saleConsAgreement wrapper = new DigioWrapperClass.saleConsAgreement();
        wrapper.file_name = 'SaleAgreement.pdf';

        // Signers
        DigioWrapperClass.signersList signer = new DigioWrapperClass.signersList();
        signer.identifier = '1';
        signer.signer_tag = 'S1';
        signer.name = 'John Doe';
        signer.sign_type = 'esign';
        wrapper.signers = new List<DigioWrapperClass.signersList>{ signer };

        // Template values
        DigioWrapperClass.constructionTemplateValues vals = new DigioWrapperClass.constructionTemplateValues();
        vals.apartmentNo = 'A101';
        vals.bedRoomNo = '2BHK';
        vals.contact = '9999999999';
        vals.area = 1200;
        vals.parkingCover = true;
        vals.parkingOpen = false;
        vals.twoWheeler = true;
        vals.basicPrice = 5000000;
        vals.floorRise = '5th';
        vals.poolFacing = 'Yes';
        vals.lakeFacing = 'No';
        vals.draftDetail = 'Draft details here';
        vals.bankName = 'HDFC';
        vals.ddNo = 'DD123';
        vals.dateNo = Date.today();
        vals.amt = 250000;
        vals.loginUser1 = 'User1';
        vals.loginUser2 = 'User2';
        vals.loginUser3 = 'User3';

        // First applicant
        DigioWrapperClass.saleConstructionFirstApplicantTable f = new DigioWrapperClass.saleConstructionFirstApplicantTable();
        f.applicantName = 'First Applicant';
        f.relativeName = 'Relative1';
        f.age = 35;
        f.dob = Date.today().addYears(-35);
        f.aadhar = '123412341234';
        f.pan = 'ABCDE1234F';
        f.email = 'first@example.com';
        f.address = 'Address1';

        // Co-applicant
        DigioWrapperClass.saleConstructionCoApplicantTable c = new DigioWrapperClass.saleConstructionCoApplicantTable();
        c.applicantName = 'Co Applicant';
        c.relativeName = 'Relative2';
        c.age = 30;
        c.dob = Date.today().addYears(-30);
        c.aadhar = '567856785678';
        c.pan = 'XYZAB1234C';
        c.email = 'co@example.com';
        c.address = 'Address2';

        // Association row
        DigioWrapperClass.constructionAssociationTable a = new DigioWrapperClass.constructionAssociationTable();
        a.SlNo = 1;
        a.floorRise = 'Ground';
        a.amount = 100000;

        // Payment table
        DigioWrapperClass.constructionPaymentTable table = new DigioWrapperClass.constructionPaymentTable();
        table.applicantTable = new List<DigioWrapperClass.saleConstructionFirstApplicantTable>{ f };
        table.applicantTable2 = new List<DigioWrapperClass.saleConstructionCoApplicantTable>{ c };
        table.cSA = new List<DigioWrapperClass.constructionAssociationTable>{ a };

        // Template
        DigioWrapperClass.constructionAgreementValueList list1 = new DigioWrapperClass.constructionAgreementValueList();
        list1.template_key = 'CA1';
        list1.template_values = vals;
        list1.template_table_values = table;

        wrapper.templates = new List<DigioWrapperClass.constructionAgreementValueList>{ list1 };

        // Assertions
        System.assertEquals('SaleAgreement.pdf', wrapper.file_name);
        System.assertEquals('A101', wrapper.templates[0].template_values.apartmentNo);
        System.assertEquals('First Applicant', wrapper.templates[0].template_table_values.applicantTable[0].applicantName);
    }

    @isTest
    static void testWelcomeKit() {
        DigioWrapperClass.getWelcomeKit kit = new DigioWrapperClass.getWelcomeKit();
        kit.file_name = 'WelcomeKit.pdf';

        // Signers
        DigioWrapperClass.signersList signer = new DigioWrapperClass.signersList();
        signer.name = 'Signer1';
        signer.identifier = '2';
        signer.sign_type = 'esign';
        signer.signer_tag = 'W1';
        kit.signers = new List<DigioWrapperClass.signersList>{ signer };

        // Template values
        DigioWrapperClass.welcomeKitTemplateValues vals = new DigioWrapperClass.welcomeKitTemplateValues();
        vals.todayDate = Date.today();
        vals.unitNumber = 'B202';
        vals.loggedInUserName = 'Admin';
        vals.allApplicantNames = 'App1, App2';
        vals.bookingDate = Date.today().addDays(-10);
        vals.companyName = 'Phoenix Group';
        vals.companyAddress = 'Hyderabad';
        vals.companyPan = 'PG1234';
        vals.projectAddress = 'Project Hyderabad';
        vals.agreementValue = 9000000;
        vals.totalAmtCollected = 5000000;
        vals.allotmentLetterDate = Date.today().addDays(-5);
        vals.accountName = 'Phoenix Account';
        vals.accountNumber = '123456789';
        vals.typeOfAccount = 'Savings';
        vals.bankName = 'ICICI';
        vals.branchName = 'Main Branch';
        vals.ifscCode = 'ICIC000123';

        // Legal Department
        DigioWrapperClass.legalDepartmentTable l = new DigioWrapperClass.legalDepartmentTable();
        l.name = 'Legal Dept';
        l.executiveName = 'Exec1';
        l.mobileNo = '9999999999';
        l.email = 'legal@example.com';

        // Address
        DigioWrapperClass.snnAddress addr = new DigioWrapperClass.snnAddress();
        addr.companyName = 'SNN';
        addr.officeAddress = 'Bangalore';
        addr.pan = 'SNNPAN123';
        addr.projectAddress = 'Project Bangalore';
        addr.amountPaid = 123456;

        // Bank details
        DigioWrapperClass.snnBankDetails bank = new DigioWrapperClass.snnBankDetails();
        bank.accountName = 'SNN Bank';
        bank.accountNumber = '1111111111';
        bank.typeOfAccount = 'Current';
        bank.bankName = 'HDFC';
        bank.branch = 'Bangalore';
        bank.ifscCode = 'HDFC000111';

        DigioWrapperClass.welcomeKitTable table = new DigioWrapperClass.welcomeKitTable();
        table.legalDepartmentTable = new List<DigioWrapperClass.legalDepartmentTable>{ l };
        table.snnAddressTable = new List<DigioWrapperClass.snnAddress>{ addr };
        table.snnBankDetailsTable = new List<DigioWrapperClass.snnBankDetails>{ bank };

        DigioWrapperClass.wlcomeKitValueList list2 = new DigioWrapperClass.wlcomeKitValueList();
        list2.template_key = 'WK1';
        list2.template_values = vals;
        list2.template_table_values = table;

        kit.templates = new List<DigioWrapperClass.wlcomeKitValueList>{ list2 };

        System.assertEquals('WelcomeKit.pdf', kit.file_name);
        System.assertEquals('Phoenix Group', kit.templates[0].template_values.companyName);
        System.assertEquals('Legal Dept', kit.templates[0].template_table_values.legalDepartmentTable[0].name);
    }

    @isTest
    static void testHomeOwners() {
        DigioWrapperClass.getHomeOwners owners = new DigioWrapperClass.getHomeOwners();
        owners.file_name = 'HomeOwners.pdf';

        DigioWrapperClass.signersList signer = new DigioWrapperClass.signersList();
        signer.name = 'OwnerSigner';
        signer.identifier = '3';
        signer.sign_type = 'esign';
        signer.signer_tag = 'H1';
        owners.signers = new List<DigioWrapperClass.signersList>{ signer };

        DigioWrapperClass.homeOwnerList ho = new DigioWrapperClass.homeOwnerList();
        ho.template_key = 'HO1';

        owners.templates = new List<DigioWrapperClass.homeOwnerList>{ ho };

        System.assertEquals('HomeOwners.pdf', owners.file_name);
        System.assertEquals('HO1', owners.templates[0].template_key);
    }

    @isTest
    static void testHandOver() {
        DigioWrapperClass.getHandOver handover = new DigioWrapperClass.getHandOver();
        handover.file_name = 'HandOver.pdf';

        DigioWrapperClass.signersList signer = new DigioWrapperClass.signersList();
        signer.name = 'Handover Signer';
        signer.identifier = '4';
        signer.sign_type = 'esign';
        signer.signer_tag = 'H2';
        handover.signers = new List<DigioWrapperClass.signersList>{ signer };

        DigioWrapperClass.handOverTemplateValues vals = new DigioWrapperClass.handOverTemplateValues();
        vals.unitNo = 'C303';
        vals.type = 'Final';
        vals.closeDate = Date.today();

        DigioWrapperClass.handOverValueList list3 = new DigioWrapperClass.handOverValueList();
        list3.template_key = 'HO2';
        list3.template_values = vals;

        handover.templates = new List<DigioWrapperClass.handOverValueList>{ list3 };

        System.assertEquals('HandOver.pdf', handover.file_name);
        System.assertEquals('C303', handover.templates[0].template_values.unitNo);
    }
}