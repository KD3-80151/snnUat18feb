angular.module('channelpartner_app').controller('cppprojectspage_ctrl', function($scope,$rootScope,){
    debugger;
    // console.log($rootScope);
    // $rootScope.activeTab = 0;
    $scope.detailsPage = false;
    $scope.mainPage = true;
    $scope.showSpinner = false;
    // $scope.filesrec = $sce.trustAsResourceUrl(window.location.origin +'/ChannelPartnerPortal/apex/ChannelPartner_SidebarPage?id=p8ADeXsaum1727086438615#/ChannelPartner_ProjectsPage/servlet/servlet.FileDownload?file=069Im000000QBqgIAG');
    // $scope.getAllProjects = function(){
    //     debugger;
    //     ChannelPartner_Controller.getAllProjects(function(result, event) {
    //         debugger;
    //         if(event.status,result){
    //             $scope.projects = result;
    //         }
    //         $scope.$apply;
    //     })
    // }
    // $scope.getAllProjects();

    // $scope.getImage = function(){
    //     debugger;
    //     ChannelPartner_Controller.getImageContentDocuments(function(result,event){
    //         debugger;
    //         if(event.status,result){
    //             $scope.image = result;
    //         }
    //         $scope.$apply();
    //     })
    // }
    // $scope.getImage();

    $scope.loadProjects = function() {
        debugger;
        ChannelPartner_Controller.getAllProjectsWithImages(function(result, event) {
            debugger;
            if (event.status,result) { // Correctly check the status
                $scope.projects = result.map(project=> {
                    if(project.Sub_Documents__r){
                        project.Sub_Documents__r.map(function (file) {
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
                
                // map(project => { // Use 'result' directly
                //     // Construct URLs for images
                //     project.imageUrls = project.imageIds.map(id => $rootScope.baseUrl + '/servlet/servlet.FileDownload?file=' + id);
                //     console.log('projects==>'+$scope.projects);
                //     console.log(JSON.stringify($scope.projects));
                //     return project; // Return the modified project
                // });
                // console.log('Projects ---> '+JSON.stringify($scope.projects));
                $scope.$apply(); // Ensure the scope is updated
            } else {
                console.error('Error retrieving projects:', event.message); // Log error if needed
            }
        });
    };
    $scope.loadProjects();


    $scope.showProjectDetails = function(value){
        debugger;
        $scope.showSpinner = true;
        $scope.projectDetails = value;
        $scope.showSpinner = false;
        $scope.mainPage = false;
        $scope.detailsPage = true;
    }

    $scope.showMainPage = function(){
        debugger;
        $scope.detailsPage = false;
        $scope.mainPage = true;
    }

    // $scope.getProjectDetails = function(value){
    //     debugger;
    //     ChannelPartner_Controller.getProjectDetails(value, function(result, event) {
    //         debugger;
    //         if(event.status,result){
    //             $scope.projectDetails = result;
    //         }
    //         else{
    //             console.warn('Error: '+event.message);
    //         }
    //         $scope.showSpinner = false;
    //         $scope.mainPage = false;
    //         $scope.detailsPage = true;
    //         $scope.$apply();
    //     })
    // }

    function showProjectDetailspage() {
        document.getElementById('projectmainpageContent').style.display = 'none';
        document.getElementById('projectDetailsContent').style.display = 'block';
    }
    function showProjectsMainPage() {
        document.getElementById('projectDetailsContent').style.display = 'none';
        document.getElementById('projectmainpageContent').style.display = 'block';
    }

    function openShareModal() {
        var shareModal = new bootstrap.Modal(document.getElementById('shareModal'));
        shareModal.show();
    }
});