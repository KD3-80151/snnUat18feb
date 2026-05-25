({
    convertArrayToCSV : function(component, sObjectList) {
        if (sObjectList == null || sObjectList.length == 0) {
            return null;  
        } 

        var columnEnd = ',';
        var lineEnd = '\n';

        var keys = [
            'Name', 'Email', 'Phone', 'Project', 'Lead_Source', 'Lead_Sub_Source'
            
        ];

        var csvString = '';
        csvString += keys.join(columnEnd);
        csvString += lineEnd;

        for (var i = 0; i < sObjectList.length; i++) {
            var counter = 0;
            for (var sTempkey in keys) {
                var skey = keys[sTempkey];
                if (counter > 0) {
                    csvString += columnEnd;
                }
                var value = sObjectList[i][skey] === undefined ? '' : sObjectList[i][skey];
                csvString += '"' + value + '"';
                counter++;
            }
            csvString += lineEnd;
        }
        return csvString;  
    }
})