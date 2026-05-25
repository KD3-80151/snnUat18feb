angular.module('channelpartner_app').controller('cppleadPage_ctrl', function($scope,$rootScope){
    debugger;
// console.log($rootScope);
// $rootScope.activeTab = 0;

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
        // $scope.leadList = [];
        // $scope.filteredList1 = [];
        // $scope.filteredList2 = [];
        $scope.filteredList2 = [];
        $scope.leadSubSource = [];
        $scope.searchKey = '';
        $scope.showSpinner = false;
        $scope.showMultiplePopUp1 = false;
        $scope.showMultiplePopUp2 = false;
        $scope.isDisabledAddLead = false;
        $scope.statusValue = statusValue;
        $scope.selectedStatus = 'All';
        $scope.LastName = "";
        $scope.Email = "";
        $scope.Phone = "";
        $scope.leadObj = {"Email":""};
        $scope.totalItems;
        $scope.totalLeadItems;
        $scope.totalVisitItems;
        $scope.totalOppItems;
        $scope.totalPages;
        $scope.totalLeadPages;
        $scope.totalVisitPages;
        $scope.totalOppPages;
        $scope.itemsPerPage = 10;
        $scope.currentPage = 1;
        $scope.currMoreLeadPage = 1;
        $scope.currMoreVisitsPage = 1;
        $scope.currOppPage = 1;
        $scope.pageWindowSize = 4;
        $scope.mainPage = true;
        $scope.convertedLeads = false;
        $scope.viewVisits = false;
        $scope.viewOpps = false;

        $scope.uploadLeads = function() {
            // console.log('selectedStatus===>'+$scope.selectedStatus);
            var myModal = new bootstrap.Modal(document.getElementById('aurapopup1'));
            myModal.show();
            if (!$scope.showMultiplePopUp1) {
                $scope.showSpinner = true;
                $Lightning.use("c:channelPartnerInventoryApp", function() {
                    $Lightning.createComponent("c:UploadLeadDetails", {}, "lightningapp1", function() {
                        console.log("Bulk Lead Upload Component is loaded in Vf page");
                        $scope.showSpinner = false;
                        $scope.$apply();
                    });
                });
                $scope.showMultiplePopUp1 = true;
            }
        }

        $scope.downloadTemplate = function() {
            var myModal = new bootstrap.Modal(document.getElementById('aurapopup2'));
            myModal.show();
            if (!$scope.showMultiplePopUp2) {
                $scope.showSpinner = true;
                $Lightning.use("c:channelPartnerInventoryApp", function() {
                    $Lightning.createComponent("c:DownloadPATemplate", {}, "lightningapp2", function() {
                        debugger;
                        console.log("Download Template Component is loaded in Vf page");
                        $scope.showSpinner = false;
                        $scope.$apply();
                    });
                });
                $scope.showMultiplePopUp2 = true;
            }
        };

        $scope.totalLeads = function(){
            debugger;
            ChannelPartner_Controller.getChannelPartnerData($rootScope.userId,function(result,event){
                debugger;
                if(event.status && result){
                    $scope.projects = result.allProject;
                    for(var i=0; i<result.leads.length; i++){
                        // result[i].CreatedDate = $scope.formatDate(result[i].CreatedDate);
                        result.leads[i].CreatedDate = (result.leads[i].CreatedDate ? new Date(result.leads[i].CreatedDate).toLocaleDateString('en-GB', {
                            day: '2-digit',
                            month: 'short',
                            year: 'numeric'
                        }) : 'Not mentioned');
                    }
                    for(var i=0; i<result.totalLeads.length; i++){
                        // result[i].CreatedDate = $scope.formatDate(result[i].CreatedDate);
                        result.totalLeads[i].CreatedDate = (result.totalLeads[i].CreatedDate ? new Date(result.totalLeads[i].CreatedDate).toLocaleDateString('en-GB', {
                            day: '2-digit',
                            month: 'short',
                            year: 'numeric'
                        }) : 'Not mentioned');
                    }
                    $scope.allLeadList = result.totalLeads;
                    $scope.totalNoOfLeads = result.totalLeads.length;
                    $scope.totalLeadItems = $scope.allLeadList.length;
                    $scope.totalLeadPages = Math.ceil($scope.totalLeadItems / $scope.itemsPerPage);

                    $scope.leadList = result.leads;
                    $scope.filteredList1 = result.leads;
                    $scope.totalItems = $scope.filteredList1.length;
                    $scope.totalPages = Math.ceil($scope.totalItems / $scope.itemsPerPage);
                    $scope.updatePaginatedLeads();


                    $scope.allVisitsList = result.totalVisits;
                    $scope.totalNoOfVisits = result.totalVisits.length;
                    $scope.filteredVisits = result.totalVisits;
                    $scope.totalVisitItems = $scope.allVisitsList.length;
                    $scope.totalVisitPages = Math.ceil($scope.totalVisitItems / $scope.itemsPerPage);

                    debugger;
                    if (result.AllOpps !== undefined && result.AllOpps.length > 0) {
                        $scope.AllOpportunities = result.AllOpps;
                        $scope.totalNoOfOpps = result.AllOpps.length;
                        $scope.totalOppItems = $scope.AllOpportunities.length;
                        $scope.totalOppPages = Math.ceil($scope.totalOppItems / $scope.itemsPerPage);
                        // console.log('All Opportunities: ', $scope.AllOpportunities);
                        // console.log('Total No of Opportunities: ', $scope.totalNoOfOpps);
                    } else {
                        // Handle case when there are no opportunities
                        $scope.AllOpportunities = [];
                        $scope.totalNoOfOpps = 0;
                        $scope.totalOppItems = 0;
                        $scope.totalOppPages = 0;
                        console.log('No opportunities found.');
                    }
                    
                }
                $scope.$apply();
            });
        }
        $scope.totalLeads();

        // $scope.totalVisits = function(){
        //     ChannelPartner_Controller.totalVisits($rootScope.userId,function(result,event){
        //         if(event.status && result){
        //             $scope.allVisitsList = result;
        //             $scope.totalNoOfVisits = result.length;
        //             $scope.filteredVisits = result;
        //             $scope.totalVisitItems = $scope.allVisitsList.length;
        //             $scope.totalVisitPages = Math.ceil($scope.totalVisitItems / $scope.itemsPerPage);
        //         }
        //         $scope.$apply();
        //     });
        // }
        // $scope.totalVisits();

        // $scope.getAllLeadDetails = function(){
        //     ChannelPartner_Controller.getLeads($rootScope.userId,function(result,event){
        //         if(event.status && result){
        //             for(var i=0; i<result.length; i++){
        //                 result[i].CreatedDate = $scope.formatDate(result[i].CreatedDate);
        //             }
        //             $scope.leadList = result;
        //             $scope.filteredList1 = result;
        //             $scope.totalItems = $scope.filteredList1.length;
        //             $scope.totalPages = Math.ceil($scope.totalItems / $scope.itemsPerPage);
        //             $scope.updatePaginatedLeads();
        //         }
        //         $scope.$apply();
        //     })
        // }
        // $scope.getAllLeadDetails();

        $scope.filterByStatus = function(value) {
            debugger;
            $scope.selectedStatus = value;
            if($scope.selectedStatus == 'All'){
                $scope.filteredList1 = $scope.leadList;
                $scope.searchKey = '';
                $scope.totalItems = $scope.filteredList1.length;
                $scope.totalPages = Math.ceil($scope.totalItems / $scope.itemsPerPage);
                $scope.updatePaginatedLeads();
            }
            else if($scope.selectedStatus){
                $scope.filteredList1 = $scope.leadList.filter(record => record.Status === $scope.selectedStatus);
                $scope.searchKey = '';
                $scope.totalItems = $scope.filteredList1.length;
                $scope.totalPages = Math.ceil($scope.totalItems / $scope.itemsPerPage);
                $scope.updatePaginatedLeads();
            }
        }

        $scope.filterByName = function() {
            debugger;
            if($scope.searchKey == ''){
                $scope.filteredList2 = $scope.filteredList1;
                $scope.totalItems = $scope.filteredList2.length;
                $scope.totalPages = Math.ceil($scope.totalItems / $scope.itemsPerPage);
                $scope.updatePaginatedLeads();
            }
            else if($scope.searchKey){
                $scope.filteredList2 = $scope.filteredList1.filter(record => record.LastName.toLowerCase().includes($scope.searchKey.toLowerCase()));
                $scope.totalItems = $scope.filteredList2.length;
                $scope.totalPages = Math.ceil($scope.totalItems / $scope.itemsPerPage);
                $scope.updatePaginatedLeads();
            }
        }

        $scope.filterByVisitId = function() {
            debugger;
            if($scope.searchVisit == ''){
                $scope.filteredVisits = $scope.allVisitsList;
                $scope.totalVisitItems = $scope.filteredVisits.length;
                $scope.totalVisitPages = Math.ceil($scope.totalVisitItems / $scope.itemsPerPage);
                $scope.updatePaginatedLeads();
            }
            else if($scope.searchVisit){
                $scope.filteredVisits = $scope.allVisitsList.filter(record => record.Name.toLowerCase().includes($scope.searchVisit.toLowerCase()));
                $scope.totalVisitItems = $scope.filteredVisits.length;
                $scope.totalVisitPages = Math.ceil($scope.totalVisitItems / $scope.itemsPerPage);
                $scope.updatePaginatedLeads();
            }
        }

        $scope.addLead = function() {
            debugger;
            if($scope.leadObj.LastName == undefined || $scope.leadObj.LastName == ""){
                swal('Info', 'Lead Name is a mandatory field!!', 'info');
                return;
            }
            if($scope.leadObj.Project__c == undefined || $scope.leadObj.Project__c == ""){
                swal('Info', 'Project is a mandatory field!!', 'info');
                return;
            }
            if(($scope.leadObj.Phone == undefined || $scope.leadObj.Phone == "")){
                swal('Info', 'Please provide Phone!!', 'info');
                return;
            }
            else{
                if ($scope.leadObj.Email != undefined && $scope.leadObj.Email != "") {
                    var x = $scope.leadObj.Email;
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
                ChannelPartner_Controller.CreateLeadForChannelPartnerLeadPage($scope.leadObj,$rootScope.userId,function(result,event){
                    if (event.status) {
                        if (result === 'SUCCESS') {
                            $scope.totalLeads();
                            $scope.closeModal();
                            swal('Success', 'Lead created successfully.', 'success');
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

        $scope.getDependentPicklist = function(){
            debugger;
            ChannelPartner_Controller.getFieldDependencies('Lead','LeadSource','Lead_Sub_Source__c',function(result,event){
                debugger;
                if(event.status,result){
                    $scope.sourceXsubSourceMap = result;
                    $scope.leadSources = Object.entries($scope.sourceXsubSourceMap).map(([key, values]) => {
                        return { key: key, values: values };
                    });
                    // console.log('$scope.leadSources ---> '+JSON.stringify($scope.leadSources));
                }else{
                    // console.log('Error while fetching lead source: '+event.message);
                }
                $scope.$apply();
            });
        }
        $scope.getDependentPicklist();

        $scope.updateSubSources = function(){
            debugger;
            $scope.leadSubSource = $scope.sourceXsubSourceMap[$scope.leadObj.LeadSource];
        }

        $scope.updatePaginatedLeads = function() {
            if($scope.mainPage){
                var start = ($scope.currentPage - 1) * $scope.itemsPerPage;
                var end = start + $scope.itemsPerPage;
                if($scope.filteredList2.length != 0 || $scope.searchKey != ''){
                    if(start>$scope.filteredList2.length){
                        start = 0;
                        end = start + $scope.itemsPerPage;
                    }
                    $scope.paginatedLeads = $scope.filteredList2.slice(start, end);
                }else if($scope.filteredList1){
                    $scope.paginatedLeads = $scope.filteredList1.slice(start, end);
                }
            }else if($scope.convertedLeads){
                var start = ($scope.currMoreLeadPage - 1) * $scope.itemsPerPage;
                var end = start + $scope.itemsPerPage;
                $scope.paginatedAllLeads = $scope.allLeadList.slice(start, end);
            }else if($scope.viewVisits){
                var start = ($scope.currMoreVisitsPage - 1) * $scope.itemsPerPage;
                var end = start + $scope.itemsPerPage;
                $scope.paginatedVisits = $scope.filteredVisits.slice(start,end);
            }else if($scope.viewOpps){
                var start = ($scope.currOppPage - 1) * $scope.itemsPerPage;
                var end = start + $scope.itemsPerPage;
                $scope.paginatedOpps = $scope.AllOpportunities.slice(start,end);
            }
            $scope.$apply();
        };

        $scope.getPageRange = function() {
            if($scope.mainPage){
                var startPage = Math.max(1, $scope.currentPage - Math.floor($scope.pageWindowSize / 2));
                var endPage = Math.min($scope.totalPages, startPage + $scope.pageWindowSize - 1);
                if (endPage - startPage < $scope.pageWindowSize - 1) {
                    startPage = Math.max(1, endPage - $scope.pageWindowSize + 1);
                }
                return Array.from({ length: (endPage - startPage + 1) }, (_, i) => i + startPage);
            }else if($scope.convertedLeads){
                var startPage = Math.max(1, $scope.currMoreLeadPage - Math.floor($scope.pageWindowSize / 2));
                var endPage = Math.min($scope.totalLeadPages, startPage + $scope.pageWindowSize - 1);
                if (endPage - startPage < $scope.pageWindowSize - 1) {
                    startPage = Math.max(1, endPage - $scope.pageWindowSize + 1);
                }
                return Array.from({ length: (endPage - startPage + 1) }, (_, i) => i + startPage);
            }else if($scope.viewVisits){
                var startPage = Math.max(1, $scope.currMoreVisitsPage - Math.floor($scope.pageWindowSize / 2));
                var endPage = Math.min($scope.totalVisitPages, startPage + $scope.pageWindowSize - 1);
                if (endPage - startPage < $scope.pageWindowSize - 1) {
                    startPage = Math.max(1, endPage - $scope.pageWindowSize + 1);
                }
                return Array.from({ length: (endPage - startPage + 1) }, (_, i) => i + startPage);
            }else if($scope.viewOpps){
                var startPage = Math.max(1, $scope.currOppPage - Math.floor($scope.pageWindowSize / 2));
                var endPage = Math.min($scope.totalOppPages, startPage + $scope.pageWindowSize - 1);
                if (endPage - startPage < $scope.pageWindowSize - 1) {
                    startPage = Math.max(1, endPage - $scope.pageWindowSize + 1);
                }
                return Array.from({ length: (endPage - startPage + 1) }, (_, i) => i + startPage);
            }
        };

        $scope.goToPage = function(page) {
            if($scope.mainPage){
                if (page >= 1 && page <= $scope.totalPages) {
                    $scope.currentPage = page;
                    $scope.updatePaginatedLeads();
                }
            }else if($scope.convertedLeads){
                if (page >= 1 && page <= $scope.totalLeadPages) {
                    $scope.currMoreLeadPage = page;
                    $scope.updatePaginatedLeads();
                }
            }else if($scope.viewVisits){
                if (page >= 1 && page <= $scope.totalVisitPages) {
                    $scope.currMoreVisitsPage = page;
                    $scope.updatePaginatedLeads();
                }
            }else if($scope.viewOpps){
                if (page >= 1 && page <= $scope.totalOppPages) {
                    $scope.currOppPage = page;
                    $scope.updatePaginatedLeads();
                }
            }
        };

        $scope.prevPages = function() {
            if($scope.mainPage){
                if ($scope.currentPage > 1) {
                    $scope.currentPage = Math.max(1, $scope.currentPage - $scope.pageWindowSize);
                    $scope.updatePaginatedLeads();
                }
            }else if($scope.convertedLeads){
                if ($scope.currMoreLeadPage > 1) {
                    $scope.currMoreLeadPage = Math.max(1, $scope.currMoreLeadPage - $scope.pageWindowSize);
                    $scope.updatePaginatedLeads();
                }
            }else if($scope.viewVisits){
                if ($scope.currMoreVisitsPage > 1) {
                    $scope.currMoreVisitsPage = Math.max(1, $scope.currMoreVisitsPage - $scope.pageWindowSize);
                    $scope.updatePaginatedLeads();
                }
            }else if($scope.viewOpps){
                if ($scope.currOppPage > 1) {
                    $scope.currOppPage = Math.max(1, $scope.currOppPage - $scope.pageWindowSize);
                    $scope.updatePaginatedLeads();
                }
            }
        };

        $scope.nextPages = function() {
            if($scope.mainPage){
                if ($scope.currentPage < $scope.totalPages) {
                    $scope.currentPage = Math.min($scope.totalPages, $scope.currentPage + $scope.pageWindowSize);
                    $scope.updatePaginatedLeads();
                }
            }else if($scope.convertedLeads){
                if ($scope.currMoreLeadPage < $scope.totalLeadPages) {
                    $scope.currMoreLeadPage = Math.min($scope.totalLeadPages, $scope.currMoreLeadPage + $scope.pageWindowSize);
                    $scope.updatePaginatedLeads();
                }
            }else if($scope.viewVisits){
                if ($scope.currMoreVisitsPage < $scope.totalVisitPages) {
                    $scope.currMoreVisitsPage = Math.min($scope.totalVisitPages, $scope.currMoreVisitsPage + $scope.pageWindowSize);
                    $scope.updatePaginatedLeads();
                }
            }else if($scope.viewOpps){
                if ($scope.currOppPage < $scope.totalOppPages) {
                    $scope.currOppPage = Math.min($scope.totalOppPages, $scope.currOppPage + $scope.pageWindowSize);
                    $scope.updatePaginatedLeads();
                }
            }
        };

        $scope.getDisplayedRange = function() {
            // debugger;
            if($scope.mainPage){
                var start = ($scope.currentPage - 1) * $scope.itemsPerPage + 1;
                var end = Math.min($scope.currentPage * $scope.itemsPerPage, $scope.totalItems);
                return `${start} to ${end}`;
            }else if($scope.convertedLeads){
                var start = ($scope.currMoreLeadPage - 1) * $scope.itemsPerPage + 1;
                var end = Math.min($scope.currMoreLeadPage * $scope.itemsPerPage, $scope.totalLeadItems);
                return `${start} to ${end}`;
            }else if($scope.viewVisits){
                var start = ($scope.currMoreVisitsPage - 1) * $scope.itemsPerPage + 1;
                var end = Math.min($scope.currMoreVisitsPage * $scope.itemsPerPage, $scope.totalVisitItems);
                return `${start} to ${end}`;
            }else if($scope.viewOpps){
                var start = ($scope.currOppPage - 1) * $scope.itemsPerPage + 1;
                var end = Math.min($scope.currOppPage * $scope.itemsPerPage, $scope.totalOppItems);
                return `${start} to ${end}`;
            }
        };

        // $scope.formatDate = function(dateString) {
        //     var date = new Date(dateString);
        //     var day = ('0' + date.getDate()).slice(-2);
        //     var month = ('0' + (date.getMonth() + 1)).slice(-2); // Months are zero-indexed
        //     var year = date.getFullYear();
        //     return day + '/' + month + '/' + year;
        // }

        $scope.viewMoreLeads = function(){
            $scope.convertedLeads = true;
            $scope.viewVisits = false;
            $scope.mainPage = false;
            $scope.viewOpps = false;
            $scope.updatePaginatedLeads();
        }

        $scope.viewMoreVisits = function(){
            $scope.convertedLeads = false;
            $scope.viewVisits = true;
            $scope.viewOpps = false;
            $scope.mainPage = false;
            $scope.updatePaginatedLeads();
        }

        $scope.showNoBookingLeads = function(){
            $scope.convertedLeads = false;
            $scope.viewOpps = true;
            $scope.viewVisits = false;
            $scope.mainPage = false;
            $scope.updatePaginatedLeads();
        }

        $scope.showMainPage = function(){
            $scope.convertedLeads = false;
            $scope.viewVisits = false;
            $scope.viewOpps = false;
            $scope.mainPage = true;
        }

        $scope.closeModal = function(){
            debugger;
            $scope.leadObj = {};
            $('#addNewLeadModal').modal('hide');
        }

        /* document.getElementById('bulkUploadBtn').addEventListener('click', function() {
            var myModal = new bootstrap.Modal(document.getElementById('bulkUploadModal'));
            myModal.show();
        });*/

        // Add event listener for Add New Lead button
        document.getElementById('addNewLeadBtn').addEventListener('click', function() {
            var myModal = new bootstrap.Modal(document.getElementById('addNewLeadModal'));
            myModal.show();
        });
		function showAcceptbyTridaLeads() {
            document.getElementById('mainLeadContent').style.display = 'none';
            document.getElementById('leadeAcceptbyContent').style.display = 'block';
        }
        function showNoSiteVisitLeads() {
            document.getElementById('mainLeadContent').style.display = 'none';
            document.getElementById('leaderNoOfVisitContent').style.display = 'block';
        }
        function showNoBookingLeads() {
            document.getElementById('mainLeadContent').style.display = 'none';
            document.getElementById('leaderNoOfBookingContent').style.display = 'block';
        }

        function showMainPage() {
            document.getElementById('leadeAcceptbyContent').style.display = 'block';
            document.getElementById('leaderNoOfVisitContent').style.display = 'none';
            document.getElementById('leaderNoOfBookingContent').style.display = 'none';
            document.getElementById('mainLeadContent').style.display = 'block';
        }
});