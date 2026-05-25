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
        public String modeOfPayment{get;set;}
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
        public Date todayDate{get;set;}
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
        public String TodayDate{get;set;}
        public String customerName{get;set;}
        public String customerAddress{get;set;}
        public String projectName{get;set;}
        public String unitNo{get;set;}
        public String blockNo{get;set;}
        public String generatedTime{get;set;}
        public String userName{get;set;}
        public Decimal oppFinalBalance{get;set;}
                public String towerCode{get;set;}
    }

    public class accountScheduleDynamicTable{
        public List<statementOfAccountTable> statementOfAccountTable{get;set;}
        public List<statementOfScheduleTable> statementOfScheduleTable{get;set;}
        public List<statementOfReceipt> statementOfReceipt{get;set;}
        public List<statementOfReceiptTotal> statementOfReceiptTotal{get;set;}
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

    public class statementOfReceiptTotal{
        public Decimal Finalamount{get;set;}
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
        public Date TodayDate{get;set;}
        public String customerName{get;set;}
        public String customerAddress{get;set;}
        public String customerPincode{get;set;}
        public String mobileNo{get;set;}
        public String SubjectName{get;set;}
        public String projectName{get;set;}
        public String bankName{get;set;}
        public String accountNo{get;set;}
        public String ifscCode{get;set;}
        public Date dueDate{get;set;}
        public String currentUser{get;set;}
        public String exactTime{get;set;}
        public String coApplicantNames{get;set;}
        public String paymentScheduleName{get;set;}
        public String blockName{get;set;}
        public String loggedInUser{get;set;}
        public Decimal FinalScheduleAmount{get;set;}
        public Decimal FinallessTotalAmount{get;set;}
        public Decimal FinallessTdsAmount{get;set;}
        public Decimal FinalbalancePaybleAmount{get;set;}
    }

    public class demandLetterPaymentScheduleTable{
        public List<demandLetterTable> DemandLetterTable{get;set;}
        public List<demandLetterTotal> DemandLetterTotalTable{get;set;}
    }

    public class demandLetterTable{
        public String bookingAgreementToSell{get;set;}
        public Decimal showValueIn{get;set;}
        public String dueDate{get;set;}
        public Decimal dueAmount{get;set;}
        public Decimal taxesAmout{get;set;}
        public Decimal totalScheduledDueAmount{get;set;}
    }

    public class demandLetterTotal{
        public Decimal FinalScheduleAmount{get;set;}
        public Decimal FinallessTotalAmount{get;set;}
        public Decimal FinallessTdsAmount{get;set;}
        public Decimal FinalbalancePaybleAmount{get;set;}
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
}