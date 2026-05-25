({
    getData : function(component, event, helper) {
        var action=component.get("c.getCallDetails");
        action.setParams({
            offset: component.get("v.offset"),
            limits: component.get("v.limit")
        });
        action.setCallback(this,function(response){ 
            if(response.getState() == "SUCCESS"){
                var retValue = response.getReturnValue();
                const existingHistory = component.get("v.callHistory");
                component.set("v.callHistory", existingHistory.concat(retValue.callDetail));
                //component.set('v.callHistory',retValue.callDetail);
                component.set('v.totalRecords',retValue.callCount)
                // Set showLoadMore based on the new offset and total records
                const len = component.get("v.callHistory").length;
                component.set("v.showLoadMore", len < retValue.callCount);
                component.set('v.spinner',false);
            }
            else {
                component.set('v.spinner',false);
                var errors = response.getError();
                console.log(errors);
                console.error("Error fetching records: " + errors);
            }
        });
        $A.enqueueAction(action); 
    }
})