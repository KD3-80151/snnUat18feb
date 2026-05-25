public without sharing class PaymentSchemeCostSheetLinkingController {

     public class WrapperList {
        @AuraEnabled
        public List<Company__c> companyNames { get; set; }

        @AuraEnabled
        public List<Project__c> projectNames { get; set; }

        @AuraEnabled
        public List<Tower__c> towerNames { get; set; }

        @AuraEnabled
        public List<Payment_Scheme__c> paymentSchemes { get; set; }

        @AuraEnabled
        public List<Cost_Sheet_Template__c> costSheetNames { get; set; }


        public WrapperList() {
            companyNames = new List<Company__c>();
            projectNames = new List<Project__c>();
            towerNames = new List<Tower__c>();
            paymentSchemes = new List<Payment_Scheme__c>();
            costSheetNames = new List<Cost_Sheet_Template__c>();
        }

        public void addCompany(Company__c company) {
            companyNames.add(company);
        }

        public void addProject(Project__c project) {
            projectNames.add(project);
        }

        public void addTower(Tower__c tower) {
            towerNames.add(tower);
        }

        public void addPaymentScheme(Payment_Scheme__c paymentScheme) {
            paymentSchemes.add(paymentScheme);
        }

        public void addCostSheetTemplate(Cost_Sheet_Template__c costSheet) {
            costSheetNames.add(costSheet);
        }
    }

    @AuraEnabled(cacheable=true)
    public static WrapperList getCostSheetData() {
        List<Company__c> companyList = [select id,Name,Email__c from Company__c  ];

        List<Project__c> projectsList = [select id,Name,Company__c from Project__c];

        List<Tower__c> towersList = [select id,Name,Project__c,Tower_Code__c,Parking_Availability__c from Tower__c];

        List<Payment_Scheme__c> paymentSchemes = [select id,Name,Block__c,Company__c,Project__c,From_Date__c,To_Date__c,Token_Amount__c,Installment_start_date_diff_in_days__c from Payment_Scheme__c where Approval_Status__c =: 'Approved'];

        List<Cost_Sheet_Template__c> costSheetTemplates = [select id,Name,Company__c,Project__c,Template_Code__c from Cost_Sheet_Template__c where Approval_Status__c =: 'Approved'];
        
        WrapperList wrapper = new WrapperList();
        
        for (Company__c company : companyList) {
            wrapper.addCompany(company);
        }

        for(Project__c project  : projectsList){
            wrapper.addProject(project );
        }

        for(Tower__c tower : towersList){
            wrapper.addTower(tower );
        }

        for(Payment_Scheme__c paymentScheme : paymentSchemes){
            wrapper.addPaymentScheme(paymentScheme );
        }

        for(Cost_Sheet_Template__c costSheet : costSheetTemplates){
            wrapper.addCostSheetTemplate(costSheet);
        }

        return wrapper;
    }

   @AuraEnabled
public static List<Scheme_Installment__c> submitData(String paymentSchemeId, String costSheetId) {
    List<Scheme_Installment__c> allSchemeInstallments = new List<Scheme_Installment__c>();
    try {
        System.debug('paymentSchemeId ===> ' + paymentSchemeId);
        System.debug('costSheetId ===> ' + costSheetId);

        List<Cost_Scheme_Linking__c> allCostSheetLinks = [
            SELECT Id, Cost_Sheet_Template__c, Payment_Scheme__c, Approval_Status__c, Name 
            FROM Cost_Scheme_Linking__c 
            WHERE Cost_Sheet_Template__c = :costSheetId 
            AND Payment_Scheme__c = :paymentSchemeId
        ];
        System.debug('allCostSheetLinks ==> ' + allCostSheetLinks);

        // Check if a record already exists
        if (!allCostSheetLinks.isEmpty()) {
            System.debug('error..');
            throw new AuraHandledException('Error: A cost scheme linking already exists with the selected Payment Scheme and Cost Sheet Template.');
        }

        // Proceed if no duplicate record was found
        Cost_Scheme_Linking__c costSheetRecord = new Cost_Scheme_Linking__c();
        costSheetRecord.Payment_Scheme__c = paymentSchemeId;
        costSheetRecord.Cost_Sheet_Template__c = costSheetId;

        insert costSheetRecord;
        String csInstallId = costSheetRecord.Id;
        System.debug('Inserted costSheetRecord ==> ' + costSheetRecord);

        // if (costSheetRecord != null) {
        //     Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        //     req.setComments('Submitting Cost Scheme Linking record for approval.');
        //     req.setObjectId(csInstallId);
        //     req.setProcessDefinitionNameOrId('Cost_Scheme_Linking_Approval_Process');
        //     req.setSubmitterId(UserInfo.getUserId());

        //     try {
        //         Approval.ProcessResult result = Approval.process(req);
                
        //         if (result.isSuccess()) {
        //             System.debug('Approval request submitted successfully.');
        //             costSheetRecord.Approval_Status__c = 'Sent';
        //             update costSheetRecord;
        //         } else {
        //             System.debug('Approval request submission failed.');
        //         }
        //     } catch (Exception e) {
        //         System.debug('Exception when submitting for approval: ' + e.getMessage());
        //         throw new AuraHandledException('Approval submission failed: ' + e.getMessage());
        //     }
        // }

        // Fetch related installment records
        List<Payment_Scheme_Installment__c> allPaymentSchemeInstallment = [
            SELECT Id, Payment_Schedule_Master__c, Payment_Scheme__c, Installment__c,Display_Order__c
            FROM Payment_Scheme_Installment__c 
            WHERE Payment_Scheme__c = :paymentSchemeId
        ];
        System.debug('allPaymentSchemeInstallment ==> ' + allPaymentSchemeInstallment);

        // Get cost sheet details
        Cost_Sheet_Template__c costSheet = [
            SELECT Id, Tax_Amount__c, Amount__c 
            FROM Cost_Sheet_Template__c 
            WHERE Id = :costSheetId
        ];
        System.debug('costSheet ==> ' + costSheet);

        // Create installment records
        Set<String> allSchemeInterest = new Set<String>();
        for (Payment_Scheme_Installment__c schemeInstallment : allPaymentSchemeInstallment) {
            Scheme_Installment__c schemeInstallments = new Scheme_Installment__c();
            schemeInstallments.Cost_Scheme_Linking__c = costSheetRecord.Id;
            schemeInstallments.Display_Order__c = schemeInstallment.Display_Order__c;
            schemeInstallments.Payment_Schedule_Master__c = schemeInstallment.Payment_Schedule_Master__c;
            schemeInstallments.Installment__c = schemeInstallment.Installment__c;
            schemeInstallments.Agreement_Value__c = (schemeInstallment.Installment__c / 100) * costSheet.Amount__c;
            schemeInstallments.Agreement_Tax__c = (schemeInstallment.Installment__c / 100) * costSheet.Tax_Amount__c;
            allSchemeInstallments.add(schemeInstallments);
        }
        System.debug('allSchemeInstallments ==> ' + allSchemeInstallments);
        
        insert allSchemeInstallments;

        for (Scheme_Installment__c insertedRecord : allSchemeInstallments) {
            allSchemeInterest.add(insertedRecord.Id);
        }
        System.debug('All Scheme Installment IDs => ' + allSchemeInterest);

        // Retrieve and return inserted installments
        List<Scheme_Installment__c> allSchemes = [
            SELECT Id, Cost_Scheme_Linking__c, Payment_Schedule_Master__c, Payment_Schedule_Master__r.Name, Name, Installment__c, Agreement_Value__c, Agreement_Tax__c 
            FROM Scheme_Installment__c 
            WHERE Id IN :allSchemeInterest
        ];

        return allSchemes;

    } catch (AuraHandledException e) {
        System.debug('AuraHandledException caught in submitData: ' + e.getMessage());
        throw e; // Rethrow to handle it in the calling component
    } catch (Exception e) {
        System.debug('Exception caught in submitData: ' + e.getMessage());
        throw new AuraHandledException('Error occurred while processing data: ' + e.getMessage());
    }
}


    

    @AuraEnabled
    public static CostSheetDataWrapper  getCostSheetExisData(String costSchemeId){
        try{
            System.debug('recordId==>'+costSchemeId);
            Cost_Scheme_Linking__c costSchemeLinking =  [select id,Name,Cost_Sheet_Template__r.Name,Payment_Scheme__c,Payment_Scheme__r.Name,Cost_Sheet_Template__c,Cost_Sheet_Template__r.Company__r.Name,Cost_Sheet_Template__r.Company__c,Cost_Sheet_Template__r.Project__c,Cost_Sheet_Template__r.Project__r.Name,Payment_Scheme__r.Block__c,Payment_Scheme__r.Id,Approval_Status__c  from Cost_Scheme_Linking__c Where Id =: costSchemeId Limit 1];

            System.debug('costSchemeLinking==>'+costSchemeLinking);

            List<Scheme_Installment__c> schemeInstallments1 =   [select id,Name,Cost_Scheme_Linking__c,Payment_Schedule_Master__c,Payment_Schedule_Master__r.Name,Agreement_Value__c,Agreement_Tax__c,Installment__c from Scheme_Installment__c where Cost_Scheme_Linking__c  =: costSchemeId];

            System.debug('schemeInstallments==>'+schemeInstallments1);

            return new CostSheetDataWrapper(costSchemeLinking, schemeInstallments1);
        }catch(Exception e){
            System.debug('Exception caught in submitData: ' + e.getMessage());
            throw new AuraHandledException('Error occurred while processing data: ' + e.getMessage());
        }

    }

    public class CostSheetDataWrapper {
        @AuraEnabled
        public Cost_Scheme_Linking__c costSchemeLinking { get; set; }
        @AuraEnabled
        public List<Scheme_Installment__c> schemeInstallments1 { get; set; }

        public CostSheetDataWrapper(Cost_Scheme_Linking__c costSchemeLinking, List<Scheme_Installment__c> schemeInstallments1) {
            this.costSchemeLinking = costSchemeLinking;
            this.schemeInstallments1 = schemeInstallments1;
        }
    }


 @AuraEnabled
public static List<Scheme_Installment__c> updateData(String paymentSchemeId, String costSheetId, String schemeId,String costSheetIdNew) {

    
    System.debug('paymentSchemeId==>'+paymentSchemeId);
    System.debug('costSheetId==>'+costSheetId);
    System.debug('schemeId==>'+schemeId);
    System.debug('costSheetIdNew==>'+costSheetIdNew);
    if(costSheetIdNew != null){

        Cost_Scheme_Linking__c costSheetRecord = [SELECT Id, Payment_Scheme__c, Cost_Sheet_Template__c 
                                                FROM Cost_Scheme_Linking__c 
                                                WHERE Id = :costSheetIdNew 
                                                LIMIT 1];

         Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
            req.setComments('Submitting Cost Scheme Linking record for approval.');
            req.setObjectId(costSheetIdNew);
            req.setProcessDefinitionNameOrId('Cost_Scheme_Linking_Approval_Process');
            req.setSubmitterId(UserInfo.getUserId());

            try {
                Approval.ProcessResult result = Approval.process(req);
                
                if (result.isSuccess()) {
                    System.debug('Approval request submitted successfully.');
                    costSheetRecord.Approval_Status__c = 'Sent';
                    update costSheetRecord;
                } else {
                    System.debug('Approval request submission failed.');
                }
            } catch (Exception e) {
                System.debug('Exception when submitting for approval: ' + e.getMessage());
                throw new AuraHandledException('Approval submission failed: ' + e.getMessage());
            }

            return [SELECT Id, Cost_Scheme_Linking__c, Payment_Schedule_Master__c, 
                       Payment_Schedule_Master__r.Name, Installment__c, Agreement_Value__c, 
                       Agreement_Tax__c 
                FROM Scheme_Installment__c 
                WHERE  Cost_Scheme_Linking__c =:costSheetIdNew];


    }else{

        List<Scheme_Installment__c> allSchemeInstallments = new List<Scheme_Installment__c>();
    Cost_Scheme_Linking__c costSheetRecord = new Cost_Scheme_Linking__c();
    costSheetRecord.Id = schemeId;

    Cost_Scheme_Linking__c schemeInstallment = [SELECT Id, Payment_Scheme__c, Cost_Sheet_Template__c 
                                                FROM Cost_Scheme_Linking__c 
                                                WHERE Id = :schemeId 
                                                LIMIT 1];

     System.debug('schemeInstallment==>'+schemeInstallment);
    
    if (schemeInstallment == null) {
        throw new CustomDataException('Scheme Installment record not found');
    }

    if (schemeInstallment.Payment_Scheme__c != paymentSchemeId || schemeInstallment.Cost_Sheet_Template__c != costSheetId) {
        
        schemeInstallment.Payment_Scheme__c = paymentSchemeId;
        schemeInstallment.Cost_Sheet_Template__c = costSheetId;
        update schemeInstallment;

        List<Scheme_Installment__c> schemeInstallments1 =   [select id,Name,Cost_Scheme_Linking__c,Payment_Schedule_Master__c,Payment_Schedule_Master__r.Name,Agreement_Value__c,Agreement_Tax__c,Installment__c from Scheme_Installment__c where Cost_Scheme_Linking__c  =: schemeId];
        System.debug('schemeInstallments1==>'+schemeInstallments1);
        delete schemeInstallments1;

        List<Payment_Scheme_Installment__c> allPaymentSchemeInstallment = [SELECT Id, Payment_Schedule_Master__c, 
                                                                            Payment_Scheme__c, Installment__c 
                                                                            FROM Payment_Scheme_Installment__c 
                                                                            WHERE Payment_Scheme__c = :paymentSchemeId];
        if (allPaymentSchemeInstallment.isEmpty()) {
            throw new CustomDataException('No Payment Scheme Installments found');
        }

        Cost_Sheet_Template__c costSheet = [SELECT Id, Tax_Amount__c, Amount__c 
                                            FROM Cost_Sheet_Template__c 
                                            WHERE Id = :costSheetId 
                                            LIMIT 1];
        if (costSheet == null) {
            throw new CustomDataException('Cost Sheet record not found');
        }

        for (Payment_Scheme_Installment__c psi : allPaymentSchemeInstallment) {
            Decimal installmentPercentage = psi.Installment__c / 100;
            Scheme_Installment__c schemeInstallments = new Scheme_Installment__c(
                Cost_Scheme_Linking__c = schemeInstallment.Id,
                Payment_Schedule_Master__c = psi.Payment_Schedule_Master__c,
                Installment__c = psi.Installment__c,
                Agreement_Value__c = installmentPercentage * costSheet.Amount__c,
                Agreement_Tax__c = installmentPercentage * costSheet.Tax_Amount__c
            );
            allSchemeInstallments.add(schemeInstallments);
        }

        insert allSchemeInstallments;

       
        return [SELECT Id, Cost_Scheme_Linking__c, Payment_Schedule_Master__c, 
                       Payment_Schedule_Master__r.Name, Installment__c, Agreement_Value__c, 
                       Agreement_Tax__c 
                FROM Scheme_Installment__c 
                WHERE Id IN :allSchemeInstallments];
    }



    }

    return new List<Scheme_Installment__c>(); 
}





public class CustomDataException extends Exception {
   
}


    
    
}