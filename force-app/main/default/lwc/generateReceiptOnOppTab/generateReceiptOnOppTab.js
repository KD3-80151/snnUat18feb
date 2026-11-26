import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import OPP_STAGE_FIELD from '@salesforce/schema/Opportunity.StageName';
import createReceipt from '@salesforce/apex/GenerateReceiptDetailsOnOppController.createReceipt';
import checkDuplicate from '@salesforce/apex/GenerateReceiptDetailsOnOppController.checkDuplicate';
import getPicklistValues from '@salesforce/apex/GenerateReceiptDetailsOnOppController.getPicklistValues';
import getDebitPaymentSchedules from '@salesforce/apex/GenerateReceiptDetailsOnOppController.getDebitPaymentSchedules';
import hasTokenAmountReceipt from '@salesforce/apex/GenerateReceiptDetailsOnOppController.hasTokenAmountReceipt';

// Receipt Date rules: no future date, and at most 3 days in the past (local date).
const RECEIPT_DATE_PAST_DAYS = 3;
const toLocalIsoDate = (d) => {
    const pad = (n) => String(n).padStart(2, '0');
    return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
};
const receiptDateMaxValue = () => toLocalIsoDate(new Date());
const receiptDateMinValue = () => {
    const d = new Date();
    d.setDate(d.getDate() - RECEIPT_DATE_PAST_DAYS);
    return toLocalIsoDate(d);
};
const receiptDateError = (value) => {
    if (!value) return 'Please select Receipt Date.';
    if (value > receiptDateMaxValue()) return 'Receipt Date cannot be a future date.';
    if (value < receiptDateMinValue()) return `Receipt Date cannot be more than ${RECEIPT_DATE_PAST_DAYS} days in the past.`;
    return null;
};


const PAN_REGEX = /^[A-Za-z]{5}[0-9]{4}[A-Za-z]{1}$/;
const OPPORTUNITY_KEY_PREFIX = '006';
const DEFAULT_RECEIPT_TYPE = 'Tax Invoice';
const CLOSED_LOST_STAGE = 'Closed Lost';

const today = () => toLocalIsoDate(new Date());

export default class GenerateReceiptOnOppTab extends LightningElement {
    /** Populated automatically when dropped on an Opportunity record page. */
    @api recordId;

    // Selected Opportunity (from record picker / record page / URL)
    selectedOpportunityId;

    // Record picker configuration
    opportunityDisplayInfo = {
        primaryField: 'Name',
        additionalFields: ['StageName']
    };
    opportunityMatchingInfo = {
        primaryField: { fieldPath: 'Name' }
    };
    // Hide Closed Lost opportunities from the picker search results
    opportunityFilter = {
        criteria: [
            { fieldPath: 'StageName', operator: 'ne', value: CLOSED_LOST_STAGE }
        ]
    };

    // Stage of the selected opportunity (guards record-page / URL prefill, which bypass the picker filter)
    selectedOpportunityStage;

    @wire(getRecord, { recordId: '$selectedOpportunityId', fields: [OPP_STAGE_FIELD] })
    wiredOpportunity({ data, error }) {
        if (data) {
            this.selectedOpportunityStage = getFieldValue(data, OPP_STAGE_FIELD);
        } else if (error) {
            this.selectedOpportunityStage = null;
            console.error('Error fetching opportunity stage:', error);
        }
    }

    // Form fields
    receiptType = DEFAULT_RECEIPT_TYPE;
    modeOfPayment;
    receiptDate = today();
    amount;
    chequeNumber;
    chequeDate;
    fundTransferDate;
    bankName;
    panNo;
    transactionReferenceNo;
    ddNumber;
    ddDate;
    referenceNo;
    paidDate;
    upiProvider;
    tdsAmount;
    cin;
    challanDate;
    bsrCode;
    drawnOnBank;
    jvDate;
    jvReferenceNumber;
    selectedAccount;

    isSubmitting = false;

    // Picklists
    @track receiptOptions = [];
    @track modeOfPaymentOptions = [];
    @track bankOptions = [];
    @track upiProviderOptions = [];

    // Against debit
    isAgainstDebit = false;
    showDebitScheduleModal = false;
    @track debitPaymentScheduleOptions = [];
    selectedDebitPaymentScheduleId;

    // Token amount
    isTokenAmount = false;
    // true when the selected opportunity already has a Token Amount receipt -> checkbox checked & frozen
    isTokenAmountLocked = false;
    isTokenStatusLoading = false;

