/**
 * @description       : 
 * @author            : Nagy
 * @group             : 
 * @last modified on  : 03-10-2023
 * @last modified by  : Nagy
**/
global with sharing class UpdatePartnerStatusSchedule implements Schedulable {
    global void execute(SchedulableContext sc) {
        //Database.executeBatch takes in the class, and then the size of batches.
        ID BatchId = Database.executeBatch(new UpdatePartnerStatusBatch(), 200);
    }
}