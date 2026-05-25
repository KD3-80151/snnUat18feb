import { LightningElement, track, wire, api } from 'lwc';
import getAllPickListVal from '@salesforce/apex/receiptController.getAllPickListVal';
import getUnitDetails from '@salesforce/apex/receiptController.getUnitDetails';
import createReceipt from '@salesforce/apex/receiptController.createReceipt';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ReceiptDetailsAndGeneration extends LightningElement {

    @track bankNameOptions = [];
    @track drawOnBankOptions = [];
    @track finTaxOptions = [];
    @track modeOfPaymentOptions = [];
    @track taxTypeOptions = [];
    @track upiProviderOptions = [];
    @track modeIsCheque = false;
    @track modeIsEFT = false;
    @track modeIsDD = false;
    @track modeIsUPI = false;
    @track modeIsTDS = false;
    @track modeIsJV = false;
    @track showUnitDetails = false;
    @track showReceiptSearch = false;
    @track receiptsRelatedToAccList = [];
    @track unitDetails ;
    @track disableUnit = true;
    @track receiptDetails = {
        Account__c:'',
        Unit__c:'',
        Receipt_Date__c: '',
        Amount__c:'',
        Cheque_Number__c:'',
        Cheque_Date__c:'',
        Drawn_on_Bank__c: '',
        Maintenance_Receipt__c:false,
        Preview__c:false,
        Remarks__c:'',
        Fund_Transfer_Date__c:'',
        Bank_Name__c: '',
        Transaction_Reference_Number__c:'',
        DD_Date__c:'',
        DD_Number__c:'',
        Reference_Number__c:'',
        Paid_Date__c:'',
        TDS_Amount__c:'',
        CIN__c:'',
        Challan_Date__c:'',
        BSR_Code__c:'',
        Bank__c:'',
        Branch__c:'',
        PAN_TAN_Number__c:'',
        AY__c:'',
        JV_Reference_Number__c:'',
        JV_Date__c:'',
        Fin_Tax__c: '',
        Mode_Of_Payment__c: 'Cheque',
        Tax_Type__c: '',
        UPI_Provider__c: ''
    };

    objByField = {
        Bank_Name__c: 'Receipt__c',
        Drawn_on_Bank__c: 'Receipt__c',
        Fin_Tax__c: 'Receipt__c',
        Mode_Of_Payment__c: 'Receipt__c',
        Tax_Type__c: 'Receipt__c',
        UPI_Provider__c: 'Receipt__c'
    };

    @track filter = null;
    matchingInfo = {
        primaryField: { fieldPath: "Name" },
        additionalFields: [{ fieldPath: 'Account__c' }],
    };

    connectedCallback(){
        debugger;
        setTimeout(() => {
            this.getAllPicklistValues();
            this.filter={};
        }, 300);
    }

    getAllPicklistValues() {
        debugger;
        getAllPickListVal({ ObjectByField: this.objByField })
            .then(result => {
                debugger;
                this.bankNameOptions        = this.mapToLabelValuePair(result['Bank_Name__c']);
                this.drawOnBankOptions      = this.mapToLabelValuePair(result['Drawn_on_Bank__c']);
                this.finTaxOptions          = this.mapToLabelValuePair(result['Fin_Tax__c']);
                this.modeOfPaymentOptions   = this.mapToLabelValuePair(result['Mode_Of_Payment__c']);
                this.taxTypeOptions         = this.mapToLabelValuePair(result['Tax_Type__c']);
                this.upiProviderOptions     = this.mapToLabelValuePair(result['UPI_Provider__c']);
            })
            .catch(error => {
                console.error('Error==>' + error);
            });
    }

    mapToLabelValuePair(values) {
        return values.map(value => ({
            label: value, value: value
        }));
    }

    selectAccount(event){
        debugger;
        this.receiptDetails.Account__c = event.detail.recordId;
        this.disableUnit = false;
        if(this.receiptDetails.Account__c != null){
            this.getUnitBasedOnClientOrUnit(this.receiptDetails.Account__c, null);
        }
        var today = new Date();
        this.receiptDetails.Receipt_Date__c = this.receiptDetails.Receipt_Date__c != null ? today.toISOString() : this.receiptDetails.Receipt_Date__c;
    }

    

    getUnitBasedOnClientOrUnit(accId, unitId){
        const unitValue = unitId != null ? unitId : null;
        const accValue = accId != null ? accId : null;
        getUnitDetails({accId : accValue, unitId : unitValue})
        .then(result => {
            if(result != null){
                this.receiptDetails.Unit__c = result.Id;
                this.unitDetails = result;
                this.showUnitDetails = this.unitDetails != null ? true : false;
            }
        })
        .catch(error => {
            console.log('Error ==> ' + error);
        });
    }

    selectUnit(event){
        debugger;
        this.receiptDetails.Unit__c = event.detail.recordId != null ? event.detail.recordId : null;
        console.log('selected unit ===> ' + this.receiptDetails.Unit__c);
        this.getUnitBasedOnClientOrUnit(null, this.receiptDetails.Unit__c);
        // if(this.receiptDetails.Unit__c && this.receiptDetails.Account__c !=null){
        //     this.filter = {
        //         criteria: [
        //             {
        //                 fieldPath: 'Account__c',
        //                 operator: 'eq',
        //                 value: this.receiptDetails.Account__c,
        //             }
        //         ],
        //     };
        // }else{
        //     this.filter = {
        //         criteria: []
        //     };
        // }
    }

    handleChange(event){
        debugger;
        const fieldName = event.target.name;
        const fieldValue = event.target.value;
        const checkedValue = event.target.checked;
        if(fieldName == 'Mode_Of_Payment__c'){
            this.modeIsCheque = false;
            this.modeIsEFT = false;
            this.modeIsDD = false;
            this.modeIsUPI = false;
            this.modeIsTDS = false;
            this.modeIsJV = false;

            const modePaymentMapping = {
                'Cheque': 'modeIsCheque',
                 'EFT': 'modeIsEFT',
                 'DD': 'modeIsDD',
                 'UPI': 'modeIsUPI',
                 'TDS': 'modeIsTDS',
                 'JV': 'modeIsJV'
            };

            if(modePaymentMapping[fieldValue]){
                this[modePaymentMapping[fieldValue]] = true;
            }
        }

        if (event.target.type === 'checkbox') {
            this.receiptDetails = {
                ...this.receiptDetails,
                [fieldName]: checkedValue 
            };
        } else {
            this.receiptDetails = {
                ...this.receiptDetails,
                [fieldName]: fieldValue
            };
        }
        console.log('Updated receiptDetails: ', JSON.stringify(this.receiptDetails));
    }

    clearReceiptData() {
        debugger;
        const checkboxFields = ['Maintenance_Receipt__c', 'Preview__c']; 
        Object.keys(this.receiptDetails).forEach(field => {
            if (checkboxFields.includes(field)) {
                this.receiptDetails[field] = false;
            } else {
                this.receiptDetails[field] = '';
            }
        });
    
        console.log('receiptDetails cleared ==> ' + JSON.stringify(this.receiptDetails));
    }
    

    get displayOnChequeorDD() {
        return this.modeIsCheque || this.modeIsDD;
    }

    saveReceipt(){
        createReceipt({receiptRec : this.receiptDetails})
        .then(result => {
            if(result != null){
                this.showToast('Success', 'Receipt created Successfully !!!', 'success');
                this.clearReceiptData();
            }
        })
        .catch(error => {
            this.showToast('Error', error, 'error');
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

}