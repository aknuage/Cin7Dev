/**
 * @description       : 
 * @author            : AK | NuAge Experts
 * @group             : 
 * @last modified on  : 01-25-2025
 * @last modified by  : AK | NuAge Experts
**/
public with sharing class TrialAcctJSONParse {
    public Data Data;
	public String StatusCode;
	public List<String> Errors;

	public class Data {
		public String TenantID;
		public String RequestID;
	}

	public static TrialAcctJSONParse parse(String json) {
		return (TrialAcctJSONParse) System.JSON.deserialize(json, TrialAcctJSONParse.class);
	}
}