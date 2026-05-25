import { api, LightningElement, track, wire } from 'lwc';
import SnnLogo from '@salesforce/resourceUrl/SnnLogo';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getProjectPicklistDetails from '@salesforce/apex/bookingFormController.getProjectPicklistDetails';
import createApplicants from '@salesforce/apex/bookingFormController.createApplicants';
import noOfApplicants from '@salesforce/label/c.No_Of_Applicants';
import bookingFormProfile from "@salesforce/resourceUrl/bookingFormProfile";
import Salutation from '@salesforce/schema/Contact.Salutation';
 
export default class BookingForm extends LightningElement {
    imageUrl = SnnLogo;
    profilePic = bookingFormProfile;
    @track nextText = 'Creating Co-Applicant Records....';
    @track showSpinner = false;

    @api recordId; // = '006Dy00000CyTSuIAN';
    @track dateval;
    @track showOtherDetails = true;
    @track purposeOfPurchaseOptions = [];
    @track sourceOfFundingOptions = [];
    @track sourceOfInfoOptions = [];
    @track workFunctionOptions = [];
    @track residentStatusOptions = [];
    @track annualIncomeOptions = [];
    @track designationOptions = [];
    @track industryOptions = [];
    @track salutationOptions = [];
    @track permanentStateOptions;
    @track addressForCommStateOptions = [];
    @track permanentCountryOptions;
    @track addressForCommCountryOptions = [];
    @track unitAndTypeValue = '';
    @track applicantList = [];
    @track applicantRec = {};
    @track profileDataList = [];
    
    handleUploadClick(event) {
        debugger;
        const index = event.target.dataset.number;
        this.template.querySelector(`input.file-input[data-number="${index}"]`).click();
        // this.template.querySelector('input.file-input').click();
    }

    handleFileChange(event) {
    debugger;
    const index = parseInt(event.target.dataset.number, 10);
    const name = event.target.name;
    const applicantRec = this.applicantList.find(app => app.Number === index);
    if (applicantRec && name === 'profilePicData') {
        const file = event.target.files[0];
        if (file) {
            if(file.size > 204800 || file.size < 20480){
                this.showToast('Error', 'File size should be between 20kb to 200kb', 'error');
                return;
            }else{
                applicantRec.fileName = file.name;
                const reader = new FileReader();
                reader.onload = () => {
                    const base64Data = reader.result.split(',')[1];
                    applicantRec.base64Data = base64Data; 
                    applicantRec.imageUrl = reader.result;
                    const profileRec = {
                        fileName: applicantRec.fileName,
                        base64Data: base64Data,
                        Name: applicantRec.Name
                    };
                    this.profileDataList = [...this.profileDataList, profileRec];
                    this.applicantList = [...this.applicantList];
                    console.log('Profile Data List:', JSON.stringify(this.profileDataList));
                };
                reader.readAsDataURL(file);
            }
        }
    }
}

    
    // handleFileChange(event) {
    //     debugger;
    //     const index = parseInt(event.target.dataset.number, 10);
    //     var name = event.target.name;
    //     var applicantRec = this.applicantList.find(app => app.Number == index);
    //     if(applicantRec && name == 'profilePicData'){
    //         const file = event.target.files[0]; 
    //         if (file) {
    //             applicantRec.fileName = file.name; 
    //             const reader = new FileReader();
    //             reader.onload = () => {
    //                 applicantRec.base64Data = reader.result.split(',')[1]; 
    //                 applicantRec.imageUrl = reader.result;
    //             };
    //             reader.readAsDataURL(file); 

    //             var profileRec = {
    //                 fileName : applicantRec.fileName,
    //                 base64Data : reader.result.split(',')[1],
    //                 Number : index
    //             }
    //         }
    //     }
        
    //     this.profileDataList.push(profileRec);

    //     this.applicantList = [...this.applicantList];
    // }

    toggleSection(event) {
        debugger;
        const buttonId = event.currentTarget.dataset.buttonid; 
        const allSections = this.template.querySelectorAll('[data-id]');
        allSections.forEach(section => {
            if (section.dataset.id !== buttonId) {
                section.classList.remove('slds-is-open');
                section.classList.add('slds-is-close');
            }
        });
        const currentSection = this.template.querySelector(`[data-id="${buttonId}"]`);
        if (currentSection.classList.contains('slds-is-open')) {
            currentSection.classList.remove('slds-is-open');
            currentSection.classList.add('slds-is-close');
        } else {
            currentSection.classList.remove('slds-is-close');
            currentSection.classList.add('slds-is-open');
        }
    }

    objByField = {
        Resident_Status__c: 'Account',
        Industry__c: 'Account',
        Designation__c: 'Account',
        Annual_Household_Income__c: 'Account',
        Purpose_of_Purchase__c: 'Account',
        Source_of_Information__c: 'Account',
        Source_of_Funding__c: 'Account',
        Work_Function_Role__c: 'Account',
        Salutation__c: 'Account'
    };

