//import { refreshApex } from '@salesforce/apex';
import getOppDetails from '@salesforce/apex/submitCourierDetailsController.getOppDetails';
import saveOppResult from '@salesforce/apex/submitCourierDetailsController.saveOppResult';
import { CloseActionScreenEvent } from "lightning/actions";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { LightningElement, api, track, wire } from 'lwc';

export default class OpportunityCourierDetails extends LightningElement {
    //@api recordId;
    @track courierDateValue = '';
    @track courierCompanyValue = '';
    @track courierDocketNumber = '';
    @track dateValue = '';
    @track companyValue = '';
    @track docketNumber = '';
    @track isEditOptionVisible = false;
    @track taskRecordId;
    @track oppId;
    @track value = '';
    @track OnlineMode = false;
    @api set recordId(value) {
        this.taskRecordId = value;
        console.log('this.taskRecordId ', this.taskRecordId);
    }
    get recordId() {
        return this.taskRecordId;
    }

    get modeOptions() {
        return [
            { label: 'Online', value: 'Online' },
            { label: 'Offline', value: 'Offline' },

        ];
    }

    handleModeChange(event) {
        debugger;
        this.value = event.detail.value;
        if (this.value == 'Online') {
            this.OnlineMode = true;
        } else {
            this.OnlineMode = false;
        }

    }

    handleChange(event) {
        debugger;
        let { name, value } = event.target;
        if (name == 'courierDate') {
            this.courierDateValue = value;
        } else if (name == 'courierCompany') {
            this.courierCompanyValue = value;
        } else if (name == 'docketNumber') {
            this.courierDocketNumber = value;
        }
    }

    @wire(getOppDetails, { taskId: '$taskRecordId' })
    oppData({ data, error }) {
        debugger;
        if (data) {
            if (data.Company__c && data.Docket_Number__c && data.Courier_Date__c) {
                this.isEditOptionVisible = true;
                this.OnlineMode = true;

            } else {
                this.OnlineMode = false;
                this.isEditOptionVisible = false;
            }

            this.courierCompanyValue = data.Company__c;
            this.courierDocketNumber = data.Docket_Number__c;
            this.courierDateValue = data.Courier_Date__c;
            this.oppId = data.Id;
            console.log(this.isEditOptionVisible);
        } else if (error) {
            console.log('Error ===> ' + error);
        }
    }

    handleSave() {
        debugger;
        /* if(this.emailValue == null || this.emailValue == ''){
            this.showToast('Error', 'Email is required to proceed!!!', 'error');
            return;
        }*/
        if (
            (this.courierDateValue == 0 ||
                !this.courierCompanyValue ||
                !this.courierDocketNumber) &&
            this.value === 'Online'
        ) {
            this.showToast('Error', 'Fill all the Required fields!!!', 'error');
            return;
        } else {
            this.isEditOptionVisible = true;
            saveOppResult({ courierDateValue: this.courierDateValue, courierCompanyValue: this.courierCompanyValue, courierDocketNumber: this.courierDocketNumber, oppId: this.oppId, taskId: this.taskRecordId })
                .then(result => {
                    this.isEditOptionVisible = false;
                    this.showToast('Success', 'Courier Details Submitted Successfully', 'Success');
                    console.log('Was Clicked!');
                    this.closeComponent();
                })
                .catch(error => {
                    this.isEditOptionVisible = false;
                });
        }
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }

    handleClick() {
        console.log('Was Clicked!');
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    closeComponent() {
        // Dispatch an event called "close"
        const closeEvent = new CustomEvent('close');
        this.dispatchEvent(closeEvent);
    }
}