import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import verifyCustomerData from '@salesforce/apex/customerDataVerifiedController.verifyCustomerData';

export default class CustomerDataVerified extends LightningElement {

    @api recordId;
    @track isDisabled = false;

    handleVerify(){
        debugger;
        this.isDisabled = true;
        verifyCustomerData({taskId: this.recordId})
        .then(result =>{
            debugger;
            this.isDisabled = false;;
            this.showToast('Success', 'Customer Data Verified', 'success');
            this.closeComponent();
        })
        .catch(error =>{
            this.isDisabled = false;;
            console.log('Error:', JSON.stringify(error));
            this.showToast('Error', 'Something went wrong!', 'error');
        })
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
            const closeEvent = new CloseActionScreenEvent('close', {
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