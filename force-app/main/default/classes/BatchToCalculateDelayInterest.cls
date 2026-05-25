public without sharing class BatchToCalculateDelayInterest implements Database.Batchable<SObject>{

    public Database.QueryLocator start(Database.BatchableContext bc) {
        List<Delay_Interest_Config__c> delayConfigDetails = [SELECT Interest_Percent_over_MCLR__c,MCLR_Rate__c,Name,Number_of_Days__c from Delay_Interest_Config__c where Name = 'Delay Interest' LIMIT 1];
        return Database.getQueryLocator([SELECT Id, Due_Date__c,Total_Due_Amount__c from Payment_Schedule__c where Due_Date__c < today AND Total_Due_Amount__c > 0]);
    }
    
    public void execute(Database.BatchableContext bc, List<Payment_Schedule__c> paymentSchList) {
        try{
            System.debug('paymentSchList ===> ' + paymentSchList);
            Integer currentYear = System.today().year();
            Date lastDayOfYear = Date.newInstance(currentYear, 12, 31);
            Integer daysInYear = lastDayOfYear.dayOfYear();
            
            List<Delay_Interest__c> delayInterestList = new List<Delay_Interest__c>();
            List<Delay_Interest_Config__c> delayConfigDetails = [SELECT Interest_Percent_over_MCLR__c,MCLR_Rate__c,Name,Number_of_Days__c from Delay_Interest_Config__c where Name = 'Delay Interest' LIMIT 1];
            Decimal totalPercentage = delayConfigDetails[0] != null ? (delayConfigDetails[0].Interest_Percent_over_MCLR__c + delayConfigDetails[0].MCLR_Rate__c) / 100 : 0;
            
            if(!paymentSchList.isEmpty() && daysInYear != null && totalPercentage != null){
                for(Payment_Schedule__c paymentSch : paymentSchList){
                    Decimal balanceDueAmount = paymentSch.Total_Due_Amount__c;
                    Integer noOfDaysDelayed = paymentSch.Due_Date__c.daysBetween(System.today());
                    if(noOfDaysDelayed > 0 && balanceDueAmount > 0){
                        Decimal delayAmount = (balanceDueAmount * totalPercentage * noOfDaysDelayed) / daysInYear;
                        System.debug('delayAmount ===> ' + delayAmount);
                        System.debug('noOfDaysDelayed ===> ' + noOfDaysDelayed);
                        Delay_Interest__c delay         = new Delay_Interest__c();
                        delay.Payment_Schedule__c       = paymentSch.Id;
                        delay.MCLR_Rate__c              = delayConfigDetails[0].MCLR_Rate__c;
                        delay.Interest_Percent_over_MCLR__c = delayConfigDetails[0].Interest_Percent_over_MCLR__c;
                        delay.Delay_Date__c             = System.today();
                        delay.Delay_Amount__c           = delayAmount.setScale(2);
                        delay.Demand_Amount__c          = balanceDueAmount;
                        delay.Number_of_Days_Delayed__c = noOfDaysDelayed;
                        delayInterestList.add(delay);
                        system.debug('delay ===> ' + delay);
                    }
                }
            }
            if(!delayInterestList.isEmpty()){
                insert delayInterestList;
            }
        }catch(Exception e){
            system.debug('Error ==> ' + e.getMessage());
            system.debug('Error in line ==> ' + e.getLineNumber());
        }
    }
    
    public void finish(Database.BatchableContext bc) {
        System.debug('batch executed successfully');
    }
}