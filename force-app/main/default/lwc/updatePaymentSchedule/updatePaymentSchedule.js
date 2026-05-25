import { LightningElement, api, track } from 'lwc';
import getPaymentSchedules from '@salesforce/apex/UpdatePaymentScheduleController.getPaymentSchedules';
import savePaymentSchedule from '@salesforce/apex/UpdatePaymentScheduleController.savePaymentSchedule';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { loadStyle } from "lightning/platformResourceLoader";
import modal from "@salesforce/resourceUrl/custommodalcss";
import { CloseActionScreenEvent } from 'lightning/actions';

export default class UpdatePaymentSchedule extends LightningElement {
    @api recordId; // Opportunity Id
    @track paymentSchedules = [];
    @track originalPaymentSchedules = []; // To store the original payment schedules
    error;

    // Fetch payment schedules when the component is initialized
    connectedCallback() {
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

        // If recordId is available, fetch the payment schedules
        if (this.recordId) {
            this.fetchPaymentSchedules();
        } else {
            console.warn('No recordId provided.');
        }
    }

    // Fetch payment schedules from Apex
    fetchPaymentSchedules() {
        getPaymentSchedules({ opportunityId: this.recordId })
            .then((result) => {
                console.log('Fetched payment schedules:', result);
                this.paymentSchedules = result;
                this.originalPaymentSchedules = JSON.parse(JSON.stringify(result)); // Store a copy of the original schedules
                this.error = undefined;
            })
            .catch((error) => {
                console.error('Error fetching payment schedules:', error);
                this.error = error.body.message;
                this.paymentSchedules = [];
            });
    }

    // Handle change in date fields (Pay Date and Due Date)
    handleDateChange(event) {
        const scheduleId = event.target.dataset.id; // Retrieve the ID of the schedule
        const field = event.target.dataset.field;  // Retrieve the field name (Pay_Date or Due_Date)
        const value = event.target.value;          // Retrieve the updated value (new date)

        // Ensure that scheduleId, field, and value are correct
        if (!scheduleId || !field || !value) {
            console.error('Missing required values. scheduleId:', scheduleId, 'field:', field, 'value:', value);
            return;
        }

        // Find the schedule record in the paymentSchedules array by ID
        const scheduleIndex = this.paymentSchedules.findIndex(item => item.Id === scheduleId);

        if (scheduleIndex !== -1) {
            const d = new Date(value);
            d.setDate(d.getDate() + 15);
            let dueDate = d.toISOString().split('T')[0];
            // Create a new object to trigger reactivity
            const updatedSchedule = { ...this.paymentSchedules[scheduleIndex], [field]: value , ['Due_Date__c']: dueDate};

            // Replace the old schedule with the updated one
            this.paymentSchedules = [
                ...this.paymentSchedules.slice(0, scheduleIndex),
                updatedSchedule,
                ...this.paymentSchedules.slice(scheduleIndex + 1)
            ];
        } else {
            console.error('Schedule not found for ID:', scheduleId);
        }
    }

    // Save the updated payment schedules
    handleSave(event) {
        // Filter the modified payment schedules by comparing with original values
        const modifiedSchedules = this.paymentSchedules.filter(schedule => {
            const originalSchedule = this.originalPaymentSchedules.find(s => s.Id === schedule.Id);
            return (originalSchedule && 
                    (originalSchedule.Pay_Date__c !== schedule.Pay_Date__c || 
                     originalSchedule.Due_Date__c !== schedule.Due_Date__c));
        });

        if (modifiedSchedules.length > 0) {
            // If there are modified schedules, save them
            savePaymentSchedule({ paymentSchedules: modifiedSchedules })
                .then(() => {
                    this.showToast('Success!', 'Payment schedules updated successfully.', 'success');
                 
                    this.closeScreen();
                      
                })
                .catch((error) => {
                    console.error('Error saving payment schedules:', error);
                    this.error = error.body.message;
                });
        } else {
            // Show an error toast if no changes were detected
            this.showToast('Error', 'No changes detected. Please modify the payment schedules before saving.', 'error');
        }
    }

    handleCancel() {
        this.closeScreen();
    }

    // Close the modal or action screen
    closeScreen() {
        const closeActionEvent = new CloseActionScreenEvent();
        this.dispatchEvent(closeActionEvent);
        setTimeout(() => {
        window.location.reload();
    }, 500); // half a second delay
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
}