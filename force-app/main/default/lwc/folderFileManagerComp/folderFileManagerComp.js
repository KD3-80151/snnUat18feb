import { LightningElement, api, track } from 'lwc';
import getDocuments from '@salesforce/apex/folderFileManagerController.getDocuments';
import createFolder from '@salesforce/apex/folderFileManagerController.createFolder';
import FileUpload from '@salesforce/resourceUrl/FileUpload';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import uploadFileToGoogleDrive from '@salesforce/apex/GoogleDriveAPI.uploadFileToGoogleDrive';
import processData from '@salesforce/apex/GoogleDriveAPI.processData';

export default class FolderFileManagerComp extends LightningElement {
    img = FileUpload;
    selectedFile;
    showButton = false;
    showSpinner = false;
    @track selectedDocumentId = '';
    @track showDocumentDiv = true;
    @track documentList = [];
    @track isShowModal = false;
    @track currectRecordId;
    @track documentName = '';
    @track docId;
    googleDriveLink = 'https://drive.google.com/file/d/1bPxd-RZR4y2FLyUz9R4lN_T5QJummzFO/preview?usp=drivesdk';
    @track isLoading = false;

    connectedCallback() {
        debugger;
        setTimeout(() => {
            this.fetchDocuments();
        }, 2500);
    }

    refreshComp() {
        debugger;
        // this.isLoading = true;
        // setTimeout(() => {
           // this.isLoading = false;
           // console.log('isLoading set to false after 3 seconds');
        // }, 2000); 
       
        console.log('inside refersh component');
        this.fetchDocuments();
        this.selectedDocumentId = '';
        this.documentName = '';
        this.selectedFile = '';
    }

    @api set recordId(value) {
        this.currectRecordId = value;
        console.log('this.currectRecordId ', this.currectRecordId);
    }

    get recordId() {
        return this.currectRecordId;
    }

    handleFileChange(event) {
        debugger;
        this.selectedFile = event.target.files[0];
        this.showButton = true;
    }

    handleUpload() {
        debugger;
        console.log('selectedDocId ===> ' + this.selectedDocumentId);
        if (this.selectedFile) {
            this.showToast('Success', 'File will be uploaded shortly!!!', 'success');
            this.hideModalBox();
            //this.isLoading = true;
            this.uploadFileInChunks(this.selectedFile);
            // setTimeout(() => {
            //     this.hideModalBox();
            // }, 1000);
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
                        folderId: this.selectedDocumentId,
                        fileData: fileData,
                        contentRange: contentRange,
                        docId : this.docId
                    });
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
                        docId: this.docId,
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
        this.refreshComp();
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

    // uploadFileInChunks(file, docId) {
    //     debugger;
        // const CHUNK_SIZE = 1024 * 1024; //its 1mb 
        // const fileSize = file.size;
        // const totalChunks = Math.ceil(fileSize / CHUNK_SIZE);

        // let startByte = 0;
        // let endByte = CHUNK_SIZE;
        // let chunkIndex = 0;
        // let contentRange = 'bytes ' + startByte + '-' + (endByte + 1)  + '/' + fileSize;

        // const reader = new FileReader();
        // reader.onload = () => {
        //     const fileData = reader.result.split(',')[1];
        //     this.sendChunkToApex(file.name, file.type, docId, fileData, contentRange);

        //     chunkIndex++;
        //     startByte = endByte;
        //     endByte = Math.min(startByte + (CHUNK_SIZE ), fileSize);
        //     if (startByte < fileSize) {
        //         reader.readAsDataURL(file.slice(startByte, endByte));
        //     }
        // };
        // reader.readAsDataURL(file.slice(startByte, endByte));
    // }


    
    sendChunkToApex(fileName, fileType, docId, fileData, contentRange ) {
        debugger;
        uploadFileToGoogleDrive({ fileName : fileName, fileType : fileType, folderId: docId, fileData : fileData, contentRange : contentRange })
            .then((result) => {
                system.debug('result ===> ' + JSON.stringify(result));
                if(result.locationValue != null){
                    this.locationValue = result.locationValue;
                    this.is308Response = result.is308Response;
                    this.rangeValue = result.rangeValue;
                }
                // this.locationValue = result;
            })
            .catch(error => {
                console.error('Error uploading chunk:', error);
            });
    }

