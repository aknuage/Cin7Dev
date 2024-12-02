public class TextPatternExtractor {
    @InvocableMethod(label='Extract Text Pattern' description='Extracts text using a regular expression pattern')
    public static List<TextPatternResult> extractTextPattern(List<TextPatternRequest> requests) {
        List<TextPatternResult> results = new List<TextPatternResult>();
        
        for (TextPatternRequest request : requests) {
            TextPatternResult result = new TextPatternResult();
            result.inputText = request.inputText;
            
            Pattern pattern = Pattern.compile(request.pattern);
            Matcher matcher = pattern.matcher(request.inputText);
            
            if (matcher.find()) {
                result.matchedText = matcher.group(1);
            } else {
                result.matchedText = null;
            }
            
            results.add(result);
        }
        
        return results;
    }
    
    public class TextPatternRequest {
        @InvocableVariable(required=true)
        public String inputText;
        
        @InvocableVariable(required=true)
        public String pattern;
    }
    
    public class TextPatternResult {
        @InvocableVariable
        public String inputText;
        
        @InvocableVariable
        public String matchedText;
    }
}