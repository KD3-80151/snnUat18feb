import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import updateOpportunityStage from '@salesforce/apex/PaymentConfirmationController.updateOpportunityStage';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
export default class PaymentConfirmation extends LightningElement {

    @api recordId;
    isLoading = false;
    buttonLabel = 'Move to Payment Confirmation';

    connectedCallback() {
        debugger;
        console.log('this.recordId==>' + this.recordId);
    }

    handleMoveToPaymentConfirmation() {
        debugger;
        this.isLoading = true;
        updateOpportunityStage({ taskId: this.recordId })
            .then((result) => {
                // Success: Handle result if needed
                console.log('Stage moved to Payment Confirmation');
                this.showToast('Success', 'Payment Stage Changed  Successfully..', 'success');
                this.isLoading = false;
                this.closeComponent();
            })
            .catch((error) => {
                // Error: Handle error if needed
                this.showToast('Error', 'Something went wrong!', 'error');
                console.error('Error:', error);
                this.isLoading = false;
            });
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(event);
    }

    closeComponent() {
        // Dispatch an event called "close"
        const closeEvent = new CustomEvent('close');
        this.dispatchEvent(closeEvent);
    }
}