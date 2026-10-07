//---sagar---
import { api, LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getProjectPicklistDetails from '@salesforce/apex/bookingFormButtonController.getProjectPicklistDetails';
import createApplicants from '@salesforce/apex/bookingFormButtonController.createApplicants';
import uploadDocuments from '@salesforce/apex/bookingFormButtonController.uploadDocuments';
import noOfApplicants from '@salesforce/label/c.No_Of_Applicants';
import bookingFormProfile from "@salesforce/resourceUrl/bookingFormProfile";


export default class BookingFormButtons extends LightningElement {
    
    profilePic = bookingFormProfile;

    @api recordId; // = '006Dy00000CyTSuIAN';
    @track dateval;
    @track showOtherDetails = true;
    @track purposeOfPurchaseOptions = [];
    @track sourceOfFundingOptions = [];
    @track sourceOfInfoOptions = [];
    @track workFunctionOptions = [];
    @track residentStatusOptions = [];
    @track typeOptions = [];
    @track status = [];
    @track annualIncomeOptions = [];
    @track designationOptions = [];
    @track industryOptions = [];
    @track yoEoptions = [];
    @track salutationOptions = [];
    @track permanentStateOptions =[];
    @track addressForCommStateOptions = [];
    @track permanentCountryOptions = [];
    @track addressForCommCountryOptions = [];
    @track unitAndTypeValue = '';
    @track applicantList = [];
    @track applicantRec = {};
    @track profileDataList = [];
    @track applicantDocumentsList = [];
    @track showSpinner = false;
    @track spinnerText = 'Account Details are Saving...';
    @track selectedDocName = '';

    handleUploadClick(event) {
        const index = event.target.dataset.number;
        const name = event.target.name;
        const uploadName = event.target.dataset.uploadname;
        const id = event.target.dataset.id;
        this.selectedDocName = uploadName;

        let inp;
        if (name === 'uploadDocuments' && id != null) {
            inp = this.template.querySelector(`input.file-input[data-id="${id}"]`);
        } else {
            inp = this.template.querySelector(`input.file-input[data-number="${index}"]`);
        }
        console.log('::inp' + inp);
        if (inp) {
            inp.value = null; // or ''
            inp.click();
        }
        }

    handleFileChange(event) {
        debugger;
        const index = parseInt(event.target.dataset.number, 10);
        const name = event.target.name;
        const file = event.target.files[0];
        let applicantRec = this.applicantList.find(app => app.Number === index);

        if(name == 'uploadDocuments'){
            const uploadname = this.selectedDocName;
            if(file.type != 'application/pdf'){
                this.showToast('File Type', 'Only PDF file type is allowed', 'error');
                return;
            }else if(file.size > 2097152){
                this.showToast('Error', 'File size should be less than 2MB', 'error');
            }else{
                if(uploadname != null){
                    applicantRec[`${uploadname}PendingName`] = file.name;

                    let currentApplicantDocRec = this.applicantDocumentsList.find(item => item.Number === index);
                    console.log('currentApplicantDocRec ===> ' + JSON.stringify(currentApplicantDocRec));
                    applicantRec ={
                        ...applicantRec,
                        [uploadname] : file.name
                    };
                    const reader = new FileReader();
                    reader.onload = () => {
                        const base64Data = reader.result.split(',')[1];
                        currentApplicantDocRec = {
                            ...currentApplicantDocRec,
                            Name: applicantRec.Name,
                            [uploadname]: base64Data,
                            [`${uploadname}FileName`]: file.name
                        };

                        this.applicantDocumentsList = this.applicantDocumentsList.map(doc =>
                            doc.Number === index ? currentApplicantDocRec : doc);

                            applicantRec[`${uploadname}PendingName`] = file.name;
                            this.applicantList = this.applicantList.map(app => app.Number === index ? applicantRec : app);

                        console.log('currentApplicantDocRec ===> ' + JSON.stringify(currentApplicantDocRec));
                        console.log('applicantList ===> ' + JSON.stringify(this.applicantList));
                        console.log('document Data List:'+ JSON.stringify(this.applicantDocumentsList));
                    };
                    reader.readAsDataURL(file);
                }
            }
        }else{
            if (applicantRec && name === 'profilePicData') {
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
    }

    sleep(ms) { return new Promise(res => setTimeout(res, ms)); }

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
        Type: 'Account',
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

    addAnotherApplicant() {
        debugger;
        const n = this.applicantList.length;
        if (n >= noOfApplicants) {
            this.showToast('Error', `You can add maximum of ${noOfApplicants} Applicants Only!!!`, 'error');
            return;
        }

        const nextNumber = n === 0 ? 1 : (this.applicantList[n - 1].Number + 1);

        const acc = {
            Number: nextNumber,
            Opportunity__c: this.recordId || null,
            uploadDocuments: `uploadDocuments${nextNumber}`,

            firstName: '',
            lastName:  '',

            // picklist fields (values)
            Salutation__c: null,
            Type: null,
            Industry__c: null,
            Designation__c: null,
            Annual_Household_Income__c: null,
            Purpose_of_Purchase__c: null,
            Source_of_Funding__c: null,
            Work_Function_Role__c: null,
            Source_of_Information__c: null,
            Resident_Status__c: null,

            // addresses & misc you render
            Permanent_Address__Street__s: null,
            Permanent_Address__City__s: null,
            Permanent_Address__CountryCode__s: null,
            Permanent_Address__StateCode__s: null,
            Permanent_Address__PostalCode__s: null,

            Address_for_Communication__Street__s: null,
            Address_for_Communication__City__s: null,
            Address_for_Communication__CountryCode__s: null,
            Address_for_Communication__StateCode__s: null,
            Address_for_Communication__PostalCode__s: null,

            Phone: null,
            Alternate_Contact_Number__c: null,
            Email__c: null,
            Official_Email__c: null,

            // ui-only
            imageUrl: this.profilePic,
            Application_Date__c: this.dateval,
            deleteIcon: true,
            _typeOptions: [],
            _residentOptions: [],
            _industryOptions: [],
            _orgTypeOptions: [],
            _desigOptions: [],
            _incomeOptions: [],
            _yoeOptions: [],
            _purposeOptions: [],
            _sourceInfoOpts: [],
            _fundingOptions: [],
            _workFnOptions: [],
            _salutationOptions: [],
        };

        acc.Name = ''; 
        this.applicantList = [...this.applicantList, acc];

        this.refreshDecoratedOptions(acc, 'Type');
        this.refreshDecoratedOptions(acc, 'Industry__c');
        this.refreshDecoratedOptions(acc, 'Designation__c');
        this.refreshDecoratedOptions(acc, 'Annual_Household_Income__c');
        this.refreshDecoratedOptions(acc, 'Purpose_of_Purchase__c');
        this.refreshDecoratedOptions(acc, 'Source_of_Funding__c');
        this.refreshDecoratedOptions(acc, 'Source_of_Information__c');
        this.refreshDecoratedOptions(acc, 'Work_Function_Role__c');
        this.refreshDecoratedOptions(acc, 'Salutation__c');
        this.refreshDecoratedOptions(acc, 'Resident_Status__c');

        this.applicantDocum
        this.applicantList = [...this.applicantList];
        }

        @track deletedAccountIds = [];


    deleteApplicant(event) {
        debugger;
        const index = parseInt(event.target.dataset.index, 10);
        const acc = this.applicantList[index];
        console.log('Deleting applicant acc ==> ' + JSON.stringify(acc));
        if (acc && acc.Id) {
            this.deletedAccountIds = [...this.deletedAccountIds, acc.Id];
        }

        this.applicantList.splice(index, 1);
        this.applicantDocumentsList.splice(index, 1);

        this.applicantList = [...this.applicantList];
        this.applicantDocumentsList = [...this.applicantDocumentsList];
    }


    @track accountId;
    @track primaryApplicant={};
    @track nextText = 'Creating applicant details and uploading documents to Google Drive. Please wait...';
    @track accNumberByIdMap;
    @track mainApplicantList = [];
    @track contactIds = [];
    handleSubmit(){
        debugger;
        this.mainApplicantList = this.applicantList;

        if(this.applicantList.length > 0){
            const firstApplicant = this.applicantList[0];
            const typeVal = (firstApplicant.Type || '').trim();
            if(firstApplicant.Email__c == null || firstApplicant.Email__c == ''){
                this.showToast('Error', 'Please add Email ID of the 1st Applicant!!!', 'error');
                return;
            }
            //  if (!typeVal) {
            //     this.showToast('Error', 'Please select Customer Type of the Applicant!!!', 'error');
            //     return; 
            // }
        }

        // const missingTypeIndex = this.applicantList.findIndex(a => !a.Type || !String(a.Type).trim());
        // if (missingTypeIndex !== -1) {
        // this.showToast(
        //     'Error',
        //     `Please select Customer Type for Applicant #${missingTypeIndex + 1}!!!`,
        //     'error'
        // );
        // return;
        // }


        const missing = this.applicantList.some(a => !a.firstName || !a.lastName);
        if (missing){
            this.showToast('Error', 'First Name and Last Name are required for every applicant.', 'error');
            return;
        }

        this.applicantList = this.applicantList.map(a => ({
            ...a,
            Name: `${a.firstName || ''} ${a.lastName || ''}`.trim()
        }));

        const namesPayload = this.mainApplicantList.map(a => ({
            accountName: `${a.firstName || ''} ${a.lastName || ''}`.trim(),
            firstName: a.firstName || '',
            lastName:  a.lastName  || ''
        }));
        const contactNamesJson = JSON.stringify(namesPayload);


        const hasEmptyApplicantRec = this.applicantList.some(item => !item.Name);
        if(hasEmptyApplicantRec){
            this.showToast('Error', 'Name has to be added to each Applicant Details!!!', 'error');
            return;
        }
        this.showSpinner = true;
        this.applicantList = this.applicantList.map(applicant => {
            return Object.keys(applicant)
                .filter(key => key === 'Name' || key === 'Phone' || key === 'Type' || key.endsWith('__c') || key.endsWith('__s') || key === 'Id')
                .reduce((obj, key) => {
                    obj[key] = applicant[key];
                    return obj;
                }, {});
        });

        this.applicantList = this.applicantList.map(item => ({
            ...item,
            Application_Date__c : this.dateval
        }));
        console.log('Filtered Applicant List:', JSON.stringify(this.applicantList));        
        
        
        const scrubAccount = (a) => {
        const asDateOnly = v => (v ? String(v).substring(0,10) : v);
        const o = {};
        for (const [k, v] of Object.entries(a)) {
            if (
            k === 'Id' ||                     // <-- keep Id
            k === 'Name' || 
            k === 'Phone' || 
            k === 'Type' || 
            k.endsWith('__c') || 
            k.endsWith('__s')
            ) {
            o[k] = v;
            }
        }

        // remove UI-only / non-Account fields
        delete o.Opportunity__c;
        delete o.uploadDocuments;
        delete o.imageUrl;
        delete o.fileName;
        delete o.base64Data;
        delete o.Number;
        delete o.sameAsPermanentAddress;

        ['Date_Of_Birth__c','Spouse_Date_of_Birth__c','Anniversary_Date__c','Application_Date__c']
            .forEach(f => { if (o[f]) o[f] = asDateOnly(o[f]); });

        return o;
        };

        this.applicantList = this.applicantList.map(scrubAccount);

        this.primaryApplicant = { ...this.applicantList[0], Primary_Applicant__c: true, Id: this.accountId };
        this.applicantList.shift(); 
        
        console.log('applicantRec ==> ' + JSON.stringify(this.applicantList));
            console.log('recordId:::>>' + this.recordId);
            console.log('profileDataList:::>>' + JSON.stringify(this.profileDataList));
        console.log('accountId:::>>' + this.accountId);
            console.log('primaryApplicant ==> ' + JSON.stringify(this.primaryApplicant));
            console.log('contactNamesJson ==> ' + contactNamesJson);
            
        createApplicants({ applicantList : this.applicantList, 
            oppId : this.recordId, 
            profileDataList : JSON.stringify(this.profileDataList), 
            accId : this.accountId, 
            primaryApplicant : this.primaryApplicant, 
            contactNamesJson : contactNamesJson, deletedAccountIds: this.deletedAccountIds })
        .then(result => {
            if(result.accNumberByIdMap != null){
                console.log('this.applicantList ===>  ' + this.applicantList);
                this.contactIds = result.contactIds != null ? result.contactIds : null;
                setTimeout(() => {
                    this.processDocumentUpload(result.accNumberByIdMap, this.mainApplicantList, this.applicantDocumentsList);
                },10000);
                
            }
        })
        .catch(error => {
            this.showToast('Error', error, 'error');
            this.nextText = 'Error Processing Applicant Details!!!!';
        });
    }

    async processDocumentUpload(result, applicantList, applicantDocumentsList){
        try {
            debugger;
            if(result != null){
                this.accNumberByIdMap = result;
                const documentNamesMap = {1 : 'proofOfIdentity', 2 : 'proofOfAddress', 3 : 'financialDocs', 4 : 'propertyDocs',5 : 'legalDocs', 6 : 'preApprovalDocs'};
                let i=1;
                let mainCount = applicantList.length;
                
                while(i <= mainCount){
                    let innerIndex = 1;
                    let innerTotalIndex = Object.keys(documentNamesMap).length;
                    let currentApplicantRec = applicantList.find(item => item.Number === i);
                    let accId = this.accNumberByIdMap[currentApplicantRec.Name];
                    while(innerIndex <= innerTotalIndex){
                        let currentApplicantDoc = applicantDocumentsList.find(item => item.Number === i);
                        const key = documentNamesMap[innerIndex];
                        // let currentDocumentData = currentApplicantDoc[documentNamesMap[innerIndex]] != null ? currentApplicantDoc[documentNamesMap[innerIndex]] : null;
                        const currentDocumentData = currentApplicantDoc && currentApplicantDoc[key] ? currentApplicantDoc[key] : null;

                        if(currentDocumentData != null){
                            let totalFileSize = currentDocumentData.length;
                            
                            let documentName =  documentNamesMap[innerIndex] === 'proofOfIdentity' ? 'Proof of Identity' :
                                                documentNamesMap[innerIndex] === 'proofOfAddress' ? 'Proof of Address' :
                                                documentNamesMap[innerIndex] === 'financialDocs' ? 'Financial Documents' :
                                                documentNamesMap[innerIndex] === 'propertyDocs' ? 'Property Documents' :
                                                documentNamesMap[innerIndex] === 'legalDocs' ? 'Legal Documents' :
                                                documentNamesMap[innerIndex] === 'preApprovalDocs' ? 'Pre-approval Documents' : '';
                            console.log('documentName ===> ' + documentName);

                            let fileName = (currentApplicantDoc && currentApplicantDoc[`${key}FileName`]) ||
                                (currentApplicantRec && currentApplicantRec[key]) ||
                                `${documentName} - ${(currentApplicantRec && currentApplicantRec.Name) || 'Document'}.pdf`;

                            console.log('fileName ===> ' + fileName);
                            
                            const result = await uploadDocuments({accId : accId, fileName : fileName, fileData : currentDocumentData, totalFileSize : totalFileSize, documentName : documentName, oppId : this.recordId});
                            console.log('result::>>', result)
                        }
                        innerIndex++;
                    }
                    i++;
                }
                   this.showToast('Success', 'Applicant Details Created Successfully!!!', 'success');
                    this.showSpinner = false;
                    setTimeout(() => {
                    this.handleCancel();
                    }, 1000);
            }
        } catch (error) {
            console.log('Error in async ===> ' + error);
        }
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


    handleChange(event) {
    
    debugger;
    const name      = event.target.name;
    const value     = event.target.value;
    const index     = parseInt(event.target.dataset.number, 10);
    const radioname = event.target.dataset.radioname;
    console.log('radioNmam::>>' + radioname);
    const type      = event.target.type;
    const checked   = event.target.checked;

    const applicantRec = this.applicantList.find(app => app.Number == index);
    if (!applicantRec) return;

    if (type === 'radio' && radioname) {
        applicantRec[radioname] = value;

        this.refreshDecoratedOptions(applicantRec, radioname);

    } else if (name === 'todaydate') {
        this.dateval = value;

    } else if (name === 'sameAsPermanentAddress') {
        applicantRec[name] = checked;

    } else {
        applicantRec[name] = value;
        console.log('name::>>' + name);
    }

    if (applicantRec.sameAsPermanentAddress) {
        applicantRec.Address_for_Communication__Street__s      = applicantRec.Permanent_Address__Street__s;
        applicantRec.Address_for_Communication__City__s        = applicantRec.Permanent_Address__City__s;
        applicantRec.Address_for_Communication__CountryCode__s = applicantRec.Permanent_Address__CountryCode__s;
        applicantRec.Address_for_Communication__StateCode__s   = applicantRec.Permanent_Address__StateCode__s;
        applicantRec.Address_for_Communication__PostalCode__s  = applicantRec.Permanent_Address__PostalCode__s;
    }

    applicantRec.Name = `${applicantRec.firstName || ''} ${applicantRec.lastName || ''}`.trim();

    // force re-render
    this.applicantList = [...this.applicantList];
    }

    refreshDecoratedOptions(app, field) {
    const map = {
        'Type'                       : ['_typeOptions'    , this.typeOptions],
        'Industry__c'                : ['_industryOptions', this.industryOptions],
        'Designation__c'             : ['_desigOptions'   , this.designationOptions],
        'Annual_Household_Income__c' : ['_incomeOptions'  , this.annualIncomeOptions],
        'Purpose_of_Purchase__c'     : ['_purposeOptions' , this.purposeOfPurchaseOptions],
        'Source_of_Funding__c'       : ['_fundingOptions' , this.sourceOfFundingOptions],
        'Source_of_Information__c'   : ['_sourceInfoOpts' , this.sourceOfInfoOptions],
        'Work_Function_Role__c'      : ['_workFnOptions'  , this.workFunctionOptions],
        'Salutation__c'              : ['_salutationOptions', this.salutationOptions],
        'Resident_Status__c'         : ['_residentOptions', this.residentStatusOptions],
    };

    const conf = map[field];
    if (!conf) return;
    const [destProp, srcOptions] = conf;
    app[destProp] = this.decorateOptions(srcOptions, app[field]);
    }


    @track projectName = '';
    @track RERA_No = '';
    @track SuperBuiltUpArea = '';
    @track Salutation;
    @track contFirstName;
    @track contLastName;
    @track companyAuthSign;
    @track withRelation;
    @track withRelationName;
    @track customerType;
    @track dobAcc;
    @track sposeName;
    @track sposeDOB;
    @track annivDate;
    @track countryOfCitzn
    @track residentStatus; 
    @track passportNo;
    @track countryOfResidence;
    @track panNo;
    @track aadharNo;
    @track permanentStreet;
    @track permanentCity;
    @track permanentState;
    @track permanentCountry;
    @track permanentPostalCode;
    @track communicationStreet;
    @track communicationCity;
    @track communicationState;
    @track communicationCountry;
    @track communicationPostalCode;
    @track primaryContactNo;
    @track emailAcc;
    @track officialEmail;
    @track industrySector;
    @track otherSpecification;
    @track loaction;
    @track designationOnLoad;
    @track orgType;
    @track annualHhIncome;
    @track nameOfOrg;
    @track purposePurchase;
    @track sourceOfFunding;
    @track workFunction;
    @track aboutTridasa;
    @track otherSpecify;
    @track refferalName;
    @track refferalProject;
    @track refferalPhone;
    @track refferalUnit;

    getOnLoadData() {
        debugger;
    getProjectPicklistDetails({oppId: this.recordId, ObjectByField: this.objByField, ObjectByFieldAddress: this.ObjectByFieldAddress
    })
    .then(result => {
        debugger;
        console.log('result==>' + JSON.stringify(result));
        if (result && result.oppRec) {
            const unit = result.oppRec.Unit__r && result.oppRec.Unit__r.Name ? result.oppRec.Unit__r.Name : null;

            this.dateval        = result.todayDate;
            console.log('this.dateval::>>' + this.dateval);
            this.accountId      = result.oppRec.AccountId || null;
            this.projectName    = result.oppRec.Project__r && result.oppRec.Project__r.Name ? result.oppRec.Project__r.Name : null;
            this.SuperBuiltUpArea = result.oppRec.Unit__r && result.oppRec.Unit__r.Super_Built_Up_Area_sq_ft__c != null
                                    ? result.oppRec.Unit__r.Super_Built_Up_Area_sq_ft__c : null;
            this.RERA_No        = (result.oppRec.Project__r && result.oppRec.Project__r.Company__r
                                    && result.oppRec.Project__r.Company__r.Registration_Number__c)
                                    ? result.oppRec.Project__r.Company__r.Registration_Number__c : null;
            this.unitAndTypeValue = [unit, result.oppRec.Type].filter(value => value).join(',');

            const applicantRec = {
                Number: 1,
                Opportunity__c: this.recordId != null ? this.recordId : null,
                firstName: '',
                lastName: '',
                sourceOfInfo: 'Source_of_Information__c' + 1,
                residentStatus: 'Resident_Status__c' + 1,
                type: 'Type' + 1,
                relation: 'Relation_To__c' + 1,
                industry: 'Industry__c' + 1,
                designation: 'Designation__c' + 1,
                annualHousehold: 'Annual_Household_Income__c' + 1,
                purposeOfPurchase: 'Purpose_of_Purchase__c' + 1,
                sourceOfFunding: 'Source_of_Funding__c' + 1,
                workFunction: 'Work_Function_Role__c' + 1,
                Salutation: 'Salutation__c' + 1,
                uploadDocuments: 'uploadDocuments' + 1,
                imageUrl: this.profilePic,
                Application_Date__c: result.todayDate,
                deleteIcon: false,
                _relationOptions: [],
                _typeOptions: [],
                _residentOptions: [],
                _industryOptions: [],
                _orgTypeOptions: [],
                _desigOptions: [],
                _incomeOptions: [],
                _yoeOptions: [],
                _purposeOptions: [],
                _sourceInfoOpts: [],
                _fundingOptions: [],
                _workFnOptions: [],
                _salutationOptions: [],
            };
            this.applicantList.push(applicantRec);

            const applicantDocRec = { Number: 1 };
            this.applicantDocumentsList.push(applicantDocRec);

            if (result && result.docUrls) {
                const u = result.docUrls || {};
                const n = result.docNames || {};
                const a0 = this.applicantList[0];
                console.log('a0 before setting doc urls==>>' + JSON.stringify(a0));
                console.log('doc urls==>>' + JSON.stringify(u));
                console.log('doc names==>>' + JSON.stringify(n));
                a0.proofOfIdentityUrl   = u.proofOfIdentity || null;
                
                a0.proofOfIdentityName  = n.proofOfIdentity || 'View';
                console.log('proofOfIdentityUrl==>>' + a0.proofOfIdentityUrl);
                console.log('proofOfIdentityName==>>' + a0.proofOfIdentityName);

                a0.proofOfAddressUrl    = u.proofOfAddress || null;
                a0.proofOfAddressName   = n.proofOfAddress || 'View';
                console.log('proofOfAddressUrl==>>' + a0.proofOfAddressUrl);
                console.log('proofOfAddressName==>>' + a0.proofOfAddressName );

                a0.financialDocsUrl     = u.financialDocs || null;
                a0.financialDocsName    = n.financialDocs || 'View';

                a0.propertyDocsUrl      = u.propertyDocs || null;
                a0.propertyDocsName     = n.propertyDocs || 'View';

                a0.legalDocsUrl         = u.legalDocs || null;
                a0.legalDocsName        = n.legalDocs || 'View';

                a0.preApprovalDocsUrl   = u.preApprovalDocs || null;
                a0.preApprovalDocsName  = n.preApprovalDocs || 'View';

                this.applicantList = [...this.applicantList];
            }


            this._unitNameForLater = unit;
        }

        if (result && result.picklistValByField) {
            this.residentStatusOptions      = this.mapToLabelValuePair(result.picklistValByField['Resident_Status__c']);
            this.typeOptions                = this.mapToLabelValuePair(result.picklistValByField['Type']);
            this.relationOptions            = this.mapToLabelValuePair(result.picklistValByField['Relation_To__c']);
            this.industryOptions            = this.mapToLabelValuePair(result.picklistValByField['Industry__c']);
            this.designationOptions         = result.picklistValByField['Designation__c']
                                              ? this.mapToLabelValuePair(result.picklistValByField['Designation__c'])
                                              : [];

            this.annualIncomeOptions        = result.picklistValByField['Annual_Household_Income__c']
                                              ? this.mapToLabelValuePair(result.picklistValByField['Annual_Household_Income__c'])
                                              : [];
            this.purposeOfPurchaseOptions   = this.mapToLabelValuePair(result.picklistValByField['Purpose_of_Purchase__c']);
            this.sourceOfInfoOptions        = this.mapToLabelValuePair(result.picklistValByField['Source_of_Information__c']);
            this.sourceOfFundingOptions     = this.mapToLabelValuePair(result.picklistValByField['Source_of_Funding__c']);
            this.workFunctionOptions        = this.mapToLabelValuePair(result.picklistValByField['Work_Function_Role__c']);
            this.salutationOptions          = this.mapToLabelValuePair(result.picklistValByField['Salutation__c']);
        }

        if (result && result.picklistValForAddress) {
            this.permanentStateOptions        = result.picklistValForAddress['Permanent_Address__StateCode__s'];
            this.addressForCommStateOptions   = result.picklistValForAddress['Address_for_Communication__StateCode__s'];
            this.permanentCountryOptions      = result.picklistValForAddress['Permanent_Address__CountryCode__s'];
            this.addressForCommCountryOptions = result.picklistValForAddress['Address_for_Communication__CountryCode__s'];
        }

        if (result.additionalApplicantVals && result.additionalApplicantVals.length) {
  let nextNumber = 2; 
  result.additionalApplicantVals.forEach(dv2 => {
    const acc = {
      Number: nextNumber,
      Opportunity__c: this.recordId || null,
      
      deleteIcon: true,
        uploadDocuments: `uploadDocuments${nextNumber}`,
      Id: dv2['Id'] || null,

      // text inputs
      firstName: dv2['Contact_FirstName'] || '',
      lastName:  dv2['Contact_LastName']  || '',
      W_o_S_o_D_o__c: dv2['W_o_S_o_D_o__c'] || null,
      Salutation__c: dv2['Salutation'] || null,
      Type: dv2['Type'] || null,
      Industry__c: dv2['Industry__c'] || null,
      Designation__c: dv2['Designation__c'] || null,
      Annual_Household_Income__c: dv2['Annual_Household_Income__c'] || null,
      Purpose_of_Purchase__c: dv2['Purpose_of_Purchase__c'] || null,
      Source_of_Funding__c: dv2['Source_of_Funding__c'] || null,
      Work_Function_Role__c: dv2['Work_Function_Role__c'] || null,
      Source_of_Information__c: dv2['Source_of_Information__c'] || null,

      // addresses
      Permanent_Address__Street__s: dv2['Permanent_Address__Street__s'] || null,
      Permanent_Address__City__s: dv2['Permanent_Address__City__s'] || null,
      Permanent_Address__CountryCode__s: dv2['Permanent_Address__CountryCode__s'] || null,
      Permanent_Address__StateCode__s: dv2['Permanent_Address__StateCode__s'] || null,
      Permanent_Address__PostalCode__s: dv2['Permanent_Address__PostalCode__s'] || null,

      Address_for_Communication__Street__s: dv2['Address_for_Communication__Street__s'] || null,
      Address_for_Communication__City__s: dv2['Address_for_Communication__City__s'] || null,
      Address_for_Communication__CountryCode__s: dv2['Address_for_Communication__CountryCode__s'] || null,
      Address_for_Communication__StateCode__s: dv2['Address_for_Communication__StateCode__s'] || null,
      Address_for_Communication__PostalCode__s: dv2['Address_for_Communication__PostalCode__s'] || null,

      // phones/emails
      Phone: dv2['Phone'] || null,
      Alternate_Contact_Number__c: dv2['Alternate_Contact_Number__c'] || null,
      Email__c: dv2['Email__c'] || null,
      Official_Email__c: dv2['Official_Email__c'] || null,

      // misc fields you render...
      If_Others_Industry__c: dv2['If_Others_Industry__c'] || null,
      Location__c: dv2['Location__c'] || null,
      Company_Firm_Name__c: dv2['Company_Firm_Name__c'] || null,
      If_Others_Work_Funtion_Role__c: dv2['If_Others_Work_Funtion_Role__c'] || null,
      Referral_Name__c: dv2['Referral_Name__c'] || null,
      Referral_Project_Name__c: dv2['Referral_Project_Name__c'] || null,
      Referral_Unit_Number__c: dv2['Referral_Unit_Number__c'] || null,
      Referral_Phone_Number__c: dv2['Referral_Phone_Number__c'] || null,
        Resident_Status__c: dv2['Resident_Status__c'] || null,
      imageUrl: this.profilePic,
      Application_Date__c: this.dateval
    };

    // computed display name for uploads, etc.
    acc.Name = `${acc.firstName || ''} ${acc.lastName || ''}`.trim();

    
    acc._typeOptions     = this.decorateOptions(this.typeOptions,          acc.Type);
    acc._residentOptions = this.decorateOptions(this.residentStatusOptions, acc.Resident_Status__c);
    acc._industryOptions = this.decorateOptions(this.industryOptions,      acc.Industry__c);
    acc._desigOptions = this.decorateOptions(this.designationOptions, acc.Designation__c);
    acc._incomeOptions = this.decorateOptions(this.annualIncomeOptions, acc.Annual_Household_Income__c);
    acc._purposeOptions = this.decorateOptions(this.purposeOfPurchaseOptions, acc.Purpose_of_Purchase__c);
    acc._sourceInfoOpts = this.decorateOptions(this.sourceOfInfoOptions, acc.Source_of_Information__c);
    acc._fundingOptions = this.decorateOptions(this.sourceOfFundingOptions, acc.Source_of_Funding__c);
    acc._workFnOptions = this.decorateOptions(this.workFunctionOptions, acc.Work_Function_Role__c);
    acc._salutationOptions = this.decorateOptions(this.salutationOptions, acc.Salutation__c);
    this.applicantList = [...this.applicantList, acc];

    // each coapplicant gets a doc bucket
    this.applicantDocumentsList = [...this.applicantDocumentsList, { Number: nextNumber }];
    nextNumber += 1;

    // Apply co-applicant document links (by Account Id on the row)
if (result.coappDocUrlsByAccount || result.coappDocNamesByAccount) {
  const accId = acc.Id; // you already put Account Id into acc.Id
  if (accId) {
    const uMap = result.coappDocUrlsByAccount ? result.coappDocUrlsByAccount[accId] : null;
    const nMap = result.coappDocNamesByAccount ? result.coappDocNamesByAccount[accId] : null;

    if (uMap) {
      acc.proofOfIdentityUrl  = uMap.proofOfIdentity || null;
      acc.proofOfAddressUrl   = uMap.proofOfAddress  || null;
      acc.financialDocsUrl    = uMap.financialDocs   || null;
      acc.propertyDocsUrl     = uMap.propertyDocs    || null;
      acc.legalDocsUrl        = uMap.legalDocs       || null;
      acc.preApprovalDocsUrl  = uMap.preApprovalDocs || null;
    }
    if (nMap) {
      acc.proofOfIdentityName = nMap.proofOfIdentity || 'View';
      acc.proofOfAddressName  = nMap.proofOfAddress  || 'View';
      acc.financialDocsName   = nMap.financialDocs   || 'View';
      acc.propertyDocsName    = nMap.propertyDocs    || 'View';
      acc.legalDocsName       = nMap.legalDocs       || 'View';
      acc.preApprovalDocsName = nMap.preApprovalDocs || 'View';
    }
  }
}


  });

  // force re-render
  this.applicantList = [...this.applicantList];
}

        // ====== 4) Map defaults from Apex (Account fields + Contact.Salutation) ======
        const dv = (result && result.defaultVals) ? result.defaultVals : {};
        // After const dv = (result && result.defaultVals) ? result.defaultVals : {};
        if (this.applicantList.length > 0) {
        const base = this.applicantList[0];
        this.applicantList[0] = {
            ...base,

            Salutation__c: dv['Salutation'] || base.Salutation__c || null,
            Type: dv['Type'] || base.Type || null,
            Industry__c: dv['Industry__c'] || base.Industry__c || null,
            Designation__c: dv['Designation__c'] || base.Designation__c || null,
            Annual_Household_Income__c: dv['Annual_Household_Income__c'] || base.Annual_Household_Income__c || null,
            Purpose_of_Purchase__c: dv['Purpose_of_Purchase__c'] || base.Purpose_of_Purchase__c || null,
            Source_of_Funding__c: dv['Source_of_Funding__c'] || base.Source_of_Funding__c || null,
            Work_Function_Role__c: dv['Work_Function_Role__c'] || base.Work_Function_Role__c || null,
            Source_of_Information__c: dv['Source_of_Information__c'] || base.Source_of_Information__c || null,
            Name_of_Authorised_Signatory__c: dv['Name_of_Authorised_Signatory__c'] || base.Name_of_Authorised_Signatory__c || null,
            W_o_S_o_D_o__c: dv['W_o_S_o_D_o__c'] || base.W_o_S_o_D_o__c || null,
            Date_Of_Birth__c: dv['Date_Of_Birth__c'] || base.Date_Of_Birth__c || null,
            Spouse_Name__c: dv['Spouse_Name__c'] || base.Spouse_Name__c || null,
            Spouse_Date_of_Birth__c: dv['Spouse_Date_of_Birth__c'] || base.Spouse_Date_of_Birth__c || null,
            Anniversary_Date__c: dv['Anniversary_Date__c'] || base.Anniversary_Date__c || null,
            Resident_Status__c: dv['Resident_Status__c'] || base.Resident_Status__c || null,
            Passport_Number__c: dv['Passport_Number__c'] || base.Passport_Number__c || null,
            Country_of_Residence__c: dv['Country_of_Residence__c'] || base.Country_of_Residence__c || null,
            PAN__c: dv['PAN__c'] || base.PAN__c || null,

            Permanent_Address__Street__s: dv['Permanent_Address__Street__s'] || base.Permanent_Address__Street__s || null,
            Permanent_Address__City__s: dv['Permanent_Address__City__s'] || base.Permanent_Address__City__s || null,
            Permanent_Address__CountryCode__s: dv['Permanent_Address__CountryCode__s'] || base.Permanent_Address__CountryCode__s || null,
            Permanent_Address__StateCode__s: dv['Permanent_Address__StateCode__s'] || base.Permanent_Address__StateCode__s || null,
            Permanent_Address__PostalCode__s: dv['Permanent_Address__PostalCode__s'] || base.Permanent_Address__PostalCode__s || null,

            Address_for_Communication__Street__s: dv['Address_for_Communication__Street__s'] || base.Address_for_Communication__Street__s || null,
            Address_for_Communication__City__s: dv['Address_for_Communication__City__s'] || base.Address_for_Communication__City__s || null,
            Address_for_Communication__CountryCode__s: dv['Address_for_Communication__CountryCode__s'] || base.Address_for_Communication__CountryCode__s || null,
            Address_for_Communication__StateCode__s: dv['Address_for_Communication__StateCode__s'] || base.Address_for_Communication__StateCode__s || null,
            Address_for_Communication__PostalCode__s: dv['Address_for_Communication__PostalCode__s'] || base.Address_for_Communication__PostalCode__s || null,

            Phone: dv['Phone'] || base.Phone || null,
            Email__c: dv['Email__c'] || base.Email__c || null,
            Official_Email__c: dv['Official_Email__c'] || base.Official_Email__c || null,
            Alternate_Contact_Number__c: dv['Alternate_Contact_Number__c'] || base.Alternate_Contact_Number__c || null,

            If_Others_Industry__c: dv['If_Others_Industry__c'] || base.If_Others_Industry__c || null,
            Location__c: dv['Location__c'] || base.Location__c || null,
            Company_Firm_Name__c: dv['Company_Firm_Name__c'] || base.Company_Firm_Name__c || null,

            If_Others_Work_Funtion_Role__c: dv['If_Others_Work_Funtion_Role__c'] || base.If_Others_Work_Funtion_Role__c || null,
            Referral_Name__c: dv['Referral_Name__c'] || base.Referral_Name__c || null,
            Referral_Project_Name__c: dv['Referral_Project_Name__c'] || base.Referral_Project_Name__c || null,
            Referral_Unit_Number__c: dv['Referral_Unit_Number__c'] || base.Referral_Unit_Number__c || null,
            Referral_Phone_Number__c: dv['Referral_Phone_Number__c'] || base.Referral_Phone_Number__c || null,
        };
        this.applicantList = [...this.applicantList];
        }

        if (this.applicantList.length > 0) {
            const a0 = this.applicantList[0];

            a0._typeOptions     = this.decorateOptions(this.typeOptions,              a0.Type);
            a0._industryOptions = this.decorateOptions(this.industryOptions,          a0.Industry__c);
            a0._desigOptions    = this.decorateOptions(this.designationOptions,       a0.Designation__c);
            a0._incomeOptions   = this.decorateOptions(this.annualIncomeOptions,      a0.Annual_Household_Income__c);
            a0._purposeOptions  = this.decorateOptions(this.purposeOfPurchaseOptions, a0.Purpose_of_Purchase__c);
            a0._fundingOptions  = this.decorateOptions(this.sourceOfFundingOptions,   a0.Source_of_Funding__c);
            a0._workFnOptions   = this.decorateOptions(this.workFunctionOptions,      a0.Work_Function_Role__c);
            a0._sourceInfoOpts  = this.decorateOptions(this.sourceOfInfoOptions,      a0.Source_of_Information__c);

            a0._residentOptions = this.decorateOptions(this.residentStatusOptions,    a0.Resident_Status__c);

            this.applicantList = [...this.applicantList]; // force re-render
        }
        
        this.customerType               = dv['Type'] || null;
        this.residentStatus             = dv['Resident_Status__c'] || null;
        this.industrySector             = dv['Industry__c'] || null;
        this.designationOnLoad          = dv['Designation__c'] || null;
        this.annualHhIncome             = dv['Annual_Household_Income__c'] || null;
        this.purposePurchase            = dv['Purpose_of_Purchase__c'] || null;
        this.sourceOfFunding            = dv['Source_of_Funding__c'] || null;
        this.workFunction               = dv['Work_Function_Role__c'] || null;
        this.aboutTridasa               = dv['Source_of_Information__c'] || null;
        this.Salutation                 = dv['Salutation'] || null; 
        this.companyAuthSign         = dv['Name_of_Authorised_Signatory__c'] || null;
        this.withRelationName        = dv['W_o_S_o_D_o__c'] || null;
        this.dobAcc                  = dv['Date_Of_Birth__c'] || null;
        this.sposeName               = dv['Spouse_Name__c'] || null;
        this.sposeDOB                = dv['Spouse_Date_of_Birth__c'] || null;
        this.annivDate               = dv['Anniversary_Date__c'] || null;
        this.passportNo              = dv['Passport_Number__c'] || null;
        this.countryOfResidence      = dv['Country_of_Residence__c'] || null;
        this.panNo                   = dv['PAN__c'] || null;

        // permanent address
        this.permanentStreet         = dv['Permanent_Address__Street__s'] || null;
        this.permanentCity           = dv['Permanent_Address__City__s'] || null;
        this.permanentCountry        = dv['Permanent_Address__CountryCode__s'] || null;
        this.permanentState          = dv['Permanent_Address__StateCode__s'] || null;
        this.permanentPostalCode     = dv['Permanent_Address__PostalCode__s'] || null;
        this.communicationStreet     = dv['Address_for_Communication__Street__s'] || null;
        this.communicationCity       = dv['Address_for_Communication__City__s'] || null;
        this.communicationCountry    = dv['Address_for_Communication__CountryCode__s'] || null;
        this.communicationState      = dv['Address_for_Communication__StateCode__s'] || null;
        this.communicationPostalCode = dv['Address_for_Communication__PostalCode__s'] || null;
        this.primaryContactNo        = dv['Phone'] || null;
        this.emailAcc                = dv['Email__c'] || null;
        this.officialEmail           = dv['Official_Email__c'] || null;
        this.otherSpecification      = dv['If_Others_Industry__c'] || null;
        this.loaction                = dv['Location__c'] || null;
        this.nameOfOrg               = dv['Company_Firm_Name__c'] || null;
        this.otherSpecify            = dv['If_Others_Work_Funtion_Role__c'] || null;

        this.refferalName            = dv['Referral_Name__c'] || null;
        this.refferalProject         = dv['Referral_Project_Name__c'] || null;
        this.refferalUnit            = dv['Referral_Unit_Number__c'] || null;
        this.refferalPhone           = dv['Referral_Phone_Number__c'] || null;

        this.applicantList[0].firstName = dv['Contact_FirstName'] || this.applicantList[0].firstName || '';
        this.applicantList[0].lastName  = dv['Contact_LastName']  || this.applicantList[0].lastName  || '';
        this.applicantList[0].Name      = `${this.applicantList[0].firstName || ''} ${this.applicantList[0].lastName || ''}`.trim();



        console.log('Picklist Value Map:', JSON.stringify(result && result.picklistValByField));
        console.log('applicantList ===> ' + JSON.stringify(this.applicantList));
        console.log('applicantDocumentsList ==> ' + JSON.stringify(this.applicantDocumentsList));
    })
    .catch(error => {
        console.error('Error==>' + error);
    });
}


    mapToLabelValuePair(values) {
        return Array.isArray(values) ? values.map(value => ({
                label: value, value: value
            })) : [];

        }

        decorateOptions(options, selected) {
            if (!Array.isArray(options)) return [];
            return options.map(o => ({
                label: o.label,
                value: o.value,
                checked: o.value === selected
            }));
            }
}