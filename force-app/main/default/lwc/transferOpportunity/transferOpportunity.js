import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import updateReceiptOpportunity from '@salesforce/apex/TransferReceiptController.updateReceiptOpportunity';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class TransferOpportunity extends LightningElement {

    @api recordId;
    @track selectedOpportunityId; 
    @track isSaving = false; 

    
    handleLookupChange(event) {
        const opportunityIds = event.detail.value;
        if (Array.isArray(opportunityIds) && opportunityIds.length > 0) {
            this.selectedOpportunityId = opportunityIds[0]; 
        }

    }

    handleSave() {
        debugger;
        if (!this.selectedOpportunityId) {
            this.showToast('Error', 'Please select an Opportunity before saving.', 'error');
            return;
        }

        this.isSaving = true;
        this.updateRecord();
        
        
    }

    updateRecord(){
        debugger;
        updateReceiptOpportunity({
            receiptId: this.recordId,
            opportunityId: this.selectedOpportunityId
        })
            .then(() => {
                debugger;
                this.showToast('Success', 'Receipt updated successfully.', 'success');
                this.closeQuickAction();
            })
            .catch((error) => {
                this.showToast('Error', 'An error occurred while updating the Receipt.', 'error');
                console.error(error);
            })
            .finally(() => {
                this.isSaving = false;
            });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    closeQuickAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleSaveFinished(event) {
        console.log('Record Edit Form finished loading');
    }
}