    ObjectByFieldAddress = {
        Permanent_Address__CountryCode__s: 'Account',
        Address_for_Communication__CountryCode__s: 'Account',
        Permanent_Address__StateCode__s: 'Account',
        Address_for_Communication__StateCode__s: 'Account'
    };
    
    connectedCallback() {
        debugger;
        const urlParams = new URLSearchParams(window.location.search);
        this.recordId = urlParams.get('c__recordId');
        console.log('Fetched Record ID:', this.recordId);
        console.log('noOfApplicants ===> ' + noOfApplicants);        
        this.getOnLoadData();
    }

    addAnotherApplicant(){
        debugger;
        const applicantListLength = this.applicantList.length;
        if(applicantListLength >= noOfApplicants){
            this.showToast('Error', 'You can add maximum of ' + noOfApplicants + ' Applicants Only!!!', 'error');
            return;
        }
        const lastApplicant = this.applicantList[applicantListLength - 1];
        const applicantRec = {
            Number              : lastApplicant.Number + 1,
            Opportunity__c      : this.recordId != null ? this.recordId : null,
            sourceOfInfo        : 'Source_of_Information__c' + lastApplicant.Number + 1,
            residentStatus      : 'Resident_Status__c' + lastApplicant.Number + 1,
            industry            : 'Industry__c' + lastApplicant.Number + 1,
            designation         : 'Designation__c' + lastApplicant.Number + 1,
            annualHousehold     : 'Annual_Household_Income__c' + lastApplicant.Number + 1,
            purposeOfPurchase   : 'Purpose_of_Purchase__c' + lastApplicant.Number + 1,
            sourceOfFunding     : 'Source_of_Funding__c' + lastApplicant.Number + 1,
            workFunction        : 'Work_Function_Role__c' + lastApplicant.Number + 1,
            Salutation          : 'Salutation__c' + lastApplicant.Number + 1,
            imageUrl            : this.profilePic,
            Application_Date__c : this.dateval,
            deleteIcon          : true
        }
        this.applicantList.push(applicantRec);
        console.log('applicantRec ==> ' + JSON.stringify(this.applicantList));
    }


    deleteApplicant(event) {
        debugger;
        const index = event.target.dataset.index;
        this.applicantList.splice(index, 1);
        console.log('Updated applicantList ==> ' + JSON.stringify(this.applicantList));

        this.applicantDocumentsList.splice(index, 1); 
        console.log('Updated applicantDocumentsList ==> ' + JSON.stringify(this.applicantDocumentsList));
    }

    @track accountId;
    @track primaryApplicant={};
    @track nextText = 'Creating Co-Applicant Records....';
    handleSubmit(){
        debugger;
        const hasEmptyApplicantRecName = this.applicantList.some(item => !item.Name);
        const hasEmptyApplicantRecEmail = !this.applicantList[0].Email__c;
        const hasEmptyApplicantRecPhone = !this.applicantList[0].Phone;
        if(hasEmptyApplicantRecName){
            this.showToast('Error', 'Name has to be added to each Applicant Details!!!', 'error');
            return;
        }
        if(hasEmptyApplicantRecEmail){
            this.showToast('Error', 'Email has to be added to Primary Applicant Details!!!', 'error');
            return;
        }
        if(hasEmptyApplicantRecPhone){
            this.showToast('Error', 'Primary Contact Number has to be added to Primary Applicant Details!!!', 'error');
            return;
        }
        this.showSpinner = true;

        this.applicantList = this.applicantList.map(applicant => {
            return Object.keys(applicant)
                .filter(key => key === 'Name' || key === 'Phone' || key.endsWith('__c') || key.endsWith('__s'))
                .reduce((obj, key) => {
                    obj[key] = applicant[key];
                    return obj;
                }, {});
        });

        this.applicantList = this.applicantList.map(item => ({
            ...item,
            Applicant_Date__c : this.dateval
        }));
        
        console.log('Filtered Applicant List:', JSON.stringify(this.applicantList));        
        
        this.primaryApplicant = { 
            ...this.applicantList[0], 
            Primary_Applicant__c: true,
            Id : this.accountId,
            Name : this.applicantList[0].First_Name__c + ' ' + this.applicantList[0].Last_Name__c
        };
            
        this.applicantList.shift();
        this.applicantList = [...this.applicantList];

        console.log('applicantRec ==> ' + JSON.stringify(this.applicantList));
        createApplicants({ applicantList : this.applicantList, oppId : this.recordId, profileDataList : JSON.stringify(this.profileDataList), accId : this.accountId, primaryApplicant : this.primaryApplicant })
        .then(result => {
            if(result.startsWith('Success')){
                this.showToast('Success', 'Applicant Details Created Successfully!!!', 'success');
                this.showSpinner = false;
                this.handleCancel();
            }else{
                this.showToast('Error', 'Error Processing Applicant Details!!!', 'error');
                this.nextText = 'Error Processing Applicant Details!!!!';
            }
            
        })
        .catch(error => {
            this.showToast('Error', error, 'error');
            this.nextText = 'Error Processing Applicant Details!!!!';
        });
    }

