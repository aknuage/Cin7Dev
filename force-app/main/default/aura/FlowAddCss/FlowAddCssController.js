({
	init : function(component, event, helper) {
        
		//Inject CSS
        var CSSToAdd = component.get("v.CSSToAdd");
        
        let CSSstyle='<style>';
        CSSstyle+= CSSToAdd;
        CSSstyle+='</style>';
        
        component.set("v.CSSToAdd",CSSstyle);
        
        
        
        
        //------Show display on certain screens -----//
        var url = window.location.href;
        console.log('CSSToAdd_page_url:'+url);
        var ShowCSSHelp = false;
        
        //When to show
        if( url.indexOf(".builder.salesforce") > -1 ) {ShowCSSHelp=true; }
        if( url.indexOf(".livepreview.salesforce") > -1 ) {ShowCSSHelp=true; }
        if( url.indexOf(".com/flexipageEditor/") > -1 ) {ShowCSSHelp=true;}
        
        //Show
        component.set("v.ShowCSSHelp",ShowCSSHelp);
        
        //Format 
        var CSSToAdd_formated = CSSstyle;

        let searchRegExp = new RegExp("{", 'g');
        CSSToAdd_formated = CSSToAdd_formated.replace(searchRegExp, '&nbsp;{ ');
        
        searchRegExp = new RegExp("<", 'g');
       // CSSToAdd_formated = CSSToAdd_formated.replace(searchRegExp, '&#x3C;');
        
        searchRegExp = new RegExp(">", 'g');
        CSSToAdd_formated = CSSToAdd_formated.replace(searchRegExp, '&#x3E; <br/>');
        
        searchRegExp = new RegExp("}", 'g');
        CSSToAdd_formated = CSSToAdd_formated.replace(searchRegExp, '}<br/><br/>');
        
        searchRegExp = new RegExp(";", 'g');
        CSSToAdd_formated = CSSToAdd_formated.replace(searchRegExp, ';<br/> &nbsp;&nbsp;&nbsp;&nbsp;');
        
        component.set("v.CSSToAdd_formated",CSSToAdd_formated);
        
        
        

	}
})