    connectedCallback() {
        const initialId = this.recordId || this.getIdFromUrl();
        if (initialId && String(initialId).startsWith(OPPORTUNITY_KEY_PREFIX)) {
            this.selectedOpportunityId = initialId;
            this.refreshTokenStatus();
        }
        this.loadPicklistValues();
    }

    get isTokenAmountDisabled() {
        return this.isTokenAmountLocked || this.isTokenStatusLoading;
    }

    get tokenAmountHelpText() {
        return this.isTokenAmountLocked
            ? 'A Token Amount receipt already exists for this Opportunity.'
            : '';
    }

    refreshTokenStatus() {
        const oppId = this.selectedOpportunityId;
        this.isTokenAmountLocked = false;
        this.isTokenAmount = false;
        if (!oppId) {
            return Promise.resolve();
        }

        this.isTokenStatusLoading = true;
        return hasTokenAmountReceipt({ oppId })
            .then(hasToken => {
                // Ignore stale responses if the user switched opportunity meanwhile
                if (oppId !== this.selectedOpportunityId) {
                    return;
                }
                this.isTokenAmountLocked = !!hasToken;
                this.isTokenAmount = !!hasToken;
            })
            .catch(error => {
                console.error('Error checking token amount receipt:', error);
            })
            .finally(() => {
                if (oppId === this.selectedOpportunityId) {
                    this.isTokenStatusLoading = false;
                }
            });
    }

    handleTokenAmountChange(event) {
        if (this.isTokenAmountLocked) {
            return;
        }
        this.isTokenAmount = event.target.checked;
    }

    getIdFromUrl() {
        try {
            const params = new URLSearchParams(window.location.search);
            return params.get('recordId') || params.get('c__recordId');
        } catch (e) {
            return null;
        }
    }

    // ---------- Getters ----------

    get isClosedLost() {
        return !!this.selectedOpportunityId && this.selectedOpportunityStage === CLOSED_LOST_STAGE;
    }

    get hasOpportunity() {
        return !!this.selectedOpportunityId && !this.isClosedLost;
    }

    get isSubmitDisabled() {
        return this.isSubmitting || !this.hasOpportunity;
    }

    get isCheque() { return this.modeOfPayment === 'Cheque'; }
    get isEFT() { return this.modeOfPayment === 'EFT'; }
    get isDD() { return this.modeOfPayment === 'DD'; }
    get isUPI() { return this.modeOfPayment === 'UPI'; }
    get isTDS() { return this.modeOfPayment === 'TDS'; }
    get isJV() { return this.modeOfPayment === 'JV'; }
    get isFundTransfer() { return this.modeOfPayment === 'FUNDTRANSFER'; }

    get selectedDebitPaymentSchedule() {
        return this.debitPaymentScheduleOptions.find(
            option => option.value === this.selectedDebitPaymentScheduleId
        );
    }

    get againstDebitHelpText() {
        if (!this.isAgainstDebit || !this.selectedDebitPaymentSchedule) {
            return '';
        }
        return `Selected debit schedule due amount: ${this.selectedDebitPaymentSchedule.totalDueAmount}`;
    }

    // ---------- Data loading ----------

    loadPicklistValues() {
        const load = (fieldName, target) =>
            getPicklistValues({ fieldName })
                .then(result => {
                    this[target] = (result || []).map(value => ({ label: value, value }));
                })
                .catch(error => {
                    console.error(`Error fetching ${fieldName}:`, error);
                });

        load('Type__c', 'receiptOptions');
        load('Mode_of_Payment__c', 'modeOfPaymentOptions');
        load('Drawn_on_Bank__c', 'bankOptions');
        load('UPI_Provider__c', 'upiProviderOptions');
    }

    // ---------- Handlers ----------

    handleOpportunityChange(event) {
        const newId = event.detail.recordId || null;
        if (newId === this.selectedOpportunityId) {
            return;
        }
        this.selectedOpportunityId = newId;
        this.selectedOpportunityStage = null;
        // Debit schedules belong to the previous opportunity - clear them.
        this.clearDebitSelection();
        this.refreshTokenStatus();
    }

    get receiptDateMin() {
        return receiptDateMinValue();
    }

    get receiptDateMax() {
        return receiptDateMaxValue();
    }

    handleInputChange(event) {
        const field = event.target.name;
        let value = event.target.value;
        if (field === 'panNo' && value) {
            value = value.toUpperCase();
        }
        this[field] = value;
    }

