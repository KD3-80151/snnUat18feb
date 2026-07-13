import { LightningElement, api, track } from 'lwc';
import submitForApproval from '@salesforce/apex/DeleteOppApprovalController.submitForApproval';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class DeleteRelatedOpportunityApproval extends LightningElement {
    @api recordId;
    @track isLoading = false;

    handleSubmit() {
        this.isLoading = true;

        submitForApproval({ opportunityId: this.recordId })
            .then(() => {
                this.showToast('Success', 'Delete approval submitted successfully.', 'success');
                this.closeAction();
            })
            .catch((error) => {
                const message = error?.body?.message || 'Unable to submit delete approval.';
                this.showToast('Error', message, 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    closeAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }
}
