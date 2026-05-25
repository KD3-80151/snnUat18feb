import { LightningElement,api,track } from 'lwc';

import generateCostSheet from '@salesforce/apex/digioRepository.generateCostSheet';
import DOWNLOAD_IMG from '@salesforce/resourceUrl/downloadingFile';
export default class GenerateCostSheet extends LightningElement {

    //  @api recordId;
    // @track subDocUrl = '';
    // @track loaded = false;
    // downloadImg = DOWNLOAD_IMG;

    // connectedCallback() {
    //     debugger;
    //     setTimeout(()=>{
    //         this.extractRecordIdFromURL();
    //        // this.generateDocument();
    //     },100);
    // }

    

    //  extractRecordIdFromURL() {
    //     debugger;
    //     const url = window.location.href; // Get the full URL
    //     const regex = /[?&]recordId=([^&]*)/; // Pattern to find recordId parameter
    //     const matches = url.match(regex);

    //     if (matches && matches[1]) {
    //         this.recordId = matches[1]; // Extract the recordId
    //         console.log('Extracted Record Id: ', this.recordId);
    //         if(this.recordId){
    //             this.generateDocument();
    //         }
    //     } else {
    //         console.error('No Record Id found in the URL');
    //     }
    // }

    // generateDocument() {
    //     generateCostSheet({ oppId: this.recordId })
    //         .then(result => {
    //             this.subDocUrl = result;
    //             console.log('subDocUrl ===> ' + result);
    //             if (this.subDocUrl) {
    //                 this.loaded = true;
    //             }
    //         })
    //         .catch(error => {
    //             console.log(error);
    //         });
    // }

    @api recordId;
    @track showSpinner = true;
    @track subDocUrl;

    connectedCallback() {
        setTimeout(() => {
            this.generateDocument();
        }, 100); 
    }

    generateDocument(){
        debugger;
        generateCostSheet({oppId : this.recordId})
        .then(result => {
            this.subDocUrl = result;
            console.log('subDocUrl ===> ' + result);
            if(this.subDocUrl){
                this.showSpinner = false;
            }
        })
        .catch(error => {
            console.log(error);
        });
    }

}