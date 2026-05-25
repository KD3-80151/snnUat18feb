({
    
	onClose : function(component, event, helper) {
		helper.closeUtility(component, event, helper);
	},
    doInit: function(component, event, helper){
        helper.getActiveInActiveNo(component, event, helper);
    }
})