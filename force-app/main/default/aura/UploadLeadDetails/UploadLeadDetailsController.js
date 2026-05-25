({

    doInit: function(component, event, helper) {
        debugger;
        var action = component.get("c.checkProfile");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var isProfileValid = response.getReturnValue();
                // Now you can use the return value as needed
                component.set("v.showUpload", isProfileValid);
            } else if (state === "ERROR") {
                // Handle error
                var errors = response.getError();
                if (errors) {
                    // Handle errors
                } else {
                    console.log("Unknown error");
                }
            }
        });
        $A.enqueueAction(action);
    },
    
    onchange: function(component, event, helper) 
    {
        debugger;
     	event.stopPropagation();
        event.preventDefault();
     	//var files=event.dataTransfer.files;
        //helper.readFile(component,helper,files[0]);
        debugger;
        var fileName = 'No File Selected.';
        if (event.getSource().get("v.files").length > 0) { 
            fileName = event.getSource().get("v.files")[0]; //['name'];
        }
        component.set("v.newfileName", fileName['name']);
        helper.readFile(component,helper,fileName);
        
  	},
    
	/*onDragOver : function(component, event, helper) {
		event.preventDefault();
	},
    
    onDrop : function(component, event, helper) {
		event.stopPropagation();
        event.preventDefault();
        event.dataTransfer.dropEffect='copy'; 
        var files=event.dataTransfer.files;
        helper.readFile(component,helper,files[0]);
	},*/
    
    processFileContent : function(component,event,helper){
        component.find("saveButton").set("v.disabled", true);
        helper.saveRecords(component,event);
    },
    
   cancel: function(component, event, helper) {
        debugger;
        component.set("v.showMain", true);
        component.set("v.showError", false);
        // var dismissActionPanel = $A.get("e.force:closeQuickAction");
        // dismissActionPanel.fire();
        // window.location.reload();

        // Check if the event is defined before firing it
        // var dismissActionPanel = $A.get("e.force:closeQuickAction");
        // if (dismissActionPanel) {
        //     dismissActionPanel.fire();
        // } else {
        //     console.warn("force:closeQuickAction event is not available in this context.");
        // }
    }
})