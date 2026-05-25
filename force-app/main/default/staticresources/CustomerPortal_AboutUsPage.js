angular.module('cp_app').controller('aboutus_ctrl', function($scope,$rootScope){
    // debugger;
    $scope.getDataOnLoad = function(){
        CustomerPortalController.getCRMDetails($rootScope.userId, function (result, event) {
            debugger;
            if (event.status && result) {
                $scope.crmName = result.crmName;
                $scope.crmEmail = result.crmEmail;
                $scope.crmPhone = result.crmPhone;
            }
            $scope.$apply();
        })
    }
    $scope.getDataOnLoad();
});