import { LightningElement, track } from 'lwc';
import getTaxInvoices from '@salesforce/apex/OpportunityReceiptController.getTaxInvoices';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import LightningConfirm from 'lightning/confirm';
import markGSTPaidForInvoices from '@salesforce/apex/OpportunityReceiptController.markGSTPaidForInvoices';

export default class OpportunityReceipts extends LightningElement {
    @track loading = false;

    @track startDate;
    @track endDate;

    @track taxInvoices = [];
    @track grandTotalGST = '0.00';
    @track selectedTotalGST = '0.00';

    selectedInvoiceIds = new Set();

    @track showGSTPaidModal = false;
    @track taxPaidDate; 

    columns = [
        {
            label: 'Tax Invoice',
            fieldName: 'taxInvoiceUrl',
            type: 'url',
            typeAttributes: { label: { fieldName: 'Name' }, target: '_blank' }
        },
        {
            label: 'Account Name',
            fieldName: 'accountUrl',
            type: 'url',
            typeAttributes: { label: { fieldName: 'accountName' }, target: '_blank' }
        },
        {
            label: 'Receipt',
            fieldName: 'receiptUrl',
            type: 'url',
            typeAttributes: { label: { fieldName: 'receiptName' }, target: '_blank' }
        },
        {
            label: 'Payment Schedule',
            fieldName: 'paymentScheduleUrl',
            type: 'url',
            typeAttributes: { label: { fieldName: 'paymentScheduleName' }, target: '_blank' }
        },
        {
            label: 'Received Amount',
            fieldName: 'Received_Amount__c',
            type: 'currency',
            cellAttributes: { alignment: 'left' }
        },
        {
            label: 'SGST',
            fieldName: 'SGST_new__c',
            type: 'currency',
            cellAttributes: { alignment: 'left' }
        },
        {
            label: 'CGST',
            fieldName: 'CGST_new__c',
            type: 'currency',
            cellAttributes: { alignment: 'left' }
        },
        {
            label: 'Total Tax Amount',
            fieldName: 'Total_Tax_Amount__c',
            type: 'currency',
            cellAttributes: { alignment: 'left' }
        },
        { label: 'Created Date', fieldName: 'CreatedDate', type: 'date' }
    ];

    get showGrandTotal() {
        return this.grandTotalGST !== null && this.grandTotalGST !== undefined;
    }

    get showNoData() {
        return !this.loading && this.taxInvoices && this.taxInvoices.length === 0;
    }

    get showSelectedTotal() {
        return this.selectedInvoiceIds && this.selectedInvoiceIds.size > 0;
    }

    // ✅ single getter only
    get disableGSTPaidDone() {
        return (
            this.loading ||
            !this.startDate ||
            !this.endDate ||
            (this.selectedInvoiceIds?.size || 0) === 0
        );
    }

    handleStartDateChange(event) {
        this.startDate = event.target.value;
    }

    handleEndDateChange(event) {
        this.endDate = event.target.value;
    }

    async handleSearch() {
        if (!this.startDate || !this.endDate) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Missing Dates',
                    message: 'Please select Start Date and End Date.',
                    variant: 'warning'
                })
            );
            return;
        }

        this.loading = true;
        this.selectedInvoiceIds = new Set();
        this.selectedTotalGST = '0.00';

        try {
            const data = await getTaxInvoices({
                startDate: this.startDate,
                endDate: this.endDate
            });

            let total = 0;

            this.taxInvoices = (data || []).map((ti) => {
                const taxPaid = ti.Total_Tax_Amount__c || 0;
                total += taxPaid;

                return {
                    ...ti,
                    taxInvoiceUrl: '/' + ti.Id,
                    paymentScheduleUrl: ti.Payment_Schedule__c ? '/' + ti.Payment_Schedule__c : null,
                    paymentScheduleName: ti.Payment_Schedule__r?.Name,
                    accountUrl: ti.Account__c ? '/' + ti.Account__c : null,
                    accountName: ti.Account__r?.Name,
                    receiptUrl: ti.Receipt__c ? '/' + ti.Receipt__c : null,
                    receiptName: ti.Receipt__r?.Name
                };
            });

            this.grandTotalGST = total.toFixed(2);
        } catch (err) {
            console.error(err);
            this.taxInvoices = [];
            this.grandTotalGST = '0.00';

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: err?.body?.message || 'Error while loading Tax Invoices',
                    variant: 'error'
                })
            );
        } finally {
            this.loading = false;
        }
    }

    handleRowSelection(event) {
        const selectedRows = event.detail.selectedRows || [];
        this.selectedInvoiceIds = new Set(selectedRows.map((r) => r.Id));

        let selectedTotal = 0;
        selectedRows.forEach((r) => {
            selectedTotal += r.Total_Tax_Amount__c || 0;
        });
        this.selectedTotalGST = selectedTotal.toFixed(2);
    }

    async handleGSTPaidDone() {
        if (!this.startDate || !this.endDate) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Missing Dates',
                    message: 'Please select Start Date and End Date.',
                    variant: 'warning'
                })
            );
            return;
        }

        const confirm = await LightningConfirm.open({
            message: 'Mark GST Paid for selected Tax Invoices?',
            label: 'Confirm GST Paid',
            theme: 'warning'
        });

        if (!confirm) return;

        this.taxPaidDate = null;
        this.showGSTPaidModal = true;
    }

    handleTaxPaidDateChange(event) {
        this.taxPaidDate = event.target.value; 
    }

    closeGSTPaidModal() {
        this.showGSTPaidModal = false;
        this.taxPaidDate = null;
    }

    async saveGSTPaid() {
        this.loading = true;

        try {
            await markGSTPaidForInvoices({
                taxInvoiceIds: Array.from(this.selectedInvoiceIds),
                taxPaidDate: this.taxPaidDate // can be null
            });

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'GST Paid updated for Tax Invoices and eligible Payment Schedules.',
                    variant: 'success'
                })
            );

            this.closeGSTPaidModal();
            await this.handleSearch();
        } catch (err) {
            console.error(err);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: err?.body?.message || 'Error while updating GST Paid',
                    variant: 'error'
                })
            );
        } finally {
            this.loading = false;
        }
    }
}