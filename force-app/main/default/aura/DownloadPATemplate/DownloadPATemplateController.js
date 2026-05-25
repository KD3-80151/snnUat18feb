({
    doInit : function(component, event, helper) {
        debugger;
        // Initialization logic can go here if needed
        // Assuming we fetch or set the pApplist attribute here for testing purposes
        // You should replace this with actual logic to fetch records
        var sampleData = [
            {
                Name: "",
                Email: "",
                Phone: "",
                Project: "",
                Lead_Source: "",
                Lead_Sub_Source: ""
            }
        ];
        component.set("v.pApplist", sampleData);
    },

    downloadFormat : function(component, event, helper) {
        var recordsList = component.get("v.pApplist");
        var csv = helper.convertArrayToCSV(component, recordsList);    
        if (csv == null) { 
            console.error('CSV conversion returned null.');
            return; 
        }

        var hiddenElement = document.createElement('a');
        hiddenElement.href = 'data:text/csv;charset=utf-8,' + encodeURI(csv);
        hiddenElement.target = '_self'; 
        hiddenElement.download = 'UploadLeadsUploadTemplate.csv'; 
        document.body.appendChild(hiddenElement);
        hiddenElement.click();
        document.body.removeChild(hiddenElement);
    }
})