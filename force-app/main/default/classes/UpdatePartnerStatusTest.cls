/**
 * @description       : 
 * @author            : Nagy
 * @group             : 
 * @last modified on  : 03-24-2023
 * @last modified by  : Nagy
**/
@isTest
public with sharing class UpdatePartnerStatusTest {
    static testMethod void testPartnerStatus(){

        Account inactiveAccount = new Account(Name = 'inactiveAccount',Partner_Type__c='Referral Partner');
        insert inactiveAccount;
        Test.setCreatedDate(inactiveAccount.Id,Datetime.now().addDays(-200));
        Account dormantAccount = new Account(Name = 'dormantAccount',Partner_Type__c='Referral Partner');
        insert dormantAccount;
        Test.setCreatedDate(dormantAccount.Id,Datetime.now().addDays(-100));

        Account inactiveAccountNoLead = new Account(Name = 'inactiveAccount',Partner_Type__c='Referral Partner');
        insert inactiveAccountNoLead;
        Test.setCreatedDate(inactiveAccountNoLead.Id,Datetime.now().addDays(-200));
        Account dormantAccountNoLead = new Account(Name = 'dormantAccount',Partner_Type__c='Referral Partner');
        insert dormantAccountNoLead;
        Test.setCreatedDate(dormantAccountNoLead.Id,Datetime.now().addDays(-100));

        //Active Account
        Account activeAccount = new Account(Name = 'acticeAccount',Partner_Type__c='Referral Partner');
        insert activeAccount;
        Test.setCreatedDate(inactiveAccount.Id,Datetime.now().addDays(-100));
        Lead activeAccountLead = new Lead (LastName = 'activeAccountLead',Referrer_Account__c = activeAccount.Id, Company = 'ABC');
        insert activeAccountLead;

        system.schedule('UpdatePartnerStatusSchedule', '0 0 * * * ?', new UpdatePartnerStatusSchedule());
        Database.executeBatch(new UpdatePartnerStatusBatch(), 200);

        Lead dormantAccountLead = new Lead (LastName = 'dormantAccountLead',Referrer_Account__c = dormantAccount.Id, Company = 'ABC');
        insert dormantAccountLead;
        Test.setCreatedDate(dormantAccountLead.Id,Datetime.now().addDays(-100));
        Lead inactiveAccountLead = new Lead (LastName = 'inactiveAccountLead',Referrer_Account__c = inactiveAccount.Id, Company = 'ABC');
        insert inactiveAccountLead;
        Test.setCreatedDate(inactiveAccountLead.Id,Datetime.now().addDays(-200));
        Database.executeBatch(new UpdatePartnerStatusBatch(), 200);
        
    }
}