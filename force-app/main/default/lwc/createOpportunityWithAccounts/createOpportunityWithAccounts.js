import { LightningElement, track, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';

import { getRecord } from 'lightning/uiRecordApi';
import createOpportunity from '@salesforce/apex/editPricingOnOpportunityController.createOpportunity';
import createContactFromAccount from '@salesforce/apex/editPricingOnOpportunityController.createContactFromAccount';

import OPPORTUNITY_FIELD from '@salesforce/schema/Case.Opportunity__c';

export default class CreateAccountOrSelect extends LightningElement {
    @api recordId;
    @track currentAccountId;
    @track opportunityId;
    optionSelected = '';

    get accountOptions() {
        return [
            { label: 'Create New Account', value: 'createNew' },
            { label: 'Fetch Existing Account', value: 'fetchExisting' }
        ];
    }
    get isCreateNew() {
        return this.optionSelected === 'createNew';
    }
    
    get isFetchExisting() {
        return this.optionSelected === 'fetchExisting';
    }
    
    @wire(getRecord, { recordId: '$recordId', fields: [OPPORTUNITY_FIELD] })
    wiredCase({ data, error }) {
        if (data) {
            this.opportunityId = data.fields.Opportunity__c.value;
            console.log('Related Opportunity Id:', this.opportunityId);
        } else if (error) {
            console.error('Error fetching Case record:', error);
        }
    }

    handleOptionChange(event) {
        debugger;
        this.optionSelected = event.detail.value;
        console.log('Selected option:', this.optionSelected); 
    }

    handleAccountChange(event) {
        debugger;
        this.currentAccountId = event.detail.recordId;
    }

    handleSave() {
        debugger;
        if (!this.currentAccountId) {
            this.showToast('Error', 'Please select a valid Account and ensure related Opportunity exists.', 'error');
            return;
        }

        if (!this.opportunityId) {
            this.showToast('Error', 'No related Opportunity found on this Case.', 'error');
            return;
        }

        createOpportunity({
            currentAccountId: this.currentAccountId,
            recordId: this.opportunityId
        })
            .then(() => {
                this.showToast('Success', 'Opportunity ownership transferred!', 'success');
                this.dispatchEvent(new CloseActionScreenEvent());
            })
            .catch(error => {
                this.showToast('Error', error.body?.message || error.message, 'error');
            });
    }

    handleAccountCreated(event) {
        debugger;
        this.currentAccountId = event.detail.id;
        this.showToast('Success', 'Account created successfully. Creating contact...', 'success');

        createContactFromAccount({ accountId: this.currentAccountId })
            .then(() => {
                return createOpportunity({
                    currentAccountId: this.currentAccountId,
                    recordId: this.opportunityId
                });
            })
            .then(() => {
                this.showToast('Success', 'Opportunity updated and Contact created successfully!', 'success');
                this.dispatchEvent(new CloseActionScreenEvent());
            })
            .catch(error => {
                this.showToast('Error', error.body?.message || error.message, 'error');
            });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}