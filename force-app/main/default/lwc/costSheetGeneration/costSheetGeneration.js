import { LightningElement, api, wire, track } from 'lwc';
import getOnLoadData from '@salesforce/apex/CostSheetGenerationController.getOnLoadData';
import createCostSheet from '@salesforce/apex/CostSheetGenerationController.createCostSheet';
import getPricingElements from '@salesforce/apex/CostSheetGenerationController.getPricingElements';
import getParkingRecords from '@salesforce/apex/CostSheetGenerationController.getParkingRecords';
import createparkingElements from '@salesforce/apex/CostSheetGenerationController.createparkingElements';
import updatePricingElements from '@salesforce/apex/CostSheetGenerationController.updatePricingElements';
import submitCostSheetForApproval from '@salesforce/apex/CostSheetGenerationController.submitCostSheetForApproval';
import checkAccess from '@salesforce/apex/CostSheetGenerationController.checkAccess';
import getUnitRecord from '@salesforce/apex/CostSheetGenerationController.getUnitRecord';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { refreshApex } from '@salesforce/apex';
import { NavigationMixin } from 'lightning/navigation';
import modal from "@salesforce/resourceUrl/QuickActionCSS";
import { loadStyle } from "lightning/platformResourceLoader";

export default class CostSheetGeneration extends NavigationMixin(LightningElement) {
    unitList = [];
    unitOptions = [];
    templateOptions = [];
    @track filteredTemplateOptions = [];
    @track wiredOnLoadData;

    isDataLoaded = false;
    isUnitDisabled = false;
    isDropdownOpen = false;
    searchKey = '';
    selectedCostSchemeId = '';
    @track showErrorBlock = false;
    @track firstScreen = true;
    @track secondScreen = false;
    @track thirdScreen = false;
    @track fourthScreen = false;
    @track isNextDisabled = false;
    @track isFourthNextDisabled = false;
    @track isFianlSaveDisabled = false;
    @track newCostSheetId = '';
    @track pricingElements = [];
    @track duplicatepricingElements = [];
    @track totalAmount = 0;
    @track parkingDetails = {};
    @track discountLineItem = [];
    @track realAmount = 0;
    @track taxAmount = 0;
    @track parkingDetailTable = false;
    @track selectedUnitRec =[];
    @track isModalOpen = false;
    @track inputBoxes = [];
    @track carParkingTax = {};

    _recordId;
    opp;

    @api
    get recordId() {
        return this._recordId;
    }
    set recordId(value) {
        this._recordId = value;
    }

    @track rows = [
        { id: 'row_1', type: '', amount: '', finalAmount: '', quantity: 1,Parking_Numbers__c : [''], carCGSTtax: '', carSGSTtax: '', taxAmt: '' }, // Initial row
    ];

    get defaultUnit() {
        debugger;
        if (this.selectedUnitId != null && this.isUnitDisabled == true) {
            return true;
        }
    }

    // get parkingType() {
    //     return [
    //         { label: 'Open', value: 'Open' },
    //         { label: 'Dependent', value: 'Dependent' },
    //         { label: 'Independent', value: 'Independent' },

    //     ];
    // }

    connectedCallback() {
        debugger;
        loadStyle(this, modal);
    }

    @wire(getOnLoadData, { recordId: '$_recordId' })
    wiredData(result) {
        debugger;
        this.wiredOnLoadData = result;
        const { error, data } = result;
        if (data) {
            this.isDataLoaded = true;
            this.showErrorBlock = (data.errorMessage != null && data.errorMessage != '') ? true : false;
            this.opp = data.opp == null || data.opp == undefined ? null : data.opp;
            this.carParkingTax = data.carParkingTax == null || data.carParkingTax == undefined ? null : data.carParkingTax;
            this.rows.carCGSTtax = data.carParkingTax.CGST__c != null || data.carParkingTax.CGST__c != undefined ? data.carParkingTax.CGST__c : 0;
            this.rows.carSGSTtax = data.carParkingTax.SGST__c != null || data.carParkingTax.SGST__c != undefined ? data.carParkingTax.SGST__c : 0;
            if (this.opp.Unit__c) {
                this.selectedUnitId = this.opp.Unit__c;
                this.isUnitDisabled = true;
            }
            this.unitList = data.unitList == undefined || data.unitList == null ? data.unitList : null;
            if (this.unitList) {
                this.unitOptions = this.unitList.map(unit => ({ label: unit.Name, value: unit.Id }));
            }

            this.templateList = data.costSheetTemplateList == undefined || data.costSheetTemplateList == null ? null : data.costSheetTemplateList;
            this.filteredTemplate();
        } else if (error) {
            this.showErrorBlock = true;
            console.log('Error:', JSON.stringify(error));
            this.showToast('Error', 'Failed to load data.', 'error');
        }
    }

