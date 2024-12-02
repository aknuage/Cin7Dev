global class EmailAccept2 implements Messaging.InboundEmailHandler {
   global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
       Lead lead;
       Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();    
       try {
           //Look for lead whos name is the email and create it if necessary
           List<Lead> leadList = new List<Lead>();
           String tempLead = email.FromAddress;
           System.debug('FROMADDRESS = '+email.FromAddress);
           System.debug('FROMADDRESS TEMPLEAD = '+tempLead);
           String leadQuery = 'select LastName from Lead where LastName = \'' + tempLead +'\'';
           leadList = Database.Query(leadQuery);
           Integer leadCount = leadList.size();
           System.debug('LEAD COUNT FROM THE QUERY -'+leadCount);
           if ([select count() from Lead where email = :email.fromAddress] == 0) {
               System.Debug('INSIDE IF for LEAD COUNT EQUAL TO 0');
              lead = new Lead();
               lead.Status = 'New';
               lead.LastName = email.FromName;
               lead.Company = (email.FromAddress.split('@').get(1));
               lead.Email = email.FromAddress;
               lead.LeadSource = 'Inbound Email - Sales';
               lead.description = email.plainTextBody;
               
               insert lead;
           } else { //Lead already exists
               lead = [select Id from Lead where email = :email.FromAddress];
           }        
           result.success = true;
       } catch (Exception e) {
           result.success = false;
           result.message = 'Error processing email...';
       }
       return result;
   }
}