    // uploadFile(file, docId) {
    //     debugger;
    //     const reader = new FileReader();
    //     reader.onload = () => {
    //         const fileData = reader.result.split(',')[1];
    //         console.log('file.name ==> ' + file.name + '  file.type ==> ' + file.type);

    //         uploadFileUnderDocument({ fileName: file.name, fileType : file.type, folderId: docId,  fileData: fileData, docId : this.docId })
    //             .then(result => {
    //                 setTimeout(() => {
    //                     this.showSpinner = false;
    //                 }, 2500);
    //                 this.showToast('Success', 'File is being uploaded!!!', 'success');
    //                 this.hideModalBox();
    //                 this.refreshComp();
    //             })
    //             .catch(error => {
    //                 this.showSpinner = false;
    //                 this.showToast('Error', error.body.message, 'error');
    //             });
    //     };
    //     reader.readAsDataURL(file);
    // }

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
            this.uploadFile(this.selectedFile);
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

    fetchDocuments() {
        debugger;
        getDocuments({ oppId: this.recordId })
            .then(result => {
                this.documentList = result;
                this.showDocumentDiv = this.documentList.length > 0 ? true : false;
                if(this.docId != ''){

                    const matchedDocument = this.documentList.find(doc => doc.Id === this.docId);
                    // this.showToast('Success', 'File will be uploaded Successfully!!!', 'success');
                    if (matchedDocument && matchedDocument.Sub_Documents__r && matchedDocument.Sub_Documents__r.length > 0) {
                        this.selectedContentDocLink = matchedDocument.Sub_Documents__r[0].File_URL__c;
                        this.showDocumentDiv = true;
                        this.showFilePreview = this.selectedContentDocLink != null ? true : false;
                    } else {
                        
                        this.selectedContentDocLink = null;
                    }
                }
            })
            .catch(error => {
                console.error('Error fetching documents:', error);
            });
    }

    // @wire(getDocuments, { oppId: '$recordId' })
    // wiredRecord({ error, data }) {
    //     if (data) {
    //         this.documentList = data;
    //         this.showDocumentDiv = this.documentList.length > 0 ? true : false;
    //     } else if (error) {
    //         console.error('Error fetching documents:', error);
    //     }
    // }

    toggleSection(event) {
        const buttonid = event.currentTarget.dataset.buttonid;
        const section = this.template.querySelector(`[data-id="${buttonid}"]`);
        if (section.classList.contains('slds-is-open')) {
            section.classList.remove('slds-is-open');
            section.classList.add('slds-is-close');
        } else {
            section.classList.remove('slds-is-close');
            section.classList.add('slds-is-open');
        }
    }

    @track showFilePreview = false;
    @track selectedContentDocLink = '';
    handleContentDocument(event) {
        debugger;
        this.selectedContentDocLink = event.target.dataset.id != null ? event.target.dataset.id : null;
        console.log('selected selectedContentDocLink ===> ' + this.selectedContentDocLink);
        this.showDocumentDiv = true;
        this.showFilePreview = this.selectedContentDocLink != null ? true : false;
    }

    showModalBox(event) {
        debugger;
        const documentRecId = event.target.dataset.recid != null ? event.target.dataset.recid : null;
        const docId = event.target.dataset.id != null ? event.target.dataset.id : null;
        console.log('docId ===> ' + docId + ' Recid ===> ' + documentRecId);
        this.selectedDocumentId = docId;
        this.docId = documentRecId;
        this.isShowModal = true;
    }

    hideModalBox() {
        this.isShowModal = false;
    }

    get url() {
        this.selectedContentDocLink;
    }

    @track isShowModalFolder = false;
    showModalBoxFolder() {
        this.isShowModalFolder = true;
    }

    hideModalBoxFolder() {
        this.isShowModalFolder = false;
    }
    handleChangeFolder(event) {
        this.documentName = event.target.value;
    }

    handleFolderCreation() {
        debugger;
        if (this.documentName == null) {
            this.showToast('Error', 'Please enter folder name', 'error');
            return;
        }
        createFolder({ folderName: this.documentName, oppId: this.recordId })
            .then(result => {
                if (result == true) {
                    this.showToast('Success', 'Folder uploaded successfully', 'success');
                    this.hideModalBoxFolder();
                } else {
                    this.showToast('Error', 'Error Uploading Folder', 'error');
                }
                this.refreshComp();
            })
            .catch(error => {
                console.log('Error ===> ' + error);
            });
    }
}