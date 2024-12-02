trigger makeAllTasksPublic on Task (before insert) {
for (Task t : trigger.new) {
if (t.IsVisibleInSelfService != true) {
t.IsVisibleInSelfService = true;
}
if(UserInfo.getUserRoleId() =='00E28000001lpJC' && t.type=='Email')
{
if(t.Minutes__c == 0 || t.Minutes__c==null)
t.Minutes__c=10;
} 
}
}