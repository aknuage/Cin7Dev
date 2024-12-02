/* Methods to update data in GuideCX
 * Micado 2022
 * 
 * Change Log
 * 20/6/22 Updated Line 38 - Changed PM details to Cyran
 * 21/6/22 Commenting out PM details to force project to move across in 'pending status'
 * 30/6/22 Added the apex class used in record trigger to update custom fields when status changes from pending to something else, further clean up
 * 12/07/22 Refined the add/update methods and added adding fields to notes field in GuideCX method
*/
global class GuideCXProjectUpsert implements beynd.GuideCXProjectConversion{
    
    global beynd.GuideCXProject projectDetails(String id){
		Opportunity opp = getOppData(id);

        beynd.GuideCXProject project  = new beynd.GuideCXProject();
        project.Name = opp.Name.left(80).trim();
        project.CashValue = opp.Amount;
        project.StartDate = opp.CloseDate;
        project.CustomerName = opp.Account != null ? opp.Account.Name : 'example';
        //Handle opportunities that may not have an account or account website
        project.CustomerWebsite = opp.Account?.Website != null ? opp.Account?.Website : 'example.com';

        //Custom fields will only transfer to GuideCX if a project skips pending and goes straight to active.
        //To bypass the pending stage, a project requires a Project Name, Project Manager, and Company Domain Name
        //Set the Project Manager field
        //Hard coding this field to test class. Logic to assign PM to come later
        //project.setProjectManager('Cyran', 'Castelino', 'cyran.castelino@cin7.com');

        // Handle custom fields (won't be populated if status is pending)
        project.CustomFields = getCustomFieldsMap();

        return project;        
    }

    global void linkProjects(Map<Id, Id> sourceProjectMap) {
        List<Opportunity> opportunities = new List<Opportunity>();
    	
        try {
            for (Id source : sourceProjectMap.keySet()) {
              opportunities.add(new Opportunity (
                Id = source,
                beynd__BeyndProject__c = sourceProjectMap.get(source)
              ));
            }
        
            update opportunities;            
        } catch(Exception e) {
            System.debug('The following exception has occurred: ' + e.getMessage());
        }

    }
    
    @InvocableMethod(label='Update GuideCX' description='Updating GuideCX custom fields once project becomes active. Enter the action type (upsert, instert, update) for updating custom fields and the SF project record Id. Add the method (Notes, Fields or All) - if Notes is selected the action Type is ignored.')
    public static void updateGuideCX(List<GuideCXProjectUpsertVar> varList) {
        GuideCXProjectUpsertVar varRecord = varList[0];
        if (varRecord.method == 'All' || varRecord.method == 'Fields') {
            updateGuideCXFuture(varRecord.salesforceId, varRecord.actionType);
        }
        if (varRecord.method == 'All' || varRecord.method == 'Notes') {
            updateGuideCXNotesFuture(varRecord.salesforceId);
        }        
    }

    @future(callout=true)
    private static void updateGuideCXFuture(Id salesforceId, String actionType) {
		updateGuideCXNonFuture(salesforceId, actionType);
    }
    
    @TestVisible
    private static Integer updateGuideCXNonFuture(Id salesforceId, String actionType) {
        // set the bearer token from GuideCX
        Map<String, String> configMap = getGuideCXConfig();
        Map<String,String> CustomFields = getCustomFieldsMap();
        String token = configMap.get('GuideCX Token');
        
        try {
            //get the opp data via the GuideCX project record in SF
            beynd__BeyndProject__c project = [Select Id,
                                             beynd__BeyndProjectURL__c,
                                             beynd__ProjectStatus__c,
                                             beynd__Source_Object__c
                                             FROM beynd__BeyndProject__c
                                             WHERE Id = :salesforceId
                                             ];
            Opportunity opp = getOppData(project.beynd__Source_Object__c);

            // Grab the GuideCX project ID from the project URL
            String projectId = project.beynd__BeyndProjectURL__c.replace('https://app.guidecx.com/app/projects/','');

            Map<String, String> projectCustomFields = getProjectCustomFields(projectId, token);
            Map<String, String> addFieldList = new Map<String, String>();
            if (projectCustomFields.size() > 0) {
                for(String fieldKey: CustomFields.keySet()) {
                    if( !( projectCustomFields.values().contains(CustomFields.get(fieldKey)) ) ) {
                        addFieldList.put(fieldkey, CustomFields.get(fieldKey));
                    }
                }           
            } else {
               addFieldList = CustomFields;
            }
            
            if( (actionType == 'update' || actionType == 'upsert') && projectCustomFields.size() > 0) {
                updateCustomFields(projectId, token, projectCustomFields, opp);
            }
            if( (actionType == 'insert' || actionType == 'upsert') && addFieldList.size() > 0) {
                addCustomFields(projectId, token, addFieldList, opp);
            }
     
            return 0;
        } catch(Exception e) {
            System.debug('The following exception has occurred: ' + e.getMessage());
            return -1;
        }
    }
    
    @TestVisible
    private static Opportunity getOppData(String salesforceId) {
        
        try {
            Map<String, String> customFields = getCustomFieldsMap();
            Map<String, String> notesFields = getNotesFieldsMap();

            String queryText = 'SELECT Id, Name, Amount, CloseDate, Account.Name, Account.Website';
            for (String idKey : customFields.keySet()){
				queryText = queryText + ', ' + customFields.get(idKey);                
            }
            for (String fieldName : notesFields.keySet()){
				queryText = queryText + ', ' + fieldName;                
            }
            queryText = queryText + ' FROM Opportunity WHERE Id = :salesforceId';
            List<Opportunity> opp = Database.query(queryText);
            system.debug(queryText);
            system.debug(opp[0]);
            return opp[0];
        } catch(Exception e) {
            System.debug('The following exception has occurred: ' + e.getMessage());
        }
        return null;
    }    
    
    @TestVisible
    private static Map<String, String> getCustomFieldsMap() {
        // Creating a map of custom field GuideCX Ids and the corresponding opportunity field API name
        Map<String,String> CustomFields = new Map<String, String>();
        List<GuideCXConfigMapping__mdt> mappings = [SELECT Id, Label, Type__c, GuideCX_Id__c, API_Name__c  from GuideCXConfigMapping__mdt WHERE Type__c = 'Mapping'];

        for (GuideCXConfigMapping__mdt mappingsRecord: mappings) {
            CustomFields.put(mappingsRecord.GuideCX_Id__c, mappingsRecord.API_Name__c);
        }     
        return CustomFields;
    }
    
    @TestVisible
    private static Map<String, String> getNotesFieldsMap() {
        // Creating a map of custom field GuideCX Ids and the corresponding opportunity field API name
        Map<String,String> CustomFields = new Map<String, String>();
        String type='Opportunity';

        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Schema.SObjectType leadSchema = schemaMap.get(type);
        Map<String, Schema.SObjectField> fieldMap = leadSchema.getDescribe().fields.getMap();
        
        List<GuideCXConfigMapping__mdt> mappings = [SELECT Id, Label, Type__c, GuideCX_Id__c, API_Name__c  from GuideCXConfigMapping__mdt WHERE Type__c = 'Notes'];

        for (GuideCXConfigMapping__mdt mappingsRecord: mappings) {
            CustomFields.put(mappingsRecord.API_Name__c, String.valueOf(fieldMap.get(mappingsRecord.API_Name__c).getDescribe().getLabel()));
        }
        return CustomFields;
    }

    @TestVisible    
    private static Map<String, String> getProjectCustomFieldsMap() {
        // Creating a map of custom field GuideCX Names and the corresponding opportunity field API name
        Map<String,String> CustomFields = new Map<String, String>();
        List<GuideCXConfigMapping__mdt> mappings = [SELECT Id, Label, Type__c, GuideCX_Id__c, API_Name__c  from GuideCXConfigMapping__mdt WHERE Type__c = 'Mapping'];

        for (GuideCXConfigMapping__mdt mappingsRecord: mappings) {
            CustomFields.put(mappingsRecord.Label, mappingsRecord.API_Name__c);
        }      
        return CustomFields;
    }
    
    @TestVisible    
    private static Map<String, String> getGuideCXConfig() {
        Map<String,String> CustomFields = new Map<String, String>();
        
        List<GuideCXConfigMapping__mdt> mappings = [SELECT Id, Label, Type__c, GuideCX_Id__c, API_Name__c  from GuideCXConfigMapping__mdt WHERE Type__c = 'Config'];

        for (GuideCXConfigMapping__mdt mappingsRecord: mappings) {
            CustomFields.put(mappingsRecord.Label, mappingsRecord.GuideCX_Id__c);
        }
  
        return CustomFields;
    }
    
    @TestVisible
    private static Map<String, String> getProjectCustomFields(String projectId, string token) {
        try {
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint('https://api.guidecx.com/api/v1/projects/' + projectId);
            request.setMethod('GET');
            request.setHeader('Authorization', 'Bearer ' + token); 
            HttpResponse response = http.send(request);	
            Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            
            if(response.getStatusCode() == 200) {
                String fieldListJson = JSON.serialize(results.get('customFields'));
                List<wrapperClass> fieldList = (List<wrapperClass>) JSON.deserialize(fieldListJson, List<wrapperClass>.class);
                
                Map<String, String> projectCustomFieldsMap = getProjectCustomFieldsMap();
                Map<String, String> fieldMap = new Map<String, String>();  
                for (wrapperClass fieldRecord: fieldList) {
                    fieldMap.put(fieldRecord.id, projectCustomFieldsMap.get(fieldRecord.name));
                }
                return fieldMap;
            } else {
                system.debug('Error loading project details: ' + results.get('error'));
            } 
        } catch(Exception e) {
            System.debug('The following exception has occurred: ' + e.getMessage());
        }
        return null;
    }
    
    @TestVisible
    private static Map<String, Integer> addCustomFields(String projectId, String token, Map<String, String> CustomFields, Opportunity opp) {
        Map<String, Integer> statusCodes = new Map<String, Integer>();
        
        try {
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint('https://api.guidecx.com/api/v1/projects/' + projectId + '/custom-fields');
            request.setMethod('POST');
            request.setHeader('Authorization', 'Bearer ' + token);    
            request.setHeader('Content-Type', 'application/json;charset=UTF-8');
            
            String payload = '';
            String fieldValue = '';
            // loop over the custom fields and create the payload
            for(String fieldKey: CustomFields.keySet()) {
                fieldValue = String.valueOf(opp.get(CustomFields.get(fieldKey)));
                payload = '{"customFieldId": "' + fieldKey + '", "value": "' + fieldValue + '"}';

                // Set the body of the request
                request.setBody(payload);
                // Make the call out
                HttpResponse response = http.send(request);      
                // getting response from callout for error checking - WIP
                Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
    
                if(response.getStatusCode() == 200) {
                    //system.debug(CustomFields.get(fieldKey) + ': added');
                } else {
                    system.debug('Error adding: ' + CustomFields.get(fieldKey) + ' - ' + results.get('error'));
                }
                statusCodes.put(CustomFields.get(fieldKey), response.getStatusCode() );
            }
        } catch(Exception e) {
            System.debug('The following exception has occurred: ' + e.getMessage());
            return statusCodes;
        }
        return statusCodes;
    }
	
    @TestVisible
    private static Integer updateCustomFields(String projectId, String token, Map<String, String> CustomFields, Opportunity opp) {
        if (CustomFields.size() > 0) {
            
            try {
                Http http = new Http();
                HTTPRequest request = new HttpRequest();
                request.setMethod('PATCH');
                request.setEndpoint('https://api.guidecx.com/api/v1/projects/' + projectId);
                request.setHeader('Authorization', 'Bearer ' + token);
                request.setHeader('Content-Type', 'application/json;charset=UTF-8');
                
                String fieldValue = '';
                String payload = '{"customFields": [';
                for(String fieldKey: CustomFields.keySet()) {
                    fieldValue = String.valueOf(opp.get(CustomFields.get(fieldKey))); 
                    payload = payload + '{"customFieldId": "' + fieldKey + '", "value": "' + fieldValue + '"},';
                }
                payload = payload.removeEnd(',') + ']}';
                
                // Set the body of the request
                request.setBody(payload);
                // Make the call out
                HttpResponse response = http.send(request);
                Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                
                if(response.getStatusCode() == 200) {
                    //system.debug('Fields updated:' + results);
                } else {
                    system.debug('Error updating fields: ' + results.get('error'));	
                }
                return response.getStatusCode();
            } catch(Exception e) {
                System.debug('The following exception has occurred: ' + e.getMessage());
            }
         }
         return 0;
    }


    @future(callout=true)
    private static void updateGuideCXNotesFuture(Id salesforceId) {
		updateGuideCXNotesNonFuture(salesforceId);
    }
    
    @TestVisible
    private static Integer updateGuideCXNotesNonFuture(Id salesforceId) { // updating the notes field in GuideCX
        // set the bearer token from GuideCX
        Map<String,String> CustomFields = getNotesFieldsMap(); // getting the fields we want to bring to GuideCX
        	
        if (CustomFields.size() > 0) {
            Map<String, String> configMap = getGuideCXConfig();
            String token = configMap.get('GuideCX Token');

            try {
                //get the opp data via the GuideCX project record in SF
                beynd__BeyndProject__c project = [Select Id,
                                                 beynd__BeyndProjectURL__c,
                                                 beynd__ProjectStatus__c,
                                                 beynd__Source_Object__c
                                                 FROM beynd__BeyndProject__c
                                                 WHERE Id = :salesforceId
                                                 ];
                Opportunity opp = getOppData(project.beynd__Source_Object__c);
    
                // Grab the GuideCX project ID from the project URL
                String projectId = project.beynd__BeyndProjectURL__c.replace('https://app.guidecx.com/app/projects/','');
                
                Http http = new Http();
                HTTPRequest request = new HttpRequest();
                request.setMethod('POST');
                request.setEndpoint('https://api.guidecx.com/api/v1/projects/' + projectId + '/notes');
                request.setHeader('Authorization', 'Bearer ' + token);
                request.setHeader('Content-Type', 'application/json;charset=UTF-8');
                
                String fieldValue = '';
                String fieldLabel = '';
                String payload = '{"text": "Additonal Information:\\n\\n';
                for(String fieldKey: CustomFields.keySet()) {
                    fieldlabel = String.valueOf(CustomFields.get(fieldKey));
                    fieldValue = String.valueOf(opp.get(fieldKey));
                    payload = payload + fieldLabel + ': ' + fieldValue + '\\n';
                }
                payload = payload + '"}';
                
                // Set the body of the request
                request.setBody(payload);
                // Make the call out
                HttpResponse response = http.send(request);
                Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                
                if(response.getStatusCode() == 200) {
                    //system.debug('Fields updated:' + results);
                } else {
                    system.debug('Error updating fields: ' + results.get('error'));	
                }
                return response.getStatusCode();
            } catch(Exception e) {
                System.debug('The following exception has occurred: ' + e.getMessage());
            }
            return 0;
        }
        return -1;
    }
    
    private class wrapperClass {
        public String id;
        public String name;
    }
    
    global class GuideCXProjectUpsertVar {
        @InvocableVariable(required=true)
        global Id salesforceId;
    
        @InvocableVariable(required=true)
        global String actionType;
        
        @InvocableVariable(required=true)
        global String method;
    }

        
}