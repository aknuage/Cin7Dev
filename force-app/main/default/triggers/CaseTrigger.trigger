trigger CaseTrigger on Case (before insert, before update, before delete, after insert, after update, after delete) {
    // triggers for the Case object are now processed in the class caseTriggerClass
    CaseTriggerClass.processTrigger(Trigger.oldMap, Trigger.new, Trigger.isBefore);
}