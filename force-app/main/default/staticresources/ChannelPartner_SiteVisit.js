angular.module('channelpartner_app').controller('cppsitevisit_ctrl', function($scope, $rootScope) {
    debugger;
    console.log($rootScope);

    $scope.oppStage = oppStage;
    $scope.data = [];
    $scope.oppRecords = [];
    $scope.visitRecords =[];
    $scope.totalOppItems;
    $scope.totalBookingItems;
    $scope.totalVisitItems;
    $scope.totalOppPages;
    $scope.totalBookingPages;
    $scope.totalVisitPages;
    $scope.itemsPerPage = 10;
    $scope.currOppPage = 1;
    $scope.currBookingPage = 1;
    $scope.currVisitsPage = 1;
    $scope.pageWindowSize = 4;
    $scope.isFirstScreenVisible = true;
    $scope.visitScreen = false;
    $scope.bookingScreen = false;
    $scope.selectedStatus = 'All';
    $scope.searchKey = '';
    $scope.filteredOppRecords2 = [];
    $scope.oppStatusValue = [];
    $scope.countOfSiteVisit = 0;
    $scope.countOfBookings = 0;

    $scope.statusClassMapping = {
        'New': 'stage-New',
        'Cost Sheet Generated': 'stage-Cost_Sheet_Generated',
        'Cost Sheet Approved': 'stage-Cost_Sheet_Approved',
        'Under Booking Process': 'stage-Under_Booking_Process',
        'Under Approval': 'stage-Under_Approval',
        'Booking Accepted': 'stage-Booking_Accepted',
        'Payment Confirmation': 'stage-Payment_Confirmation',
        'Allotment Letter Generated': 'stage-Allotment_Letter_Generated',
        'Agreement Data Sheet': 'stage-Agreement_Data_Sheet',
        'Agreement Creation': 'stage-Agreement_Creation',
        'Agreement Sent To Customer': 'stage-Agreement_Sent_To_Customer',
        'Agreement Signed': 'stage-Agreement_Signed',
        'Demand Letter': 'stage-Demand_Letter',
        'Pre Handover Check': 'stage-Pre_Handover_Check',
        'Final Handover': 'stage-Final_Handover',
        'Registration': 'stage-Registration',
        'Closed Lost': 'stage-Closed_Lost',
        'Completed': 'stage-Completed',
        'Upcoming': 'stage-Upcoming',
        'Incomplete': 'stage-Incomplete'
    };


    $scope.getVisitandOpportunityRec = function() {
        debugger;

        // const urlParams = new URLSearchParams(window.location.search);
        // const hashCode = urlParams.get('id');

        // const teamHead = localStorage.getItem('hashCode');

        ChannelPartner_Controller.FetchVisitOppRecords($rootScope.teamHead, $rootScope.userId,function(result, event) {
            if (event.status) {
                $scope.data = result;
                $scope.oppRecords = result.oppList.map(function(opp) {
                    // Format the date
                    $scope.countOfBookings  +=  1;
                    opp.CreatedDateFormatted = new Date(opp.CreatedDate).toLocaleDateString('en-GB', {
                        day: '2-digit',
                        month: 'short',
                        year: 'numeric'
                    });
                    return opp;
                });
                $scope.totalBookingItems = $scope.oppRecords.length;
                $scope.filteredOppRecords1 = $scope.oppRecords;
                $scope.totalOppItems = $scope.filteredOppRecords1.length;
                $scope.totalOppPages = Math.ceil($scope.totalOppItems / $scope.itemsPerPage);
                $scope.totalBookingPages = Math.ceil($scope.totalBookingItems / $scope.itemsPerPage);
                $scope.visitRecords = result.visitList;
                $scope.totalVisitItems = $scope.visitRecords.length;
                $scope.totalVisitPages = Math.ceil($scope.totalVisitItems / $scope.itemsPerPage);
                $scope.updatePaginatedRecords();
                for(var i=0;i< $scope.visitRecords.length;i++){
                    $scope.countOfSiteVisit = $scope.countOfSiteVisit + 1 ;
                }
                // console.log('Fetched Records:', result);
                $scope.$apply(); 
                // $scope.getOpportunityStagePicklistValues(); 
            } else {
                
                console.error('Error fetching records:', event.message);
            }
        });
    };
    $scope.getVisitandOpportunityRec();


    // $scope.getOpportunityStagePicklistValues = function(){
    //     debugger;

    //     ChannelPartner_Controller.getOpportunityStagePicklistValues(function(result, event) {
    //         if (event.status) {
    //             $scope.oppStatusValue = ['All'];
    //             $scope.oppStatusValue  = $scope.oppStatusValue.concat(result);
    //             $scope.selectedStatus = $scope.oppStatusValue[0];
    //             console.log('Fetched Records:', $scope.oppStatusValue);
                
    //             $scope.$apply(); 

               
    //         } else {
                
    //             console.error('Error fetching records:', event.message);
    //         }
    //     });



    // }


    // $scope.stageStyles = {
    //     'New': { 'background-color': '#ffcccb', 'border-radius': '50px', 'color': '#ffffff', 'margin-top': '15px', 'margin-bottom': '15px' },
    //     'Cost Sheet Generated': { 'background-color': '#ffeb3b', 'border-radius': '50px', 'color': '#ffffff', 'margin-top': '15px', 'margin-bottom': '15px' },
    //     'Cost Sheet Approved': { 'background-color': '#8bc34a', 'border-radius': '50px', 'color': '#ffffff', 'margin-top': '15px', 'margin-bottom': '15px' },
    //     'Under Booking Process': { 'background-color': '#4caf50', 'border-radius': '50px', 'color': '#ffffff', 'margin-top': '15px', 'margin-bottom': '15px' },
    //     'Under Approval': { 'background-color': '#ff9800', 'border-radius': '50px', 'color': '#ffffff', 'margin-top': '15px', 'margin-bottom': '15px' },
    //     'Booking Accepted': { 'background-color': '#3f51b5', 'border-radius': '50px', 'color': '#ffffff', 'margin-top': '15px', 'margin-bottom': '15px' },
    //     'Payment Confirmation': { 'background-color': '#00bcd4', 'border-radius': '50px', 'color': '#ffffff', 'margin-top': '15px', 'margin-bottom': '15px' },
    //     'Allotment Letter Generated': { 'background-color': '#9c27b0', 'border-radius': '50px', 'color': '#ffffff', 'margin-top': '15px', 'margin-bottom': '15px' },
    //     'Agreement Data Sheet': { 'background-color': '#ff5722', 'border-radius': '50px', 'color': '#ffffff', 'margin-top': '15px', 'margin-bottom': '15px' },
    //     'Agreement Creation': { 'background-color': '#607d8b', 'border-radius': '50px', 'color': '#ffffff', 'margin-top': '15px', 'margin-bottom': '15px' },
    //     'Agreement Sent To Customer': { 'background-color': '#795548', 'border-radius': '50px', 'color': '#ffffff', 'margin-top': '15px', 'margin-bottom': '15px' },
    //     'Agreement Signed': { 'background-color': '#4caf50', 'border-radius': '50px', 'color': '#ffffff', 'margin-top': '15px', 'margin-bottom': '15px' },
    //     'Demand Letter': { 'background-color': '#f44336', 'border-radius': '50px', 'color': '#ffffff', 'margin-top': '15px', 'margin-bottom': '15px' },
    //     'Pre Handover Check': { 'background-color': '#2196f3', 'border-radius': '50px', 'color': '#ffffff', 'margin-top': '15px', 'margin-bottom': '15px' },
    //     'Final Handover': { 'background-color': '#3f51b5', 'border-radius': '50px', 'color': '#ffffff', 'margin-top': '15px', 'margin-bottom': '15px' },
    //     'Registration': { 'background-color': '#673ab7', 'border-radius': '50px', 'color': '#ffffff', 'margin-top': '15px', 'margin-bottom': '15px' },
    //     'Closed Lost': { 'background-color': '#9e9e9e', 'border-radius': '50px', 'color': '#ffffff', 'margin-top': '15px', 'margin-bottom': '15px' }
    // };


    $scope.filterByStatus = function(value) {
        debugger;
        $scope.selectedStatus = value;
        if ($scope.selectedStatus == 'All') {
            $scope.filteredOppRecords1 = $scope.oppRecords;
            $scope.filteredOppRecords2 = [];
            $scope.searchKey = '';
            $scope.totalOppItems = $scope.filteredOppRecords1.length;
            $scope.totalOppPages = Math.ceil($scope.totalOppItems / $scope.itemsPerPage);
            $scope.updatePaginatedRecords();
        }else{
            $scope.filteredOppRecords1 = $scope.oppRecords.filter(opp => opp.StageName === $scope.selectedStatus);
            $scope.filteredOppRecords2 = [];
            $scope.searchKey = '';
            $scope.totalOppItems = $scope.filteredOppRecords1.length;
            $scope.totalOppPages = Math.ceil($scope.totalOppItems / $scope.itemsPerPage);
            $scope.updatePaginatedRecords();
        }
    };

    $scope.filterByName = function(value) {
        debugger;
        $scope.searchKey = value;
        if($scope.searchKey == ''){
            $scope.filteredOppRecords2 = $scope.filteredOppRecords1;
            $scope.totalOppItems = $scope.filteredOppRecords2.length;
            $scope.totalOppPages = Math.ceil($scope.totalOppItems / $scope.itemsPerPage);
            $scope.updatePaginatedRecords();
        }
        else if($scope.searchKey){
            $scope.filteredOppRecords2 = $scope.filteredOppRecords1.filter(record => record.Name.toLowerCase().includes($scope.searchKey.toLowerCase()));
            $scope.totalOppItems = $scope.filteredOppRecords2.length;
            $scope.totalOppPages = Math.ceil($scope.totalOppItems / $scope.itemsPerPage);
            $scope.updatePaginatedRecords();
        }
    };

    $scope.viewSiteVisit = function() {
        $scope.isFirstScreenVisible = false;
        $scope.visitScreen = true;
        $scope.updatePaginatedRecords();
    };

    $scope.viewBookings = function() {
        $scope.isFirstScreenVisible = false;
        $scope.bookingScreen = true;
        $scope.updatePaginatedRecords();
    };

    $scope.goBack = function() {
        $scope.visitScreen = false;
        $scope.bookingScreen = false;
        $scope.isFirstScreenVisible = true;
    };

    $scope.updatePaginatedRecords = function() {
        if($scope.isFirstScreenVisible){
            var start = ($scope.currOppPage - 1) * $scope.itemsPerPage;
            var end = start + $scope.itemsPerPage;
            if($scope.filteredOppRecords2.length != 0 || $scope.searchKey != ''){
                $scope.paginatedOpps = $scope.filteredOppRecords2.slice(start, end);
            }else if($scope.filteredOppRecords1){
                $scope.paginatedOpps = $scope.filteredOppRecords1.slice(start, end);
            }
        }else if($scope.bookingScreen){
            var start = ($scope.currBookingPage - 1) * $scope.itemsPerPage;
            var end = start + $scope.itemsPerPage;
            $scope.paginatedBookings = $scope.oppRecords.slice(start, end);
        }else if($scope.visitScreen){
            var start = ($scope.currVisitsPage - 1) * $scope.itemsPerPage;
            var end = start + $scope.itemsPerPage;
            $scope.paginatedVisits = $scope.visitRecords.slice(start,end);
        }
        $scope.$apply();
    };

    $scope.getPageRange = function() {
        if($scope.isFirstScreenVisible){
            var startPage = Math.max(1, $scope.currOppPage - Math.floor($scope.pageWindowSize / 2));
            var endPage = Math.min($scope.totalOppPages, startPage + $scope.pageWindowSize - 1);
            if (endPage - startPage < $scope.pageWindowSize - 1) {
                startPage = Math.max(1, endPage - $scope.pageWindowSize + 1);
            }
            return Array.from({ length: (endPage - startPage + 1) }, (_, i) => i + startPage);
        }else if($scope.bookingScreen){
            var startPage = Math.max(1, $scope.currBookingPage - Math.floor($scope.pageWindowSize / 2));
            var endPage = Math.min($scope.totalBookingPages, startPage + $scope.pageWindowSize - 1);
            if (endPage - startPage < $scope.pageWindowSize - 1) {
                startPage = Math.max(1, endPage - $scope.pageWindowSize + 1);
            }
            return Array.from({ length: (endPage - startPage + 1) }, (_, i) => i + startPage);
        }else if($scope.visitScreen){
            var startPage = Math.max(1, $scope.currVisitsPage - Math.floor($scope.pageWindowSize / 2));
            var endPage = Math.min($scope.totalVisitPages, startPage + $scope.pageWindowSize - 1);
            if (endPage - startPage < $scope.pageWindowSize - 1) {
                startPage = Math.max(1, endPage - $scope.pageWindowSize + 1);
            }
            return Array.from({ length: (endPage - startPage + 1) }, (_, i) => i + startPage);
        }
    };

    $scope.goToPage = function(page) {
        if($scope.isFirstScreenVisible){
            if (page >= 1 && page <= $scope.totalOppPages) {
                $scope.currOppPage = page;
                $scope.updatePaginatedRecords();
            }
        }else if($scope.bookingScreen){
            if (page >= 1 && page <= $scope.totalBookingPages) {
                $scope.currBookingPage = page;
                $scope.updatePaginatedRecords();
            }
        }else if($scope.visitScreen){
            if (page >= 1 && page <= $scope.totalVisitPages) {
                $scope.currVisitsPage = page;
                $scope.updatePaginatedRecords();
            }
        }
    };

    $scope.prevPages = function() {
        if($scope.isFirstScreenVisible){
            if ($scope.currOppPage > 1) {
                $scope.currOppPage = Math.max(1, $scope.currOppPage - $scope.pageWindowSize);
                $scope.updatePaginatedRecords();
            }
        }else if($scope.bookingScreen){
            if ($scope.currBookingPage > 1) {
                $scope.currBookingPage = Math.max(1, $scope.currBookingPage - $scope.pageWindowSize);
                $scope.updatePaginatedRecords();
            }
        }else if($scope.visitScreen){
            if ($scope.currVisitsPage > 1) {
                $scope.currVisitsPage = Math.max(1, $scope.currVisitsPage - $scope.pageWindowSize);
                $scope.updatePaginatedRecords();
            }
        }
    };

    $scope.nextPages = function() {
        if($scope.isFirstScreenVisible){
            if ($scope.currOppPage < $scope.totalOppPages) {
                $scope.currOppPage = Math.min($scope.totalOppPages, $scope.currOppPage + $scope.pageWindowSize);
                $scope.updatePaginatedRecords();
            }
        }else if($scope.bookingScreen){
            if ($scope.currBookingPage < $scope.totalBookingPages) {
                $scope.currBookingPage = Math.min($scope.totalBookingPages, $scope.currBookingPage + $scope.pageWindowSize);
                $scope.updatePaginatedRecords();
            }
        }else if($scope.visitScreen){
            if ($scope.currVisitsPage < $scope.totalVisitPages) {
                $scope.currVisitsPage = Math.min($scope.totalVisitPages, $scope.currVisitsPage + $scope.pageWindowSize);
                $scope.updatePaginatedRecords();
            }
        }
    };

    $scope.getDisplayedRange = function() {
        if($scope.isFirstScreenVisible){
            var start = ($scope.currOppPage - 1) * $scope.itemsPerPage + 1;
            var end = Math.min($scope.currOppPage * $scope.itemsPerPage, $scope.totalOppItems);
            return `${start} to ${end}`;
        }else if($scope.bookingScreen){
            var start = ($scope.currBookingPage - 1) * $scope.itemsPerPage + 1;
            var end = Math.min($scope.currBookingPage * $scope.itemsPerPage, $scope.totalBookingItems);
            return `${start} to ${end}`;
        }else if($scope.visitScreen){
            var start = ($scope.currVisitsPage - 1) * $scope.itemsPerPage + 1;
            var end = Math.min($scope.currVisitsPage * $scope.itemsPerPage, $scope.totalVisitItems);
            return `${start} to ${end}`;
        }
    };
});
