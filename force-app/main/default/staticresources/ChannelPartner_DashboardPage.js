angular.module('channelpartner_app').controller('cppdashboard_ctrl', function ($scope, $rootScope) {
    debugger;
    // console.log($rootScope);
    // $rootScope.activeTab = 0;
    $scope.statusClassMapping = {
        'Pending': 'stage-Pending',
        'Sent': 'stage-Sent',
        'Approved': 'stage-Approved',
        'Rejected': 'stage-Rejected'
    };
    // $rootScope.activeTab = 0;
    $scope.mainPage = true;
    $scope.allInvoicesPage = false;
    $scope.invoiceTotalAmountPage = false;
    $scope.invoiceAmountApprovedPage = false;
    $scope.itemsPerPage = 10;
    $scope.currentAllInvoicePage = 1;
    $scope.currentAllInvoicePage2 = 1;
    $scope.currentApprovedInvoicePage = 1;
    // $scope.currentAllInvoicePage = 1;
    $scope.pageWindowSize = 4;
    $scope.totalAllInvoiceItems = 0;
    $scope.totalAllInvoicePages;
    $scope.totalAllInvoiceItems2 = 0;
    $scope.totalApprovedInvoiceItems = 0;
    $scope.totalAllInvoicePages2;
    $scope.totalApprovedInvoicePages;
    $scope.totalApprovedAmount = 0;
    $scope.totalAmount = 0;
    $scope.visitRank = 0;
    $scope.unitRank = 0;
    $scope.amountRank = 0;
    $scope.formattedTotalApprovedAmount = 'Loading...';
    $scope.formattedTotalAmount = 'Loading...';
    $scope.allInvoices;
    $scope.approvedInvoices;
    $scope.invoiceRec = {};

    $scope.formatCurrency = function(amount) {
        debugger;
        return new Intl.NumberFormat('en-IN', {
            style: 'currency',
            currency: 'INR', // Replace with your currency code (e.g., 'INR' for Indian Rupee)
            minimumFractionDigits: 0 // Change to 2 if you need decimals
        }).format(amount);
    };

    $scope.init = function () {
        if ($rootScope.userId == localStorage.getItem('hashCode')) {
            $rootScope.activeTab = 'dashboard'; // Ensure the dashboard is active by default
        } else {
		    window.location.href = window.location.href.includes('/apex') ? '/apex' : '/ChannelPartnerPortal';
        }
    };
    $scope.init();

    function showPaymentPlanPage() {
        document.getElementById('bookingPageContent').style.display = 'none';
        document.getElementById('paymentPlanContent').style.display = 'block';
    }
    function showTotalEarningPage() {
        document.getElementById('bookingPageContent').style.display = 'none';
        document.getElementById('totalEarningContent').style.display = 'block';
    }
    function showInvoiceApprovedPage() {
        document.getElementById('bookingPageContent').style.display = 'none';
        document.getElementById('invoiceApprovedContent').style.display = 'block';
    }
    function showLeadredboardPage() {
        document.getElementById('bookingPageContent').style.display = 'none';
        document.getElementById('leaderBoardContent').style.display = 'block';
    }

    function showBookingPage() {
        document.getElementById('paymentPlanContent').style.display = 'none';
        document.getElementById('totalEarningContent').style.display = 'none';
        document.getElementById('invoiceApprovedContent').style.display = 'none';
        document.getElementById('leaderBoardContent').style.display = 'none';
        document.getElementById('bookingPageContent').style.display = 'block';
    }

    $scope.getDataOnLoad = function(){
        debugger;
        ChannelPartner_Controller.getInvoices($rootScope.teamHead,$rootScope.userId,function(result,event){
            debugger;
            if(event.status){
                $scope.cpDataMap = result.cpDataMap;
                for(var i=0; i<result.AllInvoices.length; i++){
                    $scope.totalAmount = $scope.totalAmount + (result.AllInvoices[i].Invoice_value_without_GST__c == undefined ? 0 : result.AllInvoices[i].Invoice_value_without_GST__c);
                    result.AllInvoices[i].CreatedDate = (result.AllInvoices[i].CreatedDate ? new Date(result.AllInvoices[i].CreatedDate).toLocaleDateString('en-GB', {
                        day: '2-digit',
                        month: 'short',
                        year: 'numeric'
                    }) : 'Not mentioned');
                    // result.AllInvoices[i].CreatedDate = $scope.formatDate(result.AllInvoices[i].CreatedDate);
                    // result.AllInvoices[i].Receipt_Date__c = $scope.formatDate(result.AllInvoices[i].Receipt_Date__c);
                }
                for(var i=0; i<result.ApprovedInvoices.length; i++){
                    $scope.totalApprovedAmount = $scope.totalApprovedAmount + (result.ApprovedInvoices[i].Invoice_value_without_GST__c == undefined ? 0 : result.ApprovedInvoices[i].Invoice_value_without_GST__c);
                    result.ApprovedInvoices[i].CreatedDate = (result.ApprovedInvoices[i].CreatedDate ? new Date(result.ApprovedInvoices[i].CreatedDate).toLocaleDateString('en-GB', {
                        day: '2-digit',
                        month: 'short',
                        year: 'numeric'
                    }) : 'Not mentioned');
                    // result.ApprovedInvoices[i].CreatedDate = $scope.formatDate(result.ApprovedInvoices[i].CreatedDate);
                    // result.ApprovedInvoices[i].Receipt_Date__c = $scope.formatDate(result.ApprovedInvoices[i].Receipt_Date__c);
                }
                // Convert object to array and sort by value in descending order
                // $scope.siteVisit = Object.entries(result.visitCounts).sort(([, valueA], [, valueB]) => valueB - valueA).map(([key, value]) => ({ id: key, value }));
                // let rankCounter1 = 0;
                // $scope.finalVisitArray = $scope.siteVisit.map((item, idx, arr) => {
                //     // If the current value is the same as the previous one, keep the same rank
                //     if (idx > 0 && item.value === arr[idx - 1].value) {
                //         return { ...item, rank: rankCounter1 };
                //     } else {
                //         return { ...item, rank: ++rankCounter1 };
                //     }
                // });
                // for(var i=0; i<$scope.finalVisitArray.length; i++){
                //     if($scope.finalVisitArray[i].id === $rootScope.accId){
                //         $scope.visitRank = $scope.finalVisitArray[i].rank;
                //     }
                // }
                // Convert object to array and sort by value in descending order
                // $scope.oppAmountList = Object.entries(result.opportunityAmounts).sort(([, valueA], [, valueB]) => valueB - valueA).map(([key, value]) => ({ id: key, value }));
                // let rankCounter2 = 0;
                // $scope.finalAmountArray = $scope.oppAmountList.map((item, idx, arr) => {
                //     // If the current value is the same as the previous one, keep the same rank
                //     if (idx > 0 && item.value === arr[idx - 1].value) {
                //         return { ...item, rank: rankCounter2 };
                //     } else {
                //         return { ...item, rank: ++rankCounter2 };
                //     }
                // });
                // for(var i=0; i<$scope.finalAmountArray.length; i++){
                //     if($scope.finalAmountArray[i].id === $rootScope.accId){
                //         $scope.amountRank = $scope.finalAmountArray[i].rank;
                //     }
                // }
                // Convert object to array and sort by value in descending order
                // $scope.unitSoldList = Object.entries(result.opportunityCounts).sort(([, valueA], [, valueB]) => valueB - valueA).map(([key, value]) => ({ id: key, value }));
                // let rankCounter3 = 0;
                // $scope.finalUnitArray = $scope.unitSoldList.map((item, idx, arr) => {
                //     // If the current value is the same as the previous one, keep the same rank
                //     if (idx > 0 && item.value === arr[idx - 1].value) {
                //         return { ...item, rank: rankCounter3 };
                //     } else {
                //         return { ...item, rank: ++rankCounter3 };
                //     }
                // });
                // for(var i=0; i<$scope.finalUnitArray.length; i++){
                //     if($scope.finalUnitArray[i].id === $rootScope.accId){
                //         $scope.unitRank = $scope.finalUnitArray[i].rank;
                //     }
                // }
                $scope.formattedTotalApprovedAmount = $scope.formatCurrency($scope.totalApprovedAmount);
                $scope.formattedTotalAmount = $scope.formatCurrency($scope.totalAmount);
                $scope.allInvoices = result.AllInvoices;
                $scope.approvedInvoices = result.ApprovedInvoices;
                $scope.totalAllInvoiceItems = $scope.allInvoices.length;
                $scope.totalAllInvoicePages = Math.ceil($scope.totalAllInvoiceItems / $scope.itemsPerPage);
                $scope.totalAllInvoiceItems2 = $scope.allInvoices.length;
                $scope.totalAllInvoicePages2 = Math.ceil($scope.totalAllInvoiceItems2 / $scope.itemsPerPage);
                $scope.totalApprovedInvoiceItems = $scope.approvedInvoices.length;
                $scope.totalApprovedInvoicePages = Math.ceil($scope.totalApprovedInvoiceItems / $scope.itemsPerPage);
                // console.log('All Invoices ---> '+JSON.stringify($scope.allInvoices));
                // console.log('Approved Invoices ---> '+JSON.stringify($scope.approvedInvoices));
            }else{
                console.log('No Invoices records found.');
            }
            $scope.$apply();
        });
    }
    $scope.getDataOnLoad();

    $scope.showMainPage = function(){
        $scope.allInvoicesPage = false;
        $scope.invoiceTotalAmountPage = false;
        $scope.invoiceAmountApprovedPage = false;
        $scope.mainPage = true;
        $scope.leaderboardPage = false;
    }

    $scope.showAllInvoices = function(){
        debugger;
        $scope.allInvoicesPage = true;
        $scope.mainPage = false;
        $scope.updatePaginatedRecords();
    }

    $scope.showInvoiceTotalAmountPage = function(){
        $scope.invoiceTotalAmountPage = true;
        $scope.mainPage = false;
        $scope.updatePaginatedRecords();
    }

    $scope.showInvoiceAmountApprovedPage = function(){
        $scope.invoiceAmountApprovedPage = true;
        $scope.mainPage = false;
        $scope.updatePaginatedRecords();
    }

    $scope.showLeaderboardPage = function(){
        $scope.leaderboardPage = true;
        $scope.mainPage = false;
    }

    $scope.openPreview = function(invoice) {
        // console.log('Opening preview for file ID:', fileId);
        
        if (invoice) {
            $scope.invoiceRec = invoice;
            var myModal = new bootstrap.Modal(document.getElementById('detailPreviewModal'));
            myModal.show();
        } else {
            console.error('No invoice record provided');
        }
    }

    $scope.closeModal = function() {
        debugger;
        $scope.invoiceRec = {};
        $('#detailPreviewModal').modal('hide');
    }

    $scope.getDisplayedRange = function() {
        // debugger;
        if($scope.allInvoicesPage){
            var start = ($scope.currentAllInvoicePage - 1) * $scope.itemsPerPage + 1;
            var end = Math.min($scope.currentAllInvoicePage * $scope.itemsPerPage, $scope.totalAllInvoiceItems);
            return `${start} to ${end}`;
        }else if($scope.invoiceTotalAmountPage){
            var start = ($scope.currentAllInvoicePage2 - 1) * $scope.itemsPerPage + 1;
            var end = Math.min($scope.currentAllInvoicePage2 * $scope.itemsPerPage, $scope.totalAllInvoiceItems2);
            return `${start} to ${end}`;
        }else if($scope.invoiceAmountApprovedPage){
            var start = ($scope.currentApprovedInvoicePage - 1) * $scope.itemsPerPage + 1;
            var end = Math.min($scope.currentApprovedInvoicePage * $scope.itemsPerPage, $scope.totalApprovedInvoiceItems);
            return `${start} to ${end}`;
        }
    }

    $scope.prevPages = function() {
        if($scope.allInvoicesPage){
            if ($scope.currentAllInvoicePage > 1) {
                $scope.currentAllInvoicePage = Math.max(1, $scope.currentAllInvoicePage - $scope.pageWindowSize);
                $scope.updatePaginatedRecords();
            }
        }else if($scope.invoiceTotalAmountPage){
            if ($scope.currentAllInvoicePage2 > 1) {
                $scope.currentAllInvoicePage2 = Math.max(1, $scope.currentAllInvoicePage2 - $scope.pageWindowSize);
                $scope.updatePaginatedRecords();
            }
        }else if($scope.invoiceAmountApprovedPage){
            if ($scope.currentApprovedInvoicePage > 1) {
                $scope.currentApprovedInvoicePage = Math.max(1, $scope.currentApprovedInvoicePage - $scope.pageWindowSize);
                $scope.updatePaginatedRecords();
            }
        }
    }

    $scope.nextPages = function() {
        if($scope.allInvoicesPage){
            if ($scope.currentAllInvoicePage < $scope.totalAllInvoicePages) {
                $scope.currentAllInvoicePage = Math.min($scope.totalAllInvoicePages, $scope.currentAllInvoicePage + $scope.pageWindowSize);
                $scope.updatePaginatedRecords();
            }
        }else if($scope.invoiceTotalAmountPage){
            if ($scope.currentAllInvoicePage2 < $scope.totalAllInvoicePages2) {
                $scope.currentAllInvoicePage2 = Math.min($scope.totalAllInvoicePages2, $scope.currentAllInvoicePage2 + $scope.pageWindowSize);
                $scope.updatePaginatedRecords();
            }
        }else if($scope.invoiceAmountApprovedPage){
            if ($scope.currentApprovedInvoicePage < $scope.totalApprovedInvoicePages) {
                $scope.currentApprovedInvoicePage = Math.min($scope.totalApprovedInvoicePages, $scope.currentApprovedInvoicePage + $scope.pageWindowSize);
                $scope.updatePaginatedRecords();
            }
        }
    }

    $scope.goToPage = function(page) {
        if($scope.allInvoicesPage){
            if (page >= 1 && page <= $scope.totalAllInvoicePages) {
                $scope.currentAllInvoicePage = page;
                $scope.updatePaginatedRecords();
            }
        }else if($scope.invoiceTotalAmountPage){
            if (page >= 1 && page <= $scope.totalAllInvoicePages2) {
                $scope.currentAllInvoicePage2 = page;
                $scope.updatePaginatedRecords();
            }
        }else if($scope.invoiceAmountApprovedPage){
            if (page >= 1 && page <= $scope.totalApprovedInvoicePages) {
                $scope.currentApprovedInvoicePage = page;
                $scope.updatePaginatedRecords();
            }
        }
    }

    $scope.updatePaginatedRecords = function() {
        if($scope.allInvoicesPage){
            var start = ($scope.currentAllInvoicePage - 1) * $scope.itemsPerPage;
            var end = start + $scope.itemsPerPage;
            $scope.paginatedAllInvoices = $scope.allInvoices.slice(start, end);
        }else if($scope.invoiceTotalAmountPage){
            var start = ($scope.currentAllInvoicePage2 - 1) * $scope.itemsPerPage;
            var end = start + $scope.itemsPerPage;
            $scope.paginatedAllInvoices2 = $scope.allInvoices.slice(start, end);
        }else if($scope.invoiceAmountApprovedPage){
            var start = ($scope.currentApprovedInvoicePage - 1) * $scope.itemsPerPage;
            var end = start + $scope.itemsPerPage;
            $scope.paginatedApprovedInvoices = $scope.approvedInvoices.slice(start, end);
        }
        $scope.$apply();
    }

    $scope.getPageRange = function() {
        if($scope.allInvoicesPage){
            var startPage = Math.max(1, $scope.currentAllInvoicePage - Math.floor($scope.pageWindowSize / 2));
            var endPage = Math.min($scope.totalAllInvoicePages, startPage + $scope.pageWindowSize - 1);
            if (endPage - startPage < $scope.pageWindowSize - 1) {
                startPage = Math.max(1, endPage - $scope.pageWindowSize + 1);
            }
            return Array.from({ length: (endPage - startPage + 1) }, (_, i) => i + startPage);
        }else if($scope.invoiceTotalAmountPage){
            var startPage = Math.max(1, $scope.currentAllInvoicePage2 - Math.floor($scope.pageWindowSize / 2));
            var endPage = Math.min($scope.totalAllInvoicePages2, startPage + $scope.pageWindowSize - 1);
            if (endPage - startPage < $scope.pageWindowSize - 1) {
                startPage = Math.max(1, endPage - $scope.pageWindowSize + 1);
            }
            return Array.from({ length: (endPage - startPage + 1) }, (_, i) => i + startPage);
        }else if($scope.invoiceAmountApprovedPage){
            var startPage = Math.max(1, $scope.currentApprovedInvoicePage - Math.floor($scope.pageWindowSize / 2));
            var endPage = Math.min($scope.totalApprovedInvoicePages, startPage + $scope.pageWindowSize - 1);
            if (endPage - startPage < $scope.pageWindowSize - 1) {
                startPage = Math.max(1, endPage - $scope.pageWindowSize + 1);
            }
            return Array.from({ length: (endPage - startPage + 1) }, (_, i) => i + startPage);
        }
    }
});