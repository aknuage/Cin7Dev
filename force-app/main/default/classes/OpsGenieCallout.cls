public class OpsGenieCallout {
	@future(callout=true)
	public static void post(String payload) {
		string endpoint;
		if (test.isrunningtest()) {
			endpoint = '';
		} else {
			endpoint = OpsGenieSetting__c.getOrgDefaults().url__c;
		}
		HttpRequest req = new HttpRequest();
		req.setEndpoint(endpoint);
		req.setMethod('POST');
		req.setBody(payload);
		req.setHeader('Content-Type', 'application/json');
		Http http = new Http();
		HTTPResponse res = http.send(req);
		System.debug(' Response: ' + res.getBody());
	}
}