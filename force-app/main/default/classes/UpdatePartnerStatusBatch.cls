/**
 * @description       : 
 * @author            : Nagy
 * @group             : 
 * @last modified on  : 04-11-2023
 * @last modified by  : AS | NuAge Experts
**/
public class UpdatePartnerStatusBatch implements
    Database.Batchable<sObject>, Database.Stateful {
    // instance member to retain state across transactions
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'Select Id, Name ,CreatedDate,Partner_Status__c, (Select Id, CreatedDate from leads__r order by createddate desc limit 1) from Account where recordType.Name = \'Partner Account\''
        );
    }
    public void execute(Database.BatchableContext bc, List<Account> scope){
        System.debug('UpdatePartnerStatusBatch Triggered...');
        // process each batch of records
        for (Account account : scope) {
            if (account.Leads__r.size()>0){
                if (account.Leads__r[0].CreatedDate<date.today().addMonths(-6)){
                    account.Partner_Status__c = 'Inactive';
                }
                else if (account.Leads__r[0].CreatedDate<date.today().addMonths(-3)){
                    account.Partner_Status__c = 'Dormant';
                }
                else{
                    account.Partner_Status__c = 'Active';
                }
            }
            else{
                if (account.CreatedDate<date.today().addMonths(-6)){
                    account.Partner_Status__c = 'Inactive';
                }
                else if (account.CreatedDate<date.today().addMonths(-3)){
                    account.Partner_Status__c = 'Dormant';
                }
            }
            
        }
        update scope;
    }
    public void finish(Database.BatchableContext bc){
        AsyncApexJob job = [SELECT Id, Status FROM AsyncApexJob WHERE Id = :bc.getJobId()]; 
        System.debug('>>>> finish ' + job.Status);
    }
}