    handleChangeUnit(event) {
        debugger;
        this.selectedUnitId = event.detail.id;
        console.log('selectedUnitId ===> ' + this.selectedUnitId);
        this.getUnitRecord();
        // this.selectedUnitId = event.detail.recordId;
        
    }

    getUnitRecord(){
        debugger;

        getUnitRecord({ unitId: this.selectedUnitId })
        .then(result => {
            console.log('Unit Record:', result);
            this.selectedUnitRec = result; 
            this.filteredTemplate();
        })
        .catch(error => {
            console.error('Error fetching unit record:', error);
        });

    }

    handleSearchChange(event) {
        debugger;
        this.searchKey = event.target.value;
        this.filteredTemplate(); // Re-filter templates based on the search term
    }

    toggleDropdown() {
        debugger;
        this.isDropdownOpen = !this.isDropdownOpen;
    }

    handleOptionClick(event) {
        debugger;
        const selectedValue = event.currentTarget.dataset.value;
        this.selectedCostSchemeId = selectedValue;
        const selectedOption = this.filteredTemplateOptions.find(option => option.value === selectedValue);
        this.searchKey = selectedOption.label;
        this.isDropdownOpen = false;
    }

    filteredTemplate() {
    debugger;
    if (!this.templateList || this.templateList.length === 0) {
        this.filteredTemplateOptions = [];
        return;
    }

    console.log('this.templateList==>', this.templateList);

    this.filteredTemplateOptions = this.templateList.reduce((acc, template) => {
        
        const blockLinking = template.Cost_Scheme_Linkings__r || [];
        console.log('blockLinking==>'+blockLinking);
        const unitLinking = template.Cost_Unit_Linking__r || [];
        console.log('unitLinking==>'+unitLinking);

        console.log('Processing Template:', template.Name);

        for (var i = 0; i < blockLinking.length; i++) {
    console.log('blockLinking:', blockLinking[i]);
    for (var j = 0; j < unitLinking.length; j++) {
        console.log('unitLinking:', unitLinking[j]);

        const unitMatch = unitLinking[j].Unit__c === this.selectedUnitId;
        let blockMatch = false;

        if (this.selectedUnitRec !== undefined && this.selectedUnitRec.Floor__r?.Blocks__c !== undefined) {
            blockMatch = blockLinking[i]?.Payment_Scheme__r?.Block__c === this.selectedUnitRec.Floor__r.Blocks__c;
        }

        const label = `${template.Name} - ${blockLinking[i]?.Payment_Scheme__r?.Name || 'Unknown'}`;

        if (unitMatch && blockMatch && label.toLowerCase().includes(this.searchKey.toLowerCase())) {
            acc.push({ label: label, value: `${blockLinking[i]?.Id || ''}` });
        }
    }
}
        return acc;
    }, []);
}



