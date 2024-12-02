/**
 * @description       : 
 * @author            : AS | NuAge Experts
 * @group             : 
 * @last modified on  : 03-21-2023
 * @last modified by  : AS | NuAge Experts
**/
public with sharing class LeadTriggerJSONParse {
    public Data Data;
	public String StatusCode;
	public List<String> Errors;

	public class Data {
		public String TenantID;
		public String RequestID;
	}

	public static LeadTriggerJSONParse parse(String json) {
		return (LeadTriggerJSONParse) System.JSON.deserialize(json, LeadTriggerJSONParse.class);
	}
}