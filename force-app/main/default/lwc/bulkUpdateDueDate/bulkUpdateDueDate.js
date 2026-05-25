import { LightningElement, track, wire, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getAllCompanies from '@salesforce/apex/bulkUpdateDueDateController.getAllCompanies';
import getProjects from '@salesforce/apex/bulkUpdateDueDateController.getProjects';
import getBlocks from '@salesforce/apex/bulkUpdateDueDateController.getBlocks';
import getpaymentScheme from '@salesforce/apex/bulkUpdateDueDateController.getpaymentScheme';
import getCostScheamLinking from '@salesforce/apex/bulkUpdateDueDateController.getCostScheamLinking';
import getPaymentInstallment from '@salesforce/apex/bulkUpdateDueDateController.getPaymentInstallment';
import saveTableData from '@salesforce/apex/bulkUpdateDueDateController.saveTableData';
import getSelectedOppPaymentSchedules from '@salesforce/apex/bulkUpdateDueDateController.getSelectedOppPaymentSchedules';
import saveOppsPaySchedulesSave from '@salesforce/apex/bulkUpdateDueDateController.saveOppsPaySchedulesSave';



import { ShowToastEvent } from 'lightning/platformShowToastEvent';
export default class BulkUpdateDueDate extends NavigationMixin(LightningElement) {
    @track companies = [];
    @track selectedCompany;
    @track selectedProject;
    @track selectedBlock;
    @track selectedScheme;
    @track showTable = false;

    @track projects = [];
    @track blocks = [];
    @track schemes = [];
    @track costSheet = [];
    @track pymentinstall = [];
    @track rows = [];


    connectedCallback() {
        this.fetchCompanies();
    }


    fetchCompanies() {
        debugger;
        getAllCompanies()

            .then(result => {
                this.companies = result;
            })
            .catch(error => {
                console.error('Error fetching companies:', error);
            });
    }
    handleCompanyChange(event) {
        debugger;
        this.selectedCompany = event.target.value;
        this.fetchProjects();
    }

    handleProjectChange(event) {
        debugger;
        this.selectedProject = event.target.value;
        this.fetchBlocks();
    }

    handleBlockChange(event) {
        debugger;
        this.selectedBlock = event.target.value;
        this.fetchScheduleScheme();
    }
    handleSchemeChange(event) {
        debugger;
        this.selectedScheme = event.target.value;
        this.fetchCostSheet();
    }
    @track showOpps=false;
    handleCostSheetChange(event) {
        debugger;
        if(event.target.value!=null){
            this.showOpps=true;
        }
        else{
            this.showOpps=false;
        }
        //this.selectedScheme = event.target.value;
        //this.fetchCostSheet();
    }
    // handleDateChange(event) {
    //     debugger;
    //     console.log('pymentinstall==>' + this.pymentinstall);

    //     const value = event.target.value;
    //     const name = event.target.dataset.field;
    //     const recid = event.target.dataset.id;
    //     this.pymentinstall = this.pymentinstall.map(row => {
    //         if (row.Id === recid) {
    //             return { ...row, [name]: value };
    //         }
    //         return row;
    //     });
    //     //console.log(`Updated ${fieldName} for row ${rowId}:`, this.pymentinstall);
    // }

    handleDateChange(event) {
        const value = event.target.value;
        const fieldName = event.target.dataset.field;
        const recId = event.target.dataset.id;
        this.pymentinstall = this.pymentinstall.map(row => {
            if (row.Id === recId) {
                let updatedRow = { ...row, [fieldName]: value };
                if (fieldName === "PayByDate") {
                    let payByDate = new Date(value);
                    payByDate.setDate(payByDate.getDate());
                    let dueDate = new Date(payByDate);
                    dueDate.setDate(dueDate.getDate() + 15);
                    updatedRow.PayByDate = payByDate.toISOString().split('T')[0];
                    updatedRow.DueDate = dueDate.toISOString().split('T')[0];
                }
                return updatedRow;
            }
            return row;
        });
    }
    handleDateChange2(event) {
        const value = event.target.value;
        const fieldName = event.target.dataset.field;
        const recId = event.target.dataset.id;
        this.oppsPaymentSchedules = this.oppsPaymentSchedules.map(row => {
            if (row.Id === recId) {
                let updatedRow = { ...row, [fieldName]: value };
                if (fieldName === "PayByDate") {
                    let payByDate = new Date(value);
                    payByDate.setDate(payByDate.getDate());
                    let dueDate = new Date(payByDate);
                    dueDate.setDate(dueDate.getDate() + 15);
                    updatedRow.Pay_Date__c = payByDate.toISOString().split('T')[0];
                    updatedRow.Due_Date__c = dueDate.toISOString().split('T')[0];
                }
                return updatedRow;
            }
            return row;
        });
    }

    /*handleDateChange1(event, rowId, fieldName) {
        debugger;
        const value = event.target.value;  
        this.pymentinstall = this.pymentinstall.map(row => {
            if (row.id === rowId) {
                return { ...row, [fieldName]: value };  
            }
            return row;
        });
    
        console.log(`Updated ${fieldName} for row ${rowId}:`, this.pymentinstall);
    }*/

    @track projectOptions = [];

    fetchProjects() {
        debugger;
        if (this.selectedCompany) {
            getProjects({ companyId: this.selectedCompany })
                .then(result => {
                    this.projects = result;


                    if (this.projects.length === 0) {
                        this.projectOptions = [{ label: 'None', value: '' }];
                        this.selectedProject = null; // Reset project selection
                    } else {
                        this.projectOptions = this.projects.map(project => ({
                            label: project.Name,
                            value: project.Id
                        }));

                        if (this.selectedProject) {
                            const selectedProjectData = this.projects.find(
                                project => project.Id === this.selectedProject
                            );
                            if (selectedProjectData) {
                                this.selectedProjectLabel = selectedProjectData.Name;
                            }
                        }

                    }

                    // Clear blocks when company changes
                    this.blocks = [];
                })
                .catch(error => {
                    console.error('Error fetching projects:', error);
                });
        }
    }




    @track blockOptions = [];
    fetchBlocks() {
        if (this.selectedProject) {
            getBlocks({ projectId: this.selectedProject })
                .then(result => {
                    this.blocks = result;

                    // Set block options for the combobox
                    if (this.blocks.length === 0) {
                        this.blockOptions = [{ label: 'None', value: '' }];
                    } else {
                        this.blockOptions = this.blocks.map(block => ({
                            label: block.Name,
                            value: block.Id
                        }));

                        // Automatically set label if selectedBlock has a value
                        if (this.selectedBlock) {
                            const selectedBlockData = this.blocks.find(
                                block => block.Id === this.selectedBlock
                            );
                            if (selectedBlockData) {
                                this.selectedBlockLabel = selectedBlockData.Name;
                            }
                        }
                    }
                })
                .catch(error => {
                    console.error('Error fetching blocks:', error);
                });
        }
    }

    @track schemeOptions = [];

    fetchScheduleScheme() {
        debugger;
        console.log('Company:', this.selectedCompany);
        console.log('Project:', this.selectedProject);
        console.log('Block:', this.selectedBlock);
        if (this.selectedCompany && this.selectedProject && this.selectedBlock) {
            getpaymentScheme({
                companyID: this.selectedCompany,
                projectId: this.selectedProject,
                blockId: this.selectedBlock
            })
                .then(result => {
                    this.schemes = result;

                    // Set block options for the combobox
                    if (this.schemes.length === 0) {
                        this.schemeOptions = [{ label: 'None', value: '' }];
                    } else {
                        this.schemeOptions = this.schemes.map(scheme => ({
                            label: scheme.Name,
                            value: scheme.Id
                        }));

                        // Automatically set label if selectedBlock has a value
                        if (this.selectedScheme) {
                            const selectedBlockData = this.schemes.find(
                                scheme => scheme.Id === this.selectedScheme
                            );
                            if (selectedBlockData) {
                                this.selectedBlockLabel = selectedBlockData.Name;
                            }
                        }
                    }
                })
                .catch(error => {
                    console.error('Error fetching blocks:', error);
                });
        }
    }

    @track CostSheetOptions = [];

    fetchCostSheet() {
        debugger;
        console.log('paymentSchene:', this.selectedScheme);

        if (this.selectedScheme) {
            getCostScheamLinking({ paymentScheme: this.selectedScheme })
                .then(result => {
                    this.costSheet = result;

                    // Set block options for the combobox
                    if (this.costSheet.length === 0) {
                        this.CostSheetOptions = [{ label: 'None', value: '' }];
                    } else {
                        this.CostSheetOptions = this.costSheet.map(cosSheet => ({
                            label: cosSheet.Cost_Sheet_Template__r.Name,
                            value: cosSheet.Id
                        }));

                        // Automatically set label if selectedBlock has a value
                        if (this.selectedScheme) {
                            const selectedBlockData = this.costSheet.find(
                                cosSheet => cosSheet.Id === this.selectedScheme
                            );
                            if (selectedBlockData) {
                                this.selectedBlockLabel = selectedBlockData.Name;
                            }
                        }
                    }
                })
                .catch(error => {
                    console.error('Error fetching blocks:', error);
                });
        }
    }
    updateRenderedRows() {
        debugger;
        console.log('this.rows' + this.rows);
        this.pymentinstall = this.rows.map((row, index) => ({
            ...row,
            index: index + 1 // 1-based index
        }));
        console.log('this.pymentinstall===>' + this.pymentinstall);
    }
    @track oppsPaymentSchedules=[];
    handleShow() {
        debugger;
        const selectedScheme = this.selectedScheme;
        if(this.selectedOpp && this.selectedScheme!=null ){
            getSelectedOppPaymentSchedules({opportunityId:this.selectedOpp})
            .then(result=>{
                this.oppsPaymentSchedules=result.map((record,index)=>({
                    ...record,
                    index:index+1
                }));
            })
        }
        else if (this.selectedScheme) {
            getPaymentInstallment({ paymentScheme: this.selectedScheme })
                .then(result => {
                    this.pymentinstall = result.map(record => ({
                        ...record,
                        Payment_Schedule_Master__c: record.Payment_Schedule_Master__r
                            ? record.Payment_Schedule_Master__r.Name
                            : 'N/A' // Adjust based on your fields
                    }));
                    this.rows = this.pymentinstall;
                    this.updateRenderedRows();
                    this.showTable = true;
                })
                .catch(error => {
                    console.error('Error fetching data:', error);
                });
        } else {
            console.warn('No schedule scheme selected');
        }
    }
    handleSave() {
        debugger;
        // let isValid = true; // Validation flag

        // // Validate each row in the pymentinstall array
        // this.pymentinstall.forEach(row => {
        //     // Find the corresponding inputs for the current row
        //     const dueDateInput = this.template.querySelector(
        //         `lightning-input[data-id="${row.Id}"][data-field="DueDate"]`
        //     );
        //     const payByDateInput = this.template.querySelector(
        //         `lightning-input[data-id="${row.Id}"][data-field="PayByDate"]`
        //     );

        //     // Check if DueDate is empty
        //     if (!row.DueDate || row.DueDate.trim() === '') {
        //         dueDateInput.setCustomValidity('Due Date is required');
        //         dueDateInput.reportValidity();
        //         isValid = false;
        //     } else {
        //         dueDateInput.setCustomValidity(''); // Clear the error
        //     }
        //     dueDateInput.reportValidity(); // Re-render validity state

        //     // Check if PayByDate is empty
        //     if (!row.PayByDate || row.PayByDate.trim() === '') {
        //         payByDateInput.setCustomValidity('Pay By Date is required');
        //         payByDateInput.reportValidity();
        //         isValid = false;
        //     } else {
        //         payByDateInput.setCustomValidity(''); // Clear the error
        //     }
        //     payByDateInput.reportValidity(); // Re-render validity state
        // });

        // Stop if validation fails
        // if (!isValid) {
        //     // Optionally, show a toast for global feedback
        //     this.showToast('Error', 'Please fill in all required fields.', 'error');
        //     return;
        // }


        const payload = {
            projectId: this.selectedProject,
            paymentSchemeId: this.selectedScheme,
            paymentInstallments: this.pymentinstall.map(row => ({
                id: row.Id,
                Name: row.Payment_Schedule_Master__c,
                dueDate: row.DueDate,
                payByDate: row.PayByDate
            }))
        };

        saveTableData({ payload: JSON.stringify(payload) })
            .then(() => {
                console.log('Data saved successfully!');
                this.showToast('Success', 'Due Date and Pay By Date are updated successfully.', 'success');

                // this[NavigationMixin.Navigate]({
                //     type: 'standard__recordPage',
                //     attributes: {
                //         recordId: this.selectedScheme, // Replace with your schedule scheme ID
                //         objectApiName: 'Payment_Scheme__c', // Replace with the API name of your object
                //         actionName: 'view'
                //     }
                // });
                setTimeout(() => {
                    window.location.reload();
                }, 500); 
            })
            .catch(error => {
                console.error('Error saving data:', error);
                this.showToast('Error', 'An error occurred while saving data.', 'error');
            });
    }
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title,
            message,
            variant,
        });
        this.dispatchEvent(event);
    }

    get companyOptions() {
        debugger;
        return this.companies.map(company => ({
            label: company.Name,
            value: company.Id
        }));
    }
    @track selectedOpp;
    handleChangeOpportunity(event){
        debugger;
        this.selectedOpp=event.detail.id; 
        if(this.selectedOpp==null){
            this.oppsPaymentSchedules=[];
        }       
    }
    handleOppsPaySchedulesSave(){
        debugger;
        this.oppsPaymentSchedules=this.oppsPaymentSchedules.map(record=>({
            ...record,
            id:record.Id,
            dueDate:record.Due_Date__c,
            payDate:record.Pay_Date__c
        }))
        saveOppsPaySchedulesSave({paymentSchedules:JSON.stringify(this.oppsPaymentSchedules)})
        .then(result=>{
            this.showToast('Success', 'Due Date and Pay By Date are updated successfully.', 'success');
             setTimeout(() => {
                    window.location.reload();
                }, 500); 
        })
        .catch(error => {
                console.error('Error saving data:', error);
                this.showToast('Error', 'An error occurred while saving data.', 'error');
        });
    }
}