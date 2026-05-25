({
	doInit : function(component, event, helper) {
        helper.getDateRange(component,helper,event,'doinit');
    },
    toggleFilterPanel: function(component, event, helper) {
        var isPanelOpen = component.get("v.isFilterPanelOpen");
        component.set("v.isFilterPanelOpen", !isPanelOpen);
    },
    
    applyFilters: function(component, event, helper) {
        
        helper.getDateRange(component,helper,event,'applyFilters');
        component.set("v.isFilterPanelOpen", false);
        component.set("v.buttonvariant", "brand"); 
    },
    
    clearFilters: function(component, event, helper) {
        component.set("v.duration",'');
        component.set("v.isFilterPanelOpen", false);
        component.set("v.buttonvariant", ""); 
        helper.getDateRange(component,helper,event,'applyFilters');
    },
})