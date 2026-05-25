import { LightningElement, api, track } from 'lwc';
import getParkingDetails from '@salesforce/apex/CostSheetController.getParkingDetails';
import createPricingElement from '@salesforce/apex/CostSheetController.createPricingElement';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ParkingDetails extends LightningElement {
    @api selectedCostSheetId; 
    @api unitId;  
    @track rows = [];  
    @track parkingTypeOptions = [];  
    @track quantityOptions = [];  
    @track parkingDetails = [];  
    value = '--None--';
   @track typeselected;
   @api noRelatedUnitMessage;
   
    
    connectedCallback() {
        this.fetchParkingDetails();
        this.generateQuantityOptions();
    }

    
    fetchParkingDetails() {
        getParkingDetails({ unitId: this.unitId })
            .then(result => {
                if (result) {
                    this.parkingDetails = result.parkingDetails; 
                    this.parkingTypeOptions = result.uniqueParkingTypes.map(type => ({
                        label: type,
                        value: type
                    }));
                    const firstParkingType = result.uniqueParkingTypes;
                    this.rows = [{
                        id: 'initial',  
                        type: 'None',  
                        rate: this.getAmountForParkingType(firstParkingType), 
                        quantity: 1,  // Default quantity is 1
                        finalAmount: this.getAmountForParkingType(firstParkingType)  
                    }];
                }
            })
            .catch(error => {
                console.error("Error fetching parking details: ", error);
            });
    }

    
    getAmountForParkingType(parkingType) {
        const parkingDetail = this.parkingDetails.find(detail => detail.Parking_Type__c === parkingType);
        return parkingDetail ? parkingDetail.Amount__c : 0; 
    }

    // Generate Quantity Options (numeric values)
    generateQuantityOptions() {
        this.quantityOptions = [];
        for (let i = 1; i <= 10; i++) {  // Example: Options for 1 to 10
            this.quantityOptions.push({ label: String(i), value: i });
        }
    }

    // Handle Parking Type change
    handleParkingTypeChange(event) {
        debugger;
        const index = event.target.dataset.index;
        const selectedParkingType = event.target.value;
        this.typeselected = selectedParkingType;

        // Update the rate based on the selected Parking Type
        const correspondingAmount = this.getAmountForParkingType(selectedParkingType);
        this.rows[index].rate = correspondingAmount;

        // Recalculate the final amount
        this.calculateFinalAmount(index);
    }

    // Handle Quantity change
    handleQuantityChange(event) {
        const index = event.target.dataset.index;
        const value = event.target.value;
        this.rows[index].quantity = value;  
        this.calculateFinalAmount(index);  
    }

    // Calculate the final amount (Rate * Quantity)
    calculateFinalAmount(index) {
        const rate = this.rows[index].rate || 0;
        const quantity = this.rows[index].quantity || 1;
        this.rows[index].finalAmount = rate * quantity;
    }

    // Handle Add Row
    handleAddRow() {
        debugger;
        const firstParkingType = this.parkingTypeOptions;
        this.rows.push({
            id: 'new' + this.rows.length,  
            type: firstParkingType,  
            rate: this.getAmountForParkingType(firstParkingType),  
            quantity: 1,
            finalAmount: this.getAmountForParkingType(firstParkingType)  
        });
    }

    // Handle Delete Row
    handleDeleteRow(event) {
        const index = event.target.dataset.index;
        this.rows.splice(index, 1);
    }

    // Close the component
    handleClose() {
        const closeEvent = new CustomEvent('close');
        this.dispatchEvent(closeEvent);
    }

    
    // Helper function to map Parking Type to Pricing Element Master ID
    handleSave() {
        console.log('typeselected==>' ,this.typeselected);
        console.log('Selected Cost Sheet ID:', this.selectedCostSheetId);  
        console.log('unitId:', this.unitId);  
    
        
        this.rows.forEach(row => {
            console.log('Row parking type:', row.type);  
        });
    
        // Prepare data to be sent to Apex
        const pricingElementsData = this.rows.map(row => ({
            amount: row.finalAmount,
            quantity: row.quantity,
            rate: row.rate,
            costSheetId: this.selectedCostSheetId,  // Corrected: Use selectedCostSheetId instead of unitId
            pricingElementMasterId: this.getPricingElementMasterId(this.typeselected)  // Map the parking type to Pricing Element Master ID
        }));
        
        console.log('Pricing Elements Data:', JSON.stringify(pricingElementsData));
    
        // Call the Apex method to create the Pricing_Element__c record
        createPricingElement({ jsondata : JSON.stringify(pricingElementsData) })
            .then(result => {
                
                if (result === 'Success') {
                    const evt = new ShowToastEvent({
                        title: 'Success',
                        message: 'Parking details saved successfully!',
                        variant: 'success',
                        mode: 'dismissable',
                    });
                    this.dispatchEvent(evt);  
                } else {
                    // Show error message if the insertion fails
                    const evt = new ShowToastEvent({
                        title: 'Error',
                        message: result,  // Show the error message returned by Apex
                        variant: 'error',
                        mode: 'dismissable',
                    });
                    this.dispatchEvent(evt);  // Dispatch the event to display the error toast message
                }
            })
            .catch(error => {
                // Show error toast if there is an error calling the Apex method
                const evt = new ShowToastEvent({
                    title: 'Error',
                    message: error.body.message || error.message,
                    variant: 'error',
                    mode: 'dismissable',
                });
                this.dispatchEvent(evt);  // Dispatch the event to display the error toast message
            });
    }
    
    // Helper function to map Parking Type to Pricing Element Master ID
getPricingElementMasterId(parkingType) {
    debugger;
    console.log('Selected parkingType:', parkingType);  

    switch (parkingType) {
        case 'Dependent':
            return 'Car Parking - Dependent';  // This is the correct value expected in Apex
        case 'Independent':
            return 'Car Parking - Independent';  // This is the correct value expected in Apex
        case 'Open':
            return 'Car Parking - Open';  // This is the correct value expected in Apex
        default:
            console.log('Error: Unknown parking type:', parkingType);
            return ''; // Empty string if no match
    }
}


}