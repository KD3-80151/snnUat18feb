import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getUnitRecordBasedOnProjectFilter from '@salesforce/apex/SelectPropertsiteVisitController.getProjectDetailsBasedonSearch';
import getPicklistValuesDynamically from '@salesforce/apex/SelectPropertsiteVisitController.getAllPickListVal';
import getProjectDetails from '@salesforce/apex/SelectPropertsiteVisitController.getProjectDetails';
import getTowersByProject from '@salesforce/apex/SelectPropertsiteVisitController.getTowersByProject';

import TOWER_IMAGE from "@salesforce/resourceUrl/towerImage";
import FAMILY_IMAGE from "@salesforce/resourceUrl/HomeBHK";
import ONEBHK from "@salesforce/resourceUrl/oneBHKPerson";
import TWOBHK from "@salesforce/resourceUrl/twoBHK";
import THREEBHK from "@salesforce/resourceUrl/threeBHK";

export default class GetSelectedPropertiesFromProject extends NavigationMixin(LightningElement) {
    
    towerimageurl = TOWER_IMAGE;
    homeimageulr = FAMILY_IMAGE;
    onebhk = ONEBHK;
    twobhk = TWOBHK;
    threebhk = THREEBHK;

    @track selectedProjectName;
    @track selectedTowerName;
    @track selectedUnitType;

    @track optionsprojectName = [];
    @track optionstowerName = [];
    @track optionsUnitType = [];

    @track AvailableForSaleCount = 0;
    @track SoldCount = 0;
    @track ManagementBlockedCount = 0;
    @track UnderCustomerDiscussionCount = 0;
    @track NotReleasedbyManagementCount = 0;
    @track BlockedforSafetyClearanceCount = 0;
    @track waitingPaymentConfirmationCount = 0;

    @track error;
    @track wrapdata;
    @track TowersUnit = [];
    @track SlabsList = [];
    @track towerpicarray = [];
    @track TowerName = '';
    @track totalunits;
    @track selectedId;
    @track unitRecord;
    @track unitBoolean = false;

    @track FloorListNumbers = [];
    floorUnitMap = new Map();
    @track floorUnitMapArray = [];

    @track FlatBhkId = null;

    objByField = {
        Unit_Type__c: 'Unit__c'
    };

    connectedCallback() {
        debugger;
        setTimeout(() => {
            this.getAllPicklistValues();
            this.getProjectAndUnitTypePickList();
        }, 300);
    }


    getProjectAndUnitTypePickList() {
        debugger;
        getProjectDetails()
            .then(result => {
                if (result && result.length > 0) {
                    this.optionsprojectName = result.map(item => ({
                        label: item.Name,
                        value: item.Name
                    }));
                }
            })
            .catch(error => {
                console.error('Error fetching projects ===> ', error);
            });
    }

    getAllPicklistValues() {
        debugger;
        getPicklistValuesDynamically({ ObjectByField: this.objByField })
            .then(result => {
                const unitTypeValues = result['Unit_Type__c'] || [];
                console.log('Fetched Unit Type Values:', unitTypeValues);
                this.optionsUnitType = this.mapToLabelValuePair(unitTypeValues);
                console.log('Mapped Unit Type Options:', this.optionsUnitType);
            })
            .catch(error => {
                console.error('error fetching picklist options ===> ', error);
            });
    }

    mapToLabelValuePair(values) {
        debugger;
        return values.map(value => ({
            label: value,
            value: value
        }));
    }


    ProjecthandleChange(event) {
        debugger;
        this.selectedProjectName = event.detail.value;
        this.selectedTowerName = null;
        this.optionstowerName = [];

        if (this.selectedProjectName) {
            getTowersByProject({ projectName: this.selectedProjectName })
                .then(result => {
                    this.optionstowerName = result.map(t => ({
                        label: t,
                        value: t
                    }));
                })
                .catch(error => {
                    console.error('Error loading towers: ', error);
                });
        }
    }

    towerHandleChange(event) {
        debugger;
        this.selectedTowerName = event.detail.value;
        this.TowerName = this.selectedTowerName;
    }

    unitTypeHandleChange(event) {
        debugger;
        this.selectedUnitType = event.detail.value;
        this.FlatBhkId = this.selectedUnitType;
    }

    filterUnits(event) {
        debugger;
        const div_id = event.target.id.split('-')[0];
        let selectedStatus;
        this.totalunits = 0;

        if (div_id === 'For_Sale') {
            selectedStatus = 'For Sale';
        } else if (div_id === 'Booked') {
            selectedStatus = 'Booked';
        } else if (div_id === 'Sold') {
            selectedStatus = 'Sold';
        } else if (div_id === 'Awaiting_Payment_Confirmation') {
            selectedStatus = 'Awaiting Payment Confirmation';
        } else if (div_id === 'Management_Blocked') {
            selectedStatus = 'Management Blocked';
        }

        this.floorUnitMapArray = this.floorUnitMapArray
            .map(item => {
                const filteredUnits = item.units.filter(unit => {
                    if (unit.Status__c === selectedStatus) {
                        this.totalunits = this.totalunits + 1;
                        return unit;
                    }
                    return false;
                });
                return {
                    ...item,
                    units: filteredUnits
                };
            })
            .filter(item => item.units.length > 0);

        console.log('Filtered Units:', JSON.stringify(this.floorUnitMapArray));
    }

