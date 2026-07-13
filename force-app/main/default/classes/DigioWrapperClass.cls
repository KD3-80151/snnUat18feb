public without sharing class DigioWrapperClass {

    //generate agreement copy document
    public class agreementCopyWrapper{
        public List<signersList> signers{get;set;}
        public String display_on_page = 'FIRST';
        public String expire_in_days = '1';
        public String file_name{get;set;}
        public List<agreementCopyTemplateList> templates{get;set;}
        public Boolean send_sign_link = false;
        public Boolean notify_signers = false;
    }
    public class agreementCopyTemplateList{
        public String template_key{get;set;}
        public agreementCopyTemplateValues template_values{get;set;}
        public agreementCopyDynamicTable template_table_values{get;set;}
    }
    public class agreementCopyTemplateValues{
        public String currentDay{get;set;}
        public Integer currentYear{get;set;}
        public String currentYearWords{get;set;}
        public String currentDate{get;set;}
        public String priAppName{get;set;}
        public String priAppSoWo{get;set;}
        public String priAppAge{get;set;}
        public String priAppPan{get;set;}
        public String priAppAadhar{get;set;}
        public String priAppEmail{get;set;}
        public String secAppName{get;set;}
        public String secAppSoWo{get;set;}
        public String secAppAge{get;set;}
        public String secAppPan{get;set;}
        public String secAppAadhar{get;set;}
        public String secAppEmail{get;set;}
        public String unitNumber{get;set;}
        public String projectName{get;set;}
        public Decimal agreementValue{get;set;}
        public String agreementValueWords{get;set;}
        public String carParkingDetails{get;set;}
        public Decimal bookingAmount{get;set;}
        public String bookingAmountWords{get;set;}
        public String chequeNo{get;set;}
        public String chequeDate{get;set;}
        public String bankName{get;set;}
        public String branchName{get;set;}
        public String receiptDate{get;set;}
        public Decimal totalReceiptAmt{get;set;}
        public String accountNumber{get;set;}
        public String ifscCode{get;set;}
        public String accbankName{get;set;}
        public String priAppAddress{get;set;}
        public String unitType{get;set;}
        public String floorName{get;set;}
        public String blockName{get;set;}
        public String superBuiltupArea{get;set;}
        public Decimal totalPaymentAmt{get;set;}
    }
    public class agreementCopyDynamicTable{
        public List<receiptData> receipt{get;set;}
        public List<paySchData> payment{get;set;}
    }
    public class receiptData{
        public Integer sl{get;set;}
        public String receiptNo{get;set;}
        public Date receiptDate{get;set;}
        public String receiptBank{get;set;}
        public Decimal Amount{get;set;}
    }
    public class paySchData{
        public String Name{get;set;}
        public Decimal amount{get;set;}
    }

    //generate data sheet document
    public class dataSheetFormatWrapper{
        public List<signersList> signers{get;set;}
        public String display_on_page = 'FIRST';
        public String expire_in_days = '1';
        public String file_name{get;set;}
        public List<dataSheetTemplateList> templates{get;set;}
        public Boolean send_sign_link = false;
        public Boolean notify_signers = false;
    }

    public class dataSheetTemplateList{
        public String template_key{get;set;}
        public dataSheetTemplateValues template_values{get;set;}
    }

    public class dataSheetTemplateValues{
        public String app1Name{get;set;}
        public String app2Name{get;set;}
        public String app3Name{get;set;}
        public String app4Name{get;set;}
        public String app5Name{get;set;}
        public String app6Name{get;set;}
        public String app1SoDoWo{get;set;}
        public String app2SoDoWo{get;set;}
        public String app3SoDoWo{get;set;}
        public String app4SoDoWo{get;set;}
        public String app5SoDoWo{get;set;}
        public String app6SoDoWo{get;set;}
        public String app1Age{get;set;}
        public String app2Age{get;set;}
        public String app3Age{get;set;}
        public String app4Age{get;set;}
        public String app5Age{get;set;}
        public String app6Age{get;set;}
        public Date app1Dob{get;set;}
        public Date app2Dob{get;set;}
        public Date app3Dob{get;set;}
        public Date app4Dob{get;set;}
        public Date app5Dob{get;set;}
        public Date app6Dob{get;set;}
        public String app1Pan{get;set;}
        public String app2Pan{get;set;}
        public String app3Pan{get;set;}
        public String app4Pan{get;set;}
        public String app5Pan{get;set;}
        public String app6Pan{get;set;}
        public String app1Email{get;set;}
        public String app2Email{get;set;}
        public String app3Email{get;set;}
        public String app4Email{get;set;}
        public String app5Email{get;set;}
        public String app6Email{get;set;}
        public String app1Address{get;set;}
        public String app2Address{get;set;}
        public String app3Address{get;set;}
        public String app4Address{get;set;}
        public String app5Address{get;set;}
        public String app6Address{get;set;}
        public String blockAndUnitNo{get;set;}
        public String unitType{get;set;}
        public String priAppNumber{get;set;}
        public Decimal superBuiltupArea{get;set;}
        public String carParking{get;set;}
        public Decimal twoWheeler{get;set;}
        public Decimal basicPrice{get;set;}
        public Decimal floorRise{get;set;}
        public Decimal premiumCharges{get;set;}
    }

    //generate debit note document wrapper, use signersList as common element
    public class generateDebitNoteWrapper{
        public List<signersList> signers{get;set;}
        public String display_on_page = 'FIRST';
        public String expire_in_days = '1';
        public String file_name{get;set;}
        public List<debitNoteTemplateList> templates{get;set;}
        public Boolean send_sign_link = false;
        public Boolean notify_signers = false;
    }

    public class debitNoteTemplateList{
        public String template_key{get;set;}
        public debitNoteTemplateValues template_values{get;set;}
    }

    public class debitNoteTemplateValues{
        public String allApplicantNames{get;set;}
        public String mainApplicantPinCode{get;set;}
        public String unitNumber{get;set;}
        public Date todayDate{get;set;}
        public String projectName{get;set;}
        public String blockName{get;set;}
        public Decimal debitAmount{get;set;}
        public String currentUser{get;set;}
        public String debitNoteDescription{get;set;}
        public String nextPaymentSchName{get;set;}
    }
    
    //generate vehicle parking document wrapper, use signersList as common element
    public class generateVehicleParkingWrapper{
        public List<signersList> signers{get;set;}
        public String display_on_page = 'FIRST';
        public String expire_in_days = '1';
        public String file_name{get;set;}
        public List<vehicleParkingTemplateList> templates{get;set;}
        public Boolean send_sign_link = false;
        public Boolean notify_signers = false;
    }

    public class vehicleParkingTemplateList{
        public String template_key{get;set;}
    }
    
    //generate contact list of service providers document wrapper, use signersList as common element
    public class generateContactListWrapper{
        public List<signersList> signers{get;set;}
        public String display_on_page = 'FIRST';
        public String expire_in_days = '1';
        public String file_name{get;set;}
        public List<serviceContactsTemplateList> templates{get;set;}
        public Boolean send_sign_link = false;
        public Boolean notify_signers = false;
    }

    public class serviceContactsTemplateList{
        public String template_key{get;set;}
    }
    
    //generate party hall rules document wrapper, use signersList as common element
    public class generatePartyHallRulesWrapper{
        public List<signersList> signers{get;set;}
        public String display_on_page = 'FIRST';
        public String expire_in_days = '1';
        public String file_name{get;set;}
        public List<partyHallRulesTemplateList> templates{get;set;}
        public Boolean send_sign_link = false;
        public Boolean notify_signers = false;
    }

    public class partyHallRulesTemplateList{
        public String template_key{get;set;}
        public partyHallRulesTemplateValues template_values{get;set;}
    }

    public class partyHallRulesTemplateValues{
        public String ResidentPhone{get;set;}
        public String ResidentName{get;set;}
        public String ResidentAltPhone{get;set;}
        public Date OppBookingDate{get;set;}
        public String UnitNumber{get;set;}
    }
    
    //generate move-in move-out policy document wrapper, use signersList as common element
    public class generateMoveInOutWrapper{
        public List<signersList> signers{get;set;}
        public String display_on_page = 'FIRST';
        public String expire_in_days = '1';
        public String file_name{get;set;}
        public List<moveInOutTemplateList> templates{get;set;}
        public Boolean send_sign_link = false;
        public Boolean notify_signers = false;
    }

    public class moveInOutTemplateList{
        public String template_key{get;set;}
        public moveInOutTemplateValues template_values{get;set;}
    }

    public class moveInOutTemplateValues{
        public String ContactMobile{get;set;}
        public String ResidentName{get;set;}
        public String ContactEmail{get;set;}
        public Date ApplicationDate{get;set;}
        public String UnitNumber{get;set;}
    }

    //generate demand letter document wrapper, use signersList as common element
    public class generateDemandLetter{
        public List<signersList> signers{get;set;}
        public String display_on_page = 'FIRST';
        public String expire_in_days = '1';
        public String file_name{get;set;}
        public List<demandTemplateList> templates{get;set;}
        public Boolean send_sign_link = false;
        public Boolean notify_signers = false;
    }

    public class demandTemplateList{
        public String template_key{get;set;}
        public demandTemplateValues template_values{get;set;}
        public demandDynamicTable template_table_values{get;set;}
    }

    public class demandTemplateValues{
        public String UnitNumber{get;set;}
        public Date PaymentScheduleDueDate{get;set;}
        public Decimal PaymentScheduleDueAmount{get;set;}
        public String Address1{get;set;}
        public String TowerName{get;set;}
        public String todayDate{get;set;}
        public String balanceAmountInWords{get;set;}
        public String ProjectName{get;set;}
        public String CoAppicantNames{get;set;}
        public String MainAppicantName{get;set;}
        public String TridasaFullName{get;set;}
        public String PaymentScheduleName{get;set;}
    }

    public class demandDynamicTable{
        public List<paymentScheduleList> paymentSchedule{get;set;}
    }

    public class paymentScheduleList{
        public Decimal totalDue{get;set;}
        public Decimal totalPayment{get;set;}
        public Decimal balanceDue{get;set;}
        public Date dueDate{get;set;}
    }

    public class signersList{
        public String identifier{get;set;}
        public String signer_tag{get;set;}
        public String name{get;set;}
        public String sign_type{get;set;}
    }

    //generate vetted receipt document wrapper, use signersList as common element
    public class generateVettedReceipt{
        public List<signersList> signers{get;set;}
        public String display_on_page = 'FIRST';
        public String expire_in_days = '1';
        public String file_name{get;set;}
        public List<receiptTemplateList> templates{get;set;}
        public Boolean send_sign_link = false;
        public Boolean notify_signers = false;
    }

    public class receiptTemplateList{
        public String template_key{get;set;}
        public receiptTemplateValues template_values{get;set;}
        public receiptDynamicTable template_table_values{get;set;}
    }

    public class receiptTemplateValues{
        public String ProjectName{get;set;}
        public String companyName{get;set;}
        public String mainReceiptAmountInWords{get;set;}
        public String unitNumber{get;set;}
        public String custwebsite{get;set;}
        public String custName{get;set;}
        public Date today1{get;set;}
        public Decimal fAmt{get;set;}
        public Date mainReceiptDate{get;set;}
        public String phoneNo{get;set;}
        public Decimal mainReceiptAmount{get;set;}
        public String receiptCinNo{get;set;}
        public String companyAddress{get;set;}
        public String receiptNo{get;set;}
        public String floorNumber{get;set;}
        public String custId{get;set;}
        public String custEmailId{get;set;}
        public String towerName{get;set;}
        public String mainReceiptBank{get;set;}
        public String reraNumber{get;set;}
    }

    public class receiptDynamicTable{
        public List<receiptTableList> receiptTable{get;set;}
    }

    public class receiptTableList{
        public String instrumentMode{get;set;}
        public Date receiptDate{get;set;}
        public String instrumentNo{get;set;}
        public String receiptBank{get;set;}
        public Decimal receiptAmount{get;set;}
        public Decimal receiptCgst{get;set;}
        public Decimal receiptSgst{get;set;}
        public Decimal receiptTotalAmount{get;set;}
    }
    
    //generate Allotment Letter document wrapper, use signersList as common element
    public class generateAllotmentLetter{
        public List<signersList> signers{get;set;}
        public String display_on_page = 'FIRST';
        public String expire_in_days = '1';
        public String file_name{get;set;}
        public List<allotmentLetterTemplateList> templates{get;set;}
        public Boolean send_sign_link = false;
        public Boolean notify_signers = false;
    }

    public class allotmentLetterTemplateList{
        public String template_key{get;set;}
        public allotmentLetterTemplateValues template_values{get;set;}
        public allotmentLetterDynamicTable template_table_values{get;set;}
    }

    public class allotmentLetterTemplateValues{
        public String applicantName{get;set;}
        public String coApplicantName{get;set;}
        public String addressName{get;set;}
        public String pinCodeNumber{get;set;}
        public String emailId{get;set;}
        public String phoneNumber{get;set;}
        public String SNNEStateFelicity{get;set;}
        public String bloackName{get;set;}
        public String companyName{get;set;}
        public String companyAddress{get;set;}
        public Decimal floorName{get;set;}
        public String apartmentNo{get;set;}
        public String apartmentTypeName{get;set;}
        public Decimal saleableAreaName{get;set;}
        public String carParkingDetails{get;set;}
        public String loginUserName{get;set;}
        public Decimal totalFlatCost{get;set;}
    }

    public class allotmentLetterDynamicTable{
        public List<paymentScheduleTable> paymentScheduleTable{get;set;}
    }

    public class paymentScheduleTable{
        public Integer SlNo{get;set;}
        public String installment{get;set;}
        public String sequence{get;set;}
        public Decimal milestone{get;set;}
        public Decimal amount{get;set;}
    }

    //Generate Serenity Gardens Receipt Template
    public class generateReceipt{
        public List<signersList> signers{get;set;}
        public String display_on_page = 'FIRST';
        public String expire_in_days = '1';
        public String file_name{get;set;}
        public List<serenityReceiptTemplateList> templates{get;set;}
        public Boolean send_sign_link = false;
        public Boolean notify_signers = false;
    }

    public class serenityReceiptTemplateList{
        public String template_key{get;set;}
        public serenityReceiptTemplateValues template_values{get;set;}
    }

    public class serenityReceiptTemplateValues{
        public String receiptNo{get;set;}
        public String receiptDate{get;set;}
        public String projectName{get;set;}
        public String customerName{get;set;}
        public String coApplicantName{get;set;}
        public String clientAddress{get;set;}
        public String amountInWords{get;set;}
        public Decimal amount {get; set;}
        public String modeOfPayment{get;set;}
        public String unitName{get;set;}
        public String unitType{get;set;}
        public String referenceNo{get;set;}
        public String chequeDate{get;set;}
        public String bankName{get;set;}
        public String typeOfUnit{get;set;}
        public String flatNo{get;set;}
        public String unitNo{get;set;}
        public String blockName{get;set;}
        public String amountValues{get;set;}
        public String loginUserName{get;set;}
        public String exactTime{get;set;}
        public String todayDate{get;set;}
        public String companyName{get;set;}
        public String companyAddress{get;set;}
        public String companyEmail{get;set;}
    }

    //Generate StatementOfAccount
    public class generateStatement{
        public List<signersList> signers{get;set;}
        public String display_on_page = 'FIRST';
        public String expire_in_days = '1';
        public String file_name{get;set;}
        public List<accountStatementTemplateList> templates{get;set;}
        public Boolean send_sign_link = false;
        public Boolean notify_signers = false;
    }

    public class accountStatementTemplateList{
        public String template_key{get;set;}
        public accountTemplateValues template_values{get;set;}
        public accountScheduleDynamicTable template_table_values{get;set;}
    }

    public class accountTemplateValues{
        public String todayDate{get;set;}
        public String customerName{get;set;}
        public String customerAddress{get;set;}
        public String projectName{get;set;}
        public String unitNo{get;set;}
        // public String blockNo{get;set;}
        public String towerCode{get;set;}
        public String generatedTime{get;set;}
        public String userName{get;set;}
        public Decimal oppFinalBalance{get;set;}
        public String todayTime {get;set;}
        public Decimal FinalReceiptAmount{get;set;}
        public Decimal finalAmountCd{get;set;}
        public Decimal finalAmountTaxCd{get;set;}
        public Decimal finalTotalAmountCd{get;set;}
        public Decimal totalBalancePaidTwrdUnit{get;set;}
        public Decimal totalPaidTillDate { get; set; }
        public Decimal totalScheduleAmount{get;set;}
        
    }

    public class accountScheduleDynamicTable{
        public List<statementOfAccountTable> statementOfAccountTable{get;set;}
        public List<statementOfScheduleTable> statementOfScheduleTable{get;set;}
        public List<statementOfReceipt> statementOfReceipt{get;set;}
        public List<statementOfReceiptTotal> statementOfReceiptTotal{get;set;}
        public List<statementOfReceiptCreditDebit> statementOfReceiptCreditDebit{get;set;}
    }

    public class statementOfAccountTable{
        public String particularData{get;set;}
        public Decimal totalBilled{get;set;}
        public Decimal amountReceived{get;set;}
        public Decimal amountBalance{get;set;}  
    }

    public class statementOfScheduleTable{
        public String Total{get;set;}
        public Decimal FinaltotalBilled{get;set;}
        public Decimal FinalamountReceived{get;set;}
        public Decimal FinalamountBalance{get;set;}

    }

    public class statementOfReceipt{
        public String receiptNo{get;set;}
        public String receiptDate{get;set;}
        public String instrumentNo{get;set;}
        public String instrumentDate{get;set;}
        public String paymentCategory{get;set;}
        public String bankName{get;set;}
        public Decimal amount{get;set;}


    }

    public class statementOfReceiptCreditDebit{
        public String receiptTypeCD{get;set;}
        public String receiptNoCD{get;set;}
        public String receiptDescCD{get;set;}
        public Decimal receiptAmountCD{get;set;}
        public Decimal receiptTaxCD{get;set;}
        public Decimal receiptTotalAmountCD{get;set;}

    }

    public class statementOfReceiptTotal{
        public Decimal FinalAmount{get;set;}
        public Decimal finalAmountCd{get;set;}
        public Decimal finalAmountTaxCd{get;set;}
        public Decimal finalTotalAmountCd{get;set;}
    }

    //Generate Demand Letter
    public class demandLetterTemplate{
        public List<signersList> signers{get;set;}
        public String display_on_page = 'FIRST';
        public String expire_in_days = '1';
        public String file_name{get;set;}
        public List<demandLetterTemplateValuesList> templates{get;set;}
        public Boolean send_sign_link = false;
        public Boolean notify_signers = false;
    }

    public class demandLetterTemplateValuesList{
        public String template_key{get;set;}
        public demandLetterTemplateValues template_values{get;set;}
        public demandLetterPaymentScheduleTable template_table_values{get;set;}
    }

    public class demandLetterTemplateValues{
        public String TodayDate{get;set;}
        public String customerName{get;set;}
        public String customerAddress{get;set;}
        public String customerPincode{get;set;}
        public String mobileNo{get;set;}
        // public String paymentScheduleName{get;set;}
        public String projectName{get;set;}
        public String bankName{get;set;}
        public Decimal totalTdsPaidTillDate{get;set;}
        public String accountNo{get;set;}
        public String ifscCode{get;set;}
        public Date dueDate{get;set;}
        public String currentUser{get;set;}
        public String exactTime{get;set;}

        public String coApplicantNames{get;set;}
        public String paymentScheduleName{get;set;}
        public String dueDateLast{get; set;}
        public String blockName{get;set;}
        public String unitName{get;set;}
        public String loggedInUser{get;set;}
        public Decimal FinalScheduleAmount{get;set;}
        public Decimal FinallessTotalAmount{get;set;}
        public Decimal FinallessTdsAmount{get;set;}
        public Decimal FinalbalancePaybleAmount{get;set;}        
        public Decimal totalAmountInclusiveOfTax{get;set;}
    }

    public class demandLetterPaymentScheduleTable{
        public List<demandLetterTable> DemandLetterTable{get;set;}
        public List<demandLetterTotal> DemandLetterTotalTable{get;set;}
        public List<creditDebitTableRow> CreditDebitTable{get;set;}
    }

    public class demandLetterTable{
        public String bookingAgreementToSell{get;set;}
        public Decimal showValueIn{get;set;}
        public String dueDate{get;set;}
        public Decimal dueAmount{get;set;}
        public Decimal AgreementValue{get;set;}
        public Decimal taxesAmout{get;set;}
        public Decimal totalScheduledDueAmount{get;set;}
    }

    public class demandLetterTotal{
        public Decimal FinalScheduleAmount{get;set;}
        public Decimal FinallessTotalAmount{get;set;}
        public Decimal FinallessTdsAmount{get;set;}
        public Decimal FinalbalancePaybleAmount{get;set;}
    }

     public class creditDebitTableRow{
        public String ReceiptType{get;set;}     
        public String Description{get;set;} 
        public Decimal Amount{get;set;}      
        public Decimal Tax{get;set;}
        public Decimal Total{get;set;}   
    }

    //Generate CostSheet
    public class costSheetTemplate{
        public List<signersList> signers{get;set;}
        public String display_on_page = 'FIRST';
        public String expire_in_days = '1';
        public String file_name{get;set;}
        public List<costSheetTemplateValuesList> templates{get;set;}
        public Boolean send_sign_link = false;
        public Boolean notify_signers = false;
    }

    public class costSheetTemplateValuesList{
        public String template_key{get;set;}
        public costSheetTemplateValues template_values{get;set;}
        public costSheetPaymentTable template_table_values{get;set;}
    }

    public class costSheetTemplateValues{
        public String unitNo{get;set;}
        public String typeOfUnit{get;set;}
        public Integer floorNumber{get;set;}
        public Decimal superBuiltupArea{get;set;}
        public Integer basicPrice{get;set;}
        public Integer apartmentPrice{get;set;}
        public Decimal cgstData{get;set;}
        public Decimal sgstData{get;set;}
        public Decimal totalValue{get;set;}
        public Decimal totalAmount{get;set;}
        public String addressDetail{get;set;}
        public String customerName{get;set;}
        public String projectName{get;set;}
        public String companyName{get;set;}
        public String terraceArea{get;set;}
        public Decimal basicPriceValue{get; set;}
        
        
    }

    public class costSheetPaymentTable{
        public List<costSheetAssociationTable> costSheetAssociation{get;set;}
        public List<costSheetTable> costSheetTable{get;set;}
    }

    public class costSheetAssociationTable{
        public String floorRise{get;set;}
        public Decimal amount{get;set;}
        
    }

    public class costSheetTable{
        public String breakup{get;set;}
        public String paymentSchedule{get;set;}
        public Date installDate{get;set;}
        public Decimal amountValue{get;set;}   
    }

    //Generate Sale and Construction Agreement
    public class saleConsAgreement{
        public List<signersList> signers{get;set;}
        public String display_on_page = 'FIRST';
        public String expire_in_days = '1';
        public String file_name{get;set;}
        public List<constructionAgreementValueList> templates{get;set;}
        public Boolean send_sign_link = false;
        public Boolean notify_signers = false;
    }

    public class constructionAgreementValueList{
        public String template_key{get;set;}
        public constructionTemplateValues template_values{get;set;}
        public constructionPaymentTable template_table_values{get;set;}
    }

    public class constructionTemplateValues{
        public String apartmentNo{get;set;}
        public String bedRoomNo{get;set;}
        public String contact{get;set;}
        public Decimal area{get;set;}
        public Boolean parkingCover{get;set;}
        public Boolean parkingOpen{get;set;}
        public Boolean twoWheeler{get;set;}
        public Decimal basicPrice{get;set;}
        public String floorRise{get;set;}
        public String poolFacing{get;set;}
        public String lakeFacing{get;set;}
        public String draftDetail{get;set;}
        public String bankName{get;set;}
        public String ddNo{get;set;}
        public Date dateNo{get;set;}
        public Decimal amt{get;set;}
        public String loginUser1{get;set;}
        public String loginUser2{get;set;}
        public String loginUser3{get;set;}
    }

    public class constructionPaymentTable{
        public List<saleConstructionFirstApplicantTable> applicantTable{get;set;}
        public List<saleConstructionCoApplicantTable> applicantTable2{get;set;}
        public List<constructionAssociationTable> cSA{get;set;}
    }

    public class saleConstructionFirstApplicantTable{
        public String applicantName{get;set;}
        public String relativeName{get;set;}
        public Integer age{get;set;}
        public Date dob{get;set;}
        public String aadhar{get;set;}
        public String pan{get;set;}
        public String email{get;set;}
        public String address{get;set;}
    }

    public class saleConstructionCoApplicantTable{
        public String applicantName{get;set;}
        public String relativeName{get;set;}
        public Integer age{get;set;}
        public String aadhar{get;set;}
        public Date dob{get;set;}
        public String pan{get;set;}
        public String email{get;set;}
        public String address{get;set;}
    }

    public class constructionAssociationTable{
        public Integer SlNo{get;set;}
        public String floorRise{get;set;}
        public Decimal amount{get;set;}
    }

    //Generate Welcome Kit
    public class getWelcomeKit{
        public List<signersList> signers{get;set;}
        public String display_on_page = 'FIRST';
        public String expire_in_days = '1';
        public String file_name{get;set;}
        public List<wlcomeKitValueList> templates{get;set;}
        public Boolean send_sign_link = false;
        public Boolean notify_signers = false;
    }

    public class wlcomeKitValueList{
        public String template_key{get;set;}
        public welcomeKitTemplateValues template_values{get;set;}
        public welcomeKitTable template_table_values{get;set;}
    }

    public class welcomeKitTemplateValues{
        public Date todayDate{get;set;}
        public String unitNumber{get;set;}
        public String loggedInUserName{get;set;}
        public String allApplicantNames{get;set;}
        public Date bookingDate{get;set;}
        public String companyName{get;set;}
        public String companyAddress{get;set;}
        public String companyPan{get;set;}
        public String projectAddress{get;set;}
        public Decimal agreementValue{get;set;}
        public Decimal totalAmtCollected{get;set;}
        public Date allotmentLetterDate{get;set;}
        public String accountName{get;set;}
        public String accountNumber{get;set;}
        public String typeOfAccount{get;set;}
        public String bankName{get;set;}
        public String branchName{get;set;}
        public String ifscCode{get;set;}
    }

    public class welcomeKitTable{
        public List<legalDepartmentTable> legalDepartmentTable{get;set;}
        public List<snnAddress> snnAddressTable{get;set;}
        public List<snnBankDetails> snnBankDetailsTable{get;set;}
    }

    public class legalDepartmentTable{
        public String name{get;set;}
        public String executiveName{get;set;}
        public String mobileNo{get;set;}
        public String email{get;set;}
    }

    public class snnAddress{
        public String companyName{get;set;}
        public String officeAddress{get;set;}
        public String pan{get;set;}
        public String projectAddress{get;set;}
        public Decimal amountPaid{get;set;}
    }

    public class snnBankDetails{
        public String accountName{get;set;}
        public String accountNumber{get;set;}
        public String typeOfAccount{get;set;}
        public String bankName{get;set;}
        public String branch{get;set;}
        public String ifscCode{get;set;}
    }

    //Generate Home Owner's Manual
    public class getHomeOwners{
        public List<signersList> signers{get;set;}
        public String display_on_page = 'FIRST';
        public String expire_in_days = '1';
        public List<homeOwnerList> templates{get;set;}
        public String file_name{get;set;}
        public Boolean send_sign_link = false;
        public Boolean notify_signers = false;
    }

    public class homeOwnerList{
        public String template_key{get;set;}
    }

    //Generate HandOver -Format-GRandeur
    public class getHandOver{
        public List<signersList> signers{get;set;}
        public String display_on_page = 'FIRST';
        public String expire_in_days = '1';
        public String file_name{get;set;}
        public List<handOverValueList> templates{get;set;}
        public Boolean send_sign_link = false;
        public Boolean notify_signers = false;
    }

    public class handOverValueList{
        public String template_key{get;set;}
        public handOverTemplateValues template_values{get;set;}
    }

    public class handOverTemplateValues{
        public String unitNo{get;set;}
        public String type{get;set;}
        public Date closeDate{get;set;}
    }

        public class generateBookingFormDocs {
        public List<signersList> signers { get; set; }
        public String display_on_page = 'FIRST';
        public String expire_in_days = '1';
        public String file_name { get; set; }
        public List<bookingFormTemplateList> templates { get; set; } //
        public Boolean send_sign_link = false;
        public Boolean notify_signers = false;
    }

    public class bookingFormTemplateList {
        public String template_key { get; set; }
        public bookingFormTemplateValues template_values { get; set; }// 
    }

    public class bookingFormTemplateValues {

        public String applicationDate { get; set; }
        public String projectName { get; set; }
        public String reraNo { get; set; }
        public String unitNo { get; set; }
        public String unitType{ get; set; }
        public String superBuiltArea { get; set; }
        
        public String firstApplicantName { get; set; }
        public String firstCompanyAuthorized { get; set; }
        public String firstRelation { get; set; }
        public String firstDob{ get; set; }
        public String firstSpouseName { get; set; }
        public String firstSpouseDob { get; set; }
        public String firstAnniDate { get; set; }
        public String firstResidentStatus { get; set; }
        public String firstCOR { get; set; }
        public String firstPan { get; set; }
        public String firstPermanAdd { get; set; }
        public String firstPermPinCode { get; set; }
        public String firstAddComm { get; set; }
        public String firstCommPinCode { get; set; }
        public String firstPrimaryCont { get; set; }
        public String firstAltCont { get; set; }
        public String firstEmail { get; set; }
        public String firstOfficialEmail { get; set; }
        public String firstPassportNo { get; set; }
        public String firstIndustry { get; set; }
        public String firstCompanyName { get; set; }
        public String firstLocation { get; set; }
        public String firstDesignation { get; set; }

        public String firstReferalName { get; set; }
        public String firstReferalNumb { get; set; }
        public String firstReferalEmail { get; set; }
        public String firstReferalProject { get; set; }

        public String totalReciptAmount { get; set; }
        public String totalReciptAmountWords { get; set; }

        public String salesuserName { get; set; }
        public String crmUser { get; set; }
        public Date todayDate{get;set;}
        public String allotmentLetterDate { get; set; }
        public String oppChanelPartName { get; set; }
        
        public String secondApplicantName { get; set; }
        public String secondCompanyAuthorized { get; set; }
        public String secondRelation { get; set; }
        public String secondDob{ get; set; }
        public String secondSpouseName { get; set; }
        public String secondSpouseDob { get; set; }
        public String secAnniDate { get; set; }
        public String secondResidentStatus { get; set; }
        public String secondCOR { get; set; }
        public String secondPan { get; set; }
        public String secondPermanAdd { get; set; }
        public String secondPermPinCode { get; set; }
        public String secondAddComm { get; set; }

        public String secondCommPinCode { get; set; }
        public String secondPrimaryCont { get; set; }
        public String secondEmail { get; set; }
        public String secondOfficialEmail { get; set; }
        public String secondIndustry { get; set; }
        public String secondCompanyName { get; set; }
        public String secondLocation { get; set; }
        public String secondDesignation { get; set; }

        public String secondAnnualHouseHoldIncome { get; set; }
        public String secondPurposeOfPurchase { get; set; }
        public String secondSourceOfFunding { get; set; }
        public String secondSourceOfInformation { get; set; }
        public String secondWorkRole { get; set; }
        public String secondRefferedBy { get; set; }

        public String secondReferalName { get; set; }
        public String secondReferalNumb { get; set; }
        public String secondReferalEmail { get; set; }
        public String secondReferalProject { get; set; }
        
        public String thirdApplicantName { get; set; }
        public String thirdCompanyAuthorized { get; set; }
        public String thirdRelation { get; set; }
        public String thirdDob{ get; set; }
        public String thirdSpouseName { get; set; }
        public String thirdSpouseDob { get; set; }
        public String thirdResidentStatus { get; set; }
        public String thirdPan { get; set; }
        public String thirdPermanAdd { get; set; }
        public String thirdPermPinCode { get; set; }
        public String thirdAddComm { get; set; }
        public String thirdCommPinCode { get; set; }
        public String thirdPrimaryCont { get; set; }
        public String thirdEmail { get; set; }
        public String thirdOfficialEmail { get; set; }
        public String thirdPassportNo { get; set; }
        public String thirdIndustry { get; set; }
        public String thirdCompanyName { get; set; }
        public String thirdLocation { get; set; }
        public String thirdDesignation { get; set; }

        public String thirdAnnualHouseHoldIncome { get; set; }
        public String thirdPurposeOfPurchase { get; set; }
        public String thirdSourceOfFunding { get; set; }
        public String thirdSourceOfInformation { get; set; }
        public String thirdWorkRole { get; set; }
        public String thirdRefferedBy { get; set; }

        public String thirdReferalName { get; set; }
        public String thirdReferalNumb { get; set; }
        public String thirdReferalEmail { get; set; }
        public String thirdReferalProject { get; set; }

        public String fourthApplicantName { get; set; }
        public String fourthCompanyAuthorized { get; set; }
        public String fourthRelation { get; set; }
        public String fourthDob{ get; set; }
        public String fourthSpouseName { get; set; }
        public String fourthSpouseDob { get; set; }
        public String fourthAnnivDate { get; set; }
        public String fourthResidentStatus { get; set; }
        public String fourthCOR { get; set; }
        public String fourthPan { get; set; }
        public String fourthPermanAdd { get; set; }
        public String fourthPermPinCode { get; set; }
        public String fourthAddComm { get; set; }
        public String fourthCommPinCode { get; set; }
        public String fourthPrimaryCont { get; set; }
        public String fourthAltCont { get; set; }
        public String fourthEmail { get; set; }
        public String fourthOfficialEmail { get; set; }
        public String fourthPassportNo { get; set; }
        public String fourthIndustry { get; set; }
        public String fourthCompanyName { get; set; }
        public String fourthLocation { get; set; }
        public String fourthDesignation { get; set; }

        public String fourthAnnualHouseHoldIncome { get; set; }
        public String fourthPurposeOfPurchase { get; set; }
        public String fourthSourceOfFunding { get; set; }
        public String fourthSourceOfInformation { get; set; }
        public String fourthWorkRole { get; set; }
        public String fourthRefferedBy { get; set; }

        public String fourthReferalName { get; set; }
        public String fourthReferalNumb { get; set; }
        public String fourthReferalEmail { get; set; }
        public String fourthReferalProject { get; set; }        

        public String fifthApplicantName { get; set; }
        public String fifthCompanyAuthorized { get; set; }
        public String fifthRelation { get; set; }
        public String fifthDob{ get; set; }
        public String fifthSpouseName { get; set; }
        public String fifthSpouseDob { get; set; }
        public String fifthAnniDate { get; set; }
        public String fifthResidentStatus { get; set; }
        public String fifthCOR { get; set; }
        public String fifthPan { get; set; }
        public String fifthPermanAdd { get; set; }
        public String fifthPermPinCode { get; set; }
        public String fifthAddComm { get; set; }
        public String fifthCommPinCode { get; set; }
        public String fifthPrimaryCont { get; set; }
        public String fifthAltCont { get; set; }
        public String fifthEmail { get; set; }
        public String fifthOfficialEmail { get; set; }
        public String fifthPassportNo { get; set; }
        public String fifthIndustry { get; set; }
        public String fifthCompanyName { get; set; }
        public String fifthLocation { get; set; }
        public String fifthDesignation { get; set; }
        public String fifthAnnualHouseHoldIncome { get; set; }
        public String fifthPurposeOfPurchase { get; set; }
        public String fifthSourceOfFunding { get; set; }
        public String fifthSourceOfInformation { get; set; }
        public String fifthWorkRole { get; set; }
        public String fifthRefferedBy { get; set; }

        public String fifthReferalName { get; set; }
        public String fifthReferalNumb { get; set; }
        public String fifthReferalEmail { get; set; }
        public String fifthReferalProject { get; set; }
        
        public String sixthApplicantName { get; set; }
        public String sixthCompanyAuthorized { get; set; }
        public String sixthRelation { get; set; }
        public String sixthDob{ get; set; }
        public String sixthSpouseName { get; set; }
        public String sixthSpouseDob { get; set; }
        public String sixthAnnivDate { get; set; }
        public String sixthResidentStatus { get; set; }
        public String sixthCOR { get; set; }
        public String sixthPan { get; set; }
        public String sixthPermanAdd { get; set; }
        public String sixthPermPinCode { get; set; }
        public String sixthAddComm { get; set; }
        public String sixthCommPinCode { get; set; }
        public String sixthPrimaryCont { get; set; }
        public String sixthAltCont { get; set; }
        public String sixthEmail { get; set; }
        public String sixthOfficialEmail { get; set; }
        public String sixthPassportNo { get; set; }
        public String sixthIndustry { get; set; }
        public String sixthCompanyName { get; set; }
        public String sixthLocation { get; set; }
        public String sixthDesignation { get; set; }

        public String sixthAnnualHouseHoldIncome { get; set; }
        public String sixthPurposeOfPurchase { get; set; }
        public String sixthSourceOfFunding { get; set; }
        public String sixthSourceOfInformation { get; set; }
        public String sixthWorkRole { get; set; }
        public String sixthRefferedBy { get; set; }

        public String sixthReferalName { get; set; }
        public String sixthReferalNumb { get; set; }
        public String sixthReferalEmail { get; set; }
        public String sixthReferalProject { get; set; }

        public String totalAgreementValues { get; set; }
        public String superBuiltUpArea { get; set; } 
        public String towerCode { get; set; } 
        public String carpetArea { get; set; }
        public String floorNumber { get; set; } 
        public String terraceArea { get; set; }
        public String sumOfbaconyAndCarpetArea{ get; set; }
        public String numberofCarParks { get; set; }
        public String twoWheeler { get; set; }

        public String otherOnOpp { get; set; }
        public String receiptPayment { get; set; } 
        public String receiptDate { get; set; } 
        public String receiptBank { get; set; } 
      

    }

    //welcome letter 
    public class WelcomeLetterWrapper {
        public List<signersList> signers { get; set; }
        public String display_on_page = 'FIRST';
        public String expire_in_days  = '1';
        public String file_name       { get; set; }
        public List<WelcomeLetterTemplateList> templates { get; set; }
        public Boolean send_sign_link = false;
        public Boolean notify_signers = false;
    }

    public class WelcomeLetterTemplateList {
        public String template_key { get; set; }
        public WelcomeLetterTemplateValues template_values { get; set; }
        public WelcomeLetterTableToAdd template_table_values { get; set; }
        
    }

    public class WelcomeLetterTableToAdd{
        public List<contactListTableRow> contactListTable{get;set;}
        public List<bankDetailsRow> bankDetailsTable{get;set;}

    }

    public class WelcomeLetterTemplateValues {
        public String salutationName     { get; set; }
        public String allApplicantDetails{ get; set; }
        public String unitName           { get; set; }
        public String towerCode          { get; set; }
        public String welcomeDate        { get; set; }
        public String projectName        { get; set; } 
        public String crmName            { get; set; }  
        public String crmEmail           { get; set; } 
        public String crmPhone           { get; set; }
        public String crmTitle           { get; set; }
        public String pronouns           { get; set; }
        public String companyName        { get; set; }
        public String companyAddress     { get; set; }
        public String companyEmail       { get; set; }
        public String bookingFormDate    { get; set; }
        public String companyPan         { get; set; }
        public String aosDate            { get; set; }
        public String projectBankActName { get; set; }
        public String projectAccntNumber { get; set; }
        public String bankType           { get; set; }
        public String bankName           { get; set; }
        public String bankBranch         { get; set; }
        public String bankIfsc           { get; set; }
        public String accntName          { get; set; }
        public String allotmentDate      { get; set; }
    }

    //!leagal department contact details
    public class contactListTableRow{ 
        public String deptName{get;set;}
        public String csEmailId{get;set;}
        public String execName{get;set;}
        public String cSMobileNo{get;set;}
    }

    public class bankDetailsRow{
        public String bankNameDetails {get; set; }
        public String bankContactPerson {get; set; }
        public String bankContacNo {get; set; }
        public String bankEmailId {get; set; }
    }

}