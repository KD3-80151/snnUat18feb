import { LightningElement, api, track } from 'lwc';
import { loadStyle } from "lightning/platformResourceLoader";
import modal from "@salesforce/resourceUrl/custommodalcss";
import getRecordDetails from '@salesforce/apex/FinaliseCostSheetController.getRecordDetails';
import createPaymentSchedule from '@salesforce/apex/FinaliseCostSheetController.createPaymentSchedule';
import sendApproval from '@salesforce/apex/FinaliseCostSheetController.sendApproval';
import { CloseActionScreenEvent } from 'lightning/modal';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class FinaliseCostSheet extends LightningElement {

    @api recordId;
    @track costSheetRecords = [];
    @track error;
    selectedCostSheetId = null;
    @track paymentSchedules = [];
    @track showButton = false;
    @track payment = false;
    @track firstScreen = true;
    @track approval = false;
    @track isDisabledNext = false;

    @track installment = 0;
    @track aggrementValue = 0;
    @track taxAmount = 0;
    @track otherCharges = 0;

    @track otherTaxAmount = 0;
    @track isDisabledApproval = false;


    @track priceElementMasterinstallment = 0;
    @track priceElementMasterDiscount = 0;
    @track priceElementMasterActualDiscount = 0;
    @track priceElementMasterActualDiscountWithoutTax = 0;
    @track priceElementMasterTaxAmount = 0;
    @track priceElementMasterQuantity = 0;
    @track priceElementMasterRate = 0;


    connectedCallback() {
        debugger;
        loadStyle(this, modal);
        console.log('this.recordId==>' + this.recordId);
        if (this.recordId) {
            this.sendRecordIdToApex();
        }
    }

    sendRecordIdToApex() {
        debugger;
        getRecordDetails({ recordId: this.recordId })
            .then(result => {
                this.costSheetRecords = result.costSheetRecords;
                this.costPricingAsstnList = result.costPricingAsstnList;

                this.costSheetRecords = this.costSheetRecords.map(costSheet => {
                    return {
                        ...costSheet,
                        isSelected: costSheet.finalize_CostSheet__c, // Mark as selected if finalized
                        trimmedCreatedDate: costSheet.CreatedDate ? costSheet.CreatedDate.split('T')[0] : null // Trim time from CreatedDate
                    };
                });
                console.log('costSheetRecords ---> '+this.costSheetRecords);

                this.paymentSchedules = result.paymentScheduleRecords;
                if (this.paymentSchedules.length > 0) {
                    this.showButton = false;
                    this.payment = true;
                    console.log('Payment schedules found:', this.paymentSchedules);

                    this.paymentSchedules = this.paymentSchedules.map((schedule, index) => {
                        // Accumulate the totals
                        this.installment += schedule.Installment__c || 0;
                        this.aggrementValue += schedule.Agreement_Value__c || 0;
                        this.taxAmount += schedule.Tax_Amount__c || 0;
                        this.otherCharges += schedule.Other_Charges__c || 0;
                        this.otherTaxAmount += schedule.Other_Tax_Amount__c || 0;

                        // Add serial number
                        return {
                            ...schedule,
                            serialNumber: index + 1, // Adding serial number starting from 1
                            Agreement_Value__c: (schedule.Agreement_Value__c || 0).toFixed(2), // Format Agreement Value
                            Tax_Amount__c: (schedule.Tax_Amount__c || 0).toFixed(2),
                            Other_Charges__c: (schedule.Other_Charges__c || 0).toFixed(2),
                            Other_Tax_Amount__c: (schedule.Other_Charges__c || 0).toFixed(2)
                        };
                    });
                    // Format the totals after all rows are processed
                    //this.installment = this.installment.toFixed(2);
                    this.aggrementValue = this.aggrementValue.toFixed(2);
                    this.taxAmount = this.taxAmount.toFixed(2);
                    this.otherCharges = this.otherCharges.toFixed(2);
                    this.otherTaxAmount = this.otherTaxAmount.toFixed(2);
                }


                if (this.costPricingAsstnList && this.costPricingAsstnList.length > 0) {
                    for (var i = 0; i < this.costPricingAsstnList.length; i++) {
                        const item = this.costPricingAsstnList[i];

                        if (item) {
                           
                            if (item.Amount__c != null) {
                                let amount = item.Amount__c.toString(); // Convert to string to handle any type
                                if (amount.includes('%')) {
                                    amount = amount.replace('%', ''); // Remove the % symbol
                                }
                                this.priceElementMasterinstallment += parseFloat(amount) || 0; // Convert to number and add
                            } else {
                                this.priceElementMasterinstallment += 0; // Add 0 if value is null
                            }

                            item.Actual_Amount__c != null ? item.Actual_Amount__c.toString() : '0';

                             this.costPricingAsstnList = [...this.costPricingAsstnList];
                       


                            this.priceElementMasterDiscount += item.Discount_Amount__c != null ? item.Discount_Amount__c : 0;
                            this.priceElementMasterActualDiscount += item.Actual_Amount__c != null ? item.Actual_Amount__c : 0;
                            this.priceElementMasterActualDiscountWithoutTax += item.Total_Amount_Excluding_Tax__c != null ? item.Total_Amount_Excluding_Tax__c : 0;
                            this.priceElementMasterTaxAmount += item.Final_Tax_Amount__c != null ? item.Final_Tax_Amount__c : 0;
                            this.priceElementMasterQuantity += item.Quantity__c != null ? item.Quantity__c : 0;
                            this.priceElementMasterRate += item.Rate__c != null ? item.Rate__c : 0;
                        }
                    }
                }
                this.error = undefined;
                console.log('this.paymentSchedules:', this.paymentSchedules);
            })
            .catch(error => {
                // this.error = error;
                // console.error('Error:', error);

            });
    }

    //  handleRadioChange(event) {
    //     debugger;
    //     this.selectedCostSheetId = event.target.value;
    //     console.log('Selected Cost Sheet Id:', this.selectedCostSheetId);
    //     this.showButton = true;
    // }

    @track selectedCostSheetTempId;
    handleRadioChange(event) {
        debugger;
        const selectedCostSheetId = event.target.value;
        const selectedCostSheetTempId = event.target.dataset.costsheettempid;
        this.selectedCostSheetTempId = selectedCostSheetTempId;
        console.log('Selected Cost Sheet Id:', selectedCostSheetId);

        // Update the selected cost sheet's isSelected property
        this.costSheetRecords = this.costSheetRecords.map(costSheet => {
            return {
                ...costSheet,
                isSelected: costSheet.Id === selectedCostSheetId // Only the selected cost sheet is marked as true
            };
        });

        // Store the selected cost sheet ID and show the Next button
        this.selectedCostSheetId = selectedCostSheetId;
        this.showButton = true; // Show the Next button once a checkbox is selected
    }

    handleNext() {
        debugger;
        if (this.selectedCostSheetId) {
            this.paymentSchedule();
            this.costSheetRecords = [];
        }
    }

    @track costPricingAsstnList= [];
    paymentSchedule() {
        debugger;
        this.isDisabledNext = true;
        createPaymentSchedule({ recordId: this.recordId, costSheetId: this.selectedCostSheetId, selectedCostSheetTempId : this.selectedCostSheetTempId })
            .then(result => {
                console.log('Apex result:', result.paymentScheduleList);
                this.isDisabledNext = false;
                this.showToast('Success', 'Payment Schedule records created successfully.', 'success');
                this.showButton = false;
                this.paymentSchedules = result.paymentScheduleList;
                this.costPricingAsstnList = result.costPricingAsstnList;

                if (this.costPricingAsstnList && this.costPricingAsstnList.length > 0) {
                    this.priceElementMasterinstallment = 0;
                    this.priceElementMasterDiscount = 0;
                    this.priceElementMasterActualDiscount = 0;
                    this.priceElementMasterActualDiscountWithoutTax = 0;
                    this.priceElementMasterTaxAmount = 0;
                    this.priceElementMasterQuantity = 0;
                    this.priceElementMasterRate = 0;
                    for (var i = 0; i < this.costPricingAsstnList.length; i++) {
                        const item = this.costPricingAsstnList[i];

                            item.Actual_Amount__c != null ? item.Actual_Amount__c.toString() : '0';

                             this.costPricingAsstnList = [...this.costPricingAsstnList];

                        if (item) {
                            // Ensure each field is checked for null or undefined
                            this.priceElementMasterinstallment += item.Amount__c != null ? item.Amount__c : 0;
                            this.priceElementMasterDiscount += item.Discount_Amount__c != null ? item.Discount_Amount__c : 0;
                            this.priceElementMasterActualDiscount += item.Actual_Amount__c != null ? item.Actual_Amount__c : 0;
                            this.priceElementMasterActualDiscountWithoutTax += item.Total_Amount_Excluding_Tax__c != null ? item.Total_Amount_Excluding_Tax__c : 0;
                            this.priceElementMasterTaxAmount += item.Final_Tax_Amount__c != null ? item.Final_Tax_Amount__c : 0;
                            this.priceElementMasterQuantity += item.Quantity__c != null ? item.Quantity__c : 0;
                            this.priceElementMasterRate += item.Rate__c != null ? item.Rate__c : 0;
                        }
                    }
                }


               

                this.paymentSchedules = this.paymentSchedules.map((schedule, index) => {
                    // Accumulate the totals
                    this.installment += schedule.Installment__c || 0;
                    this.aggrementValue += schedule.Agreement_Value__c || 0;
                    this.taxAmount += schedule.Tax_Amount__c || 0;
                    this.otherCharges += schedule.Other_Charges__c || 0;
                    this.otherTaxAmount += schedule.Other_Tax_Amount__c || 0;

                    // Add serial number
                    return {
                        ...schedule,
                        serialNumber: index + 1,
                        Agreement_Value__c: (schedule.Agreement_Value__c || 0).toFixed(2),
                        Tax_Amount__c: (schedule.Tax_Amount__c || 0).toFixed(2),
                        Other_Charges__c: (schedule.Other_Charges__c || 0).toFixed(2),
                        Other_Tax_Amount__c: (schedule.Other_Charges__c || 0).toFixed(2)
                    };
                });

                // Format the totals after all rows are processed
                //this.installment = this.installment.toFixed(2);
                this.aggrementValue = this.aggrementValue.toFixed(2);
                this.taxAmount = this.taxAmount.toFixed(2);
                this.otherCharges = this.otherCharges.toFixed(2);
                this.otherTaxAmount = this.otherTaxAmount.toFixed(2);


                this.payment = true;
                this.firstScreen = false;
                this.approval = true;
                //this.closeComponent();
            })
            .catch(error => {
                console.error('Error:', error);
                this.isDisabledNext = false;
                this.showToast('Error', 'Something went wrong!', 'error');
            });
    }

    handleApproval() {
        debugger;
        this.isDisabledApproval = true;
        console.log('this.recordId==>' + this.recordId);
        sendApproval({ recordId: this.recordId })
            .then(result => {
                this.showToast('Success', 'Approval sent Successfully..', 'success');
                console.log('Approval response:', result);
                this.isDisabledApproval = false;
                this.closeComponent();
            })
            .catch(error => {
                console.error('Error:', error);
                this.isDisabledApproval = false;
            });
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(event);
    }

    closeComponent() {
        // Dispatch an event called "close"
        const closeEvent = new CustomEvent('close');
        this.dispatchEvent(closeEvent);
    }

}