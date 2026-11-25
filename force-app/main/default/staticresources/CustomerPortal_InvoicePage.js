angular.module('cp_app').controller('invoice_ctrl', function($scope, $rootScope, $sce) {
    // Receipts tab of the Customer Portal.
    // Nov 2026 (client): only Tax Invoice receipts are listed, the receipt number is shown instead of the
    // record id, the per-receipt TDS upload / TDS approval columns are removed, and each booking has its own
    // "Upload TDS Challan" button (stored in the booking's "TDS Uploaded Docs" folder; the booking owner is notified).
    $scope.cpbaseUrl = window.origin + '/CustomerPortal';
    $scope.fileName = 'No file selected';
    $scope.receiptsLoaded = false;
    $scope.tdsChallans = {};
    $scope.challanOpp = null;
    $scope.uploading = false;

    var MAX_CHALLAN_BYTES = 3 * 1024 * 1024;               // same limit as CustomerPortalController.TDS_CHALLAN_MAX_BYTES
    var ALLOWED_EXTENSIONS = ['pdf', 'jpg', 'jpeg', 'png'];
    var UPLOAD_FAILED = 'The file could not be uploaded. Please try again.';

    $scope.statusClassMapping = {
        'Sent': 'stage-sent',
        'Pending': 'stage-pending',
        'Approved': 'stage-approved',
        'Rejected': 'stage-rejected'
    };

    function applyScope() {
        if (!$scope.$$phase && !$rootScope.$$phase) {
            $scope.$apply();
        }
    }

    // challansOnly: after an upload only the challan lists are refreshed, so the open booking stays open.
    $scope.fetchOppWithInvoices = function (challansOnly) {
        CustomerPortalController.getInvoiceDetails($rootScope.userId, function (result, event) {
            if (event.status && result && challansOnly) {
                $scope.tdsChallans = result.oppIdXTdsChallans || {};
            } else if (event.status && result) {
                $scope.opportunities = result.oppList || [];
                $scope.tdsChallans = result.oppIdXTdsChallans || {};
            } else if (challansOnly) {
                console.error('Error in Apex call:', event.message);
            } else {
                console.error('Error in Apex call:', event.message);
                $scope.opportunities = [];
                $scope.tdsChallans = {};
            }
            $scope.receiptsLoaded = true;
            applyScope();
        });
    };
    $scope.fetchOppWithInvoices();

    // Kept in script: Visualforce turns && and > in page attributes into entities that Angular cannot parse.
    $scope.showNoReceipts = function () {
        return $scope.receiptsLoaded && (!$scope.opportunities || $scope.opportunities.length === 0);
    };
    $scope.hasChallans = function (opp) {
        var list = opp && $scope.tdsChallans ? $scope.tdsChallans[opp.Id] : null;
        return !!(list && list.length > 0);
    };

    function resetFileInput() {
        $scope.fileName = 'No file selected';
        var input = document.getElementById('tdsDoc');
        if (input) {
            input.value = '';
        }
    }

    // Close the upload popup
    $scope.closeModal = function () {
        $('#uploadModal').modal('hide');
        $scope.challanOpp = null;
        resetFileInput();
    };

    // Open the upload popup for one booking
    $scope.showChallanUpload = function (opp) {
        $scope.challanOpp = opp;
        resetFileInput();
        var myModal = new bootstrap.Modal(document.getElementById('uploadModal'));
        myModal.show();
    };

    $scope.onFileChange = function (file) {
        $scope.fileName = file ? file.name : 'No file selected';
    };

    $scope.uploadChallan = function () {
        // Ignore repeated clicks while an upload is in progress
        if ($scope.uploading) {
            return;
        }
        if (!$scope.challanOpp) {
            swal('Error', 'Please close this window and click "Upload TDS Challan" on the booking again.', 'error');
            return;
        }
        var input = document.getElementById('tdsDoc');
        var file = input && input.files ? input.files[0] : null;
        if (!file) {
            swal('Error', 'Please select the TDS Challan file to upload.', 'error');
            return;
        }
        var extension = (file.name.indexOf('.') > -1 ? file.name.split('.').pop() : '').toLowerCase();
        if (ALLOWED_EXTENSIONS.indexOf(extension) === -1) {
            swal('Error', 'Please upload the TDS Challan as a PDF, JPG or PNG file.', 'error');
            return;
        }
        if (file.size === 0) {
            swal('Error', 'The selected file is empty. Please choose another file.', 'error');
            return;
        }
        if (file.size > MAX_CHALLAN_BYTES) {
            swal('Error', 'The file is too large. Please upload a file of up to 3 MB.', 'error');
            return;
        }

        $scope.uploading = true;
        var oppId = $scope.challanOpp.Id;
        var reader = new FileReader();
        reader.onload = function (e) {
            var dataUrl = e.target.result || '';
            var base64 = dataUrl.indexOf(',') > -1 ? dataUrl.substring(dataUrl.indexOf(',') + 1) : '';
            CustomerPortalController.uploadTdsChallan($rootScope.userId, oppId, file.name, base64, file.type || '', function (result, event) {
                $scope.uploading = false;
                if (event.status && result && result.success) {
                    swal(result.alreadyUploaded ? 'Already uploaded' : 'Uploaded', result.message, result.alreadyUploaded ? 'info' : 'success');
                    $scope.closeModal();
                    $scope.fetchOppWithInvoices(true);
                } else {
                    console.log('TDS Challan upload: ' + ((result && result.message) || event.message));
                    swal('Error', (result && result.message) ? result.message : UPLOAD_FAILED, 'error');
                }
                applyScope();
            }, { escape: false, timeout: 120000 });
        };
        reader.onerror = reader.onabort = function () {
            $scope.uploading = false;
            swal('Error', 'There was an error reading the file. Please try again.', 'error');
            applyScope();
        };
        reader.readAsDataURL(file);
        applyScope();
    };
});

app.directive('fileChange', function() {
    return {
        restrict: 'A',
        scope: {
            fileChange: '&'
        },
        link: function(scope, element, attrs) {
            element.on('change', function(event) {
                var file = event.target.files[0];
                scope.$apply(function() {
                    scope.fileChange({ file: file });
                });
            });
        }
    };
});
