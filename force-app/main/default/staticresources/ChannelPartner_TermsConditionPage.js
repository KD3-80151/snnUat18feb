angular.module('channelpartner_app').controller('cpptermsconditions_ctrl', function($scope,$sce,$rootScope){
    debugger;
// console.log($rootScope);
// $rootScope.activeTab = 0;

$scope.terms = '';
$scope.isLoading = true; // Show loading initially

$scope.getTerms = function() {
    debugger;
    ChannelPartner_Controller.getTerms(function(result, event) {
        if (event.status) {
            debugger;
            // console.log('Apex Result:', result);
            if (result.Description__c) {
                // console.log("Description==>", result.Description__c);
                var term = decodeHtmlEntities(result.Description__c);
                $scope.terms = $sce.trustAsHtml(term);// Sanitize and trust the HTML
            }
        }
        else {
            console.log('Error in fetching Terms and Conditions ---> '+event.message);
        }
        $scope.isLoading = false; // Hide loading
        $scope.$apply(); // Update scope
    });
};

// Initialize by fetching the terms
$scope.getTerms();

    function decodeHtmlEntities(html) {
        var txt = document.createElement('textarea');
        txt.innerHTML = html;
        return txt.value;
    }
});