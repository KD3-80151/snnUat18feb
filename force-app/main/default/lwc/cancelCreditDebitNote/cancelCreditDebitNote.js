import { LightningElement, api } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import getNoteSummary from '@salesforce/apex/CreditDebitNoteService.getNoteSummary';
import cancelNote from '@salesforce/apex/CreditDebitNoteService.cancelNote';

// Client (21 Nov): option to cancel a credit/debit note; the payment schedule is adjusted back.
export default class CancelCreditDebitNote extends LightningElement {
    _recordId;
    summary;
    loading = true;
    saving = false;
    reason = '';

    @api
    get recordId() {
        return this._recordId;
    }
    set recordId(value) {
        this._recordId = value;
        if (value) {
            this.load();
        }
    }

    get header() {
        return this.summary && this.summary.entryType ? 'Cancel ' + this.summary.entryType : 'Cancel Credit/Debit Note';
    }

    get canCancel() {
        return this.summary && this.summary.canCancel;
    }

    load() {
        this.loading = true;
        getNoteSummary({ recordId: this._recordId })
            .then(result => {
                this.summary = result;
            })
            .catch(error => {
                this.summary = { canCancel: false, message: this.errorText(error) };
            })
            .finally(() => {
                this.loading = false;
            });
    }

    handleReason(event) {
        this.reason = event.target.value;
    }

    handleCancel() {
        if (!this.reason || !this.reason.trim()) {
            this.toast('Error', 'Please enter the reason for cancelling.', 'error');
            return;
        }
        this.saving = true;
        cancelNote({ recordId: this._recordId, reason: this.reason.trim() })
            .then(message => {
                this.toast('Cancelled', message, 'success');
                notifyRecordUpdateAvailable([{ recordId: this._recordId }]);
                this.close();
            })
            .catch(error => {
                this.toast('Not cancelled', this.errorText(error), 'error');
            })
            .finally(() => {
                this.saving = false;
            });
    }

    errorText(error) {
        return (error && error.body && error.body.message) || 'Something went wrong.';
    }

    toast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant, mode: variant === 'error' ? 'sticky' : 'dismissible' }));
    }

    close() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}