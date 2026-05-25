({
    sendDespositionVal : function(component,event,helper){ 
        var callId = component.get("v.callId");
        alert(callId);
        if(callId == "" || callId == undefined){
            helper.showToast('error',"Call Id is empty,Refresh to get call id");
        }else{
            var action1 = component.get("c.callDisposition");
            action1.setParams({ 
                'callId' : callId,
            }); 
            action1.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    var result = response.getReturnValue();
                    if(result){
                        component.set("v.callId","");
                      var event = $A.get("e.c:parentMethodEvent"); 
                        if (event) {
                        event.fire();
                        }
                    }else{
                        helper.showToast('error','Call is Still Live');
                    }
                }else if(state === 'ERROR'){
                    var errors = response.getError();
                    var errorMessage='';
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            console.log("Error message: " +errors[0].message);
                            errorMessage = errors[0].message;
                        }
                    } else {
                        errorMessage = "Unknown error, contact your system admin";
                    }
                    helper.showToast('error',errorMessage);
                }
            });  
            $A.enqueueAction(action1);
        }
    },
    updateCallRecord : function(component,event,helper){ 
        var callid = component.get("v.callId");
        if(callid == "" || callid == undefined){
            helper.showToast('error',"Call Id is empty,Refresh to get call id");
        }else{
            var action = component.get("c.callDetailsUpdate");
            action.setParams({ 'callRecord' : component.get("v.callDetail") }); 
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    component.set("v.callDetail", {
                        'sObjectType': 'Call_details__c',
                        'Id' : '',
                        'Subject__c': '',
                        'Comments__c': '',
                        //'Roll_Number__c' : '',
                        'Call_Disposition__c' : ''
                    });
                   // helper.sendDespositionVal(component,event,helper);
                    component.set("v.recordId","");
                    //component.set("v.callId","");
                    component.set("v.custNo","");
                   /* var event = $A.get("e.c:parentMethodEvent"); 
                        if (event) {
                        event.fire();
                        }*/
                    component.set("v.showMcubeTask",false);
                     
                } else if(state === 'ERROR'){
                    var errors = response.getError();
                    var errorMessage='';
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            console.log("Error message: " +errors[0].message);
                            errorMessage = errors[0].message;
                        }
                    } else {
                        errorMessage = "Unknown error, contact your system admin";
                        console.log("Unknown error");
                    }
                    helper.showToast('error',errorMessage);
                }
            });  
            $A.enqueueAction(action);
            
        }
        
    },
    showToast : function(type,message) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "type":type,
            "message":  message
        });
        toastEvent.fire();
    },
    closeModel: function(component, event, helper) {
        if(component.get("v.fromUtility")){
            
            var parentComponent = component.get("v.parentUtility"); // Get the parent component reference
            var action = parentComponent.get("c.ResetPopup"); // Get the parent method
            // Invoke the action
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    console.log("Parent method executed successfully.");
                } else {
                    console.error("Failed to execute parent method: " + response.getError());
                }
            });
            $A.enqueueAction(action);
            
            
        }
        else if(component.get("v.fromQuickAction")){			
            var parentComponent = component.get("v.parentQuickAction"); // Get the parent component reference
            var action = parentComponent.get("c.closeUtility"); // Get the parent method
            // Invoke the action
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    console.log("Parent method executed successfully.");
                } else {
                    console.error("Failed to execute parent method: " + response.getError());
                }
            });
            $A.enqueueAction(action);
            
        }
        
},
    fetchCallDetails :function(component,event,helper){
        var action = component.get("c.getLastCallDetails");
        action.setParams({ 'callType' : "Outbound Call" });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                //component.set('v.callDetail',result);
                setTimeout(() => {
                    component.set("v.callDetail", {
                    'sObjectType': 'Call_details__c',
                    'Id' : result.Id,
                    'Subject__c': result.Subject__c,
                    'Comments__c': result.Comments__c,
                    'Roll_Number__c' : result.Roll_Number__c,
                    'Call_Disposition__c' : result.Call_Disposition__c,
                });
                           }, 50);
            
            //alert(result.Call_ID__c);
            component.set('v.callId',result.Call_ID__c);
            component.set('v.custNo',result.Customer_Number__c);
            
            component.set('v.showDialer',false);
            component.set("v.showMcubeTask",true);
        }
            else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            } 
        });
        $A.enqueueAction(action);  
    },
    closeUtility : function(component, event, helper) {
        var utilityAPI = component.find("utilitybar");
        var utilityId = utilityAPI.getEnclosingUtilityId();
        utilityAPI.minimizeUtility();
    },
})