    handleCancel(){
        if(this.recordId != null && this.recordId != ''){
            const recordId = this.recordId;
            window.top.location.href = `/lightning/r/Opportunity/${recordId}/view`;
        }else{
            window.top.location.href = '/lightning/o/Opportunity/list';
        }
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(event);
    }

    handleChange(event){
        debugger;
        const name = event.target.name;
        const value = event.target.value;
        const index = parseInt(event.target.dataset.number, 10);
        const radioname = event.target.dataset.radioname;
        const type = event.target.type;
        console.log('Index :', index);
        var applicantRec = this.applicantList.find(app => app.Number == index);

        if(type === 'radio'){
            applicantRec[radioname] = value;
        }else if(name === 'todaydate'){
            this.dateval = value;
        }else{
            applicantRec[name] = value;
        }
                applicantRec['Name'] = (applicantRec.First_Name__c || '') + ' ' + (applicantRec.Last_Name__c || '');
        

        this.applicantList = [...this.applicantList];
        console.log('applicantRec ==> ' + JSON.stringify(this.applicantList));
    }

    @track projectName = '';
    @track RERA_No = '';
    @track SuperBuiltUpArea = '';
    @track RERA_No = '';
    getOnLoadData() {
        getProjectPicklistDetails({ oppId : this.recordId, ObjectByField: this.objByField, ObjectByFieldAddress : this.ObjectByFieldAddress })
            .then(result => {
                debugger;
                if(result.oppRec){
                    const applicantRec = {
                        Number              : 1,
                        Opportunity__c      : this.recordId != null ? this.recordId : null,
                        sourceOfInfo        : 'Source_of_Information__c' + 1,
                        residentStatus      : 'Resident_Status__c' + 1,
                        industry            : 'Industry__c' + 1,
                        designation         : 'Designation__c' + 1,
                        annualHousehold     : 'Annual_Household_Income__c' + 1,
                        purposeOfPurchase   : 'Purpose_of_Purchase__c' + 1,
                        sourceOfFunding     : 'Source_of_Funding__c' + 1,
                        workFunction        : 'Work_Function_Role__c' + 1,
                        Salutation          : 'Salutation__c' + 1,
                        imageUrl            : this.profilePic,
                        Application_Date__c : result.todayDate
                    }
                    this.applicantList.push(applicantRec);
                    console.log('applicantList ===> ' + JSON.stringify(this.applicantList));
                    this.dateval = result.todayDate;
                    this.accountId          = result.oppRec.AccountId;
                    const type              = result.oppRec.Type != null ? result.oppRec.Type : null;
                    const unit              = result.oppRec.Unit__r.Unit_Name__c != null ? result.oppRec.Unit__r.Unit_Name__c : null;
                    this.projectName        = result.oppRec.Project__r.Name != null ? result.oppRec.Project__r.Name : null;
                    this.unitAndTypeValue   = [unit, type].filter(value => value).join(',');
                    this.SuperBuiltUpArea   = result.oppRec.Unit__r.Super_Built_Up_Area_sq_ft__c != null ? result.oppRec.Unit__r.Super_Built_Up_Area_sq_ft__c : null;
                    this.RERA_No            = result.oppRec.Project__r.Company__r.Registration_Number__c != null ? result.oppRec.Project__r.Company__r.Registration_Number__c : null;
                }
                if(result.picklistValByField){
                    this.residentStatusOptions      = this.mapToLabelValuePair(result.picklistValByField['Resident_Status__c']);
                    this.industryOptions            = this.mapToLabelValuePair(result.picklistValByField['Industry__c']);
                    this.designationOptions         = this.mapToLabelValuePair(result.picklistValByField['Designation__c']);
                    this.annualIncomeOptions        = this.mapToLabelValuePair(result.picklistValByField['Annual_Household_Income__c']);
                    this.purposeOfPurchaseOptions   = this.mapToLabelValuePair(result.picklistValByField['Purpose_of_Purchase__c']);
                    this.sourceOfInfoOptions        = this.mapToLabelValuePair(result.picklistValByField['Source_of_Information__c']);
                    this.sourceOfFundingOptions     = this.mapToLabelValuePair(result.picklistValByField['Source_of_Funding__c']);
                    this.workFunctionOptions        = this.mapToLabelValuePair(result.picklistValByField['Work_Function_Role__c']);
                    this.salutationOptions          = this.mapToLabelValuePair(result.picklistValByField['Salutation__c']);
                }
                if(result.picklistValForAddress){
                    this.permanentStateOptions          = (result.picklistValForAddress['Permanent_Address__StateCode__s']);
                    this.addressForCommStateOptions     = (result.picklistValForAddress['Address_for_Communication__StateCode__s']);
                    this.permanentCountryOptions        = (result.picklistValForAddress['Permanent_Address__CountryCode__s']);
                    this.addressForCommCountryOptions   = (result.picklistValForAddress['Address_for_Communication__CountryCode__s']);
                }
            })
            .catch(error => {
                console.error('Error==>' + error);
            });
    }

    mapToLabelValuePair(values) {
        return values.map(value => ({
            label: value, value: value
        }));
    }
}