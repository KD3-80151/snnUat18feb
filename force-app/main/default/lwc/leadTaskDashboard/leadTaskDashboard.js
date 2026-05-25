//with Platform events

import { LightningElement, api, wire } from 'lwc';
import { subscribe, unsubscribe, onError, setDebugFlag, isEmpEnabled } from 'lightning/empApi';
import getRelatedTasks from '@salesforce/apex/LeadTaskController.getRelatedTasks';
import { refreshApex } from '@salesforce/apex';

export default class LeadTaskDashboard extends LightningElement {
    @api recordId;
    totalTasks = 0;
    openTasks = 0;
    completedTasks = 0;
    priorityTasks = 0;
    wiredTaskResult;
    subscription = {}; // To store the subscription object

    channelName = '/event/TaskChangeEvent__e'; // The platform event channel name

    @wire(getRelatedTasks, { leadId: '$recordId' })
    wiredTasks(result) {
        this.wiredTaskResult = result;
        const { data, error } = result;

        if (data) {
            this.totalTasks = data.length;
            this.openTasks = data.filter(task => task.Status === 'Open').length;
            this.completedTasks = data.filter(task => task.Status === 'Completed').length;
            this.priorityTasks = data.filter(task => task.Priority === 'High').length;
        } else if (error) {
            console.error('Error fetching tasks', error);
        }
    }
    connectedCallback() {
        this.handleSubscribe();
    }
    disconnectedCallback() {
        this.handleUnsubscribe();
    }

    handleSubscribe() {
        const messageCallback = (response) => {
            console.log('New event received: ', response);
            this.refreshTaskData();
        };

        // Subscribe to platform event channel
        subscribe(this.channelName, -1, messageCallback).then(response => {
            console.log('Subscription request sent: ', response);
            this.subscription = response;
        });
    }

    handleUnsubscribe() {
        unsubscribe(this.subscription, response => {
            console.log('Unsubscribed from channel: ', response);
        });
    }
    refreshTaskData() {
        refreshApex(this.wiredTaskResult);
    }
}