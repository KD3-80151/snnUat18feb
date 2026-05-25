angular.module('cp_app').controller('projectdoc_ctrl', function($sce, $scope, $rootScope) {
    debugger;
    // console.log($rootScope);
    // $rootScope.activeTab = 0;

    $scope.documents = []; // Change variable name to documents

    $scope.getProjectDocuments = function() {
        debugger;
        CustomerPortalController.getProjectDocuments($rootScope.userId,function(result, event) { 
            debugger;
            console.log('Apex Method Called'); 
            if (event.status) {
                console.log('Documents:', result); 
                $scope.projects = result.projectList;
                $scope.projectXDocuments = result.projectXDocuments;
                $scope.$apply(); 
            } else {
                console.error('Error retrieving documents:', event.message);
            }
        });
    };
    $scope.getProjectDocuments();

    $scope.getApplicantDocuments = function (projectId) {
        debugger;
        $scope.docs = $scope.projectXDocuments[projectId];
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
            $('#filePreviewFrameProjectDocs').attr('src', $scope.getTrustedUrl($scope.filesrec));
            // Show the modal using Bootstrap 5 method
            var myModal = new bootstrap.Modal(document.getElementById('filePreviewModalProjectDocs'));
            myModal.show();
        } else {
            console.error('No attachment ID provided');
        }
    }

    $scope.closeModal = function () {
        debugger;
        $scope.filesrec = '';
        $('#filePreviewFrameProjectDocs').attr('src', $scope.getTrustedUrl($scope.filesrec));
        $('#filePreviewModalProjectDocs').modal('hide');
    }
});



