import { LightningElement, api } from 'lwc';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { RefreshEvent } from 'lightning/refresh';
import createCommNotesAndTask from '@salesforce/apex/CreateCommNotesAndTask.createCommNotesAndTask';

export default class CreateCommNotesAndTaskOnLead extends LightningElement {

    @api recordId;

    title = '';
    remarks = '';
    nextFollowUpDateTime;
    isLoading = false;

    handleTitleChange(event){
        this.title = event.target.value;
    }

    handleRemarksChange(event){
        this.remarks = event.target.value;
    }

    handleFollowUpChange(event){
        this.nextFollowUpDateTime = event.target.value;
    }

    validateInputs(){
        return [...this.template.querySelectorAll('lightning-input, lightning-textarea')]
            .reduce((isValid, input) => input.reportValidity() && isValid, true);
    }

    async handleSave(){
        if(!this.validateInputs()){
            return;
        }

        this.isLoading = true;
        try{
            await createCommNotesAndTask({
                recordId: this.recordId,
                title: this.title,
                remarks: this.remarks,
                nextFollowUpDateTime: this.nextFollowUpDateTime || null
            });

            const message = this.nextFollowUpDateTime ? 'Communication Note and Follow Up Task created successfully.'
                : 'Communication Note created successfully.';
            this.showToast('Success', message, 'success');

            await notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
            // Refresh the whole record page (highlights panel, related lists, activity) before the action closes
            this.dispatchEvent(new RefreshEvent());
            this.resetForm();
            this.closeAction();
        }
        catch(error){
            this.showToast('Error', this.reduceError(error), 'error');
        }
        finally{
            this.isLoading = false;
        }
    }

    handleCancel(){
        this.resetForm();
        this.closeAction();
    }

    resetForm(){
        this.title = '';
        this.remarks = '';
        this.nextFollowUpDateTime = null;
    }

    closeAction(){
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    showToast(title, message, variant){
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    reduceError(error){
        if(error?.body?.message){
            return error.body.message;
        }
        return error?.message || 'Something went wrong.';
    }
}
