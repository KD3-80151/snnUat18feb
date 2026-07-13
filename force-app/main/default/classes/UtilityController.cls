public withOut sharing class UtilityController {
    public static List<String> getPicklistValues(String ObjectApi_name, String Field_name){
        List<String> lstPickvals = new List<String>();
        Schema.SObjectType targetType = Schema.getGlobalDescribe().get(ObjectApi_name);
        Sobject Object_name = targetType.newSObject();
        Schema.sObjectType sobject_type = Object_name.getSObjectType();
        Schema.DescribeSObjectResult sobject_describe = sobject_type.getDescribe();
        Map<String, Schema.SObjectField> field_map = sobject_describe.fields.getMap();
        List<Schema.PicklistEntry> pick_list_values = field_map.get(Field_name).getDescribe().getPickListValues();
        for (Schema.PicklistEntry a : pick_list_values){
            lstPickvals.add(String.ValueOf(a.getLabel()).trim());
        }
        System.debug('lstPickvals Values Method 1 === :'+lstPickvals);
        return lstPickvals;
    }

    public static List<String> getPicklistValuesWithAll(String ObjectApi_name, String Field_name){
        List<String> pickList = new List<String>{ 'All' };
            pickList.addAll(getPicklistValues(objectApi_name, field_name));
        System.debug('pickList Values Method 2 == :'+pickList);
        return pickList;
    }

    public static String generateRandomString(){
        Integer len = 10;
        final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
        String randStr = '';
        while (randStr.length() < len) {
            Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
            randStr += chars.substring(idx, idx+1);
        }
        return randStr+string.ValueOf(system.now().getTime()); 
    }

    public static String generateOTP(){
        Integer len = 6;
        String randStr = '';
        while (randStr.length() < len) {
            Integer num = Math.mod(Math.abs(Crypto.getRandomInteger()), 9);
            randStr += String.valueOf(num);
        }
        SYstem.debug('Generated OTP ---> '+randStr);
        return randStr; 
    }

        public static Map<String, String> getPicklistValueMap(String objName, String fieldName) {
        Map<String, String> picklistValues = new Map<String, String>();
        if (String.isBlank(objName) || String.isBlank(fieldName)) {
            System.debug('Object or field name is blank');
            return picklistValues;
        }
        try {
            Schema.SObjectType sObjType = Schema.getGlobalDescribe().get(objName);
            if (sObjType == null) {
                System.debug('No SObject type found for name: ' + objName);
                return picklistValues;
            }
            Schema.DescribeSObjectResult describeResult = sObjType.getDescribe();
            Schema.SObjectField field = describeResult.fields.getMap().get(fieldName);
            if (field == null) {
                System.debug('No SObject field found for name: ' + fieldName);
                return picklistValues;
            }
            for (Schema.PicklistEntry entry : field.getDescribe().getPicklistValues()) {
                if (entry.isActive()) {
                    picklistValues.put(entry.getLabel(), entry.getValue()); // or reverse if needed
                }
            }
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
        }
        System.debug('picklistValues: ' + picklistValues);
        return picklistValues;
    }
}