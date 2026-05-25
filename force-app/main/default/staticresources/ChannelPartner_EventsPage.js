angular.module('channelpartner_app').controller('cppevents_ctrl', function ($scope, $sce, $rootScope) {
    debugger;
    // console.log($rootScope);
    // $rootScope.activeTab = 0;
    $scope.baseurl = window.origin;

    $scope.eventList = function() {
        debugger;
        ChannelPartner_Controller.getEventDetailsForSite(function (result, event) {
            if (event.status && result) {
                $scope.listOfEvents = result;
            }
            if ($scope.listOfEvents != undefined) {
                for (var i = 0; i < $scope.listOfEvents.length; i++) {
                    if ($scope.listOfEvents[i].Event_Date_Time__c != null) {
                        $scope.listOfEvents[i].Event_Date_Time__c = new Date($scope.listOfEvents[i].Event_Date_Time__c);
                    }
                    if ($scope.listOfEvents[i].Sub_Documents__r) {
                        const subDocuments = $scope.listOfEvents[i].Sub_Documents__r;
                        const validImageExtensions = ['.jpg', '.png', '.jpeg'];
                        const pdfExtension = '.pdf';
                        for (const document of subDocuments) {
                            const fileName = document.Name || '';
                            const fileUrl = document.File_URL__c || '';
                            // Extract file ID using regex
                            const fileIdMatch = fileUrl.match(/\/d\/([a-zA-Z0-9_-]+)/);
                            if (fileIdMatch && fileIdMatch[1]) {
                                const fileId = fileIdMatch[1];
                                // Check for valid image extensions
                                if (validImageExtensions.some(ext => fileName.endsWith(ext))) {
                                    $scope.listOfEvents[i].imageUrl = `https://drive.google.com/thumbnail?id=${fileId}&sz=w1000`;
                                }
                                // Check for PDF extension
                                if (fileName.endsWith(pdfExtension)) {
                                    $scope.listOfEvents[i].pdfUrl = fileUrl;
                                }
                            }
                        }
                    }
                }
                console.log('Event ---> '+JSON.stringify($scope.listOfEvents));
            }
            $scope.$apply();
        })
    }
    $scope.eventList();

    // $scope.viewEvent = function (fileId) {
    //     if (fileId) {
    //         var fileDownloadUrl = $scope.baseurl + '/servlet/servlet.FileDownload?file=' + fileId;
    //         window.open(fileDownloadUrl, '_blank');
    //     } else {
    //         alert('No file associated with this event.');
    //     }
    // };

    $scope.getTrustedUrl = function(url) {
        return $sce.trustAsResourceUrl(url);
    }

    $scope.openPreview = function(fileId) {
        debugger;
        console.log('Opening preview for file ID:', fileId);
        
        if (fileId) {
            // Set the URL for the file preview
            $scope.filesrec = fileId;
            console.log('File URL for preview:', $scope.filesrec);
            
            // Set the iframe source to the file URL
            $('#filePreviewFrameEvents').attr('src', $scope.getTrustedUrl($scope.filesrec));
            
            // Show the modal using Bootstrap 5 method
            var myModal = new bootstrap.Modal(document.getElementById('filePreviewModalEvents'));
            myModal.show();
        } else {
            console.error('No attachment ID provided');
        }
    }    

    $scope.closeModal = function() {
        debugger;
        $scope.filesrec = '';
        $('#filePreviewFrameEvents').attr('src', $scope.getTrustedUrl($scope.filesrec));
        $('#filePreviewModalEvents').modal('hide');
    }
});