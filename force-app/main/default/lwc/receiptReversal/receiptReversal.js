import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getRelReceipts from '@salesforce/apex/ReceiptReversalController.getRelReceipts';
import saveReceiptChanges from '@salesforce/apex/ReceiptReversalController.saveReceiptChanges';

export default class ReceiptReversal extends LightningElement {
    @track showTable = false;
    @track isShowModal = false;
    @track selectedUnitId;
    @track receiptNumOptions = [];
    @track receipts = [];
    @track receiptReversalData = [];
    @track selectedreceiptsArr = [];
    @track selectedReceipt;
    @track chequeNum;
    @track clientName;
    @track chequeDate;
    @track bouncedDate;
    @track bouncedReason;
    @track typeOfCheque;
    @track selectedRcpt;
    @track isSaveDisabled = false;

    handleChangeUnit(event) {
        debugger;
        // this.selectedReceipt = null;
        // this.chequeNum = null;
        // this.chequeDate = null;
        // this.receiptNumOptions = [];
        // this.receipts = [];
        // this.clientName = null;
        // this.showTable = false;
        // this.receiptReversalData = [];
        this.handleClear();
        this.selectedUnitId = event.detail.id;
        console.log('selectedUnitId ===> ' + this.selectedUnitId);
        this.getReceiptRecords();
    }

    getReceiptRecords() {
        debugger;
        return new Promise((resolve, reject) => {
            getRelReceipts({ unitId: this.selectedUnitId })
                .then((result) => {
                    console.log('Result:', JSON.stringify(result));
                    this.receipts = result.relatedReceipts;
                    this.receiptNumOptions = result.relatedReceipts.map((receipt) => {
                        return { label: receipt.Receipt_Number__c, value: receipt.Id };
                    });
                    this.clientName = result.clientName;
                    resolve();
                })
                .catch((error) => {
                    console.error('Error:', JSON.stringify(error));
                    reject(error);
                });
        });
    }

    handleChangeReceiptNum(event){
        debugger;
        this.selectedRcpt = event.detail.value;
        console.log('Selected Receipt Option ===> ' + this.selectedRcpt);
        this.selectedReceipt = this.receipts.find(receipt => receipt.Id === event.detail.value);
        console.log('selectedReceipt ===> ' + JSON.stringify(this.selectedReceipt));
        this.chequeNum = this.selectedReceipt.Cheque_Number__c;
        this.chequeDate = this.selectedReceipt.Cheque_Date__c;
        console.log('Cheque Number ===> ' + this.chequeNum);
        console.log('Cheque Date ===> ' + this.chequeDate);
    }

    handleSearch() {
        debugger;
        this.receiptReversalData = [];
        if (this.selectedUnitId && this.clientName && this.selectedReceipt && this.chequeNum && this.chequeDate) {
            this.receiptReversalData.push({ ...this.selectedReceipt, isChecked: false });
            this.showTable = true;
        } else if(this.selectedReceipt == null && this.selectedUnitId){
            this.receiptReversalData = this.receipts.map(receipt => ({ ...receipt, isChecked: false }));
            this.showTable = true;
        } else {
            const event = new ShowToastEvent({
                title: 'Error',
                message: 'Please select all required fields.',
                variant: 'error',
            });
            this.dispatchEvent(event);
        }
    }

    handleSelectAll(event) {
        debugger;
        const isChecked = event.target.checked;
        this.receiptReversalData = this.receiptReversalData.map(row => {
            row.isChecked = isChecked;
            return row;
        });
        const checkboxes = this.template.querySelectorAll('input[data-id]');
        checkboxes.forEach(checkbox => {
            checkbox.checked = isChecked;
        });
    }

    handleCheck(event) {
        debugger;
        var selectedReceiptId = event.target.dataset.id;
        console.log('Selected Receipt Id:', selectedReceiptId);
        this.receiptReversalData.find(receipt => receipt.Id === selectedReceiptId).isChecked = event.target.checked;
        console.log('receipts:', JSON.stringify(this.receiptReversalData));
    }

    handleInputChange(event) {
        debugger;
        const field = event.target.label;
        if (field === 'Bounced Date') {
            this.bouncedDate = event.target.value;
        } else if (field === 'Bounced Reason') {
            this.bouncedReason = event.target.value;
        }
    }

    handleChequeChange(event) {
        if(event.target.value == 'Same Cheque'){
            this.typeOfCheque = 'Same Cheque';
        }else if(event.target.value == 'New Cheque'){
            this.typeOfCheque = 'New Cheque';
        }
    }

    handleApply() {
        debugger;
        this.selectedreceiptsArr = [];
        this.selectedreceiptsArr = this.receiptReversalData.filter(receipt => receipt.isChecked);
        console.log('Selected Receipts:', JSON.stringify(this.selectedreceiptsArr));
        if(this.selectedreceiptsArr.length == 0){
            const event = new ShowToastEvent({
                title: 'Error',
                message: 'Please select at least one receipt.',
                variant: 'error',
            });
            this.dispatchEvent(event);
        }
        this.isShowModal = true;
    }

    handleSave() {
        debugger;
        this.isSaveDisabled = true;
        if (this.bouncedDate == null || this.bouncedDate == undefined || this.bouncedDate == '') {
            const event = new ShowToastEvent({
                title: 'Error',
                message: 'Bounced Date is required.',
                variant: 'error',
            });
            this.dispatchEvent(event);
            this.isSaveDisabled = false;
        }else{
            saveReceiptChanges({ receipts: this.selectedreceiptsArr, typeOfCheque: this.typeOfCheque, bouncedDate: this.bouncedDate, bouncedReason: this.bouncedReason })
            .then((result) => {
                console.log('Result:', JSON.stringify(result));
                if (result.includes('SUCCESS')){
                    const event = new ShowToastEvent({
                        title: 'SUCCESS',
                        message: 'Receipt Reversal successfully saved.',
                        variant: 'success',
                    });
                    this.dispatchEvent(event);
                    this.getReceiptRecords().then(() => this.handleSearch());
                    this.isShowModal = false;
                }else if (result.includes('ERROR')){
                    const event = new ShowToastEvent({
                        title: 'ERROR',
                        message: 'Receipt Reversal not saved. ',
                        variant: 'error',
                    });
                    this.dispatchEvent(event);
                }
                this.isSaveDisabled = false;
            })
            .catch((error) => {
                const event = new ShowToastEvent({
                    title: 'ERROR',
                    message: 'Receipt Reversal not saved. ',
                    variant: 'error',
                });
                this.dispatchEvent(event);
                console.error('Error:', JSON.stringify(error));
                this.isSaveDisabled = false;
            });
        }
    }

    hideModalBox() {
        debugger;
        this.bouncedDate = null;
        this.bouncedReason = null;
        this.typeOfCheque = null;
        this.isShowModal = false;
    }

    handleClear() {
        debugger;
        this.selectedUnitId = null;
        this.selectedReceipt = null;
        this.chequeNum = null;
        this.chequeDate = null;
        this.receiptNumOptions = [];
        this.receipts = [];
        this.clientName = null;
        this.showTable = false;
        this.receiptReversalData = [];
    }
}