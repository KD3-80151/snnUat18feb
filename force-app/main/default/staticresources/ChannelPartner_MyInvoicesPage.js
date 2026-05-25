angular.module('channelpartner_app').controller('cppmyinvoices_ctrl', function($scope,$rootScope){
    debugger;
    $scope.statusClassMapping = {
        'Pending': 'stage-Pending',
        'Sent': 'stage-Sent',
        'Approved': 'stage-Approved',
        'Rejected': 'stage-Rejected'
    };
    $scope.getMyInvoices = function(){
        debugger;
        ChannelPartner_Controller.getMyInvoices($rootScope.userId,function(result, event) {
            debugger;
            if (event.status &&  result) {
                for(var i=0; i<result.length; i++){
                    result[i].CreatedDate = (result[i].CreatedDate ? new Date(result[i].CreatedDate).toLocaleDateString('en-GB', {
                        day: '2-digit',
                        month: 'short',
                        year: 'numeric'
                    }) : 'Not mentioned');
                }
                $scope.myInvoices = result;
            }else{
                console.log('Error fetching my invoives: '+event.message);
            }
            $scope.$apply();
        });
    }
    $scope.getMyInvoices();
    $scope.openPreview = function(invoice) {
        debugger;
        if (invoice) {
            $scope.invoiceRec = invoice;
            var myModal = new bootstrap.Modal(document.getElementById('detailInvoiceModal'));
            myModal.show();
        } else {
            console.error('No invoice record provided');
        }
    }
    $scope.closeModal = function() {
        debugger;
        $scope.invoiceRec = {};
        $('#detailInvoiceModal').modal('hide');
    }
});