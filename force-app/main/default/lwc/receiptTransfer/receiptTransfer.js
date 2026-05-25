import { LightningElement, track, wire } from 'lwc';
import fetchProjectDetails from '@salesforce/apex/receiptTransferController.fetchProjectDetails';
import fetchTowerDetails from '@salesforce/apex/receiptTransferController.fetchTowerDetails';
import fetchAccDetails from '@salesforce/apex/receiptTransferController.fetchAccDetails';
import fetchOpportunityDetails from '@salesforce/apex/receiptTransferController.fetchOpportunityDetails';
import fetchOppDetails from '@salesforce/apex/receiptTransferController.fetchOppDetails';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import createTransferLog from '@salesforce/apex/receiptTransferController.createTransferLog';



export default class ReceiptTransfer extends LightningElement {
    @track projectOptions = [];
    @track FromBlockOptions = [];
    @track ToBlockOptions = [];
    @track fromClientOptions = [];
    @track toClientOptions = [];
    @track fromOpportunityOptions =[];
     @track toOpportunityOptions =[];
    @track transferLogDetails = {};
    @track fromOppList = [];
    @track toOppList = [];
    @track toOppListFormatted = [];
    @track disableButton = true;
    @track selectedReceiptList = [];
    @track isShowModal = false;
    @track receiptLogLineItems = [];
    @track oppIdByNameMap = new Map();
    toClientName = '';
    selectedFromOppId = '';
    @track columns = [
        { label: 'Opportunity', fieldName: 'Name', type: 'text' },
        { label: 'Project', fieldName: 'ProjectName', type: 'text' },
        { label: 'Unit', fieldName: 'UnitName', type: 'text' }
    ];

    handleRowSelection(event) {
        const selectedRows = event.detail.selectedRows;
        this.selectedToOppId = selectedRows.length > 0 ? selectedRows[0].Id : null;
    }

    processOpps() {
        debugger;
        if (this.selectedToOppId && this.selectedReceiptList.length > 0 && this.selectedFromOppId != null) {
            const newEntries = this.fromOppList.find(opp => opp.Id === this.selectedFromOppId)?.Receipts__r?.filter(receipt => this.selectedReceiptList.includes(receipt.Id)).map(receipt => ({ From_Opportunity__c: this.selectedFromOppId, To_Opportunity__c: this.selectedToOppId, Receipt__c: receipt.Id })) || [];
            this.receiptLogLineItems = [
                ...this.receiptLogLineItems.filter(item => !this.selectedReceiptList.includes(item.Receipt__c)),
                ...newEntries
            ];
            this.fromOppList = this.fromOppList.map(opp => opp.Id === this.selectedFromOppId?{...opp,Receipts__r: opp.Receipts__r.map(receipt => this.selectedReceiptList.includes(receipt.Id)? {...receipt, ToOpportunity: this.oppIdByNameMap.get(this.selectedToOppId)} : receipt)} : opp);
            this.selectedFromOppId = '';
            this.selectedToOppId = '';
            this.selectedReceiptList = [];
        } else {
            this.showToast('Error', 'Please select any Opportunity!!!', 'error');
            return;
        }
        console.log('this.receiptLogLineItems ==> ', JSON.stringify(this.receiptLogLineItems));
        this.selectedToOppId = '';
        this.hideModalBox();
    }

    showModalBox(fromOppId) {
        this.isShowModal = true;
        if (fromOppId) {
            this.selectedFromOppId = fromOppId;
            this.toOppListFormatted = this.toOppList.filter(opp => opp.Id !== fromOppId).map(opp => ({
                ...opp, ProjectName: opp.Project__r ? opp.Project__r.Name : '', UnitName: opp.Unit__r ? opp.Unit__r.Unit_Name__c : ''
            }));
        }
    }

    hideModalBox() {
        this.isShowModal = false;
    }

    @wire(fetchProjectDetails)
    wiredProjects({ data }) {
        if (data) {
            this.projectOptions = data != null ? data.map(proj => ({ label: proj.Name, value: proj.Id })) : [];
        }
    }

    handleSubmit() {
        debugger;
        // if (this.receiptLogLineItems.length > 0) {
        //     this.receiptLogLineItems = this.receiptLogLineItems.filter(item =>
        //         this.fromOppList.some(opp =>
        //             opp.Receipts__r.some(receipt => receipt.isSelected && receipt.Id === item.Receipt__c)
        //         )
        //     );
        // }
        if (this.receiptLogLineItems.length == 0) {
            this.showToast('Error', 'Please select any Receipt!!!', 'error');
            return;
        }

        if (this.receiptLogLineItems.length > 0) {
            createTransferLog({ logLineItemList: this.receiptLogLineItems, transferLogDetails: this.transferLogDetails })
            .then(data => {
                this.showToast('Success', 'Transfer Log Created Successfully!!!', 'success');
                this.handleClear();
                window.location.reload();

            })
            .catch(error => {
                this.showToast('Error', error.body.message, 'error');
                console.log(error.body.message);
            })
        }
    }

