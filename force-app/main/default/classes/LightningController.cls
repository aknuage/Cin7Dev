public class LightningController{
  public LightningController() { 
        
  }

  @AuraEnabled
  public static String getURL(){
        String domain = URL.getSalesforceBaseUrl().getHost();
        //String vfdomain = domain.replace('salesforce.com','visual.force.com');
        
        return 'https://'+domain+'/apex/LitmosNapiliDashboard'; 
  }
}