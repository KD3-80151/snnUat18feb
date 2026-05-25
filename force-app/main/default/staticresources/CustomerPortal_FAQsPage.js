angular.module('cp_app').controller('faq_ctrl', function($scope, $rootScope) {
    debugger;
    console.log($rootScope);
    // $rootScope.activeTab = 0;
    
    // Data model to hold the FAQ entries
    $scope.faqs = [];
    $scope.isLoading = true; // Show loading state
    
    // Fetch FAQs from Salesforce using Apex
    $scope.getLocationList = function() {
        debugger;
        CustomerPortalController.faqs(function(result, event) {
            if (event.status) {
                debugger;
                console.log('Apex Result:', result);
                if (result) {
                    $scope.faqs = result; // Assign result to $scope.faqs
                    console.log("FAQs List:", $scope.faqs);
                } else {
                    console.log('No FAQs returned from Apex.');
                }
            } else {
                console.error('Failed to retrieve FAQs: ', event.message);
                alert('An error occurred while fetching FAQs.');
            }
            $scope.isLoading = false; // Hide loading state
            $scope.$apply(); // Ensure UI is updated
        });
    }

    // Initialize by fetching the FAQs
    $scope.getLocationList();
    
});
