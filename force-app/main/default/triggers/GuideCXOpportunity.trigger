/* Opportunity trigger to update GuideCX
 * Micado 2022
 * 
 * Change Log
 * 08/07/2022 Inital version
 * 12/07/2022 Added logic for beynd__CreateBeyndProjectOnClosedWon__c checkbox
*/
trigger GuideCXOpportunity on Opportunity (before insert, 
  before update, 
  before delete, 
  after insert, 
  after update, 
  after delete,
  after undelete) {
    Set<Id> closedWon = new Set<Id>();
    switch on Trigger.operationType { 
      /**
        Finds opportunities that have been moved to closed/won and sends the 
        set of IDs to the GuideCXService class to handle further.
      */
      

      // when BEFORE_INSERT {}         
      // when BEFORE_UPDATE {}
      // when BEFORE_DELETE {}         
      when AFTER_INSERT {
        for (Opportunity o : Trigger.new) {
          if(o.IsWon && o.beynd__CreateBeyndProjectOnClosedWon__c){
            closedWon.add(o.Id);
          }
        }
      }
      when AFTER_UPDATE {
        for (Opportunity o : Trigger.new) {
          if (o.IsWon && !Trigger.oldMap.get(o.Id).IsWon && o.beynd__CreateBeyndProjectOnClosedWon__c) { 
            closedWon.add(o.Id);
          }
        }
      }
      // when AFTER_DELETE {}         
      // when AFTER_UNDELETE {}  

      
      // for (Opportunity o : Trigger.new) {
      //   if (o.IsWon && !Trigger.oldMap.get(o.Id).IsWon && o.beynd__CreateBeyndProjectOnClosedWon__c) { 
      //     closedWon.add(o.Id);
      //   }
      // }

    }
  if (!closedWon.isEmpty()) { 
    beynd.GuideCXService.createProjects(closedWon);
  }
}