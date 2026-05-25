@isTest
public class TaxMasterControllerTest {
   @isTest
    public static void testCheckUniqueName(){
        Tax_Master__c t1 = new Tax_Master__c(Name=' test1 ',Tax__c = 5,Taxable__c=6,Short_Name__c = 'T1');
        insert t1;
        Tax_Master__c t2 = new Tax_Master__c(Name=' test2 ',Tax__c = 5,Taxable__c=6,Short_Name__c = 'T2');
        insert t2;
        List<Tax_Master__c> newTMs = new List<Tax_Master__c>{t1};
        Map<Id,Tax_Master__c> oldTMs = new Map<Id,Tax_Master__c>();
        oldTMs.put(t2.Id,t2);
        Test.startTest();
        TaxMasterController.checkUniqueName(newTMs,oldTMs);
        Test.stopTest();
        
        
    }
}