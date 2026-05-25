import { LightningElement, api, track } from 'lwc';
import generateSerenityReceipt from '@salesforce/apex/digioRepository.generateSerenityReceipt';
import sendigiodetails1 from '@salesforce/apex/digioRepository.sendigiodetails1';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import DOWNLOAD_IMG from '@salesforce/resourceUrl/downloadingFile';

export default class GenerateSerenityReceipt extends LightningElement {

   @api recordId;
        @track showSpinner = true;
        @track subDocUrl;
        @track digioID;

    connectedCallback() {
        debugger;
        setTimeout(()=>{
            
             this.extractRecordIdFromURL();
        },100);
    }

     extractRecordIdFromURL() {
        debugger;
        const url = window.location.href; // Get the full URL
        const regex = /[?&]recordId=([^&]*)/; // Pattern to find recordId parameter
        const matches = url.match(regex);

        if (matches && matches[1]) {
            this.recordId = matches[1]; // Extract the recordId
            console.log('Extracted Record Id: ', this.recordId);
            if(this.recordId){
                this.generateDocument();
            }
        } else {
            console.error('No Record Id found in the URL');
        }
    }

    generateDocument(){
        debugger;
        generateSerenityReceipt({recorId : this.recordId})
        .then(result => {
            this.subDocUrl = result.subDocUrl;
            this.digioID = result.digiDocId;
            console.log('subDocUrl ===> ' + result);
            if(this.subDocUrl){
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
            //this.showSpinner = true;

            // Call Apex method to download the document using digioID
            sendigiodetails1({ digiDocId: this.digioID ,recieptId : this.recordId, docname : 'VettedReceipt' })
                .then(() => {
                    //this.showSpinner = false;
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
                    // You can add additional logic to send email or notify the user
                })
                .catch(error => {
                    this.showSpinner = false;
                    console.error('Error downloading document: ', error);
                });
        } else {
            console.error('No digioID available to download document');
        }
    }

    handleCancel(event){
        this.dispatchEvent(new CloseActionScreenEvent());
    }


}