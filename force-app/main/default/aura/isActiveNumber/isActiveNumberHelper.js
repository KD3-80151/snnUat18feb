({
    getActiveInActiveNo : function(component, event, helper,checked,isOpen) {
        component.set('v.spinner',true);
        var checked = component.get("v.checked");
        var brekVal = component.get("v.breakReason");
        var action = component.get("c.offlineonline");
        action.setParams({ 
            'isActive' : checked,
            'isOpen' : isOpen,
            'breakReason' : brekVal
        }); 
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                 alert('brekVal')
                   alert(brekVal)
                var retValue = response.getReturnValue();
                if(retValue){
                    //component.set("v.disabletoggle",!retValue);  
                }
                if(isOpen){
                    component.set("v.checked",retValue);
                }
                if(checked){
                    component.set("v.breakReason",'');
                }

                
                       
               
                component.set('v.spinner',false);
            } else if(state === 'ERROR'){
                component.set('v.spinner',false);
                var errors = response.getError();
                var profile = component.get('v.currentUser').Profile.Name
                if(!isOpen){
                    var isChecked = component.get("v.checked")
                    component.set("v.checked",!isChecked);
                }
                if(!isOpen ){
                    var errorMessage='';
                    if (errors) {
                        
                        if (errors[0] && errors[0].message) {
                            console.log("Error message: " + 
                                        errors[0].message);
                            errorMessage = errors[0].message;
                        }
                    } else {
                        
                        errorMessage = "Unknown error, contact your system admin";
                        console.log("Unknown error");
                    }
                    helper.showToast('error',errorMessage);
                }
            }
        });  
        $A.enqueueAction(action); 
    },
    
    showToast : function(type,message) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "type":type,
            "message":  message
        });
        toastEvent.fire();
    },
})