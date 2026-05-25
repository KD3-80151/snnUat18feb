import { LightningElement, api, track } from 'lwc';
import fetchReceipts from '@salesforce/apex/receiptController.fetchReceipts';
import { NavigationMixin } from 'lightning/navigation';

export default class ReceiptRelatedToAccount extends NavigationMixin(LightningElement) {
    @api accId = '';
    @api unitId = '';
    @track showReceiptSearch = false;
    @track receiptsRelatedToAccList = [];
    @track noRecipts = false;

    connectedCallback(){
        debugger;
        console.log('accountId ==> ' + this.accId);
        this.fetchReceiptsRelatedToAcc();
    }

    handleClickReceipt(event){
        const receiptId = event.currentTarget.dataset.id;
        console.log('receiptId ===> ' + receiptId);
        const baseUrl = window.location.origin;
        const recordUrl = `${baseUrl}/lightning/r/Receipt__c/${receiptId}/view`;
        window.open(recordUrl, '_blank');

        // this[NavigationMixin.Navigate]({
        //     type: 'standard__recordPage',
        //     attributes: {
        //         recordId: receiptId,
        //         objectApiName: 'Receipt__c', 
        //         actionName: 'view'
        //     }
        // });
    }

    fetchReceiptsRelatedToAcc(){
        fetchReceipts({accId : this.accId, unitId : this.unitId})
        .then(result => {
            if(result != null){
                this.receiptsRelatedToAccList = result;
                this.showReceiptSearch = true;
                setTimeout(() => this.template.querySelector('c-dynamic-pagination').setPagination(10));
                this.noRecipts = false;

                this.receiptsRelatedToAccList = this.receiptsRelatedToAccList.map((item, index) => ({
                    ...item, index : index + 1
                }));
            }else{
                this.noRecipts = true;
            }
        })
        .catch(error => {
            console.log('Error ==> ' + error);
        });
    }

    @track paginatedList = [];
    jobPaginationCallback(event) {
        debugger;
        this.paginatedList = event.detail.recordToDisplay;
        console.log('paginatedList==>', this.paginatedList);
    }
}