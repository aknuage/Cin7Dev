({
    doInit: function (component, event, helper) { 
        
        var columns = [
            {
                type: 'url',
                fieldName: 'AccountURL',
                label: 'Account Name',
                typeAttributes: {
                    label: { fieldName: 'accountName' }
                }
            },
            {
                type: 'currency',
                fieldName: 'Cin7_MRR__c',
                label: 'Cin7 MRR'
            }            
        ];
        component.set('v.gridColumns', columns);
                
        var trecid = component.get('v.recordId');
        //helper.getAccountDetail(component,event,helper,trecid);
        if(trecid){
            
            helper.callToServer(component,
                "c.findHierarchyData",
                function(response) {
                    var expandedRows = [];
                    var apexResponse = response;
                    let totalAmount=0;
                    var roles = {};
                    var results = apexResponse;
                    var nameAcc;
                    roles[undefined] = { Name: "Root", _children: [] };
                    var accName = component.get('v.accountName');
                    apexResponse.forEach(function(v) {
                        expandedRows.push(v.Id);
                        roles[v.Id] = {                             
                            accountName: v.Name ,
                            name: v.Id, 
                            Cin7_MRR__c:v.Cin7_MRR__c,
                            AccountURL:'/'+v.Id,
                            _children: [] };
                            totalAmount+=v.Cin7_MRR__c;
                    });
                    apexResponse.forEach(function(v) {
                        roles[v.ParentId]._children.push(roles[v.Id]);   
                    });                
                    component.set("v.gridData", roles[undefined]._children);
                    component.set('v.totalAmount', totalAmount);
                    component.set('v.gridExpandedRows', expandedRows);
                }, 
                {
                    recId: component.get('v.recordId')
                }
            );    
        }
        
        
        
        
    }
})