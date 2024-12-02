@istest
public with sharing class OpsGenieCalloutMock implements HttpCalloutmock {
	public HTTPResponse respond(HTTPRequest req) {
		map<string, Object> reqBody = (map<string, Object>) JSON.deserializeUntyped(req.getBody());

		System.assertEquals('Escalated', (String) reqbody.get('priority'));
		System.assertEquals('subject', (String) reqbody.get('subject'));
		System.assertEquals('Description', (String) reqbody.get('description'));

		HttpResponse res = new HttpResponse();
		res.setHeader('Content-Type', 'application/json');
		res.setBody('{"example": "test"}');
		res.setStatusCode(200);
		return res;
	}
}