    handleNext() {
        debugger;
        console.log('this.opp==>' + this.opp);
        const parsedData = this.opp;

        // Extract the 'Id' value and assign it to a variable
        const oppId = parsedData.Id;

        checkAccess({ opp: oppId })
            .then(result => {
                if (result) {
                    debugger;
                    this.discountLineItem = result;
                } else if (result === 'ERROR') {
                    // this.showToast('Error', 'Cost Sheet record already exists with the same Cost Scheme Linking on this Opportunity.', 'error');
                }

            })
            .catch(error => {
                console.log('Error:', JSON.stringify(error));
                this.showToast('Error', 'Something went wrong!', 'error');
            });

        this.isNextDisabled = true;
        createCostSheet({ opp: this.opp, tasks: this.opp.Tasks, unitId: this.selectedUnitId, cslId: this.selectedCostSchemeId })
            .then(result => {
                refreshApex(this.wiredOnLoadData);
                if (result != 'ERROR') {
                    this.newCostSheetId = result;
                    this.isUnitDisabled = true;
                    this.showToast('Success', 'Cost Sheet record created successfully.', 'success');
                    this.isNextDisabled = false;
                    this.getPricingElements();
                } else if (result === 'ERROR') {
                    this.showToast('Error', 'Cost Sheet record already exists with the same Cost Scheme Linking on this Opportunity.', 'error');
                    this.isNextDisabled = false;
                }
            })
            .catch(error => {
                console.log('Error:', JSON.stringify(error));
                this.showToast('Error', 'Something went wrong!', 'error');
                this.isNextDisabled = false;
            });
    }

    getPricingElements() {
        debugger;

        getPricingElements({ costSheetId: this.newCostSheetId })
            .then(result => {

                if (result && Array.isArray(result) && result.length > 0) {
                    this.pricingElements = result;
                    this.pricingElements = this.pricingElements.map(item => {
                        return { ...item, edit: false, ActualAmount: item.Amount__c != null ? item.Amount__c : 0, permanantTax: item.Final_Tax_Amount__c != null ? item.Final_Tax_Amount__c : 0, limitExceed: "" };
                    });

                    console.log('this.discountLineItem==>' + this.discountLineItem);
                    console.log('this.pricingElements==>' + this.pricingElements);

                    for (var i = 0; i < this.discountLineItem.length; i++) {
                        for (var j = 0; j < this.pricingElements.length; j++) {
                            console.log('discountLineItem==>' + this.discountLineItem[i]);
                            console.log('pricingElements==>' + this.pricingElements[j]);
                            if (this.discountLineItem[i].Discount_Master__r.Pricing_Element_Master__c == this.pricingElements[j].Pricing_Element_Master__c) {
                                this.pricingElements[j].edit = true;
                            }
                        }

                    }
                    console.log('this.pricingElements==>' + this.pricingElements);

                    this.totalAmount = this.pricingElements.reduce((sum, element) => {
                        return sum + (element.Amount__c || 0);
                    }, 0);
                    this.formattedTotalAmount = new Intl.NumberFormat('en-IN').format(this.totalAmount);

                    this.realAmount = this.formattedTotalAmount;
                    this.taxAmount = this.pricingElements.reduce((sum, element) => {
                        return sum + (element.Final_Tax_Amount__c || 0);
                    }, 0);

                    this.totalAmount = this.totalAmount + this.taxAmount;
                    this.formattedTotalAmount = new Intl.NumberFormat('en-IN').format(this.totalAmount);
                    this.taxAmount = new Intl.NumberFormat('en-IN').format(this.taxAmount);

                    this.firstScreen = false;
                    this.secondScreen = true;

                    console.log('Pricing Elements:', JSON.stringify(this.pricingElements));


                } else if (result === 'ERROR') {
                    this.showToast('Error', 'Cost Sheet record already exists with the same Cost Scheme Linking on this Opportunity.', 'error');
                } else {
                    this.showToast('Info', 'No records found for the provided Cost Sheet ID.', 'info');
                }

            })
            .catch(error => {
                console.log('Error:', JSON.stringify(error));
                this.showToast('Error', 'Something went wrong!', 'error');
            });

    }


