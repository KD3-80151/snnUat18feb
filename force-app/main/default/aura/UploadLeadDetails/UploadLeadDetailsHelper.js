({
    readFile: function(component, helper, file) {
        debugger;
        if (!file) return;
        console.log('file'+file.name);
        if(!file.name.match(/\.(csv||CSV)$/)){
            return alert('only support csv files');
        }else{
            
            reader = new FileReader();
            reader.onerror =function errorHandler(evt) {
                switch(evt.target.error.code) {
                    case evt.target.error.NOT_FOUND_ERR:
                        alert('File Not Found!');
                        break;
                    case evt.target.error.NOT_READABLE_ERR:
                        alert('File is not readable');
                        break;
                    case evt.target.error.ABORT_ERR:
                        break; // noop
                    default:
                        alert('An error occurred reading this file.');
                };
            }
            //reader.onprogress = updateProgress;
            reader.onabort = function(e) {
                alert('File read cancelled');
            };
            reader.onloadstart = function(e) { 
                debugger;
                var output = '<ui type=\"disc\"><li><strong>'+file.name +'</strong> ('+file.type+')- '+file.size+'bytes, last modified: '+file.lastModifiedDate.toLocaleDateString()+'</li></ui>';
                component.set("v.newfileName",file.name);
                component.set("v.TargetFileName",output);
                
            };
            reader.onload = function(e) {
                debugger;
                var data=e.target.result;
                component.set("v.fileContentData",data);
                console.log("file data"+JSON.stringify(data));
                var allTextLines = data.split(/\r\n|\n/);
                var dataRows=allTextLines.length-1;
                var headers = allTextLines[0].split(',');
                console.log("Rows length::"+dataRows);
                
                var columnsToExclude = [];
                var filteredHeaders = headers.filter(function(header) {
                    return !columnsToExclude.includes(header.trim());
                });
                
                var filteredDataRows = [];
                
                // Start from index 1 to skip the header row
                for (var i = 1; i < allTextLines.length; i++) {
                    var columns = allTextLines[i].split(',');
                    var filteredData = {};
                    var allSingleColValues = '';
                    for (var j = 0;  j < columns.length; j++) {
                        
                        if( j > 19 && columns[j] != null ){
                            
                            
                            //1. Keep All rest of value till Column End
                            for(var y=19;y<columns.length;y++){
                                allSingleColValues +=columns[y]+',';
                            }
                            // allSingleColValues= allSingleColValues.removeEnd(',');
                            //allSingleColValues = allSingleColValues.slice(0, -1);
                            allSingleColValues = allSingleColValues.replace(/,+$/, '');
                            filteredData[filteredHeaders[19].trim()] = allSingleColValues;
                            break;
                            
                            //And then Break
                        }
                        else if (!columnsToExclude.includes(headers[j].trim())) {
                            filteredData[filteredHeaders[j].trim()] = columns[j];
                        }
                    }
                    filteredDataRows.push(filteredData);
                }
                
                console.log("Filtered headers: " + JSON.stringify(headers));
                console.log("Filtered data rows: " + JSON.stringify(filteredDataRows));
                
                var numOfRows=component.get("v.NumOfRecords");
                if(dataRows > numOfRows+1 || dataRows == 1 || dataRows== 0){
                    alert("File Rows between 1 to .");
                    component.set("v.showMain",true);
                    
                } 
                else{
                    var lines = [];
                    var filecontentdata;
                    var content = '<div class="scrollable-container slds-scrollable" style="max-height:18em;">';
                    content += '<table class="table-bordered slds-table">';
                    content += '<thead><tr class="slds-text-title--caps">';
                    for (var i = 0; i < filteredHeaders.length; i++) {
                        content += '<th class="slds-has-flexi-truncate" scope="col" style="background-color:#9D6200; color:white; text-align:center;">' + filteredHeaders[i] + '</th>';
                        console.log('filteredHeaders[i] -- ', filteredHeaders[i]);
                    }
                    content += '</tr></thead><tbody>';
                    for (var i = 0; i < filteredDataRows.length; i++) {
                        var rowData = filteredDataRows[i];
                        content += '<tr>';
                        for (var j = 0; j < filteredHeaders.length; j++) {
                            var columnName = filteredHeaders[j];
                            content += '<td class="slds-cell-wrap" style="background-color:#EBEAEA;">' + (rowData[columnName] !== undefined ? rowData[columnName] : '') + '</td>';
                        }
                        content += '</tr>';
                    }
                    content += '</tbody></table>';
                    content += '</div>';
                    component.set("v.TableContent",content);
                    component.set("v.showMain",false);                   
                }
            }
            reader.readAsText(file);
            
        }
        var reader = new FileReader();
        reader.onloadend = function() {
            
        };
        reader.readAsDataURL(file);
    },
    
    
    /*
    saveRecords: function(component, event) {
        debugger;
        // Display error message initially
        component.set("v.showError", true);
        var toastEvent = $A.get("e.force:showToast");
        // Call Apex method to upload lead records
        var action = component.get("c.uploadLeadRecords");
        var extraData = component.get("v.fileContentData");
        var allTextLines = extraData.split(/\r\n|\n/);
        var headers = allTextLines[0].split(',');
        var fieldsList = headers;
        action.setParams({ fileData: component.get("v.fileContentData"), fields: fieldsList });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            var title, message, type;
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                if(result == 'Success'){
                    alert('Record Saved Successfully...');
                    component.set("v.showError", false);
                    // title = "Success";
                    // message = "Records uploaded successfully.";
                    // type = "success";
                    // Reload the window
                    window.location.reload();

                }else{
                    alert(result);
                    
                    // title = "Error";
                    // message = result;
                    // type = "error";
                    // Reload the window
                //window.location.reload();
                }
                
                // swal({
                //     title: title,
                //     text: message,
                //     icon: type
                // }).then(function() {
                //     // Close the action panel if applicable
                //     if (sforce && sforce.one) {
                //         sforce.one.back(true);
                //     }
                // });
                
            } else if (state === "ERROR") {
                var errors = response.getError();
                var errorMessage = "An unknown error occurred.";
                if (errors && errors[0] && errors[0].message) {
                    errorMessage = errors[0].message;
                }
                // swal({
                //     title: "Error",
                //     text: errorMessage,
                //     icon: "error"
                // });
                // Show error message on UI
                //component.set("v.errorMessage", errorMessage);
            }
        });
        
        // Execute the action
        $A.enqueueAction(action);
    }
    
    */
    
    saveRecords: function(component, event) {
        debugger;
        // Display error message initially
        component.set("v.showError", true);
        var extraData = component.get("v.fileContentData");
        var allTextLines = extraData.split(/\r\n|\n/);
        var headers = allTextLines[0].split(',');
        var fieldsList = headers;
        var records = allTextLines.slice(1); // Exclude headers
        
        // Helper function to process records in batches
        var processBatch = function(startIndex) {
            var batchSize = 50;
            var endIndex = Math.min(startIndex + batchSize, records.length);
            var currentBatch = records.slice(startIndex, endIndex).join('\n');
            var moreRecords = endIndex < records.length;
            
            var action = component.get("c.uploadLeadRecords");
            action.setParams({ 
                fileData: currentBatch, 
                fields: fieldsList,
                
            });
            
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    var result = response.getReturnValue();
                    if (result == 'Success') {
                        alert('Record Saved Successfully...');
                        component.set("v.showError", false);
                        if (moreRecords) {
                            // Process the next batch
                            processBatch(endIndex);
                        } else {
                            // Reload the window when all batches are processed
                            // window.location.reload();
                        }
                    } else {
                        alert(result);
                    }
                } else if (state === "ERROR") {
                    var errors = response.getError();
                    var errorMessage = "An unknown error occurred.";
                    if (errors && errors[0] && errors[0].message) {
                        errorMessage = errors[0].message;
                    }
                    alert(errorMessage);
                }
            });
            
            // Execute the action
            $A.enqueueAction(action);
        };
        
        // Start processing batches from the first record
        processBatch(0);
    }
    
    
    
});