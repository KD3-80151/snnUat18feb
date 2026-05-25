angular.module('channelpartner_app').controller('cppmyteam_ctrl', function ($scope, $rootScope) {
    debugger;
    $scope.statusClassMapping = {
        'New': 'stage-New',
        'Assigned': 'stage-Assigned',
        'Contacted': 'stage-Contacted',
        'Qualified': 'stage-Qualified',
        'SV Planned': 'stage-SV_Planned',
        'Re-Enquiry': 'stage-Re_Enquiry',
        'Dropped': 'stage-Dropped'
    };
    // console.log($rootScope);
    // $rootScope.activeTab = 0;
    $scope.teamMemberDetails = false;
    $scope.myTeam = true;
    $scope.showSpinner = false;
    $scope.editProfile = false;
    $scope.isDisabledAddMember = false;
    $scope.totalItems;
    $scope.totalPages;
    $scope.itemsPerPage = 5;
    $scope.currentPage = 1;
    $scope.pageWindowSize = 4;
    $scope.accObj = { "Name": "" };

    $scope.getTeamMembers = function () {
        debugger;
        ChannelPartner_Controller.getTeamMembers($rootScope.userId, function (result, event) {
            debugger;
            if (event.status && result) {
                $scope.teamMembers = result.accList;
                $scope.maxTMCount = Number(result.maxCount);
            }
            $scope.$apply();
        });
    }
    $scope.getTeamMembers();

    $scope.showTeamDetail = function (teamMember) {
        debugger;
        $scope.memberRecord = teamMember;
        $scope.showSpinner = true;
        ChannelPartner_Controller.getRelatedLeads(teamMember.Id, function (result, event) {
            debugger;
            if (event.status && result) {
                $scope.relatedLeads = result;
                $scope.totalItems = $scope.relatedLeads.length;
                $scope.totalPages = Math.ceil($scope.totalItems / $scope.itemsPerPage);
                $scope.updatePaginatedLeads();
            }
            $scope.teamMemberDetails = true;
            $scope.myTeam = false;
            $scope.editProfile = false;
            $scope.showSpinner = false;
            $scope.$apply();
        })
    }

    $scope.showEditProfile = function (teamMember) {
        debugger;
        $scope.memberRecord = teamMember;
        $scope.teamMemberDetails = false;
        $scope.myTeam = false;
        $scope.showSpinner = false;
        $scope.editProfile = true;
        $scope.$apply();
    }

    $scope.addTeanMember = function () {
        debugger;
        if ($scope.accObj.Name == "") {
            swal('Info', 'Team member Name is a mandatory field!!', 'info');
        }
        if ($scope.accObj.Email__c == "" || $scope.accObj.Email__c == undefined) {
            swal('Info', 'Team member Email is a mandatory field!!', 'info');
        }
        else {
            if ($scope.accObj.Email__c != undefined && $scope.accObj.Email__c != "") {
                var x = $scope.accObj.Email__c;
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
            $scope.isDisabledAddMember = true;
            var file = document.getElementById("uploadImage").files[0];
            if (file == undefined) {
                // $scope.acc1.Id = $rootScope.accId;
                // delete ($scope.memberRecord['$$hashKey']);
                ChannelPartner_Controller.CreateChannelPartnerForChannelPartnerTeamPage($scope.accObj, $rootScope.userId, function (result, event) {
                    debugger;
                    if (event.status && result) {
                        $scope.accObj.Id = result;
                        swal('Success', 'Data inserted successfully.', 'success');
                        $scope.isDisabledAddMember = false;
                        $scope.closeModal();
                    } else {
                        swal('Error', 'Something went wrong!', 'error');
                        $scope.isDisabledAddMember = false;
                    }
                    $scope.getTeamMembers();
                    $scope.$apply();
                });
            } else {
                var fileName = file.name;
                var typeOfFile = fileName.split(".");
                var lengthOfType = typeOfFile.length;
                var fileExtention2 = typeOfFile[lengthOfType - 1];
                if (fileExtention2 == 'png' || fileExtention2 == 'PNG' || fileExtention2 == "jpg" || fileExtention2 == "jpeg" || fileExtention2 == "JPEG" || fileExtention2 == "JPG") {
                    // debugger;
                } else {
                    // debugger;
                    swal('info', 'Please choose jpg/jpeg/png file only.', 'info');
                    return;
                }

                if (file.size < '30720' || file.size > '512000') {
                    debugger;
                    swal("info", "File must be between 30 to 500 kb in size. Your file is too small. Please try again.", "info");
                    return;
                }else{
                    ChannelPartner_Controller.CreateChannelPartnerForChannelPartnerTeamPage($scope.accObj, $rootScope.userId, function (result, event) {
                        debugger;
                        if (event.status && result) {
                            $scope.accObj.Id = result;
                            // If a file is uploaded, first upload the file and then update the profile
                            $scope.uploadFileOnCreation('Profile Picture')
                            .then(function () {
                                // File upload was successful, now update the profile
                                // $scope.acc1.Id = $rootScope.accId;
                                $scope.isDisabledAddMember = false;
                                swal('Success', 'Profile created successfully.', 'success');
                                $scope.getTeamMembers();
                                $scope.closeModal();
                            })
                            .catch(function (error) {
                                // Handle any errors during file upload
                                $scope.isDisabledAddMember = false;
                                console.error("Error during upload or save: ", error);
                            });
                            // alert('Data inserted successfully...');
                        } else {
                            $scope.isDisabledAddMember = false;
                            swal('Error', 'Something went wrong!', 'error');
                        }
                        $scope.getTeamMembers();
                        $scope.$apply();
                    });
                }
            }
        }
    }

    $scope.updatePaginatedLeads = function () {
        // debugger;
        var start = ($scope.currentPage - 1) * $scope.itemsPerPage;
        var end = start + $scope.itemsPerPage;
        $scope.paginatedLeads = $scope.relatedLeads.slice(start, end);
        $scope.$apply();
    }

    $scope.getPageRange = function () {
        // debugger;
        var startPage = Math.max(1, $scope.currentPage - Math.floor($scope.pageWindowSize / 2));
        var endPage = Math.min($scope.totalPages, startPage + $scope.pageWindowSize - 1);
        if (endPage - startPage < $scope.pageWindowSize - 1) {
            startPage = Math.max(1, endPage - $scope.pageWindowSize + 1);
        }
        return Array.from({ length: (endPage - startPage + 1) }, (_, i) => i + startPage);
    }

    $scope.goToPage = function (page) {
        // debugger;
        if (page >= 1 && page <= $scope.totalPages) {
            $scope.currentPage = page;
            $scope.updatePaginatedLeads();
        }
    }

    $scope.prevPages = function () {
        // debugger;
        if ($scope.currentPage > 1) {
            $scope.currentPage = Math.max(1, $scope.currentPage - $scope.pageWindowSize);
            $scope.updatePaginatedLeads();
        }
    }

    $scope.nextPages = function () {
        // debugger;
        if ($scope.currentPage < $scope.totalPages) {
            $scope.currentPage = Math.min($scope.totalPages, $scope.currentPage + $scope.pageWindowSize);
            $scope.updatePaginatedLeads();
        }
    }

    $scope.showMainPage = function () {
        $scope.teamMemberDetails = false;
        $scope.myTeam = true;
        $scope.showSpinner = false;
        $scope.editProfile = false;
        $scope.getTeamMembers();
    }

    $scope.getDisplayedRange = function () {
        // debugger;
        var start = ($scope.currentPage - 1) * $scope.itemsPerPage + 1;
        var end = Math.min($scope.currentPage * $scope.itemsPerPage, $scope.totalItems);
        return `${start} to ${end}`;
    }

    var fileExtention1
    $scope.uploadFile = function (type, fileSizeFun, fileSizeMin) {
        return new Promise(function (resolve, reject) {
            debugger;
            maxFileSize = fileSizeFun;
            var file = document.getElementById("uploadProfile").files[0];
            if (file != undefined) {
                fileName = file.name;
                var typeOfFile = fileName.split(".");
                var lengthOfType = typeOfFile.length;
                fileExtention1 = typeOfFile[lengthOfType - 1];
                if (fileExtention1 == 'png' || fileExtention1 == 'PNG' || fileExtention1 == "jpg" || fileExtention1 == "jpeg" || fileExtention1 == "JPEG" || fileExtention1 == "JPG") {
                    debugger;
                } else {
                    debugger;
                    swal('info', 'Please choose jpg/jpeg/png file only.', 'info');
                    return reject('Invalid file format');
                }

                if (file.size <= maxFileSize) {
                    debugger;
                    if (file.size < fileSizeMin) {
                        debugger;
                        swal("info", "File must be between 30 to 500 kb in size. Your file is too small. Please try again.", "info");
                        return reject('File too small');
                    }

                    attachmentName = file.name;
                    var fileReader = new FileReader();

                    fileReader.onloadend = function (e) {
                        attachment = window.btoa(this.result);  // Base 64 encode the file before sending it
                        positionIndex = 0;
                        fileSize = attachment.length;
                        $scope.showSpinnereditProf = false;
                        debugger;
                        if (fileSize < maxStringSize) {
                            // Call the function to upload the attachment
                            $scope.uploadAttachment(type).then(resolve).catch(reject);
                        } else {
                            swal("info", "Base 64 Encoded file is too large. Maximum size is " + maxStringSize + " your file is " + fileSize + ".", "info");
                            return reject('File too large');
                        }
                    };

                    fileReader.onerror = function () {
                        swal("info", "There was an error reading the file. Please try again.", "info");
                        return reject('File reading error');
                    };

                    fileReader.onabort = function () {
                        swal("info", "There was an error reading the file. Please try again.", "info");
                        return reject('File read aborted');
                    };

                    fileReader.readAsBinaryString(file);  // Read the body of the file

                } else {
                    swal("info", "File must be under 500 kb in size. Your file is too large. Please try again.", "info");
                    return reject('File too large');
                }
            }
        });
    };

    $scope.uploadFileOnCreation = function (type) {
        return new Promise(function (resolve, reject) {
            debugger;
            var file = document.getElementById("uploadImage").files[0];
            if (file != undefined) {
                attachmentName = file.name;
                var fileReader = new FileReader();
                fileReader.onloadend = function (e) {
                    attachment = window.btoa(this.result);  // Base 64 encode the file before sending it
                    positionIndex = 0;
                    fileSize = attachment.length;
                    $scope.showSpinnereditProf = false;
                    debugger;
                    if (fileSize < maxStringSize) {
                        // Call the function to upload the attachment
                        $scope.uploadAttachmentOnCreation(type).then(resolve).catch(reject);
                    } else {
                        swal("info", "Base 64 Encoded file is too large. Maximum size is " + maxStringSize + " your file is " + fileSize + ".", "info");
                        return reject('File too large');
                    }
                };
                fileReader.onerror = function () {
                    swal("info", "There was an error reading the file. Please try again.", "info");
                    return reject('File reading error');
                };
                fileReader.onabort = function () {
                    swal("info", "There was an error reading the file. Please try again.", "info");
                    return reject('File read aborted');
                };
                fileReader.readAsBinaryString(file);  // Read the body of the file
            }
        });
    };

    $scope.uploadAttachment = function (type) {
        debugger;
        return new Promise(function (resolve, reject) {
            debugger;
            var attachmentBody = "";
            if (fileSize <= positionIndex + chunkSize) {
                attachmentBody = attachment.substring(positionIndex);
                doneUploading = true;
            } else {
                attachmentBody = attachment.substring(positionIndex, positionIndex + chunkSize);
            }

            // console.log("Uploading " + attachmentBody.length + " chars of " + fileSize);
            ChannelPartner_Controller.doUploadTeamMemberProfilePic(
                $scope.memberRecord.Id, attachmentBody, attachmentName, fileExtention1,
                function (result, event) {
                    debugger;
                    if (event.type === 'exception') {
                        console.log("exception");
                        console.log(event);
                        reject(event.message);
                    } else if (event.status, result == 'Success') {
                        if (doneUploading == true) {
                            // $scope.profilePicId = result;
                            resolve(result);  // Resolve the promise
                        } else {
                            positionIndex += chunkSize;
                            $scope.uploadAttachment(type).then(resolve).catch(reject);  // Recursively call if not done
                        }
                    } else {
                        reject('Upload failed');
                    }
                    $scope.$apply();
                },
                { buffer: true, escape: true, timeout: 120000 }
            );
        });
    };

    $scope.uploadAttachmentOnCreation = function (type) {
        return new Promise(function (resolve, reject) {
            debugger;
            var attachmentBody = "";
            if (fileSize <= positionIndex + chunkSize) {
                attachmentBody = attachment.substring(positionIndex);
                doneUploading = true;
            } else {
                attachmentBody = attachment.substring(positionIndex, positionIndex + chunkSize);
            }

            // console.log("Uploading " + attachmentBody.length + " chars of " + fileSize);
            ChannelPartner_Controller.doUploadTeamMemberProfilePic(
                $scope.accObj.Id, attachmentBody, attachmentName, fileExtention2,
                function (result, event) {
                    debugger;
                    if (event.type === 'exception') {
                        console.log("exception");
                        console.log(event);
                        reject(event.message);
                    } else if (event.status, result == 'Success') {
                        if (doneUploading == true) {
                            // $scope.profilePicId = result;
                            resolve(result);  // Resolve the promise
                        } else {
                            positionIndex += chunkSize;
                            $scope.uploadAttachmentOnCreation(type).then(resolve).catch(reject);  // Recursively call if not done
                        }
                    } else {
                        reject('Upload failed');
                    }
                    $scope.$apply();
                },
                { buffer: true, escape: true, timeout: 120000 }
            );
        });
    };

    $scope.saveChanges = function () {
        debugger;
        var file = document.getElementById("uploadProfile").files[0];

        // If no file is uploaded, just update the profile
        if (file == undefined) {
            // $scope.acc1.Id = $rootScope.accId;
            delete ($scope.memberRecord['$$hashKey']);
            ChannelPartner_Controller.updateProfile($scope.memberRecord, function (event, result) {
                debugger;
                if (event.status, result) {
                    // $scope.acc1 = result;
                    swal('Success', 'Profile updated successfully.', 'success');
                }else{
                    console.log('Error updating profile ---> '+event.message);
                }
            });
        } else {
            // If a file is uploaded, first upload the file and then update the profile
            $scope.uploadFile('Profile Picture', '512000', '30720')
                .then(function () {
                    // File upload was successful, now update the profile
                    // $scope.acc1.Id = $rootScope.accId;
                    delete ($scope.memberRecord['$$hashKey']);
                    delete ($scope.memberRecord['Profile_Pic_Attachment_Id__c']);
                    ChannelPartner_Controller.updateProfile($scope.memberRecord, function (event, result) {
                        debugger;
                        if (event.status, result) {
                            $scope.editmemberRecord = result;
                            swal('Success', 'Profile updated successfully.', 'success');
                        }
                    });
                })
                .catch(function (error) {
                    // Handle any errors during file upload
                    console.error("Error during upload or save: ", error);
                });
        }
    };

    $scope.closeModal = function(){
        debugger;
        $scope.accObj = {};
        document.querySelector("#uploadImage").value = '';
        $('#addNewMemberModal').modal('hide');
    }

    document.getElementById('addTeamMemberBtn').addEventListener('click', function () {
        // Show the modal from the included page
        debugger;
        if($scope.teamMembers.length >= $scope.maxTMCount){
            swal('Error', 'You have reached maximum limit of team members!', 'error');
                        // myModal.hide();
        }else{
            var myModal = new bootstrap.Modal(document.getElementById('addNewMemberModal'));
            myModal.show();
        }

    })
    document.getElementById('addTeamMemberBtnMobile').addEventListener('click', function () {
        // Show the modal from the included page
        var myModal = new bootstrap.Modal(document.getElementById('addNewMemberModal'));
        myModal.show();
    })

    function showEditProfilePage() {
        document.getElementById('myteamPageContent').style.display = 'none';
        document.getElementById('editProfileContent').style.display = 'block';
    }
    function showViewDetailPage() {
        document.getElementById('myteamPageContent').style.display = 'none';
        document.getElementById('viewDetailsContent').style.display = 'block';
    }
    function showMyTeamsPage() {
        document.getElementById('editProfileContent').style.display = 'none';
        document.getElementById('viewDetailsContent').style.display = 'none';
        document.getElementById('myteamPageContent').style.display = 'block';
    }
});

app.directive('wrapIntlTelInput', function ($timeout) {
    return {
        restrict: 'A',
        require: '^ngModel',
        link: link
    };

    ////////////////////////////////////////////////////////////

    function link(scope, elem, attrs, ctrl) {
        hookFieldIntoIntlTelInputJqueryPlugin();
        hookFieldIntoJqueryChangeEvent();

        ctrl.$parsers.push(validateFieldAndFormatModelValue);

        elem.on('blur keyup change', applyRenderWhenChange);
        elem.on('$destroy', function () {
            elem.off('blur keyup change');
        });

        $timeout(applyMaskingWhenInitWithPresetPhoneNumber);

        ////////////

        function hookFieldIntoIntlTelInputJqueryPlugin() {
            elem.intlTelInput({
                autoFormat: false,
                autoHideDialCode: true,
                autoPlaceholder: false,
                defaultCountry: 'us',
                nationalMode: true,
                numberType: '',
                preferredCountries: ['us', 'ca', 'gb', 'au'],
                responsiveDropdown: false,
                utilsScript: ''
            });
        }

        function hookFieldIntoJqueryChangeEvent() {
            elem.change(reformatPhoneNumberWithCountryCode);
        }

        function reformatPhoneNumberWithCountryCode() {
            ctrl.$$parseAndValidate();
        }

        function validateFieldAndFormatModelValue(value) {
            var parsedValue = elem.intlTelInput('getNumber') || value;
            var formattedModelValue = removeInvalidInput(parsedValue);
            ctrl.$setValidity('invalidIntlTel', elem.intlTelInput('isValidNumber'));
            return formattedModelValue;

            ////////////

            function removeInvalidInput(input) {
                return input ? input.replace(/(?!^\+?)[^0-9]/g, '') : '';
            }
        }

        function applyMaskingWhenInitWithPresetPhoneNumber() {
            if (elem.val()) {a
                elem.intlTelInput('setNumber', elem.val());
                applyRenderWhenChange();
            }
        }

        function applyRenderWhenChange() {
            scope.$apply(function () {
                return ctrl.$setViewValue(elem.val());
            });
        }
    }
});