angular.module('cp_app').controller('invoice_ctrl', function($scope, $rootScope, $sce) {
    debugger;
    console.log($rootScope);
    // $rootScope.activeTab = 0;
    $scope.cpbaseUrl = window.origin + '/CustomerPortal';
    $scope.receipt = {};
    $scope.fileName = 'No file selected';

    // Hide the modal initially
    $('#filePreviewModal').modal('hide');

    $scope.statusClassMapping = {
        'Sent': 'stage-sent',
        'Pending': 'stage-pending',
        'Approved': 'stage-approved',
        'Rejected': 'stage-rejected'
    };

    $scope.fetchOppWithInvoices = function () {
        debugger;
        CustomerPortalController.getInvoiceDetails($rootScope.userId, function (result, event) {
            debugger;
            if (event.status) {
                // console.log('Apex Result:', result);
                $scope.opportunities = result.oppList;
                $scope.nameXreceipt = result.nameXreceipt;
            } else {
                console.error('Error in Apex call:', event.message);
            }
            $scope.$apply(); // Update the scope
            console.log('Fetched opportunities with invoices:', JSON.stringify($scope.opportunities));
        });
    };
    $scope.fetchOppWithInvoices();

    // Function to open the file preview
    $scope.openPreview = function (attachmentId) {
        console.log('Opening preview for attachment:', attachmentId);
        console.log('Sub Documents:', JSON.stringify($scope.nameXreceipt[attachmentId]));
        if ($scope.nameXreceipt[attachmentId] && $scope.nameXreceipt[attachmentId].Sub_Documents__r) {
            // Set the URL for the file preview
            $scope.filesrec = $scope.nameXreceipt[attachmentId].Sub_Documents__r[0].File_URL__c;
            console.log('File URL for preview:', $scope.filesrec);
            // Set the iframe source to the file URL
            $('#filePreviewFrame').attr('src', $scope.filesrec);
            // Show the modal using Bootstrap
            var myModal = new bootstrap.Modal(document.getElementById('filePreviewModal'));
            myModal.show();
        } else {
            swal('Info', 'No document uploded yet for this record.', 'info');
            console.error('No attachment ID provided');
        }
    };

    $scope.download = function (attachmentId) {
        debugger;
        console.log('Downloading file with ID:', attachmentId);
        console.log('Sub Documents:', JSON.stringify($scope.nameXreceipt[attachmentId]));
        if ($scope.nameXreceipt[attachmentId] && $scope.nameXreceipt[attachmentId].Sub_Documents__r) {
            const fileIdMatch = $scope.nameXreceipt[attachmentId].Sub_Documents__r[0].File_URL__c.match(/\/d\/([a-zA-Z0-9_-]+)/);
            var fileId;
            if (fileIdMatch && fileIdMatch[1]) {
                fileId = fileIdMatch[1];
            }
            var fileDownloadUrl = `https://drive.google.com/uc?export=download&id=${fileId}`;
            window.open(fileDownloadUrl, '_self');
        } else {
            swal('Info', 'No document uploded yet for this record.', 'info');
            console.error('No attachment ID provided');
        }
    }

    // $scope.downloadFile = function (attachmentId) {
    //     debugger;
    //     if (attachmentId) {
    //         var downloadUrl = $scope.cpbaseUrl + '/servlet/servlet.FileDownload?file=' + attachmentId;
    //         console.log('Downloading file from URL:', downloadUrl);
    //         // Create a temporary anchor element
    //         var link = document.createElement('a');
    //         link.href = downloadUrl;
    //         link.download = 'Tridasa'; // Optional: Specify the filename here if needed
    //         // Append the anchor to the body (required for Firefox)
    //         document.body.appendChild(link);
    //         // Trigger the download by simulating a click
    //         link.click();
    //         // Clean up by removing the anchor
    //         document.body.removeChild(link);
    //     } else {
    //         console.error('No attachment ID provided for download.');
    //     }
    // };

    // Function to close the modal
    $scope.closeModal = function () {
        debugger;
        $('#filePreviewModal').modal('hide');
        $('#uploadModal').modal('hide');
        $scope.receipt = {};
    };

    $scope.showUpload = function (value) {
        debugger;
        $scope.receipt = value;
        var myModal = new bootstrap.Modal(document.getElementById('uploadModal'));
        myModal.show();
    }

    $scope.uploadTDS = function () {
        debugger;
        return new Promise((resolve, reject) => {
            $scope.saveFile()
            .then(() => {
                CustomerPortalController.submitTDSApproval($scope.receipt.Id, function (result, event) {
                    if(event.status && result.includes('success')){
                        swal("Success", "File uploaded successfully.", "success");
                        $scope.fetchOppWithInvoices();
                        $scope.closeModal();
                        resolve(result);
                    } else {
                        reject(result);
                    }
                });
            })
            .catch((error) => {
                reject(error);
            });
        })
    }

    $scope.onFileChange = function(file) {
        if (file) {
            $scope.fileName = file.name;
        } else {
            $scope.fileName = 'No file selected';
        }
    };

    $scope.saveFile = function () {
        return new Promise((resolve, reject) => {
            debugger;
            var file = document.getElementById('tdsDoc').files[0];
            // If no file is uploaded throw an error
            if (file == undefined) {
                swal('Error', 'Please select a file to upload.', 'error');
                return reject('No file selected');
            } else {
                // If a file is uploaded then proceed with the upload
                fileName = file.name;
                debugger;
                attachmentName = file.name;
                var fileReader = new FileReader();
                fileReader.onloadend = function (e) {
                    attachment = window.btoa(this.result);  // Base 64 encode the file before sending it
                    positionIndex = 0;
                    fileSize = attachment.length;
                    attachmentBody = attachment.substring(positionIndex);
                    // $scope.showSpinnereditProf = false;
                    debugger;
                    if (fileSize < maxStringSize) {
                        // Call the function to upload the attachment
                        CustomerPortalController.uploadDocuments($scope.receipt.Id, attachmentName, attachmentBody, fileSize, $scope.receipt.Name, file.type, function (result, event) {
                            debugger;
                            if (event.status && result.subDocUrl) {
                                return resolve(result);
                            } else {
                                console.log('Error while uploading ' + type + ' ---> ' + event.result);
                                return reject('Error while uploading');
                            }
                            $scope.$apply();
                        });
                    } else {
                        swal("info", "Base 64 Encoded file is too large. Maximum size is " + maxStringSize + " your file is " + fileSize + ".", "info");
                        return reject('File too large');
                    }
                };
                fileReader.onerror = function () {
                    swal("info", "There was an error reading the file. Please try again.", "info");
                    return reject('Error reading file');
                };
                fileReader.onabort = function () {
                    swal("info", "There was an error reading the file. Please try again.", "info");
                    return  reject('Error reading file');
                };
                fileReader.readAsBinaryString(file);  // Read the body of the file
            }
        });
    }
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