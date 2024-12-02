trigger InsertMSTZoneOpportunity on Opportunity (before insert, before update) {
    
    private static final String STRTIMEZONE = 'America/Denver';
    
    for(Opportunity Opportunity : Trigger.New)
    {
        
        if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate))
        {
            
            if(Opportunity.CloseDate != NULL)
            {
                DateTime dt = DateTime.newInstance(Opportunity.CloseDate.year(), Opportunity.CloseDate.month(),Opportunity.CloseDate.day(), system.now().hour(), system.now().minute(), system.now().second() );
                Opportunity.ReportingExpectedCloseDate__c = getDateInMst(dt);
            }
        }        
    }
    
    public static Date getDateInMst(Datetime dateTimeToFormat)
    {
        
        if(dateTimeToFormat != NULL)
        {
            Datetime dateTimeFormatted = Datetime.valueof(dateTimeToFormat.format('YYYY-MM-dd HH:mm:ss', STRTIMEZONE));
            return Date.newInstance(dateTimeFormatted.year(), dateTimeFormatted.month(), dateTimeFormatted.day());
        }        
        return NULL;
    }
}