    ClearUnits() {
        debugger;
        this.selectedProjectName = null;
        this.selectedTowerName = null;
        this.selectedUnitType = null;
        this.TowerName = null;
        this.FlatBhkId = null;

        this.optionstowerName = [];
        this.towersUnit = [];
        this.SlabsList = [];
        this.floorUnitMapArray = [];
        this.totalunits = 0;

        this.AvailableForSaleCount = 0;
        this.SoldCount = 0;
        this.ManagementBlockedCount = 0;
        this.UnderCustomerDiscussionCount = 0;
        this.NotReleasedbyManagementCount = 0;
        this.BlockedforSafetyClearanceCount = 0;
        this.waitingPaymentConfirmationCount = 0;
    }

    SearchUnits() {
        debugger;
        if (!this.selectedProjectName || !this.selectedTowerName) {
            this.showToast('Error', 'Please select Project, Tower', 'error');
            return;
        }

        getUnitRecordBasedOnProjectFilter({
            FlatBhkId: this.FlatBhkId,
            projectName: this.selectedProjectName,
            towerName: this.selectedTowerName,
            unitType: this.selectedUnitType
        })
            .then((result) => {
                if (result) {
                    this.wrapdata = result;
                    let tempUnitArry = [];
                    let temptotalunits = 0;

                    this.TowerName = result.defaultTowerName || this.selectedTowerName || null;
                    this.FlatBhkId = result.defaultFlatType || this.selectedUnitType || null;

                    this.AvailableForSaleCount = result.AvailableforSale || 0;
                    this.waitingPaymentConfirmationCount = result.AwaitingPaymentConfirmation || 0;
                    this.SoldCount = result.Sold || 0;
                    this.ManagementBlockedCount = result.ManagementBlocked || 0;
                    this.UnderCustomerDiscussionCount = result.UnderCustomerDiscussion || 0;
                    this.NotReleasedbyManagementCount = result.Blocked_NotReleasedbyMgmt || 0;
                    this.BlockedforSafetyClearanceCount = result.Blocked_ForFire_SafetyClearance || 0;

                    if (result.FloorwithunitMapDetails) {
                        for (let key in result.FloorwithunitMapDetails) {
                            let tempobject = {};
                            tempobject.unitName = key;
                            tempobject.Id = key;
                            tempobject.hasFloorDetails = false;
                            tempobject.mainFloor = null;
                            let tempinnerunitarray = [];

                            for (let j = 0; j < result.FloorwithunitMapDetails[key].length; j++) {
                                const u = result.FloorwithunitMapDetails[key][j];
                                const matchesTower = u.Floor__r.Blocks__r.Tower_Code__c === this.TowerName;
                                const matchesUnitType = !this.FlatBhkId || u.Unit_Type__c === this.FlatBhkId;

                                if (matchesTower && matchesUnitType) {
                                    temptotalunits = temptotalunits + 1;

                                    if (u.Floor__r.Floor_No__c != null && tempobject.hasFloorDetails === false) {
                                        tempobject.hasFloorDetails = true;
                                        tempobject.mainFloor = u.Floor__r.Floor_No__c;
                                    }
                                    
                                    if (u.Status__c === 'For Sale') {
                                        u.newClass = 'greenClass';
                                    } else if (u.Status__c === 'Awaiting Payment Confirmation') {
                                        u.newClass = 'amberClass';
                                    } else if (u.Status__c === 'Management Blocked') {
                                        u.newClass = 'purpleClass';
                                    } else if (u.Status__c === 'Booked') {
                                        u.newClass = 'pinkClass';
                                    } else if (u.Status__c === 'Sold') {
                                        u.newClass = 'redClass';
                                    }

                                    tempinnerunitarray.push(u);
                                }
                            }

                            tempobject.unitdetails = tempinnerunitarray;
                            tempUnitArry.push(tempobject);
                        }
                    }

                    this.SlabsList = result.getSlabsListFromUnit || [];
                    this.FloorListNumbers = [];

                    this.SlabsList.forEach((item) => {
                        if (!this.FloorListNumbers.includes(item.Floor_No__c)) {
                            this.FloorListNumbers.push(item.Floor_No__c);
                        }
                    });

                    this.SlabsList.sort((a, b) => (a.Floor_No__c < b.Floor_No__c ? 1 : -1));
                    this.TowersUnit = tempUnitArry;

                    let uniqueSlabsList = [];
                    let seenFloorNos = new Set();

                    for (let slab of this.SlabsList) {
                        if (!seenFloorNos.has(slab.Floor_No__c)) {
                            seenFloorNos.add(slab.Floor_No__c);
                            uniqueSlabsList.push(slab);
                        }
                    }

                    this.SlabsList = uniqueSlabsList;

                    const floorsInUnits = new Set();
                    this.TowersUnit.forEach(tower => {
                        (tower.unitdetails || []).forEach(unit => {
                            const floorNumber = unit.Floor__r.Floor_No__c;
                            floorsInUnits.add(floorNumber);
                        });
                    });

                    const uniqueFloorsInUnits = Array.from(floorsInUnits);
                    const missingFloors = this.FloorListNumbers.filter(floor => !uniqueFloorsInUnits.includes(floor));

                    this.TowersUnit.forEach(tower => {
                        missingFloors.forEach(floor => {
                            const floorExists = this.TowersUnit.some(t => t.mainFloor === floor);
                            if (!floorExists) {
                                const tempTowerData = {
                                    Id: null,
                                    hasFloorDetails: false,
                                    mainFloor: floor
                                };
                                this.TowersUnit.push(tempTowerData);
                            }
                        });
                    });

                    this.TowersUnit.sort((a, b) => {
                        const floorA = a.mainFloor || Number.MIN_SAFE_INTEGER;
                        const floorB = b.mainFloor || Number.MIN_SAFE_INTEGER;
                        return floorB - floorA;
                    });

                    this.buildFloorUnitMap();
                    this.totalunits = temptotalunits;
                } else {
                    this.TowersUnit = [];
                    this.SlabsList = [];
                    this.totalunits = 0;
                    this.towerpicarray = [];
                    this.AvailableForSaleCount = 0;
                    this.SoldCount = 0;
                    this.ManagementBlockedCount = 0;
                    this.UnderCustomerDiscussionCount = 0;
                    this.NotReleasedbyManagementCount = 0;
                    this.BlockedforSafetyClearanceCount = 0;
                    this.waitingPaymentConfirmationCount = 0;
                }
            })
            .catch((error) => {
                this.error = error;
                console.error('Error in SearchUnits: ', error);
            });
    }

