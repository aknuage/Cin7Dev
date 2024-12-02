@istest
public class TriggerOpsGenieNotifTest {
	@istest
	public static void TriggerOpsGenieNotifTest_success() {
		Test.setMock(HttpCalloutMock.class, new OpsGenieCalloutMock());
		TriggerOpsGenieNotifInvocable.OpsGenieNotif c = new TriggerOpsGenieNotifInvocable.OpsGenieNotif();

		c.description = 'Description';
		c.Priority = 'Escalated';
		c.subject = 'subject';

		TriggerOpsGenieNotifInvocable.invoke(new List<TriggerOpsGenieNotifInvocable.OpsGenieNotif>{ c });
	}
}