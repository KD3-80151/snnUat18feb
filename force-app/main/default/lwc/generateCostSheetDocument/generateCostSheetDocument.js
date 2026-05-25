import { LightningElement, api, track, wire } from 'lwc';
import generateCostSheet from '@salesforce/apex/digioRepository.generateCostSheet';
import getCostSheets from '@salesforce/apex/digioRepository.getCostSheets'; 
import sendigiodetails from '@salesforce/apex/digioRepository.sendigiodetails';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions'; 
 
    


export default class GenerateCostSheetDocument extends LightningElement {
     @api recordId;
    @track showSpinner = true;
    @track subDocUrl;
    @track digioID;
    @track showCostSheet = true;
    @track selectedCostSheet;
    @track costSheetOptions = [];

    connectedCallback(){
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

    fetchCostSheetRecords(){
        debugger;
        getCostSheets({oppId : this.recordId})
        .then(result => {
            let costSheetData = result;
            let finalizeCost = costSheetData.filter(item => item.finalize_CostSheet__c === true) || {};
            if(finalizeCost[0] != null && finalizeCost[0].Id != null){
                this.selectedCostSheet = finalizeCost[0].Id;
                this.showCostSheet = false;
                this.generateDocument();
                
            }else{
                this.costSheetOptions = costSheetData.map(item => ({ label : item.Name , value : item.Id}));
                this.showCostSheet = true;
            }
        })
        .catch(error => {
            console.log(error);
        });
    }

    handleChange(event){
        debugger;
        console.log('event.detail==>'+event.detail);
        this.selectedCostSheet = event.detail.value;
    }

    generateDocument(){
        debugger;
        this.showCostSheet = false;
        this.showSpinner = true;
        generateCostSheet({costSheetId : this.selectedCostSheet})
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
            sendigiodetails({ digiDocId: this.digioID ,oppId : this.recordId,docname : 'CostSheetDoc' })
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

     
  
   
    handleCancel(event){
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}