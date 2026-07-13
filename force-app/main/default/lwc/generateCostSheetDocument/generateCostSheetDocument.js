import { LightningElement, api, track, wire } from 'lwc';
import generateCostSheetDocument from '@salesforce/apex/digioRepository.generateCostSheetDocument';
import getCostSheets from '@salesforce/apex/digioRepository.getCostSheets'; 
import sendigiodetails from '@salesforce/apex/digioRepository.sendigiodetails';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions'; 
 
    


// export default class GenerateCostSheetDocument extends LightningElement {
//      @api recordId;
//     @track showSpinner = true;
//     @track subDocUrl;
//     @track digioID;
//     @track showCostSheet = true;
//     @track selectedCostSheet;
//     @track costSheetOptions = [];

//     connectedCallback(){
//         const url = window.location.href.toString();
//         const queryParams = url.split("&");
        
//         const recordIdParam = queryParams.find(param => param.includes("recordId"));
        
//         if (recordIdParam) {
//             const recordIdKeyValue = recordIdParam.split("=");
//             if (recordIdKeyValue.length === 2) {
//                 const recordId = recordIdKeyValue[1];
//                 this.recordId = recordId;
//             } else {
//                 console.error("Invalid recordId parameter format");
//             }
//         } else {
//             console.error("recordId parameter not found in the URL");
//         }
        
//         this.fetchCostSheetRecords();
//     }

//     fetchCostSheetRecords(){
//         debugger;
//         getCostSheets({oppId : this.recordId})
//         .then(result => {
//             let costSheetData = result;
//             let finalizeCost = costSheetData.filter(item => item.finalize_CostSheet__c === true) || {};
//             if(finalizeCost[0] != null && finalizeCost[0].Id != null){
//                 this.selectedCostSheet = finalizeCost[0].Id;
//                 this.showCostSheet = false;
//                 this.generateDocument();
                
//             }else{
//                 this.costSheetOptions = costSheetData.map(item => ({ label : item.Name , value : item.Id}));
//                 this.showCostSheet = true;
//             }
//         })
//         .catch(error => {
//             console.log(error);
//         });
//     }

//     handleChange(event){
//         debugger;
//         console.log('event.detail==>'+event.detail);
//         this.selectedCostSheet = event.detail.value;
//     }

//     generateDocument(){
//         debugger;
//         this.showCostSheet = false;
//         this.showSpinner = true;
//         generateCostSheet({costSheetId : this.selectedCostSheet})
//         .then(result => {
//             this.subDocUrl = result.subDocUrl;
//             this.digioID = result.digiDocId;
//             console.log('subDocUrl ===> ' + result);
//             if(this.subDocUrl){
//                 this.showSpinner = false;
//             }
//         })
//         .catch(error => {
//             console.log(error);
//         });
//     }
    
//     sendEmailtoCustomerwithAttachment() {
//         debugger;
//         if (this.digioID) {
             

//             // Call Apex method to download the document using digioID
//             sendigiodetails({ digiDocId: this.digioID ,oppId : this.recordId,docname : 'CostSheetDoc' })
//                 .then(() => {
                     
//                     console.log('Document downloaded successfully');
//                     this.dispatchEvent(new CloseActionScreenEvent());
//                             // You can add additional logic to send email or notify the user
//                             this.dispatchEvent(
//                                 new ShowToastEvent({
//                                     title: 'Success',
//                                     message: 'Email sent successfully with attachment.',
//                                     variant: 'success'
//                                 })
//                             );
//                     // You can add additional logic to send email or notify the user
//                 })
//                 .catch(error => {
//                     this.showSpinner = false;
//                     console.error('Error downloading document: ', error);
//                 });
//         } else {
//             console.error('No digioID available to download document');
//         }
//     }

     
  
   
//     handleCancel(event){
//         this.dispatchEvent(new CloseActionScreenEvent());
//     }
// }

export default class GenerateCostSheetDocument extends LightningElement {
    @api recordId;
    @track showSpinner = true;
    @track subDocUrl;
    @track digioID;
    @track showCostSheet = true;
    @track selectedCostSheet = '';
    @track costSheetOptions = [];
    @track costSheetData;
    @track message = '';
    @track proj = '-';
    @track block = '-';

