import { api, LightningElement, track, wire } from 'lwc';
import getCRMUsers from '@salesforce/apex/opportunityApprovalProcess.getCRMUsers';
import submitForApproval from '@salesforce/apex/opportunityApprovalProcess.submitForApproval';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class OpportunityApprovalProcess extends LightningElement {

    @api recordId; // Record ID of the Opportunity
    @track userOptions = [];
    @track selectedUserId;
    @track isDisabled = false;

    // async connectedCallback() {
    //     debugger;
    //     this.fetchCRMUsers();
    // }

    // Method to fetch CRM users imperatively
    async fetchCRMUsers() {
        debugger;
        try {
            const data = await getCRMUsers({taskId: this.recordId});
            if (data) {
                
                // this.userOptions = data.map((user) => {
                //     return { label: user.Name, value: user.Id };
                // });
                // this.selectedUserId = this.userOptions[0].value; 
                this.selectedUserId = data;
            }
        } catch (error) {
            this.error = error;
            console.error('Error fetching CRM users:', error);
        }
    }

    handleUserChange(event) {
        this.selectedUserId = event.target.value;
    }

    async handleSubmit() {
        debugger;
        this.isDisabled = true;
        await this.fetchCRMUsers();
        submitForApproval({ taskId: this.recordId, selectedUserId: this.selectedUserId })
            .then(() => {
                this.isDisabled = false;
                this.showToast('Success', 'Approval submitted successfully', 'success');
                this.closeComponent();
                this.closeAction();
                //this.dispatchEvent(new CloseActionScreenEvent()); // Close the Quick Action modal
            })
            .catch(error => {
                this.isDisabled = false;
                this.showToast('Error: Approval is already in progress', error.body.message, 'error');
                console.error(error);
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

    closeAction(){  
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    closeComponent() {
        // Dispatch an event called "close"
        const closeEvent = new CustomEvent('close');
        this.dispatchEvent(closeEvent);
    }
}