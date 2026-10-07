public without sharing class FinaliseCostSheetController {

    public class CostSheetWrapper {
       @AuraEnabled public List<Cost_Sheet__c> costSheetRecords { get; set; }
       @AuraEnabled public List<Payment_Schedule__c> paymentScheduleRecords { get; set; }
       @AuraEnabled public List<Pricing_Element__c> costPricingAsstnList { get; set; }

       public CostSheetWrapper() {
           costSheetRecords = new List<Cost_Sheet__c>();
           paymentScheduleRecords = new List<Payment_Schedule__c>();
           costPricingAsstnList = new List<Pricing_Element__c>();
       }
   }

 @AuraEnabled
 public static CostSheetWrapper getRecordDetails(Id recordId) {
     System.debug('Received Record Id: ' + recordId);
     
     // Query the Task record
     Task ts = [SELECT Id, WhatId FROM Task WHERE Id = :recordId LIMIT 1];
     Opportunity oppRec = [SELECT Id,Cost_Sheet_Template__c from Opportunity where Id =: ts.WhatId LIMIT 1];
     System.debug('Task: ' + ts);

     // Retrieve Payment Schedule records
     

     // Retrieve Cost Sheet records
     List<Cost_Sheet__c> relatedCostSheetRecords = [SELECT Id, Opportunity__c, Name, Cost_Scheme_Linking__c ,Opportunity__r.Name,Cost_Scheme_Linking__r.Cost_Sheet_Template__r.Name,Cost_Scheme_Linking__r.Payment_Scheme__r.Name,finalize_CostSheet__c,Discounted_Cost_Sheet__c,Cost_Sheet_Approval_Summary__c,CreatedDate
                                                     FROM Cost_Sheet__c
                                                     WHERE Opportunity__c = :ts.WhatId];

     System.debug('Related Cost Sheets: ' + relatedCostSheetRecords);
       String finalizeCostSheet = '';
       List<Payment_Schedule__c> getPaymentSchemes;
     for(Cost_Sheet__c finalize : relatedCostSheetRecords){
       if(finalize.finalize_CostSheet__c == true){
           finalizeCostSheet = finalize.Id;

           getPaymentSchemes = [SELECT Id, Name, Installment__c, Agreement_Value__c, Opportunity__c, Opportunity__r.Name ,Tax_Amount__c,Due_Date__c,Pay_Date__c,Other_Charges__c,Other_Tax_Amount__c
                                                        FROM Payment_Schedule__c  
                                                      WHERE Opportunity__c = :ts.WhatId];
     System.debug('Payment Schedules: ' + getPaymentSchemes);
       }
     }

     

     List<Pricing_Element__c> costPricingAsstnList;
     if(finalizeCostSheet != null){
        costPricingAsstnList = [select id,Name,Pricing_Element_Master__r.Name,Amount__c,Actual_Amount__c,Discount__c,Discount_Amount__c,Tax_Amount__c,Final_Tax_Amount__c,PE_Type__c,Quantity__c,Rate__c,Total_Amount_Excluding_Tax__c from Pricing_Element__c where Cost_Sheet__c =:finalizeCostSheet];
     }
       
          
       

     // Create the wrapper instance
     CostSheetWrapper wrapper = new CostSheetWrapper();
     wrapper.paymentScheduleRecords = getPaymentSchemes;
     wrapper.costSheetRecords = relatedCostSheetRecords;
       wrapper.costPricingAsstnList = costPricingAsstnList;

     System.debug('wrapper==>'+wrapper);

     return wrapper;
 }



 @AuraEnabled
 public static costSheetAndTemplateWrapper createPaymentSchedule(Id recordId,Id costSheetId, Id selectedCostSheetTempId) {
     System.debug('Record ID: ' + recordId);
     System.debug('Processing Cost Sheet ID: ' + costSheetId);

     Cost_Sheet__c getCostSheet = [select id,Opportunity__c,Name,Cost_Scheme_Linking__c,finalize_CostSheet__c,Total_Pricing_Value__c, Total_Pricing_Value_Excluding_Tax__c, Total_Tax_Value__c from Cost_Sheet__c Where Id =:costSheetId Limit 1];
     // finalize_CostSheet__c is now set after the Opportunity approval (see opportunityTriggerHandler.finalizeCostSheetOnApproval)
     // getCostSheet.finalize_CostSheet__c = true;
     // update getCostSheet;

     Cost_Scheme_Linking__c getSchemeLinking = [select id,Payment_Scheme__c,Cost_Sheet_Template__c,Cost_Sheet_Template__r.Amount__c,Cost_Sheet_Template__r.Tax_Amount__c  from Cost_Scheme_Linking__c Where id =:getCostSheet.Cost_Scheme_Linking__c Limit 1];

     List<Payment_Scheme_Installment__c> getPaymetSchemeRecords = [select id,Payment_Scheme__c,Payment_Scheme__r.Name,Installment__c,Name,Payment_Schedule_Master__c,Payment_Schedule_Master__r.Name,Display_Order__c,Payment_Schedule_Master__r.Installment_Code__c, Payment_Schedule_Master__r.Installment_Sequence__c from Payment_Scheme_Installment__c Where Payment_Scheme__c  =:getSchemeLinking.Payment_Scheme__c];
     System.debug('Received Record Id: ' + recordId);
     Task ts = [select id,WhatId from Task Where id =: recordId Limit 1];
     Decimal smallDisplayNum =  10000;
     for(Payment_Scheme_Installment__c psi : getPaymetSchemeRecords){
         if(psi.Display_Order__c  < smallDisplayNum){
             smallDisplayNum = psi.Display_Order__c;
         }
     }

     List<Payment_Schedule__c> allPaymentSchedules = new List<Payment_Schedule__c>();
     for(Payment_Scheme_Installment__c psi : getPaymetSchemeRecords){
         Payment_Schedule__c ps = new Payment_Schedule__c();
         ps.Opportunity__c = ts.WhatId;
         ps.Installment__c = psi.Installment__c;
         ps.Agreement_Value__c = (getCostSheet.Total_Pricing_Value_Excluding_Tax__c / 100) * psi.Installment__c;
         ps.Tax_Amount__c = (getCostSheet.Total_Tax_Value__c / 100) * psi.Installment__c;
         ps.Other_Charges__c = 0;
         ps.Other_Tax_Amount__c = 0;
         ps.Installment_Sequence__c =  psi.Payment_Schedule_Master__r.Installment_Sequence__c;
         /* if (smallDisplayNum == psi.Display_Order__c) {
             ps.Due_Date__c = Date.today(); // Set to today's date
             ps.Pay_Date__c = Date.today(); // Set to today's date
         } else {
             // Calculate the last date of the next month
             Date nextMonth = Date.today().addMonths(1);
             Integer lastDayOfNextMonth = Date.daysInMonth(nextMonth.year(), nextMonth.month());
             Date nextMonthLastDate = Date.newInstance(nextMonth.year(), nextMonth.month(), lastDayOfNextMonth);
             ps.Due_Date__c = nextMonthLastDate; // Set to the last date of next month
             ps.Pay_Date__c = nextMonthLastDate; // Set to the last date of next month
         } */
        
         ps.Name = psi.Payment_Schedule_Master__r.Name;
         allPaymentSchedules.add(ps);
     }
     insert allPaymentSchedules;

     // If payment schedules were previously deleted via Delete_Approval__c approval,
     // backfill received amounts from already-approved receipts onto the new schedules.
     Opportunity oppApprovalCheck = [SELECT Id, Delete_Approval__c FROM Opportunity WHERE Id = :ts.WhatId LIMIT 1];
     if (oppApprovalCheck.Delete_Approval__c == 'Approved') {
         receiptTriggerHandler.applyApprovedReceiptsToSchedules(ts.WhatId);
     }

     List<Cost_Sheet__c> costSheetList = [SELECT Id, Unit__c FROM Cost_Sheet__c
                                             WHERE Id =: costSheetId];

     List<Payment_Schedule__c> insertedPaymentSchedules = [SELECT Id, Name, Installment__c, Agreement_Value__c, Opportunity__c, Opportunity__r.Name ,Tax_Amount__c,Due_Date__c,Pay_Date__c,Other_Charges__c,Other_Tax_Amount__c
                                                        FROM Payment_Schedule__c 
                                                        WHERE Id IN :allPaymentSchedules];

     Opportunity opp = [select id,Name,Payment_Scheme__c,Cost_Sheet_Template__c from Opportunity where Id =:ts.WhatId Limit 1];
     opp.Payment_Scheme__c = getSchemeLinking.Payment_Scheme__c;
     opp.Cost_Sheet_Template__c = getSchemeLinking.Cost_Sheet_Template__c;
     opp.Unit__c = costSheetList[0].Unit__c;
     opp.Name = 'opp';
     update opp;

     List<Pricing_Element__c> costPricingAsstnList = [select id,Name,Pricing_Element_Master__r.Name,Amount__c,Actual_Amount__c,Discount__c,Discount_Amount__c,Tax_Amount__c,PE_Type__c,Quantity__c,Rate__c, Final_Tax_Amount__c, Total_Amount_Excluding_Tax__c from Pricing_Element__c where Cost_Sheet__c =:getCostSheet.ID];

     costSheetAndTemplateWrapper wrp = new costSheetAndTemplateWrapper();
     wrp.costPricingAsstnList = costPricingAsstnList;
     wrp.paymentScheduleList = insertedPaymentSchedules;
     return wrp;
 }

 public class costSheetAndTemplateWrapper{
     @AuraEnabled public List<Payment_Schedule__c> paymentScheduleList{get;set;}
     @AuraEnabled public List<Pricing_Element__c> costPricingAsstnList{get;set;}
 }


 @AuraEnabled
 public static CostSheetWrapper getCostSheetPreview(Id costSheetId) {
     System.debug('costSheetId:::>> ' + costSheetId);
     Cost_Sheet__c cs = [SELECT Id, finalize_CostSheet__c, Opportunity__c, Opportunity__r.Name
                         FROM Cost_Sheet__c WHERE Id = :costSheetId LIMIT 1];

     List<Pricing_Element__c> pricingElements = [
         SELECT Id, Name, Pricing_Element_Master__r.Name, Amount__c, Actual_Amount__c, Discount__c,
                Discount_Amount__c, Tax_Amount__c, Final_Tax_Amount__c, PE_Type__c, Quantity__c, Rate__c,
                Total_Amount_Excluding_Tax__c
         FROM Pricing_Element__c WHERE Cost_Sheet__c = :costSheetId
     ];

     List<Payment_Schedule__c> existingSchedules = new List<Payment_Schedule__c>();
     if (cs.finalize_CostSheet__c == true) {
         existingSchedules = [SELECT Id, Name, Installment__c, Agreement_Value__c, Tax_Amount__c,
                                     Due_Date__c, Pay_Date__c, Other_Charges__c, Other_Tax_Amount__c,
                                     Opportunity__c, Opportunity__r.Name
                              FROM Payment_Schedule__c WHERE Opportunity__c = :cs.Opportunity__c];
     }

     CostSheetWrapper wrapper = new CostSheetWrapper();
     wrapper.costSheetRecords = new List<Cost_Sheet__c>{ cs };
     wrapper.paymentScheduleRecords = existingSchedules;
     wrapper.costPricingAsstnList = pricingElements;
     return wrapper;
 }

 @AuraEnabled
 public static List<Payment_Schedule__c> generatePaymentSchedulePreview(Id costSheetId) {
     Cost_Sheet__c getCostSheet = [SELECT Id, Opportunity__c, Total_Pricing_Value_Excluding_Tax__c,
                                          Total_Tax_Value__c, Cost_Scheme_Linking__r.Payment_Scheme__c
                                   FROM Cost_Sheet__c WHERE Id = :costSheetId LIMIT 1];

     List<Payment_Scheme_Installment__c> schemeInstallments = [
         SELECT Installment__c, Name, Payment_Schedule_Master__r.Name,
                Payment_Schedule_Master__r.Installment_Sequence__c, Display_Order__c
         FROM Payment_Scheme_Installment__c
         WHERE Payment_Scheme__c = :getCostSheet.Cost_Scheme_Linking__r.Payment_Scheme__c
     ];

     List<Payment_Schedule__c> previewList = new List<Payment_Schedule__c>();
     for (Payment_Scheme_Installment__c psi : schemeInstallments) {
         Payment_Schedule__c ps = new Payment_Schedule__c();
         ps.Opportunity__c = getCostSheet.Opportunity__c;
         ps.Name = psi.Payment_Schedule_Master__r.Name;
         ps.Installment__c = psi.Installment__c;
         ps.Agreement_Value__c = (getCostSheet.Total_Pricing_Value_Excluding_Tax__c / 100) * psi.Installment__c;
         ps.Tax_Amount__c = (getCostSheet.Total_Tax_Value__c / 100) * psi.Installment__c;
         ps.Other_Charges__c = 0;
         ps.Other_Tax_Amount__c = 0;
         ps.Installment_Sequence__c = psi.Payment_Schedule_Master__r.Installment_Sequence__c;
         previewList.add(ps);
     }
     return previewList;
 }

 @AuraEnabled
 public static String sendApproval(Id recordId) {
     try {
         System.debug('taskId==>'+recordId);
         // Retrieve the Task and associated Opportunity
         Task ts = [SELECT Id, WhatId,Status FROM Task WHERE Id = :recordId AND Subject =: 'Finalise Cost Sheet & Generate Payment Schedule' LIMIT 1];
         System.debug('Task: ' + ts);

         ts.Status = 'Completed';
         try {
             update ts;
         } catch (DmlException e) {
             System.debug('DML Exception: ' + e.getMessage());
             System.debug('Task Record ID: ' + ts.Id);
             
             System.debug('WhatId: ' + ts.WhatId);
         }


           Opportunity opp = [SELECT Id, Payment_Scheme__c, Cost_Sheet_Template__c 
                            FROM Opportunity 
                            WHERE Id = :ts.WhatId 
                            LIMIT 1];

           System.debug('opportunityId ==>'+opp);
           // Stage / Cost_Sheet_Finalised__c / Cost_Sheet_Approval_Status__c are now updated by the
           // Opportunity Cost Sheet Approval Process once it is approved
           // opp.StageName = 'Cost Sheet Approved';
           // opp.Cost_Sheet_Finalised__c = true;
           // opp.Cost_Sheet_Approval_Status__c = 'Approved';
           // update opp;

         if (opp != null && opp.Id != null) {
             Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
             req.setComments('Submitting Opportunity Cost Sheet record for approval.');
             req.setObjectId(opp.Id);
             req.setProcessDefinitionNameOrId('Opportunity_Cost_Sheet_Approval_Process');
             req.setSubmitterId(UserInfo.getUserId());

             Approval.ProcessResult result = Approval.process(req);

             if (result.isSuccess()) {
                 System.debug('Approval request submitted successfully.');
                 return 'Approval request submitted successfully for Opportunity ID: ' + opp.Id;
             } else {
                 System.debug('Approval request submission failed.');
                 return 'Approval request submission failed for Opportunity ID: ' + opp.Id;
             }
         } else {
             throw new AuraHandledException('Opportunity not found or not associated with the given Task.');
         }
     } catch (Exception e) {
         System.debug('Exception when submitting for approval: ' + e.getMessage());
         throw new AuraHandledException('Approval submission failed: ' + e.getMessage());
     }
 }
}