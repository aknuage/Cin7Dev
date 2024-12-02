public with sharing class NorthpassSubscriptionWrapper 
{
    public NorthpassSubscriptionWrapper()
    {
        data = new Data();
        data.attributes = new Attributes();
    }

    public Data data;

    public class Data 
    {
        public String type;
        public String id;
        public Attributes attributes;
    }    

    public class Attributes 
    {
        public String type;
        public String email;
        public String first_name;
        public String last_name;
        public String sso_uid;
        public String northpass_group_id;
        public String northpass_group_name;
        public String dear_tenant_id;
    }

    public static NorthpassSubscriptionWrapper parse (String json)
    {
        return (NorthpassSubscriptionWrapper) System.JSON.deserialize(json, NorthpassSubscriptionWrapper.class);
    }
}