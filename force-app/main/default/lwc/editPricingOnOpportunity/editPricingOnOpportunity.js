import { LightningElement, api, track } from 'lwc';
import { loadStyle } from "lightning/platformResourceLoader";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import modal from "@salesforce/resourceUrl/custommodalcss";
import getAccess from '@salesforce/apex/editPricingOnOpportunityController.getAccess';
import getPricingElements from '@salesforce/apex/editPricingOnOpportunityController.getPricingElements';
import savePricingElements from '@salesforce/apex/editPricingOnOpportunityController.savePricingElements';

export default class EditPricingOnOpportunity extends LightningElement {

    @track pricingElements = [];
    @track originalPricingElements = [];
    @api recordId;
    @track totalDiscountAmount = 0;
    error;
    @track description ='';

    connectedCallback() {
        debugger;
        loadStyle(this, modal);
        // Parse recordId from the URL (if not passed as a property)
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
        // If recordId is available, fetch the Pricing Elements
        if (this.recordId) {
            this.checkAccess();
            
        } else {
            console.warn('No recordId provided.');
        }
    }

    checkAccess = function(){
        debugger;

        getAccess({ opportunityId: this.recordId })
        .then((result) => {
            debugger;
            if(result == '1'){
                this.fetchPricingElements();
            }else if(result == '2'){
                this.description = 'Demand Letter Already Generated for This Opportunity';
            }else if(result == '3'){
                this.description = 'You Dont have an Access to Edit Pricing Elements';
            }
            
    })
        .catch((error) => {
            debugger;
            console.error('Error fetching pricing elements:', error);
            this.pricingElements = [];
            this.error = error;
        });

    }



    fetchPricingElements = function(){
        getPricingElements({ opportunityId: this.recordId })
        .then((result) => {
            debugger;
            console.log('Fetched pricing elements:', JSON.stringify(result));
            this.pricingElements = result[0].Pricing_Elements__r.map(pe => ({
                ...pe,
                discountAmount: pe.Discount_Amount__c ? pe.Discount_Amount__c : 0,
                amount: pe.Amount__c ? pe.Amount__c : 0,
                taxAmount: pe.finalize_CostSheet__c ? pe.finalize_CostSheet__c : 0,
                totalAmounts: (pe.Amount__c ? pe.Amount__c : 0) + (pe.finalize_CostSheet__c ? pe.finalize_CostSheet__c : 0) - (pe.Discount_Amount__c ? pe.Discount_Amount__c : 0)
            }));
            // this.pricingElements = result[0].Pricing_Elements__r;
            this.originalPricingElements = JSON.parse(JSON.stringify(result[0].Pricing_Elements__r)); // Store a copy of the original pricing elements
            this.calculateTotalDiscountAmount();
            this.error = undefined;
    })
        .catch((error) => {
            debugger;
            console.error('Error fetching pricing elements:', error);
            this.pricingElements = [];
            this.error = error;
        });
    }

        get totalAmountSum() {
            debugger;
        return this.pricingElements.reduce((sum, pe) => sum + (pe.Amount__c || 0), 0);
    }

      calculateTotalDiscountAmount() {
        debugger;
        this.totalDiscountAmount = this.pricingElements.reduce((sum, pe) => {
            return sum + (pe.discountAmount || 0);
        }, 0);
    }

    get totalTaxAmount() {
        debugger;
    return this.pricingElements.reduce((sum, pe) => sum + (pe.Tax_Amount__c || 0), 0);
}

    get totalAmount() {
        debugger;
        return this.pricingElements.reduce((sum, pe) => sum + (pe.totalAmounts || 0), 0);
    }

