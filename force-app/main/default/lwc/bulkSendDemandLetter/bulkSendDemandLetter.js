import { LightningElement, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'; // Import ShowToastEvent
import getFilters from '@salesforce/apex/BulkSendDemandLetterController.getFilters';
import getTowers from '@salesforce/apex/BulkSendDemandLetterController.getTowers';
import getFilteredOpportunities from "@salesforce/apex/BulkSendDemandLetterController.getFilteredOpportunities";
import sendInstallmentIds from '@salesforce/apex/BulkSendDemandLetterController.sendInstallmentIds';

export default class BulkSendDemandLetter extends LightningElement {
    @track projectOptions = [];
    @track towerOptions = [];
    @track installmentOptions = [];
    @track selectedProject = '';
    @track selectedTower = '';
    @track selectedInstallments = [];
    @track opportunityData = [];
    @track showTable = false;

    @wire(getFilters)
    wiredFilters({ data, error }) {
        debugger;
        if (data) {
            this.projectOptions = data.projects.map(project => ({ label: project.Name, value: project.Id }));
            this.installmentOptions = data.installments.map(installment => ({ label: installment.Name, value: installment.Name }));
        } else if (error) {
            console.error(error);
        }
    }

    handleProjectChange(event) {
        this.selectedProject = event.detail.value;
        getTowers({ projectId: this.selectedProject })
            .then(data => {
                this.towerOptions = data.map(tower => ({ label: tower.Tower_Code__c, value: tower.Id }));
            })
            .catch(error => {
                console.error(error);
            });
    }

    handleTowerChange(event) {
        this.selectedTower = event.detail.value;
    }

    handleInstallmentChange(event) {
        this.selectedInstallments = event.detail.value;
    }

    handleSearch() {
        debugger;
        if (this.selectedProject == '' || this.selectedTower == '' || this.selectedInstallments == '') {
            this.showToast('Error', 'Please select all filters.', 'error');
        } else {
            getFilteredOpportunities({
                projectId: this.selectedProject,
                tower: this.selectedTower,
                installmentName: JSON.stringify(this.selectedInstallments),
            })
                .then((data) => {
                    this.opportunityData = data.map(row => ({ ...row, isSelected: false }));
                    this.showTable = true;
                })
                .catch((error) => {
                    console.error("Error fetching opportunities: ", error);
                });
        }
    }

    selectedInstallmentIds = new Set();

    handleRowSelection(event) {
        const installmentId = event.target.dataset.installmentId;
        const isChecked = event.target.checked;

        if (isChecked) {
            this.selectedInstallmentIds.add(installmentId);
        } else {
            this.selectedInstallmentIds.delete(installmentId);
        }

        const rowId = event.target.dataset.id;
        const rowIndex = this.opportunityData.findIndex(row => row.Id === rowId);
        if (rowIndex > -1) {
            this.opportunityData[rowIndex].isSelected = isChecked;
        }
    }

    handleSelectAll(event) {
        debugger;
        const isChecked = event.target.checked;

        this.opportunityData = this.opportunityData.map(row => {
            row.isSelected = isChecked;
            if (isChecked) {
                this.selectedInstallmentIds.add(row.InstallmentId);
            } else {
                this.selectedInstallmentIds.delete(row.InstallmentId);
            }
            return row;
        });


        const checkboxes = this.template.querySelectorAll('input[data-installment-id]');
        checkboxes.forEach(checkbox => {
            checkbox.checked = isChecked;
        });
    }

    handleSendToCustomer() {
        debugger
        const installmentIdList = Array.from(this.selectedInstallmentIds);

        if (installmentIdList.length === 0) {
            this.showToast('Error', 'No Installments selected.', 'error');
            return;
        }

        sendInstallmentIds({ installmentIds: installmentIdList })
            .then((result) => {

                this.showToast('Success', 'Demand Letter sent successfully.', 'success');


                this.selectedInstallmentIds.clear();
                this.opportunityData = this.opportunityData.map(row => {
                    row.isSelected = false;
                    return row;
                });


                const checkboxes = this.template.querySelectorAll('input[data-installment-id]');
                checkboxes.forEach(checkbox => {
                    checkbox.checked = false;
                });
            })
            .catch((error) => {

                console.error('Error:', error);
                this.showToast('Error', 'Error occurred while sending installments.', 'error');
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

    handleClear() {
        this.selectedProject = "";
        this.selectedTower = "";
        this.selectedInstallments = [];
        this.opportunityData = [];
        this.showTable = false;
    }
}