({
    getDateRange: function(component, helper, event, from) {
        var selectedValue ='';
        if (from != 'doinit') {
            selectedValue = component.find('select1').get('v.value');
        } 
        var startDate, endDate;
        var today = new Date();
        
        switch (selectedValue) {
            case 'Today':
                startDate = new Date(today.getFullYear(), today.getMonth(), today.getDate());
                endDate = new Date(today.getFullYear(), today.getMonth(), today.getDate(), 23, 59, 59);
                break;
                
            case 'Yesterday':
                startDate = new Date(today.getFullYear(), today.getMonth(), today.getDate() - 1);
                endDate = new Date(today.getFullYear(), today.getMonth(), today.getDate() - 1, 23, 59, 59);
                break;
                
            case 'This_Week':
                var firstDayOfWeek = new Date(today.setDate(today.getDate() - today.getDay()));
                startDate = new Date(firstDayOfWeek.getFullYear(), firstDayOfWeek.getMonth(), firstDayOfWeek.getDate());
                endDate = new Date(firstDayOfWeek.getFullYear(), firstDayOfWeek.getMonth(), firstDayOfWeek.getDate() + 6, 23, 59, 59);
                break;
                
            case 'This_Month':
                startDate = new Date(today.getFullYear(), today.getMonth(), 1);
                endDate = new Date(today.getFullYear(), today.getMonth() + 1, 0, 23, 59, 59); 
                break;
                
            default:
                startDate = null;
                endDate = null;
        }
        
        var formatDate = function(date) {
            if (date) {
                var year = date.getFullYear();
                var month = ('0' + (date.getMonth() + 1)).slice(-2); 
                var day = ('0' + date.getDate()).slice(-2);
                return year + '-' + month + '-' + day;
            }
            return null;
        };
        
        var sdate = formatDate(startDate);
        var edate = formatDate(endDate);
        helper.callCount(component, event, helper, sdate, edate);
    },
   
    callCount : function(component, event, helper,startdate,enddate) {
        component.set("v.spinner",true);
        var action = component.get("c.getCallCount");
        action.setParams({ 
            'startDate' : startdate,
            'endDate' : enddate,
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                component.set("v.userCallCount",result); 
                component.set("v.spinner",false);
            } else{
                
                component.set("v.spinner",false);
            }
        });  
        $A.enqueueAction(action); 
        
    },
})