    handleModeOfPaymentChange(event) {
        this.modeOfPayment = event.detail.value;
    }

    handleAgainstDebitChange(event) {
        this.isAgainstDebit = event.target.checked;
        if (this.isAgainstDebit) {
            this.openDebitScheduleModal();
        } else {
            this.clearDebitSelection();
        }
    }

    openDebitScheduleModal() {
        if (!this.hasOpportunity) {
            this.isAgainstDebit = false;
            this.showToast('Error', 'Please select an Opportunity first.', 'error');
            return;
        }

        getDebitPaymentSchedules({ oppId: this.selectedOpportunityId })
            .then(result => {
                this.debitPaymentScheduleOptions = result || [];
                if (this.debitPaymentScheduleOptions.length === 0) {
                    this.isAgainstDebit = false;
                    this.showToast('Info', 'No debit payment schedules found for this opportunity.', 'info');
                    return;
                }
                this.showDebitScheduleModal = true;
            })
            .catch(error => {
                console.error('Error fetching debit payment schedules:', error);
                this.isAgainstDebit = false;
                this.showToast('Error', error?.body?.message || 'Unable to fetch debit payment schedules.', 'error');
            });
    }

    handleDebitScheduleSelection(event) {
        this.selectedDebitPaymentScheduleId = event.detail.value;
    }

    handleDebitModalCancel() {
        this.clearDebitSelection();
    }

    handleDebitModalConfirm() {
        if (!this.selectedDebitPaymentScheduleId) {
            this.showToast('Error', 'Please select one payment schedule.', 'error');
            return;
        }
        this.showDebitScheduleModal = false;
    }

    clearDebitSelection() {
        this.isAgainstDebit = false;
        this.showDebitScheduleModal = false;
        this.debitPaymentScheduleOptions = [];
        this.selectedDebitPaymentScheduleId = null;
    }

    // ---------- Submit ----------

    async validate() {
        const oppId = this.selectedOpportunityId;

        switch (this.modeOfPayment) {
            case 'Cheque': {
                if (!this.amount || !this.chequeNumber || !this.chequeDate || !this.drawnOnBank) {
                    return 'Please fill all required fields for Cheque mode.';
                }
                if (this.chequeNumber.length !== 6) {
                    return 'Please enter valid Cheque Number of 6 digits.';
                }
                const ok = await this.checkDuplicateReceipt(oppId, 'Cheque', this.chequeNumber);
                return ok ? null : 'Cheque Number already used. Please select another one.';
            }
            case 'EFT':
                if (!this.amount || !this.fundTransferDate || !this.bankName || !this.transactionReferenceNo) {
                    return 'Please fill all required fields for EFT mode.';
                }
                return null;
            case 'DD': {
                if (!this.amount || !this.ddNumber || !this.ddDate || !this.drawnOnBank) {
                    return 'Please fill all required fields for DD mode.';
                }
                if (this.ddNumber.length !== 6) {
                    return 'Please enter valid DD Number of 6 digits.';
                }
                const ok = await this.checkDuplicateReceipt(oppId, 'DD', this.ddNumber);
                return ok ? null : 'DD Number already used. Please select another one.';
            }
            case 'UPI':
                if (!this.amount || !this.referenceNo || !this.paidDate || !this.upiProvider) {
                    return 'Please fill all required fields for UPI mode.';
                }
                return null;
            case 'TDS':
                if (!this.tdsAmount || !this.cin || !this.challanDate || !this.bsrCode || !this.bankName || !this.panNo) {
                    return 'Please fill all required fields for TDS mode.';
                }
                if (!PAN_REGEX.test(this.panNo)) {
                    return 'Please enter a valid PAN Number in the format ABCDE1234F.';
                }
                return null;
            case 'JV':
                if (!this.amount || !this.jvDate || !this.jvReferenceNumber) {
                    return 'Please fill all required fields for JV mode.';
                }
                return null;
            case 'FUNDTRANSFER':
                if (!this.amount || !this.fundTransferDate || !this.referenceNo) {
                    return 'Please fill all required fields for Fund Transfer mode.';
                }
                return null;
            default:
                return null;
        }
    }


