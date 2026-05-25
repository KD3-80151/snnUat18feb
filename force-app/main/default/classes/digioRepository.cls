public without Sharing class digioRepository {

    @AuraEnabled
    public static Opportunity checkAlreadyGenerated(String oppId){
        Opportunity oppDetails = new  Opportunity();
        try{
            System.debug('oppId::'+oppId);
            oppDetails = [SELECT Id,Name,AccountId,Unit__r.Unit_Name__c,Booking_Date__c,Project__r.Name,Unit__r.Floor__r.Blocks__r.Name,Unit__r.Floor__r.Name,Unit__r.Floor__r.Floor_No__c,Unit__r.Unit_Type__c,Unit__r.Super_Built_Up_Area_sq_ft__c,Allotment_Letter_Generated__c,OwnerId,(SELECT Id,Document_Id__c from Documents__r where Name = 'Post Sales' LIMIT 1) from Opportunity where Id =: oppId LIMIT 1];
            System.debug('oppDetails::'+oppDetails);
            return oppDetails;
        }Catch(Exception e){
            system.debug('Error in generateDemandLetterDocument===> ' + e.getMessage());
            system.debug('Error line ===> ' + e.getLineNumber());
        }
        return oppDetails;
    }

    @AuraEnabled
    public static docwrpperClass generateAgreementCopyDoc(String recordId){
        try{
            System.debug('recordId =======> ' + recordId);
            if(recordId != null){
                List<Opportunity> oppDetails = [SELECT Id,Name,Unit__r.Floor__r.Floor_No__c,Document_Id__c,Total_Amount_Collected__c,Total_Outstanding_Amount__c,Project__r.Name,Booking_Amount__c,Account.Salutation__c,Account.Name,Project__r.Bank_Name__c,Project__r.Account_Number__c,Project__r.IFSC_Code__c,Account.W_o_S_o_D_o__c,Account.Age__c,Account.Date_Of_Birth__c,Account.PAN__c,Account.Aadhaar_Number__c,Account.Email__c,Account.Address_for_Communication__Street__s ,Account.Address_for_Communication__City__s ,Account.Address_for_Communication__PostalCode__s ,Unit__r.Unit_Name__c,Unit__r.Floor__r.Blocks__r.Tower_Code__c,Unit__r.Unit_Type__c,Account.Phone,Unit__r.Super_Built_Up_Area_sq_ft__c,Unit__r.Base_Price_per_sqft__c,Unit__r.Floor_Rise__c,Agreement_Value__c, (SELECT Id,Name,Document_Id__c from Documents__r where Name = 'Root Folder' LIMIT 1) from Opportunity where Id =: recordId LIMIT 1];
                System.debug('oppDetails ===> ' + oppDetails);
                String parentFolderId;
                String docId;
                String subDocUrl = '';
                docwrpperClass wrapperRec = new docwrpperClass();
                if(!oppDetails.isEmpty() && oppDetails[0].Documents__r != null){
                    parentFolderId = oppDetails[0].Documents__r[0].Document_Id__c;
                    docId = oppDetails[0].Documents__r[0].Id;
                }
                
                Digio_Integration__c customData = Digio_Integration__c.getValues('Digio');
                List<Applicant__c> applicantList;
                List<Pricing_Element__c> carParkingList;
                List<Receipt__c> receiptDetails;
                List<Receipt__c> allReceiptList;
                List<Payment_Schedule__c> allPaymentSchList;
                List<String> carParkingTotal = new List<String>();
                Map<String,Decimal> carParkingTypeByCount = new Map<String,Decimal>();
                if(oppDetails[0].Id != null){
                    applicantList = [SELECT Id,Account__r.Name,Account__r.Salutation__c,Account__r.W_o_S_o_D_o__c,Account__r.Age__c,Account__r.Aadhaar_Number__c,Account__r.Date_Of_Birth__c,Account__r.PAN__c,Account__r.Email__c,Account__r.Permanent_Address__Street__s,Account__r.Permanent_Address__City__s,Account__r.Permanent_Address__PostalCode__s from Applicant__c where Opportunity__c =: oppDetails[0].Id Order by CreatedDate ASC LIMIT 1];
                    carParkingList = [SELECT Id,Quantity__c,Pricing_Element_Master__r.Parking_Type__c,Cost_Sheet__r.finalize_CostSheet__c from Pricing_Element__c WHERE Cost_Sheet__c != null AND Cost_Sheet__r.finalize_CostSheet__c = true AND Cost_Sheet__r.Opportunity__c =: oppDetails[0].Id AND (parking_Element__c = true OR Pricing_Element_Master__r.Parking_Type__c != null)];
                    System.debug('carParkingList ===> ' + carParkingList);
                    if(!carParkingList.isEmpty()){
                        for(Pricing_Element__c pri : carParkingList){
                            if(!carParkingTypeByCount.containsKey(pri.Pricing_Element_Master__r.Parking_Type__c)){
                                carParkingTypeByCount.put(pri.Pricing_Element_Master__r.Parking_Type__c, pri.Quantity__c);
                            }
                            carParkingTypeByCount.put( pri.Pricing_Element_Master__r.Parking_Type__c, carParkingTypeByCount.get(pri.Pricing_Element_Master__r.Parking_Type__c) + pri.Quantity__c );
                        }
                        if(carParkingTypeByCount != null){
                            for(String key : carParkingTypeByCount.keySet()){
                                if(carParkingTypeByCount.get(key) > 0){
                                    String carDetails = key + ' - ' + String.valueOf(carParkingTypeByCount.get(key));
                                    carParkingTotal.add(carDetails);
                                }
                            }
                        }
                    }
                    System.debug('carParkingTypeByCount ===> ' + carParkingTypeByCount);
                    receiptDetails = [SELECT Id,Receipt_Date__c,Cheque_Date__c,Cheque_Number__c,Branch__c,Bank__c,Amount__c from Receipt__c WHERE Opportunity__c =: oppDetails[0].Id AND Token_Amount__c = true];
                    allReceiptList = [SELECT Id,Receipt_Date__c,Cheque_Date__c,Cheque_Number__c,Amount__c,Bank__c,Mode_Of_Payment__c,DD_Number__c, JV_Reference_Number__c, Transaction_Reference_Number__c,Branch__c from Receipt__c WHERE Opportunity__c =: oppDetails[0].Id Order by CreatedDate ASC];
                    allPaymentSchList = [SELECT Id,Name,Agreement_Value__c from Payment_Schedule__c WHERE Opportunity__c =: oppDetails[0].Id Order by CreatedDate ASC];
                }
                if(customData.Authorization__c != null && customData.Endpoint_URL__c != null && customData.Agreement_Copy_Key__c != null && parentFolderId != null){
                    String endpoint = customData.Endpoint_URL__c + '/v2/client/template/multi_templates/create_sign_request';
                    DigioWrapperClass.agreementCopyWrapper generateDoc = new DigioWrapperClass.agreementCopyWrapper();
                    String fileName = oppDetails[0].Name + ' - Agreement Copy ' + String.valueOf(DateTime.now().getTime() / 1000);
                    generateDoc.file_name = fileName;
                    
                    DigioWrapperClass.signersList signer = new DigioWrapperClass.signersList();
                    signer.identifier = 'salesforce@snnestates.com';
                    signer.signer_tag = 'Signer 1';
                    signer.name = 'SNN Estates';
                    signer.sign_type = 'document_review';
                    generateDoc.signers = new List<DigioWrapperClass.signersList>{signer};
                    
                    DigioWrapperClass.agreementCopyTemplateList tempList = new DigioWrapperClass.agreementCopyTemplateList();
                    tempList.template_key = customData.Agreement_Copy_Key__c;
                    generateDoc.templates = new List<DigioWrapperClass.agreementCopyTemplateList>{tempList};

                    DigioWrapperClass.agreementCopyTemplateValues templateValues = new DigioWrapperClass.agreementCopyTemplateValues();
                    DateTime now = DateTime.now();
                    Date today = System.today();
                    DateTime dt = DateTime.newInstance(today, Time.newInstance(0, 0, 0, 0));
                    templateValues.currentDay           = now.format('EEEE');
                    templateValues.currentYear          = today.year();
                    templateValues.currentDate          = dt.format('MM/dd/yyyy');
                    templateValues.priAppName           = oppDetails[0].Account.Salutation__c != null ? oppDetails[0].Account.Salutation__c + '.' + oppDetails[0].Account.Name : oppDetails[0].Account.Name;
                    templateValues.priAppSoWo           = oppDetails[0].Account.W_o_S_o_D_o__c != null ? oppDetails[0].Account.W_o_S_o_D_o__c : '';
                    templateValues.priAppAge            = oppDetails[0].Account.Age__c != null ? String.valueOf(oppDetails[0].Account.Age__c) : '';
                    templateValues.priAppPan            = oppDetails[0].Account.PAN__c != null ? String.valueOf(oppDetails[0].Account.PAN__c) : '';
                    templateValues.priAppAadhar         = oppDetails[0].Account.Aadhaar_Number__c != null ? String.valueOf(oppDetails[0].Account.Aadhaar_Number__c) : '';
                    templateValues.priAppEmail          = oppDetails[0].Account.Email__c != null ? oppDetails[0].Account.Email__c : '';
                    templateValues.secAppName           = applicantList[0].Account__r.Salutation__c != null ? applicantList[0].Account__r.Salutation__c + '.' + applicantList[0].Account__r.Name : applicantList[0].Account__r.Name;
                    templateValues.secAppSoWo           = applicantList[0].Account__r.W_o_S_o_D_o__c != null ? applicantList[0].Account__r.W_o_S_o_D_o__c : '';
                    templateValues.secAppAge            = applicantList[0].Account__r.Age__c != null ? String.valueOf(applicantList[0].Account__r.Age__c) : '';
                    templateValues.secAppPan            = applicantList[0].Account__r.PAN__c != null ? String.valueOf(applicantList[0].Account__r.PAN__c) : '';
                    templateValues.secAppAadhar         = applicantList[0].Account__r.Aadhaar_Number__c != null ? String.valueOf(applicantList[0].Account__r.Aadhaar_Number__c) : '';
                    templateValues.secAppEmail          = applicantList[0].Account__r.Email__c != null ? applicantList[0].Account__r.Email__c : '';
                    templateValues.unitNumber           = oppDetails[0].Unit__r.Unit_Name__c != null ? oppDetails[0].Unit__r.Unit_Name__c : '';
                    templateValues.projectName          = oppDetails[0].Project__r.Name != null ? oppDetails[0].Project__r.Name : '';
                    templateValues.agreementValue       = oppDetails[0].Agreement_Value__c != null ? oppDetails[0].Agreement_Value__c : 0;
                    templateValues.agreementValueWords  = oppDetails[0].Agreement_Value__c != null ? NumberToWordsHelper.numberToEnglish(Integer.valueOf(oppDetails[0].Agreement_Value__c)) : 'Zero';
                    templateValues.carParkingDetails    = carParkingTotal.size() > 0 ? String.join(carParkingTotal, ',') : '';
                    templateValues.bookingAmount        = oppDetails[0].Booking_Amount__c != null ? oppDetails[0].Booking_Amount__c : 0;
                    templateValues.bookingAmountWords   = oppDetails[0].Booking_Amount__c != null ? NumberToWordsHelper.numberToEnglish(Integer.valueOf(oppDetails[0].Booking_Amount__c)) : 'Zero';
                    templateValues.chequeNo             = !receiptDetails.isEmpty() && receiptDetails[0].Cheque_Number__c != null ? receiptDetails[0].Cheque_Number__c : '..............';
                    templateValues.chequeDate           = !receiptDetails.isEmpty() && receiptDetails[0].Cheque_Date__c != null ? String.valueOf(receiptDetails[0].Cheque_Date__c) : '..............';
                    templateValues.bankName             = !receiptDetails.isEmpty() && receiptDetails[0].Bank__c != null ? receiptDetails[0].Bank__c : '..............';
                    templateValues.branchName           = !receiptDetails.isEmpty() && receiptDetails[0].Branch__c != null ? receiptDetails[0].Branch__c : '..............';
                    templateValues.receiptDate          = !receiptDetails.isEmpty() && receiptDetails[0].Receipt_Date__c != null ? String.valueOf(receiptDetails[0].Receipt_Date__c) : '..............';
                    templateValues.totalReceiptAmt      = oppDetails[0].Total_Amount_Collected__c != null ? oppDetails[0].Total_Amount_Collected__c : 0;
                    templateValues.accountNumber        = oppDetails[0].Project__r.Account_Number__c != null ? oppDetails[0].Project__r.Account_Number__c : '';
                    templateValues.ifscCode             = oppDetails[0].Project__r.IFSC_Code__c != null ? oppDetails[0].Project__r.IFSC_Code__c : '';
                    templateValues.accbankName          = oppDetails[0].Project__r.Bank_Name__c != null ? oppDetails[0].Project__r.Bank_Name__c : '';
                    List<String> app1AddList = new List<String>();
                    if (oppDetails[0].Account != null) {
                        if (String.isNotBlank(oppDetails[0].Account.Address_for_Communication__Street__s )) app1AddList.add(oppDetails[0].Account.Address_for_Communication__Street__s );
                        if (String.isNotBlank(oppDetails[0].Account.Address_for_Communication__City__s )) app1AddList.add(oppDetails[0].Account.Address_for_Communication__City__s );
                        if (String.isNotBlank(oppDetails[0].Account.Address_for_Communication__PostalCode__s )) app1AddList.add(oppDetails[0].Account.Address_for_Communication__PostalCode__s );
                    }
                    templateValues.priAppAddress        = app1AddList.isEmpty() ? '' : String.join(app1AddList, ', ');
                    templateValues.unitType             = oppDetails[0].Unit__r.Unit_Type__c != null ? oppDetails[0].Unit__r.Unit_Type__c : '';
                    templateValues.floorName            = oppDetails[0].Unit__r.Floor__r.Floor_No__c != null ? String.valueOf(oppDetails[0].Unit__r.Floor__r.Floor_No__c) : '';
                    templateValues.blockName            = oppDetails[0].Unit__r.Floor__r.Blocks__r.Tower_Code__c != null ? oppDetails[0].Unit__r.Floor__r.Blocks__r.Tower_Code__c : '';
                    templateValues.superBuiltupArea     = oppDetails[0].Unit__r.Super_Built_Up_Area_sq_ft__c != null ? String.valueOf(oppDetails[0].Unit__r.Super_Built_Up_Area_sq_ft__c) : '';
                    templateValues.totalPaymentAmt      = oppDetails[0].Total_Outstanding_Amount__c != null ? oppDetails[0].Total_Outstanding_Amount__c : 0;
                    tempList.template_values = templateValues;

                    DigioWrapperClass.agreementCopyDynamicTable tableValues = new DigioWrapperClass.agreementCopyDynamicTable();
                    list<DigioWrapperClass.receiptData> receiptList = new List<DigioWrapperClass.receiptData>();
                    Integer slNo = 1;
                    for(Receipt__c rec : allReceiptList){
                        DigioWrapperClass.receiptData receiptTable = new DigioWrapperClass.receiptData();
                        receiptTable.sl = slNo;
                        if(rec.Mode_Of_Payment__c != null || rec.Mode_Of_Payment__c != ''){
                            if(rec.Mode_Of_Payment__c == 'Cheque'){
                                receiptTable.receiptNo = rec.Cheque_Number__c != null ? rec.Cheque_Number__c : '';
                            }else if(rec.Mode_Of_Payment__c == 'JV'){
                                receiptTable.receiptNo = rec.JV_Reference_Number__c != null ? rec.JV_Reference_Number__c : '';
                            }else if(rec.Mode_Of_Payment__c == 'DD'){
                                receiptTable.receiptNo = rec.DD_Number__c != null ? rec.DD_Number__c : '';
                            }else{
                                receiptTable.receiptNo = rec.Transaction_Reference_Number__c != null ? rec.Transaction_Reference_Number__c : '';
                            }
                        }
                        receiptTable.receiptDate        = rec.Receipt_Date__c != null ? rec.Receipt_Date__c : null;
                        receiptTable.receiptBank        = rec.Bank__c != null ? rec.Bank__c : '';
                        receiptTable.Amount             = rec.Amount__c != null ? rec.Amount__c : 0;
                        receiptList.add(receiptTable);
                        slNo++;
                    }
                    tableValues.receipt = receiptList;
                    
                    list<DigioWrapperClass.paySchData> paymentList = new List<DigioWrapperClass.paySchData>();
                    for(Payment_Schedule__c pay : allPaymentSchList){
                        DigioWrapperClass.paySchData paymentTable = new DigioWrapperClass.paySchData();
                        paymentTable.Name               = pay.Name != null ? pay.Name : '';
                        paymentTable.amount             = pay.Agreement_Value__c != null ? pay.Agreement_Value__c : 0;
                        paymentList.add(paymentTable);
                    }
                    tableValues.payment = paymentList;
                    tempList.template_table_values = tableValues;

                    String jsonBody = Json.serialize(generateDoc);
                    String digiDocId = digioCalloutUtility.sendHttpRequest('POST', endpoint, customData.Authorization__c, jsonBody);
                    wrapperRec.digiDocId = digiDocId;
                    if(digiDocId != null && fileName != null){
                        subDocUrl = digioCalloutUtility.downloadDocument(digiDocId, fileName, parentFolderId, docId);
                        wrapperRec.subDocUrl = subDocUrl;
                        System.debug('subDocUrl ===> ' + subDocUrl);
                    }
                }
                return wrapperRec;
            }
            return null;
        }catch(Exception e){
            system.debug('Error in data sheet===> ' + e.getMessage());
            system.debug('Error line ===> ' + e.getLineNumber());
            return null;
        }
    }

    @AuraEnabled
    public static docwrpperClass generateDataSheetFormatDoc(String recordId){
        try{
            System.debug('recordId ===> ' + recordId);
            if(recordId != null){
                List<Opportunity> oppDetails = [SELECT Id,Name,Document_Id__c,Account.Salutation__c,Account.Name,Account.W_o_S_o_D_o__c,Account.Age__c,Account.Date_Of_Birth__c,Account.PAN__c,Account.Email__c,Account.Permanent_Address__Street__s,Account.Permanent_Address__City__s,Account.Permanent_Address__PostalCode__s,Unit__r.Unit_Name__c,Unit__r.Floor__r.Blocks__r.Tower_Code__c,Unit__r.Unit_Type__c,Account.Phone,Unit__r.Super_Built_Up_Area_sq_ft__c,Unit__r.Base_Price_per_sqft__c,Unit__r.Floor_Rise__c, (SELECT Id,Name,Document_Id__c from Documents__r where Name = 'Root Folder' LIMIT 1) from Opportunity where Id =: recordId LIMIT 1];
                System.debug('oppDetails ===> ' + oppDetails);
                String parentFolderId;
                String docId;
                String subDocUrl = '';
                docwrpperClass wrapperRec = new docwrpperClass();
                if(!oppDetails.isEmpty() && oppDetails[0].Documents__r != null){
                    parentFolderId = oppDetails[0].Documents__r[0].Document_Id__c;
                    docId = oppDetails[0].Documents__r[0].Id;
                }
                
                Digio_Integration__c customData = Digio_Integration__c.getValues('Digio');
                String templateKey = '';
                List<Applicant__c> applicantList;
                List<Pricing_Element__c> carParkingList;
                List<String> carParkingTotal = new List<String>();
                Map<String,Decimal> carParkingTypeByCount = new Map<String,Decimal>();
                List<Pricing_Element__c> twoWheelerParking;
                List<Pricing_Element__c> premiumChargesList;
                if(oppDetails[0].Id != null){
                    applicantList = [SELECT Id,Account__r.Name,Account__r.Salutation__c,Account__r.W_o_S_o_D_o__c,Account__r.Age__c,Account__r.Date_Of_Birth__c,Account__r.PAN__c,Account__r.Email__c,Account__r.Permanent_Address__Street__s,Account__r.Permanent_Address__City__s,Account__r.Permanent_Address__PostalCode__s from Applicant__c where Opportunity__c =: oppDetails[0].Id Order by CreatedDate ASC];
                    if(!applicantList.isEmpty()){
                        templateKey = applicantList.size() == 1 ? customData.Data_Sheet_Format_2__c : applicantList.size() == 2 ? customData.Data_Sheet_Format_3__c : applicantList.size() == 3 ? customData.Data_Sheet_Format_4__c : applicantList.size() == 4 ? customData.Data_Sheet_Format_5__c : applicantList.size() == 5 ? customData.Data_Sheet_Format_6__c : null;
                    }else{
                        templateKey = customData.Data_Sheet_Format_1__c;
                    }
                    System.debug('applicantList size ===> ' + applicantList.size() + ' templateKey ====> ' + templateKey);
                    carParkingList = [SELECT Id,Quantity__c,Pricing_Element_Master__r.Parking_Type__c,Cost_Sheet__r.finalize_CostSheet__c from Pricing_Element__c WHERE Cost_Sheet__c != null AND Cost_Sheet__r.finalize_CostSheet__c = true AND Cost_Sheet__r.Opportunity__c =: oppDetails[0].Id AND (parking_Element__c = true OR Pricing_Element_Master__r.Parking_Type__c != null)];
                    System.debug('carParkingList ===> ' + carParkingList);
                    if(!carParkingList.isEmpty()){
                        for(Pricing_Element__c pri : carParkingList){
                            if(!carParkingTypeByCount.containsKey(pri.Pricing_Element_Master__r.Parking_Type__c)){
                                carParkingTypeByCount.put(pri.Pricing_Element_Master__r.Parking_Type__c, pri.Quantity__c);
                            }
                            carParkingTypeByCount.put( pri.Pricing_Element_Master__r.Parking_Type__c, carParkingTypeByCount.get(pri.Pricing_Element_Master__r.Parking_Type__c) + pri.Quantity__c );
                        }
                        if(carParkingTypeByCount != null){
                            for(String key : carParkingTypeByCount.keySet()){
                                if(carParkingTypeByCount.get(key) > 0){
                                    String carDetails = key + ' - ' + String.valueOf(carParkingTypeByCount.get(key));
                                    carParkingTotal.add(carDetails);
                                }
                            }
                        }
                    }
                    System.debug('carParkingTypeByCount ===> ' + carParkingTypeByCount);
                    twoWheelerParking = [SELECT Id,Quantity__c,Pricing_Element_Master__r.Two_Wheeler_Parking__c from Pricing_Element__c where Pricing_Element_Master__r.Two_Wheeler_Parking__c = true AND Cost_Sheet__r.finalize_CostSheet__c = true AND Cost_Sheet__r.Opportunity__c =: oppDetails[0].Id LIMIT 1];
                    System.debug('twoWheelerParking ===> ' + twoWheelerParking);
                    premiumChargesList = [SELECT Id,Pricing_Element_Master__r.Name,Rate__c from Pricing_Element__c where (Pricing_Element_Master__r.Name LIKE '%Premium%' OR Pricing_Element_Master__r.Name LIKE '%premium%') AND Cost_Sheet__r.finalize_CostSheet__c = true AND Cost_Sheet__r.Opportunity__c =: oppDetails[0].Id LIMIT 1];
                    System.debug('premiumChargesList ===> ' + premiumChargesList);
                }
                if(customData.Authorization__c != null && customData.Endpoint_URL__c != null && templateKey != null && parentFolderId != null){
                    String endpoint = customData.Endpoint_URL__c + '/v2/client/template/multi_templates/create_sign_request';
                    DigioWrapperClass.dataSheetFormatWrapper generateDoc = new DigioWrapperClass.dataSheetFormatWrapper();
                    String fileName = oppDetails[0].Name + ' - Data Sheet Format ' + String.valueOf(DateTime.now().getTime() / 1000);
                    generateDoc.file_name = fileName;
                    
                    DigioWrapperClass.signersList signer = new DigioWrapperClass.signersList();
                    signer.identifier = 'salesforce@snnestates.com';
                    signer.signer_tag = 'Signer 1';
                    signer.name = 'SNN Estates';
                    signer.sign_type = 'document_review';
                    generateDoc.signers = new List<DigioWrapperClass.signersList>{signer};
                    
                    DigioWrapperClass.dataSheetTemplateList tempList = new DigioWrapperClass.dataSheetTemplateList();
                    tempList.template_key = templateKey;
                    generateDoc.templates = new List<DigioWrapperClass.dataSheetTemplateList>{tempList};

                    DigioWrapperClass.dataSheetTemplateValues templateValues = new DigioWrapperClass.dataSheetTemplateValues();
                    
                    templateValues.app1Dob           = oppDetails[0].Account.Date_Of_Birth__c != null ? oppDetails[0].Account.Date_Of_Birth__c : null;
                    templateValues.app1Pan           = oppDetails[0].Account.PAN__c != null ? String.valueOf(oppDetails[0].Account.PAN__c) : '';
                    templateValues.app1Email         = oppDetails[0].Account.Email__c != null ? oppDetails[0].Account.Email__c : '';
                    if(!applicantList.isEmpty() && applicantList.size() >= 1){
                        templateValues.app2Name          = applicantList[0].Account__r.Salutation__c != null ? applicantList[0].Account__r.Salutation__c + '.' + applicantList[0].Account__r.Name : applicantList[0].Account__r.Name;
                        templateValues.app2SoDoWo        = applicantList[0].Account__r.W_o_S_o_D_o__c != null ? applicantList[0].Account__r.W_o_S_o_D_o__c : '';
                        templateValues.app2Age           = applicantList[0].Account__r.Age__c != null ? String.valueOf(applicantList[0].Account__r.Age__c) : '';
                        templateValues.app2Dob           = applicantList[0].Account__r.Date_Of_Birth__c != null ? applicantList[0].Account__r.Date_Of_Birth__c : null;
                        templateValues.app2Pan           = applicantList[0].Account__r.PAN__c != null ? String.valueOf(applicantList[0].Account__r.PAN__c) : '';
                        templateValues.app2Email         = applicantList[0].Account__r.Email__c != null ? applicantList[0].Account__r.Email__c : '';
                    } 
                    if(!applicantList.isEmpty() && applicantList.size() >= 2){
                        templateValues.app3Name          = applicantList[1].Account__r.Salutation__c != null ? applicantList[1].Account__r.Salutation__c + '.' + applicantList[1].Account__r.Name : applicantList[1].Account__r.Name;
                        templateValues.app3SoDoWo        = applicantList[1].Account__r.W_o_S_o_D_o__c != null ? applicantList[1].Account__r.W_o_S_o_D_o__c : '';
                        templateValues.app3Age           = applicantList[1].Account__r.Age__c != null ? String.valueOf(applicantList[1].Account__r.Age__c) : '';
                        templateValues.app3Dob           = applicantList[1].Account__r.Date_Of_Birth__c != null ? applicantList[1].Account__r.Date_Of_Birth__c : null;
                        templateValues.app3Pan           = applicantList[1].Account__r.PAN__c != null ? String.valueOf(applicantList[1].Account__r.PAN__c) : '';
                        templateValues.app3Email         = applicantList[1].Account__r.Email__c != null ? applicantList[1].Account__r.Email__c : '';
                    } 
                    if(!applicantList.isEmpty() && applicantList.size() >= 3){
                        templateValues.app4Name          = applicantList[2].Account__r.Salutation__c != null ? applicantList[2].Account__r.Salutation__c + '.' + applicantList[2].Account__r.Name : applicantList[2].Account__r.Name;
                        templateValues.app4SoDoWo        = applicantList[2].Account__r.W_o_S_o_D_o__c != null ? applicantList[2].Account__r.W_o_S_o_D_o__c : '';
                        templateValues.app4Age           = applicantList[2].Account__r.Age__c != null ? String.valueOf(applicantList[2].Account__r.Age__c) : '';
                        templateValues.app4Dob           = applicantList[2].Account__r.Date_Of_Birth__c != null ? applicantList[2].Account__r.Date_Of_Birth__c : null;
                        templateValues.app4Pan           = applicantList[2].Account__r.PAN__c != null ? String.valueOf(applicantList[2].Account__r.PAN__c) : '';
                        templateValues.app4Email         = applicantList[2].Account__r.Email__c != null ? applicantList[2].Account__r.Email__c : '';
                    } 
                    if(!applicantList.isEmpty() && applicantList.size() >= 4){
                        templateValues.app5Name          = applicantList[3].Account__r.Salutation__c != null ? applicantList[3].Account__r.Salutation__c + '.' + applicantList[3].Account__r.Name : applicantList[3].Account__r.Name;
                        templateValues.app5SoDoWo        = applicantList[3].Account__r.W_o_S_o_D_o__c != null ? applicantList[3].Account__r.W_o_S_o_D_o__c : '';
                        templateValues.app5Age           = applicantList[3].Account__r.Age__c != null ? String.valueOf(applicantList[3].Account__r.Age__c) : '';
                        templateValues.app5Dob           = applicantList[3].Account__r.Date_Of_Birth__c != null ? applicantList[3].Account__r.Date_Of_Birth__c : null;
                        templateValues.app5Pan           = applicantList[3].Account__r.PAN__c != null ? String.valueOf(applicantList[3].Account__r.PAN__c) : '';
                        templateValues.app5Email         = applicantList[3].Account__r.Email__c != null ? applicantList[3].Account__r.Email__c : '';
                    } 
                    if(!applicantList.isEmpty() && applicantList.size() >= 5){
                        templateValues.app6Name          = applicantList[4].Account__r.Salutation__c != null ? applicantList[4].Account__r.Salutation__c + '.' + applicantList[4].Account__r.Name : applicantList[4].Account__r.Name;
                        templateValues.app6SoDoWo        = applicantList[4].Account__r.W_o_S_o_D_o__c != null ? applicantList[4].Account__r.W_o_S_o_D_o__c : '';
                        templateValues.app6Age           = applicantList[4].Account__r.Age__c != null ? String.valueOf(applicantList[4].Account__r.Age__c) : '';
                        templateValues.app6Dob           = applicantList[4].Account__r.Date_Of_Birth__c != null ? applicantList[4].Account__r.Date_Of_Birth__c : null;
                        templateValues.app6Pan           = applicantList[4].Account__r.PAN__c != null ? String.valueOf(applicantList[4].Account__r.PAN__c) : '';
                        templateValues.app6Email         = applicantList[4].Account__r.Email__c != null ? applicantList[4].Account__r.Email__c : '';
                    }
                    
                    List<String> app1AddList = new List<String>();
                    if (oppDetails[0].Account != null) {
                        if (String.isNotBlank(oppDetails[0].Account.Permanent_Address__Street__s)) app1AddList.add(oppDetails[0].Account.Permanent_Address__Street__s);
                        if (String.isNotBlank(oppDetails[0].Account.Permanent_Address__City__s)) app1AddList.add(oppDetails[0].Account.Permanent_Address__City__s);
                        if (String.isNotBlank(oppDetails[0].Account.Permanent_Address__PostalCode__s)) app1AddList.add(oppDetails[0].Account.Permanent_Address__PostalCode__s);
                    }
                    templateValues.app1Address       = app1AddList.isEmpty() ? '' : String.join(app1AddList, ', ');
                    for (Integer i = 0; i < Math.min(applicantList.size(), 5); i++) {
                        List<String> addressParts = new List<String>();
                        if (applicantList[i].Account__r != null) {
                            if (String.isNotBlank(applicantList[i].Account__r.Permanent_Address__Street__s))
                                addressParts.add(applicantList[i].Account__r.Permanent_Address__Street__s);
                            if (String.isNotBlank(applicantList[i].Account__r.Permanent_Address__City__s))
                                addressParts.add(applicantList[i].Account__r.Permanent_Address__City__s);
                            if (String.isNotBlank(applicantList[i].Account__r.Permanent_Address__PostalCode__s))
                                addressParts.add(applicantList[i].Account__r.Permanent_Address__PostalCode__s);
                        }
                        String fullAddress = addressParts.isEmpty() ? '' : String.join(addressParts, ', ');
                        if (i == 0) templateValues.app2Address = fullAddress;
                        if (i == 1) templateValues.app3Address = fullAddress;
                        if (i == 2) templateValues.app4Address = fullAddress;
                        if (i == 3) templateValues.app5Address = fullAddress;
                        if (i == 4) templateValues.app6Address = fullAddress;
                    }
                    String towerCode = oppDetails[0].Unit__r?.Floor__r?.Blocks__r?.Tower_Code__c;
                    String unitName = oppDetails[0].Unit__r?.Unit_Name__c;
                    templateValues.blockAndUnitNo   = String.isNotBlank(towerCode) && String.isNotBlank(unitName) ? towerCode + ' - ' + unitName : String.isNotBlank(towerCode) ? towerCode : String.isNotBlank(unitName) ? unitName : '';
                    templateValues.unitType         = oppDetails[0].Unit__r.Unit_Type__c != null ? oppDetails[0].Unit__r.Unit_Type__c : '';
                    templateValues.priAppNumber     = oppDetails[0].Account.Phone != null ? oppDetails[0].Account.Phone : '';
                    templateValues.superBuiltupArea = oppDetails[0].Unit__r.Super_Built_Up_Area_sq_ft__c != null ? oppDetails[0].Unit__r.Super_Built_Up_Area_sq_ft__c : 0;
                    templateValues.carParking       = carParkingTotal.size() > 0 ? String.join(carParkingTotal, ',') : '';
                    templateValues.twoWheeler       = !twoWheelerParking.isEmpty() && twoWheelerParking[0] != null && twoWheelerParking[0].Quantity__c != null ? twoWheelerParking[0].Quantity__c : 0;
                    templateValues.basicPrice       = oppDetails[0].Unit__r.Base_Price_per_sqft__c != null ? oppDetails[0].Unit__r.Base_Price_per_sqft__c : 0;
                    templateValues.floorRise        = oppDetails[0].Unit__r.Floor_Rise__c != null ? oppDetails[0].Unit__r.Floor_Rise__c : 0;
                    templateValues.premiumCharges   = !premiumChargesList.isEmpty() && premiumChargesList[0].Rate__c != null ? premiumChargesList[0].Rate__c : 0;
                    tempList.template_values = templateValues;

                    String jsonBody = Json.serialize(generateDoc);
                    String digiDocId = digioCalloutUtility.sendHttpRequest('POST', endpoint, customData.Authorization__c, jsonBody);
                    wrapperRec.digiDocId = digiDocId;
                    if(digiDocId != null && fileName != null){
                        subDocUrl = digioCalloutUtility.downloadDocument(digiDocId, fileName, parentFolderId, docId);
                        wrapperRec.subDocUrl = subDocUrl;
                    }
                }
                return wrapperRec;
            }
            return null;
        }catch(Exception e){
            system.debug('Error in data sheet===> ' + e.getMessage());
            system.debug('Error line ===> ' + e.getLineNumber());
            return null;
        }
    }
    
    @InvocableMethod
    public static void invokeFromFlow(List<String> paymentSchIds){
        System.debug('Invoked from Flow with: ' + paymentSchIds);
        System.enqueueJob(new generateDebitNoteQueueable(paymentSchIds));
    }
    
    public static void generateDebitNoteWrapper(List<String> paymentSchId){
        System.debug('generateDebitNoteWrapper ' + paymentSchId);
        try{
            if(!paymentSchId.isEmpty()){
                List<Payment_Schedule__c> paymentSchList = [SELECT Id,Name,Opportunity__c, Installment_Sequence__c from Payment_Schedule__c where Id =: paymentSchId[0] LIMIT 1];
                List<Opportunity> oppDetails = [SELECT Id,Name,Unit__r.Floor__r.Blocks__r.Tower_Code__c,AccountId,Account.Name,Account.Salutation__c,Account.Address_for_Communication__PostalCode__s ,Unit__r.Name,Project__r.Name,(SELECT Id,Document_Id__c from Documents__r where Name = 'Post Sales' LIMIT 1) from Opportunity where Id =: paymentSchList[0].Opportunity__c LIMIT 1];
                List<Contact> contactList = [SELECT Id,Email,accountId from Contact where AccountId =: oppDetails[0].AccountId order by createddate desc LIMIT 1];
                List<Receipt__c> debitReceipt = [SELECT Id,Debit_Note_Reminder_Sent__c,Opportunity__c,Type__c,Description__c,Amount__c from Receipt__c where Opportunity__c =: paymentSchList[0].Opportunity__c and Type__c = 'Debit' and Debit_Note_Reminder_Sent__c = false order by CreatedDate Desc LIMIT 1];
                System.debug(' debitReceipt ===> ' + debitReceipt);
                System.debug(' paymentSchList ===> ' + paymentSchList);
                if(!debitReceipt.isEmpty() && !paymentSchList.isEmpty()){
                    List<Applicant__c> coApplicantList = [select id,Account__r.Name,Account__r.Salutation__c from Applicant__c where Opportunity__c =:oppDetails[0].Id Limit 1];
                    List<String> allApplicantNames = new List<String>();
                    if(oppDetails[0].Name != null){
                        List<String> mainAppName = new List<String>();
                        mainAppName.add(oppDetails[0].Account.Salutation__c);
                        mainAppName.add(oppDetails[0].Account.Name);
                        allApplicantNames.add(String.join(mainAppName, '. '));
                    }
                    if(!coApplicantList.isEmpty()){
                        for(Applicant__c applicant : coApplicantList){
                            List<String> coApplicantName = new List<String>();
                            coApplicantName.add(applicant.Account__r.Salutation__c);
                            coApplicantName.add(applicant.Account__r.Name);
                            allApplicantNames.add(String.join(coApplicantName, '. '));
                        }
                    }
                    
                    String parentFolderId;
                    String docId;
                    String cntVersionId = '';
                    docwrpperClass wrapperRec = new docwrpperClass();
                    
                    if(!oppDetails.isEmpty() && oppDetails[0].Documents__r != null){
                        parentFolderId = oppDetails[0].Documents__r[0].Document_Id__c;
                        docId = oppDetails[0].Documents__r[0].Id;
                    }
                    System.debug('parentFolderId ===> ' + parentFolderId);
                    System.debug('docId ===> ' + docId);
                    
                    Digio_Integration__c customData = Digio_Integration__c.getValues('Digio');
                    if(!oppDetails.isEmpty() && customData.Authorization__c != null && customData.Endpoint_URL__c != null && customData.Debit_Note_Template_Key__c != null && parentFolderId != null){
                        String endpoint = customData.Endpoint_URL__c + '/v2/client/template/multi_templates/create_sign_request';
                        
                        DigioWrapperClass.generateDebitNoteWrapper generateDoc = new DigioWrapperClass.generateDebitNoteWrapper();
                        String fileName = 'Debit Note - ' + String.valueOf(System.now());
                        generateDoc.file_name = fileName;
                        
                        DigioWrapperClass.signersList signer = new DigioWrapperClass.signersList();
                        signer.identifier = 'salesforce@snnestates.com';
                        signer.signer_tag = 'Signer 1';
                        signer.name = 'SNN Estates';
                        signer.sign_type = 'document_review';
                        generateDoc.signers = new List<DigioWrapperClass.signersList>{signer};
                        
                        DigioWrapperClass.debitNoteTemplateList tempList = new DigioWrapperClass.debitNoteTemplateList();
                        tempList.template_key = customData.Debit_Note_Template_Key__c;
                        DigioWrapperClass.debitNoteTemplateValues templateVariables = new DigioWrapperClass.debitNoteTemplateValues();
                        templateVariables.allApplicantNames     = !allApplicantNames.isEmpty() ? String.join(allApplicantNames, ', ') : null;
                        templateVariables.mainApplicantPinCode  = oppDetails[0].Account.Address_for_Communication__PostalCode__s != null ? oppDetails[0].Account.Address_for_Communication__PostalCode__s : '';
                        templateVariables.todayDate             = System.today();
                        templateVariables.unitNumber            = oppDetails[0].Unit__r.Name != null ? oppDetails[0].Unit__r.Name : '';
                        templateVariables.projectName           = oppDetails[0].Project__r.Name != null ? oppDetails[0].Project__r.Name : '';
                        templateVariables.blockName             = oppDetails[0].Unit__r.Floor__r.Blocks__r.Tower_Code__c != null ? oppDetails[0].Unit__r.Floor__r.Blocks__r.Tower_Code__c : '';
                        templateVariables.currentUser           = UserInfo.getName();
                        templateVariables.debitNoteDescription  = debitReceipt[0].Description__c != null ? debitReceipt[0].Description__c : '';
                        templateVariables.debitAmount           = debitReceipt[0].Amount__c != null ? debitReceipt[0].Amount__c : 0;
                        templateVariables.nextPaymentSchName    = paymentSchList[0].Name != null ? paymentSchList[0].Name : '';
                        
                        tempList.template_values = templateVariables;
                        generateDoc.templates = new List<DigioWrapperClass.debitNoteTemplateList>{tempList};
                        
                        String jsonBody = Json.serialize(generateDoc);
                        String digiDocId = digioCalloutUtility.sendHttpRequest('POST', endpoint, customData.Authorization__c, jsonBody);
                        
                        if(digiDocId != null && fileName != null){
                            EmailTemplate temp = [SELECT Id, Subject, HtmlValue, Body FROM EmailTemplate WHERE DeveloperName = 'Debit_Note'];
                            cntVersionId = digioCalloutUtility.downloadDocumentAndContentVer(digiDocId, fileName, parentFolderId, docId);
                            if(!contactList.isEmpty() && contactList[0].Email != null){
                                List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();
                                if(cntVersionId != null){
                                    ContentVersion contentVersion = [SELECT Id,Title,VersionData from ContentVersion where Id =: cntVersionId LIMIT 1];
                                    Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
                                    attachment.setFileName(contentVersion.Title + '.pdf');
                                    attachment.setBody(contentVersion.VersionData);
                                    attachment.setContentType('application/pdf');
                                    attachments.add(attachment);
                                }
                                
                                if(!attachments.isEmpty()){
                                    List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
                                    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                                    String htmlBody = temp.HtmlValue.replace('{!Opportunity.Name}', oppDetails[0].Name);
                                    email.setToAddresses(new String[]{contactList[0].Email});
                                    email.setSubject(temp.Subject);
                                    email.setHtmlBody(htmlBody);
                                    email.setFileAttachments(attachments);
                                    emailList.add(email);
                                    if (!emailList.isEmpty()) {
                                        Messaging.sendEmail(emailList);
                                        System.debug('Email sent successfully' + contactList[0].Email);
                                        debitReceipt[0].Debit_Note_Reminder_Sent__c = true;
                                        update debitReceipt[0];
                                        
                                        ContentVersion cnt = [select id,ContentDocumentId from contentVersion where id =: cntVersionId];
                                        if(cnt.ContentDocumentId != null){
                                            delete [SELECT Id from ContentDocument where ID =: cnt.ContentDocumentId];
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }catch(Exception e){
            system.debug('Error in generateVettedReceiptDocument===> ' + e.getMessage());
            system.debug('Error line ===> ' + e.getLineNumber());
        }
    }

     //Generate Allotment Letter
    @AuraEnabled
    public static docwrpperClass generateAllotmentLetter(String oppId){
        try{
            System.debug('oppId==>'+oppId);
            
            String coApplicantNames = '';
            String parentFolderId;
            String docId;
            String subDocUrl = '';
            docwrpperClass wrapperRec = new docwrpperClass();
            List<Applicant__c> allApplicants = [select id,Name,Permanent_Address__c,Permanent_Address__PostalCode__s,Email__c,Primary_Contact_Number__c,Opportunity__r.Unit__r.Super_Built_Up_Area_sq_ft__c,Opportunity__r.Unit__c,Opportunity__r.Unit__r.Name,Opportunity__r.Unit__r.Unit_Type__c,Opportunity__r.Unit__r.Floor__c,Opportunity__r.Unit__r.Floor__r.Name,Opportunity__r.Unit__r.Floor__r.Blocks__c,Opportunity__r.Unit__r.Floor__r.Blocks__r.Name,Opportunity__r.Project__c,Opportunity__r.Project__r.Name,Primary_Applicant__c,Opportunity__r.Opportunity_Unique_Id__c,Permanent_Address__City__s,Account__r.Name from Applicant__c where Opportunity__c  =: oppId];
            System.debug('allApplicants==>'+allApplicants);
            List<Payment_Schedule__c>paymentScheduleRelatedToOpp = [select id,Name,Installment__c,Agreement_Value__c,Installment_Sequence__c from Payment_Schedule__c where Opportunity__c =: oppId];
            System.debug('paymentScheduleRelatedToOpp==>'+paymentScheduleRelatedToOpp);
            List<Cost_Sheet__c>  finalizeCostSheet =[select id,finalize_CostSheet__c from Cost_Sheet__c Where finalize_CostSheet__c =: True and Opportunity__c =: oppId Limit 1];
            List<Pricing_Element__c> carParkingDetailList = [select id,Pricing_Element_Master__r.Name,Quantity__c,parking_Element__c from Pricing_Element__c Where Cost_Sheet__c =: finalizeCostSheet[0].Id AND parking_Element__c =: True];
            List<Opportunity> oppDetails = [SELECT Id,Name,AccountId,Unit__r.Unit_Name__c,Booking_Date__c,Project__r.Name,Unit__r.Floor__r.Blocks__r.Name,Unit__r.Floor__r.Name,Unit__r.Floor__r.Floor_No__c,Unit__r.Unit_Type__c,Unit__r.Super_Built_Up_Area_sq_ft__c,Allotment_Letter_Generated__c,OwnerId,(SELECT Id,Document_Id__c from Documents__r where Name = 'Post Sales' LIMIT 1) from Opportunity where Id =: oppId LIMIT 1];
            if(!oppDetails.isEmpty() && oppDetails[0].Documents__r != null){
                parentFolderId = oppDetails[0].Documents__r[0].Document_Id__c;
                docId = oppDetails[0].Documents__r[0].Id;
            }
            List<Account> mainApplicant = [select id,Name,W_o_S_o_D_o__c,Date_Of_Birth__c,PAN__c,Email__c,Permanent_Address__c,Phone from Account where Id =:oppDetails[0].AccountId Limit 1];
            for(Applicant__c applicant : allApplicants){
                if (String.isNotBlank(coApplicantNames)) {
                    coApplicantNames += ' ; ';
                }
                coApplicantNames += applicant.Account__r.Name;
            }
            System.debug('coApplicantNames==>'+coApplicantNames);
            Digio_Integration__c customData = Digio_Integration__c.getValues('Digio');
            System.debug('mainApplicant==>'+mainApplicant);
            System.debug('customData==>'+customData);
            if(mainApplicant[0] != null && customData.Authorization__c != null && customData.Endpoint_URL__c != null){
                String endpoint = customData.Endpoint_URL__c + '/v2/client/template/multi_templates/create_sign_request';
                System.debug('endpoint ===> ' + endpoint);
                DigioWrapperClass.generateAllotmentLetter generateDoc = new DigioWrapperClass.generateAllotmentLetter();
                
                Datetime now = System.now();
                String formattedTimestamp = now.format('yyyy-MM-dd HH:mm:ss');
                System.debug('Formatted Timestamp: ' + formattedTimestamp);
                
                String fileName = 'Allotment Letter - '+ formattedTimestamp;
                generateDoc.file_name = fileName;
                
                DigioWrapperClass.signersList signer = new DigioWrapperClass.signersList();
                signer.identifier = 'projects@snnestates.com';
                signer.signer_tag = 'Signer 1';
                signer.name = 'Snn';
                signer.sign_type = 'document_review';
                
                generateDoc.signers = new List<DigioWrapperClass.signersList>{signer};
                DigioWrapperClass.allotmentLetterTemplateList tempList = new DigioWrapperClass.allotmentLetterTemplateList();
                tempList.template_key =  customData.Allotment_Letter_Template_Key__c;  //TMP241212151402462NHKDAIMAVB78D9
                
                System.debug('mainApplicant==>'+mainApplicant);
                
                DigioWrapperClass.allotmentLetterTemplateValues templateVariables = new DigioWrapperClass.allotmentLetterTemplateValues();
                templateVariables.loginUserName       = UserInfo.getName();
                templateVariables.applicantName       = mainApplicant[0].Name != null ? mainApplicant[0].Name : '';
                templateVariables.coApplicantName       = coApplicantNames != null ? coApplicantNames: '';
                if (mainApplicant[0].Permanent_Address__c != null) {
                    System.Address address = mainApplicant[0].Permanent_Address__c;
                    templateVariables.addressName =
                        (address.getStreet() != null ? address.getStreet() + ', ' : '') +
                        (address.getCity() != null ? address.getCity() + ', ' : '') +
                        (address.getState() != null ? address.getState() + ', ' : '') +
                        (address.getCountry() != null ? address.getCountry() + ', ' : '') +
                        (address.getPostalCode() != null ? address.getPostalCode() : '');
                    
                    templateVariables.pinCodeNumber = (address.getPostalCode() != null ? address.getPostalCode() : '');
                    
                    templateVariables.addressName = templateVariables.addressName.trim().endsWith(',')
                        ? templateVariables.addressName.substring(0, templateVariables.addressName.length() - 1)
                        : templateVariables.addressName;
                } else {
                    templateVariables.addressName = '';
                }
                System.debug('Allotment Letter==>');
                
                templateVariables.emailId       = mainApplicant[0].Email__c != null ? mainApplicant[0].Email__c : '';
                templateVariables.phoneNumber       = mainApplicant[0].Phone != null ? mainApplicant[0].Phone : '';
                templateVariables.SNNEStateFelicity       = oppDetails[0].Project__r.Name != null ? oppDetails[0].Project__r.Name : '';
                templateVariables.bloackName       = oppDetails[0].Unit__r.Floor__r.Blocks__r.Name != null ? oppDetails[0].Unit__r.Floor__r.Blocks__r.Name : '';
                templateVariables.floorName       = oppDetails[0].Unit__r.Floor__r.Floor_No__c != null ? oppDetails[0].Unit__r.Floor__r.Floor_No__c : 0;
                templateVariables.apartmentNo       = oppDetails[0].Unit__r.Unit_Name__c != null ? oppDetails[0].Unit__r.Unit_Name__c : '';
                templateVariables.apartmentTypeName       = oppDetails[0].Unit__r.Unit_Type__c != null ? oppDetails[0].Unit__r.Unit_Type__c : '';
                templateVariables.saleableAreaName       = oppDetails[0].Unit__r.Super_Built_Up_Area_sq_ft__c != null ? oppDetails[0].Unit__r.Super_Built_Up_Area_sq_ft__c : 0;
                templateVariables.totalFlatCost          = 0;
                templateVariables.carParkingDetails  = '';
                System.debug('carParkingDetailList==>'+carParkingDetailList);
                for(Pricing_Element__c cpd : carParkingDetailList){
                    System.debug('cpd==>'+cpd);
                    templateVariables.carParkingDetails       = templateVariables.carParkingDetails +  cpd.Pricing_Element_Master__r.Name + ' - ' +  cpd.Quantity__c + ',';
                    System.debug('templateVariables.carParkingDetails==>'+templateVariables.carParkingDetails);
                }
                
                if (!String.isEmpty(templateVariables.carParkingDetails)) {
                    templateVariables.carParkingDetails = templateVariables.carParkingDetails.substring(0, templateVariables.carParkingDetails.length() - 1);
                }
                
                System.debug('Payment Schedule==>');
                
                DigioWrapperClass.allotmentLetterDynamicTable tableValues = new DigioWrapperClass.allotmentLetterDynamicTable();
                list<DigioWrapperClass.paymentScheduleTable> paymentScheduleList = new List<DigioWrapperClass.paymentScheduleTable>();
                if(!paymentScheduleRelatedToOpp.isEmpty()){
                    Integer serialNo = 1;
                    for(Payment_Schedule__c paymentSchedule : paymentScheduleRelatedToOpp){
                        DigioWrapperClass.paymentScheduleTable paymentTable = new DigioWrapperClass.paymentScheduleTable();
                        paymentTable.SlNo = serialNo;
                        paymentTable.installment = paymentSchedule.Name != null ? paymentSchedule.Name : '';
                        paymentTable.sequence = paymentSchedule.Installment__c != null ? String.valueOf(paymentSchedule.Installment__c) + '%' : '';
                        // paymentSchedule.Installment_Sequence__c != null ? paymentSchedule.Installment_Sequence__c : '';
                        paymentTable.milestone = paymentSchedule.Agreement_Value__c != null ? paymentSchedule.Agreement_Value__c : 0;
                        paymentTable.amount = paymentSchedule.Agreement_Value__c != null ? paymentSchedule.Agreement_Value__c : 0;
                        paymentScheduleList.add(paymentTable);
                        serialNo = serialNo + 1;
                        templateVariables.totalFlatCost += paymentSchedule.Agreement_Value__c != null ? paymentSchedule.Agreement_Value__c : 0;
                    }
                    tableValues.paymentScheduleTable = paymentScheduleList;
                    tempList.template_table_values = tableValues;
                    tempList.template_values = templateVariables;
                    generateDoc.templates = new List<DigioWrapperClass.allotmentLetterTemplateList>{tempList};
                    system.debug('generateDoc ===> ' + generateDoc);
                    system.debug('serialize json ===> ' + Json.serialize(generateDoc));
                    
                    String jsonBody = Json.serialize(generateDoc);
                    String authorizationValue = 'Basic' + '' +EncodingUtil.base64Encode(Blob.valueOf(customData.Client_ID__c + ':' + customData.Client_Secret__c));
                    System.debug('authorizationValue==>'+authorizationValue);
                    
                    String digiDocId = digioCalloutUtility.sendHttpRequest('POST', endpoint, customData.Authorization__c, jsonBody);
                    wrapperRec.digiDocId = digiDocId;
                    if(digiDocId != null && fileName != null){
                        subDocUrl = digioCalloutUtility.downloadDocument(digiDocId, fileName, parentFolderId, docId);
                        wrapperRec.subDocUrl = subDocUrl;
                        System.debug('subDocUrl ===> ' + subDocUrl);
                    }
                    
                    if(oppDetails[0].Allotment_Letter_Generated__c != true){
                        oppDetails[0].Allotment_Letter_Generated__c = true;
                        oppDetails[0].StageName = 'Agreement Data Sheet';
                        update oppDetails[0];
                    }
                    
                    List<Task> taskList = [SELECT Id,Subject from Task where Subject = 'Confirmation - Customer Data Verified ?' and WhatId =: oppDetails[0].Id];
                    if(taskList.isEmpty()){
                        Task tsk = new Task();
                        tsk.Subject = 'Confirmation - Customer Data Verified ?';
                        tsk.WhatId = oppDetails[0].Id;
                        tsk.OwnerId = oppDetails[0].OwnerId;
                        insert tsk;
                    }
                }
                return wrapperRec;
            }
            return null;
        }catch(Exception e){
            system.debug('Error in generateDemandLetterDocument===> ' + e.getMessage());
            system.debug('Error line ===> ' + e.getLineNumber());
            return null;
        }
    }
    
    //Serenity Receipt Template
    @AuraEnabled
    public static docwrpperClass generateSerenityReceipt(String recorId){
        try{
            System.debug('recorId=>'+recorId);
            if(recorId != null){
                String parentFolderId;
                String docId;
                String subDocUrl = '';
                docwrpperClass wrapperRec = new docwrpperClass();
                List<Receipt__c> receiptRecord = [select id,Name,Drawn_On_Bank__c,JV_Reference_Number__c,UPI_Provider__c,Receipt_Date__c,Opportunity__r.Project__r.Name,Opportunity__c,Mode_Of_Payment__c,Reference_Number__c,Cheque_Date__c,Bank__c,Opportunity__r.Unit__r.Unit_Type__c,Amount__c,Opportunity__r.Unit__r.Floor__r.Blocks__r.Name,Opportunity__r.Unit__r.Unit_Name__c,Opportunity__r.Unit__r.Name,Opportunity__r.Opportunity_Unique_Id__c,Receipt_Number__c 
                                        ,Opportunity__r.Project__r.Company__r.Name,Opportunity__r.Project__r.Company__r.Address__c,Opportunity__r.Project__r.Company__r.Email__c  from Receipt__c Where Id =: recorId Limit 1];
                
                List<Opportunity> oppDetails = [SELECT Id,Name,AccountId,Unit__r.Name,Booking_Date__c,(SELECT Id,Document_Id__c from Documents__r where Name = 'Receipts' LIMIT 1) from Opportunity where Id =: receiptRecord[0].Opportunity__c LIMIT 1];
                if(!oppDetails.isEmpty() && oppDetails[0].Documents__r != null){
                    parentFolderId = oppDetails[0].Documents__r[0].Document_Id__c;
                    docId = oppDetails[0].Documents__r[0].Id;
                }
                
                List<Account> mainAccount = [select id,Name,Permanent_Address__c,Salutation__c from Account where Id =: oppDetails[0].AccountId Limit 1];
                List<Applicant__c> coApplicantDetails;
                List<String> firstApplicantName = new List<String>();
                firstApplicantName.add(mainAccount[0].Salutation__c);
                firstApplicantName.add(mainAccount[0].Name);
                
                if(!receiptRecord.isEmpty() && receiptRecord[0].Opportunity__c != null){
                    coApplicantDetails = [SELECT Id,Name,Primary_Applicant__c,Account__r.Salutation__c,Permanent_Address__c,Permanent_Address__City__s,Account__r.Name from Applicant__c where Opportunity__c =: receiptRecord[0].Opportunity__c];
                }
                
                List<String> coApplicantList = new List<String>();
                if(!coApplicantDetails.isEmpty()){
                    for(Applicant__c app : coApplicantDetails){
                        List<String> coAppName = new List<String>();
                        coAppName.add(app.Account__r.Salutation__c);
                        coAppName.add(app.Account__r.Name);
                        coApplicantList.add(String.join(coAppName, '. '));
                    }
                }
                
                Digio_Integration__c customData = Digio_Integration__c.getValues('Digio');
                if(customData.Authorization__c != null && customData.Endpoint_URL__c != null){
                    String endpoint = customData.Endpoint_URL__c + '/v2/client/template/multi_templates/create_sign_request';
                    DigioWrapperClass.generateReceipt generateDoc = new DigioWrapperClass.generateReceipt();
                    Datetime now = System.now();
                    String formattedTimestamp = now.format('yyyy-MM-dd HH:mm:ss');
                    String fileName = 'Serenity Receipt - '+ formattedTimestamp;
                    generateDoc.file_name = fileName;
                    
                    DigioWrapperClass.signersList signer = new DigioWrapperClass.signersList();
                    signer.identifier = 'projects@snnestates.com';
                    signer.signer_tag = 'Signer 1';
                    signer.name = 'Snn';
                    signer.sign_type = 'document_review';
                    
                    generateDoc.signers = new List<DigioWrapperClass.signersList>{signer};
                    DigioWrapperClass.serenityReceiptTemplateList tempList = new DigioWrapperClass.serenityReceiptTemplateList();
                    tempList.template_key = customData.Serenity_Receipt_Template_Key__c;
                    
                    DigioWrapperClass.serenityReceiptTemplateValues templateVariables = new DigioWrapperClass.serenityReceiptTemplateValues();
                    templateVariables.receiptNo             = receiptRecord[0].Receipt_Number__c != null ? receiptRecord[0].Receipt_Number__c : '';
                    templateVariables.receiptDate           = receiptRecord[0].Receipt_Date__c != null ? String.valueOf(receiptRecord[0].Receipt_Date__c) : '';
                    templateVariables.projectName           = receiptRecord[0].Opportunity__r.Project__r.Name != null ? receiptRecord[0].Opportunity__r.Project__r.Name : '';
                    templateVariables.customerName          = !firstApplicantName.isEmpty() ? String.join(firstApplicantName, '. ') : '';
                    templateVariables.coApplicantName       = coApplicantList != null && !coApplicantList.isEmpty() ? String.join(coApplicantList, ', '): '';
                    templateVariables.modeOfPayment         = receiptRecord[0].Mode_Of_Payment__c != null ? receiptRecord[0].Mode_Of_Payment__c : '';
                    templateVariables.referenceNo           = receiptRecord[0].Reference_Number__c != null ? receiptRecord[0].Reference_Number__c : '';
                    templateVariables.chequeDate            = receiptRecord[0].Cheque_Date__c != null ? String.valueOf(receiptRecord[0].Cheque_Date__c) : '';
                    templateVariables.bankName              = (receiptRecord[0].Mode_Of_Payment__c == 'Cheque' || receiptRecord[0].Mode_Of_Payment__c == 'DD') && receiptRecord[0].Drawn_On_Bank__c != null ? receiptRecord[0].Drawn_On_Bank__c :
                        (receiptRecord[0].Mode_Of_Payment__c == 'EFT' || receiptRecord[0].Mode_Of_Payment__c == 'TDS') && receiptRecord[0].Bank__c != null ? receiptRecord[0].Bank__c :
                        (receiptRecord[0].Mode_Of_Payment__c == 'UPI' ) && receiptRecord[0].UPI_Provider__c != null ? receiptRecord[0].UPI_Provider__c :
                        (receiptRecord[0].Mode_Of_Payment__c == 'JV') && receiptRecord[0].JV_Reference_Number__c != null ? receiptRecord[0].JV_Reference_Number__c : '';
                    templateVariables.typeOfUnit            = receiptRecord[0].Opportunity__r.Unit__r.Unit_Type__c != null ? receiptRecord[0].Opportunity__r.Unit__r.Unit_Type__c : '';
                    templateVariables.flatNo                = receiptRecord[0].Opportunity__r.Unit__r.Name != null ? receiptRecord[0].Opportunity__r.Unit__r.Name : '';
                    templateVariables.unitNo                = receiptRecord[0].Opportunity__r.Unit__r.Unit_Name__c != null ? receiptRecord[0].Opportunity__r.Unit__r.Unit_Name__c : '';
                    templateVariables.blockName             = receiptRecord[0].Opportunity__r.Unit__r.Floor__r.Blocks__r.Name != null ? receiptRecord[0].Opportunity__r.Unit__r.Floor__r.Blocks__r.Name : '';
                    templateVariables.companyName           = receiptRecord[0].Opportunity__r.Project__r.Company__r.Name != null ? receiptRecord[0].Opportunity__r.Project__r.Company__r.Name : '';
                    templateVariables.companyAddress        = receiptRecord[0].Opportunity__r.Project__r.Company__r.Address__c != null ? receiptRecord[0].Opportunity__r.Project__r.Company__r.Address__c : '';
                    templateVariables.companyEmail          = receiptRecord[0].Opportunity__r.Project__r.Company__r.Email__c != null ? receiptRecord[0].Opportunity__r.Project__r.Company__r.Email__c : '';
                    templateVariables.amountValues          = receiptRecord[0].Amount__c != null  ? String.valueOf(receiptRecord[0].Amount__c) : '';
                    templateVariables.loginUserName         = UserInfo.getName();
                    templateVariables.amountInWords         = receiptRecord[0].Amount__c != null ? NumberToWordsHelper.numberToEnglish(Integer.valueOf(receiptRecord[0].Amount__c)) : 'Zero Rupees';
                    templateVariables.exactTime             = System.now().format('HH:mm:ss');
                    templateVariables.todayDate             = System.today();
                    if (!mainAccount.isEmpty() && mainAccount[0].Permanent_Address__c != null) {
                        System.Address address = mainAccount[0].Permanent_Address__c;
                        templateVariables.clientAddress = (address.getStreet() != null ? address.getStreet() + ', ' : '') + (address.getCity() != null ? address.getCity() + ', ' : '') + (address.getState() != null ? address.getState() + ', ' : '') + (address.getCountry() != null ? address.getCountry() + ', ' : '') + (address.getPostalCode() != null ? address.getPostalCode() : '');
                        templateVariables.clientAddress = templateVariables.clientAddress.trim().endsWith(',') ? templateVariables.clientAddress.substring(0, templateVariables.clientAddress.length() - 1) : templateVariables.clientAddress;
                    } else {
                        templateVariables.clientAddress = '';
                    }
                    tempList.template_values = templateVariables;
                    generateDoc.templates = new List<DigioWrapperClass.serenityReceiptTemplateList>{tempList};
                    String jsonBody = Json.serialize(generateDoc);
                    String authorizationValue = 'Basic' + ' ' +EncodingUtil.base64Encode(Blob.valueOf(customData.Client_ID__c + ':' + customData.Client_Secret__c));
                    String digiDocId = digioCalloutUtility.sendHttpRequest('POST', endpoint, authorizationValue, jsonBody);
                    wrapperRec.digiDocId = digiDocId;
                    if(digiDocId != null && fileName != null){
                        subDocUrl = digioCalloutUtility.downloadDocument(digiDocId, fileName, parentFolderId, docId);
                        wrapperRec.subDocUrl = subDocUrl;
                    }
                    return wrapperRec;
                }
            }
            return null;
        }catch(Exception e){
            system.debug('Error in generateDemandLetterDocument===> ' + e.getMessage());
            system.debug('Error line ===> ' + e.getLineNumber());
            return null;
        }
    }
    
    //Generate Statement of Accounts
    @AuraEnabled
    public static docwrpperClass generateStatementOfAccounts(String oppId){
        try{
            System.debug('oppId==>'+oppId);
            
            String coApplicantNames = '';
            List<Applicant__c> allApplicants = [select id,Name,Permanent_Address__c,Permanent_Address__PostalCode__s,Email__c,Primary_Contact_Number__c,Opportunity__r.Unit__c,Opportunity__r.Unit__r.Name,Opportunity__r.Unit__r.Unit_Type__c,Opportunity__r.Unit__r.Floor__c,Opportunity__r.Unit__r.Floor__r.Blocks__c,Opportunity__r.Unit__r.Floor__r.Name,Opportunity__r.Unit__r.Floor__r.Blocks__r.Name,Opportunity__r.Project__c,Opportunity__r.Project__r.Name,Primary_Applicant__c,Opportunity__r.Opportunity_Unique_Id__c,Permanent_Address__City__s from Applicant__c where Opportunity__c  =: oppId];
            System.debug('allApplicants==>'+allApplicants);
            List<Payment_Schedule__c>paymentScheduleRelatedToOpp = [select id,Name,Installment__c,Agreement_Value__c,Tax_Amount__c,(select id,Amount_Balance__c,Amount_Received__c,Total_Due_Amount__c from Demand_Letters__r ) from Payment_Schedule__c where Opportunity__c =: oppId];
            System.debug('paymentScheduleRelatedToOpp==>'+paymentScheduleRelatedToOpp);
            
            List<Opportunity> oppDetails = [SELECT Id,Name,AccountId,Unit__r.Name,Booking_Date__c,Project__r.Name,Unit__r.Floor__r.Blocks__r.Tower_Code__c,
            (SELECT Id,Document_Id__c from Documents__r where Name = 'Post Sales' LIMIT 1) from Opportunity where Id =: oppId LIMIT 1];
            String parentFolderId;
            String docId;
            String subDocUrl = '';
            docwrpperClass wrapperRec = new docwrpperClass();
            if(!oppDetails.isEmpty() && oppDetails[0].Documents__r != null){
                parentFolderId = oppDetails[0].Documents__r[0].Document_Id__c;
                docId = oppDetails[0].Documents__r[0].Id;
            }
            
            List<Account> mainApplicant = [select id,Name,W_o_S_o_D_o__c,Date_Of_Birth__c,PAN__c,Email__c,Permanent_Address__c,Phone from Account where Id =:oppDetails[0].AccountId Limit 1];
            for(Applicant__c applicant : allApplicants){
                
                if (String.isNotBlank(coApplicantNames)) {
                    coApplicantNames += ' ; ';
                }
                coApplicantNames += applicant.Name;
                
            }
            
            
            System.debug('coApplicantNames==>'+coApplicantNames);
            Digio_Integration__c customData = Digio_Integration__c.getValues('Digio');
            
            if(mainApplicant[0] != null && customData.Authorization__c != null && customData.Endpoint_URL__c != null && customData.Statement_of_Accounts_Template_Key__c != null){
                
                String endpoint = customData.Endpoint_URL__c + '/v2/client/template/multi_templates/create_sign_request';
                System.debug('endpoint ===> ' + endpoint);
                
                DigioWrapperClass.generateStatement generateDoc = new DigioWrapperClass.generateStatement();
                
                Datetime now = System.now();
                String formattedTimestamp = now.format('yyyy-MM-dd HH:mm:ss');
                System.debug('Formatted Timestamp: ' + formattedTimestamp);
                
                String fileName = 'Statement of Account - '+formattedTimestamp;
                generateDoc.file_name = fileName;
                
                DigioWrapperClass.signersList signer = new DigioWrapperClass.signersList();
                signer.identifier = 'projects@snnestates.com';
                signer.signer_tag = 'Signer 1';
                signer.name = 'Snn';
                signer.sign_type = 'document_review';
                
                generateDoc.signers = new List<DigioWrapperClass.signersList>{signer};
                
                DigioWrapperClass.accountStatementTemplateList tempList = new DigioWrapperClass.accountStatementTemplateList();
                tempList.template_key = customData.Statement_of_Accounts_Template_Key__c; //'TMP2412111746272701KTIMRW3B349OV';
                
                System.debug('mainApplicant==>'+mainApplicant);

                DigioWrapperClass.accountTemplateValues templateVariables = new DigioWrapperClass.accountTemplateValues();
                templateVariables.todayDate             = String.valueOf(Date.today());
                templateVariables.customerName          = mainApplicant[0].Name != null ? mainApplicant[0].Name: '';
                templateVariables.projectName           = oppDetails[0].Project__r.Name != null ? oppDetails[0].Project__r.Name : '';
                templateVariables.unitNo                = oppDetails[0].Unit__r.Name != null ? oppDetails[0].Unit__r.Name : '';
                // templateVariables.blockNo               = oppDetails[0].Unit__r.Floor__r.Blocks__r.Name != null ? oppDetails[0].Unit__r.Floor__r.Blocks__r.Name : '';
                templateVariables.towerCode             = oppDetails[0].Unit__r.Floor__r.Blocks__r.Tower_Code__c != null ? oppDetails[0].Unit__r.Floor__r.Blocks__r.Tower_Code__c : '';

                templateVariables.generatedTime         = System.now().format('HH:mm:ss');
                templateVariables.userName              = UserInfo.getName();
                // templateVariables.todayTime             = System.now().format('HH:mm:ss');
                
                if (mainApplicant[0].Permanent_Address__c != null) {
                    System.Address address = mainApplicant[0].Permanent_Address__c;
                    templateVariables.customerAddress =
                        (address.getStreet() != null ? address.getStreet() + ', ' : '') +
                        (address.getCity() != null ? address.getCity() + ', ' : '') +
                        (address.getState() != null ? address.getState() + ', ' : '') +
                        (address.getCountry() != null ? address.getCountry() + ', ' : '') +
                        (address.getPostalCode() != null ? address.getPostalCode() : '');
                    
                    templateVariables.customerAddress = templateVariables.customerAddress.trim().endsWith(',')
                        ? templateVariables.customerAddress.substring(0, templateVariables.customerAddress.length() - 1)
                        : templateVariables.customerAddress;
                } else {
                    templateVariables.customerAddress = '';
                }
                
                DigioWrapperClass.accountScheduleDynamicTable tableValues = new DigioWrapperClass.accountScheduleDynamicTable();
                list<DigioWrapperClass.statementOfAccountTable> paymentScheduleList = new List<DigioWrapperClass.statementOfAccountTable>();
                
                Decimal totalBilledAmount = 0;
                Decimal totalReceivedAmount = 0;
                Decimal totalBalanceAmount = 0;
                
                if(!paymentScheduleRelatedToOpp.isEmpty()){
                    for(Payment_Schedule__c paySchedule : paymentScheduleRelatedToOpp){
                        DigioWrapperClass.statementOfAccountTable paymentSchedule = new DigioWrapperClass.statementOfAccountTable();
                        paymentSchedule.particularData = paySchedule.Name != null ? String.valueOf(paySchedule.Name) : '';
                        paymentSchedule.totalBilled = paySchedule.Agreement_Value__c != null ? paySchedule.Agreement_Value__c : 0;
                        for(Demand_Letter__c dl : paySchedule.Demand_Letters__r){
                            paymentSchedule.amountReceived = dl.Amount_Balance__c != null ? dl.Amount_Balance__c : 0;
                            paymentSchedule.amountBalance = dl.Total_Due_Amount__c != null ? dl.Total_Due_Amount__c : 0;
                        }
                        if (paymentSchedule != null) {
                            totalBilledAmount += (paymentSchedule.totalBilled != null) ? paymentSchedule.totalBilled : 0;
                            totalReceivedAmount += (paymentSchedule.amountReceived != null) ? paymentSchedule.amountReceived : 0;
                            totalBalanceAmount += (paymentSchedule.amountBalance != null) ? paymentSchedule.amountBalance : 0;
                        }
                        paymentScheduleList.add(paymentSchedule);
                    }
                    tableValues.statementOfAccountTable = paymentScheduleList;
                    
                    list<DigioWrapperClass.statementOfScheduleTable> totalScheduleList = new List<DigioWrapperClass.statementOfScheduleTable>();
                    DigioWrapperClass.statementOfScheduleTable scheduleTotal = new DigioWrapperClass.statementOfScheduleTable();
                    scheduleTotal.Total = 'Total';
                    scheduleTotal.FinaltotalBilled = totalBilledAmount;
                    scheduleTotal.FinalamountReceived = totalReceivedAmount;
                    scheduleTotal.FinalamountBalance = totalBalanceAmount;
                    totalScheduleList.add(scheduleTotal);
                    tableValues.statementOfScheduleTable = totalScheduleList;
                }
                
                List<Receipt__c > receiptsRelatedToOpp = [select id,Name,Receipt_Date__c,Mode_Of_Payment__c,Cheque_Number__c,Cheque_Date__c,Bank__c,Amount__c,Opportunity__c,DD_Number__c,DD_Date__c,Transaction_Reference_Number__c,Fund_Transfer_Date__c,JV_Date__c,JV_Reference_Number__c,Receipt_Number__c  from Receipt__c where Opportunity__c =: oppId];
                
                Decimal finalTotalAmount = 0;
                if(!receiptsRelatedToOpp.isEmpty()){
                    List<DigioWrapperClass.statementOfReceipt> receiptsList = new List<DigioWrapperClass.statementOfReceipt>();
                    for(Receipt__c receipt : receiptsRelatedToOpp){
                        DigioWrapperClass.statementOfReceipt receipts = new DigioWrapperClass.statementOfReceipt();
                        receipts.receiptNo = receipt.Receipt_Number__c != null ? receipt.Receipt_Number__c : '';
                        receipts.receiptDate = receipt.Receipt_Date__c != null ? String.valueOf(receipt.Receipt_Date__c) : '';
                        
                        receipts.paymentCategory = receipt.Mode_Of_Payment__c != null ? receipt.Mode_Of_Payment__c : '';
                        
                        if(receipt.Mode_Of_Payment__c != null || receipt.Mode_Of_Payment__c != ''){
                            if(receipts.paymentCategory == 'Cheque'){
                                receipts.instrumentNo = receipt.Cheque_Number__c != null ? String.valueOf(receipt.Cheque_Number__c) : null;
                                receipts.instrumentDate = receipt.Cheque_Date__c != null ? String.valueOf(receipt.Cheque_Date__c) : '';
                            }else if(receipts.paymentCategory == 'DD'){
                                receipts.instrumentNo = receipt.DD_Number__c != null ? String.valueOf(receipt.DD_Number__c) : null;
                                receipts.instrumentDate = receipt.DD_Date__c != null ? String.valueOf(receipt.DD_Date__c) : '';
                            }else if(receipts.paymentCategory == 'JV'){
                                receipts.instrumentNo = receipt.JV_Reference_Number__c != null ? String.valueOf(receipt.JV_Reference_Number__c) : null;
                                receipts.instrumentDate = receipt.JV_Date__c != null ? String.valueOf(receipt.JV_Date__c) : '';
                            }else{
                                receipts.instrumentNo = receipt.Transaction_Reference_Number__c != null ? String.valueOf(receipt.Transaction_Reference_Number__c) : null;
                                receipts.instrumentDate = receipt.Fund_Transfer_Date__c != null ? String.valueOf(receipt.Fund_Transfer_Date__c) : '';
                            }
                        }
                        receipts.bankName = receipt.Bank__c != null ? receipt.Bank__c : '';
                        receipts.amount = receipt.Amount__c != null ? receipt.Amount__c : 0;
                        
                        finalTotalAmount += receipts.amount;
                        receiptsList.add(receipts);
                        tableValues.statementOfReceipt = receiptsList;
                        List<DigioWrapperClass.statementOfReceiptTotal> totalReceiptsList = new List<DigioWrapperClass.statementOfReceiptTotal>();
                        DigioWrapperClass.statementOfReceiptTotal totalReceipt = new DigioWrapperClass.statementOfReceiptTotal();
                        totalReceipt.Finalamount = finalTotalAmount;
                        totalReceiptsList.add(totalReceipt);
                        tableValues.statementOfReceiptTotal = totalReceiptsList;
                    }
                }
                
                tempList.template_values = templateVariables;
                tempList.template_table_values = tableValues;
                generateDoc.templates = new List<DigioWrapperClass.accountStatementTemplateList>{tempList};
                
                system.debug('generateDoc ===> ' + generateDoc);
                system.debug('serialize json ===> ' + Json.serialize(generateDoc));
                
                String jsonBody = Json.serialize(generateDoc);
                // String authorizationValue = 'Basic' + ' ' +EncodingUtil.base64Encode(Blob.valueOf(customData.Client_ID__c + ':' + customData.Client_Secret__c));
                // System.debug('authorizationValue==>'+authorizationValue);
                
                String digiDocId = digioCalloutUtility.sendHttpRequest('POST', endpoint, customData.Authorization__c, jsonBody);
                wrapperRec.digiDocId = digiDocId;
                if(digiDocId != null && fileName != null){
                    subDocUrl = digioCalloutUtility.downloadDocument(digiDocId, fileName, parentFolderId, docId);
                    wrapperRec.subDocUrl = subDocUrl;
                    System.debug('subDocUrl ===> ' + subDocUrl);
                }
                return wrapperRec;
            }
            return null;
        }catch(Exception e){
            system.debug('Error in generateDemandLetterDocument===> ' + e.getMessage());
            system.debug('Error line ===> ' + e.getLineNumber());
            return null;
        }
        
    }

    //generate Demand Letter
    @AuraEnabled
    public static  docwrpperClass generateDemandLetter(String oppId){
        try{
            System.debug('oppId==>'+oppId);
            Opportunity  oppRecord = [select id,AccountId,Phone__c,Opportunity_Unique_Id__c,Project__r.Name,(SELECT Id,Document_Id__c from Documents__r where Name = 'Demand Letters' LIMIT 1) from Opportunity where id=:oppId Limit 1];
            if(oppRecord != null && oppRecord.AccountId != null){
                Contact conRecord =  [select id,AccountId,Name,MailingAddress,MailingPostalCode,GenderIdentity  from Contact where AccountId =:oppRecord.AccountId Limit 1];
                
                String parentFolderId;
                String docId;
                String subDocUrl = '';
                docwrpperClass wrapperRec = new docwrpperClass();
                if(oppRecord != null && oppRecord.Documents__r != null){
                    parentFolderId = oppRecord.Documents__r[0].Document_Id__c;
                    docId = oppRecord.Documents__r[0].Id;
                }
                Digio_Integration__c customData = Digio_Integration__c.getValues('Digio');
                if(customData.Authorization__c != null && customData.Endpoint_URL__c != null){
                    String endpoint = customData.Endpoint_URL__c + '/v2/client/template/multi_templates/create_sign_request';
                    System.debug('endpoint ===> ' + endpoint);
                    DigioWrapperClass.demandLetterTemplate generateDoc = new DigioWrapperClass.demandLetterTemplate();
                    Datetime now = System.now();
                    String formattedTimestamp = now.format('yyyy-MM-dd HH:mm:ss');
                    System.debug('Formatted Timestamp: ' + formattedTimestamp);
                    
                    String fileName = 'Demand Letter - '+formattedTimestamp;
                    generateDoc.file_name = fileName;
                    
                    DigioWrapperClass.signersList signer = new DigioWrapperClass.signersList();
                    signer.identifier = 'projects@snnestates.com';
                    signer.signer_tag = 'Signer 1';
                    signer.name = 'Snn';
                    signer.sign_type = 'document_review';
                    
                    generateDoc.signers = new List<DigioWrapperClass.signersList>{signer};
                    
                    DigioWrapperClass.demandLetterTemplateValuesList tempList = new DigioWrapperClass.demandLetterTemplateValuesList();
                    // tempList.template_key = 'TMP2412141842042578PU1UG2C31SBOG';
                    tempList.template_key = customData.Demand_Letter_Template_Key__c;
                    
                    DigioWrapperClass.demandLetterTemplateValues templateVariables = new DigioWrapperClass.demandLetterTemplateValues();
                    templateVariables.TodayDate             =          Date.Today();
                    
                    if(conRecord.GenderIdentity != null){
                        if(conRecord.GenderIdentity == 'Male'){
                            templateVariables.customerName          =      conRecord.Name != null ? 'Mr. '+conRecord.Name: '';
                        }else if(conRecord.GenderIdentity == 'Female'){
                            templateVariables.customerName          =      conRecord.Name != null ? 'Ms. '+conRecord.Name: '';
                        }
                    }else{
                        templateVariables.customerName      =      conRecord.Name != null ? conRecord.Name: '';
                    }
                    
                    templateVariables.customerPincode       =          conRecord.MailingPostalCode != null ? conRecord.MailingPostalCode: '';
                    templateVariables.mobileNo              =          oppRecord.Phone__c != null ? oppRecord.Phone__c: '';
                    templateVariables.SubjectName           =          'Pending Payment Schedules for Constructed Floor';
                    templateVariables.projectName           =        oppRecord.Project__r.Name != null ? oppRecord.Project__r.Name : '' ;
                    
                    List<SNN_Bank_Details__c> bankDetailsList = [SELECT Account_Number__c, Bank_Name__c, Branch__c,IFSC_Code__c,Type_of_Account__c,Name FROM SNN_Bank_Details__c];
                    templateVariables.bankName              =          bankDetailsList[0].Bank_Name__c != null ? bankDetailsList[0].Bank_Name__c: '';
                    templateVariables.accountNo              =          bankDetailsList[0].Account_Number__c != null ? bankDetailsList[0].Account_Number__c: '';
                    templateVariables.ifscCode              =          bankDetailsList[0].IFSC_Code__c != null ? bankDetailsList[0].IFSC_Code__c: '';
                    templateVariables.dueDate              =          Date.today().addDays(7);
                    templateVariables.exactTime              =           System.now().format('HH:mm:ss');
                    templateVariables.currentUser       =          UserInfo.getName();
                    
                    
                    
                    
                    if (conRecord.MailingAddress != null) {
                        System.Address address = conRecord.MailingAddress;
                        
                        templateVariables.customerAddress =
                            (address.getStreet() != null ? address.getStreet() + ', ' : '') +
                            (address.getCity() != null ? address.getCity() + ', ' : '') +
                            (address.getState() != null ? address.getState() + ', ' : '') +
                            (address.getCountry() != null ? address.getCountry() : '');
                        
                        templateVariables.customerAddress = templateVariables.customerAddress.trim().endsWith(',')
                            ? templateVariables.customerAddress.substring(0, templateVariables.customerAddress.length() - 1)
                            : templateVariables.customerAddress;
                    } else {
                        templateVariables.customerAddress = '';
                    }
                    
                    tempList.template_values = templateVariables;
                    
                    List<Payment_Schedule__c> PaymentScheduleRecords = [SELECT Id, Name, Installment__c, Due_Date__c, Tax_Amount__c, CreatedDate,Agreement_Value__c,(select id,Amount_Balance__c,Amount_Received__c,Total_Due_Amount__c from Demand_Letters__r Where Total_Due_Amount__c !=0)  FROM Payment_Schedule__c WHERE Opportunity__c = :oppId AND Due_Date__c = :Date.today().addDays(15)];
                    System.debug('paymentScheduleRecords==>'+PaymentScheduleRecords);
                    DigioWrapperClass.demandLetterPaymentScheduleTable tableValues = new DigioWrapperClass.demandLetterPaymentScheduleTable();
                    list<DigioWrapperClass.demandLetterTable> DemandLetterTable1 = new List<DigioWrapperClass.demandLetterTable>();
                    
                    Decimal totalScheduleAmount = 0;
                    
                    List<Payment_Schedule__c> paymentSchedulesToUpdate = new List<Payment_Schedule__c>();
                    if(PaymentScheduleRecords.size() > 0){
                        for(Payment_Schedule__c paySch :PaymentScheduleRecords){
                            DigioWrapperClass.demandLetterTable paySchTable = new DigioWrapperClass.demandLetterTable();
                            
                            paySchTable.bookingAgreementToSell = paySch.Name != null ? String.valueOf(paySch.Name) : '';
                            paySchTable.showValueIn = paySch.Installment__c != null ? paySch.Installment__c : 0;
                            paySchTable.dueDate = paySch.Due_Date__c != null ? paySch.Due_Date__c.format() : null;
                            paySchTable.dueAmount = paySch.Agreement_Value__c != null ? paySch.Agreement_Value__c : 0;
                            // if(paySch.Demand_Letters__r != null && !paySch.Demand_Letters__r.isEmpty()){
                                //     for(Demand_Letter__c dl : paySch.Demand_Letters__r){
                                    //         paySchTable.dueAmount = dl.Total_Due_Amount__c != null ? dl.Total_Due_Amount__c : 0;
                                    //         paySchTable.totalScheduledDueAmount = dl.Total_Due_Amount__c != null ? dl.Total_Due_Amount__c : 0;
                                    //         totalScheduleAmount += Integer.valueOf(paySchTable.totalScheduledDueAmount) ;
                                //     }
                            // }
                            paySchTable.taxesAmout = paySch.Tax_Amount__c != null ? paySch.Tax_Amount__c : 0;
                            paySchTable.totalScheduledDueAmount = (paySchTable.dueAmount != null ? paySchTable.dueAmount:0) + paySchTable.taxesAmout;
                            totalScheduleAmount = totalScheduleAmount + paySchTable.totalScheduledDueAmount;
                            DemandLetterTable1.add(paySchTable);
                            paySch.Demand_Letter_Sent__c = True;
                            paymentSchedulesToUpdate.add(paySch);
                            
                        }
                        if(!paymentSchedulesToUpdate.isEmpty()){

                            update paymentSchedulesToUpdate;

                            Task t = new Task();
                            t.Subject = 'Update Registration Date';
                            t.WhatId = oppId; // Tag task to the Opportunity
                            t.Status = 'Not Started'; // adjust as per your org picklist
                            t.Priority = 'Normal';    // adjust as per your org picklist
                            
                            insert t;

                            Opportunity OppUpdate = new Opportunity();

                             OppUpdate.StageName = 'Registration';
                             OppUpdate.Id = oppId;
                             update OppUpdate;

                            
                        }
                        
                    }else {
                        // Assigning empty values for one record
                        DigioWrapperClass.demandLetterTable emptyTable = new DigioWrapperClass.demandLetterTable();
                        emptyTable.bookingAgreementToSell = '';
                        emptyTable.showValueIn = 0;
                        emptyTable.dueDate = null;
                        emptyTable.dueAmount = 0;
                        emptyTable.totalScheduledDueAmount = 0;
                        emptyTable.taxesAmout = 0;
                        
                        DemandLetterTable1.add(emptyTable);
                    }
                    DigioWrapperClass.demandLetterPaymentScheduleTable tableValues1 = new DigioWrapperClass.demandLetterPaymentScheduleTable();
                    tableValues1.DemandLetterTable = DemandLetterTable1;
                    tempList.template_table_values = tableValues1;
                    
                    list<DigioWrapperClass.demandLetterTotal> DemandLetterTotalTable = new List<DigioWrapperClass.demandLetterTotal>();
                    DigioWrapperClass.demandLetterTotal paySchTotal = new DigioWrapperClass.demandLetterTotal();
                    paySchTotal.FinalScheduleAmount = totalScheduleAmount;
                    paySchTotal.FinallessTotalAmount = 0;
                    paySchTotal.FinallessTdsAmount = 0;
                    paySchTotal.FinalbalancePaybleAmount = paySchTotal.FinalScheduleAmount - paySchTotal.FinallessTotalAmount;
                    DemandLetterTotalTable.add(paySchTotal);
                    
                    tableValues1.DemandLetterTotalTable = DemandLetterTotalTable;
                    tempList.template_table_values = tableValues1;
                    
                    generateDoc.templates = new List<DigioWrapperClass.demandLetterTemplateValuesList>{tempList};
                    
                    system.debug('generateDoc ===> ' + generateDoc);
                    system.debug('serialize json ===> ' + Json.serialize(generateDoc));
                    
                    String jsonBody = Json.serialize(generateDoc);
                    String authorizationValue = 'Basic' + ' ' +EncodingUtil.base64Encode(Blob.valueOf(customData.Client_ID__c + ':' + customData.Client_Secret__c));
                    System.debug('authorizationValue==>'+authorizationValue);
                    
                    String digiDocId = digioCalloutUtility.sendHttpRequest('POST', endpoint, authorizationValue, jsonBody);
                    wrapperRec.digiDocId = digiDocId ;
                    if(digiDocId != null && fileName != null){
                        subDocUrl = digioCalloutUtility.downloadDocument(digiDocId, fileName, parentFolderId, docId);
                        wrapperRec.subDocUrl = subDocUrl ;
                        System.debug('subDocUrl ===> ' + subDocUrl);
                    }
                    
                }
                return wrapperRec;
            }
            return null;
        }catch(Exception e){
            system.debug('Error in generateDemandLetterDocument===> ' + e.getMessage());
            system.debug('Error line ===> ' + e.getLineNumber());
            return null;
        }
    }
    
    //generate costSheet
    @AuraEnabled
    public static  docwrpperClass generateCostSheet(String costSheetId){
        try{
            System.debug('costSheetId==>'+costSheetId);
            if(costSheetId != null){
                List<Cost_Sheet__c> selectedCostSheet = [select id,Name,Opportunity__r.Project__r.Name,Opportunity__r.Unit__r.Unit_Name__c, Opportunity__r.Name,Opportunity__c,Unit__r.Unit_Type__c,Unit__r.Floor__r.Floor_No__c,Unit__r.Super_Built_Up_Area_sq_ft__c,Unit__r.Total__c,Total_Pricing_Value__c,Cost_Scheme_Linking__c,Unit__r.Unit_Name__c,Unit__r.Base_Price_per_sqft__c from Cost_Sheet__c where id=:costSheetId Limit 1];
                List<Opportunity>  oppRecord  = [SELECT Id,SGST_Tax_Amount__c,CGST_Tax_Amount__c,Total_Outstanding_Amount__c ,Unit__r.Unit_Type__c,Unit__r.Floor__r.Floor_No__c,Unit__r.Super_Built_Up_Area_sq_ft__c,Unit__r.Floor__r.Blocks__r.Parking_Availability__c,Unit__r.Total__c,Opportunity_Unique_Id__c,Cost_Sheet_Template__c ,(SELECT Id,Document_Id__c from Documents__r where Name = 'Sales' LIMIT 1)
                                         From Opportunity WHERE Id =: selectedCostSheet[0].Opportunity__c LIMIT 1];
                String parentFolderId;
                String docId;
                String subDocUrl = '';
                docwrpperClass wrapperRec = new docwrpperClass();
                if(!oppRecord.isEmpty() && oppRecord[0].Documents__r != null){
                    parentFolderId = oppRecord[0].Documents__r[0].Document_Id__c;
                    docId = oppRecord[0].Documents__r[0].Id;
                }
                
                Digio_Integration__c customData = Digio_Integration__c.getValues('Digio');
                if(!oppRecord.isEmpty() && !selectedCostSheet.isEmpty() && customData.Authorization__c != null && customData.Endpoint_URL__c != null){
                    String endpoint = customData.Endpoint_URL__c + '/v2/client/template/multi_templates/create_sign_request';
                    DigioWrapperClass.costSheetTemplate generateDoc = new DigioWrapperClass.costSheetTemplate();
                    Datetime now = System.now();
                    String formattedTimestamp = now.format('yyyy-MM-dd HH:mm:ss');
                    String fileName = 'Cost Sheet - '+formattedTimestamp;
                    generateDoc.file_name = fileName;
                    DigioWrapperClass.signersList signer = new DigioWrapperClass.signersList();
                    signer.identifier = 'projects@snnestates.com';
                    signer.signer_tag = 'Signer 1';
                    signer.name = 'Snn';
                    signer.sign_type = 'document_review';
                    
                    generateDoc.signers = new List<DigioWrapperClass.signersList>{signer};
                    DigioWrapperClass.costSheetTemplateValuesList tempList = new DigioWrapperClass.costSheetTemplateValuesList();
                    tempList.template_key = customData.Cost_Sheet_Template_Key__c;
                    
                    DigioWrapperClass.costSheetTemplateValues costSheetTable = new DigioWrapperClass.costSheetTemplateValues();
                    costSheetTable.typeOfUnit       = selectedCostSheet[0].Opportunity__r.Unit__r.Unit_Name__c != null ?  selectedCostSheet[0].Opportunity__r.Unit__r.Unit_Name__c : '';
                    costSheetTable.projectName      = selectedCostSheet[0].Opportunity__r.Project__r.Name != null ?  selectedCostSheet[0].Opportunity__r.Project__r.Name : '';
                    costSheetTable.floorNumber      = selectedCostSheet[0].Unit__r.Floor__r.Floor_No__c != null ? (Integer) selectedCostSheet[0].Unit__r.Floor__r.Floor_No__c : null;
                    costSheetTable.superBuiltupArea = selectedCostSheet[0].Unit__r.Super_Built_Up_Area_sq_ft__c != null ?  selectedCostSheet[0].Unit__r.Super_Built_Up_Area_sq_ft__c : 0;
                    costSheetTable.basicPrice       = selectedCostSheet[0].Unit__r.Base_Price_per_sqft__c != null ? (Integer) selectedCostSheet[0].Unit__r.Base_Price_per_sqft__c : 0;
                    Integer unitTotal = selectedCostSheet[0].Unit__r.Total__c != null ?  (Integer) selectedCostSheet[0].Unit__r.Total__c : 0;
                    Decimal totalAmount = selectedCostSheet[0].Total_Pricing_Value__c != null ? selectedCostSheet[0].Total_Pricing_Value__c : 0;
                    SNN_JP_Nagar_Details__c addressDetail = [SELECT Name,JP_Nagar_Address__c FROM SNN_JP_Nagar_Details__c Where Name =:'JP Nagar Address'  LIMIT 1];
                    if (addressDetail != null) {
                        costSheetTable.addressDetail = addressDetail.JP_Nagar_Address__c;
                    }
                    DigioWrapperClass.costSheetPaymentTable tableValues = new DigioWrapperClass.costSheetPaymentTable();
                    list<DigioWrapperClass.costSheetAssociationTable> costPaymentAssociationList = new List<DigioWrapperClass.costSheetAssociationTable>();
                    if(selectedCostSheet[0].Id != null){
                        costSheetTable.apartmentPrice = 0;
                        List<Pricing_Element__c> costAssociations = [select id,Pricing_Element_Master__c,Amount__c,Pricing_Element_Master__r.Name,Cost_Sheet__c,Actual_Amount__c,Total_Amount_Excluding_Tax__c from Pricing_Element__c where Cost_Sheet__c =: selectedCostSheet[0].Id];
                        for(Pricing_Element__c ca : costAssociations){
                            DigioWrapperClass.costSheetAssociationTable costSheetPaymentTable = new DigioWrapperClass.costSheetAssociationTable();
                            costSheetPaymentTable.floorRise         = ca.Pricing_Element_Master__r.Name != null ? String.valueOf(ca.Pricing_Element_Master__r.Name) : '';
                            costSheetPaymentTable.amount = ca.Total_Amount_Excluding_Tax__c != null ? ca.Total_Amount_Excluding_Tax__c : null;
                            costSheetTable.apartmentPrice   =   (costSheetTable.apartmentPrice != null ? costSheetTable.apartmentPrice : 0) + (Integer) costSheetPaymentTable.amount;
                            costPaymentAssociationList.add(costSheetPaymentTable);
                        }
                        costSheetTable.cgstData = oppRecord[0].CGST_Tax_Amount__c != null ? oppRecord[0].CGST_Tax_Amount__c : 0; //Math.round(costSheetTable.apartmentPrice * 0.025 * 100) / 100;
                        costSheetTable.sgstData = oppRecord[0].SGST_Tax_Amount__c != null ? oppRecord[0].SGST_Tax_Amount__c : 0; //Math.round(costSheetTable.apartmentPrice * 0.025 * 100) / 100;
                        costSheetTable.totalValue = (costSheetTable.apartmentPrice != null ? costSheetTable.apartmentPrice : 0) + (costSheetTable.cgstData != null ? costSheetTable.cgstData : 0) + (costSheetTable.sgstData != null ? costSheetTable.sgstData : 0);
                    }else{
                        DigioWrapperClass.costSheetAssociationTable costSheetPaymentTable = new DigioWrapperClass.costSheetAssociationTable();
                        costSheetPaymentTable.floorRise         =  '';
                        costSheetPaymentTable.amount =  null;
                        costPaymentAssociationList.add(costSheetPaymentTable);
                    }
                    tableValues.costSheetAssociation = costPaymentAssociationList;
                    tempList.template_table_values = tableValues;
                    
                    list<DigioWrapperClass.costSheetTable> paymentScheduleList = new List<DigioWrapperClass.costSheetTable>();
                    List<Payment_Schedule__c > paymentSclList = [select Id,Agreement_Value__c,Installment__c,Name,Due_Date__c FROM Payment_Schedule__c Where Opportunity__c  =: selectedCostSheet[0].Opportunity__c];
                    System.debug('paymentSclList==>'+paymentSclList.size());
                    Integer TotalAmountsvaluepayment = 0;
                    for(Payment_Schedule__c ps : paymentSclList){
                        DigioWrapperClass.costSheetTable costSheetPaymentTable = new DigioWrapperClass.costSheetTable();
                        costSheetPaymentTable.breakup = ps.Installment__c != null ? String.valueOf(ps.Installment__c) + '%' : '';
                        costSheetPaymentTable.paymentSchedule   = ps.Name != null ? ps.Name : null;
                        costSheetPaymentTable.installDate   = ps.Due_Date__c != null ? ps.Due_Date__c : null;
                        costSheetPaymentTable.amountValue = (costSheetTable.totalValue * (costSheetPaymentTable.breakup != null ? Decimal.valueOf(costSheetPaymentTable.breakup.replace('%', '')) : 0)) / 100;
                        if(costSheetPaymentTable.amountValue != null){
                            TotalAmountsvaluepayment += Math.round(costSheetPaymentTable.amountValue);
                        }
                        paymentScheduleList.add(costSheetPaymentTable);
                    }
                    costSheetTable.totalAmount = TotalAmountsvaluepayment != null ? TotalAmountsvaluepayment : null;
                    tempList.template_values = costSheetTable;
                    tableValues.costSheetTable = paymentScheduleList;
                    tempList.template_table_values = tableValues;
                    
                    generateDoc.templates = new List<DigioWrapperClass.costSheetTemplateValuesList>{tempList};
                    String jsonBody = Json.serialize(generateDoc);
                    String authorizationValue = 'Basic' + '' +EncodingUtil.base64Encode(Blob.valueOf(customData.Client_ID__c + ':' + customData.Client_Secret__c));
                    String digiDocId = digioCalloutUtility.sendHttpRequest('POST', endpoint, customData.Authorization__c, jsonBody);
                    wrapperRec.digiDocId = digiDocId ;
                    if(digiDocId != null && fileName != null){
                        subDocUrl = digioCalloutUtility.downloadDocument(digiDocId, fileName, parentFolderId, docId);
                        wrapperRec.subDocUrl = subDocUrl ;
                        
                    }
                    return wrapperRec;
                }
            }
            return null;
        }catch(Exception e){
            system.debug('Error in generateDemandLetterDocument===> ' + e.getMessage());
            system.debug('Error line ===> ' + e.getLineNumber());
            return null;
        }
    }
    
    Public class docwrpperClass{
        @AuraEnabled public String subDocUrl;
        @AuraEnabled public String digiDocId;
    }
    
    @AuraEnabled(cacheable=false)
    public static void sendigiodetails(String digiDocId ,string oppId,string docname){
        try{
            if(oppId != null && digiDocId != null && docname != null){
                Opportunity oppRec = [Select Id ,Email__c from Opportunity where Id =: oppId ];
                digioCalloutUtility.downloadDigioDocWithoutGDrive (digiDocId,oppRec.Id,docname);
            }
        }catch(Exception e){
            system.debug('Error ==> ' + e.getMessage());
            system.debug('Error in line ==> ' + e.getLineNumber());
        }
    }
    
    @AuraEnabled(cacheable=false)
    public static void sendigiodetails1(String digiDocId ,string recieptId,string docname){
        try{
            if(recieptId != null && digiDocId != null && docname != null){
                Receipt__c  recieptRec = [Select Id ,Opportunity__c  from Receipt__c where Id =: recieptId ];
                system.debug('recieptRec.Opportunity__c ==> ' +recieptRec.Opportunity__c);
                digioCalloutUtility.downloadDigioDocWithoutGDrive (digiDocId,recieptRec.Opportunity__c,docname);
            }
        }catch(Exception e){
            system.debug('Error ==> ' + e.getMessage());
            system.debug('Error in line ==> ' + e.getLineNumber());
        }
    }
    
    @AuraEnabled(cacheable=false)
    public static List<Cost_Sheet__c> getCostSheets(String oppId){
        try{
            System.debug('recordId ===> ' + oppId);
            List<Cost_Sheet__c> costSheetList = [SELECT Id,Name,finalize_CostSheet__c from Cost_Sheet__c where Opportunity__c =: oppId];
            System.debug('costSheetList ===> ' + costSheetList);
            return costSheetList;
        }catch(Exception e){
            system.debug('Error ==> ' + e.getMessage());
            system.debug('Error in line ==> ' + e.getLineNumber());
            return null;
        }
    }

    //genarte Prepare Sale and Construction Agreement
    @AuraEnabled
    public static docwrpperClass saleAndConstructionAgreement(String oppId){
        try{
            System.debug('recordId==>'+oppId);
            
            Opportunity  oppRecord  = [SELECT Id,Total_Outstanding_Amount__c ,Unit__r.Unit_Type__c,Unit__r.Floor__r.Floor_No__c,Unit__r.Super_Built_Up_Area_sq_ft__c,Unit__r.Floor__r.Blocks__r.Parking_Availability__c,Unit__r.Total__c,Opportunity_Unique_Id__c,Cost_Sheet_Template__c,Unit__r.Floor__r.Blocks__r.Tower_Code__c ,Unit__r.Unit_Name__c,Phone__c,AccountId,(SELECT Id,Document_Id__c from Documents__r where Name = 'Post Sales' LIMIT 1)
                                         From Opportunity WHERE Id =: oppId LIMIT 1];
            String parentFolderId;
            String docId;
            String subDocUrl = '';
            docwrpperClass wrapperRec = new docwrpperClass();
            if(oppRecord != null && oppRecord.Documents__r != null){
                parentFolderId = oppRecord.Documents__r[0].Document_Id__c;
                docId = oppRecord.Documents__r[0].Id;
            }
            
            Account  mainApplicant;
            List<Applicant__c> coApplicant = new List<Applicant__c>();
            mainApplicant = [select id,Name,W_o_S_o_D_o__c,Date_Of_Birth__c,PAN__c,Email__c,Permanent_Address__c,Aadhaar_Number__c from Account where Id =:oppRecord.AccountId];
            
            List<Applicant__c> allApplicants = [select id,Name,W_o_S_o_D_o__c,Account__r.Name,Account__r.W_o_S_o_D_o__c,Date_Of_Birth__c,Permanent_Address__c,Permanent_Address__PostalCode__s,Email__c,Primary_Contact_Number__c,Opportunity__r.Unit__c,Opportunity__r.Unit__r.Name,Opportunity__r.Unit__r.Unit_Type__c,Opportunity__r.Unit__r.Floor__c,Opportunity__r.Unit__r.Floor__r.Blocks__c,Opportunity__r.Unit__r.Floor__r.Name,Opportunity__r.Unit__r.Floor__r.Blocks__r.Name,Opportunity__r.Project__c,Opportunity__r.Project__r.Name,Primary_Applicant__c,Opportunity__r.Opportunity_Unique_Id__c,Permanent_Address__City__s,PAN__c,Account__r.Aadhaar_Number__c from Applicant__c where Opportunity__c  =: oppId];
            System.debug('allApplicants==>'+allApplicants);
            
            for(Applicant__c applicant : allApplicants){
                if(coApplicant.isEmpty()){
                    coApplicant.add(applicant);
                }
                
                
            }
            System.debug('coApplicants==>'+coApplicant);
            
            Digio_Integration__c customData = Digio_Integration__c.getValues('Digio');
            if(oppRecord != null && customData.Authorization__c != null && customData.Endpoint_URL__c != null){
                
                String endpoint = customData.Endpoint_URL__c + '/v2/client/template/multi_templates/create_sign_request';
                System.debug('endpoint ===> ' + endpoint);
                
                DigioWrapperClass.saleConsAgreement generateDoc = new DigioWrapperClass.saleConsAgreement();
                
                Datetime now = System.now();
                String formattedTimestamp = now.format('yyyy-MM-dd HH:mm:ss');
                System.debug('Formatted Timestamp: ' + formattedTimestamp);
                
                String fileName = 'Sale and Construction Agreement - '+formattedTimestamp;
                generateDoc.file_name = fileName;
                
                DigioWrapperClass.signersList signer = new DigioWrapperClass.signersList();
                signer.identifier = 'projects@snnestates.com';
                signer.signer_tag = 'Signer 1';
                signer.name = 'Snn';
                signer.sign_type = 'document_review';
                
                generateDoc.signers = new List<DigioWrapperClass.signersList>{signer};
                
                DigioWrapperClass.constructionAgreementValueList tempList = new DigioWrapperClass.constructionAgreementValueList();
                //tempList.template_key = 'TMP241216125304459Y1QXETY82KOUE6';
                tempList.template_key = customData.sale_And_Construction_Agreement__c;
                
                DigioWrapperClass.constructionTemplateValues applicantDetails = new DigioWrapperClass.constructionTemplateValues();
                applicantDetails.apartmentNo       = oppRecord.Unit__r.Floor__r.Blocks__r.Tower_Code__c != null ?  oppRecord.Unit__r.Floor__r.Blocks__r.Tower_Code__c : '';
                applicantDetails.bedRoomNo      = oppRecord.Unit__r.Unit_Type__c  != null ?  oppRecord.Unit__r.Unit_Type__c  : '';
                applicantDetails.contact = oppRecord.Phone__c != null ?  oppRecord.Phone__c : null;
                applicantDetails.area       = oppRecord.Unit__r.Super_Built_Up_Area_sq_ft__c != null ?  oppRecord.Unit__r.Super_Built_Up_Area_sq_ft__c : 0;
                List<Receipt__c> receipt = [select id,Bank__c,DD_Number__c,Receipt_Date__c,Total_Amount__c from Receipt__c Where Opportunity__c =:oppId Limit 1 ];
                
                applicantDetails.bankName = receipt[0].Bank__c != null ?  receipt[0].Bank__c : null;
                applicantDetails.ddNo = receipt[0].DD_Number__c != null ?  receipt[0].DD_Number__c : null;
                applicantDetails.dateNo = receipt[0].Receipt_Date__c != null ?  receipt[0].Receipt_Date__c : null;
                applicantDetails.amt = receipt[0].Total_Amount__c != null ?  receipt[0].Total_Amount__c : null;
                
                tempList.template_values = applicantDetails;
                
                DigioWrapperClass.constructionPaymentTable constructionTableValues = new DigioWrapperClass.constructionPaymentTable();
                
                list<DigioWrapperClass.saleConstructionFirstApplicantTable> firstApplicantList = new List<DigioWrapperClass.saleConstructionFirstApplicantTable>();
                if(mainApplicant != null){
                    DigioWrapperClass.saleConstructionFirstApplicantTable mainApplicantTable = new DigioWrapperClass.saleConstructionFirstApplicantTable();
                    mainApplicantTable.applicantName         = mainApplicant.Name != null ? mainApplicant.Name : '';
                    mainApplicantTable.relativeName = mainApplicant.W_o_S_o_D_o__c != null ? mainApplicant.W_o_S_o_D_o__c : '';
                    if (mainApplicant.Date_Of_Birth__c != null) {
                        Date birthDate = mainApplicant.Date_Of_Birth__c;
                        Date today = Date.today();
                        Integer age = today.year() - birthDate.year();
                        
                        // Check if the birthday has occurred this year
                        if (today < birthDate.addYears(age)) {
                            age -= 1; // Subtract one year if the birthday hasn't happened yet
                        }
                        
                        mainApplicantTable.age = age;
                    } else {
                        mainApplicantTable.age = null;
                    }
                    mainApplicantTable.dob = mainApplicant.Date_Of_Birth__c != null ? mainApplicant.Date_Of_Birth__c : null;
                    mainApplicantTable.aadhar         = mainApplicant.Aadhaar_Number__c != null ? mainApplicant.Aadhaar_Number__c : null;
                    mainApplicantTable.pan         = mainApplicant.PAN__c != null ? mainApplicant.PAN__c : null;
                    mainApplicantTable.email = mainApplicant.Email__c != null ? mainApplicant.Email__c : null;
                    if (mainApplicant.Permanent_Address__c != null) {
                        System.Address address = mainApplicant.Permanent_Address__c;
                        mainApplicantTable.address =
                            (address.getStreet() != null ? address.getStreet() + ', ' : '') +
                            (address.getCity() != null ? address.getCity() + ', ' : '') +
                            (address.getState() != null ? address.getState() + ', ' : '') +
                            (address.getCountry() != null ? address.getCountry() + ', ' : '') +
                            (address.getPostalCode() != null ? address.getPostalCode() : '');
                        
                        mainApplicantTable.address = mainApplicantTable.address.trim().endsWith(',')
                            ? mainApplicantTable.address.substring(0, mainApplicantTable.address.length() - 1)
                            : mainApplicantTable.address;
                    } else {
                        mainApplicantTable.address = '';
                    }
                    firstApplicantList.add(mainApplicantTable);
                    constructionTableValues.applicantTable = firstApplicantList;
                    tempList.template_table_values = constructionTableValues;
                }
                list<DigioWrapperClass.saleConstructionCoApplicantTable> secondApplicantList = new List<DigioWrapperClass.saleConstructionCoApplicantTable>();
                if(!coApplicant.isEmpty()){
                    
                    for(Integer i=0;i<coApplicant.size();i++){
                        DigioWrapperClass.saleConstructionCoApplicantTable coApplicantTable = new DigioWrapperClass.saleConstructionCoApplicantTable();
                        coApplicantTable.applicantName         = coApplicant[i].Name != null ? coApplicant[i].Name : '';
                        coApplicantTable.relativeName = coApplicant[i].Account__r.W_o_S_o_D_o__c != null ? coApplicant[i].Account__r.W_o_S_o_D_o__c : '';
                        
                        if (coApplicant[i].Date_Of_Birth__c != null) {
                            Date birthDate = coApplicant[i].Date_Of_Birth__c;
                            Date today = Date.today();
                            Integer age = today.year() - birthDate.year();
                            
                            // Check if the birthday has occurred this year
                            if (today < birthDate.addYears(age)) {
                                age -= 1; // Subtract one year if the birthday hasn't happened yet
                            }
                            
                            coApplicantTable.age = age;
                        } else {
                            coApplicantTable.age = null;
                        }
                        
                        coApplicantTable.dob = coApplicant[i].Date_Of_Birth__c != null ? coApplicant[i].Date_Of_Birth__c : null;
                        coApplicantTable.aadhar         = coApplicant[i].Account__r.Aadhaar_Number__c != null ? coApplicant[i].Account__r.Aadhaar_Number__c : null;
                        coApplicantTable.pan         = coApplicant[i].PAN__c != null ? coApplicant[i].PAN__c : null;
                        coApplicantTable.email = coApplicant[i].Email__c != null ? coApplicant[i].Email__c : null;
                        
                        if (coApplicant[i].Permanent_Address__c != null) {
                            System.Address address = coApplicant[i].Permanent_Address__c;
                            coApplicantTable.address =
                                (address.getStreet() != null ? address.getStreet() + ', ' : '') +
                                (address.getCity() != null ? address.getCity() + ', ' : '') +
                                (address.getState() != null ? address.getState() + ', ' : '') +
                                (address.getCountry() != null ? address.getCountry() + ', ' : '') +
                                (address.getPostalCode() != null ? address.getPostalCode() : '');
                            
                            coApplicantTable.address = coApplicantTable.address.trim().endsWith(',')
                                ? coApplicantTable.address.substring(0, coApplicantTable.address.length() - 1)
                                : coApplicantTable.address;
                        } else {
                            coApplicantTable.address = '';
                        }
                        secondApplicantList.add(coApplicantTable);
                        
                    }
                    
                    
                    
                    
                    
                    
                    constructionTableValues.applicantTable2 = secondApplicantList;
                    tempList.template_table_values = constructionTableValues;
                }
                list<DigioWrapperClass.constructionAssociationTable> costPaymentAssociationList = new List<DigioWrapperClass.constructionAssociationTable>();
                if(oppRecord.Cost_Sheet_Template__c != null){
                    List<Cost_Pricing_Association__c> costAssociations = [select id,Pricing_Element_Master__c,Amount__c,Pricing_Element_Master__r.Name from Cost_Pricing_Association__c where Cost_Sheet_Template__c =: oppRecord.Cost_Sheet_Template__c];
                    for(Cost_Pricing_Association__c ca : costAssociations){
                        DigioWrapperClass.constructionAssociationTable costSheetPaymentTable = new DigioWrapperClass.constructionAssociationTable();
                        costSheetPaymentTable.floorRise         = ca.Pricing_Element_Master__r.Name != null ? String.valueOf(ca.Pricing_Element_Master__r.Name) : '';
                        costSheetPaymentTable.amount = ca.Amount__c != null ? ca.Amount__c : null;
                        
                        costPaymentAssociationList.add(costSheetPaymentTable);
                    }
                    constructionTableValues.cSA = costPaymentAssociationList;
                    tempList.template_table_values = constructionTableValues;
                }
                generateDoc.templates = new List<DigioWrapperClass.constructionAgreementValueList>{tempList};
                system.debug('generateDoc ===> ' + generateDoc);
                system.debug('serialize json ===> ' + Json.serialize(generateDoc));
                
                String jsonBody = Json.serialize(generateDoc);
                String authorizationValue = 'Basic' + '' +EncodingUtil.base64Encode(Blob.valueOf(customData.Client_ID__c + ':' + customData.Client_Secret__c));
                System.debug('authorizationValue==>'+authorizationValue);
                
                String digiDocId = digioCalloutUtility.sendHttpRequest('POST', endpoint, customData.Authorization__c, jsonBody);
                wrapperRec.digiDocId = digiDocId ;
                if(digiDocId != null && fileName != null){
                    subDocUrl = digioCalloutUtility.downloadDocument(digiDocId, fileName, parentFolderId, docId);
                    wrapperRec.subDocUrl = subDocUrl ;
                }
                return wrapperRec;
            }
            return null;
        }catch(Exception e){
            system.debug('Error in generateDemandLetterDocument===> ' + e.getMessage());
            system.debug('Error line ===> ' + e.getLineNumber());
            return null;
        }
    }
    
    @AuraEnabled
    public static docwrpperClass generateWelcomeKit(String oppId){
        try{
            System.debug('oppId==>'+oppId);
            if(oppId != null){
                List<Opportunity> oppRecord = [SELECT Id,Name, Total_Outstanding_Amount__c ,Total_Amount_Collected__c,Project__r.Account_Name__c,Allotment_Letter_Generated_Date_Time__c, Opportunity_Unique_Id__c, Unit__r.Unit_Name__c,Agreement_Value__c, (SELECT Id,Account__r.Salutation__c,Account__r.Name from Applicants__r),Project__r.Company__r.PAN_No__c,Project__r.Company__r.Address__c,
                                                Project__r.Name, Booking_Date__c, Project__r.Project_Address__c,Project__r.Account_Number__c,Project__r.Type_of_Account__c,Project__r.Bank_Name__c,Project__r.Branch__c,Project__r.IFSC_Code__c, Project__r.Company__r.Name,Account.Salutation__c,Account.Name, (SELECT Id, Document_Id__c, Name FROM Documents__r WHERE Name = 'Post Sales' LIMIT 1) FROM Opportunity WHERE Id = :oppId LIMIT 1];
                String parentFolderId;
                String docId;
                String subDocUrl = '';
                docwrpperClass wrapperRec = new docwrpperClass();
                if(!oppRecord.isEmpty() && oppRecord[0].Documents__r != null){
                    parentFolderId = oppRecord[0].Documents__r[0].Document_Id__c;
                    docId = oppRecord[0].Documents__r[0].Id;
                }
                List<String> applicantNames = new List<String>();
                applicantNames.add((String.isNotBlank(oppRecord[0].Account.Salutation__c) ? oppRecord[0].Account.Salutation__c + ' ' : '') + oppRecord[0].Account.Name);
                if(oppRecord[0].Applicants__r.size() > 0){
                    for (Applicant__c app : oppRecord[0].Applicants__r) {
                        applicantNames.add((String.isNotBlank(app.Account__r.Salutation__c) ? app.Account__r.Salutation__c + ' ' : '') + app.Account__r.Name);
                    }
                }
                Digio_Integration__c customData = Digio_Integration__c.getValues('Digio');
                if(!oppRecord.isEmpty() && customData.Authorization__c != null && customData.Endpoint_URL__c != null){
                    String endpoint = customData.Endpoint_URL__c + '/v2/client/template/multi_templates/create_sign_request';
                    DigioWrapperClass.getWelcomeKit generateDoc = new DigioWrapperClass.getWelcomeKit();
                    Datetime now = System.now();
                    String fileName = oppRecord[0].Name + ' - Welcome Kit - ' + String.valueOf(DateTime.now().getTime() / 1000);
                    generateDoc.file_name = fileName;
                    
                    DigioWrapperClass.signersList signer = new DigioWrapperClass.signersList();
                    signer.identifier = 'projects@snnestates.com';
                    signer.signer_tag = 'Signer 1';
                    signer.name = 'Snn';
                    signer.sign_type = 'document_review';
                    generateDoc.signers = new List<DigioWrapperClass.signersList>{signer};
                    DigioWrapperClass.wlcomeKitValueList tempList = new DigioWrapperClass.wlcomeKitValueList();
                    tempList.template_key = customData.welComeKit_Template_Key__c;
                    DigioWrapperClass.welcomeKitTemplateValues welcomeKitDetail = new DigioWrapperClass.welcomeKitTemplateValues();
                    welcomeKitDetail.todayDate          = System.Today();
                    welcomeKitDetail.unitNumber         = oppRecord[0].Unit__r.Unit_Name__c != null ? oppRecord[0].Unit__r.Unit_Name__c : '';
                    welcomeKitDetail.loggedInUserName   = UserInfo.getName();
                    welcomeKitDetail.allApplicantNames  = !applicantNames.isEmpty() ? String.join(applicantNames, ',') : '';
                    welcomeKitDetail.bookingDate        = oppRecord[0].Booking_Date__c != null ?  oppRecord[0].Booking_Date__c  : null;
                    welcomeKitDetail.companyName        = oppRecord[0].Project__r.Company__r.Name != null ? oppRecord[0].Project__r.Company__r.Name : '';
                    welcomeKitDetail.companyAddress     = oppRecord[0].Project__r.Company__r.Address__c != null ? oppRecord[0].Project__r.Company__r.Address__c : '';
                    welcomeKitDetail.companyPan         = oppRecord[0].Project__r.Company__r.PAN_No__c != null ? oppRecord[0].Project__r.Company__r.PAN_No__c : '';
                    welcomeKitDetail.projectAddress     = oppRecord[0].Project__r.Project_Address__c  != null ?  oppRecord[0].Project__r.Project_Address__c  : '';
                    welcomeKitDetail.agreementValue     = oppRecord[0].Agreement_Value__c != null ? oppRecord[0].Agreement_Value__c : 0;
                    welcomeKitDetail.totalAmtCollected  = oppRecord[0].Total_Amount_Collected__c != null ? oppRecord[0].Total_Amount_Collected__c : 0;
                    welcomeKitDetail.allotmentLetterDate= oppRecord[0].Allotment_Letter_Generated_Date_Time__c != null ? Date.valueOf(oppRecord[0].Allotment_Letter_Generated_Date_Time__c) : null;
                    welcomeKitDetail.accountName        = oppRecord[0].Project__r.Account_Name__c != null ? oppRecord[0].Project__r.Account_Name__c : '';
                    welcomeKitDetail.accountNumber      = oppRecord[0].Project__r.Account_Number__c != null ? oppRecord[0].Project__r.Account_Number__c : '';
                    welcomeKitDetail.typeOfAccount      = oppRecord[0].Project__r.Type_of_Account__c != null ? oppRecord[0].Project__r.Type_of_Account__c : '';
                    welcomeKitDetail.bankName           = oppRecord[0].Project__r.Bank_Name__c != null ? oppRecord[0].Project__r.Bank_Name__c : '';
                    welcomeKitDetail.branchName         = oppRecord[0].Project__r.Branch__c != null ? oppRecord[0].Project__r.Branch__c : '';
                    welcomeKitDetail.ifscCode           = oppRecord[0].Project__r.IFSC_Code__c != null ? oppRecord[0].Project__r.IFSC_Code__c : '';
                    tempList.template_values = welcomeKitDetail;
                    generateDoc.templates = new List<DigioWrapperClass.wlcomeKitValueList>{tempList};
                    String jsonBody = Json.serialize(generateDoc);
                    String authorizationValue = 'Basic' + '' +EncodingUtil.base64Encode(Blob.valueOf(customData.Client_ID__c + ':' + customData.Client_Secret__c));
                    String digiDocId = digioCalloutUtility.sendHttpRequest('POST', endpoint, customData.Authorization__c, jsonBody);
                    wrapperRec.digiDocId = digiDocId ;
                    if(digiDocId != null && fileName != null){
                        subDocUrl = digioCalloutUtility.downloadDocument(digiDocId, fileName, parentFolderId, docId);
                        wrapperRec.subDocUrl = subDocUrl ;
                    }
                    return wrapperRec;
                }
            }
            return null;
        }catch(Exception e){
            system.debug('Error in welcomeKit Document===> ' + e.getMessage());
            system.debug('Error line ===> ' + e.getLineNumber());
            return null;
        }
    }
    
    @AuraEnabled
    public static docwrpperClass generateSnnHomeOwner(String oppId){
        try{
            System.debug('oppId==>'+oppId);
            if(oppId != null){
                List<Opportunity> oppRecord = [SELECT Id, Total_Outstanding_Amount__c , Unit__r.Unit_Type__c, Unit__r.Floor__r.Floor_No__c, Unit__r.Super_Built_Up_Area_sq_ft__c, Unit__r.Floor__r.Blocks__r.Parking_Availability__c, Unit__r.Total__c, Opportunity_Unique_Id__c, Cost_Sheet_Template__c, 
            Unit__r.Floor__r.Blocks__r.Tower_Code__c, Unit__r.Unit_Name__c, Phone__c, Project__r.Name, Booking_Date__c, Project__r.Project_Address__c, Project__r.Company__r.Name, (SELECT Id, Document_Id__c, Name FROM Documents__r WHERE Name = 'Post Sales' LIMIT 1) FROM Opportunity WHERE Id = :oppId LIMIT 1];
                String parentFolderId;
                String docId;
                String subDocUrl = '';
                docwrpperClass wrapperRec = new docwrpperClass();
                if(!oppRecord.isEmpty() && oppRecord[0].Documents__r != null){
                    parentFolderId = oppRecord[0].Documents__r[0].Document_Id__c;
                    docId = oppRecord[0].Documents__r[0].Id;
                }
                
                Digio_Integration__c customData = Digio_Integration__c.getValues('Digio');
                if(customData.Authorization__c != null && customData.Endpoint_URL__c != null){
                    String endpoint = customData.Endpoint_URL__c + '/v2/client/template/multi_templates/create_sign_request';
                    DigioWrapperClass.getHomeOwners generateDoc = new DigioWrapperClass.getHomeOwners();
                    Datetime now = System.now();
                    String formattedTimestamp = now.format('yyyy-MM-dd HH:mm:ss');
                    String fileName = 'Snn Home owners - '+formattedTimestamp;
                    generateDoc.file_name = fileName;
                    
                    DigioWrapperClass.signersList signer = new DigioWrapperClass.signersList();
                    signer.identifier = 'projects@snnestates.com';
                    signer.signer_tag = 'Signer 1';
                    signer.name = 'Snn';
                    signer.sign_type = 'document_review';
                    generateDoc.signers = new List<DigioWrapperClass.signersList>{signer};
                    
                    DigioWrapperClass.homeOwnerList tempList = new DigioWrapperClass.homeOwnerList();
                    tempList.template_key = customData.SNN_Home_owners__c;
                    generateDoc.templates = new List<DigioWrapperClass.homeOwnerList>{tempList};
                    String jsonBody = Json.serialize(generateDoc);
                    String authorizationValue = 'Basic' + '' +EncodingUtil.base64Encode(Blob.valueOf(customData.Client_ID__c + ':' + customData.Client_Secret__c));
                    String digiDocId = digioCalloutUtility.sendHttpRequest('POST', endpoint, customData.Authorization__c, jsonBody);
                    wrapperRec.digiDocId = digiDocId ;
                    if(digiDocId != null && fileName != null){
                        subDocUrl = digioCalloutUtility.downloadDocument(digiDocId, fileName, parentFolderId, docId);
                        wrapperRec.subDocUrl = subDocUrl ;
                    }
                    return wrapperRec;
                }
            }
            return null;
        }catch(Exception e){
            system.debug('Error in welcomeKit Document===> ' + e.getMessage());
            system.debug('Error line ===> ' + e.getLineNumber());
            return null;
        }
    }
    
   @AuraEnabled
    public static docwrpperClass generateHandOverOfFlat(String oppId){
        try{
            Opportunity oppRecord = [SELECT Id, Total_Outstanding_Amount__c , Unit__r.Unit_Type__c, 
            Unit__r.Floor__r.Floor_No__c, Unit__r.Super_Built_Up_Area_sq_ft__c, 
            Unit__r.Floor__r.Blocks__r.Parking_Availability__c, Unit__r.Total__c, 
            Opportunity_Unique_Id__c, Cost_Sheet_Template__c, 
            Unit__r.Floor__r.Blocks__r.Tower_Code__c, Unit__r.Unit_Name__c, 
            Phone__c, Project__r.Name, Booking_Date__c, Project__r.Project_Address__c, 
            Project__r.Company__r.Name,CloseDate,
            (SELECT Id, Document_Id__c, Name FROM Documents__r WHERE Name = 'Post Sales' LIMIT 1)
            FROM Opportunity 
            WHERE Id = :oppId LIMIT 1];
            
            System.debug('oppRecord==>'+oppRecord);
            
            String parentFolderId;
            String docId;
            String subDocUrl = '';
            docwrpperClass wrapperRec = new docwrpperClass();
            System.debug('oppRecord.Documents__r ==>'+oppRecord.Documents__r);
            if(oppRecord != null && oppRecord.Documents__r != null){
                parentFolderId = oppRecord.Documents__r[0].Document_Id__c;
                docId = oppRecord.Documents__r[0].Id;
            }
            
            Digio_Integration__c customData = Digio_Integration__c.getValues('Digio');
            
            if(oppRecord != null && customData.Authorization__c != null && customData.Endpoint_URL__c != null){
                
                String endpoint = customData.Endpoint_URL__c + '/v2/client/template/multi_templates/create_sign_request';
                System.debug('endpoint ===> ' + endpoint);
                
                DigioWrapperClass.getHandOver generateDoc = new DigioWrapperClass.getHandOver();
                
                Datetime now = System.now();
                String formattedTimestamp = now.format('yyyy-MM-dd HH:mm:ss');
                System.debug('Formatted Timestamp: ' + formattedTimestamp);
                
                String fileName = ' Snn HandOver Format -Grandeur - '+formattedTimestamp;
                generateDoc.file_name = fileName;
                DigioWrapperClass.signersList signer = new DigioWrapperClass.signersList();
                signer.identifier = 'projects@snnestates.com';
                signer.signer_tag = 'Signer 1';
                signer.name = 'Snn';
                signer.sign_type = 'document_review';
                
                generateDoc.signers = new List<DigioWrapperClass.signersList>{signer};
                
                DigioWrapperClass.handOverValueList tempList = new DigioWrapperClass.handOverValueList();
                //TMP250102114708082L5ZRWP33FBYLOQ
                tempList.template_key = customData.HandOverOfFlat__c;
                
                DigioWrapperClass.handOverTemplateValues welcomeKitDetail = new DigioWrapperClass.handOverTemplateValues();
                welcomeKitDetail.unitNo = oppRecord.Unit__r.Unit_Name__c != null ?  oppRecord.Unit__r.Unit_Name__c : '';
                if (oppRecord.Unit__r.Unit_Type__c != null) {
                    String unitType = oppRecord.Unit__r.Unit_Type__c.split(' ')[0]; // Extract the number part
                    welcomeKitDetail.type = unitType;
                } else {
                    welcomeKitDetail.type = ''; // Default to empty string if null
                }
                welcomeKitDetail.closeDate = oppRecord.CloseDate != null ? oppRecord.CloseDate : null;
                
                
                tempList.template_values = welcomeKitDetail;
                
                generateDoc.templates = new List<DigioWrapperClass.handOverValueList>{tempList};
                system.debug('generateDoc ===> ' + generateDoc);
                system.debug('serialize json ===> ' + Json.serialize(generateDoc));
                String jsonBody = Json.serialize(generateDoc);
                String authorizationValue = 'Basic' + '' +EncodingUtil.base64Encode(Blob.valueOf(customData.Client_ID__c + ':' + customData.Client_Secret__c));
                System.debug('authorizationValue==>'+authorizationValue);
                
                String digiDocId = digioCalloutUtility.sendHttpRequest('POST', endpoint, customData.Authorization__c, jsonBody);
                wrapperRec.digiDocId = digiDocId ;
                if(digiDocId != null && fileName != null){
                    subDocUrl = digioCalloutUtility.downloadDocument(digiDocId, fileName, parentFolderId, docId);
                    wrapperRec.subDocUrl = subDocUrl ;
                }
                return wrapperRec;
                
            }
            return null;
            
        }catch(Exception e){
            system.debug('Error in welcomeKit Document===> ' + e.getMessage());
            system.debug('Error line ===> ' + e.getLineNumber());
            return null;
        }
        
    }
}