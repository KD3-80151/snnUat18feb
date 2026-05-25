import { LightningElement, track, api,wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import createReceipt from '@salesforce/apex/GenerateReceiptDetailsOnOppController.createReceipt';
import checkDuplicate from '@salesforce/apex/GenerateReceiptDetailsOnOppController.checkDuplicate';
import getPicklistValues from '@salesforce/apex/GenerateReceiptDetailsOnOppController.getPicklistValues';
import getAccountValues from '@salesforce/apex/GenerateReceiptDetailsOnOppController.getAccountValues';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class GenerateReceiptDetailsOnOpp extends LightningElement {
    @api recordId;

    @track receiptType;
    @track modeOfPayment;
    @track receiptDate = new Date().toISOString().split('T')[0];
    @track amount;
    @track chequeNumber;
    @track chequeDate;
    @track fundTransferDate;
    @track bankName;
    @track panNo;
    @track transactionReferenceNo;
    @track ddNumber;
    @track ddDate;
    @track referenceNo;
    @track paidDate;
    @track upiProvider;
    @track tdsAmount;
    @track cin;
    @track challanDate;
    @track bsrCode;
    @track drawnOnBank;
    @track jvDate;
    @track jvReferenceNumber;
    @track isDisabled = false;

    @track receiptOptions = [];
    @track modeOfPaymentOptions = [];
    @track bankOptions = [];
    @track upiProviderOptions = [];
    @track accountOptions = [];
     @track selectedAccount;

    isCheque = false;
    isEFT = false;
    isDD = false;
    isUPI = false;
    isTDS = false;
    isJV = false;

    

    connectedCallback() {
        console.log('recordId:', this.recordId); 
        console.log('Component Loaded - connectedCallback');
                this.recordId = this.getIdFromUrl(); 
        this.loadPicklistValues();
        this.fetchAccounts();
    }


    getIdFromUrl() {
        debugger;
        const url = window.location.href;
        const params = new URLSearchParams(url.split('?')[1]);
        return params.get('recordId'); // Correctly extracting the recordId
    }


    loadPicklistValues() {
        debugger;
        console.log('Loading Picklist Values');
        getPicklistValues({ fieldName: 'Type__c' })
            .then(result => {
                 const allOptions = result.map(value => ({ label: value, value }));
                this.receiptOptions = allOptions.filter(option => 
                option.value === 'Credit' || option.value === 'Debit'
            );
                console.log('Receipt Type options loaded:', this.receiptOptions);
            })
            .catch(error => {
                console.error('Error fetching Receipt Type:', error);
            });

        getPicklistValues({ fieldName: 'Mode_of_Payment__c' })
            .then(result => {
                this.modeOfPaymentOptions = result.map(value => ({ label: value, value }));
                console.log('Mode of Payment options loaded:', this.modeOfPaymentOptions);
            })
            .catch(error => {
                console.error('Error fetching Mode of Payment:', error);
            });

        getPicklistValues({ fieldName: 'Drawn_on_Bank__c' })
            .then(result => {
                this.bankOptions = result.map(value => ({ label: value, value }));
                console.log('Bank options loaded:', this.bankOptions);
            })
            .catch(error => {
                console.error('Error fetching Drawn on Bank:', error);
            });

        getPicklistValues({ fieldName: 'UPI_Provider__c' })
            .then(result => {
                this.upiProviderOptions = result.map(value => ({ label: value, value }));
                console.log('UPI Provider options loaded:', this.upiProviderOptions);
            })
            .catch(error => {
                console.error('Error fetching UPI Provider:', error);
            });
            
           
    }

    fetchAccounts(){
        debugger;
         console.log('Record ID:', this.recordId); // Debugging
    if (!this.recordId) {
        console.error('recordId is undefined or null');
        return;
    }

         getAccountValues({ oppId: this.recordId })
            .then(result => {
                debugger;
                if (result) {
                    this.accountOptions = result.map(acc => ({
                        label: acc.Name,
                        value: acc.Id
                    }));
                    console.log('Account Options:', this.accountOptions);
                }
            })
            .catch(error => {
                console.error('Error fetching accounts:', error);
            });

    }

    handleAccountChange(event) {
        debugger;
        this.selectedAccount = event.detail.value;
        console.log('Selected Account:', this.selectedAccount);
    }



    handleInputChange(event) {
        debugger;
        const field = event.target.name;  
        this[field] = event.target.value; 
        console.log(`${field} updated with value: ${this[field]}`);  
    }
    

    handleModeOfPaymentChange(event) {
        this.modeOfPayment = event.target.value;
        console.log(`Mode of Payment changed to: ${this.modeOfPayment}`);

        this.isCheque = this.isEFT = this.isDD = this.isUPI = this.isTDS = this.isJV = false;

    
        switch (this.modeOfPayment) {
            case 'Cheque':
                this.isCheque = true;
                break;
            case 'EFT':
                this.isEFT = true;
                break;
            case 'DD':
                this.isDD = true;
                break;
            case 'UPI':
                this.isUPI = true;
                break;
            case 'TDS':
                this.isTDS = true;
                break;
            case 'JV':
                this.isJV = true;
                break;
            default:
                break;
        }

        console.log('Conditional Fields: ', {
            isCheque: this.isCheque,
            isEFT: this.isEFT,
            isDD: this.isDD,
            isUPI: this.isUPI,
            isTDS: this.isTDS,
            isJV: this.isJV,
        });
    }

    async handleSubmit() {
        debugger;
        console.log('Form Submit initiated');
        let isValid = true;
        let errorMessage = '';

        console.log('Form Data:', {
            amount: this.amount,
            chequeNumber: this.chequeNumber,
            chequeDate: this.chequeDate,
            fundTransferDate: this.fundTransferDate,
            bankName: this.bankName,
            panNo : this.panNo,
            transactionReferenceNo: this.transactionReferenceNo,
            ddNumber: this.ddNumber,
            ddDate: this.ddDate,
            referenceNo: this.referenceNo,
            paidDate: this.paidDate,
            upiProvider: this.upiProvider,
            tdsAmount: this.tdsAmount,
            cin: this.cin,
            challanDate: this.challanDate,
            bsrCode: this.bsrCode,
            drawnOnBank: this.drawnOnBank,
            jvDate: this.jvDate,
            jvReferenceNumber: this.jvReferenceNumber,
            modeOfPayment: this.modeOfPayment
        });

        switch (this.modeOfPayment) {
            case 'Cheque':
                if (!this.amount || !this.chequeNumber || !this.chequeDate || !this.drawnOnBank) {
                    isValid = false;
                    errorMessage = 'Please fill all required fields for Cheque mode.';
                }
                if(this.chequeNumber.length != 6){
                    isValid = false;
                    errorMessage = 'Please enter valid Cheque Number of 6 digits.';
                }
                if(this.chequeNumber.length == 6){
                    isValid = await this.checkDuplicateReceipt(this.recordId, 'Cheque', this.chequeNumber);
                    if(isValid == false){
                        errorMessage = 'Cheque Number already used. Please select another one.';
                    }
                }
                break;
            case 'EFT':
                if (!this.amount || !this.fundTransferDate || !this.bankName || !this.transactionReferenceNo) {
                    isValid = false;
                    errorMessage = 'Please fill all required fields for EFT mode.';
                }
                break;
            case 'DD':
                if (!this.amount || !this.ddNumber || !this.ddDate || !this.drawnOnBank) {
                    isValid = false;
                    errorMessage = 'Please fill all required fields for DD mode.';
                }
                if(this.ddNumber.length != 6){
                    isValid = false;
                    errorMessage = 'Please enter valid DD Number of 6 digits.';
                }
                if( this.ddNumber.length == 6){
                    isValid = await this.checkDuplicateReceipt(this.recordId, 'DD', this.ddNumber);
                    if(isValid == false){
                        errorMessage = 'DD Number already used. Please select another one.';
                    }
                }
                break;
            case 'UPI':
                if (!this.amount || !this.referenceNo || !this.paidDate || !this.upiProvider) {
                    isValid = false;
                    errorMessage = 'Please fill all required fields for UPI mode.';
                }
                break;
            case 'TDS':
                if (!this.tdsAmount || !this.cin || !this.challanDate || !this.bsrCode || !this.bankName) {
                    isValid = false;
                    errorMessage = 'Please fill all required fields for TDS mode.';
                }
                break;
            case 'JV':
                if (!this.amount || !this.jvDate || !this.jvReferenceNumber) {
                    isValid = false;
                    errorMessage = 'Please fill all required fields for JV mode.';
                }
                break;
            default:
                break;
        }

        if (!isValid) {
            console.log('Validation failed:', errorMessage);
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: errorMessage,
                variant: 'error'
            }));
            return;
        }

        const receiptData = {
            opportunityId: this.recordId,
            receiptType: this.receiptType,
            receiptDate: this.receiptDate,
            modeOfPayment: this.modeOfPayment,
            amount: this.amount,
            chequeNumber: this.chequeNumber,
            chequeDate: this.chequeDate,
            fundTransferDate: this.fundTransferDate,
            bankName: this.bankName,
            panNo : this.panNo,
            transactionReferenceNo: this.transactionReferenceNo,
            ddNumber: this.ddNumber,
            ddDate: this.ddDate,
            referenceNo: this.referenceNo,
            paidDate: this.paidDate,
            upiProvider: this.upiProvider,
            tdsAmount: this.tdsAmount,
            cin: this.cin,
            challanDate: this.challanDate,
            bsrCode: this.bsrCode,
            drawnOnBank: this.drawnOnBank,
            jvDate: this.jvDate,
            jvReferenceNumber: this.jvReferenceNumber
        };

        console.log('Submitting receipt data to Apex:', receiptData);

        this.isDisabled = true;
        createReceipt({ receiptData ,accId : this.selectedAccount})
            .then(() => {
                debugger;
                console.log('Receipt created successfully');
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Success',
                    message: 'Receipt created successfully.',
                    variant: 'success'
                }));
                this.isDisabled = false;
                this.resetForm();
                this.dispatchEvent(new CloseActionScreenEvent());
            })
            .catch(error => {
                console.error('Error creating receipt:', error);
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error',
                    message: error.body.message,
                    variant: 'error'
                }));
                this.isDisabled = false;
            });
    }

    checkDuplicateReceipt(oppId, type, uniqueNumber){
        return new Promise((resolve, reject) => {
            if (uniqueNumber) {
                checkDuplicate({ oppId, type, uniqueNumber })
                    .then(result => {
                        console.log('Has Duplicate ---> ', result);
                        resolve(result);
                    })
                    .catch(error => {
                        console.error('Error finding duplicate ---> ', error);
                        reject(error);
                    });
            } else {
                reject('Unique number is not provided');
            }
        });
    }

    resetForm() {
        console.log('Resetting form');
        this.receiptType = '';
        this.receiptDate = null;
        this.modeOfPayment = '';
        this.amount = null;
        this.chequeNumber = '';
        this.chequeDate = null;
        this.fundTransferDate = null;
        this.bankName = '';
        this.panNo ='';
        this.transactionReferenceNo = '';
        this.ddNumber = '';
        this.ddDate = null;
        this.referenceNo = '';
        this.paidDate = null;
        this.upiProvider = '';
        this.tdsAmount = null;
        this.cin = '';
        this.challanDate = null;
        this.bsrCode = '';
        this.drawnOnBank = '';
        this.jvDate = null;
        this.jvReferenceNumber = '';
    }

    closeComponent() {
        // Dispatch an event called "close"
        const closeEvent = new CustomEvent('close');
        this.dispatchEvent(closeEvent);
    }
}