public with sharing class TriggerOpsGenieNotifInvocable {
	@invocableMethod(
		label='Send Genie Ops Notif'
		description='Given a case, send a notification to Ops Genie'
		category='Case'
	)
	public static void invoke(List<OpsGenieNotif> cases) {
		for (OpsGenieNotif c : cases) {
			//make sure to turn everything into a string if it isn't already
			Map<String, String> payload = new Map<string, string>{
				'priority' => c.priority,
				'subject' => c.subject,
				'description' => c.description
			};

			OpsGenieCallout.post(JSON.serialize(payload));
		}
	}

	public class OpsGenieNotif {
		@invocableVariable
		public String subject;
		@invocableVariable
		public String description;
		@invocableVariable
		public String priority;
	}
}