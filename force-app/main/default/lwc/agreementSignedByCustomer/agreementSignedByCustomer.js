import { LightningElement, api, track } from 'lwc';
import updateRelOppAndCompleteTask from '@salesforce/apex/agreementSignedByCustomerController.updateRelOppAndCompleteTask';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class AgreementSignedByCustomer extends LightningElement {

    @api recordId;
    @track isDisabled = false;

    handleYes(){
        debugger;
        this.isDisabled = true;
        updateRelOppAndCompleteTask({taskId: this.recordId})
        .then(result =>{
            debugger;
            this.isDisabled = false;
            this.showToast('Success', 'Agreement Signed by Customer', 'success');
            this.closeComponent();
        })
        .catch(error =>{
            this.isDisabled = false;
            console.log('Error:', JSON.stringify(error));
            this.showToast('Error', 'Something went wrong!', 'error');
        })
    }

    handleNo(){
        debugger;
        this.showToast('Info', 'Agreement not Signed by Customer', 'info');
        this.closeComponent();
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(event);
    }

    closeAction() {
        debugger;
            const closeEvent = new CustomEvent('close', {
            bubbles: true,
            composed: true
        });
        this.dispatchEvent(closeEvent);
    }

    closeComponent() {
        // Dispatch an event called "close"
        const closeEvent = new CustomEvent('close');
        this.dispatchEvent(closeEvent);
    }
}