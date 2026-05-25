var workingDaysValues = [];
var userId, contId, siteURL, candidateId, getAllEvents, eventsOnLoad;
var maxStringSize = 6000000; // Maximum String size is 6,000,000 characters
var maxFileSize = 4350000; // After Base64 Encoding, this is the max file size
var chunkSize = 950000; // Maximum Javascript Remoting message size is 1,000,000 characters
var attachment, attachmentName, fileSize, positionIndex, doneUploading, blobData, applicantName;

var app = angular.module("cp_app");
var sitePrefix = window.location.href.includes("/apex")
  ? "/apex"
  : "/CustomerPortal";
app.config(function ($routeProvider, $locationProvider) {
  $locationProvider.html5Mode(false).hashPrefix("");
  var rp = $routeProvider;

  for (var i = 0; i < tabValues.length; i++) {
    var pageName = "/" + tabValues[i].Name;

    if (tabValues[i].Apex_class_Name__c != undefined) {
      // debugger;
      rp.when(pageName, {
        templateUrl: sitePrefix + pageName,
        controller: tabValues[i].Apex_class_Name__c,
      });
    } else {
      // debugger;
      rp.when(pageName, {
        templateUrl: sitePrefix + pageName,
      });
    }
  }
});

// Controller definition
app.controller("cp_dashboard_ctrl", function ($scope, $rootScope, $timeout, $window, $location) {
  $rootScope.userId = userId;
  if($rootScope.userId == localStorage.getItem('hashCode')){
    $rootScope.activeTab = 'bookings';
  }else{
    window.location.href = '/apex/CustomerPortal_LoginPage';
  }

  $scope.config = {};
  $scope.baseUrl = window.origin;
  $scope.isSidebarOpen = false;

  // Function to handle tab switching
  $scope.setActive = function (sectionId) {
    debugger;
    $rootScope.activeTab = sectionId;

    // Mapping between sectionId and page names
    var pageMapping = {
      listings: "CustomerPortal_ListingsPage",
      bookings: "CustomerPortal_BookingPage",
      siteVisits: "CustomerPortal_SiteVisitsPage",
      projectUpdates: "CustomerPortal_ProjectUpdatesPage",
      invoices: "CustomerPortal_InvoicePage",
      tdsFaqs: "CustomerPortal_TDSFaqPage",
      projectDocuments: "CustomerPortal_ProjectDocumentsPage",
      customerDocuments: "CustomerPortal_CustomerDocumentsPage",
      serviceRequests: "CustomerPortal_ServiceRequestsPage",
      referrals: "CustomerPortal_ReferralsPage",
      faqs: "CustomerPortal_FAQsPage",
      blogs: "CustomerPortal_BlogsPage",
      aboutUs: "CustomerPortal_AboutUsPage",
      termsConditions: "CustomerPortal_TermsConditonPage",
      logOut: "CustomerPortal_LogOutPage",
      profileDetails: 'CustomerPortal_ProfileDetailsPage',                
    };

    var pageName = pageMapping[sectionId];
    if (pageName) {
      var link = document.createElement("a");
      link.href = "#/" + pageName;
      link.click();
    } else {
      console.error("Invalid sectionId:", sectionId);
    }
    if (window.innerWidth <= 768) {
      $scope.isSidebarOpen = false;
    }
  };

  // Initialize with default tab
  $scope.init = function () {
    $rootScope.activeTab = "bookings";
  };

  // Toggle the sidebar open/close
  $scope.toggleSidebar = function () {
    $scope.isSidebarOpen = !$scope.isSidebarOpen;

    // Auto close sidebar after 2 seconds if open
    if ($scope.isSidebarOpen) {
      $timeout(function () {
        $scope.isSidebarOpen = false;
      }, 120000);
    }
  };

  
  $scope.openLogoutModal = function() {
    var modalElement = document.getElementById('logoutModal');
    var modal = new bootstrap.Modal(modalElement);
    modal.show();
};

$scope.Custlogout = function () {
//   debugger;
//   var urlParams = new URLSearchParams(window.location.search);
//   var hashCode = urlParams.get('id'); // Extract the hash code from URL
//   console.log('Extracted ID:', hashCode);

//   if (hashCode) {
//       // Call the clearCode function to delete the hash code
//       $scope.clearCode(hashCode);
//   } else {
//       console.error('ID is not available in URL');
//   }
//   window.history.replaceState(null, null, window.location.pathname);
// };

// Function to clear the hash code
  debugger;
  CustomerPortalController.deleteHashCode($rootScope.userId, function(result, event) {
      debugger;
      if (event.status) {
          // Clear local storage and redirect
          localStorage.setItem('hashCode','');
          // localStorage.clear();
          window.location.replace('/apex/CustomerPortal_LoginPage');
          history.pushState(null, null, window.location.href);
          // $scope.$apply();
      } else {
          console.error('Error in Apex call:', event.message);
      }
      $scope.$apply();
  });
};

$scope.loadProfileDetails = function () {
  $rootScope.activeTab = 'profileDetails'; // Show profile details when profile is clicked
};

$scope.loadprofilePage = function (profileName) {
  debugger;
  $rootScope.activeTab = profileName;

  debugger;
  var currentUrl = window.location.href.split('#')[0];

  // Get the page name from the mapping
  var pageName = 'CustomerPortal_ProfileDetailsPage';

  // Construct the new URL
  if (pageName) {
    debugger;
    var baseUrl = currentUrl.split('#')[0]; // Removes any existing hash part
    var newUrl = `${baseUrl}#/${pageName}`;
    window.location.replace(newUrl);

  } else {
    console.error('Invalid sectionId:', sectionId);
  }
  // Close the sidebar after selecting a menu item on mobile
  if (window.innerWidth <= 768) {
    $scope.isSidebarOpen = false;
  }
  $scope.$apply();
}

$scope.closeSideBar = function(){
  $scope.isSidebarOpen = false;
}
// window.onpopstate = function() {
//   debugger;
//   var urlParams = new URLSearchParams(window.location.search);
//   var hashCode = urlParams.get('id');
//   if (hashCode) {
//       // Redirect to the login page if they attempt to go back to a page with a hash code
//       $window.location.href = "https://site-computing-644--tridasadev.sandbox.my.salesforce-sites.com/CustomerPortal"; 
//   }
// };

$rootScope.replaceAMPinObj = function(obj) {
  if (typeof obj === 'string') {
    return obj.replace(/&amp;/g, '&');
  } else if (Array.isArray(obj)) {
    return obj.map(item => $rootScope.replaceAMPinObj(item));
  } else if (obj !== null && typeof obj === 'object') {
    const newObj = {};
    for (const key in obj) {
      if (obj.hasOwnProperty(key)) {
        newObj[key] = $rootScope.replaceAMPinObj(obj[key]);
      }
    }
    return newObj;
  }
  return obj;
}

$rootScope.replaceAMPinArr = function(value){
  debugger;
  if(value != undefined && value != null && value.length > 0){
    for(var i=0; i<value.length; i++){
      value[i] = $rootScope.replaceAMPinObj(value[i]);;
    }
  }
  return value;
}
});
