import { LightningElement, api, track } from 'lwc';
import getCostSheets from '@salesforce/apex/CostSheetController.getCostSheets';
import checkForRelatedUnit from '@salesforce/apex/CostSheetController.checkForRelatedUnit';

export default class EditCarParking extends LightningElement {
    @api recordId;  
    @track costSheets = [];  
    @track isLoading = false;
    @track selectedCostSheetId;  
    @track selectedCostSheet;  
    @track noCostSheets = false;
    @track showChildComponent = false;  

    getIdFromUrl() {
        debugger;
        const url = window.location.href;
        const params = new URLSearchParams(url.split('?')[1]);
        return params.get('recordId'); 
    }
    
    connectedCallback() {
        this.recordId = this.getIdFromUrl(); 
        this.fetchCostSheets();
    }

    fetchCostSheets() {
        this.isLoading = true;
        getCostSheets({ opportunityId: this.recordId })
            .then(result => {
                this.isLoading = false;
                if (result && result.length > 0) {
                    this.costSheets = result.map(costSheet => {
                        return {
                            ...costSheet,
                            UnitName: costSheet.Unit__r ? costSheet.Unit__r.Name : 'No Unit Available'
                        };
                    });
                    this.noCostSheets = false;
                } else {
                    this.costSheets = [];
                    this.noCostSheets = true;
                }
            })
            .catch(error => {
                this.isLoading = false;
                this.costSheets = [];
                this.noCostSheets = true;
                console.error("Error fetching cost sheets: ", error);
            });
    }

   

    handleSelection(event) {
        const selectedId = event.target.value;  
        console.log('selectedId==>', selectedId);
        const selectedCostSheet = this.costSheets.find(costSheet => costSheet.Id === selectedId);
        this.selectedCostSheet = selectedCostSheet;
        this.selectedCostSheetId = selectedId;  
    }
    

    
    handleNext() {
        console.log('Selected Cost Sheet ID:', this.selectedCostSheetId);
    
        if (this.selectedCostSheetId) {
            
            this.checkForRelatedUnit(this.selectedCostSheetId)
                .then(result => {
                    if (result) {
                        
                        this.noRelatedUnitMessage = '';  
                        this.showChildComponent = true;  
                    } else {
                        
                        this.noRelatedUnitMessage = 'No related Unit';
                        this.showChildComponent = true;  
                    }
                })
                .catch(error => {
                    console.error("Error checking for related Unit: ", error);
                    this.noRelatedUnitMessage = 'Error checking related Unit';
                    this.showChildComponent = true;  
                });
        } else {
            alert('Please select a cost sheet before proceeding.');
        }
    }
    
    
    checkForRelatedUnit(costSheetId) {
        return checkForRelatedUnit({ costSheetId: costSheetId });
    }

    handleCloseChildComponent() {
        this.showChildComponent = false;  
    }
}