    buildFloorUnitMap() {
        debugger;
        let floorUnitMap = new Map();
        this.TowersUnit.forEach(floor => {
            if (floor.unitdetails && Array.isArray(floor.unitdetails)) {
                floorUnitMap.set(floor.mainFloor, {
                    floorDetails: floor,
                    units: floor.unitdetails
                });
            }
        });
        this.floorUnitMapArray = Array.from(floorUnitMap, ([floorNumber, data]) => ({
            floorNumber: floorNumber,
            floorDetails: data.floorDetails,
            units: data.units
        }));
        console.log('this.floorUnitMapArray:', JSON.stringify(this.floorUnitMapArray));
    }

    handleBHKClick(event) {
        debugger;
        const buttons = this.template.querySelectorAll('.buttonBHK');
        console.log('Buttons:', buttons); 
        buttons.forEach(button => {
            button.style.backgroundColor = '#D6D6D6';
            button.textContent = 'Select';
        });
        let clickedButton;
        if (event) {
            clickedButton = event.currentTarget;
            this.FlatBhkId = event.target.dataset.eventId;
        } else if (this.FlatBhkId) {
            clickedButton = Array.from(buttons).find(button => button.dataset.eventId === this.FlatBhkId);
        }
        if (clickedButton) {
            clickedButton.style.backgroundColor = '#00A1E0';
            clickedButton.textContent = 'Selected';
        }
        if (event) {
            this.SearchUnits();
        }
    }

    handleDivClick(event) {
        debugger;
        const clickedId = event.currentTarget.getAttribute('data-event-id');
        this.selectedId = clickedId;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.selectedId,
                objectApiName: 'Unit__c',
                actionName: 'view'
            }
        });
    }

    handleClose() {
        this.unitBoolean = false;
    }

    handleMouseOver(event) {
        const itemId = event.currentTarget.dataset.id;
        const tooltip = this.template.querySelector(`#tooltip-${itemId}`);
        const unitType = event.currentTarget.dataset.unitType || 'N/A';
        const slab = event.currentTarget.dataset.slab || 'N/A';
        const status = event.currentTarget.dataset.status || 'N/A';
        const tower = event.currentTarget.dataset.tower || 'N/A';

        tooltip.innerHTML = `
        <strong>Unit Type:</strong> ${unitType}<br>
        <strong>Slab:</strong> ${slab}<br>
        <strong>Status:</strong> ${status}<br>
        <strong>Tower:</strong> ${tower}
    `;
        const rect = event.currentTarget.getBoundingClientRect();
        tooltip.style.left = `${rect.left + window.scrollX}px`;
        tooltip.style.top = `${rect.top + window.scrollY - tooltip.offsetHeight - 5}px`;
        tooltip.style.display = 'block';
    }

    handleMouseOut(event) {
        const itemId = event.currentTarget.dataset.id;
        const tooltip = this.template.querySelector(`#tooltip-${itemId}`);
        tooltip.style.display = 'none';
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title,
            message,
            variant
        });
        this.dispatchEvent(event);
    }
}