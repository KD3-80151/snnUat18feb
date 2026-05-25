public with sharing class CostSheetController {
    @AuraEnabled(cacheable=true)
    public static List<Cost_Sheet__c> getCostSheets(Id opportunityId) {
        if(opportunityId != null){
            System.debug('Opportunity Id received: ' + opportunityId);
        } else {
            System.debug('Opportunity Id is null.');
        }
        
        try {
            List<Cost_Sheet__c> costSheets = [
                SELECT Id, Name, Unit__r.Name, Unit__c, Total_Pricing_Value__c
                FROM Cost_Sheet__c
                WHERE Opportunity__c = :opportunityId
            ];

            System.debug('Number of Cost Sheets found: ' + costSheets.size());
            return costSheets.isEmpty() ? null : costSheets;

        } catch (Exception e) {
            System.debug('Error fetching Cost Sheets: ' + e.getMessage());
            return null; 
        }
    }

    public class ParkingDetailsWrapper {
        @AuraEnabled public List<Parking_Details__c> parkingDetails;
        @AuraEnabled public List<String> uniqueParkingTypes;

        public ParkingDetailsWrapper(List<Parking_Details__c> parkingDetails, List<String> uniqueParkingTypes) {
            this.parkingDetails = parkingDetails;
            this.uniqueParkingTypes = uniqueParkingTypes;
        }
    }

    @AuraEnabled(cacheable=true)
    public static ParkingDetailsWrapper getParkingDetails(Id unitId) {
        try {
            Unit__c unit = [SELECT Floor__r.Blocks__r.Id FROM Unit__c WHERE Id = :unitId LIMIT 1];
            if (unit != null && unit.Floor__r != null && unit.Floor__r.Blocks__r != null) {
                List<Parking_Details__c> parkingDetails = [SELECT Id, Parking_Type__c, Amount__c 
                                                           FROM Parking_Details__c 
                                                           WHERE Block__c = :unit.Floor__r.Blocks__r.Id];
                
                List<String> uniqueParkingTypes = new List<String>();
                for (Parking_Details__c detail : parkingDetails) {
                    if (detail.Parking_Type__c != null && !uniqueParkingTypes.contains(detail.Parking_Type__c)) {
                        uniqueParkingTypes.add(detail.Parking_Type__c);
                    }
                }

                return new ParkingDetailsWrapper(parkingDetails, uniqueParkingTypes);
            }
            return null;
        } catch (Exception e) {
            System.debug('Error fetching Parking Details: ' + e.getMessage());
            return null;
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getParkingTypePicklistValues() {
        List<String> parkingTypes = new List<String>();

        try {
            Schema.DescribeFieldResult fieldResult = Parking_Details__c.Parking_Type__c.getDescribe();
            List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();
            for (Schema.PicklistEntry entry : picklistValues) {
                parkingTypes.add(entry.getLabel());
            }
        } catch (Exception e) {
            System.debug('Error fetching Parking Type picklist values: ' + e.getMessage());
        }

        return parkingTypes.isEmpty() ? null : parkingTypes;
    }

    @AuraEnabled
public static String createPricingElement(String jsondata) {
    System.debug('jsondata==>' + jsondata);

    // Deserialize the JSON string into a list of PricingElementWrapper objects
    List<PricingElementWrapper> pricingElementsData = (List<PricingElementWrapper>) JSON.deserialize(jsondata, List<PricingElementWrapper>.class);
    System.debug('pricingElementsData==>' + pricingElementsData);

    try {
        List<Pricing_Element__c> pricingElementsToInsert = new List<Pricing_Element__c>();

        
        if (pricingElementsData == null || pricingElementsData.isEmpty()) {
            return 'Error: No data provided';
        }

        
        for (PricingElementWrapper elementData : pricingElementsData) {
            System.debug('Incoming Element Data: ' + elementData);

            
            Id pricingElementMasterId = getPricingElementMasterIdByName(elementData.pricingElementMasterId);
            
            if (pricingElementMasterId == null) {
                return 'Error: Invalid Pricing Element Master Name';
            }

            
            Pricing_Element__c pricingElement = new Pricing_Element__c(
                Amount__c = elementData.amount,
                Cost_Sheet__c = elementData.costSheetId,
                Quantity__c = elementData.quantity,
                Rate__c = elementData.rate,
                Pricing_Element_Master__c = pricingElementMasterId,  
                parking_Element__c = true
            );

            
            pricingElementsToInsert.add(pricingElement);
        }

        
        insert pricingElementsToInsert;

        
        return 'Success';

    } catch (Exception e) {
        
        System.debug('Error occurred: ' + e.getMessage());
        return 'Error: ' + e.getMessage();
    }
}


private static Id getPricingElementMasterIdByName(String masterName) {
    
    List<Pricing_Element_Master__c> masterRecords = [SELECT Id FROM Pricing_Element_Master__c WHERE Name = :masterName LIMIT 1];
    
    
    if (masterRecords.isEmpty()) {
        return null;  
    }
    
    
    return masterRecords[0].Id;
}

public class PricingElementWrapper {
    @AuraEnabled public Decimal amount;
    @AuraEnabled public Id costSheetId;  
    @AuraEnabled public Integer quantity;
    @AuraEnabled public Decimal rate;
    @AuraEnabled public String pricingElementMasterId;  

    // No-arg constructor
    public PricingElementWrapper() {
    }

    // Constructor to initialize the wrapper class
    public PricingElementWrapper(Decimal amount, Id costSheetId, Integer quantity, Decimal rate, String pricingElementMasterId) {
        this.amount = amount;
        this.costSheetId = costSheetId;
        this.quantity = quantity;
        this.rate = rate;
        this.pricingElementMasterId = pricingElementMasterId;
    }
} 

@AuraEnabled
public static Boolean checkForRelatedUnit(Id costSheetId) {
    try {
        
        Cost_Sheet__c costSheet = [SELECT Id, Unit__c FROM Cost_Sheet__c WHERE Id = :costSheetId LIMIT 1];
        
        if (costSheet != null && costSheet.Unit__c != null) {
            
            return true;
        } else {
            
            return false;
        }
    } catch (Exception e) {
        System.debug('Error checking for related Unit: ' + e.getMessage());
        return false;
    }
}


}