    handleDiscountChange(event) {
        debugger;
        const fieldName = event.target.dataset.field;
        const rowIndex = event.target.dataset.index;
        const value = parseFloat(event.target.value) || 0;

        const priceMasterId = this.pricingElements[rowIndex]['Pricing_Element_Master__c'];

        if (priceMasterId) {
            console.log('lineItems ==>' + JSON.stringify(this.discountLineItem));
            let maximumDiscountAmount = null;
            for (let i = 0; i < this.discountLineItem.length; i++) {
                console.log('priceMasterId ==>' + priceMasterId);
                console.log('lineItems ==>' + JSON.stringify(this.discountLineItem[i].Pricing_Element_Master__c));
                if (priceMasterId === this.discountLineItem[i].Discount_Master__r?.Pricing_Element_Master__c) {
                    const lineMaximum = parseFloat(this.discountLineItem[i].Maximum__c);
                    if (!isNaN(lineMaximum)) {
                        maximumDiscountAmount = maximumDiscountAmount == null
                            ? lineMaximum
                            : Math.max(maximumDiscountAmount, lineMaximum);
                    }
                }
            }

            if (maximumDiscountAmount != null && value > maximumDiscountAmount) {
                this.pricingElements[rowIndex]['limitExceed'] = "Discount Amount Limit exceeded :" + maximumDiscountAmount;
                this.showToast('Error', 'Please Enter Discount Amount Less Than ' + maximumDiscountAmount, 'error');
                return;
            }

            this.pricingElements[rowIndex]['limitExceed'] = "";
        }

        // Update the Discount_Amount__c in pricingElements
        this.pricingElements[rowIndex][fieldName] = value;

        if (fieldName === 'Discount_Amount__c') {
            const amount = this.pricingElements[rowIndex].Amount__c || 0;
            const quantity = this.pricingElements[rowIndex].Quantity__c || 0;
            const rate = this.pricingElements[rowIndex].Rate__c || 0;
            const taxAmount = this.pricingElements[rowIndex].permanantTax || 0;
            const originalTaxPercentage = (taxAmount / amount) * 100 || 0; // Calculate the original tax percentage

            if (amount > 0) {
                if (value > 0) {
                    // Discount is applied
                    const discountPercentage = (value / rate) * 100;
                    this.pricingElements[rowIndex].Discount__c = discountPercentage.toFixed(2);
                    this.pricingElements[rowIndex].ActualAmount = amount - (value * quantity);

                    // Recalculate tax based on the reduced amount
                    // const newTaxAmount = ((amount - value) * originalTaxPercentage) / 100;
                    // this.pricingElements[rowIndex].Tax_Amount__c = newTaxAmount.toFixed(2);
                } else {
                    // Discount is removed, reset to original values
                    this.pricingElements[rowIndex].Discount__c = 0;
                    this.pricingElements[rowIndex].ActualAmount = amount;

                    // Restore the original tax amount
                    // this.pricingElements[rowIndex].Tax_Amount__c = (amount * originalTaxPercentage) / 100;
                }
            }
        }

        // Calculate Total Tax Amount
        this.realAmount = this.pricingElements.reduce((sum, element) => {
            return sum + (parseFloat(element.ActualAmount) || 0); 
        }, 0);

        console.log('this.taxAmount==>' + this.taxAmount);
        console.log('this.realAmount==>' + this.realAmount);
        this.formattedTotalAmount = this.realAmount + this.taxAmount;

        // const numericRealAmount = parseFloat(this.realAmount.replace(/[^0-9.]/g, ''));
        const numericRealAmount = parseFloat(String(this.realAmount).replace(/[^0-9.]/g, ''));
        const numericTaxAmount = parseFloat(this.taxAmount);

        // Perform the calculation
        this.totalAmount = numericRealAmount + numericTaxAmount;

        // Optional: Format the result for display
        this.formattedTotalAmount = new Intl.NumberFormat('en-IN').format(this.totalAmount);
        // this.taxAmount = new Intl.NumberFormat('en-IN').format(this.taxAmount);
        // this.duplicatepricingElements = this.pricingElements;
    }


    handleThirdScreen() {
        debugger;
        this.secondScreen = false;
        this.thirdScreen = true;

    }

    handleParking(event) {
        debugger;
        this.getParkingDetails();
        this.parkingDetailTable = true;


    }

    @track parkingType = [];

    @track noParkingDetails = false;

    @track availableOpenParking = 0;

    @track availableDependantParking = 0;

    @track availableIndependantParking = 0;

