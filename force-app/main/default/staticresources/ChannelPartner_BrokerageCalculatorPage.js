angular.module('channelpartner_app').controller('cppbrokerage_ctrl', function($scope,$rootScope){
    debugger;
console.log($rootScope);
// $rootScope.activeTab = 0;
$scope.propertyValue;
$scope.commissionRate = 0.25;
$scope.noDataSection = true;
$scope.resultSectionboolean = false;

$scope.getBrokerageDetails = function(){
    debugger;
    ChannelPartner_Controller.getBrokerageDetails(function(result, event) {
        debugger;
        if (event.status, result) {
            $scope.brokerageDetails = result;
            $scope.gstValue = $scope.brokerageDetails.GST__c;
            $scope.tdsValue = $scope.brokerageDetails.TDS__c;
            $scope.commissionRatesString = $scope.brokerageDetails.Commission_Rate__c;
            $scope.commissionRatesList = $scope.commissionRatesString.split(',').map(function(rate) {
                return parseFloat(rate);
            });
        }
        $scope.$apply();
    })
}

$scope.getBrokerageDetails();

$scope.calculateBrokerage = function() {
    debugger;
    if ($scope.propertyValue == '' || $scope.commissionRate == '') {
        alert('Please enter valid data');
        return;
    }

    $scope.invoiceValue = parseFloat(((parseFloat($scope.propertyValue) * parseFloat($scope.commissionRate.slice(0, $scope.commissionRate.length-1))) / 100).toFixed(2));
    $scope.gst = parseFloat(($scope.gstValue * $scope.invoiceValue).toFixed(2)); // GST amount
    $scope.tds = ($scope.tdsValue * $scope.invoiceValue).toFixed(2); // TDS amount
    $scope.invoiceWithGST = parseFloat(($scope.invoiceValue + $scope.gst).toFixed(2)); // Invoice Value With GST
    $scope.totalAmount = ($scope.invoiceWithGST - $scope.tds).toFixed(2);
 

    $scope.resultSectionboolean = true;
    $scope.noDataSection = false;
    $scope.$apply();
}

$scope.clearFormAndReset = function() {
    // Hide the result section and show the no data section
    $scope.resultSectionboolean = false;
    $scope.noDataSection = true;
    // Clear the form fields
    $scope.propertyValue = '';
    $scope.commissionRate = '0.25%';
}
});