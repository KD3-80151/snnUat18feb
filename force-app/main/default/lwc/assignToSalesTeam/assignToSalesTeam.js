import { LightningElement, track, api,wire } from 'lwc';
import getUsersWithSalesTeamProfile from '@salesforce/apex/assignToSalesTeamController.getUsersWithSalesTeamProfile';
import getLeadDetails from '@salesforce/apex/assignToSalesTeamController.getLeadDetails';
import updateLeadOwner from '@salesforce/apex/assignToSalesTeamController.updateLeadOwner';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { CurrentPageReference } from 'lightning/navigation';

export default class UserDropdown extends LightningElement {
    recordId;
    @track userOptions = [];
    @track selectedUserId;
    @track IsQualified = false; // Default value
    CurrentPageReference;
     @track type = 'Sales'


    // @wire(CurrentPageReference)
    // setCurrentPageReference(currentPageReference) {
    //     if (currentPageReference) {
    //         this.recordId = currentPageReference.state.recordId; // URL parameter
    //         console.log('Record Id:', this.recordId);
    //         this.handleSave();
    //     }
    // }


    connectedCallback() {
        debugger;
        // Extract the recordId from the URL
        const urlParams = new URLSearchParams(window.location.search);
        this.recordId = urlParams.get('recordId'); // URL parameter

        if (this.recordId) {
            console.log('Record Id:', this.recordId);
            this.handleSave();
        }
    }


    


    // Connected Callback
    
        
        
       // this.fetchUsers(); // Fetch users when the component is initialized
    

    // fetchUsers() {
    //     getUsersWithSalesTeamProfile()
    //         .then(data => {
    //             console.log('Fetched data:', data);
    //             this.userOptions = data.map(user => ({
    //                 label: user.Name,
    //                 value: user.Id
    //             }));
    //             // Fetch lead details after users are loaded
    //             this.getLeadDetail();
    //             console.log(this.userOptions);
    //         })
    //         .catch(error => {
    //             console.error('Error fetching users', error);
    //             this.showToast('Error', 'Error fetching users.', 'error');
    //         });
    // }

    getLeadDetail() {
        debugger;
        console.log('ecordId==>'+this.recordId);
       this.type = 'Sales';
        getLeadDetails({ leadId: this.recordId })
            .then(result => {
                this.IsQualified = result.Is_Qualified__c; // Set the IsQualified value
                console.log('Fetched lead details:', this.IsQualified);
              //  this.handleSave();
            })
            .catch(error => {
                console.error('Error fetching lead details', error);
            });
    }

    handleUserChange(event) {
        this.selectedUserId = event.detail.value;
    }

    handleCheckboxChange(event) {
        this.IsQualified = event.target.checked; // Update IsQualified based on checkbox
    }

    handleSave() {
        debugger;
        // if (!this.selectedUserId) {
        //     this.showToast('Error', 'Please select a user.', 'error');
        //     return;
        // }

        console.log('Lead ID:', this.recordId);
        

        updateLeadOwner({ leadId: this.recordId , type: this.type})
            .then(() => {
                console.log('Lead owner update successful.');
                this.showToast('Success', 'Lead owner updated successfully.', 'success');
                this.refreshComponent(); // Refresh the component to get updated details
                this.dispatchEvent(new CloseActionScreenEvent()); // Close the component
                
            })
            .catch(error => {
                console.error('Error updating lead owner', error);
                this.showToast('Error', 'Error updating lead owner.', 'error');
            });
    }

    refreshComponent() {
        // Re-fetch users and lead details after saving
       // this.fetchUsers(); // Re-fetch users
        this.getLeadDetail(); // Re-fetch lead details
    }

    handleSaveCancelled() {
        this.dispatchEvent(new CloseActionScreenEvent()); // Close the component
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title,
            message,
            variant
        }));
    }
}