    getParkingDetails() {
        debugger;

        getParkingRecords({ unitId: this.selectedUnitId })
            .then(result => {
                if (result && Array.isArray(result) && result.length > 0) {
                    this.parkingDetails = result;
                    this.parkingDetails.forEach(item => {

                        this.availableOpenParking = item.Parking_Type__c == 'Open' ? item.Available_Parking__c : this.availableOpenParking;

                        this.availableDependantParking = item.Parking_Type__c == 'Dependent' ? item.Available_Parking__c : this.availableDependantParking;

                        this.availableIndependantParking = item.Parking_Type__c == 'Independent' ? item.Available_Parking__c : this.availableIndependantParking;

                    });

                    this.parkingType = result.map(item => {

                        return { label: item.Parking_Type__c, value: item.Parking_Type__c}

                    });

                    this.noParkingDetails = false;

                    this.parkingDetailTable = true;

                }else{

                    this.noParkingDetails = true;

                    this.parkingDetailTable = false;

                }

            })
            .catch(error => {
                console.error('Error:', error);
                this.showToast('Error', 'Unable to fetch parking details.', 'error');
            });
    }

   handleParkingNumberChange(event) {
    debugger;
    const id = event.target.dataset.id;
    const index = parseInt(event.target.dataset.index, 10); // Ensure it's a number
    const newValue = event.target.value;

    let currentRow = this.rows.find(row => row.id === id);

    if (currentRow && Array.isArray(currentRow.Parking_Numbers__c)) {
        if (index >= 0 && index < currentRow.Parking_Numbers__c.length) {
            currentRow.Parking_Numbers__c[index] = { 
                ...currentRow.Parking_Numbers__c[index], 
                value: newValue 
            };
        }
        this.rows = [...this.rows]; // Ensure LWC reactivity
    }

    console.log('Updated Rows:', JSON.stringify(this.rows));
    }


    handleParkingTypeChange(event) {
        debugger;
        const index = parseInt(event.target.dataset.index, 10);
        const id = event.target.dataset.id;
        const selectedType = event.target.value;
        const name = event.target.name;
        if(name == 'parkingType'){
            for(var i=0;i<this.rows.length;i++){
                if(this.rows[i].type == selectedType){
                    this.showToast('Error', selectedType + ' Type Parking is Already Selected..', 'error');
                    return;
                }
            }
        }
        var parkingDetail = {};
        var quantity = 1;

        var currentRow = this.rows.find(item => item.id === id);
        console.log('currentRow ===> ' + currentRow);

        if(name == 'quantity'){
            quantity = selectedType;
            parkingDetail = this.parkingDetails.find(item => item.Parking_Type__c === currentRow.type);
              if (currentRow) {
                currentRow.quantity = quantity;
                
                 currentRow.Parking_Numbers__c = Array.from({ length: quantity }, (_, idx) => ({
                    key: `${currentRow.id}_${idx}`,  // Unique key
                    value: '' // Empty value for user input
                }));

              }
              console.log('Updated Rows:', JSON.stringify(currentRow));
              this.rows = [...this.rows];
        }else if(name == 'Parking_Numbers__c'){
            currentRow[name] = selectedType;
             parkingDetail = this.parkingDetails.find(
                item => item.Parking_Type__c === currentRow.type
            );
            
           
        }

        
        
        else{
            parkingDetail = this.parkingDetails.find(
                item => item.Parking_Type__c === selectedType
            );
        }

        var amount = parkingDetail != null ? parkingDetail.Amount__c : 0;
        var finalAmount = currentRow.quantity != '' && name != 'quantity' ? parkingDetail.Amount__c * currentRow.quantity : name == 'quantity' && selectedType != null ? parkingDetail.Amount__c * selectedType : 0;

        // const amount = parkingDetail ? (parkingDetail.Amount__c) : 0;
        `  console.log('Found Parking Detail:', parkingDetail);
            console.log('Amount for Selected Type:', amount);`

        
        // const previousAmount = this.rows[index]?.amount || 0;
        // this.totalAmount = this.totalAmount - previousAmount + finalAmount;

        // Format the totalAmount
        this.formattedTotalAmount = new Intl.NumberFormat('en-IN').format(this.totalAmount);
        this.rows = this.rows.map((row, rowIndex) => {
            if (rowIndex === index) {
                return {
                    ...row,
                    type: ((name == 'Parking_Numbers__c' || name == 'quantity' ) && currentRow != null) ? currentRow.type : selectedType,
                    amount: amount,
                    quantity:currentRow['quantity'],
                    carCGSTtax : this.carParkingTax.CGST__c != null || this.carParkingTax.CGST__c != undefined ? this.carParkingTax.CGST__c : 0,
                    carSGSTtax : this.carParkingTax.SGST__c != null || this.carParkingTax.SGST__c != undefined ? this.carParkingTax.SGST__c : 0,
                    finalAmount:finalAmount,
                    taxAmt: (finalAmount * (parseFloat(this.carParkingTax?.CGST__c) / 100)) +
                            (finalAmount * (parseFloat(this.carParkingTax?.SGST__c) / 100)),
                    Parking_Numbers__c: ((name == 'quantity' || name == 'type' ) && currentRow != null) ? currentRow['Parking_Numbers__c'] : currentRow['Parking_Numbers__c'],

                };
            }
            return row;
        });

        this.updateAvailableOptions();
        console.log('Updated Rows:', this.rows);
        console.log('Updated Total Amount:', this.totalAmount);
        console.log('Formatted Total Amount:', this.formattedTotalAmount);

        const numericRealAmount = parseFloat(String(this.realAmount).replace(/[^0-9.]/g, ''));
        const numericTaxAmount = parseFloat(this.taxAmount);
        var finalAmountNew = this.rows.reduce((sum, element) => {
            return sum + (parseFloat(element.finalAmount) || 0); 
        }, 0);
        this.totalAmount = numericRealAmount + numericTaxAmount + finalAmountNew;
        this.formattedTotalAmount = this.totalAmount;
    }

