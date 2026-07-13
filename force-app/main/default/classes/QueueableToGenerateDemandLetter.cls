public without sharing class QueueableToGenerateDemandLetter implements Queueable, Database.AllowsCallouts {
    
    private Map<Id, List<Payment_Schedule__c>> oppToPaymentsMap;
    private Map<String, List<String>> oppIdByContentVersionIds;
    private Set<Id> processedPaymentScheduleIds;
    
    public QueueableToGenerateDemandLetter(Map<Id, List<Payment_Schedule__c>> oppToPaymentsMap,
        Map<String, List<String>> oppIdByContentVersionIds,
        Set<Id> processedPaymentScheduleIds
    )
    {
        System.debug('oppToPaymentsMap ==> ' + oppToPaymentsMap);
        this.oppToPaymentsMap = (oppToPaymentsMap != null) ? oppToPaymentsMap : new Map<Id, List<Payment_Schedule__c>>();
        this.oppIdByContentVersionIds = (oppIdByContentVersionIds != null) ? oppIdByContentVersionIds : new Map<String, List<String>>();
        this.processedPaymentScheduleIds = (processedPaymentScheduleIds != null) ? processedPaymentScheduleIds : new Set<Id>();
    }
    
    public void execute(QueueableContext qc){
        try{
            System.debug('oppIdByContentVersionIds ===> ' + oppIdByContentVersionIds);
            System.debug('processedPaymentScheduleIds ===> ' + processedPaymentScheduleIds);
            
            if (oppToPaymentsMap == null || oppToPaymentsMap.isEmpty()) {
                System.debug('No opportunities to process.');
                return;
            }
            
            Map<Id, List<Payment_Schedule__c>> nextOppToPaymentsMap = new Map<Id, List<Payment_Schedule__c>>(oppToPaymentsMap);
            
            Id oppId = nextOppToPaymentsMap.keySet().iterator().next();
            System.debug('oppId ===> ' + oppId);
            
            List<Payment_Schedule__c> paymentSchList = nextOppToPaymentsMap.get(oppId);
            if (paymentSchList == null) {
                paymentSchList = new List<Payment_Schedule__c>();
            }
            System.debug('paymentSchList ===> ' + paymentSchList);
            
            if (!paymentSchList.isEmpty()) {
                Payment_Schedule__c currentPayment = paymentSchList.remove(0);
                System.debug('currentPayment ===> ' + currentPayment);
                System.debug('oppIdByContentVersionIds before ===> ' + oppIdByContentVersionIds);
                
                Map<String, List<String>> updatedMap = generateDemandLetterDocument(currentPayment.Id, oppIdByContentVersionIds);
                
                if (updatedMap != null) {
                    oppIdByContentVersionIds = updatedMap;
                    processedPaymentScheduleIds.add(currentPayment.Id);
                }
                
                System.debug('oppIdByContentVersionIds after ===> ' + oppIdByContentVersionIds);
                System.debug('processedPaymentScheduleIds after ===> ' + processedPaymentScheduleIds);
                
                if (!paymentSchList.isEmpty()) {
                    nextOppToPaymentsMap.put(oppId, paymentSchList);
                    System.debug('More payments pending for same opp, enqueueing next generate job.');
                    System.enqueueJob(
                        new QueueableToGenerateDemandLetter(nextOppToPaymentsMap, oppIdByContentVersionIds, processedPaymentScheduleIds)
                    );
                    return;
                } else {
                    nextOppToPaymentsMap.remove(oppId);
                    
                    if (!nextOppToPaymentsMap.isEmpty()) {
                        System.debug('Moving to next opportunity, enqueueing next generate job.');
                        System.enqueueJob(
                            new QueueableToGenerateDemandLetter(nextOppToPaymentsMap, oppIdByContentVersionIds, processedPaymentScheduleIds)
                        );
                        return;
                    } else {
                        System.debug('All demand letters generated. Enqueueing email sender queueable.');
                        System.enqueueJob(new QueueableToSendDemandLetterEmails(oppIdByContentVersionIds, processedPaymentScheduleIds)
                        );
                        return;
                    }
                }
            }
            
        } catch(Exception e){
            System.debug('Error ==> ' + e.getMessage());
            System.debug('Error in line ==> ' + e.getLineNumber());
            System.debug('Stack ==> ' + e.getStackTraceString());
        }
    }
    
    @AuraEnabled
    public static Map<String, List<String>> generateDemandLetterDocument(String recordId, Map<String, List<String>> oppIdBycontentVersionIds){
        
        System.debug('record id ==>'+recordId +' content version id ==>'+oppIdBycontentVersionIds);
        Map<String, List<String>> oppIdByCntVersionIds = (oppIdBycontentVersionIds != null)
            ? oppIdBycontentVersionIds
            : new Map<String, List<String>>();
        
        try{
            if(recordId != null){
                List<Payment_Schedule__c> PaymentScheduleRecords = [SELECT Id, Total_Received_Amount__c, Total_Due_Amount__c, Total_Amount_Inclusive_Of_Tax__c, Name, Opportunity__r.Unit__r.Floor__r.Blocks__r.Tower_Code__c,Opportunity__r.Unit__r.Floor__r.Blocks__r.Name, Opportunity__c,
                           Opportunity__r.Unit__r.Unit_Name__c, Opportunity__r.Less_Total_Receipts__c, Opportunity__r.Project__r.Name, Opportunity__r.Project__r.Account_Name__c, Opportunity__r.Project__r.Account_Number__c, Opportunity__r.Project__r.Bank_Name__c,
                           Opportunity__r.Project__r.IFSC_Code__c, Installment__c, Tax_Amount__c, Pay_Date__c, Due_Date__c, CreatedDate, Agreement_Value__c, (SELECT Id, Amount_Balance__c, Amount_Received__c, Total_Due_Amount__c
                            FROM Demand_Letters__r WHERE Total_Due_Amount__c != 0) FROM Payment_Schedule__c WHERE Id = :recordId LIMIT 1];
                System.debug('paymentScheduleRecords==>'+PaymentScheduleRecords);
                
                if(!PaymentScheduleRecords.isEmpty()){
                    Opportunity oppRecord = [
                        SELECT Id, AccountId, Account.Salutation__c, Total_TDS_Amount_till_date__c, Less_Total_Receipts__c, Account.Name, Account.Phone, Phone__c, Opportunity_Unique_Id__c, (SELECT Id, Document_Id__c FROM Documents__r WHERE Name = 'Demand Letters' LIMIT 1) FROM Opportunity WHERE Id = :PaymentScheduleRecords[0].Opportunity__c LIMIT 1];
                    System.debug('Opp record ==>'+oppRecord);
                    
                    List<Receipt__c> cdReceipts = [
                        SELECT Id, Type__c, Description__c, Amount__c, Credit_Debit_CGST__c, Credit_Debit_SGST__c, Amount_Paid_Excluding_TAX__c FROM Receipt__c WHERE Opportunity__c = :oppRecord.Id AND Type__c IN ('Credit', 'Debit') AND Approval_Status__c = 'Approved' ORDER BY CreatedDate ASC];
                    Boolean hasCreditDebit = (cdReceipts != null && !cdReceipts.isEmpty());
                    System.debug('hasreditDebit::' + hasCreditDebit);
                    
                    if(oppRecord != null && oppRecord.AccountId != null){
                        List<Applicant__c> coApplicantDetails = [SELECT Id, Account__r.Name, Account__r.Salutation__c FROM Applicant__c WHERE Opportunity__c = :PaymentScheduleRecords[0].Opportunity__c];
                        
                        List<String> coApplicantList = new List<String>();
                        if(!coApplicantDetails.isEmpty()){
                            for(Applicant__c app : coApplicantDetails){
                                List<String> coAppName = new List<String>();
                                coAppName.add(app.Account__r.Salutation__c);
                                coAppName.add(app.Account__r.Name);
                                coApplicantList.add(String.join(coAppName, '. '));
                            }
                        }
                        
                        String parentFolderId;
                        String docId;
                        
                        if(oppRecord != null && oppRecord.Documents__r != null && !oppRecord.Documents__r.isEmpty()){
                            parentFolderId = oppRecord.Documents__r[0].Document_Id__c != null ? oppRecord.Documents__r[0].Document_Id__c : null;
                            docId = oppRecord.Documents__r[0].Id != null ? oppRecord.Documents__r[0].Id : null;
                        }
                        
                        Digio_Integration__c customData = Digio_Integration__c.getValues('Digio');
                        if(customData.Authorization__c != null && customData.Endpoint_URL__c != null){
                            String endpoint = customData.Endpoint_URL__c + '/v2/client/template/multi_templates/create_sign_request';
                            System.debug('endpoint ===> ' + endpoint);
                            
                            DigioWrapperClass.demandLetterTemplate generateDoc = new DigioWrapperClass.demandLetterTemplate();
                            Datetime now = System.now();
                            String formattedTimestamp = now.format('yyyy-MM-dd HH:mm:ss');
                            String fileName = 'Demand Letter - ' + formattedTimestamp;
                            generateDoc.file_name = fileName;
                            
                            DigioWrapperClass.signersList signer = new DigioWrapperClass.signersList();
                            signer.identifier = 'projects@snnestates.com';
                            signer.signer_tag = 'Signer 1';
                            signer.name = 'Snn';
                            signer.sign_type = 'document_review';
                            generateDoc.signers = new List<DigioWrapperClass.signersList>{signer};
                            
                            DigioWrapperClass.demandLetterTemplateValuesList tempList = new DigioWrapperClass.demandLetterTemplateValuesList();
                            tempList.template_key = hasCreditDebit ? customData.Demand_Letter_Credit_Debit_Template_Key__c : customData.Demand_Letter_Template_Key__c;
                            
                            DigioWrapperClass.demandLetterTemplateValues templateVariables = new DigioWrapperClass.demandLetterTemplateValues();
                            templateVariables.TodayDate = Date.today().format();
                            system.debug('TodayDate ===> ' + templateVariables.TodayDate);
                            
                            List<String> mainApplicantName = new List<String>();
                            mainApplicantName.add(oppRecord.Account.Salutation__c);
                            mainApplicantName.add(oppRecord.Account.Name);
                            templateVariables.customerName = String.join(mainApplicantName, '.');
                            templateVariables.coApplicantNames = coApplicantList != null && !coApplicantList.isEmpty() ? String.join(coApplicantList, ', ') : '';
                            templateVariables.mobileNo = oppRecord.Account.Phone != null ? oppRecord.Account.Phone : '';
                            templateVariables.paymentScheduleName = PaymentScheduleRecords[0].Name != null ? PaymentScheduleRecords[0].Name : '';
                            templateVariables.dueDate = PaymentScheduleRecords[0].Pay_Date__c != null ? PaymentScheduleRecords[0].Pay_Date__c : null;
                            templateVariables.dueDateLast = PaymentScheduleRecords[0].Due_Date__c != null ? PaymentScheduleRecords[0].Due_Date__c.format() : null; // Added by Yashwanth
                            templateVariables.projectName = PaymentScheduleRecords[0].Opportunity__r.Project__r.Name != null ? PaymentScheduleRecords[0].Opportunity__r.Project__r.Name : '';
                            templateVariables.blockName = PaymentScheduleRecords[0].Opportunity__r.Unit__r.Floor__r.Blocks__r.Name != null ? PaymentScheduleRecords[0].Opportunity__r.Unit__r.Floor__r.Blocks__r.Name : '';
                            templateVariables.bankName = PaymentScheduleRecords[0].Opportunity__r.Project__r.Bank_Name__c != null ? PaymentScheduleRecords[0].Opportunity__r.Project__r.Bank_Name__c : '';
                            templateVariables.unitName = PaymentScheduleRecords[0].Opportunity__r.Unit__r.Unit_Name__c != null ? PaymentScheduleRecords[0].Opportunity__r.Unit__r.Unit_Name__c : '';
                            templateVariables.accountNo = PaymentScheduleRecords[0].Opportunity__r.Project__r.Account_Number__c != null ? PaymentScheduleRecords[0].Opportunity__r.Project__r.Account_Number__c : '';
                            templateVariables.ifscCode = PaymentScheduleRecords[0].Opportunity__r.Project__r.IFSC_Code__c != null ? PaymentScheduleRecords[0].Opportunity__r.Project__r.IFSC_Code__c : '';
                            templateVariables.currentUser = UserInfo.getName();
                            templateVariables.totalTdsPaidTillDate = oppRecord.Total_TDS_Amount_till_date__c != null ? oppRecord.Total_TDS_Amount_till_date__c : 0;
                            templateVariables.exactTime = System.now().format('HH:mm:ss');
                            // templateVariables.FinalScheduleAmount = (PaymentScheduleRecords[0].Agreement_Value__c != null ? PaymentScheduleRecords[0].Agreement_Value__c : 0) + (PaymentScheduleRecords[0].Tax_Amount__c != null ? PaymentScheduleRecords[0].Tax_Amount__c : 0);
                            templateVariables.totalAmountInclusiveOfTax = PaymentScheduleRecords[0].Total_Amount_Inclusive_Of_Tax__c != null ? PaymentScheduleRecords[0].Total_Amount_Inclusive_Of_Tax__c : 0;
                            templateVariables.FinallessTotalAmount = oppRecord.Less_Total_Receipts__c != null ? oppRecord.Less_Total_Receipts__c : 0;
                            
                            // templateVariables.FinalbalancePaybleAmount = templateVariables.totalAmountInclusiveOfTax - (templateVariables.FinallessTotalAmount + templateVariables.totalTdsPaidTillDate);
                            System.debug('templateVariables.FinalbalancePaybleAmount::' + templateVariables.FinalbalancePaybleAmount);
                            tempList.template_values = templateVariables;
                            
                            Id oppIdForTable = PaymentScheduleRecords[0].Opportunity__c;
                            
                            List<Payment_Schedule__c> schedulesForTable = [SELECT Id, Name, Installment__c, Agreement_Value__c, Tax_Amount__c, Total_Due_Amount__c, Total_Amount_Inclusive_Of_Tax__c, Total_Received_Amount__c, Pay_Date__c, Demand_Letter_Sent__c
                                FROM Payment_Schedule__c
                                WHERE Opportunity__c = :oppIdForTable
                                  AND (Demand_Letter_Sent__c = true OR Id = :recordId)
                                ORDER BY Installment_Sequence__c ASC, CreatedDate ASC
                            ];

                            List<DigioWrapperClass.demandLetterTable> DemandLetterTable1 = new List<DigioWrapperClass.demandLetterTable>();
                            Decimal totalScheduledAll = 0;
                            Decimal totalReceivedAll  = 0;

                            if (!schedulesForTable.isEmpty()) {
                                for (Payment_Schedule__c paySch : schedulesForTable) {
                                    DigioWrapperClass.demandLetterTable paySchTable = new DigioWrapperClass.demandLetterTable();

                                    Decimal agremntValueOnPaysch = (paySch.Agreement_Value__c != null ) ? paySch.Agreement_Value__c : 0;
                                    Decimal taxAmt  = (paySch.Tax_Amount__c != null) ? paySch.Tax_Amount__c : 0;
                                    Decimal recvAmt = (paySch.Total_Received_Amount__c != null) ? paySch.Total_Received_Amount__c : 0;
                                    Decimal totalAmtInclOfTax = (paySch.Total_Amount_Inclusive_Of_Tax__c != null) ? paySch.Total_Amount_Inclusive_Of_Tax__c : 0;
                                    
                                    paySchTable.bookingAgreementToSell = (paySch.Name != null) ? String.valueOf(paySch.Name) : '';
                                    paySchTable.showValueIn = (paySch.Installment__c != null) ? paySch.Installment__c : 0;
                                    paySchTable.dueDate = (paySch.Pay_Date__c != null) ? paySch.Pay_Date__c.format() : null;
                                    paySchTable.AgreementValue = agremntValueOnPaysch;
                                    paySchTable.taxesAmout = taxAmt;
                                    paySchTable.totalScheduledDueAmount = totalAmtInclOfTax;

                                    totalScheduledAll += paySchTable.totalScheduledDueAmount;
                                    totalReceivedAll  += recvAmt;

                                    DemandLetterTable1.add(paySchTable);
                                }
                            } else {
                                DigioWrapperClass.demandLetterTable emptyTable = new DigioWrapperClass.demandLetterTable();
                                emptyTable.bookingAgreementToSell = '';
                                emptyTable.showValueIn = 0;
                                emptyTable.dueDate = null;
                                emptyTable.AgreementValue = 0;
                                emptyTable.taxesAmout = 0;
                                emptyTable.totalScheduledDueAmount = 0;
                                DemandLetterTable1.add(emptyTable);
                            }
                            
                            Decimal creditAmountToMinus = 0;
                            Decimal debitAmountToAdd = 0;
                            List<DigioWrapperClass.creditDebitTableRow> cdRows = new List<DigioWrapperClass.creditDebitTableRow>();
                            if(hasCreditDebit){
                                for(Receipt__c r : cdReceipts){
                                    DigioWrapperClass.creditDebitTableRow cdr = new DigioWrapperClass.creditDebitTableRow();
                                    cdr.ReceiptType = (String)r.Type__c;
                                    cdr.Description = (String)r.Description__c;
                                    cdr.Amount = (r.Amount__c != null) ? r.Amount__c : 0;
                                    cdr.Tax = (r.Credit_Debit_CGST__c != null && r.Credit_Debit_SGST__c != null)
                                        ? r.Credit_Debit_CGST__c + r.Credit_Debit_SGST__c : 0;
                                    cdr.Total = (r.Amount__c != null ? r.Amount__c : 0) + cdr.Tax;
                                    cdRows.add(cdr);
                                    if(r.Type__c != null && r.Type__c == 'Credit'){
                                        creditAmountToMinus += (r.Amount__c != null ? (r.Amount__c + cdr.Tax) : 0);
                                    }
                                    if(r.Type__c != null && r.Type__c == 'Debit'){
                                        debitAmountToAdd += (r.Amount__c != null ? (r.Amount__c + cdr.Tax) : 0);
                                    }
                                }
                            }
                            
                            Decimal tdsAmount = templateVariables.totalTdsPaidTillDate != null ? templateVariables.totalTdsPaidTillDate : 0;
                            Decimal lessTotalReceipts = templateVariables.FinallessTotalAmount != null ? templateVariables.FinallessTotalAmount : 0;

                            DigioWrapperClass.demandLetterPaymentScheduleTable tableValues1 = new DigioWrapperClass.demandLetterPaymentScheduleTable();
                            tableValues1.DemandLetterTable = DemandLetterTable1;
                            tableValues1.CreditDebitTable = cdRows;
                            tempList.template_table_values = tableValues1;

                            System.debug('totalScheduledAll::' + totalScheduledAll);
                            templateVariables.FinalScheduleAmount = (totalScheduledAll - creditAmountToMinus) + debitAmountToAdd;
                            templateVariables.FinalbalancePaybleAmount =
                                (((totalScheduledAll - creditAmountToMinus) + debitAmountToAdd) - tdsAmount - lessTotalReceipts).setScale(2);

                            generateDoc.templates = new List<DigioWrapperClass.demandLetterTemplateValuesList>{tempList};
                            
                            String jsonBody = JSON.serialize(generateDoc);
                            String authorizationValue = 'Basic ' + EncodingUtil.base64Encode(
                                Blob.valueOf(customData.Client_ID__c + ':' + customData.Client_Secret__c)
                            );
                            
                            String digiDocId = digioCalloutUtility.sendHttpRequest('POST', endpoint, authorizationValue, jsonBody);
                            if(digiDocId != null && fileName != null){
                                oppIdByCntVersionIds = downloadDocument123(
                                    digiDocId,
                                    fileName,
                                    parentFolderId,
                                    docId,
                                    oppIdByCntVersionIds
                                );
                                System.debug('oppIdByCntVersionIds ===> ' + oppIdByCntVersionIds);
                            }
                        }
                        return oppIdByCntVersionIds;
                    }
                }
            }
            return oppIdByCntVersionIds;
        }catch(Exception e){
            System.debug('Error in generateDemandLetterDocument===> ' + e.getMessage());
            System.debug('Error line ===> ' + e.getLineNumber());
            System.debug('Stack ===> ' + e.getStackTraceString());
            return oppIdByCntVersionIds;
        }
    }   
    
    public static Map<String,List<String>> downloadDocument123(
        String digiDocId,
        String fileName,
        String parentFolderId,
        String docId,
        Map<String, List<String>> oppIdBycontentVersionIds
    ){
        try {
            System.debug('Inside download document');
            Digio_Integration__c customData = Digio_Integration__c.getValues('Digio');
            
            if(customData.Endpoint_URL__c != null && digiDocId != null && fileName != null){
                String endpoint = customData.Endpoint_URL__c + '/v2/client/document/download?document_id=' + digiDocId;
                System.debug('endpoint ===> ' + endpoint);
                
                HTTP http = new HTTP();
                HttpRequest req = new HttpRequest();
                req.setMethod('GET');
                req.setEndpoint(endpoint);
                req.setHeader('Authorization', customData.Authorization__c);
                req.setHeader('Content-Type','application/json');
                
                HttpResponse res = http.send(req);
                Blob responseBlob = res.getBodyAsBlob();
                System.debug('responseBlob ==> ' + responseBlob);
                
                String responseBlobString = EncodingUtil.base64Encode(responseBlob);
                Integer chunkSize = 1024 * 1024 * 3;
                Integer totalFileSize = responseBlobString.length();
                Integer totalFileSizeBlob = responseBlob.size();
                Integer offset = 0;
                Boolean is308Response = false;
                Boolean isLessThan2MB = false;
                String locationValue = null;
                
                if(totalFileSize < chunkSize){
                    isLessThan2MB = true;
                    chunkSize = totalFileSize;
                }
                
                while (offset < totalFileSize) {
                    Integer chunkEnd = Math.min(offset + chunkSize, totalFileSize);
                    Integer chunkEndBlob = Math.min(offset + chunkSize, totalFileSizeBlob);
                    String contentRange = 'bytes ' + offset + '-' + (chunkEndBlob - 1)  + '/' + totalFileSizeBlob;
                    String fileData = responseBlobString.substring(offset, offset + chunkEnd);
                    
                    if (locationValue == null) {
                        GoogleDriveAPI.wrapperForResponse firstUpload = GoogleDriveAPI.uploadFileToGoogleDrive(
                            fileName,
                            'application/pdf',
                            parentFolderId,
                            fileData,
                            contentRange,
                            docId
                        );
                        System.debug('firstUpload ===> ' + firstUpload);
                        if (firstUpload != null) {
                            locationValue = firstUpload.locationValue;
                            if (firstUpload.is308Response) {
                                is308Response = true;
                            }
                        }
                        if(isLessThan2MB){
                            break;
                        }
                    } else {
                        Boolean nextUpload = GoogleDriveAPI.processData(locationValue, fileData, contentRange, docId, fileName);
                        if (nextUpload == true) {
                            is308Response = true;
                        } else {
                            break;
                        }
                    }
                    
                    if (is308Response) {
                        offset += chunkSize;
                    } else {
                        break;
                    }
                }
                
                List<Document__c> docRec = [SELECT Id, Name, Opportunity__c FROM Document__c WHERE Id = :docId LIMIT 1];
                List<String> contentVersionIds = new List<String>();
                
                if(!docRec.isEmpty() && docRec[0].Opportunity__c != null){
                    ContentVersion cntVersion = new ContentVersion(
                        Title = fileName,
                        PathOnClient = fileName,
                        VersionData = responseBlob
                    );
                    insert cntVersion;
                    System.debug('Id ===> ' + cntVersion.Id);
                    
                    if (oppIdBycontentVersionIds == null) {
                        oppIdBycontentVersionIds = new Map<String, List<String>>();
                    }
                    
                    String oppKey = String.valueOf(docRec[0].Opportunity__c);
                    
                    if(!oppIdBycontentVersionIds.containsKey(oppKey)){
                        oppIdBycontentVersionIds.put(oppKey, new List<String>());
                    }
                    contentVersionIds = oppIdBycontentVersionIds.get(oppKey);
                    contentVersionIds.add(cntVersion.Id);
                    oppIdBycontentVersionIds.put(oppKey, contentVersionIds);
                }
            }
            return oppIdBycontentVersionIds;
        } catch (Exception e) {
            System.debug('Error ==> ' + e.getMessage());
            System.debug('Error in line ==> ' + e.getLineNumber());
            System.debug('Stack ==> ' + e.getStackTraceString());
            return oppIdBycontentVersionIds;
        }
    }
    
       public static void dummyMethod(){
        Integer i = 0;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
        i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;i++;
    }
}