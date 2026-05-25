import { api, LightningElement, track } from 'lwc';
import getFilesFromDrive from '@salesforce/apex/SyncGoogleDriveController.getFilesFromDrive';
import getFolderId from '@salesforce/apex/SyncGoogleDriveController.getFolderId';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
// import { getRecord } from 'lightning/uiRecordApi';
// import FolderIdField from '@salesforce/schema/Project__c.folderId__c';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class SyncFilesFromDrive extends LightningElement {
    @api recordId;  
    @track folderId;


    
    // @wire(getRecord, { recordId: '$recordId', fields: [FolderIdField] })
    // projectRecord;

    connectedCallback() {
        debugger;
        const url = window.location.href.toString();
        const queryParams = url.split("&");
        const recordIdParam = queryParams.find(param => param.includes("recordId"));
        if (recordIdParam) {
            const recordIdKeyValue = recordIdParam.split("=");
            if (recordIdKeyValue.length === 2) {
                this.recordId = recordIdKeyValue[1];
            } else { 
                console.error("Invalid recordId parameter format");
            }
        } else { 
            console.error("recordId parameter not found in the URL"); 
        }
        if (this.recordId) {
            getFolderId({ recordId: this.recordId })
                .then((result) => {
                    this.folderId = result;
                    
                    this.getFilesFromDrive();
                })
                .catch((error) => {
                    
                    console.error('Error retrieving folderId:', error);
                });
        }
    }

    // Call the getFilesFromDrive Apex method
    getFilesFromDrive() {
        if (this.folderId) {
            getFilesFromDrive({ folderId: this.folderId, recordId: this.recordId })
            .then((result) => {
                debugger;
                if (result === 'success') {
                    // Show success toast message
                    this.showToast('Success', 'Google Drive files fetched and inserted successfully.', 'success');
                    this.handleCloseModal();
                } else {
                    this.showToast('Error', 'Please Check if folder or file exist', 'error');
                    this.handleCloseModal();
                }
            })
            .catch((error) => {
                this.showToast('Error', 'Please Check if folder or file exist.', 'error');
                this.handleCloseModal();
                console.error('Error fetching files from Google Drive:', error);
            });
        } else {
            this.showToast('Error', 'Please Check if folder or file exist.', 'error');
            this.handleCloseModal();
            console.error('Folder ID is not available');
        }
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }

    handleCloseModal() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}