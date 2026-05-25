angular.module('cp_app').controller('sitevisit_ctrl', function($scope,$rootScope){
    debugger;
    $scope.upcomingSiteVisit = [];
    $scope.completedSiteVisit = [];
    $scope.incompleteSiteVisit = [];
    $scope.detailsPage = false;
    $scope.mainPage = true;
    $scope.visitToFollow = {"Purpose_Of_Buying__c" : "Investment"};
    $scope.visitToCancel = {};
    $scope.visitToReschedule = {};
    $scope.visitToEnd = {};
    $scope.selectedVisit = {};
    $scope.hour = 0;
    $scope.minute = 0;
    $scope.today = new Date();

    $scope.getVisitRecords = function() {
        debugger;
        CustomerPortalController.FetchVisitOnCon($rootScope.userId, function(result, event) {
            debugger;
            $scope.visitList = result.visitList;
            $scope.projectXSubDocs = result.projectXSubDocs;
            $scope.projectXamenities = result.projectXamenities;
            $scope.visitWithProject = $scope.visitList.map(visit => {
                visit.Actual_Visit_Date__c = (visit.Actual_Visit_Date__c ? new Date(visit.Actual_Visit_Date__c).toLocaleDateString('en-GB', {
                    day: '2-digit',
                    month: 'short',
                    year: 'numeric'
                }) : 'Not mentioned');
                visit.showContact = false;
                if(visit.Project__c){
                    visit.Project__r.Amenities__r = $scope.projectXamenities[visit.Project__c];
                    visit.Project__r.Sub_Documents__r = $scope.projectXSubDocs[visit.Project__c].map(function (file) {
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
                return visit;
            });
            $scope.upcomingSiteVisit = $scope.visitWithProject.filter(visit => visit.Status__c === 'Upcoming');
            $scope.completedSiteVisit = $scope.visitWithProject.filter(visit => visit.Status__c === 'SV Completed');
            $scope.incompleteSiteVisit = $scope.visitWithProject.filter(visit => visit.Status__c === 'Incomplete');
        });
    };
    $scope.getVisitRecords();

    $scope.showDetails = function(value){
        debugger;
        $scope.selectedVisit = value;
        $scope.detailsPage = true;
        $scope.mainPage = false;
    }

    $scope.showMainPage = function(){
        debugger;
        $scope.detailsPage = false;
        $scope.mainPage = true;
    }

    $scope.showPhone = function(value){
        debugger;
        value.showContact = !value.showContact;
    }

    $scope.openFollowUp = function(value){
        $scope.selectedVisit = value;
        $('#followUpVisitModal').modal('show');
    }

    $scope.openCancelVisit = function(){
        $scope.visitToCancel.Id = $scope.selectedVisit.Id;
        $('#cancelVisitModal').modal('show');
    }

    $scope.openRescheduleVisit = function(value){
        $scope.selectedVisit = value;
        $scope.visitToReschedule.Id = $scope.selectedVisit.Id;
        $('#RescheduleVisitModal').modal('show');
    }

    $scope.openEndVisit = function(value){
        $scope.selectedVisit = value;
        $scope.visitToEnd.Id = $scope.selectedVisit.Id;
        $('#EndVisitModal').modal('show');
    }

    $scope.closeModal = function(){
        debugger;
        $scope.purposeOfBuying = purposeOfBuying;
        $scope.visitToReschedule = {};
        $scope.visitToCancel = {};
        $scope.visitToFollow = {"Purpose_Of_Buying__c" : "Investment"};
        $scope.visitToEnd = {};
        $('#followUpVisitModal').modal('hide');
        $('#cancelVisitModal').modal('hide');
        $('#RescheduleVisitModal').modal('hide');
        $('#EndVisitModal').modal('hide');
        reset();
    }

    $scope.cancelVisit = function(){
        debugger;
        $scope.visitToCancel.Status__c = 'Cancelled';
        CustomerPortalController.updateVisit($scope.visitToCancel, function(result,event){
            debugger;
            if(event.status && result == 'Success'){
                showSuccess();
                $scope.getVisitRecords();
            }else{
                swal('Error', 'Failed to cancel visit.', 'error');
                console.log('Error while cancelling visit: '+event.result);
            }
            $scope.$apply();
        })
    }

    $scope.rescheduleVisit = function(){
        debugger;
        if($scope.visitToReschedule.Actual_Visit_Date__c == null || $scope.visitToReschedule.Actual_Visit_Date__c == undefined || $scope.visitToReschedule.Actual_Visit_Date__c == ''){
            swal('Info', 'Date of Visit is required!', 'info');
            return;
        }
        if($scope.visitToReschedule.time == null || $scope.visitToReschedule.time == undefined || $scope.visitToReschedule.time == ''){
            swal('Info', 'Time of Visit is required!', 'info');
            return;
        }
        if($scope.visitToReschedule.Reason_of_Reschedule__c == null || $scope.visitToReschedule.Reason_of_Reschedule__c == undefined || $scope.visitToReschedule.Reason_of_Reschedule__c == ''){
            swal('Info', 'Reason for Resceduling of Visit is required!', 'info');
            return;
        }
        if ($scope.visitToReschedule.Actual_Visit_Date__c != null) {
            $scope.today.setHours(0, 0, 0, 0);
            if($scope.visitToReschedule.Actual_Visit_Date__c < $scope.today){
                swal('Info', 'Date of Visit cannot be in past!', 'info');
                return;
            }
            var actualDate = new Date($scope.visitToReschedule.Actual_Visit_Date__c).setUTCHours(0, 0, 0, 0);
            var todayDate = new Date($scope.today).setUTCHours(0, 0, 0, 0);
            if(actualDate === todayDate && $scope.visitToReschedule.time != null){
                var currTimeObject = new Date();
                currTimeObject.setFullYear(1970, 0, 1);
                var currTime = currTimeObject.getTime();
                var selectedTimeObject = new Date($scope.visitToReschedule.time);
                var selectedTime = selectedTimeObject.getTime();
                if(selectedTime < currTime){
                    swal('Info', 'Time of Visit cannot be in past!', 'info');
                    return;
                }
            }
            var dateString = $scope.visitToReschedule.Actual_Visit_Date__c;
            // Create a new Date object from the date string
            var dateObject = new Date(dateString);
            // Get the Unix timestamp (milliseconds since the Unix epoch)
            var unixTimestamp = dateObject.getTime();
            // Update the $scope.SLIlist[i].Actual_date_of_dispatch__c with the Unix timestamp
            $scope.visitToReschedule.Actual_Visit_Date__c = unixTimestamp;
        }
        if ($scope.visitToReschedule.time != null) {
            var timeString = $scope.visitToReschedule.time;
            var timeObject = new Date(timeString);
            $scope.hour = timeObject.getHours();
            $scope.minute = timeObject.getMinutes();
            delete ($scope.visitToReschedule['time']);
        }
        $scope.visitToReschedule.Status__c = 'Upcoming';
        CustomerPortalController.rescheduleVisit($scope.visitToReschedule, $scope.hour, $scope.minute, function(result,event){
            debugger;
            if(event.status && result.Id){
                $scope.visitToReschedule = result;
                showSuccess();
                $scope.getVisitRecords();
            }else{
                swal('Error', 'Failed to reschedule visit.', 'error');
                console.log('Error while rescheduling visit: '+event.result);
            }
            $scope.$apply();
        })
    }

    $scope.followUpVisit = function(){
        debugger;
        if($scope.visitToFollow.Actual_Visit_Date__c == null || $scope.visitToFollow.Actual_Visit_Date__c == undefined || $scope.visitToFollow.Actual_Visit_Date__c == ''){
            swal('Info', 'Date of Visit is required!', 'info');
            return;
        }
        if($scope.visitToFollow.time == null || $scope.visitToFollow.time == undefined || $scope.visitToFollow.time == ''){
            swal('Info', 'Time of Visit is required!', 'info');
            return;
        }
        if($scope.visitToFollow.Purpose_Of_Buying__c == null || $scope.visitToFollow.Purpose_Of_Buying__c == undefined || $scope.visitToFollow.Purpose_Of_Buying__c == ''){
            swal('Info', 'Purpose Of Visit is required!', 'info');
            return;
        }
        if ($scope.visitToFollow.Actual_Visit_Date__c != null) {
            $scope.today.setHours(0, 0, 0, 0);
            if($scope.visitToFollow.Actual_Visit_Date__c < $scope.today){
                swal('Info', 'Date of Visit cannot be in past!', 'info');
                return;
            }
            var actualDate = new Date($scope.visitToFollow.Actual_Visit_Date__c).setUTCHours(0, 0, 0, 0);
            var todayDate = new Date($scope.today).setUTCHours(0, 0, 0, 0);
            if(actualDate === todayDate && $scope.visitToFollow.time != null){
                var currTimeObject = new Date();
                currTimeObject.setFullYear(1970, 0, 1);
                var currTime = currTimeObject.getTime();
                var selectedTimeObject = new Date($scope.visit.time);
                var selectedTime = selectedTimeObject.getTime();
                if(selectedTime < currTime){
                    swal('Info', 'Time of Visit cannot be in past!', 'info');
                    return;
                }
            }
            var dateString = $scope.visitToFollow.Actual_Visit_Date__c;
            // Create a new Date object from the date string
            var dateObject = new Date(dateString);
            // Get the Unix timestamp (milliseconds since the Unix epoch)
            var unixTimestamp = dateObject.getTime();
            // Update the $scope.SLIlist[i].Actual_date_of_dispatch__c with the Unix timestamp
            $scope.visitToFollow.Actual_Visit_Date__c = unixTimestamp;
        }
        if ($scope.visitToFollow.time != null) {
            var timeString = $scope.visitToFollow.time;
            var timeObject = new Date(timeString);
            $scope.hour = timeObject.getHours();
            $scope.minute = timeObject.getMinutes();
            delete ($scope.visitToFollow['time']);
        }
        $scope.visitToFollow.Project__c = $scope.selectedVisit.Project__c;
        $scope.visitToFollow.Follow_Up_of_Visit__c = $scope.selectedVisit.Id;
        $scope.visitToFollow.Status__c = 'Upcoming';
        CustomerPortalController.saveVisit($rootScope.userId, $scope.visitToFollow, $scope.hour, $scope.minute, function(result,event){
            debugger;
            if(event.status && result.Id){
                $scope.visitToFollow = result;
                showSuccess();
                $scope.getVisitRecords();
            }else{
                swal('Error', 'Failed to save visit.', 'error');
                console.log('Error while saving visit: '+event.result);
            }
            $scope.$apply();
        })
    }

    $scope.endVisit = function(){
        debugger;
        $scope.visitToEnd.Status__c = 'Ended';
        CustomerPortalController.updateVisit($scope.visitToEnd, function(result,event){
            debugger;
            if(event.status && result == 'Success'){
                showSuccess();
                $scope.getVisitRecords();
            }else{
                swal('Error', 'Failed to end visit.', 'error');
                console.log('Error while ending visit: '+event.result);
            }
            $scope.$apply();
        })
    }
});
function showSuccess() {
    debugger;
    document.getElementById('visitForm1').style.display = 'none';
    document.getElementById('visitForm2').style.display = 'none';
    document.getElementById('visitForm3').style.display = 'none';
    document.getElementById('visitForm4').style.display = 'none';
    document.getElementById('successMessage1').style.display = 'block';
    document.getElementById('successMessage2').style.display = 'block';
    document.getElementById('successMessage3').style.display = 'block';
    document.getElementById('successMessage4').style.display = 'block';
}
function reset() {
    debugger;
    document.getElementById('visitForm1').style.display = 'block';
    document.getElementById('visitForm2').style.display = 'block';
    document.getElementById('visitForm3').style.display = 'block';
    document.getElementById('visitForm4').style.display = 'block';
    document.getElementById('successMessage1').style.display = 'none';
    document.getElementById('successMessage2').style.display = 'none';
    document.getElementById('successMessage3').style.display = 'none';
    document.getElementById('successMessage4').style.display = 'none';
}