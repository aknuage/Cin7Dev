public with sharing class NorthpassHelper 
{
    /**
     * Return map of Northpass group Ids keyed by group name
     * 
     * @return Map of Northpass group Ids keyed by group name (label)
     * @author nkoonce @ NuAge : CIN7-107 : June 2024
     */
    public static Map<String,String> GetGroupIdsByName()
    {
        Map<String,String> returnValue = new Map<String,String>();

        Organization org = [SELECT Id, Name, IsSandbox FROM Organization];

        List<Northpass_Group__mdt> groups;
        
        // Get Northpass group info based on whether we're in a sandbox or prod
        if (org.IsSandbox)
        {
            groups = [SELECT Label, Northpass_Group_Id__c FROM Northpass_Group__mdt WHERE QualifiedApiName LIKE 'Sandbox%' LIMIT 100];
        }
        else groups = [SELECT Label, Northpass_Group_Id__c FROM Northpass_Group__mdt WHERE QualifiedApiName LIKE 'Prod%' LIMIT 100];

        // Build the map
        for (Northpass_Group__mdt npg : groups)
        {
            returnValue.put(npg.Label, npg.NorthPass_Group_Id__c);
        }

        return returnValue;
    }

    /**
     * Call queuable to create Northpass Subscriptions
     * 
     * @param subscriptionsToCreate - list of NorthpassSubscriptionWrappers
     * @return void
     * @author nkoonce @ NuAge : CIN7-107 : June 2024
     */
    public static void CreateNorthpassSubscriptions(List<NorthpassSubscriptionWrapper> subscriptionsToCreate) 
    {
        System.enqueueJob(new CreateNorthPassUserQueueable(subscriptionsToCreate));
    }

    /**
     * Enter withh AccountContactRelation, NorthpassSubscriptionWrapper and map of Northpass Group Ids by name. 
     * If the ACR has a Dear Tenant Id:
        - and the contact is a Customer, assign the Core Customer Group to the wrapper
        - and the contact is a Partner,  assign the Core Partner Group to the wrapper
     * If the ACR has a Cin7 Username: 
        - and the contact is a Customer, assign the Omni Customer Group to the wrapper
        - and the contact is a Partner, assign the Omni Partner Group to the wrapper
     * 
     * @param acr - Account Contact Relation record
     * @param wrap - NorthpassSubscriptionWrapper record
     * @param northpassGroupIdsByName - map of northpass group names to their respective Ids in Northpass
     * @return void 
     * @author nkoonce @ NuAge : CIN7-107 : July 2024
     */
    public static void AssignNorthpassGroup(AccountContactRelation acr, NorthpassSubscriptionWrapper wrap, Map<String,String> northpassGroupIdsByName)
    {
        // Get the group Id we want to subscribe each contact to
        if (String.isNotBlank(acr.Account.Dear_Tenant_Id__c))
        {
            if (acr.Contact.Contact_Type__c == 'Customer')
            {
                wrap.data.attributes.northpass_group_name = 'Core Customer';
                wrap.data.attributes.northpass_group_id = northpassGroupIdsByName.get('Core Customer');

            }
            else if (acr.Contact.Contact_Type__c == 'Partner')
            {
                wrap.data.attributes.northpass_group_name = 'Core Partner';
                wrap.data.attributes.northpass_group_id = northpassGroupIdsByName.get('Core Partner');
            }
        } 
        else if (String.IsNotBlank(acr.Account.Cin7_Username__c)) 
        {
            if (acr.Contact.Contact_Type__c == 'Customer')
            {
                wrap.data.attributes.northpass_group_name = 'Omni Customer';
                wrap.data.attributes.northpass_group_id = northpassGroupIdsByName.get('Omni Customer');

            }
            else if (acr.Contact.Contact_Type__c == 'Partner')
            {
                wrap.data.attributes.northpass_group_name = 'Omni Partner';
                wrap.data.attributes.northpass_group_id = northpassGroupIdsByName.get('Omni Partner');
            }
        }
        system.debug('User will be assigned to the ' + wrap.data.attributes.northpass_group_name + ' group, Id: ' + wrap.data.attributes.northpass_group_id);
    }
}