    handleValueChange(event) {
        debugger;
        const pricingElementId = event.target.dataset.id; // Retrieve the ID of the Pricing Element
        const field = event.target.dataset.field;  // Retrieve the field name (Quantity or Rate)
        let value = event.target.value;          // Retrieve the updated value (new value)
    
        // Ensure that pricingElementId, field, and value are correct
        if ((field === 'Quantity__c' || field === 'Rate__c') && value === '') {
            value = "0";
        }
        if (!pricingElementId || !field) {
            console.error('Missing required values. pricingElementId:', pricingElementId, 'field:', field, 'value:', value);
            return;
        }
    
        // Find the Pricing Element record in the pricingElements array by ID
        const pricingElementIndex = this.pricingElements.findIndex(item => item.Id === pricingElementId);
        if (pricingElementIndex !== -1) {
            // Clone the existing object and update the specific field
            const updatedPricingElement = { 
                ...this.pricingElements[pricingElementIndex], 
                [field]: value 
            };
    
            // Ensure numerical values are correctly parsed
            updatedPricingElement.Quantity__c = parseFloat(updatedPricingElement.Quantity__c) || 0;
            updatedPricingElement.Rate__c = parseFloat(updatedPricingElement.Rate__c) || 0;
            updatedPricingElement.amount = updatedPricingElement.Quantity__c * updatedPricingElement.Rate__c;
    
            updatedPricingElement.taxAmount = parseFloat(updatedPricingElement.taxAmount) || 0;
            updatedPricingElement.discountAmount = parseFloat(updatedPricingElement.discountAmount) || 0;
    
            // Calculate totalAmounts correctly
            updatedPricingElement.totalAmounts = 
                updatedPricingElement.amount + updatedPricingElement.taxAmount - updatedPricingElement.discountAmount;
    
            // Replace the old Pricing Element with the updated one to trigger reactivity
            this.pricingElements = [
                ...this.pricingElements.slice(0, pricingElementIndex),
                updatedPricingElement,
                ...this.pricingElements.slice(pricingElementIndex + 1)
            ];
    
            // **Update TotalAmount for all pricing elements**
            this.updateTotalAmount();
        } else {
            console.error('Pricing Element not found for ID:', pricingElementId);
        }
    }
    
    // Function to update the TotalAmount for all pricing elements
    updateTotalAmount() {
        debugger;
        this.pricingElements = this.pricingElements.map(item => ({
            ...item,
            Quantity__c: parseFloat(item.Quantity__c) || 0,
            Rate__c: parseFloat(item.Rate__c) || 0,
            amount: (parseFloat(item.Quantity__c) || 0) * (parseFloat(item.Rate__c) || 0),
            taxAmount: parseFloat(item.taxAmount) || 0,
            discountAmount: parseFloat(item.discountAmount) || 0,
            totalAmounts: 
                ((parseFloat(item.Quantity__c) || 0) * (parseFloat(item.Rate__c) || 0)) + 
                (parseFloat(item.taxAmount) || 0) - 
                (parseFloat(item.discountAmount) || 0)
        }));
    }
    

   

    // Save the updated Pricing Element
    handleSave(event) {
        debugger;
        //this.validatePricingElements();
        // Filter the modified Pricing Element by comparing with original values
        const modifiedPricingElements = this.pricingElements.filter(pricingElement => {
            const originalPricingElement = this.originalPricingElements.find(pe => pe.Id === pricingElement.Id);
            return (originalPricingElement && 
                    (originalPricingElement.Quantity__c !== pricingElement.Quantity__c || 
                        originalPricingElement.Rate__c !== pricingElement.Rate__c));
        });
        // If validation fails, prevent saving
        // if (this.pricingElements.some(pe => pe.isWrong)) {
        //     this.showToast('Error', 'Quantity or Rate cannot be null or 0.', 'error');
        //     return;
        // }
        if (modifiedPricingElements.length > 0) {
            // If there are modified pricing element, save them
            savePricingElements({ pricingElements: modifiedPricingElements })
                .then(() => {
                    this.showToast('Success!', 'Pricing Elements updated successfully.', 'success');
                    this.closeScreen();
                })
                .catch((error) => {
                    console.error('Error saving Pricing Elelments:', error);
                    this.error = error;
                });
        } else {
            // Show an error toast if no changes were detected
            this.showToast('Error', 'No changes detected. Please modify the Pricing Elements before saving.', 'error');
        }
    }

    // validatePricingElements() {
    //     this.pricingElements = this.pricingElements.map((pricingElement) => {
    //         let isWrong = pricingElement.Quantity__c == 0 || pricingElement.Rate__c == 0;
    //         return {
    //             ...pricingElement,
    //             isWrong,
    //             rowClass: isWrong ? 'has-error' : '',
    //         };
    //     });
    // }

    // Handle cancel button click
    handleCancel() {
        this.closeScreen();
    }

    // Show toast notification
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }

    // Close the modal or action screen
    closeScreen() {
        const closeActionEvent = new CloseActionScreenEvent();
        this.dispatchEvent(closeActionEvent);
    }
}