    showReceipts() {
        debugger;
        const allInputs = this.template.querySelectorAll('lightning-input, lightning-combobox');
        let isValid = true;
        allInputs.forEach(input => { if (input.reportValidity() === false) { isValid = false; } })
        if (!isValid) { this.showToast('Error', 'Please Fill all the required fields!!!', 'error'); return; }
        const matchedClient = this.toClientOptions?.find(
            acc => acc.value === this.transferLogDetails?.To_Client__c
        );

        this.toClientName = matchedClient ? matchedClient.label : null;


        fetchOppDetails({ fromAccountId: this.transferLogDetails?.From_Client__c || null,
    toAccountId: this.transferLogDetails?.To_Client__c || null,
    fromOpp: this.transferLogDetails?.From_Opportunity__c || null,
    toOpp: this.transferLogDetails?.To_Opportunity__c || null})
        .then(data => {
            if (data != null) {
             //   this.fromOppList = data.fromOppList != null && data.fromOppList.length > 0 ? data.fromOppList.map(opp => {return {...opp, isSelected: false, Receipts__r: opp.Receipts__r.map(receipt => {return {...receipt, isSelected: false, CreatedDate: new Date(receipt.CreatedDate).toLocaleDateString("en-US", { year: "numeric", month: "short", day: "numeric" })};})};}) : null;

             this.fromOppList = data.fromOppList != null && data.fromOppList.length > 0
  ? data.fromOppList.map(opp => {
      return {
        ...opp,
        isSelected: false,
        Receipts__r: Array.isArray(opp.Receipts__r)
          ? opp.Receipts__r.map(receipt => {
              return {
                ...receipt,
                isSelected: false,
                CreatedDate: new Date(receipt.CreatedDate).toLocaleDateString("en-US", {
                  year: "numeric",
                  month: "short",
                  day: "numeric"
                })
              };
            })
          : []
      };
    })
  : null;

                if(this.fromOppList){
                    this.fromOppList.forEach(opp => {
                        this.oppIdByNameMap.set(opp.Id, opp.Name);
                    })
                }else{
                    this.showToast('Error','No Opportunities found for the selected Client!!!','error');
                }
                this.toOppList = data.toOppList.length > 0 ? data.toOppList : null;
                if(this.toOppList){
                    this.toOppList.forEach(opp => {
                        if(!this.oppIdByNameMap.has(opp.Id)){
                            this.oppIdByNameMap.set(opp.Id,opp.Name);
                        }
                    })
                }
                if(this.fromOppList){
                    this.disableButton = this.fromOppList.length > 0 ? false : true;
                }
            }
        })
    }

    handleChange(event) {
        debugger;
        const value = event.target.value;
        const name = event.target.name;
        if (name != null && value != null) {
            this.transferLogDetails[name] = value;
            const commonFunction = name.includes('Project')
            ? 'fetchBlockDetails'
            : name.includes('Block')
                ? 'fetchAccountDetails'
                : name.includes('Opportunity')
                    ? 'fetchOpportunityDetails'
                    : `handle${name}`;
           // const commonFunction = name.includes('Project') ? 'fetchBlockDetails' : name.includes('Block') ? 'fetchAccountDetails' : `handle${name}`;
            this[commonFunction]?.(name, value);
        }
    }

    fetchBlockDetails(name, projectId) {
        debugger;
        const finalName = name.includes('From_Project__c') ? 'FromBlockOptions' : 'ToBlockOptions';
        fetchTowerDetails({ projectId: projectId })
        .then(data => {
            this[finalName] = data != null ? data.map(block => ({ label: block.Tower_Code__c, value: block.Id })) : [];
        })
    }

    fetchAccountDetails(name, blockId) {
        const finalName = name == 'From_Block__c' ? 'fromClientOptions' : 'toClientOptions';
        fetchAccDetails({ blockId: blockId })
        .then(data => {
            this[finalName] = data != null ? data.map(acc => ({ label: acc.Name, value: acc.Id })) : [];
            
        })

        const finalName1 = name.includes('From_Block__c') ? 'fromOpportunityOptions' : 'toOpportunityOptions';
         fetchOpportunityDetails({ blockId: blockId })
        .then(data => {
            this[finalName1] = data != null ? data.map(acc => ({ label: acc.Name, value: acc.Id })) : [];
        })
    }

    fetchOpportunityDetails(name,blockId){
        debugger;
         
    }

    handleClear() {
        this.transferLogDetails = {};
        this.fromOppList = [];
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(event);
    }

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

    allSelected(event) {
        debugger;
        const oppId = event.target.dataset.oppid;
        const isChecked = event.target.checked;
        const opp = this.fromOppList.find(o => o.Id === oppId);
        if (opp) {
            opp.isSelected = isChecked;
            opp.Receipts__r.forEach(receipt => {
                receipt.isSelected = isChecked;
            });
        }
        if (isChecked) {
            const selectedReceiptList = this.fromOppList.find(opp => opp.Id === oppId)?.Receipts__r?.filter(receipt => receipt.isSelected)?.map(receipt => receipt.Id) || [];
            this.selectedReceiptList = selectedReceiptList;
        } else {
            const deselectedReceipts = this.fromOppList.find(opp => opp.Id === oppId)?.Receipts__r?.filter(receipt => receipt.isSelected === false ) || [];
            this.receiptLogLineItems = this.receiptLogLineItems.filter(item => !deselectedReceipts.includes(item.Receipt__c));
        }
        if (this.isShowModal == false && isChecked) {
            this.showModalBox(oppId);
        }
    }

    handleCheckboxChange(event) {
        debugger;
        const receiptId = event.target.dataset.id;
        const oppId = event.target.dataset.oppid;
        const isChecked = event.target.checked;
        const opp = this.fromOppList.find(o => o.Id === oppId);
        if (opp && receiptId != null) {
            this.selectedReceiptList = receiptId;
            const receipt = opp.Receipts__r.find(r => r.Id === receiptId);
            if (receipt) {
                receipt.isSelected = isChecked;
            }
        }
        if (!isChecked) {
            this.receiptLogLineItems = this.receiptLogLineItems.filter(item => item.Receipt__c !== receiptId);
        }
        if (this.isShowModal == false && isChecked) {
            this.showModalBox(oppId);
        }
    }
}