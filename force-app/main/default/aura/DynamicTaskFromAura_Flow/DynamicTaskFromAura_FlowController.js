({
    doInit : function(component, event, helper) {
        debugger;
        var compName = '';
        var recordId = component.get("v.recordId");
        var ledRecordId= '';
        var flowName = '';
        var action = component.get("c.getCurrentTaskRecord");
        var oppId = '';
        action.setParams({ 
            "recordId" : component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if(state==='SUCCESS'){
                var responseValue = response.getReturnValue();
                var taskstatus = responseValue.Status;
                ledRecordId = responseValue.WhoId;
                if(responseValue.Task_Master_del__r.Action_Type__c == 'Flow'){
                    flowName = responseValue.Task_Master_del__r.Action_URL__c;
                }else if(responseValue.Task_Master_del__r.Action_Type__c == 'Component'){
                    compName = 'c:'+responseValue.Task_Master_del__r.Action_URL__c;
                    oppId = responseValue.WhatId;
                }
                component.set("v.actionType",responseValue.Task_Master_del__r.Action_Type__c);
                
                if(taskstatus != 'Completed'){
                    if(responseValue.Task_Master_del__r.Action_Type__c == 'Flow'){
                        var inputVariables = [
                            {
                                name : "rv_Task_io",
                                type : "SObject",
                                value : responseValue
                            },
                            {
                                name : "v_trigger_object_name_io",
                                type : "String",
                                value : "Task"
                            }
                        ];
                        
                        if(responseValue.Status=='Open'){
                            
                            //  var flow = component.find("OnOpenStatus");
                            // flow.startFlow(flowName,inputVariables);
                            
                        }else if(responseValue.Status=='Completed'){
                            //  var Tempflow = component.find("OnOpenStatus");
                            //  Tempflow.startFlow(flowName, inputVariables);
                            
                        }
                    }
                    
                    if(responseValue.Task_Master_del__r.Action_Type__c == 'Component' && responseValue.Task_Master_del__r.Action_URL__c != 'bookingForm'){
                        var comp = compName;
                        $A.createComponent(
                            comp,{
                            recordId : recordId,
                            onclose: component.getReference("c.handleClose") // Listen to the close event
                            } ,
                            function(lwcCmp, status, errorMessage) {
                                if (status === "SUCCESS") {
                                    var body = component.get("v.body");
                                    body.push(lwcCmp);
                                    component.set("v.body", body);
                                }
                                else if (status === "INCOMPLETE") {
                                    console.log("No response from server or client is offline.");
                                }
                                    else if (status === "ERROR") {
                                        console.error("Error: " + errorMessage);
                                    }
                            }
                        );
                    }
                    else{
                        console.log('oppId ===> ' + oppId);
                        helper.navigateToLwc(component,oppId);
                    }
                }else if(taskstatus == 'Completed'){
                    component.set("v.statusMessage", "Your Task is already in Completed Stage, You cannot access the Component."); 
                }
            }
            
        });
        
        $A.enqueueAction(action);
    },
    
    handleClose: function (component, event, helper) {
        debugger;
        
        $A.get("e.force:closeQuickAction").fire();
    },
    
    
    //Close button event
    // handleCloseModal : function(component, event, helper) {
    //     debugger;
    //     var dismissActionPanel = $A.get("e.force:closeQuickAction");
    //     dismissActionPanel.fire();  
    // },
    
    // dismissPopUp : function(component){
    //     debugger;
    //     var dismissPanel = $A.get("e.force:closeQuickAction");
    //     dismissPanel.fire();
    // }
    
})