    // Client (21 Nov): show a clear error when the amount is missing
    missingAmountMessage() {
        if (!this.modeOfPayment) {
            return 'Please select the Mode of Payment and enter the Amount.';
        }
        const value = this.modeOfPayment === 'TDS' ? this.tdsAmount : this.amount;
        if (value === undefined || value === null || value === '' || isNaN(parseFloat(value)) || parseFloat(value) <= 0) {
            return this.modeOfPayment === 'TDS' ? 'Please enter the TDS Amount.' : 'Please enter the Amount.';
        }
        return null;
    }

    async handleSubmit() {
        const receiptDateMsg = receiptDateError(this.receiptDate);
        if (receiptDateMsg) {
            this.showToast('Error', receiptDateMsg, 'error');
            return;
        }
        if (this.isClosedLost) {
            this.showToast('Error', 'Receipts cannot be created for a Closed Lost Opportunity.', 'error');
            return;
        }
        if (!this.hasOpportunity) {
            this.showToast('Error', 'Please select an Opportunity.', 'error');
            return;
        }

        const amountError = this.missingAmountMessage();
        if (amountError) {
            this.showToast('Error', amountError, 'error');
            return;
        }

        const fieldsValid = [...this.template.querySelectorAll('lightning-input, lightning-combobox')]
            .reduce((valid, input) => input.reportValidity() && valid, true);
        if (!fieldsValid) {
            this.showToast('Error', 'Please complete all required fields.', 'error');
            return;
        }

        this.isSubmitting = true;
        try {
            const errorMessage = await this.validate();
            if (errorMessage) {
                this.showToast('Error', errorMessage, 'error');
                return;
            }

            if (this.isAgainstDebit) {
                if (!this.selectedDebitPaymentScheduleId) {
                    this.showToast('Error', 'Please select a debit payment schedule.', 'error');
                    return;
                }
                const enteredAmount = this.modeOfPayment === 'TDS'
                    ? parseFloat(this.tdsAmount) || 0
                    : parseFloat(this.amount) || 0;
                const totalDueAmount = this.selectedDebitPaymentSchedule?.totalDueAmount || 0;
                if (enteredAmount > totalDueAmount) {
                    this.showToast(
                        'Error',
                        `Amount cannot be greater than selected debit payment schedule due amount (${totalDueAmount}).`,
                        'error'
                    );
                    return;
                }
            }

            const receiptData = {
                opportunityId: this.selectedOpportunityId,
                receiptType: this.receiptType,
                receiptDate: this.receiptDate,
                modeOfPayment: this.modeOfPayment,
                amount: this.amount,
                chequeNumber: this.chequeNumber,
                chequeDate: this.chequeDate,
                fundTransferDate: this.fundTransferDate,
                bankName: this.bankName,
                panNo: this.panNo,
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
                paymentScheduleId: this.selectedDebitPaymentScheduleId,
                againstDebit: this.isAgainstDebit,
                tokenAmount: this.isTokenAmount
            };

            await createReceipt({ receiptData, accId: this.selectedAccount });
            this.showToast('Success', 'Receipt created successfully.', 'success');
            this.resetForm();
        } catch (error) {
            console.error('Error creating receipt:', error);
            this.showToast('Error', error?.body?.message || error?.message || 'Unable to create receipt.', 'error');
        } finally {
            this.isSubmitting = false;
        }
    }

    checkDuplicateReceipt(oppId, type, uniqueNumber) {
        if (!uniqueNumber) {
            return Promise.reject(new Error('Unique number is not provided'));
        }
        return checkDuplicate({ oppId, type, uniqueNumber });
    }

    handleReset() {
        this.resetForm();
    }

    /** Clears the payment details. The selected Opportunity is kept so another receipt can be added quickly. */
    resetForm() {
        this.receiptType = DEFAULT_RECEIPT_TYPE;
        this.receiptDate = today();
        this.modeOfPayment = null;
        this.amount = null;
        this.chequeNumber = null;
        this.chequeDate = null;
        this.fundTransferDate = null;
        this.bankName = null;
        this.panNo = null;
        this.transactionReferenceNo = null;
        this.ddNumber = null;
        this.ddDate = null;
        this.referenceNo = null;
        this.paidDate = null;
        this.upiProvider = null;
        this.tdsAmount = null;
        this.cin = null;
        this.challanDate = null;
        this.bsrCode = null;
        this.drawnOnBank = null;
        this.jvDate = null;
        this.jvReferenceNumber = null;
        this.clearDebitSelection();
        // Re-check: a receipt just saved with Token Amount should now lock the checkbox.
        this.refreshTokenStatus();
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}