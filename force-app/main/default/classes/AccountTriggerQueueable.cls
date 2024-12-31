public with sharing class AccountTriggerQueueable {
    public AccountTriggerQueueable() {

    }

    public class Cin7Account{
        public String Email;
        public String FirstName;
        public String LastName;
        public String ContactName;
        public String CompanyName;
        public String Phone;
        public String Address;
        public String AddressLine1;
        public String AddressLine2;
        public String City;
        public String State;
        public String ZipPostcode;
        public String Country;
        public String Timezone;
        public String Industry;
        public String WebsiteURL;
        public String PaymentFrequency;
        public String Type;
        public Decimal TrialDays;
        public String DemoData;
        public String CouponReferralCode;
        public String TenantID; // field used to update partner account info
    }

    public class Cin7ClientPartnerRelationship{
        public String PartnerID;
        public String ClientID;
        public String Type;
        public Boolean IsPartnerOnboarding;
    }
}