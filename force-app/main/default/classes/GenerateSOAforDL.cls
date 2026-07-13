public with sharing class GenerateSOAforDL {
    
    @AuraEnabled
    public static docwrpperClass generateStatementOfAccounts(String oppId, List<Id> selectedPaymentScheduleIds){
        try{
            System.debug('oppId==>'+oppId);
            System.debug('selectedPaymentScheduleIds==>'+selectedPaymentScheduleIds);
            Set<Id> selectedPaymentScheduleIdSet = new Set<Id>();
            if (selectedPaymentScheduleIds != null) {
                selectedPaymentScheduleIdSet.addAll(selectedPaymentScheduleIds);
            }
            
            String coApplicantNames = '';
            List<Applicant__c> allApplicants = [select id,Name,Permanent_Address__c,Permanent_Address__PostalCode__s,Email__c,Primary_Contact_Number__c,Opportunity__r.Unit__c,Opportunity__r.Unit__r.Name,Opportunity__r.Unit__r.Unit_Type__c,Opportunity__r.Unit__r.Floor__c,Opportunity__r.Unit__r.Floor__r.Blocks__c,Opportunity__r.Unit__r.Floor__r.Name,Opportunity__r.Unit__r.Floor__r.Blocks__r.Name,Opportunity__r.Project__c,Opportunity__r.Project__r.Name,Primary_Applicant__c,Opportunity__r.Opportunity_Unique_Id__c,Permanent_Address__City__s from Applicant__c where Opportunity__c  =: oppId];
            System.debug('allApplicants==>'+allApplicants);
            List<Payment_Schedule__c>paymentScheduleRelatedToOpp = [select id,Name,Installment__c,Agreement_Value__c,Debit_Payment_Schedule__c,Tax_Amount__c, Total_Amount_Inclusive_Of_Tax__c, Total_Received_Amount__c, Demand_Letter_Sent__c, Total_Due_Amount__c, (select id,Amount_Balance__c,Amount_Received__c,Total_Due_Amount__c from Demand_Letters__r ) from Payment_Schedule__c where Opportunity__c =: oppId];
            System.debug('paymentScheduleRelatedToOpp==>'+paymentScheduleRelatedToOpp);
            
            List<Opportunity> oppDetails = [SELECT Id,Name,AccountId,Unit__r.Unit_Name__c,Booking_Date__c, Total_Schedule_Amount__c, Total_Amount_Collected__c, Project__r.Name,Unit__r.Floor__r.Blocks__r.Tower_Code__c,Unit__r.Floor__r.Blocks__r.Name,
                                            (SELECT Id,Document_Id__c from Documents__r where Name = 'Post Sales' LIMIT 1) from Opportunity where Id =: oppId LIMIT 1];
            String parentFolderId;
            String docId;
            String subDocUrl = '';
            docwrpperClass wrapperRec = new docwrpperClass();
            if(!oppDetails.isEmpty() && oppDetails[0].Documents__r != null){
                system.debug('enter the condition');
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
            
            List<Receipt__c > receiptsRelatedToOpp = [select id,Name,Receipt_Date__c,Mode_Of_Payment__c, UPI_Provider__c, Paid_Date__c, Cheque_Number__c,Cheque_Date__c,Drawn_on_Bank__c,Amount__c,Opportunity__c,DD_Number__c,DD_Date__c,Transaction_Reference_Number__c, Type__c, Description__c, Reference_Number__c, Fund_Date__c,
                                                      Fund_Transfer_Date__c,JV_Date__c, Total_GST__c, Amount_Paid_Excluding_TAX__c,JV_Reference_Number__c, Challan_Date__c, Bank__c, TDS_Amount__c, CIN__c, Receipt_Number__c, Credit_Debit_SGST__c, Credit_Debit_CGST__c  from Receipt__c where Opportunity__c =: oppId and Approval_Status__c = 'Approved'];
            System.debug('receiptsRelatedToOpp==>'+receiptsRelatedToOpp + 'size==>'+receiptsRelatedToOpp.size());
            Boolean hasCreditDebit = false;
            for (Receipt__c rec : receiptsRelatedToOpp) {
                if (rec.Type__c == 'Credit') {
                    hasCreditDebit = true;
                    break;
                }
            }
            
            if(mainApplicant[0] != null && customData.Authorization__c != null && customData.Endpoint_URL__c != null){
                
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
                
                tempList.template_key = hasCreditDebit ? customData.Statement_of_Account_Debit_Template_Key__c : customData.Statement_of_Accounts_Template_Key__c;
                System.debug('mainApplicant==>'+mainApplicant);
                
                DigioWrapperClass.accountTemplateValues templateVariables = new DigioWrapperClass.accountTemplateValues();
                templateVariables.todayDate             = String.valueOf(Date.today().format());
                templateVariables.customerName          = mainApplicant[0].Name != null ? mainApplicant[0].Name: '';
                templateVariables.projectName           = oppDetails[0].Project__r.Name != null ? oppDetails[0].Project__r.Name : '';
                templateVariables.unitNo                = oppDetails[0].Unit__r.Unit_Name__c != null ? oppDetails[0].Unit__r.Unit_Name__c : '';
                // templateVariables.blockNo               = oppDetails[0].Unit__r.Floor__r.Blocks__r.Name != null ? oppDetails[0].Unit__r.Floor__r.Blocks__r.Name : '';
                templateVariables.towerCode             = oppDetails[0].Unit__r.Floor__r.Blocks__r.Name != null ? oppDetails[0].Unit__r.Floor__r.Blocks__r.Name : '';
                
                templateVariables.generatedTime         = System.now().format('HH:mm:ss');
                templateVariables.userName              = UserInfo.getName();
                templateVariables.totalPaidTillDate     = oppDetails[0].Total_Amount_Collected__c != null ? oppDetails[0].Total_Amount_Collected__c : 0;

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
                Decimal totalScheduleAmountFromPS = 0;

                if(!paymentScheduleRelatedToOpp.isEmpty()){
                    for(Payment_Schedule__c paySchedule : paymentScheduleRelatedToOpp){
                        DigioWrapperClass.statementOfAccountTable paymentSchedule = new DigioWrapperClass.statementOfAccountTable();
                        Boolean showAsActiveSchedule =
                            ((paySchedule.Total_Due_Amount__c != null && paySchedule.Demand_Letter_Sent__c == true) ||
                             paySchedule.Debit_Payment_Schedule__c == true ||
                             selectedPaymentScheduleIdSet.contains(paySchedule.Id));

                        if (showAsActiveSchedule) {
                            totalScheduleAmountFromPS += (paySchedule.Total_Amount_Inclusive_Of_Tax__c != null ? paySchedule.Total_Amount_Inclusive_Of_Tax__c : 0);
                        }

                        // paymentSchedule.particularData      =((paySchedule.Total_Due_Amount__c != null && paySchedule.Demand_Letter_Sent__c == true) ? String.valueOf(paySchedule.Name) : String.valueOf(paySchedule.Name) + ' (Upcoming Milestone)');
                        paymentSchedule.particularData      = showAsActiveSchedule ? String.valueOf(paySchedule.Name) : String.valueOf(paySchedule.Name) + ' (Upcoming Milestone)';
                        
                        // paymentSchedule.particularData      = paySchedule.Name != null ? String.valueOf(paySchedule.Name) : '';
                        paymentSchedule.totalBilled         = paySchedule.Total_Amount_Inclusive_Of_Tax__c != null ? paySchedule.Total_Amount_Inclusive_Of_Tax__c : 0;
                        Decimal amountReceived = 0;
                        amountReceived                      = paySchedule.Total_Received_Amount__c != null ? paySchedule.Total_Received_Amount__c : 0;
                        paymentSchedule.amountReceived      = amountReceived.setScale(2);
                        paymentSchedule.amountBalance       = showAsActiveSchedule && paySchedule.Total_Due_Amount__c != null ? paySchedule.Total_Due_Amount__c : 0;
                        // for(Demand_Letter__c dl : paySchedule.Demand_Letters__r){
                        //     paymentSchedule.amountReceived = dl.Amount_Balance__c != null ? dl.Amount_Balance__c : 0;
                        //     paymentSchedule.amountBalance = dl.Total_Due_Amount__c != null ? dl.Total_Due_Amount__c : 0;
                        // }
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
                    scheduleTotal.FinaltotalBilled = totalBilledAmount.setScale(2);
                    scheduleTotal.FinalamountReceived = totalReceivedAmount;
                    scheduleTotal.FinalamountBalance = totalBalanceAmount;
                    totalScheduleList.add(scheduleTotal);
                    tableValues.statementOfScheduleTable = totalScheduleList;
                }

                templateVariables.totalScheduleAmount      = totalScheduleAmountFromPS;
                templateVariables.totalBalancePaidTwrdUnit = templateVariables.totalScheduleAmount - templateVariables.totalPaidTillDate;

                
                Decimal finalTotalAmount = 0;
                Decimal finalAmountCd = 0;
                Decimal finalAmountTaxCd = 0;
                Decimal finalTotalAmountCd = 0;
                
                List<DigioWrapperClass.statementOfReceipt> receiptsList = new List<DigioWrapperClass.statementOfReceipt>();
                List<DigioWrapperClass.statementOfReceiptCreditDebit> creditDebitList = new List<DigioWrapperClass.statementOfReceiptCreditDebit>();
                system.debug('receiptsRelatedToOpp:::' + receiptsRelatedToOpp.size());
                Integer count = 0;
                Integer creditCount = 0;
                Integer debitCount = 0;
                for(Receipt__c receipt : receiptsRelatedToOpp){
                    system.debug('receipt==>'+receipt + 'count==>'+count++);
                    if(receipt.Type__c == 'Tax Invoice'){
                        DigioWrapperClass.statementOfReceipt receipts = new DigioWrapperClass.statementOfReceipt();
                        
                        receipts.receiptNo = receipt.Receipt_Number__c != null ? receipt.Receipt_Number__c : '';
                        receipts.receiptDate = receipt.Receipt_Date__c != null ? formatDate(receipt.Receipt_Date__c) : '';
                        receipts.paymentCategory = receipt.Mode_Of_Payment__c != null ? receipt.Mode_Of_Payment__c : '';
                        
                        if(String.isNotBlank(receipt.Mode_Of_Payment__c)){
                            if(receipt.Mode_Of_Payment__c == 'Cheque'){
                                receipts.instrumentNo = receipt.Cheque_Number__c != null ? String.valueOf(receipt.Cheque_Number__c) : '';
                                receipts.instrumentDate = receipt.Cheque_Date__c != null ? formatDate(receipt.Cheque_Date__c) : '';
                            }else if(receipt.Mode_Of_Payment__c == 'DD'){
                                receipts.instrumentNo = receipt.DD_Number__c != null ? String.valueOf(receipt.DD_Number__c) : '';
                                receipts.instrumentDate = receipt.DD_Date__c != null ? formatDate(receipt.DD_Date__c) : '';
                            }else if(receipt.Mode_Of_Payment__c == 'JV'){
                                receipts.instrumentNo = receipt.JV_Reference_Number__c != null ? String.valueOf(receipt.JV_Reference_Number__c) : '';
                                receipts.instrumentDate = receipt.Paid_Date__c != null ? formatDate(receipt.Paid_Date__c) : '';
                            }
                            else if(receipt.Mode_Of_Payment__c == 'TDS'){
                                receipts.instrumentNo = receipt.CIN__c != null ? String.valueOf(receipt.CIN__c) : '';
                                receipts.instrumentDate = receipt.Challan_Date__c != null ? formatDate(receipt.Challan_Date__c) : '';
                            }
                            else if(receipt.Mode_Of_Payment__c == 'UPI'){
                                receipts.instrumentNo = receipt.Reference_Number__c != null ? String.valueOf(receipt.Reference_Number__c) : '';
                                receipts.instrumentDate = receipt.Paid_Date__c != null ? formatDate(receipt.Paid_Date__c) : '';
                            }
                            else if(receipt.Mode_Of_Payment__c == 'FUNDTRANSFER'){
                                receipts.instrumentNo = receipt.Reference_Number__c != null ? String.valueOf(receipt.Reference_Number__c) : '';
                                receipts.instrumentDate = receipt.Fund_Date__c != null ? formatDate(receipt.Fund_Date__c) : '';
                            }
                            else{
                                receipts.instrumentNo = receipt.Transaction_Reference_Number__c != null ? String.valueOf(receipt.Transaction_Reference_Number__c) : '';
                                receipts.instrumentDate = receipt.Fund_Transfer_Date__c != null ? formatDate(receipt.Fund_Transfer_Date__c) : '';
                            }
                        }
                        
                        receipts.bankName = receipt.Mode_Of_Payment__c == 'TDS' ? (receipt.Bank__c != null ? receipt.Bank__c : '') : receipt.Mode_Of_Payment__c == 'UPI' ? (receipt.UPI_Provider__c != null ? receipt.UPI_Provider__c : '') : receipt.Mode_Of_Payment__c == 'EFT' ? (receipt.Bank__c != null ? receipt.Bank__c : '') : (receipt.Drawn_on_Bank__c != null ? receipt.Drawn_on_Bank__c : '');
                            receipts.amount = receipt.Mode_Of_Payment__c == 'TDS' ? (receipt.TDS_Amount__c != null ? receipt.TDS_Amount__c : 0) : (receipt.Amount__c != null ? receipt.Amount__c : 0);
                                
                                finalTotalAmount += receipts.amount;
                        receiptsList.add(receipts);
                    }
                    
                    if(receipt.Type__c == 'Credit'){
                        creditCount++;
                        DigioWrapperClass.statementOfReceiptCreditDebit receiptsCD  = new DigioWrapperClass.statementOfReceiptCreditDebit();
                        receiptsCD.receiptNoCD                                      = receipt.Receipt_Number__c != null ? receipt.Receipt_Number__c : '';
                        receiptsCD.receiptTypeCD                                    = receipt.Type__c != null ? receipt.Type__c : '';
                        receiptsCD.receiptDescCD                                    = receipt.Description__c != null ? receipt.Description__c : '';
                        receiptsCD.receiptAmountCD                                  = receipt.Amount__c != null ? receipt.Amount__c : 0;
                        receiptsCD.receiptTaxCD                                     = (receipt.Credit_Debit_CGST__c != null && receipt.Credit_Debit_SGST__c != null) ? receipt.Credit_Debit_CGST__c + receipt.Credit_Debit_SGST__c : 0;
                        receiptsCD.receiptTotalAmountCD                             = receipt.Amount__c != null && receipt.Credit_Debit_CGST__c != null && receipt.Credit_Debit_SGST__c != null ? receipt.Amount__c + receipt.Credit_Debit_CGST__c + receipt.Credit_Debit_SGST__c : 0;
                        
                        finalAmountCd += receiptsCD.receiptAmountCD;
                        finalAmountTaxCd += receiptsCD.receiptTaxCD;
                        finalTotalAmountCd += receiptsCD.receiptTotalAmountCD;
                        
                        creditDebitList.add(receiptsCD);
                    }
                }
                system.debug('creditCount::::' + creditCount);
                // system.debug('debitCount:::' + debitCount);
                if(!receiptsList.isEmpty()){
                    tableValues.statementOfReceipt = receiptsList;
                }
                
                if(!creditDebitList.isEmpty()){
                    tableValues.statementOfReceiptCreditDebit = creditDebitList;
                }
                
                List<DigioWrapperClass.statementOfReceiptTotal> totalReceiptsList = new List<DigioWrapperClass.statementOfReceiptTotal>();
                DigioWrapperClass.statementOfReceiptTotal totalReceipt = new DigioWrapperClass.statementOfReceiptTotal();
                totalReceipt.FinalAmount = finalTotalAmount;
                
                system.debug('finalTotalAmount==>'+finalTotalAmount);
                totalReceipt.finalAmountCd = finalAmountCd;
                totalReceipt.finalAmountTaxCd = finalAmountTaxCd;
                totalReceipt.finalTotalAmountCd = finalTotalAmountCd;
                System.debug('totalReceipt.finalAmountCd==>'+totalReceipt.finalAmountCd);
                System.debug('totalReceipt.finalAmountTaxCd==>'+totalReceipt.finalAmountTaxCd);
                System.debug('totalReceipt.finalTotalAmountCd==>'+totalReceipt.finalTotalAmountCd);
                totalReceiptsList.add(totalReceipt);
                tableValues.statementOfReceiptTotal = totalReceiptsList;
                
                
                templateVariables.FinalReceiptAmount = finalTotalAmount;
                templateVariables.finalAmountCd = finalAmountCd;
                templateVariables.finalAmountTaxCd = finalAmountTaxCd;
                templateVariables.finalTotalAmountCd = finalTotalAmountCd;
                System.debug('templateVariables.FinalReceiptAmount==>'+templateVariables.FinalReceiptAmount);
                
                tempList.template_values = templateVariables;
                tempList.template_table_values = tableValues;
                generateDoc.templates = new List<DigioWrapperClass.accountStatementTemplateList>{tempList};
                    
                    system.debug('generateDoc ===> ' + generateDoc);
                system.debug('serialize json ===> ' + Json.serialize(generateDoc));
                
                String jsonBody = Json.serialize(generateDoc);
                String authorizationValue = 'Basic' + ' ' +EncodingUtil.base64Encode(Blob.valueOf(customData.Client_ID__c + ':' + customData.Client_Secret__c));
                System.debug('authorizationValue==>'+authorizationValue);
                
                // System.debug('authorizationValue==>'+customData.Authorization__c);
                String digiDocId = digioCalloutUtility.sendHttpRequest('POST', endpoint, authorizationValue, jsonBody);
                System.debug('digiDocId::>>' + digiDocId);
                System.debug('fileName::>>' + fileName);
                System.debug('parentFolderId::>>' + parentFolderId);
                System.debug('docId::>>' + docId);
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
            system.debug('Error in generateStatementOfAccounts===> ' + e.getMessage());
            system.debug('Error line ===> ' + e.getLineNumber());
            return null;
        }
    }
    
    Public class docwrpperClass{
        @AuraEnabled public String subDocUrl;
        @AuraEnabled public String digiDocId;
        @AuraEnabled public String soaSubDocUrl;
        @AuraEnabled public String soaDigiDocId;
    }
    
    private static String formatDate(Date d) {
        if (d == null) return '';
        return DateTime.newInstance(d.year(), d.month(), d.day()).format('dd/MM/yyyy');
    }
}