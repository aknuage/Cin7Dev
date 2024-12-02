trigger insertMontainStandardTimeZone on Lead (before insert,before update) {
    
    //Redundant code
    //String TimeZones = '(GMT-07:00) Mountain Standard Time (America/Denver)';
    //List<String> lststrsplit = TimeZones.substring(12,TimeZones.length()).split('\\(',2);
    //string strTimeZone = lststrsplit[1].substring(0,lststrsplit[1].length()-1);
    private static final String STRTIMEZONE = 'America/Denver';
    
    //Code Enhancements by Sid
    for(Lead lead : Trigger.New){

        //Logic To be Executed when Lead is Inserted
        if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)){

            //Set the Reporting_NewStatus_Date__c based on NewStatusDate__c
            if(lead.NewStatusDate__c != NULL){
                            
                lead.Reporting_NewStatus_Date__c = getDateInMst(lead.NewStatusDate__c);
            }

            //Set the Reporting_WorkingStatus_Date__c based on WorkingStatusDate__c
            if(lead.WorkingStatusDate__c != NULL){
            
                lead.Reporting_WorkingStatus_Date__c = getDateInMst(lead.WorkingStatusDate__c);
            }

            //Set the Reporting_UnqualifiedStatus_Date__c based on UnqualifiedStatusDate__c
            if(lead.UnqualifiedStatusDate__c != NULL){
            
                lead.Reporting_UnqualifiedStatus_Date__c = getDateInMst(lead.UnqualifiedStatusDate__c);
            }

            //Set the Reporting_CreatedDate__c based on CreatedDate
            if(lead.CreatedDate != NULL){
            
                lead.Reporting_CreatedDate__c = getDateInMst(lead.CreatedDate);
            }
        }        
    }

    //Method to return the Date in MST Timezone
    public static Date getDateInMst(Datetime dateTimeToFormat){

        if(dateTimeToFormat != NULL){
            Datetime dateTimeFormatted = Datetime.valueof(dateTimeToFormat.format('YYYY-MM-dd HH:mm:ss', STRTIMEZONE));
            return Date.newInstance(dateTimeFormatted.year(), dateTimeFormatted.month(), dateTimeFormatted.day());
        }        
        return NULL;
    }
}