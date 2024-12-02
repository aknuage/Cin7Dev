@isTest
public class insertMontainStandardTimeZoneTest {
	@isTest
    public static void method1(){
       	Id userId = UserInfo.getUserId();
        Account acc = new Account();
        acc.Name = 'Test Account';
        insert acc;
        
        Contact con = new Contact();
        con.LastName = 'Mitul Test';
        con.Email = 'test@gmail.com';
        con.AccountId = acc.Id;
        insert con;
        
        Lead l = new Lead();
        l.Company = 'Test ABX';
        l.LastName = 'Test 123';
		l.Email = 'test@gmail.com';
        l.Phone = '7485965263';
        l.Status = 'New';
        l.LeadSource = 'Customer Referral';
        l.Type__c = 'Customer';
        l.Sales_Region__c = 'Americas';
        l.Referrer_Account__c = acc.Id;
        l.Referral_Contact__c = con.Id;
        l.Sales_Coordinator__c = userId;
        //l.NewStatusDate__c = System.now();
        insert l;  
        l.NewStatusDate__c = System.now().AddDays(2);
        l.WorkingStatusDate__c = System.now().AddDays(2);
        l.UnqualifiedStatusDate__c = System.now().AddDays(2);
        update l;
        
    }
    
    @isTest
    public static void method2(){
        Id userId = UserInfo.getUserId();
        Account acc = new Account();
        acc.Name = 'Test Account';
        insert acc;
        
        Contact con = new Contact();
        con.LastName = 'Mitul Test';
        con.Email = 'test@gmail.com';
        con.AccountId = acc.Id;
        insert con;
        
        Lead l = new Lead();
        l.Company = 'Test ABX';
        l.LastName = 'Test 123';
		l.Email = 'test@gmail.com';
        l.Phone = '7485965263';
        l.Status = 'Working';
        l.LeadSource = 'Customer Referral';
        l.Type__c = 'Customer';
        l.Sales_Region__c = 'Americas';
        //l.WorkingStatusDate__c = System.now();
        l.Referrer_Account__c = acc.Id;
        l.Referral_Contact__c = con.Id;
        l.Sales_Coordinator__c = userId;
        insert l;
        l.NewStatusDate__c = System.now().AddDays(3);
        l.WorkingStatusDate__c = System.now().AddDays(3);
        l.UnqualifiedStatusDate__c = System.now().AddDays(3);
        
        update l;
    }
    
    @isTest
    public static void method3(){
        Id userId = UserInfo.getUserId();
        Account acc = new Account();
        acc.Name = 'Test Account';
        insert acc;
        
        Contact con = new Contact();
        con.LastName = 'Mitul Test';
        con.Email = 'test@gmail.com';
        con.AccountId = acc.Id;
        insert con;
        
        Lead l = new Lead();
        l.Company = 'Test ABX';
        l.LastName = 'Test 123';
		l.Email = 'test@gmail.com';
        l.Phone = '7485965263';
        l.Status = 'Unqualified';
        l.LeadSource = 'Customer Referral';
        l.Type__c = 'Customer';
        l.Sales_Region__c = 'Americas';
        //l.UnqualifiedStatusDate__c = System.now();
        l.Referrer_Account__c = acc.Id;
        l.Referral_Contact__c = con.Id;
        l.Sales_Coordinator__c = userId;
        insert l;
        l.NewStatusDate__c = System.now().AddDays(4);
        l.WorkingStatusDate__c = System.now().AddDays(4);
        l.UnqualifiedStatusDate__c = System.now().AddDays(4);
        update l;
    }
    
    @isTest
    public static void method4(){
       	Id userId = UserInfo.getUserId();
        Account acc = new Account();
        acc.Name = 'Test Account';
        insert acc;
        
        Contact con = new Contact();
        con.LastName = 'Mitul Test';
        con.Email = 'test@gmail.com';
        con.AccountId = acc.Id;
        insert con;
        
        Lead l = new Lead();
        l.Company = 'Test ABX';
        l.LastName = 'Test 123';
		l.Email = 'test@gmail.com';
        l.Phone = '7485965263';
        l.Status = 'New';
        l.LeadSource = 'Customer Referral';
        l.Type__c = 'Customer';
        l.Sales_Region__c = 'Americas';
        l.Referrer_Account__c = acc.Id;
        l.Referral_Contact__c = con.Id;
        l.Sales_Coordinator__c = userId;
        l.NewStatusDate__c = System.now();
        insert l; 
      	l.NewStatusDate__c = System.now().AddDays(5);
        l.WorkingStatusDate__c = System.now().AddDays(5);
        l.UnqualifiedStatusDate__c = System.now().AddDays(5);
        update l;
        
    }
    
    @isTest
    public static void method5(){
        Id userId = UserInfo.getUserId();
        Account acc = new Account();
        acc.Name = 'Test Account';
        insert acc;
        
        Contact con = new Contact();
        con.LastName = 'Mitul Test';
        con.Email = 'test@gmail.com';
        con.AccountId = acc.Id;
        insert con;
        
        Lead l = new Lead();
        l.Company = 'Test ABX';
        l.LastName = 'Test 123';
		l.Email = 'test@gmail.com';
        l.Phone = '7485965263';
        l.Status = 'Working';
        l.LeadSource = 'Customer Referral';
        l.Type__c = 'Customer';
        l.Sales_Region__c = 'Americas';
        l.WorkingStatusDate__c = System.now();
        l.Referrer_Account__c = acc.Id;
        l.Referral_Contact__c = con.Id;
        l.Sales_Coordinator__c = userId;
        insert l;
        l.NewStatusDate__c = System.now().AddDays(6);
        l.WorkingStatusDate__c = System.now().AddDays(6);
        l.UnqualifiedStatusDate__c = System.now().AddDays(6);
        update l;
    }
    
    @isTest
    public static void method6(){
        Id userId = UserInfo.getUserId();
        Account acc = new Account();
        acc.Name = 'Test Account';
        insert acc;
        
        Contact con = new Contact();
        con.LastName = 'Mitul Test';
        con.Email = 'test@gmail.com';
        con.AccountId = acc.Id;
        insert con;
        
        Lead l = new Lead();
        l.Company = 'Test ABX';
        l.LastName = 'Test 123';
		l.Email = 'test@gmail.com';
        l.Phone = '7485965263';
        l.Status = 'Unqualified';
        l.LeadSource = 'Customer Referral';
        l.Type__c = 'Customer';
        l.Sales_Region__c = 'Americas';
        l.UnqualifiedStatusDate__c = System.now();
        l.Referrer_Account__c = acc.Id;
        l.Referral_Contact__c = con.Id;
        l.Sales_Coordinator__c = userId;
        insert l;
        l.NewStatusDate__c = System.now().AddDays(7);
        l.WorkingStatusDate__c = System.now().AddDays(7);
        l.UnqualifiedStatusDate__c = System.now().AddDays(7);
        update l;
    }
}