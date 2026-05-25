({
	doInit:function(component, event, helper){
        var checked = component.get("v.checked");
        helper.getActiveInActiveNo(component, event, helper,true,true);
        if(!checked){
           // component.set("v.checked",true);
            //helper.getActiveInActiveNo(component, event, helper,true,true);
            
            //helper.getUseronlineStatus(component, event, helper);
        }       
    },
    handleIsActive:function(component, event, helper){
        var checked = component.get("v.checked");
        var brekVal = component.get("v.breakReason");
        if(!checked && (brekVal == '' || brekVal ==  undefined)){
            helper.showToast('error','Select Break Reason');
            component.set("v.checked",!checked);
            
        }else{
            helper.getActiveInActiveNo(component, event, helper,checked,false);
        }
    },
    handleLogout: function(component, event, helper) {
                component.set("v.disableLogin",false);
                var name = component.get("v.username");
                var pswrd = component.get("v.password");
                var reqtype = 'logout';
                if (name !== '' && pswrd != '') {
                    var action = component.get("c.signInSignOut");
                    action.setParams({ 
                        'username' : name,
                        'password' : pswrd,
                        'type' : reqtype,
                        
                    }); 
                    action.setCallback(this, function(response) {
                        var state = response.getState();
                        var result = response.getReturnValue();
                        if (state === "SUCCESS"  && result) {
                            component.set("v.loggedIn",false);
                            component.set("v.disableLogin",false);
                            component.set("v.username",'');
                            component.set("v.password",'');
                            component.set("v.disabletoggle",true);
                            
                            helper.showToast('success','Logged Out Successfully');
                        } else if(state === 'ERROR'){
                            component.set("v.loggedIn",true);
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
                                component.set("v.loggedIn",true);
                                helper.showToast('error','Please check your username and password');
                            }
                    });  
                    $A.enqueueAction(action); 
                    
                    
                } else if(name == ''){
                    helper.showToast('error','Enter username.');
                }else if(pswrd == ''){
                    helper.showToast('error','Enter password.');
                }
                
            },
})