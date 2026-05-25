angular.module('cp_app').controller('projectupdt_ctrl', function($scope,$rootScope,$sce){
    debugger;
    $scope.mainPage = true;
    $scope.updatesPage = false;
    $scope.projectUpdates = [];
    // console.log($rootScope);
    // $rootScope.activeTab = 0;

    $scope.showProjectUpdates = function(value){
        debugger;
        $scope.mainPage = false;
        $scope.projectUpdates = $scope.projectIdXProjectUpdates[value];
        for(var i=0; i<$scope.projectUpdates.length; i++){
            if ($scope.projectUpdates[i].Sub_Documents__r) {
                const subDocuments = $scope.projectUpdates[i].Sub_Documents__r;
                const validImageExtensions = ['.jpg', '.png', '.jpeg'];
                const validVideoExtensions = ['.mp4', '.mov', '.avi', '.mkv'];
                for (const document of subDocuments) {
                    document.CreatedDate = (document.CreatedDate ? new Date(document.CreatedDate).toLocaleDateString('en-GB', {
                        day: '2-digit',
                        month: 'short',
                        year: 'numeric'
                    }) : 'Not mentioned');
                    const fileName = document.Name || '';
                    const fileUrl = document.File_URL__c || '';
                    // Extract file ID using regex
                    const fileIdMatch = fileUrl.match(/\/d\/([a-zA-Z0-9_-]+)/);
                    if (fileIdMatch && fileIdMatch[1]) {
                        const fileId = fileIdMatch[1];
                        // Check for valid image extensions
                        if (validImageExtensions.some(ext => fileName.endsWith(ext))) {
                            document.imageUrl = `https://drive.google.com/thumbnail?id=${fileId}&sz=w1000`;
                            //document.imageUrl = `https://drive.google.com/file/d/${fileId}/preview`;
                        }
                        // Check for video extension
                        if (validVideoExtensions.some(ext => fileName.endsWith(ext))) {
                            document.videoUrl = $scope.trustVideoUrl(document.File_URL__c);
                        }
                    }
                }
            }
        }
        console.log('projectUpdates ---> '+JSON.stringify($scope.projectUpdates));
        $scope.updatesPage = true;   
    }

    $scope.showMainPage = function(){
        $scope.updatesPage = false;
        $scope.projectUpdates = [];
        $scope.mainPage = true;
    }

    $scope.fetchProjectsWithUpdates = function(){
        debugger;
        CustomerPortalController.fetchProjectsWithUpdates(function(result,event){
            debugger;
            if(event.status,result){
                $scope.projectIdXProjectUpdates = result.projectIdXProjectUpdates;
                $scope.projectList = result.projectList.map(project=> {
                    if(project.Sub_Documents__r){
                        project.Sub_Documents__r.map(function (file) {
                            if(file.CreatedDate) {
                                file.CreatedDate = (file.CreatedDate ? new Date(file.CreatedDate).toLocaleDateString('en-GB', {
                                    day: '2-digit',
                                    month: 'short',
                                    year: 'numeric'
                                }) : 'Not mentioned');
                            }
                            if (file.File_URL__c) {
                                let fileIdMatch = String(file.File_URL__c).match(/\/d\/([a-zA-Z0-9_-]+)/);
                                if (fileIdMatch && fileIdMatch[1]) {
                                    let fileId = fileIdMatch[1];
                                    // console.log("File ID:", fileId);
                                    file.File_URL__c = 'https://drive.google.com/thumbnail?id='+fileId+'&sz=w1000';
                                } else {
                                    console.error("No file ID found in the URL:", file.File_URL__c);
                                }
                            }else{
                                console.error("No file Url in this sub document:", file);
                            }
                            return file;
                        });
                    }
                    return project;
                });
            }
            $scope.$apply();
        });
    }
    $scope.fetchProjectsWithUpdates();

    $scope.trustVideoUrl = function(url) {
        return $sce.trustAsResourceUrl(url);
    };

    $scope.openVideo = function(fileId){
        debugger;
        console.log('Opening preview for file ID:', fileId);
        if (fileId) {
            // Set the URL for the file preview
            $scope.filesrec = fileId;
            console.log('File URL for preview:', $scope.filesrec);
            // Set the iframe source to the file URL
            $('#videoPreviewFrame').attr('src', $scope.trustVideoUrl($scope.filesrec));
            // Show the modal using Bootstrap 5 method
            var myModal = new bootstrap.Modal(document.getElementById('videoModal'));
            myModal.show();
        } else {
            console.error('No attachment ID provided');
        }
    }

    $scope.openImage = function(fileId){
        debugger;
        console.log('Opening preview for file ID:', fileId);
        if (fileId) {
            // Set the URL for the file preview
            $scope.filesrec = fileId;
            console.log('File URL for preview:', $scope.filesrec);
            // Set the iframe source to the file URL
            //$('#imagePreviewFrame').attr('src', $scope.trustVideoUrl($scope.filesrec));
            $('#imagePreviewFrame').attr('src', $scope.filesrec);

            // Show the modal using Bootstrap 5 method
            var myModal = new bootstrap.Modal(document.getElementById('imageModal'));
            myModal.show();
        } else {
            console.error('No attachment ID provided');
        }
    }
});