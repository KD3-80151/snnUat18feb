angular.module('channelpartner_app').controller('cppheader1_ctrl', function($scope,$rootScope){
    debugger;
        // console.log($rootScope);
        // $rootScope.activeTab = 0;
        debugger;
        $rootScope.userId;
        $scope.baseUrl = window.origin; 
        $rootScope.profilePicId = '';
        $rootScope.acc = {};
        $rootScope.accId;
        $rootScope.profileUrl = 'https://snnestates--snnsandbox.sandbox.my.salesforce-sites.com/ChannelPartnerPortal/sfc/servlet.shepherd/version/download/';

        $scope.getUserDetails = function(){
            debugger;
            ChannelPartner_Controller.getUserDetails($rootScope.userId,function(result,event){
                debugger;
                if(event.status && result){
                    // if(result.Profile_Pic_Attachment_Id__c != undefined){
                        $rootScope.acc = result;
                        $rootScope.accId = result.Id;
                        if(result.Profile_Pic_Attachment_Id__c != undefined){
                            $rootScope.profilePicId = result.Profile_Pic_Attachment_Id__c;
                        }
                    // }
                }
                $scope.$apply();
            })
        }
        $scope.getUserDetails();

        $scope.loadprofilePage = function(profileName){
            debugger;
            $rootScope.activeTab = profileName;

            debugger;
            var currentUrl = window.location.href.split('#')[0];
        
            // Get the page name from the mapping
            var pageName = 'ChannelPartner_ProfileDetailsPage';
        
            // Construct the new URL
            if (pageName) {
              debugger;
                var baseUrl = currentUrl.split('#')[0]; // Removes any existing hash part
                var newUrl = `${baseUrl}#/${pageName}`;
                window.location.replace(newUrl);
                
            } else {
                console.error('Invalid sectionId:', sectionId);
            }
                // Close the sidebar after selecting a menu item on mobile
                if (window.innerWidth <= 768) {
                    $scope.isSidebarOpen = false;
                }
        }
});