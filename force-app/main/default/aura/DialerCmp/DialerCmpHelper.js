({
    getUserRelatedPlatformEvent : function(cmp, event, helper){
        var action = cmp.get("c.getPlatformUserGroup");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var eventToSubscribe  = response.getReturnValue();
                const empApi = cmp.find('empApi');
                empApi.setDebugFlag(true);
                const replayId = -1; 
                let eventReceivedFlag = false;
                
                if(eventToSubscribe!=null && eventToSubscribe!='error'){
                    empApi.subscribe('/event/'+eventToSubscribe, replayId, $A.getCallback(eventReceived => {
                        helper.getDetails(cmp, event, helper, eventReceived.data.payload); 
                        eventReceivedFlag = true;
                    })).then(subscription => {
                        console.log('Subscribed to channel ', subscription.channel);
                    });
                        /*if(!eventReceivedFlag){
                        helper.fetchCallDetails(cmp, event, helper);
                    }*/
                    }
                    
                    }
                        else if (state === "ERROR") {
                        var errors = response.getError();
                        if (errors) {
                        if (errors[0] && errors[0].message) {
                        console.log("Error message: " + 
                        errors[0].message);
                    }
                    } else {
                        console.log("Unknown error");
                    }
                        
                        return 'error';
                    }
                    });
                        
                        $A.enqueueAction(action);
                    
                    },
    getDetails : function(component, event, helper, payload) {
        if(payload.UserId__c != null && payload.UserId__c == $A.get( "$SObjectType.CurrentUser.Id" )){
            //component.set('v.displayCall', true); 
            if(payload.RecordId__c != undefined && payload.RecordId__c != null ){
                if(payload.CallId__c == undefined || payload.CallId__c == null){
                component.set('v.recordId', payload.RecordId__c);
                //component.set('v.callId', payload.CallId__c); 
                component.set('v.showDialer', false);
                component.set('v.hold', true);
                helper.clearTransferDetails(component, event, helper);
                helper.recUpdated(component, event, helper);
                helper.openUtility(component, event, helper);
                helper.navigateToRecord(component, event, helper);
            }
            }
            //helper.openUtility(component, event, helper);
        }
    },
    openUtility : function(component, event, helper) {
        var utilityAPI = component.find("utilitybar");
        var utilityId = utilityAPI.getEnclosingUtilityId();
        utilityAPI.openUtility(utilityId);
    },
    fetchCountryCode : function(component, event, helper) {
        var action = component.get("c.getCountryCodes");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.countryCodes", response.getReturnValue());
            } else {
                console.error("Failed to fetch country codes: " + response.getError());
            }
        });
        $A.enqueueAction(action);
    },
    getUserLoggedInStatus : function(component, event, helper) {
        var action = component.get("c.userStatus");
        action.setCallback(this, function(response) {
            var state = response.getState();
            var result = response.getReturnValue();
            if (state === "SUCCESS") {
                component.set("v.username",result.u.Mcube_username__c);
                component.set("v.password",result.u.Mcube_password__c);
                if(result.u.Mcube_Logged_In__c && result.mcubeLogin){
                    component.set("v.loggedIn",true);
                    component.set("v.disabletoggle",false);
                    component.set("v.disableLogin",true);

                }else{
                    component.set("v.loggedIn",false);
                    component.set("v.disabletoggle",true);
                    component.set("v.disableLogin",false);
                }
                
                   component.set("v.checked",result.u.mcube_Availability__c);
               
            } else {
                console.error("Failed to fetch User Status: " + response.getError());
            }
        });
        $A.enqueueAction(action);
    },
    makeCall: function (component, event, helper,recordId) {
        var phoneNumber = component.get("v.phoneNumber");
        var selectedCountryCode = component.get("v.selectedCountryCode");
        if (phoneNumber !== '') {
            var action = component.get("c.clickToCall");
            action.setParams({ 
                'countryCode' : selectedCountryCode,
                'mobileNo' : phoneNumber,
                'recId' : recordId,
                
            }); 
            action.setCallback(this, function(response) {
                var state = response.getState();
                 var result = JSON.parse(response.getReturnValue());
                if (state === "SUCCESS") {
                    if(result.status == false){
                        var message = result.msg;
                        helper.showToast('error',message);
                    }else{
                    var mes = 'Calling '+ phoneNumber;
                    component.set("v.showDialer",false);
                    component.set("v.hold",true);
                    helper.startPolling(component, event, helper);
                    helper.showToast('info',mes);
                    component.set("v.phoneNumber",'');
                    }
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
                //helper.closeQuick(component, event);
            });  
            $A.enqueueAction(action); 
            
            
        } else {
            helper.showToast('error','Please enter a number to call.');
        }
    },
    closeUtility : function(component, event, helper) {
        helper.clearTransferDetails(component, event, helper);
        var utilityAPI = component.find("utilitybar");
        var utilityId = utilityAPI.getEnclosingUtilityId();
        utilityAPI.minimizeUtility();
        component.set('v.showDialer', true);
        
    },
    recUpdated: function(component, event, helper) {
                var childComp = component.find("childComp");
                if (childComp) {
                    childComp.fetchCallDetails();
                }
            },
    fetchCallDetails :function(component,event,helper){
        var action = component.get("c.getLastCallDetails");
        //action.setParams({ 'recId' : component.get("v.recordId") });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                //component.set("v.callDetails",result);
               if(result.Invoke_Mcube__c){
                    component.set('v.showDialer',true);
                   helper.showToast('info','No recent call available to update');
                }else{
                    component.set('v.showDialer',false);
                    this.recUpdated(component, event, helper);
                }
                 if(result.Hold_Status__c == 'Hold' || result.Hold_Status__c == '' ||result.Hold_Status__c == null){
                    component.set('v.hold',true);
                }else{
                    component.set('v.hold',false);
                }
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        if(errors[0].message == 'List has no rows for assignment to SObject'){
                            helper.showToast('info','No recent call available to update');
                        }
                        console.log("Error message: " + errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            } 
        });
        $A.enqueueAction(action);  
    },
    navigateToRecord : function(component, event, helper) {
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            "recordId": component.get('v.recordId'),
            "slideDevName": "detail"
        });
        navEvt.fire();  
        
    },
    clearTransferDetails : function(component, event, helper) {
      component.set("v.tranferAgentNo",'');
                    component.set("v.searchKey", '');
                    component.set("v.agents", []);
                    component.set("v.filteredAgents", []);
                    component.set("v.showSearchAgent", "false");
    },
    showToast : function(type,message) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "type":type,
            "message":  message
        });
        toastEvent.fire();
    },
    startPolling: function(component,event,helper) {
        //const helper = this;
        component.set("v.isPolling", true);
        const intervalId = window.setInterval(
            $A.getCallback(function () {
                helper.recUpdated(component, event, helper);
            }),
            5000 // Poll every 5 seconds
        );
        
        component.set("v.pollingIntervalId", intervalId);
        
        // Automatically stop polling after 5
        window.setTimeout(
            $A.getCallback(function () {
                if (component.get("v.isPolling")) {
                    helper.stopPolling(component, event, helper);
                    component.set("v.isPolling", false); // Update UI state
                }
            }),
            5000 // for 1 minute keep 60000 timeout
        );
    },
    
    stopPolling: function(component,event,helper) {
        
        const intervalId = component.get("v.pollingIntervalId");
        if (intervalId) {
            window.clearInterval(intervalId);
            component.set("v.pollingIntervalId", null);
            
        }
        component.set("v.isPolling", false);
    },
})