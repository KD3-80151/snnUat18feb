({
 
	closeUtility : function(component, event, helper) {
        var utilityAPI = component.find("utilitybar");
        var utilityId = utilityAPI.getEnclosingUtilityId();
        utilityAPI.minimizeUtility();
    },
    getActiveInActiveNo : function(component, event, helper) {
        //component.set('v.spinner',true);
        var action = component.get("c.offlineonline");
        action.setParams({ 
            'isActive' : null,
            'isOpen' : true,
            'breakReason' : null
        }); 
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var retValue = response.getReturnValue();
                component.set("v.checked",retValue);
                
            } else if(state === 'ERROR'){
                //component.set('v.spinner',false);
                var errors = response.getError();
            }
            //helper.closeQuick(component, event);
        });  
        $A.enqueueAction(action); 
    },
})