({
    doInit : function(component, event, helper) {
       /* const empApi = component.find('dialerApi');
        empApi.setDebugFlag(true);
        const replayId = -1; 
        
        empApi.subscribe('/event/dailerCmp__e', replayId, $A.getCallback(eventReceived => {
            helper.getDetails(component, event, helper, eventReceived.data.payload);        
        }))
            .then(subscription => {
            console.log('Subscribed to channel ', subscription.channel);
        });*/
               
        helper.fetchCountryCode(component, event, helper);
        helper.getUserLoggedInStatus(component, event, helper);
        var eventToSubscribe = helper.getUserRelatedPlatformEvent(component, event, helper) ;
           
            
        },
    addNumber: function (component, event, helper) {
        var phoneNumber = component.get("v.phoneNumber");
        var value = event.currentTarget.dataset.value;
        component.set("v.phoneNumber", phoneNumber + value);
        
        var clickedButton = event.currentTarget;
        $A.util.addClass(clickedButton, "clicked");
        
        setTimeout(function () {
            $A.util.removeClass(clickedButton, "clicked");
        }, 200);
},
    clearNumber: function (component, event, helper) {
        var phoneNumber = component.get("v.phoneNumber");
        
        if (phoneNumber.length > 0) {
            component.set("v.phoneNumber", phoneNumber.slice(0, -1));
        }
},
    createRecord: function (component, event, helper) {
        helper.clearTransferDetails(component, event, helper);
        var result = '';
            helper.makeCall(component, event, helper,result);
        var isOnline = component.get("v.checked");
        var phoneNumber = component.get("v.phoneNumber");
       /* if (phoneNumber !== '' && isOnline) {
            var result = '';
            helper.makeCall(component, event, helper,result);
             var action = component.get("c.createCallDetails");
                    action.setParams({ 
                        
                        'mobileNo' : phoneNumber,
                    }); 
                    action.setCallback(this, function(response) {
                        var state = response.getState();
                        if (state === "SUCCESS") {
                            var result = response.getReturnValue();
                            component.set("v.recordId",result);
                            helper.makeCall(component, event, helper,result);
                            
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
                    if(!isOnline){
                        helper.showToast('error','You are on break');
                    }else{
                        helper.showToast('error','Please enter a number to call.');
                        
                    }
                    //alert('Please enter a number to call.');
                }
                 */
            },
    openDispositionScreen: function (component, message, helper) {
        
        if(message != null && message.getParam("showForm") == true){
           
            component.set("v.showDialer",false);
            component.set("v.showDialer",false);
            component.set("v.hold",true);
            component.set("v.hold",true);
            component.set("v.showMcubeTask",true);
            helper.clearTransferDetails(component, event, helper);
            helper.openUtility(component, event, helper);
            helper.startPolling(component, event, helper);
        }
    },
    handleChildEvent: function(component, event, helper) {
        // Call the closeUtility method when the event is handled
        console.log('Parent method closeUtility invoked from child!');
        helper.closeUtility(component, event, helper); // Call the parent method
},
    togglePasswordVisibility: function(component, event, helper) {
        var isVisible = component.get("v.isPasswordVisible");
        component.set("v.isPasswordVisible", !isVisible);
},
    handleLogin: function(component, event, helper) {
        component.set("v.disableLogin",true);
        var name = component.get("v.username");
        var pswrd = component.get("v.password");
        var reqtype = 'login';
        if (name !== '' && pswrd != '') {
            var action = component.get("c.signInSignOut");
            action.setParams({ 
                'username' : name,
                'password' : pswrd,
                'type' : reqtype,
                
            }); 
            action.setCallback(this, function(response) {
                var state = response.getState();
                var result = JSON.parse(response.getReturnValue());
                if (state === "SUCCESS") {
                    if(result.status == "false"){
                        component.set("v.disableLogin",false);
                        var message = result.error;
                        helper.showToast('error',message);
                    }else{
                        component.set("v.disableLogin",true);
                        component.set("v.loggedIn",true);
                        component.set("v.disabletoggle",false);
                        component.set("v.checked",true);
                        var message = result.msg;
                        helper.showToast('success',message);
                    }
                }/* else if(state === 'ERROR'){
                    component.set("v.loggedIn",false);
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
                    else if(!result){
                        component.set("v.loggedIn",false);
                        helper.showToast('error','Please check your username and password');
                    }*/
                else if(state === 'ERROR'){
                    component.set("v.disableLogin",false);
                    component.set("v.loggedIn",false);
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
            
            
        } else if(name == ''){
            helper.showToast('error','Enter username.');
        }else if(pswrd == ''){
            helper.showToast('error','Enter password.');
        }
        
},
    handleHold: function(component, event, helper) {
        var callid = component.get("v.callId");
        if(callid == "" || callid == undefined){
            helper.showToast('error',"Call Id is Empty,Refresh to get call id");
        }
        else {
            var action = component.get("c.holdUnhold");
            action.setParams({ 
                'callId' : callid,
                'holdtype' : 'hold',
            }); 
            action.setCallback(this, function(response) {
                var state = response.getState();
                //var result = response.getReturnValue();
                var result = JSON.parse(response.getReturnValue());
                if (state === "SUCCESS"  && result) {
                    //var result = JSON.parse(response.getReturnValue());
                    if(result.status == "fail"){
                        var message = result.msg;
                        helper.showToast('error',message);
                    }else{
                        component.set("v.hold",false);
                        helper.showToast('success','Customer is on Hold');
                    }
                    
                } 
                else if(state === 'ERROR'){
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
    handleUnhold: function(component, event, helper) {
        var callid = component.get("v.callId");
        var action = component.get("c.holdUnhold");
        action.setParams({ 
            'callId' : callid,
            'holdtype' : 'unhold',
        }); 
        action.setCallback(this, function(response) {
            var state = response.getState();
            //var result = response.getReturnValue();
            var result = JSON.parse(response.getReturnValue());
            if (state === "SUCCESS"  && result) {
                if(result.status == "fail"){
                    var message = result.msg;
                    helper.showToast('error',message);
                }else{
                    component.set("v.hold",true);
                    helper.showToast('success','Unholded successfully');
                }
            } 
            else if(state === 'ERROR'){
                component.set("v.loggedIn",false);
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
        
        
        
},
    recUpdated1: function(component, event, helper) {
        
        helper.fetchCallDetails(component, event, helper);
        
},
    recUpdated: function(component, event, helper) {
        helper.recUpdated(component, event, helper);
},
    fetchAgents: function (component, event, helper) {
        helper.clearTransferDetails(component, event, helper);
        var action = component.get("c.getAvailableAgentNames");
        action.setParams({ 
            callId: component.get("v.callId"),
        }); 
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var agents = response.getReturnValue();
                component.set("v.agents", agents);
                component.set("v.filteredAgents", agents);
                component.set("v.showSearchAgent", "true");
                
            } else {
                console.error('Error fetching agents:', response.getError());
            }
        });
        $A.enqueueAction(action);
},
    filterAgents: function(component, event, helper) {
        var searchKey = component.get("v.searchKey").toLowerCase();
        
        var agents = component.get("v.agents");
        
        var filtered = agents.filter(function(agent) {
            return agent.label.toLowerCase().includes(searchKey) || 
                agent.value.toLowerCase().includes(searchKey);
        });
        
        component.set("v.filteredAgents", filtered);
        component.set("v.showDropdown", filtered.length > 0);
},
    selectAgent: function(component, event, helper) {
        var selectedLabel = event.target.getAttribute('data-label');
        component.set("v.tranferAgentNo",event.target.getAttribute('data-value'));
        component.set("v.searchKey", selectedLabel);
        component.set("v.showDropdown", false);
},
    transferCall: function(component, event, helper){
        var agentNo = component.get("v.tranferAgentNo");
        if(agentNo == "" || agentNo == undefined){
            helper.showToast("error", "Select Agent");
        }else{
        var action = component.get("c.callTransfer");
        action.setParams({ 
            callId: component.get("v.callId"),
            transferToAgentNo : agentNo,
        }); 
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = JSON.parse(response.getReturnValue());
                if(result.status == "fail"){
                    var message = result.msg;
                    helper.showToast('error',message);
                }else{
                    var message = 'Call Transferred To '+ component.get("v.searchKey");
                    helper.showToast('success',message);
                    helper.clearTransferDetails(component, event, helper);
                    //helper.closeUtility(component, event, helper);
                    
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
        });
        $A.enqueueAction(action);
        }
    },
    openDialer: function(component, event, helper){
        component.set('v.showDialer', true);
        component.set("v.callId","");
    },
})