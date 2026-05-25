public without Sharing  class channelPartner_InventoryController {


	 @AuraEnabled(cacheable=true)
    public static List<Project__c> getProjectDetails(){
        List<Project__c> projectList = [SELECT Id,Name,City__c,Zone__c from Project__c]; 
        if(projectList.size() > 0){
            return projectList;
        }
        return null;
    }
    
    @AuraEnabled(cacheable= true)
    public static Map<String, List<String>> getAllPickListVal(Map<String, String> ObjectByField){
        Map<String, List<String>> picklistValByField = new Map<String, List<String>>();
        for(String fields : ObjectByField.keySet()){
            picklistValByField.put(fields, getPicklistValues(ObjectByField.get(fields), fields));
        }
        return picklistValByField;
    }
    
    @AuraEnabled(cacheable= true)
    public static List<String> getPicklistValues(String objName, String fieldName){
        List<String> options = new List<String>();
        Map<String, String> mapPickListValues = new Map<String, String>();
        Schema.SObjectType objSobjectType = Schema.getGlobalDescribe().get(objName);
        Schema.DescribeSObjectResult objDescribeSobject = objSobjectType.getDescribe();
        Map<String, Schema.SObjectField> mapFields = objDescribeSobject.fields.getMap();
        List<Schema.PicklistEntry> lstPickListValues = mapFields.get(fieldName).getDescribe().getPickListValues();
        for (Schema.PicklistEntry objPickList : lstPickListValues) {
            options.add(objPickList.getValue());
        }
        return options;
    }
    
    @AuraEnabled
    public static SelectPropertiesWrappper getProjectDetailsBasedonSearch(String city,String zone,String projectName,String FlatBhkId, String towerName){ 
        System.debug('city === >'+city + ' zone ===> ' + zone + ' projectName ===> ' + projectName + ' towerName===> '  +towerName) ;
        SelectPropertiesWrappper untiwrap = new SelectPropertiesWrappper();
        List<Unit__c> getUnitBasedProjectQuery = new List<Unit__c>();
        Set<Id> ProjectIdSet = new Set<Id>();
        Set<Id> SlabsIdSet = new Set<Id>();
        Integer AvailableForSaleCount = 0;
        Integer SoldCount = 0;
        Integer ManagementBlockedCount = 0;
        Integer UnderCustomerDiscussionCount = 0;
        Integer NotReleasedbyManagementCount = 0;
        Integer BlockedforSafetyClearanceCount = 0;
        Integer waitingPaymentConfirmationCount = 0;
        map<String, List<Unit__c>> FloorwithunitMap = new map<String, List<Unit__c>>();
        
        try{
            List<Project__c> getAllProjectRecordsList = [SELECT Id,Name,Zone__c,City__c FROM Project__c WHERE Name=:projectName AND Zone__c=:zone AND City__c=:city];
            System.debug('getAllProjectRecordsList ===> ' + getAllProjectRecordsList);
            if(getAllProjectRecordsList.size()>0){
                for(Project__c pro : getAllProjectRecordsList){
                    ProjectIdSet.add(pro.id);
                }

                if(ProjectIdSet.size()>0){
                    List<Tower__c> towers = [SELECT Id, Name FROM Tower__c WHERE Project__r.Name = :projectName order by Name ASC];
                    System.debug('towers ===> ' + towers);
                    Set<String> towerNamesSet = new Set<String>();
                    List<String> towerPicklist;
                    if(towers.size() > 0){
                        for (Tower__c tower : towers) {
                            towerNamesSet.add(tower.Name);
                        }
                        towerPicklist = new List<String>(towerNamesSet);
                        untiwrap.TowerPickistvalues = towerPicklist;
                        System.debug('untiwrap.TowerPickistvalues===>'+untiwrap.TowerPickistvalues);
                    }

                    String defaultTower = towerPicklist.contains(towerName) ? towerName : towerPicklist[0];
                    System.debug('defaultTower ==> ' + defaultTower);
                    List<Floor__c> projectTowerSlabs = [SELECT Construction_Status__c, Floor_No__c, Id, Name,Blocks__c, (SELECT Id,Name,Floor__c FROM Units__r) FROM Floor__c WHERE Blocks__r.Name =: defaultTower ORDER By Floor_No__c DESC];
                    Set<Id> floorIds = new Set<Id>();
                    if(projectTowerSlabs.size() > 0){
                        for(Floor__c floor : projectTowerSlabs){
                            floorIds.add(floor.Id);
                        }
                        untiwrap.getSlabsListFromUnit =projectTowerSlabs;
                        System.debug('untiwrap.getSlabsListFromUnit ===> ' + untiwrap.getSlabsListFromUnit);
                    }
                    
                    String defaultUnitType = FlatBhkId == null ? '1 BHK' : FlatBhkId;
                    System.debug('defaultUnitType ==> ' + defaultUnitType);
                    List<Unit__c> units = [SELECT Id,Name,Unit_Name__c,Status__c,Floor__c, Floor__r.Name,Floor__r.Floor_No__c,Unit_Type__c,Floor__r.Blocks__r.Name FROM Unit__c  WHERE Floor__r.Floor_No__c !=null and Floor__c IN: floorIds and Unit_Type__c =: defaultUnitType];
                    System.debug('units size==>'+ units.size());
                    untiwrap.defaultTowerName = defaultTower != null ? defaultTower : null;
                    untiwrap.defaultFlatType = defaultUnitType != null ? defaultUnitType : null;

                    for(Unit__c unit : units ){
                        System.debug('unit ===> ' + unit);
                        System.debug('unit status ===> ' + unit.Status__c);
                        if(String.isNotBlank(unit.Status__c)){
                            AvailableForSaleCount           = (unit.Status__c == 'For Sale') ? AvailableForSaleCount + 1 : AvailableForSaleCount;
                            SoldCount                       = (unit.Status__c =='Sold') ? SoldCount + 1 : SoldCount;
                            ManagementBlockedCount          = (unit.Status__c =='Management Blocked') ? ManagementBlockedCount + 1 : ManagementBlockedCount;
                            UnderCustomerDiscussionCount    = (unit.Status__c =='Under Customer Discussion') ? UnderCustomerDiscussionCount + 1 : UnderCustomerDiscussionCount;
                            NotReleasedbyManagementCount    = (unit.Status__c =='Not Released by Management') ? NotReleasedbyManagementCount + 1 : NotReleasedbyManagementCount;
                            BlockedforSafetyClearanceCount  = (unit.Status__c =='Blocked for Safety Clearance ') ? BlockedforSafetyClearanceCount + 1 : BlockedforSafetyClearanceCount;
                            waitingPaymentConfirmationCount = (unit.Status__c =='Awaiting Payment Confirmation') ? waitingPaymentConfirmationCount + 1 : waitingPaymentConfirmationCount;
                        }
                        if (FloorwithunitMap.containsKey(unit.Floor__r.Name)){
                            List<Unit__c> ExistingUnitlist = FloorwithunitMap.get(unit.Floor__r.Name);
                            if (unit.Status__c != null){
                                ExistingUnitlist.add(unit);
                            }
                            FloorwithunitMap.put(unit.Floor__r.Name, ExistingUnitlist);
                        } else{
                            List<Unit__c> NewUnitlist = new List<Unit__c>();
                            NewUnitlist.add(unit);
                            FloorwithunitMap.put(unit.Floor__r.Name, NewUnitlist);
                        }
                        untiwrap.FloorwithunitMapDetails = FloorwithunitMap;
                    }
                    if(AvailableForSaleCount !=null){
                        untiwrap.AvailableforSale = AvailableForSaleCount;
                    }
                    if(SoldCount !=null){
                        untiwrap.Sold = SoldCount;
                    }
                    if(ManagementBlockedCount !=null){
                        untiwrap.ManagementBlocked = ManagementBlockedCount;
                    }
                    if(UnderCustomerDiscussionCount !=null){
                        untiwrap.UnderCustomerDiscussion = UnderCustomerDiscussionCount;
                    }
                    if(NotReleasedbyManagementCount !=null){
                        untiwrap.Blocked_NotReleasedbyMgmt = NotReleasedbyManagementCount;
                    }
                    if(BlockedforSafetyClearanceCount !=null){
                        untiwrap.Blocked_ForFire_SafetyClearance = BlockedforSafetyClearanceCount;
                    }
                    if(waitingPaymentConfirmationCount !=null){
                        untiwrap.AwaitingPaymentConfirmation = waitingPaymentConfirmationCount;
                    }
                    if(getUnitBasedProjectQuery.size()>0){
                        untiwrap.getUnitRecordBasedOnProjectList = getUnitBasedProjectQuery;
                    }
                    
                    if(untiwrap !=null){
                        System.debug('untiwrap.FloorwithunitMapDetails ===> ' + untiwrap.FloorwithunitMapDetails);
                        System.debug('untiwrap == >'+untiwrap);
                        return untiwrap;
                    }
                }
            }else{
                return null;
            }
        }catch(Exception e){
            System.debug('The Error ::'+e.getMessage() +' AND Error Line No :'+e.getLineNumber());
        }
        return null;
    }
    
    public class SelectPropertiesWrappper{
        @AuraEnabled public List<Unit__c> getUnitRecordBasedOnProjectList { get; set; }
        @AuraEnabled public List<Floor__c> getSlabsListFromUnit { get; set; }
        @AuraEnabled public map<String, List<Unit__c>> FloorwithunitMapDetails{ get; set; }
        @AuraEnabled public Integer AvailableforSale { get; set; }
        @AuraEnabled public Integer AwaitingPaymentConfirmation { get; set; }
        @AuraEnabled public Integer Sold { get; set; }
        @AuraEnabled public Integer ManagementBlocked { get; set; }
        @AuraEnabled public Integer UnderCustomerDiscussion { get; set; }
        @AuraEnabled public Integer Blocked_NotReleasedbyMgmt { get; set; }
        @AuraEnabled public Integer Blocked_ForFire_SafetyClearance { get; set; }
        @AuraEnabled public List<String> TowerPickistvalues{ get; set; }
        @AuraEnabled public String defaultTowerName { get; set; }
        @AuraEnabled public String defaultFlatType { get; set; }
    }
    
    @AuraEnabled(cacheable=true)
    public static Unit__c getUnitRecord(String recordId) {
        return [SELECT Id, Name, Unit_Name__c, Status__c, Floor__c, Floor__r.Name, Floor__r.Floor_No__c, Unit_Type__c FROM Unit__c WHERE Id = :recordId LIMIT 1];
    }
	
}