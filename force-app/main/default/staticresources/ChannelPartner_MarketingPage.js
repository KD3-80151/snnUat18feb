angular.module('channelpartner_app').controller('cppmarketing_ctrl', function($scope,$sce,$rootScope){
    debugger;
    // console.log($rootScope);
    // $rootScope.activeTab = 0;

    $scope.getAllMarketingRecords = function(){
        debugger;
        ChannelPartner_Controller.getAllMarketingRecords(function(result, event) {
            debugger;
            if(event.status) {
                $scope.allMarketingRecords = result;
                
                // console.log('Marketing record ---> '+JSON.stringify($scope.allMarketingRecords));
            }
            $scope.$apply();
        });
    }
    $scope.getAllMarketingRecords();

    $scope.getTrustedUrl = function(url) {
        return $sce.trustAsResourceUrl(url);
    }

    $scope.openPreview = function(fileId) {
        debugger;
        // console.log('Opening preview for file ID:', fileId);
        
        if (fileId) {
            // Set the URL for the file preview
            $scope.filesrec = fileId;
            // console.log('File URL for preview:', $scope.filesrec);
            
            // Set the iframe source to the file URL
            $('#filePreviewFrame').attr('src', $scope.getTrustedUrl($scope.filesrec));
            
            // Show the modal using Bootstrap
            var myModal = new bootstrap.Modal(document.getElementById('filePreviewModal'));
            myModal.show();
        } else {
            console.error('No attachment ID provided');
        }
    }

    $scope.closeModal = function() {
        debugger;
        $scope.filesrec = '';
        $('#filePreviewFrame').attr('src', $scope.getTrustedUrl($scope.filesrec));
        $('#filePreviewModal').modal('hide');
    }
});