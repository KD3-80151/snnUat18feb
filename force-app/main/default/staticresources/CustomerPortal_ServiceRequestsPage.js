angular.module('cp_app').controller('servicereq_ctrl', function($scope, $rootScope, $timeout) {
    debugger;
    console.log($rootScope);
    // $rootScope.activeTab = 0;

    // Data model for case
    $scope.caseData = {"Type":"Problem"};
    $scope.typeValue = typeValue;
    $scope.pageWindowSize = 4;
    $scope.itemsPerPage = 10;
    $scope.curTicketPage = 1;
    $scope.totalTicketItems;
    $scope.totalTicketPages;
    $scope.cases = [];

    // Wait for the DOM to be ready before removing disabled attribute
    $timeout(function() {
        document.getElementById('subject').removeAttribute('disabled');
        document.getElementById('issueDescription').removeAttribute('disabled');
    }, 0); // 0 ensures this runs as soon as the DOM is ready

    // Function to submit the case data
    $scope.submitCase = function() {
        debugger;
        if (($scope.caseData.Subject == undefined || $scope.caseData.Subject == '') && ($scope.caseData.Description == undefined || $scope.caseData.Description == '')) {
            swal(
                'Info',
                'Please provide any one of subject or description!',
                'info'
            );
            return;
        }
        console.log('Case Data:', $scope.caseData);
        CustomerPortalController.createNewCase(
            $rootScope.userId,
            $scope.caseData,
            function(result, event) {
                if (event.status && result === 'Success') {
                    $scope.fetchCases();
                    $scope.closeModal();
                    swal('Success', 'Case created succesfully.', 'success');
                    $scope.$apply(); // Apply scope changes
                } else {
                    swal('Error', 'Failed to create case.', 'error');
                    console.log('Failed to create case: ' + event.message);
                }
            }
        );
    };

    $scope.fetchCases = function(){
        debugger;
        CustomerPortalController.fetchCases($rootScope.userId,function(result,event){
            debugger;
            if(event.status){
                $scope.cases = $rootScope.replaceAMPinArr(result);
                $scope.totalTicketItems = $scope.cases.length;
                $scope.totalTicketPages = Math.ceil($scope.totalTicketItems / $scope.itemsPerPage);
                $scope.updatePaginatedRecords();
            }else{
                console.log('Error while fetching cases: '+event.message);
            }
            $scope.$apply();
        });
    }
    $scope.fetchCases();

    $scope.getDisplayedRange = function() {
        // debugger;
        var start = ($scope.curTicketPage - 1) * $scope.itemsPerPage + 1;
        var end = Math.min($scope.curTicketPage * $scope.itemsPerPage, $scope.totalTicketItems);
        return `${start} to ${end}`;
    }

    $scope.prevPages = function() {
        if ($scope.curTicketPage > 1) {
            $scope.curTicketPage = Math.max(1, $scope.curTicketPage - $scope.pageWindowSize);
            $scope.updatePaginatedRecords();
        }
    }

    $scope.nextPages = function() {
        if ($scope.curTicketPage < $scope.totalTicketPages) {
            $scope.curTicketPage = Math.min($scope.totalTicketPages, $scope.curTicketPage + $scope.pageWindowSize);
            $scope.updatePaginatedRecords();
        }
    }

    $scope.goToPage = function(page) {
        if (page >= 1 && page <= $scope.totalTicketPages) {
            $scope.curTicketPage = page;
            $scope.updatePaginatedRecords();
        }
    }

    $scope.updatePaginatedRecords = function() {
        var start = ($scope.curTicketPage - 1) * $scope.itemsPerPage;
        var end = start + $scope.itemsPerPage;
        $scope.paginatedTickets = $scope.cases.slice(start, end);
        $scope.$apply();
    }

    $scope.getPageRange = function() {
        var startPage = Math.max(1, $scope.curTicketPage - Math.floor($scope.pageWindowSize / 2));
        var endPage = Math.min($scope.totalTicketPages, startPage + $scope.pageWindowSize - 1);
        if (endPage - startPage < $scope.pageWindowSize - 1) {
            startPage = Math.max(1, endPage - $scope.pageWindowSize + 1);
        }
        return Array.from({ length: (endPage - startPage + 1) }, (_, i) => i + startPage);
    }

    $scope.openPreview = function() {
        var myModal = new bootstrap.Modal(document.getElementById('serviceRequestModal'));
        myModal.show();
    }

    $scope.closeModal = function(){
        debugger;
        $scope.caseData = {"Type":"Problem"};
        $('#serviceRequestModal').modal('hide');
    }
});
