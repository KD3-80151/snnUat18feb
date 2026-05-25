angular.module('channelpartner_app').controller('cppavailability_ctrl', function($scope,$rootScope){
    debugger;
console.log($rootScope);
// $rootScope.activeTab = 0;

function showAvailabilitypage() {
    document.getElementById('availabilitypageContent').style.display = 'none';
    document.getElementById('availabilityContent').style.display = 'block';
}
function showAvailabilityMainPage() {
    document.getElementById('availabilityContent').style.display = 'none';
    document.getElementById('availabilitypageContent').style.display = 'block';
}

function openShareModal() {
    var shareModal = new bootstrap.Modal(document.getElementById('shareModal'));
    shareModal.show();
}
});