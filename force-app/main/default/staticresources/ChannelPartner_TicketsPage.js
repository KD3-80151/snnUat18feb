angular.module('channelpartner_app').controller('cppticket_ctrl', function($scope, $rootScope, $timeout) {
    debugger;
    // console.log($rootScope);
    // $rootScope.activeTab = 0;

    // Data model for case
    $scope.caseData = {
        subject: '',
        description: ''
    };
    $scope.isDisabledSubmit = false;
    $scope.typeValue = typeValue;
    $scope.caseData = {"Type":"Problem"};
    $scope.cases = [];
    $scope.pageWindowSize = 4;
    $scope.itemsPerPage = 10;
    $scope.curTicketPage = 1;
    $scope.totalTicketItems;
    $scope.totalTicketPages;

    // Wait for the DOM to be ready before removing disabled attribute
    $timeout(function() {
        document.getElementById('subject').removeAttribute('disabled');
        document.getElementById('issueDescription').removeAttribute('disabled');
    }, 0); // 0 ensures this runs as soon as the DOM is ready

    $scope.fetchCases = function(){
        debugger;
        ChannelPartner_Controller.fetchCases($rootScope.userId,function(result,event){
            debugger;
            if(event.status){
                $scope.cases = result;
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

    $scope.submitCase = function() {
        debugger;
        if(($scope.caseData.SuppliedEmail == undefined || $scope.caseData.SuppliedEmail == '') && ($scope.caseData.SuppliedPhone == undefined || $scope.caseData.SuppliedPhone == '')){
            swal(
                'Info',
                'Please Enter either Email or Phone!',
                'info'
                );
            return;
        }
        $scope.TicketPDF = document.getElementById("ticketPDF").files[0];
        if ($scope.TicketPDF) {
            $scope.fileName = $scope.TicketPDF.name;
            var typeOfFile = $scope.fileName.split(".");
            var lengthOfType = typeOfFile.length;
            var fileExtension = typeOfFile[lengthOfType - 1].toLowerCase();
            if ($scope.TicketPDF.size > '2000000') {
                swal("info", "Document File must be under 2 mb in size. Your file is too large. Please try again.", "info");
                return reject('MSME File too large');
            }
            if (['pdf', 'jpeg', 'jpg', 'png'].indexOf(fileExtension) === -1) {
                swal('Info', 'Please choose a PDF, JPG, JPEG, or PNG MSME file only.', 'info');
                return reject('Invalid MSME file format');
            }
            const reader = new FileReader();
            reader.onload = () => {
                $scope.base64 = reader.result.split(',')[1];
            };
            reader.readAsDataURL($scope.TicketPDF);
        }
        $scope.isDisabledSubmit = true;
        ChannelPartner_Controller.createCase($scope.caseData,$rootScope.userId,function(result,event) {
            debugger;
            if (event.status && result.startsWith('500')) {
                $scope.caseId = result;
                if($scope.TicketPDF && $scope.base64){
                    ChannelPartner_Controller.uploadAttachment($scope.caseId, $scope.fileName, $scope.base64, function(result, event){
                        if(event.status && result == 'Success'){
                            console.log('Attachment uploaded successfully.');
                        }else{
                            console.log('Error while uploading attachment: '+event.message);
                        }
                    });
                }
                $scope.isDisabledSubmit = false;
                $scope.fetchCases();
                $scope.closeModal();
                swal('Success', 'Case created succesfully.', 'success');
            }else{
                $scope.isDisabledSubmit = false;
                swal('Error', 'Failed to create case.', 'error');
            }
        })
        $scope.$apply();
    }

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
    
    $scope.openServiceRequestModal = function(){
        debugger;
        var myModal = new bootstrap.Modal(document.getElementById('serviceRequestModal'));
        myModal.show();
    }

    $scope.closeModal = function(){
        debugger;
        $scope.caseData = {};
        $('#serviceRequestModal').modal('hide');
    }

    // Event listener for enabling/disabling the 'Other Issue' input field
    // document.getElementById('issueSelect').addEventListener('change', function () {
    //     var otherIssueInput = document.getElementById('otherIssue');
    //     if (this.value !== 'Others') {
    //         otherIssueInput.value = ''; // Clear the input field when another option is selected
    //     }
    // });
});