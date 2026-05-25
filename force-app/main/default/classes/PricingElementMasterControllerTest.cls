@isTest
public class PricingElementMasterControllerTest {
	@isTest
    static void testCheckUniqueName(){
        List<Pricing_Element_Master__c> newPs = new List<Pricing_Element_Master__c>();
        Map<Id,Pricing_Element_Master__c> oldPs = new Map<Id,Pricing_Element_Master__c>();
        Pricing_Element_Master__c ps1 = new Pricing_Element_Master__c(Name = 'ps1');
        insert ps1;
        oldPs.put(ps1.Id,ps1);
        Pricing_Element_Master__c ps2 = new Pricing_Element_Master__c(Name = 'ps2');
        insert ps2;
        oldPs.put(ps2.Id,ps2);
       	ps1.Name = 'PS1';
        Pricing_Element_Master__c ps3 = new Pricing_Element_Master__c(Name = 'ps2');
        update ps1;
        try{
        insert ps3;
        }catch(Exception e){
            
        }
        newPs.add(ps1);
        newPs.add(ps2);
        Test.startTest();
        try{
        PricingElementMasterController.checkUniqueName(newPs,oldPs);
        }catch(Exception e){
            
        }
        Test.stopTest();
        
    }
}