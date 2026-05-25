angular
    .module("cp_app")
    .controller("booking_ctrl", function ($scope, $rootScope, $sce) {
        debugger;
        console.log($rootScope);

        $scope.statusClassMapping = {
            'Realized': 'stage-realized',
            'Partial Paid': 'stage-partial_paid',
            'Unpaid': 'stage-unpaid'
        };

        $scope.bookingPage = true;
        $scope.paymentPlan = false;
        $scope.psData = [];
        $scope.pageWindowSize = 4;
        $scope.itemsPerPage = 10;
        $scope.curBookingPage = 1;
        $scope.curPsPage = 1;
        $scope.totalBookingItems;
        $scope.totalBookingPages;
        $scope.totalPsPages;
        $scope.totalPsItems;

        $scope.showMainPage = function () {
            $scope.bookingPage = true;
            $scope.paymentPlan = false;
            $scope.psData = [];
        }

        $scope.toggleDetails = function (value) {
            value.showDoc = !value.showDoc;
        }

        $scope.openDocumentsPopUp = function (value) {
            debugger;
            $scope.documents = value;
            var myModal = new bootstrap.Modal(document.getElementById('documentsModal'));
            myModal.show();
            $scope.$apply();
        }

        $scope.closeDocumentsPopUp = function () {
            debugger;
            $('#documentsModal').modal('hide');
        }

        $scope.formatCurrency = function (amount) {
            debugger;
            return new Intl.NumberFormat('en-IN', {
                style: 'currency',
                currency: 'INR', // Replace with your currency code (e.g., 'INR' for Indian Rupee)
                minimumFractionDigits: 0 // Change to 2 if you need decimals
            }).format(amount);
        };

        // $scope.showPaymentPlanPage = function (value) {
        //     $scope.bookingPage = false;
        //     $scope.totalAmount = 0;
        //     $scope.totalAmountStr = '';
        //     $scope.amountPaid = 0;
        //     $scope.amountPaidStr = '';
        //     $scope.amountDue = 0;
        //     $scope.amountDueStr = '';

        //     //newVariablesBy Sagar---
        //     $scope.totalAmountCollected = '';
        //     $scope.amountPaidTillDate = '';
        //     debugger;
        //     CustomerPortalController.fetchPaymentSchedules(value.Id, function (result, event) {
        //         debugger;
        //         if (event.status && result) {
        //             for (var i = 0; i < result.length; i++) {
        //                 result[i].Due_Date__c = (result[i].Due_Date__c ? new Date(result[i].Due_Date__c).toLocaleDateString('en-GB', {
        //                     day: '2-digit',
        //                     month: 'short',
        //                     year: 'numeric'
        //                 }) : 'Not mentioned');
        //                 result[i].Pay_Date__c = (result[i].Pay_Date__c ? new Date(result[i].Pay_Date__c).toLocaleDateString('en-GB', {
        //                     day: '2-digit',
        //                     month: 'short',
        //                     year: 'numeric'
        //                 }) : 'Not mentioned');
        //                 $scope.totalAmount += result[i].Agreement_Value__c ? result[i].Agreement_Value__c : 0;
        //                 $scope.amountDue += result[i].Total_Due_Amount__c;
        //                 result[i].Agreement_Value__c = result[i].Agreement_Value__c ? $scope.formatCurrency(result[i].Agreement_Value__c) : '₹0';
        //                 result[i].Total_Due_Amount__c = $scope.formatCurrency(result[i].Total_Due_Amount__c);
        //             }
        //             $scope.amountPaid = $scope.totalAmount - $scope.amountDue;
        //             $scope.totalAmountStr =  //$scope.formatCurrency($scope.totalAmount);
        //             $scope.amountPaidStr = $scope.formatCurrency($scope.amountPaid);
        //             $scope.amountDueStr = $scope.formatCurrency($scope.amountDue);
        //             $scope.psData = $rootScope.replaceAMPinArr(result);
        //             $scope.totalPsItems = $scope.psData.length;
        //             $scope.totalPsPages = Math.ceil($scope.totalPsItems / $scope.itemsPerPage);
        //             $scope.paymentPlan = true;
        //             $scope.updatePaginatedRecords();
        //         }
        //         $scope.$apply();
        //     });
        // }

        $scope.showPaymentPlanPage = function (value) {

            $scope.bookingPage = false;

            $scope.totalAmount = 0;
            $scope.totalAmountStr = '';

            $scope.amountPaid = 0;
            $scope.amountPaidStr = '';

            $scope.amountDue = 0;
            $scope.amountDueStr = '';

            CustomerPortalController.fetchPaymentSchedules(value.Id, function (result, event) {

                if (event.status && result) {

                    for (var i = 0; i < result.length; i++) {

                        result[i].Due_Date__c = (
                            result[i].Due_Date__c
                            ? new Date(result[i].Due_Date__c).toLocaleDateString('en-GB', {
                                day: '2-digit',
                                month: 'short',
                                year: 'numeric'
                            })
                            : 'Not mentioned'
                        );

                        result[i].Pay_Date__c = (
                            result[i].Pay_Date__c
                            ? new Date(result[i].Pay_Date__c).toLocaleDateString('en-GB', {
                                day: '2-digit',
                                month: 'short',
                                year: 'numeric'
                            })
                            : 'Not mentioned'
                        );

                        result[i].Agreement_Value__c =
                            result[i].Agreement_Value__c
                            ? $scope.formatCurrency(result[i].Agreement_Value__c)
                            : '₹0';

                        result[i].Total_Due_Amount__c =
                            $scope.formatCurrency(result[i].Total_Due_Amount__c);
                    }

                    // Taking values from Opportunity
                    if (result.length > 0 && result[0].Opportunity__r) {

                        $scope.totalAmount =
                            result[0].Opportunity__r.Total_Outstanding_Amount__c || 0;

                        $scope.amountPaid =
                            result[0].Opportunity__r.Total_Amount_Collected__c || 0;

                        $scope.amountDue =
                            $scope.totalAmount - $scope.amountPaid;
                    }

                    $scope.totalAmountStr = $scope.formatCurrency($scope.totalAmount);
                    $scope.amountPaidStr = $scope.formatCurrency($scope.amountPaid);
                    $scope.amountDueStr = $scope.formatCurrency($scope.amountDue);

                    $scope.psData = $rootScope.replaceAMPinArr(result);

                    $scope.totalPsItems = $scope.psData.length;
                    $scope.totalPsPages = Math.ceil($scope.totalPsItems / $scope.itemsPerPage);

                    $scope.paymentPlan = true;

                    $scope.updatePaginatedRecords();
                }

                $scope.$apply();
            });
        }

        $scope.fetchBookingData = function () {
            debugger;
            CustomerPortalController.fetchBookingData($rootScope.userId, function (result, event) {
                debugger;
                if (event.status && result) {
                    for (var i = 0; i < result.length; i++) {
                        result[i].Booking_Date__c = (result[i].Booking_Date__c ? new Date(result[i].Booking_Date__c).toLocaleDateString('en-GB', {
                            day: '2-digit',
                            month: 'short',
                            year: 'numeric'
                        }) : 'Not mentioned');
                        result[i].showDoc = false;
                    }
                    $scope.oppList = result;
                    $scope.totalBookingItems = $scope.oppList.length;
                    $scope.totalBookingPages = Math.ceil($scope.totalBookingItems / $scope.itemsPerPage);
                    $scope.updatePaginatedRecords();
                }
                $scope.$apply();
            });
        }
        $scope.fetchBookingData();

        $scope.getTrustedUrl = function (url) {
            return $sce.trustAsResourceUrl(url);
        }

        $scope.openPreview = function (fileId) {
            debugger;
            console.log('Opening preview for file ID:', fileId);
            if (fileId) {
                // Set the URL for the file preview
                $scope.filesrec = fileId;
                console.log('File URL for preview:', $scope.filesrec);
                // Set the iframe source to the file URL
                $('#filePreviewFramebookings').attr('src', $scope.getTrustedUrl($scope.filesrec));
                // Show the modal using Bootstrap 5 method
                var myModal = new bootstrap.Modal(document.getElementById('filePreviewModalbookings'));
                myModal.show();
            } else {
                console.error('No attachment ID provided');
            }
        }

        $scope.closeModal = function () {
            debugger;
            $scope.filesrec = '';
            $('#filePreviewFramebookings').attr('src', $scope.getTrustedUrl($scope.filesrec));
            $('#filePreviewModalbookings').modal('hide');
        }
        
        // $scope.openFirstPopup = function () {
        //     debugger;
        //     // Show the modal using Bootstrap 5 method
        //     var myModal = new bootstrap.Modal(document.getElementById('welcomeScreen'));
        //     myModal.show();
        // }
        // $scope.openFirstPopup();

        // $scope.closeFirstPopup = function () {
        //     debugger;
        //     $scope.filesrec = '';
        //     $('#filePreviewFramebookings').attr('src', $scope.getTrustedUrl($scope.filesrec));
        //     $('#welcomeScreen').modal('hide');
        // }

        $scope.download = function (fileURL) {
            debugger;
            console.log('Downloading file with ID:', fileURL);
            if (fileURL) {
                const fileIdMatch = fileURL.match(/\/d\/([a-zA-Z0-9_-]+)/);
                var fileId;
                if (fileIdMatch && fileIdMatch[1]) {
                    fileId = fileIdMatch[1];
                }
                var fileDownloadUrl = `https://drive.google.com/uc?export=download&id=${fileId}`;
                window.open(fileDownloadUrl, '_self');
            } else {
                alert('No file associated with this event.');
            }
        }

        $scope.getDisplayedRange = function () {
            if ($scope.bookingPage) {
                var start = ($scope.curBookingPage - 1) * $scope.itemsPerPage + 1;
                var end = Math.min($scope.curBookingPage * $scope.itemsPerPage, $scope.totalBookingItems);
                return `${start} to ${end}`;
            } else if ($scope.paymentPlan) {
                var start = ($scope.curPsPage - 1) * $scope.itemsPerPage + 1;
                var end = Math.min($scope.curPsPage * $scope.itemsPerPage, $scope.totalPsItems);
                return `${start} to ${end}`;
            }
        }

        $scope.prevPages = function () {
            if ($scope.bookingPage) {
                if ($scope.curBookingPage > 1) {
                    $scope.curBookingPage = Math.max(1, $scope.curBookingPage - $scope.pageWindowSize);
                    $scope.updatePaginatedRecords();
                }
            } else if ($scope.paymentPlan) {
                if ($scope.curPsPage > 1) {
                    $scope.curPsPage = Math.max(1, $scope.curPsPage - $scope.pageWindowSize);
                    $scope.updatePaginatedRecords();
                }
            }
        }

        $scope.nextPages = function () {
            if ($scope.bookingPage) {
                if ($scope.curBookingPage < $scope.totalBookingPages) {
                    $scope.curBookingPage = Math.min($scope.totalBookingPages, $scope.curBookingPage + $scope.pageWindowSize);
                    $scope.updatePaginatedRecords();
                }
            } else if ($scope.paymentPlan) {
                if ($scope.curPsPage < $scope.totalPsPages) {
                    $scope.curPsPage = Math.min($scope.totalPsPages, $scope.curPsPage + $scope.pageWindowSize);
                    $scope.updatePaginatedRecords();
                }
            }
        }

        $scope.goToPage = function (page) {
            if ($scope.bookingPage) {
                if (page >= 1 && page <= $scope.totalBookingPages) {
                    $scope.curBookingPage = page;
                    $scope.updatePaginatedRecords();
                }
            } else if ($scope.paymentPlan) {
                if (page >= 1 && page <= $scope.totalPsPages) {
                    $scope.curPsPage = page;
                    $scope.updatePaginatedRecords();
                }
            }
        }

        $scope.updatePaginatedRecords = function () {
            if ($scope.bookingPage) {
                var start = ($scope.curBookingPage - 1) * $scope.itemsPerPage;
                var end = start + $scope.itemsPerPage;
                $scope.paginatedBookings = $scope.oppList.slice(start, end);
            } else if ($scope.paymentPlan) {
                var start = ($scope.curPsPage - 1) * $scope.itemsPerPage;
                var end = start + $scope.itemsPerPage;
                $scope.paginatedPs = $scope.psData.slice(start, end);
            }
            $scope.$apply();
        }

        $scope.getPageRange = function () {
            if ($scope.bookingPage) {
                var startPage = Math.max(1, $scope.curBookingPage - Math.floor($scope.pageWindowSize / 2));
                var endPage = Math.min($scope.totalBookingPages, startPage + $scope.pageWindowSize - 1);
                if (endPage - startPage < $scope.pageWindowSize - 1) {
                    startPage = Math.max(1, endPage - $scope.pageWindowSize + 1);
                }
                return Array.from({ length: (endPage - startPage + 1) }, (_, i) => i + startPage);
            } else if ($scope.paymentPlan) {
                var startPage = Math.max(1, $scope.curPsPage - Math.floor($scope.pageWindowSize / 2));
                var endPage = Math.min($scope.totalPsPages, startPage + $scope.pageWindowSize - 1);
                if (endPage - startPage < $scope.pageWindowSize - 1) {
                    startPage = Math.max(1, endPage - $scope.pageWindowSize + 1);
                }
                return Array.from({ length: (endPage - startPage + 1) }, (_, i) => i + startPage);
            }
        }
    });