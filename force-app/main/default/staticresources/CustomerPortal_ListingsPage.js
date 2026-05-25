angular.module('cp_app').controller('listing_ctrl', function($scope,$rootScope){
    debugger;
    console.log($rootScope);
    // $rootScope.activeTab = 0;
    $scope.detailsPage = false;
    $scope.mainPage = false;
    $scope.showSpinner = true;
    $scope.purposeOfBuying = purposeOfBuying;
    $scope.visit = {"Purpose_Of_Buying__c" : "Investment"};
    $scope.hour = 0;
    $scope.minute = 0;
    $scope.today = new Date();

    $scope.fetchAllProjects = function(){
        debugger;
        CustomerPortalController.fetchAllProjects(function(result,event){
            debugger;
            if(event.status){
                $scope.projects = result.map(project=> {
                    project.showContact = false;
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
                $scope.mainPage = true;
                $scope.showSpinner = false;
                $scope.$apply(); // Ensure the scope is updated
                console.log($scope.projects);
            }
        });
    }
    $scope.fetchAllProjects();

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

    $scope.openScheduleVisit = function(value) {
        debugger;
        $scope.projectVisit = value;
        var myModal = new bootstrap.Modal(document.getElementById('scheduleVisitModal'));
        myModal.show();
    }

    $scope.openReferNow = function(value) {
        debugger;
        $scope.projectRefer = value;
        var myModal = new bootstrap.Modal(document.getElementById('inviteModal'));
        myModal.show();
    }

    $scope.openContactSales = function(value) {
        debugger;
        var myModal = new bootstrap.Modal(document.getElementById('contactModal'));
        myModal.show();
    }

    $scope.closeModal = function(){
        debugger;
        $scope.projectVisit = {};
        $scope.projectRefer = {};
        $scope.visit = {"Purpose_Of_Buying__c" : "Investment"};
        $('#scheduleVisitModal').modal('hide');
        $('#contactModal').modal('hide');
        $('#inviteModal').modal('hide');
        $scope.newLead = {};
        reset1();
    }

    $scope.showPhone = function(value){
        debugger;
        value.showContact = !value.showContact;
    }

    $scope.whatsappRedirct = function(value){
        debugger;
        const message = "Hello I would like to know more about the project "+value.Name;
        const url = `https://wa.me/+91${value.Owner.Phone}?text=${encodeURIComponent(message)}`;
        window.open(url, '_blank');
    }

    $scope.saveVisit = function(){
        debugger;
        if($scope.visit.Actual_Visit_Date__c == null || $scope.visit.Actual_Visit_Date__c == undefined || $scope.visit.Actual_Visit_Date__c == ''){
            swal('Info', 'Date of Visit is required!', 'info');
            return;
        }
        if($scope.visit.time == null || $scope.visit.time == undefined || $scope.visit.time == ''){
            swal('Info', 'Time of Visit is required!', 'info');
            return;
        }
        if($scope.visit.Purpose_Of_Buying__c == null || $scope.visit.Purpose_Of_Buying__c == undefined || $scope.visit.Purpose_Of_Buying__c == ''){
            swal('Info', 'Purpose Of Visit is required!', 'info');
            return;
        }
        if ($scope.visit.Actual_Visit_Date__c != null) {
            $scope.today.setHours(0, 0, 0, 0);
            if($scope.visit.Actual_Visit_Date__c < $scope.today){
                swal('Info', 'Date of Visit cannot be in past!', 'info');
                return;
            }
            const actualDate = new Date($scope.visit.Actual_Visit_Date__c).setUTCHours(0, 0, 0, 0);
            const todayDate = new Date($scope.today).setUTCHours(0, 0, 0, 0);
            if(actualDate === todayDate && $scope.visit.time != null){
                const currTimeObject = new Date();
                currTimeObject.setFullYear(1970, 0, 1);
                const currTime = currTimeObject.getTime();
                const selectedTimeObject = new Date($scope.visit.time);
                const selectedTime = selectedTimeObject.getTime();
                if(selectedTime < currTime){
                    swal('Info', 'Time of Visit cannot be in past!', 'info');
                    return;
                }
            }
            const dateString = $scope.visit.Actual_Visit_Date__c;
            // Create a new Date object from the date string
            const dateObject = new Date(dateString);
            // Get the Unix timestamp (milliseconds since the Unix epoch)
            const unixTimestamp = dateObject.getTime();
            // Update the $scope.SLIlist[i].Actual_date_of_dispatch__c with the Unix timestamp
            $scope.visit.Actual_Visit_Date__c = unixTimestamp;
        }
        if ($scope.visit.time != null) {
            const timeString = $scope.visit.time;
            const timeObject = new Date(timeString);
            $scope.hour = timeObject.getHours();
            $scope.minute = timeObject.getMinutes();
            delete ($scope.visit['time']);
        }
        $scope.visit.Project__c = $scope.projectVisit.Id;
        $scope.visit.Status__c = 'Upcoming';
        CustomerPortalController.saveVisit($rootScope.userId, $scope.visit, $scope.hour, $scope.minute, function(result,event){
            debugger;
            if(event.status && result.Id){
                $scope.visit = result;
                showSuccess1();
            }else{
                swal('Error', 'Failed to save visit.', 'error');
                console.log('Error while saving visit: '+event.result);
            }
            $scope.$apply();
        })
    }

    $scope.sendInvite = function() {
        debugger;
        if($scope.newLead.LastName == undefined || $scope.newLead.LastName == ""){
            swal('Info', 'Lead Name is a mandatory field!!', 'info');
            return;
        }
        $scope.newLead.Project__c = $scope.projectRefer.Id;
        if(($scope.newLead.Phone == undefined || $scope.newLead.Phone == "") && ($scope.newLead.Email == undefined || $scope.newLead.Email == "")){
            swal('Info', 'Please provide Phone or Email!!', 'info');
            return;
        }
        else{
            if ($scope.newLead.Email != undefined && $scope.newLead.Email != "") {
                var x = $scope.newLead.Email;
                var atpos = x.indexOf("@");
                var dotpos = x.lastIndexOf(".");
                if (atpos < 1 || dotpos < atpos + 2 || dotpos + 2 >= x.length) {
                    swal(
                        'Info',
                        'Email Format Invalid!',
                        'info'
                    );
                    return;
                }
            }
            $scope.isDisabledAddLead = true;
            CustomerPortalController.CreateReferralLead($scope.newLead,$rootScope.userId,function(result,event){
                if (event.status) {
                    if (result === 'SUCCESS') {
                        // $scope.totalLeads();
                        $scope.closeModal();
                        swal('Success', 'Referral added successfully.', 'success');
                        $scope.isDisabledAddLead = false;
                    } else {
                        swal('Error', result, 'error');
                        $scope.isDisabledAddLead = false;
                    }
                } else {
                    swal('Error', event.message, 'error');
                    $scope.isDisabledAddLead = false;
                }
            });
            $scope.$apply();
        }
    }
});
function showSuccess1() {
    document.getElementById('visitForm').style.display = 'none';
    document.getElementById('successMessage').style.display = 'block';
}
function reset1() {
    document.getElementById('visitForm').style.display = 'block';
    document.getElementById('successMessage').style.display = 'none';
}