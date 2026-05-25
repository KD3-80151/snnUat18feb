import { LightningElement, api, track  } from 'lwc';
import generateHandOverOfFlat from '@salesforce/apex/digioRepository.generateHandOverOfFlat';
import sendigiodetails from '@salesforce/apex/digioRepository.sendigiodetails';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions'; 
import DOWNLOAD_IMG from '@salesforce/resourceUrl/downloadingFile';
export default class HandOverFormat extends LightningElement {

     @api recordId;
        @track showSpinner = true;
        @track subDocUrl;
        @track digioID;
        connectedCallback() {
            setTimeout(() => {
                this.generateDocument();
            }, 100); 
        }
    
        generateDocument(){
            debugger;
            generateHandOverOfFlat({oppId : this.recordId})
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
              
    
                // Call Apex method to download the document using digioID
                sendigiodetails({ digiDocId: this.digioID ,oppId : this.recordId,docname : 'HandOverFormate' })
                    .then(() => {
                        
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
        handleCancel(event) {
                this.dispatchEvent(new CloseActionScreenEvent());
            }
    

}