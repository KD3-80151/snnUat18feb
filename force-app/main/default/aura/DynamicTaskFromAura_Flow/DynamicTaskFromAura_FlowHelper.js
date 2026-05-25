({
    navigateToLwc : function(component, oppId) {
        var navService = component.find("navService");
        var pageReference = {
            type: 'standard__component',
            attributes: {
                componentName: 'c__bookingForm' 
            },
            state: {
                c__recordId: oppId
            }
        };
        navService.navigate(pageReference);
    }
})