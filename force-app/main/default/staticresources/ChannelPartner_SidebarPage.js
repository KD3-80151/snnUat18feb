var workingDaysValues = [];
var userId;
var contId;
var siteURL;
var candidateId;
var getAllEvents;
var eventsOnLoad;
var maxStringSize = 6000000; //Maximum String size is 6,000,000 characters
var maxFileSize = 4350000; //After Base64 Encoding, this is the max file size
var chunkSize = 950000; //Maximum Javascript Remoting message size is 1,000,000 characters
var attachment;
var attachmentName;
var fileSize;
var positionIndex;
var doneUploading;
var blobData;
var applicantName;

var app = angular.module("channelpartner_app");
var sitePrefix = window.location.href.includes("/apex")
  ? "/apex"
  : "/ChannelPartnerPortal";
app.config(function ($routeProvider, $locationProvider) {
  $locationProvider.html5Mode(false).hashPrefix("");
  var rp = $routeProvider;

  for (var i = 0; i < tabValues.length; i++) {
    var pageName = "/" + tabValues[i].Name;

    if (tabValues[i].Apex_class_Name__c != undefined) {
      rp.when(pageName, {
        templateUrl: sitePrefix + pageName,
        controller: tabValues[i].Apex_class_Name__c,
      });
    } else {
      rp.when(pageName, {
        templateUrl: sitePrefix + pageName,
      });
    }
  }
});

app.controller("cpp_dashboard_ctrl", function ($scope, $rootScope, $timeout, $window, $location, $element) {
  debugger;
  $scope.config = {};
  $rootScope.userId = userId;
  if($rootScope.userId == localStorage.getItem('hashCode')){
    $rootScope.activeTab = 'dashboard'; // Ensure the dashboard is active by default
  }else{
    window.location.href = '/apex/ChannelPartner_LoginPage';
  }
  $rootScope.teamHead = localStorage.getItem('teamHead');
  $rootScope.userDetails;
  // $rootScope.activeTab = 0;
  $rootScope.baseUrl = window.origin;
  $scope.isSidebarOpen = true;
  $rootScope.statusValue = statusValue;
  $rootScope.activeTab = 'dashboard'; // Default active section

  $scope.init = function () {
    debugger;
    $rootScope.activeTab = 'dashboard'; // Ensure the dashboard is active by default
  };
  $scope.init();

  $scope.toggleSidebar = function () {
    $scope.isSidebarOpen = !$scope.isSidebarOpen;

    // Auto close sidebar after 2 seconds
    if ($scope.isSidebarOpen) {
      $timeout(function () {
        $scope.isSidebarOpen = false;
      },120000);
    }
  };

  $scope.setActive = function (sectionId) {
    debugger;
    var now = new Date();
    var LastSynced = localStorage.getItem('LogIn Time');

    if (LastSynced) {
      // Convert LastSynced from string to Date
      var lastSyncedDate = new Date(LastSynced);
      
      // Check if the conversion was successful
      if (isNaN(lastSyncedDate.getTime())) {
        console.error("Invalid date format for 'LogIn Time' in localStorage.");
      } else {
        var differenceInMilliseconds = now - lastSyncedDate;
        var differenceInHours = differenceInMilliseconds / (1000 * 60 * 60);
        
        if (differenceInHours > 1) {
          $scope.logout();
        }
      }
    } else {
      console.error("No 'LogIn Time' found in localStorage.");
    }
    $rootScope.activeTab = sectionId;

    // Define the mapping between sectionId and page names
    var pageMapping = {
      'dashboard': 'ChannelPartner_DashboardPage',
      'leads': 'ChannelPartner_LeadPage',
      'siteVisit':'ChannelPartner_SiteVisit',
      'myTeam': 'ChannelPartner_MyTeamPage',
      'marketing': 'ChannelPartner_MarketingPage',
      'brokerageCalculator': 'ChannelPartner_BrokerageCalculatorPage',
      'projects': 'ChannelPartner_ProjectsPage',
      'availability': 'ChannelPartner_AvailabilityPage',
      'tickets': 'ChannelPartner_TicketsPage',
      'events': 'ChannelPartner_EventsPage',
      'aboutUs': 'ChannelPartner_AboutUsPage',
      'termsConditions': 'ChannelPartner_TermsConditionPage',
      'profileDetails': 'ChannelPartner_ProfileDetailsPage'
    };

    // Get the base URL without the hash
    debugger;
    var currentUrl = window.location.href.split('#')[0];

    // Get the page name from the mapping
    var pageName = pageMapping[sectionId];

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
  };

  $scope.loadProfileDetails = function () {
    $rootScope.activeTab = 'profileDetails'; // Show profile details when profile is clicked
  };

  $scope.openLogoutModal = function () {
    var modalElement = document.getElementById('logoutModal');
    var modal = new bootstrap.Modal(modalElement);
    modal.show();
  };

  $scope.logout = function () {
    // Redirect to login page after logout
    debugger;
    ChannelPartner_Controller.logoutUser($rootScope.userId,function(result,event){
      debugger;
      if(event.status && result == 'Success'){
        localStorage.setItem('hashCode','');
        window.location.replace('/apex/ChannelPartner_LoginPage');
        history.pushState(null, null, window.location.href);
        // history.back();
      }else if(result == 'Error'){
        window.location.replace('/apex/ChannelPartner_LoginPage');
        history.pushState(null, null, window.location.href);
        // history.back();
      }else{
        alert('Error logging Out !');
        console.log(result);
      }
      $scope.$apply();
    });
  };

  $scope.loadprofilePage = function (profileName) {
    debugger;
    $rootScope.activeTab = profileName;

    debugger;
    var currentUrl = window.location.href.split('#')[0];

    // Get the page name from the mapping
    var pageName = 'ChannelPartner_ProfileDetailsPage';

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

});
