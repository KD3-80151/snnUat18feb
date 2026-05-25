import { LightningElement, track, wire } from 'lwc';
import fetchCompanyDetails from '@salesforce/apex/ReceiptReAllocationController.fetchCompanyDetails';
import fetchProjectDetails from '@salesforce/apex/ReceiptReAllocationController.fetchProjectDetails';
import fetchBlockDetails from '@salesforce/apex/ReceiptReAllocationController.fetchBlockDetails';
import getAllClients from '@salesforce/apex/ReceiptReAllocationController.getAllClients';

export default class ReceiptReAllocation extends LightningElement {
    @track companyOptions = [];
    @track projectOptions = [];
    @track blockOptions = [];
    @track allClientList = [];
    @track showclientdetails = false;

    get shouldshowclientdetails() {
        return this.allClientList.length > 0 && this.showclientdetails;
    }

    @wire(fetchCompanyDetails)
        wiredProjects({ data }) {
            if (data) {
                this.companyOptions = data != null ? data.map(company => ({ label: company.Name, value: company.Id })) : [];
            }
        }

    handleChange(event) {
        debugger;
        const value = event.target.value;
        const name = event.target.name;
        if (name != null && value != null) {
            this.name = value;
            const commonFunction = name.includes('Company') ? 'fetchProjDetails' : name.includes('Project') ? 'fetchBloDetails' : name.includes('Block') ? 'fetchClients' : `handle${name}`;
            this[commonFunction]?.(name, value);
        }
    }

    fetchProjDetails(name, companyId) {
        debugger;
        fetchProjectDetails({ companyId: companyId })
            .then(data => {
                this.projectOptions = data ? data.map(project => ({ label: project.Name, value: project.Id })) : [];
            })
            .catch(error => {
                console.error('Error fetching project details:', error);
                this.projectOptions = [];
            });
    }
    
    fetchBloDetails(name, projectId) {
        debugger;
        fetchBlockDetails({ projectId: projectId })
            .then(data => {
                this.blockOptions = data ? data.map(block => ({ label: block.Name, value: block.Id })) : [];
            })
            .catch(error => {
                console.error('Error fetching block details:', error);
                this.blockOptions = [];
            });
    }

    fetchClients(name,BlockId){
        
        getAllClients({BlockId : BlockId})
        .then(data => {
            if (data) {
                this.allClientList = data.map(item => ({
                    ...item.oppDetails,
                    TotalReceipts: item.totalNumberOfReceipts
                }));
            } else {
                debugger;
            }
        })
        .catch(error => {
            console.error('Error fetching client details:', error);
            debugger;
            this.allClientList = [];
            this.showclientdetails = false; // Ensure it's false if there's an error
        }); 
    }

    showClientTable(){
        debugger;
        const allInputs = this.template.querySelectorAll('lightning-combobox');
        let isValid = true;
        allInputs.forEach(input => {if(input.reportValidity() === false){isValid = false;}})
        if(!isValid){this.showToast('Error', 'Please Fill all the required fields!!!', 'error'); return;}
        debugger;
        this.showclientdetails = true;
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(event);
    }

    handleRowSelection(event) {
        const clientId = event.target.dataset.id;
        if (event.target.checked) {
            this.selectedClients.add(clientId);
        } else {
            this.selectedClients.delete(clientId);
        }
        console.log('Selected Clients:', Array.from(this.selectedClients));
    }

    handleSelectAll(event) {
        debugger;
        const checkboxes = this.template.querySelectorAll('input[type="checkbox"]');
        debugger;
        if (event.target.checked) {
            debugger;
            checkboxes.forEach(checkbox => {
                checkbox.checked = true;
                if (checkbox.dataset.id) {
                    this.selectedClients.add(checkbox.dataset.id);
                }
            });
        } else {
            checkboxes.forEach(checkbox => {
                checkbox.checked = false;
                this.selectedClients.clear();
            });
        }
        console.log('Selected Clients:', Array.from(this.selectedClients));
    }
}