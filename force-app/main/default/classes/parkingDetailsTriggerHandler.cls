public without sharing class parkingDetailsTriggerHandler {
    
    public static void validateBeforeInsert(List<Parking_Details__c> newParkingDetails) {
        try{

            Set<Id> towerIds = new Set<Id>();
            Map<Id, Decimal> existingTotalParkingByTower = new Map<Id, Decimal>();
            Map<Id, Map<String, Parking_Details__c>> existingParkingByType = new Map<Id, Map<String, Parking_Details__c>>();
            Map<Id, Decimal> towerCapacityMap = new Map<Id, Decimal>();
            
            for (Parking_Details__c parking : newParkingDetails) {
                if(parking.Parking_Type__c == null){
                    parking.addError('Parking Type is required for creating Parking Details.');
                }
                if (parking.Block__c == null) {
                    parking.addError('Tower is required for creating Parking Details.');
                }
                if(parking.Total_Parking__c != null && parking.Available_Parking__c == null){
                    parking.Available_Parking__c = parking.Total_Parking__c;
                }
                towerIds.add(parking.Block__c);
            }
            
            if (towerIds.isEmpty()) {
                return;
            }
            
            for (Parking_Details__c parking : [ SELECT Block__c, Parking_Type__c, Total_Parking__c FROM Parking_Details__c WHERE Block__c IN :towerIds]) {
                if (!existingParkingByType.containsKey(parking.Block__c)) {
                    existingParkingByType.put(parking.Block__c, new Map<String, Parking_Details__c>());
                }
                existingParkingByType.get(parking.Block__c).put(parking.Parking_Type__c, parking);
                if (!existingTotalParkingByTower.containsKey(parking.Block__c)) {
                    existingTotalParkingByTower.put(parking.Block__c, 0);
                }
                existingTotalParkingByTower.put(parking.Block__c,existingTotalParkingByTower.get(parking.Block__c) + parking.Total_Parking__c);
            }
            
            for (Tower__c tower : [SELECT Id, Total_Parking__c FROM Tower__c WHERE Id IN :towerIds]) {
                towerCapacityMap.put(tower.Id, tower.Total_Parking__c);
            }
            
            for (Parking_Details__c parking : newParkingDetails) {
                Decimal existingTotal = existingTotalParkingByTower.get(parking.Block__c) != null ? existingTotalParkingByTower.get(parking.Block__c) : 0;
                Decimal towerCapacity = towerCapacityMap.get(parking.Block__c);
                
                Map<String, Parking_Details__c> parkingByType = existingParkingByType.get(parking.Block__c);
                if (parkingByType != null && parkingByType.containsKey(parking.Parking_Type__c)) {
                    parking.addError('Only one Parking Details record of type ' + parking.Parking_Type__c + ' is allowed per Tower.');
                }
                
                Decimal newTotalParking = existingTotal + parking.Total_Parking__c;
                if (newTotalParking > towerCapacity) {
                    parking.addError('The total parking across all details exceeds the Tower\'s Total Parking capacity (' + towerCapacity + '). Current total parking (including this record): ' + newTotalParking );
                } else {
                    existingTotalParkingByTower.put(parking.Block__c, newTotalParking);
                    if (parkingByType == null) {
                        parkingByType = new Map<String, Parking_Details__c>();
                        existingParkingByType.put(parking.Block__c, parkingByType);
                    }
                    parkingByType.put(parking.Parking_Type__c, parking);
                }
            }
        }catch(Exception e){
            system.debug('Error ==> ' + e.getMessage());
            system.debug('Error in line ==> ' + e.getLineNumber());
        }
    }

    public static void afterInsert(List<Parking_Details__c> newParkingDetails) {
        try{
            
        }catch(Exception e){
            system.debug('Error ==> ' + e.getMessage());
            system.debug('Error in line ==> ' + e.getLineNumber());
        }
    }
}