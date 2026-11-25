import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import OPPORTUNITY_OBJECT from '@salesforce/schema/Opportunity';
import LOSS_REASON_FIELD from '@salesforce/schema/Opportunity.Loss_Reason__c';
import saveFollowUp from '@salesforce/apex/customerFollowUpController.saveFollowUp';

export default class CustomerFollowUp extends LightningElement {
    @api recordId; // Task Id (passed by DynamicTaskFromAura_Flow)

    customerResponse = '';
    title = '';
    remarks = '';
    lossReason = '';
    isSaving = false;
    lossReasonOptions = [];

    responseOptions = [
        { label: 'Interested', value: 'Interested' },
        { label: 'Not Interested', value: 'Not Interested' }
    ];

    @wire(getObjectInfo, { objectApiName: OPPORTUNITY_OBJECT })
    oppInfo;

    @wire(getPicklistValues, {
        recordTypeId: '$oppInfo.data.defaultRecordTypeId',
        fieldApiName: LOSS_REASON_FIELD
    })
    wiredLossReasons({ data }) {
        if (data) {
            this.lossReasonOptions = data.values;
        }
    }

    get isInterested() {
        return this.customerResponse === 'Interested';
    }

    get isNotInterested() {
        return this.customerResponse === 'Not Interested';
    }

    get isSaveDisabled() {
        return this.isSaving || !this.customerResponse;
    }

    handleResponseChange(e) {
        this.customerResponse = e.detail.value;
        this.title = '';
        this.remarks = '';
        this.lossReason = '';
    }
    handleTitleChange(e) { this.title = e.detail.value; }
    handleRemarksChange(e) { this.remarks = e.detail.value; }
    handleLossReasonChange(e) { this.lossReason = e.detail.value; }

    validate() {
        const missing = this.isInterested
            ? !this.title?.trim() || !this.remarks?.trim()
            : !this.lossReason || !this.remarks?.trim();
        if (missing) {
            this.showToast('Error', 'Please fill all required fields.', 'error');
        }
        return !missing;
    }

    handleSave() {
        if (!this.validate()) return;
        this.isSaving = true;
        saveFollowUp({
            taskId: this.recordId,
            customerResponse: this.customerResponse,
            title: this.title,
            remarks: this.remarks,
            lossReason: this.lossReason
        })
            .then(() => {
                this.showToast('Success', 'Follow up saved', 'success');
                this.dispatchEvent(new CustomEvent('close'));
            })
            .catch(error => {
                this.showToast('Error', error?.body?.message || 'Something went wrong!', 'error');
            })
            .finally(() => {
                this.isSaving = false;
            });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}