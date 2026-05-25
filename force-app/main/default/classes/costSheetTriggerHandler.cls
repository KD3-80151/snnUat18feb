public without Sharing  class costSheetTriggerHandler {
    public static void afterUpdate(Map<Id,Cost_Sheet__c> newMap, Map<Id,Cost_Sheet__c> oldMap){
        try{
            System.debug('after update cost sheet');
            Set<Id> costSheetIds = new Set<Id>();
            for(Id costSheetId : newMap.keySet()){
                Cost_Sheet__c newCostSheet = newMap.get(costSheetId);
                Cost_Sheet__c oldCostSheet = oldMap.get(costSheetId);
                
                if(newCostSheet.Finalize_CostSheet__c == true && oldCostSheet.Finalize_CostSheet__c != true){
                    costSheetIds.add(costSheetId);
                }
            }
            List<Pricing_Element__c> pricingElementList = [SELECT Id,Name,Cost_Sheet__c,Pricing_Element_Master__c,Pricing_Element_Master__r.Parking_Type__c,Quantity__c from Pricing_Element__c 
                                                            WHERE Cost_Sheet__c IN: costSheetIds AND Pricing_Element_Master__r.Parking_Type__c != null];
            Map<String,Decimal> parkingTypeByQuantity = new Map<String,Decimal>();
            if(!pricingElementList.isEmpty()){
                for(Pricing_Element__c pricing : pricingElementList){
                    if(pricing.Pricing_Element_Master__r.Parking_Type__c != null){
                        parkingTypeByQuantity.put(pricing.Pricing_Element_Master__r.Parking_Type__c, pricing.Quantity__c);
                    }
                }
            }
    
            List<Parking_Details__c> parkingDetailsList;
            List<Parking_Details__c> parkingDetailsToUpdate = new List<Parking_Details__c>();
            if(parkingTypeByQuantity != null){
                parkingDetailsList = [SELECT Id, Name,Parking_Type__c,Amount__c,Total_Parking__c,Available_Parking__c from Parking_Details__c where Parking_Type__c IN: parkingTypeByQuantity.keySet()];
                if(!parkingDetailsList.isEmpty()){
                    for(Parking_Details__c parking : parkingDetailsList){
                        Decimal parkingQuantity = parking.Parking_Type__c != null ? parkingTypeByQuantity.get(parking.Parking_Type__c) : parking.Total_Parking__c;
                        parking.Available_Parking__c = parking.Available_Parking__c != null ? parking.Available_Parking__c - parkingQuantity : parking.Total_Parking__c - parkingQuantity;
                        parkingDetailsToUpdate.add(parking);
                    }
                }
            }
    
            if(!parkingDetailsToUpdate.isEmpty()){
                update parkingDetailsToUpdate;
            }
        }catch(Exception e){
            system.debug('Error ==> ' + e.getMessage());
            system.debug('Error in line ==> ' + e.getLineNumber());
        }
    }
}