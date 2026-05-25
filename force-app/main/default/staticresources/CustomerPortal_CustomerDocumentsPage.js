angular.module('cp_app').controller('customerdoc_ctrl', function($sce, $scope,$rootScope){
    debugger;
    console.log($rootScope);
    // $rootScope.activeTab = 0;
    $scope.docs = [];
    $scope.mainPage = true;
    $scope.applicantsPage = false;
    $scope.applicants = [];

    $scope.fetchCustomerDocs = function () {
        debugger;
        CustomerPortalController.fetchCustomerDocs($rootScope.userId, function (result, event) {
            debugger;
            if (event.status) {
                // console.log('oppList ---> ' + JSON.stringify(result.oppList));
                // console.log('accIdXDocuments ---> ' + JSON.stringify(result.accIdXDocuments));
                $scope.opportunities = result.oppList;
                $scope.accIdXDocuments = result.accIdXDocuments;
                $scope.$apply();
            } else {
                console.log('Error while fetching customer documents: ' + event.message);
            }
        });
    }
    $scope.fetchCustomerDocs();

    $scope.showMainPage = function () {
        $scope.mainPage = true;
        $scope.applicantsPage = false;
    }

    $scope.showApplicants = function (opp) {
        debugger;
        $scope.applicants = opp.Applicants__r;
        $scope.mainPage = false;
        $scope.applicantsPage = true;
    }

    $scope.getApplicantDocuments = function (accId) {
        debugger;
        $scope.docs = $scope.accIdXDocuments[accId];
        console.log('docs ---> ' + JSON.stringify($scope.docs));
        $scope.$apply();
    }

    $scope.getTrustedUrl = function (url) {
        return $sce.trustAsResourceUrl(url);
    }

    $scope.openPreview = function (fileId) {
        debugger;
        console.log('Opening preview for file ID:', fileId);
        if (fileId) {
            // Set the URL for the file preview
            $scope.filesrec = fileId;
            console.log('File URL for preview:', $scope.filesrec);
            // Set the iframe source to the file URL
            $('#filePreviewFrameCustDocs').attr('src', $scope.getTrustedUrl($scope.filesrec));
            // Show the modal using Bootstrap 5 method
            var myModal = new bootstrap.Modal(document.getElementById('filePreviewModalCustDocs'));
            myModal.show();
        } else {
            console.error('No attachment ID provided');
        }
    }

    $scope.closeModal = function () {
        debugger;
        $scope.filesrec = '';
        $('#filePreviewFrameCustDocs').attr('src', $scope.getTrustedUrl($scope.filesrec));
        $('#filePreviewModalCustDocs').modal('hide');
    }
});