public without sharing class editPricingOnOpportunityController {

    @AuraEnabled
    public static String getAccess(String opportunityId){
        System.debug('opportunityId: ' + opportunityId);
        if (opportunityId == null) {
            throw new AuraHandledException('Opportunity Id cannot be null.');
        }
        
        try {
             User us = [SELECT Id, Name, Profile.Name FROM User WHERE Id = :UserInfo.getUserId()];
            System.debug('Current User: ' + us.Name + ' Profile: ' + us.Profile.Name);

            List<Opportunity>oppList = [select id,StageName,Cost_Sheet_Approval_Status__c,Cost_Sheet_Finalised__c from Opportunity where Id =: opportunityId];
            if(us.Profile.Name == 'System Administrator' || us.Profile.Name == 'Admin'){
                if(oppList[0].Cost_Sheet_Finalised__c != True){
                    return '1';
                }else{
                    return '2';
                }

            }else{
                if(oppList[0].Cost_Sheet_Approval_Status__c != 'Approved' && oppList[0].Cost_Sheet_Finalised__c == True){
                    return '1';
                }else{
                    return '3';
                }
            }
            
           
           
        }catch (Exception e) {
            System.debug('Error: ' + e.getMessage() + ' at line: ' + e.getLineNumber());
            return null;
        }
    }

    @AuraEnabled
    public static List<Cost_Sheet__c> getPricingElements(String opportunityId){
        System.debug('opportunityId: ' + opportunityId);
        if (opportunityId == null) {
            throw new AuraHandledException('Opportunity Id cannot be null.');
        }

        try {
            List<Cost_Sheet__c> costSheets = [SELECT Id, Opportunity__c, finalize_CostSheet__c, (SELECT Id, Pricing_Element_Master__c, Pricing_Element_Master__r.Name, Unit__c, Quantity__c, Rate__c, Amount__c, Final_Tax_Amount__c, Discount_Amount__c, PE_Type__c FROM Pricing_Elements__r) FROM Cost_Sheet__c WHERE Opportunity__c = :opportunityId AND finalize_CostSheet__c = true LIMIT 1];
            return costSheets;
        }catch (Exception e) {
            System.debug('Error: ' + e.getMessage() + ' at line: ' + e.getLineNumber());
            return null;
        }
    }

    @AuraEnabled
    public static void savePricingElements(List<Pricing_Element__c> pricingElements) {
        if (pricingElements == null || pricingElements.isEmpty()) {
            throw new AuraHandledException('The list of pricing Elements cannot be null or empty.');
        }
        try {
            update pricingElements;
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage() + ' at line: ' + e.getLineNumber());
            throw new AuraHandledException('An unexpected error occurred while saving pricing elements.');
        }
    }

     @AuraEnabled
     public static string createOpportunity(string currentAccountId, string recordId) {
         System.debug('currentAccountId======>' + currentAccountId);
          System.debug('recordId======>' + recordId);
          Opportunity opp = new Opportunity();
       try {
        if (recordId != null) {
            List<Opportunity> oppList = [
                SELECT Id, AccountId, Account.Name FROM Opportunity WHERE Id =: recordId
            ];
            if (!oppList.isEmpty()) {
                // Save old account name before updating
                String oldAccountId = oppList[0].AccountId;
                String oldAccountName = '';
                String newAccountName = '';

                if (oldAccountId != null) {
                    oldAccountName = [SELECT Name FROM Account WHERE Id = :oldAccountId].Name;
                }
                if (currentAccountId != null) {
                    newAccountName = [SELECT Name FROM Account WHERE Id = :currentAccountId].Name;
                }

                opp.Id = recordId;
                opp.AccountId = currentAccountId;
                opp.Previous_Opportunity__c = oppList[0].AccountId;
                update opp;
                System.debug('opp======>' + opp);

                // Add a Note after update
               ContentNote contentNote = new ContentNote();
                contentNote.Title = 'Ownership Transferred from ' + oldAccountName + ' to ' + newAccountName;
                System.debug('contentNote.Title====>'+contentNote.Title);
                contentNote.Content = Blob.valueOf('Ownership successfully transferred from ' + oldAccountName + ' to ' + newAccountName + '.');
                contentNote.OwnerId = UserInfo.getUserId(); // optional
                insert contentNote;
                System.debug('contentNote====>'+contentNote);

                // Link the note to the Opportunity
                ContentDocumentLink link = new ContentDocumentLink();
                link.ContentDocumentId = contentNote.Id;
                link.LinkedEntityId = recordId;
                link.ShareType = 'V'; // Viewer
                link.Visibility = 'AllUsers';
                insert link;
                 System.debug('link====>'+link);
            }
        }

        }catch(Exception error){
            System.debug('Error in saveOppResult ===> ' + error.getMessage()+ 'Line number ===> ' + error.getLineNumber());            
        }
        return opp.Id;
     }

    @AuraEnabled
    public static Id createContactFromAccount(Id accountId) {
        Account acc = [SELECT Id, Name, Phone, Website, Email__c FROM Account WHERE Id = :accountId LIMIT 1];

        Contact con = new Contact();
        con.AccountId = acc.Id;
        con.LastName = acc.Name != null ? acc.Name : 'Unnamed';
        if (acc.Email__c != null) {
            con.Email = acc.Email__c;
        }
        if (acc.Phone != null) {
            con.Phone = acc.Phone;
        }

        insert con;
        return con.Id;
    }

}