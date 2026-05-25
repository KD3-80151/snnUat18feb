import { LightningElement,api } from 'lwc';

export default class CustomSpinner extends LightningElement {
    @api spinnerText = 'Downloading, please wait...';
    @api secondText = 'Uploading to Google Drive....';
    connectedCallback() {
        setTimeout(() => {
            this.spinnerText = this.secondText;
        }, 3000); 
    }
}