    connectedCallback() {
        const url = window.location.href.toString();
        const queryParams = url.split("&");
        const recordIdParam = queryParams.find(param => param.includes("recordId"));
        if (recordIdParam) {
            const recordIdKeyValue = recordIdParam.split("=");
            if (recordIdKeyValue.length === 2) {
                const recordId = recordIdKeyValue[1];
                this.recordId = recordId;
            } else {
                console.error("Invalid recordId parameter format");
            }
        } else {
            console.error("recordId parameter not found in the URL");
        }
        this.fetchCostSheetRecords();
    }

    fetchCostSheetRecords() {
        debugger;
        getCostSheets({ recordId: this.recordId, selectedCostSheet: this.selectedCostSheet })
            .then(result => {
                this.costSheetData = result;
                let finalizeCost = this.costSheetData.filter(item => item.finalize_CostSheet__c === true) || {};
                if (finalizeCost[0] != null && finalizeCost[0].Id != null) {
                    this.showCostSheet = false;
                    this.generateDocument();
                } else {
                    var unitCreatedDateMap = {};
                    this.costSheetData.forEach(item => {
                        if(unitCreatedDateMap[item.Unit__r.Unit_Number_Only__c] == null) {
                            unitCreatedDateMap[item.Unit__r.Unit_Number_Only__c] = [];
                        }
                        unitCreatedDateMap[item.Unit__r.Unit_Number_Only__c].push(item.CreatedDate);
                    });
                    this.costSheetOptions = this.costSheetData.map(item => {
                        const name = unitCreatedDateMap[item.Unit__r.Unit_Number_Only__c] != null 
                                        ? unitCreatedDateMap[item.Unit__r.Unit_Number_Only__c].indexOf(item.CreatedDate) == 0 
                                        ? item.Unit__r.Unit_Number_Only__c 
                                        : item.Unit__r.Unit_Number_Only__c + '-v' + (parseFloat(unitCreatedDateMap[item.Unit__r.Unit_Number_Only__c].indexOf(item.CreatedDate)) + 1)
                                        : item.Unit__r.Unit_Number_Only__c;
                        return { 
                            label: name, value: item.Id 
                        };
                    });
                    this.showCostSheet = true;
                }
            })
            .catch(error => {
                console.log(error);
            });
    }

    handleChange(event) {
        this.selectedCostSheet = event.detail.value;
        this.proj = this.costSheetData.find(item => item.Id == this.selectedCostSheet)?.Unit__r?.Floor__r?.Blocks__r?.Project__r?.Name;
        this.block = this.costSheetData.find(item => item.Id === this.selectedCostSheet)?.Unit__r?.Floor__r?.Blocks__r?.Name;
    }

    generateDocument() {
        debugger;
        this.showCostSheet = false;
        this.showSpinner = true;
        generateCostSheetDocument({ recordId: this.recordId, selectedCostSheet: this.selectedCostSheet })
            .then(result => {
                if (result && result.message == "emailMandatory") {
                    this.showSpinner = false;
                    this.showCostSheet = true;
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Email Required',
                        message: 'Email is mandatory on the Opportunity. Please add an email before generating the Cost Sheet document.',
                        variant: 'error',
                        mode: 'sticky'
                    }));
                } else if (result && result.message == "changeDate") {
                    this.message = 'Please update the Base Price. The Unit\'s End Date has been exceeded.';
                } else {
                    this.subDocUrl = result.subDocUrl;
                    this.digioID = result.digiDocId;
                    console.log('subDocUrl ===> ' + result);
                    if (this.subDocUrl) {
                        this.showSpinner = false;
                    }
                }
            })
            .catch(error => {
                console.log(error);
            });
    }
    sendEmailtoCustomerwithAttachment() {
        debugger;
        if (this.digioID) {
            // this.showSpinner = true;
            // Call Apex method to download the document using digioID
            sendigiodetails({ digiDocId: this.digioID, oppId: this.recordId, docname: 'Cost Sheet' })
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

    handleCancel(event) {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}