    updateAvailableOptions() {
        debugger;
        const selectedTypes = this.rows.map(row => row.type);

        const allOptions = [
            { label: 'Open', value: 'Open' },
            { label: 'Dependent', value: 'Dependent' },
            { label: 'Independent', value: 'Independent' },
        ];

        this.availableParkingTypes = allOptions.filter(
            option => !selectedTypes.includes(option.value)
        );
        console.log('this.availableParkingTypes==>' + this.availableParkingTypes);
    }

    handleAddRow() {
        debugger;
        const newRow = {
            id: `row_${Date.now()}`,
            type: '',
            quantity: 1,
            amount: '',
            carCGSTtax : this.carParkingTax.CGST__c != null || this.carParkingTax.CGST__c != undefined ? this.carParkingTax.CGST__c : 0,
            carSGSTtax : this.carParkingTax.SGST__c != null || this.carParkingTax.SGST__c != undefined ? this.carParkingTax.SGST__c : 0,
            taxAmt: '',
            finalAmount: '',
            Parking_Numbers__c: ['']
        };

        this.rows = [...this.rows, newRow];
    }

    handleAddRow1(event){
        debugger;
         const index = event.target.dataset.index;
        let quantity = parseInt(this.rows[index].quantity, 10);

        if (quantity > 0) {
            this.inputBoxes = [];
            for (let i = 1; i <= quantity; i++) {
                this.inputBoxes.push({ label: `Box ${i}` });
            }
            console.log('this.inputBoxes==>'+this.inputBoxes);
            this.isModalOpen = true;
        } else {
            alert('Please enter a valid quantity.');
        }
        this.isModalOpen = true;
    }

    closeModal(event){
        debugger;

        this.isModalOpen = false;
    }

    handleAddParking(event) {
        debugger;
       
    }

    handleDeleteRow(event) {
        debugger;
        const indexToDelete = parseInt(event.target.dataset.index, 10);
        console.log('Deleting row at index:', indexToDelete);

        const amountToSubtract = this.rows[indexToDelete]?.amount || 0;
        this.totalAmount -= amountToSubtract;
        this.formattedTotalAmount = new Intl.NumberFormat('en-IN').format(this.totalAmount);

        this.rows = this.rows.filter((_, rowIndex) => rowIndex !== indexToDelete);
        console.log('Updated rows:', this.rows);
        this.updateAvailableOptions();
    }

