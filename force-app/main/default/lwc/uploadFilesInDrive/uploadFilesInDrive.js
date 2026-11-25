import { LightningElement, api, track } from 'lwc';
import FileUpload from '@salesforce/resourceUrl/FileUpload';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import uploadFileToGoogleDrive from '@salesforce/apex/UploadFilesInDriveController.uploadFileToGoogleDrive';
import getFolderId from '@salesforce/apex/UploadFilesInDriveController.getFolderId';
import processData from '@salesforce/apex/UploadFilesInDriveController.processData';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class UploadFilesInDrive extends LightningElement {
    img = FileUpload;
    selectedFile;
    showButton = false;
    showSpinner = false;
    @track selectedDocumentId = '';
    @track isShowModal = false;
    @track docId;
    @track folderId;
    folderError;
    _recordId;
    googleDriveLink = 'https://drive.google.com/file/d/1bPxd-RZR4y2FLyUz9R4lN_T5QJummzFO/preview?usp=drivesdk';

    // Injected automatically when used as a Quick Action / on a record page (e.g. Document__c)
    @api
    get recordId() {
        return this._recordId;
    }
    set recordId(value) {
        if (value && value !== this._recordId) {
            this._recordId = value;
            this.fetchFolderId();
        }
    }

    connectedCallback() {
        // Fallback: support being opened with ?recordId=... in the URL
        if (!this._recordId) {
            const recordIdParam = new URLSearchParams(window.location.search).get('recordId');
            if (recordIdParam) {
                this.recordId = recordIdParam;
            }
        }
    }

    fetchFolderId() {
        getFolderId({ recordId: this._recordId })
            .then((result) => {
                if (result && !result.startsWith('Error')) {
                    this.folderId = result;
                    this.folderError = undefined;
                } else {
                    this.folderId = undefined;
                    this.folderError = result;
                }
                console.log('folderId:', this.folderId);
            })
            .catch((error) => {
                this.folderError = 'Unable to fetch the Google Drive folder for this record.';
                console.error('Error retrieving folderId:', error);
            });
    }

    handleFileChange(event) {
        debugger;
        this.selectedFile = event.target.files[0];
        this.showButton = true;
    }

    handleUpload() {
        debugger;
        if (!this.folderId) {
            this.showToast('Error', this.folderError || 'Google Drive folder not found for this record.', 'error');
            return;
        }
        if (this.selectedFile) {
            this.showToast('Success', 'File will be uploaded shortly!!!', 'success');
            this.uploadFileInChunks(this.selectedFile);
           // this.handleClose();
        } else {
            this.showToast('Error', 'Please select a file to upload', 'error');
        }
    }

    handleFileChange(event) {
        debugger;
        this.selectedFile = event.target.files[0];
        this.showButton = true; 
    }
    
    
    
    @track locationValue = '';
    @track rangeValue = '';
    async uploadFileInChunks(file) {
        debugger;
        let chunkSize = 1024 * 1024 * 2; // 2 MB chunk size
        let totalFileSize = file.size;
        let offset = 0;
        let is308Response = false;
        let isLessThan2MB = false;

        if(totalFileSize < chunkSize){
            isLessThan2MB = true;
            chunkSize = totalFileSize;
        }
        
        while (offset < totalFileSize) {
            let chunk = file.slice(offset, offset + chunkSize);
            let contentRange = `bytes ${offset}-${Math.min(offset + chunkSize - 1, totalFileSize - 1)}/${totalFileSize}`;
            console.log('contentRange ===> ' + contentRange);
            
            let fileData = await this.readFileAsBase64(chunk);  

            if (this.locationValue === '') {
                try {
                    const result = await uploadFileToGoogleDrive({
                        fileName: file.name,
                        fileType: file.type,
                        folderId: this.folderId,
                        fileData: fileData,
                        contentRange: contentRange,
                        docId : this.recordId
                    });
                                 // Step 2: Check if the file already exists based on the response
        if (result && result.locationValue === 'File already exists') {
            debugger;
            this.showToast('Error', 'File already exists in Google Drive.', 'error');
            return; // Stop the upload process if the file exists
        } else {
            this.handleClose();
        }
                    this.locationValue = result.locationValue; 
                    if (result.is308Response) {
                        is308Response = result.is308Response == true ? true : false;  
                    }

                    if(isLessThan2MB){
                        break;
                    }
                } catch (error) {
                    console.error('Error in uploadFileToGoogleDrive', error);
                    return;
                }
            } else {
                try {
                    const result = await processData({
                        locationValue: this.locationValue,
                        fileData: fileData,
                        contentRange: contentRange,
                        docId: this.recordId,
                        fileName : file.name
                    });
                    
                    if (result) {
                        if (result == true) {
                            console.log('result ===> ' + result);
                            is308Response = result == true ? true : false;
                        } else {
                            break;
                        }
                    }
                } catch (error) {
                    console.error('Error in processData', error);
                    return;
                }
            }

            if (is308Response) {
                offset += chunkSize;
            }else{
                break;
            }
        }
    }

    readFileAsBase64(file) {
        debugger;
        return new Promise((resolve, reject) => {
            const reader = new FileReader();
            reader.onloadend = () => {
                resolve(reader.result.split(',')[1]); 
            };
            reader.onerror = reject;
            reader.readAsDataURL(file);
        });
    }
        
    handleDragOver(event) {
        debugger;
        event.preventDefault();
        this.highlightDropArea(event);
    }

    handleDragLeave(event) {
        debugger;
        event.preventDefault();
        this.unhighlightDropArea(event);
    }

    handleDrop(event) {
        debugger;
        event.preventDefault();
        this.unhighlightDropArea(event);
        const files = event.dataTransfer.files;
        if (files.length > 0) {
            this.selectedFile = files[0];
            this.handleUpload();
        }
    }

    highlightDropArea(event) {
        debugger;
        const dragDropContainer = this.template.querySelector('.drag-drop-container');
        dragDropContainer.classList.add('highlight');
    }

    unhighlightDropArea(event) {
        debugger;
        const dragDropContainer = this.template.querySelector('.drag-drop-container');
        dragDropContainer.classList.remove('highlight');
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }
    hideModalBox() {
        this.handleClose();
    }

    handleClose() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}