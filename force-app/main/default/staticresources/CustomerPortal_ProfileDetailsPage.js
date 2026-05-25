angular.module('cp_app').controller('cpprofilepage_ctrl', function($scope,$rootScope){
  debugger;
  console.log($rootScope);
  // $rootScope.activeTab = 0;
  $scope.baseUrl = window.origin;
  $rootScope.profilePicId;
  $rootScope.profileUrl;
  $scope.profilePic = true;
  $scope.editable = false;
  $scope.con1 = {};
  $scope.$watch('$root.con', function (newVal, oldVal) {
    if (newVal) {
      $scope.con1 = angular.copy(newVal);
    }
  });

  $scope.changeProfilePic = function () {
    debugger;
    $scope.profilePic = false;
  }

  $scope.editProfile = function () {
    $scope.editable = true;
  }

  var urlParams = new URLSearchParams(window.location.search);
  var hashCode = urlParams.get('id');
  console.log('Extracted ID:', hashCode);


  // $scope.getLocationList = function() {
  //     debugger;
  //     if (hashCode) {
  //         // Call the Apex controller method with the ID
  //         CustomerPortalController.getContactDetail(hashCode, function(result, event) {
  //             debugger;
  //             if (event.status) {
  //                 console.log('Apex Result:', result); // For debugging
  //                 $scope.profileData = result[0];
  //                 $scope.$apply(); // Apply scope changes
  //                 initForm(); 
  //             } else {
  //                 console.error('Error in Apex call:', event.message);
  //             }
  //         });
  //     } else {
  //         console.error('Contact ID is not available in URL');
  //     }
  // };


  function initForm() {


    const isEditing = localStorage.getItem('isEditing') === 'true';
    const fields = document.querySelectorAll('.form-control');
    const button = document.getElementById('editButton');
    const saveButton = document.getElementById('saveButton');

    fields.forEach(field => {
      field.disabled = !isEditing; //Disable all Fields
    });

    button.style.display = isEditing ? 'none' : 'inline-block'; // Toggle Edit Profile button visibility
    saveButton.style.display = isEditing ? 'inline-block' : 'none'; // Toggle Save Profile button visibility
  }

  function toggleEdit() {
    debugger;
    const isEditing = localStorage.getItem('isEditing') === 'true';

    localStorage.setItem('isEditing', !isEditing);
    initForm(); // Update button display and field states
  }

  // function saveProfile() {
  //   debugger;
  //   const formData = {
  //     firstName: document.getElementById('firstName').value,
  //     lastName: document.getElementById('lastName').value,
  //     emailId: document.getElementById('emailId').value,
  //     phoneNumber: document.getElementById('phoneNumber').value,
  //     department: document.getElementById('department').value,
  //     // username: document.getElementById('username').value,
  //     //password: document.getElementById('password').value
  //   };



  //   var urlParams = new URLSearchParams(window.location.search);
  //   var hashCode = urlParams.get('id');
  //   console.log('Extracted ID:', hashCode);

  //   // Call Apex method to save contact details
  //   CustomerPortalController.saveContactDetails(hashCode, formData, function (result, event) {
  //     if (event.status) {
  //       if (result === 'Success') {
  //         console.log('Profile updated successfully:', formData);
  //         alert('Profile updated successfully!');

  //         // Switch back to view mode
  //         localStorage.setItem('isEditing', 'false');
  //         initForm();
  //       } else {
  //         alert(result); // Display the error message
  //       }
  //     } else {
  //       console.error('Apex call failed:', event.message);
  //       alert('Failed to update profile.');
  //     }
  //   });


  //   //alert('Profile updated successfully!');

  //   // Switch back to view mode
  //   //localStorage.setItem('isEditing', 'false');
  //   //initForm(); 
  // }

  // function handleUnload() {
  //     debugger;
  //     localStorage.setItem('isEditing', 'false'); // Reset edit mode flag
  // }

  // Initialize form on page load
  document.addEventListener('DOMContentLoaded', (event) => {
    initForm();
  });

  // Handle page unload
  // window.onbeforeunload = handleUnload;



  var fileExtention;
  $scope.uploadFile = function (type, fileSizeFun, fileSizeMin) {
    return new Promise(function (resolve, reject) {
      debugger;
      maxFileSize = fileSizeFun;
      var file = document.getElementById("profilePic").files[0];
      if (file != undefined) {
        fileName = file.name;
        var typeOfFile = fileName.split(".");
        lengthOfType = typeOfFile.length;
        fileExtention = typeOfFile[lengthOfType - 1];
        if (fileExtention == "jpg" || fileExtention == "jpeg" || fileExtention == "JPEG" || fileExtention == "JPG") {
          debugger;
        } else {
          debugger;
          swal('info', 'Please choose jpg/jpeg file only.', 'info');
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

  $scope.uploadAttachment = function (type) {
    return new Promise(function (resolve, reject) {
      debugger;
      var attachmentBody = "";
      if (fileSize <= positionIndex + chunkSize) {
        attachmentBody = attachment.substring(positionIndex);
        doneUploading = true;
      } else {
        attachmentBody = attachment.substring(positionIndex, positionIndex + chunkSize);
      }
      console.log("Uploading " + attachmentBody.length + " chars of " + fileSize);
      CustomerPortalController.doUploadProfilePic(
        $rootScope.userId, attachmentBody, attachmentName, fileExtention,
        function (result, event) {
          debugger;
          if (event.type === 'exception') {
            console.log("exception");
            console.log(event);
            reject(event.message);
          } else if (event.status, result) {
            if (doneUploading == true) {
              $rootScope.profilePicId = result;
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

  $scope.saveChanges = function () {
    debugger;
    var file = document.getElementById("profilePic").files[0];
    $("#saveChangesBtn").attr("disabled", "disabled");

    // If no file is uploaded, just update the profile
    if (file == undefined) {
      swal('Info', 'Please add something to save changes!', 'info');
      $scope.editable = false;
      $("#saveChangesBtn").removeAttr("disabled");
    } else {
      // If a file is uploaded, first upload the file and then update the profile
      $scope.uploadFile('Profile Picture', '512000', '30720')
        .then(function () {
          // File upload was successful, now update the profile
          swal('Success', 'Profile updated successfully.', 'success');
          $scope.editable = false;
          $("#saveChangesBtn").removeAttr("disabled");
        })
        .catch(function (error) {
          // Handle any errors during file upload
          console.error("Error during upload or save: ", error);
          $("#saveChangesBtn").removeAttr("disabled");
        });
    }
    $scope.$apply();
  }
});



app.directive("ngFileSelect", function(fileReader, $timeout) {
  debugger;
    return {
      scope: {
        ngModel: '='
      },
      link: function($scope, el) {
        function getFile(file) {
          fileReader.readAsDataUrl(file, $scope)
            .then(function(result) {
              $timeout(function() {
                $scope.ngModel = result;
              });
            });
        }

        el.bind("change", function(e) {
          var file = (e.srcElement || e.target).files[0];
          getFile(file);
        });
      }
    };
  });

app.factory("fileReader", function($q, $log) {
  var onLoad = function(reader, deferred, scope) {
    return function() {
      scope.$apply(function() {
        deferred.resolve(reader.result);
      });
    };
  };

  var onError = function(reader, deferred, scope) {
    return function() {
      scope.$apply(function() {
        deferred.reject(reader.result);
      });
    };
  };

  var onProgress = function(reader, scope) {
    return function(event) {
      scope.$broadcast("fileProgress", {
        total: event.total,
        loaded: event.loaded
      });
    };
  };

  var getReader = function(deferred, scope) {
    var reader = new FileReader();
    reader.onload = onLoad(reader, deferred, scope);
    reader.onerror = onError(reader, deferred, scope);
    reader.onprogress = onProgress(reader, scope);
    return reader;
  };

  var readAsDataURL = function(file, scope) {
    var deferred = $q.defer();

    var reader = getReader(deferred, scope);
    reader.readAsDataURL(file);

    return deferred.promise;
  };

  return {
    readAsDataUrl: readAsDataURL
  };
});

app.directive('wrapIntlTelInput', function ($timeout) {
  return {
    restrict: 'A',
    require: '^ngModel',
    link: link
  };

  ////////////////////////////////////////////////////////////

  function link (scope, elem, attrs, ctrl) {
    hookFieldIntoIntlTelInputJqueryPlugin();
    hookFieldIntoJqueryChangeEvent();

    ctrl.$parsers.push(validateFieldAndFormatModelValue);

    elem.on('blur keyup change', applyRenderWhenChange);
    elem.on('$destroy', function () {
      elem.off('blur keyup change');
    });

    $timeout(applyMaskingWhenInitWithPresetPhoneNumber);

    ////////////

    function hookFieldIntoIntlTelInputJqueryPlugin () {
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

    function hookFieldIntoJqueryChangeEvent () {
      elem.change(reformatPhoneNumberWithCountryCode);
    }

    function reformatPhoneNumberWithCountryCode () {
      ctrl.$$parseAndValidate();
    }

    function validateFieldAndFormatModelValue (value) {
      var parsedValue = elem.intlTelInput('getNumber') || value;
      var formattedModelValue = removeInvalidInput(parsedValue);
      ctrl.$setValidity('invalidIntlTel', elem.intlTelInput('isValidNumber'));
      return formattedModelValue;

      ////////////
      
      function removeInvalidInput (input) {
        return input ? input.replace(/(?!^\+?)[^0-9]/g, '') : '';
      }
    }

    function applyMaskingWhenInitWithPresetPhoneNumber () {
      if (elem.val()) {
        elem.intlTelInput('setNumber', elem.val());
        applyRenderWhenChange();
      }
    }

    function applyRenderWhenChange () {
      scope.$apply(function () {
        return ctrl.$setViewValue(elem.val());
      });
    }
  }
});
