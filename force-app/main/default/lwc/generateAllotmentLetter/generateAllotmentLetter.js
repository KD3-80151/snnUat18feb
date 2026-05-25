import { LightningElement, api, track } from 'lwc';
import checkStatus from '@salesforce/apex/digioRepository.checkAlreadyGenerated';
import generateAllotmentLetter from '@salesforce/apex/digioRepository.generateAllotmentLetter';
import sendigiodetails from '@salesforce/apex/digioRepository.sendigiodetails';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import DOWNLOAD_IMG from '@salesforce/resourceUrl/downloadingFile';

export default class GenerateAllotmentLetter extends LightningElement {



    @api recordId;
    @track showSpinner = true;
    @track subDocUrl;
    @track digioID;

    connectedCallback() {
        debugger;
        setTimeout(() => {
            this.checkAlreadyGenerated();
        }, 100);
    }

    checkAlreadyGenerated() {
        debugger;
        checkStatus({ oppId: this.recordId }).then(result => {
            if (result.Allotment_Letter_Generated__c == false) {
                this.generateDocument();
            } else {
                this.showSpinner = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'error',
                        message: 'Allotment Letter Already Generated.',
                        variant: 'error'
                    })
                );
                this.dispatchEvent(new CloseActionScreenEvent());
            }
        }).catch(error => {
            console.log(error);
        });
    }

    generateDocument() {
        debugger;
        generateAllotmentLetter({ oppId: this.recordId })
            .then(result => {
                this.subDocUrl = result.subDocUrl;
                this.digioID = result.digiDocId;
                console.log('subDocUrl ===> ' + result);
                if (this.subDocUrl) {
                    this.showSpinner = false;
                }
            })
            .catch(error => {
                console.log(error);
            });
    }
    sendEmailtoCustomerwithAttachment() {
        debugger;
        if (this.digioID) {
            this.showSpinner = true;
            // Call Apex method to download the document using digioID
            sendigiodetails({ digiDocId: this.digioID, oppId: this.recordId, docname: 'AllotmentLetter' })
                .then(() => {
                    this.showSpinner = false;
                    console.log('Document downloaded successfully');
                    this.dispatchEvent(new CloseActionScreenEvent());
                    // You can add additional logic to send email or notify the user
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: 'Email sent successfully with attachment.',
                            variant: 'success'
                        })
                    );
                    // Close the quick action
                })
                .catch(error => {
                    this.showSpinner = false;
                    console.error('Error downloading document: ', error);
                });
        } else {
            console.error('No digioID available to download document');
        }
    }
    handleCancel(event) {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

}