    computeDiscountedAmount(item) {
        const rate = item.Rate__c || 0;
        const quantity = item.Quantity__c || 0;
        const discount = item.Discount_Amount__c || 0;
        if (!discount) {
            return { ...item, ActualAmount: item.Amount__c };
        }
        const netRate = rate - discount;
        const netAmount = netRate * quantity;
        return { ...item, Rate__c: netRate, Amount__c: netAmount, ActualAmount: netAmount };
    }

    @track discountAdded = false;
    @track discountByPricingMap = [];
    handleFouth() {
        debugger;
        console.log('this.rows==>' + this.rows);

          for (let row of this.rows) {

            if (JSON.stringify(row.Parking_Numbers__c) === '[""]') {
                continue; // Skip this row
            }

            if (!row.Parking_Numbers__c || row.Parking_Numbers__c.length === 0) {
                this.showToast('Error', 'No Car Parking Numbers found', 'error');
                return;
            }

            if (row.Parking_Numbers__c.some(parking => parking.value.trim() === '')) {
                this.showToast('Error', 'Please Fill All Car Parking Numbers', 'error');
                return;
            
            }
    }



        if (this.rows && this.rows.length > 0) {
            this.isFourthNextDisabled = true;
            createparkingElements({ parkingElements: this.rows, costId: this.newCostSheetId })
                .then(result => {
                    console.log('Apex result:', result);
                    const newParkingElements = result.map(item => this.computeDiscountedAmount(item));
                    this.pricingElements = [...this.pricingElements, ...newParkingElements];

                    console.log('Updated pricingElements:', this.pricingElements);
                    
                    this.thirdScreen = false;
                    this.fourthScreen = true;
                    this.isFourthNextDisabled = false;
                })
                .catch(error => {
                    console.error('Error during Apex call:', error);
                    this.isFourthNextDisabled = false;
                });
        } else {
            console.log('No parking element records to send.');
        }

        this.pricingElements = this.pricingElements.map(item => this.computeDiscountedAmount(item));
        this.discountAdded = this.pricingElements.some(item => item.Discount_Amount__c != null);
        
        this.pricingElements.forEach(item => {
            if(item.Discount_Amount__c != null){
                const discountAmount = String(item.Discount_Amount__c);
                this.discountByPricingMap.push({
                    discountAmount: item.Discount_Amount__c,
                    id: item.Pricing_Element_Master__c
                });
            }
        });
        this.thirdScreen = false;
        this.fourthScreen = true;
    }


    handleFinalSave() {
        debugger;
        console.log('this.costSheetId' + this.costSheetId);
        console.log('discountByPricingMap'+ this.discountByPricingMap);
        console.log('Pricing Elements to update:', JSON.stringify(this.pricingElements));
        this.isFianlSaveDisabled = true;

        updatePricingElements({ pricingElements: this.pricingElements })
        .then(result => {
            if(this.discountAdded == true){
                console.log('submit for approval');
                this.submitForApproval();
            }
            console.log('Upsert successful:', result);
            this.showToast('Success', 'Pricing Elements are Updated Successfully..', 'success');
            this.isFianlSaveDisabled = false;
            this.closeAction();
            this.closeComponent();
        })
        .catch(error => {
            console.error('Error during upsert:', error);
            this.isFianlSaveDisabled = false;
        });
    }

    submitForApproval(){
        debugger;
        submitCostSheetForApproval({ data : JSON.stringify(this.discountByPricingMap), costSheetId : this.newCostSheetId })
        .then(result => {

        })
        .catch(error => {

        });
    }

    showToast(title, message, variant) {
        debugger;
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(event);
    }

    closeAction() {
        debugger;
        this.dispatchEvent(new CloseActionScreenEvent());
        this.closeModal();
    }

    closeModal() {
        debugger;
        // Dispatch a custom event to notify parent to close the modal
        const closeEvent = new CustomEvent('cancel');
        this.dispatchEvent(closeEvent);
    }

    closeComponent() {
        debugger;
        // Dispatch an event called "close"
        const closeEvent = new CustomEvent('close');
        this.dispatchEvent(closeEvent);
    }
}
