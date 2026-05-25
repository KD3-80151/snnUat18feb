angular.module('cp_app').controller('blogs_ctrl', function($scope, $rootScope) {
    debugger;
    console.log($rootScope);
    // $rootScope.activeTab = 0;

    // $scope.Blogs = [];
    // $scope.selectedBlog = null; 

    
    // $scope.getBlogs = function() {
    //     debugger;
    //     CustomerPortalController.getBlogsWithFiles(function(result, event) {
    //         if (event.status && result) {
    //             debugger;
    //             // $scope.Blogs = result;
    //             $scope.Blogs = result.map(Blog=> {
    //                 if(Blog.Sub_Documents__r){
    //                     Blog.Sub_Documents__r.map(function (file) {
    //                         if (file.File_URL__c) {
    //                             let fileIdMatch = String(file.File_URL__c).match(/\/d\/([a-zA-Z0-9_-]+)/);
    //                             if (fileIdMatch && fileIdMatch[1]) {
    //                                 let fileId = fileIdMatch[1];
    //                                 // console.log("File ID:", fileId);
    //                                 file.File_URL__c = 'https://drive.google.com/thumbnail?id='+fileId+'&sz=w1000';
    //                             } else {
    //                                 console.error("No file ID found in the URL:", file.File_URL__c);
    //                             }
    //                         }else{
    //                             console.error("No file Url in this sub document:", file);
    //                         }
    //                         return file;
    //                     });
    //                 }
    //                 return Blog;
    //             });
    //             $scope.$apply(); 
    //         } else {
    //             alert('Failed to load blogs.');
    //         }
    //     });
    // };

    // // Initialize by fetching the blogs
    // $scope.getBlogs();

    // $scope.viewBlogDetail = function(blog) {
    //     $scope.selectedBlog = blog; 
    // };

   
    // $scope.backToList = function() {
    //     $scope.selectedBlog = null; 
    // };
});
