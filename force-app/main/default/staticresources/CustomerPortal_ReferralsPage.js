angular.module('cp_app').controller('referral_ctrl', function($scope, $rootScope) {
    debugger;
    $scope.statusClassMapping = {
        'New': 'stage-New',
        'Assigned': 'stage-Assigned',
        'Contacted': 'stage-Contacted',
        'Qualified': 'stage-Qualified',
        'SV Planned': 'stage-SV_Planned',
        'Re-Enquiry': 'stage-Re-Enquiry',
        'Dropped': 'stage-Dropped',
        'Converted': 'stage-Converted'
    };
    // console.log($rootScope);
    // $rootScope.activeTab = 0;
    $scope.mobileNumber = '';
    $scope.isDisabled = false;
    $scope.newLead = {};
    $scope.isDisabledAddLead = false;

    $scope.getAllData = function() {
        debugger;
        CustomerPortalController.getAllData($rootScope.userId, function(result,event){
            if (event.status) {
                $scope.projects = result.projectList;
                $scope.referredLeads = result.leadList;
            } else {
                swal('Error', event.message, 'error');
            }
            $scope.$apply();
        });
    }
    $scope.getAllData();

    $scope.sendInvite = function() {
        debugger;
        if($scope.newLead.LastName == undefined || $scope.newLead.LastName == ""){
            swal('Info', 'Lead Name is a mandatory field!!', 'info');
            return;
        }
        if($scope.newLead.Project__c == undefined || $scope.newLead.Project__c == ""){
            swal('Info', 'Project is a mandatory field!!', 'info');
            return;
        }
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
            $scope.$apply();x
        }
    }

    $scope.openReferral = function() {
         var myModal = new bootstrap.Modal(document.getElementById('inviteModal_r'));
         myModal.show();
        //$('#inviteModal').show();
    }

    $scope.closeModal = function(){
        debugger;
        $scope.newLead = {};
        $('#inviteModal_r').modal('hide');
    }

    $scope.toggleReadMore = function() {
        debugger;
        var dots = document.getElementById("dots");
        var moreText = document.getElementById("more");
        var btnText = document.getElementById("readMoreBtn");
    
        if (dots.style.display === "none") {
          dots.style.display = "inline";
          btnText.innerHTML = "Read More";
          moreText.style.display = "none";
        } else {
          dots.style.display = "none";
          btnText.innerHTML = "Read Less";
          moreText.style.display = "inline";
        }
      }    
});