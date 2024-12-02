/**
 * @description       : Wrapper class used to parse JSON from "Get Customer Details" callout. Translate into custom data structure.
 * @author            : AS | NuAge Experts
 * @group             : 
 * @last modified on  : 02-28-2024
 * @last modified by  : AS | NuAge Experts
**/
public with sharing class IncomingRequestJSONParse {
    public Data Data;
    public List<String> Errors;

    public class Data {
        public Integer Sales6MonthsCount{get;set;}
		public Integer IntegrationCount{get;set;}
		public Integer SalesCount{get;set;}
		public String AnniversaryDate{get;set;}
		public Integer Sales3MonthsCount{get;set;}
		public String Status{get;set;}
		public Integer Sales12MonthsCount{get;set;}
		public Decimal Discount{get;set;}
		public Decimal SalesGMV{get;set;}
		public Decimal AdditionalUsersCost{get;set;}
		public Decimal SalesGMV3Months{get;set;}
		public Integer AdditionalUsers{get;set;}
		public Decimal SalesGMV6Months{get;set;}
		public String ReferrerDomain{get;set;}
		public Decimal SalesGMV12Months{get;set;}
		public String IsVarPartner{get;set;}
		public List<SKUs> SKUs;
		public String PartnerType{get;set;}
		public list<Users> Users{get;set;}
		public String Utm_Content{get;set;}
		public list<Discount> Discounts{get;set;}
		public String Utm_Term{get;set;}
		public String Country{get;set;}
		public String Utm_Medium{get;set;}
		public Datetime CreateDate{get;set;}
		public String Utm_Source{get;set;}
		public String Email{get;set;}
		public String Utm_Campaign{get;set;}
		public Datetime LastUpdatedDate{get;set;}
		public String CustomerDomain{get;set;}
		public String Organisation{get;set;}
		public Boolean IsNeedAttention{get;set;}
		public String SalesPersonEmail{get;set;}
		public String PlanType{get;set;}
		public String TenantID{get;set;}
		public String ReferredByPartnerId{get;set;}
		public String WebsiteURL{get;set;}
		public String ReferredByPartner{get;set;}
		public String SubscriptionExpirationDate{get;set;}
		public String SubscriptionName{get;set;}
		public String Source{get;set;}
		public Datetime Cancelled{get;set;}
		public list<Contacts> Contacts{get;set;}
		public Datetime Subscribed{get;set;}
		public Boolean IsOnboardingOptional{get;set;}

    }
    public class SKUs {
        public String Name;
        public Integer Quantity;
        public Double Total;
        public String Frequency;
    }
    public class Contacts {
        public String Phone;
        public String Email;
        public String FirstName;
        public String LastName;
    }
    public class Users{
		public String UserType{get;set;}
		public String DisplayName{get;set;}
		public String Email{get;set;}
		public String UserId{get;set;}
	}

	public class Discount{
		public String ID{get;set;}
		public String ValidTill{get;set;}
		public Decimal Discount{get;set;}
		public String SubscriptionFeatureGroup{get;set;}
		public Boolean IsOnboardingDiscount{get;set;}
		
	}
    
    public static IncomingRequestJSONParse parse(String json) {
        return (IncomingRequestJSONParse) System.JSON.deserialize(json, IncomingRequestJSONParse.class);
    }
}