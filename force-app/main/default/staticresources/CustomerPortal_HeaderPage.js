angular.module('cp_app').controller('cpheader1_ctrl', function($scope,$rootScope){
    debugger;
    $rootScope.userId;
    $rootScope.profilePicId = '';
    $scope.profileId = '';
    $rootScope.con = {};
    $rootScope.conId;
    $rootScope.profileUrl = 'https://snnestates--snnsandbox.sandbox.my.salesforce-sites.com/CustomerPortal/sfc/servlet.shepherd/version/download/';
    $scope.baseUrl = window.origin;

    $scope.getUserDetails = function () {
        debugger;
        CustomerPortalController.getContactDetail($rootScope.userId, function (result, event) {
            debugger;
            if (event.status && result) {
                $rootScope.con = result;
                $rootScope.conId = result.Id;
                if (result.Profile_Pic_Attachment_Id__c != undefined) {
                    $scope.profileId = result.Profile_Pic_Attachment_Id__c;
                    $rootScope.profilePicId = result.Profile_Pic_Attachment_Id__c;
                }
            }
            $scope.$apply();
        })
    }
    $scope.getUserDetails();

    $scope.loadprofilePage = function (profileName) {
        debugger;
        $rootScope.activeTab = profileName;

        debugger;
        var currentUrl = window.location.href.split('#')[0];

        // Get the page name from the mapping
        var pageName = 'CustomerPortal_ProfileDetailsPage';

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