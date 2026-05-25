({
    doInit : function(component, event, helper) {
        component.set('v.spinner',true);
        helper.getData(component, event, helper);
    },
    
    // Onclick of the number
    onclickNumber: function(component, event, helper) {
        // Get the clicked element
        var clickedElement = event.currentTarget;
        
        // Retrieve the ID from the data-id attribute
        var callId = clickedElement.getAttribute("data-id");
        //alert(callId);
        var index = parseInt(clickedElement.getAttribute("data-index"), 10);
        // Toggle the slide animations
        if(component.get('v.indexCall') === index) {
            // Collapse the element (slide up)
            component.set('v.indexCall', null);
        } else {
            // Expand the element (slide down)
            component.set('v.indexCall', index);
        }
    },
    handleScroll: function(component, event, helper) {
        helper.getData(component, event, helper);
    }
})