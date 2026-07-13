import { LightningElement, api, track } from 'lwc';
import generateDebitNote from '@salesforce/apex/GenerateDebitNoteController.generateDebitNote';
import sendigiodetails1 from '@salesforce/apex/digioRepository.sendigiodetails1';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class GenerateDebitNote extends LightningElement {
    @api recordId;
    @track showSpinner = true;
    @track subDocUrl;
    @track digiDocId;

    connectedCallback() {
        setTimeout(() => {
            this.extractRecordIdFromURL();
        }, 100);
    }

    extractRecordIdFromURL() {
        const url = window.location.href;
        const regex = /[?&]recordId=([^&]*)/;
        const matches = url.match(regex);

        if (matches && matches[1]) {
            this.recordId = matches[1];
            if (this.recordId) {
                this.generateDocument();
            }
        } else if (this.recordId) {
            this.generateDocument();
        } else {
            this.showSpinner = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'No Record Id found in the URL',
                    variant: 'error'
                })
            );
        }
    }

    generateDocument() {
        this.showSpinner = true;

        generateDebitNote({ recorId: this.recordId })
            .then(result => {
                this.subDocUrl = result?.subDocUrl;
                this.digiDocId = result?.digiDocId;

                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Debit Note generated successfully.',
                        variant: 'success'
                    })
                );
            })
            .catch(error => {
                console.error(error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: error?.body?.message || 'Error generating Debit Note',
                        variant: 'error'
                    })
                );
            })
            .finally(() => {
                this.showSpinner = false;
            });
    }

    sendEmailtoCustomerwithAttachment() {
        if (!this.digiDocId) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Debit Note is not generated yet.',
                    variant: 'error'
                })
            );
            return;
        }

        this.showSpinner = true;

        sendigiodetails1({
            digiDocId: this.digiDocId,
            recieptId: this.recordId,
            docname: 'DebitNote'   
        })
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Email sent successfully with attachment.',
                        variant: 'success'
                    })
                );

                this.dispatchEvent(new CloseActionScreenEvent());
            })
            .catch(error => {
                console.error(error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: error?.body?.message || 'Error sending email',
                        variant: 'error'
                    })
                );
            })
            .finally(() => {
                this.showSpinner = false;
            });
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}