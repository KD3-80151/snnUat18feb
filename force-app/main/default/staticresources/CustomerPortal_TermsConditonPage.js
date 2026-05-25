angular.module('cp_app').controller('termsconditions_ctrl', function($scope, $sce, $rootScope) {
    debugger;
    console.log($rootScope);
    // $rootScope.activeTab = 0;

    $scope.terms = '';
    $scope.isLoading = true; // Show loading initially
    $scope.trustedTerms = ''; // For trusted HTML

    // Fetch Terms and Conditions from Salesforce using Apex
    $scope.getTerms = function() {
        debugger;
        CustomerPortalController.getTerms(function(result, event) {
            if (event.status) {
                debugger;
                console.log('Apex Result:', result);
                if (result.Description__c) {
                    // console.log("Description==>", result.Description__c);

                    // Decode HTML entities and trust as HTML
                    var decodedHtml = decodeHtmlEntities(result.Description__c);
                    $scope.trustedTerms = $sce.trustAsHtml(decodedHtml); // Sanitize and trust the HTML
                }
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
