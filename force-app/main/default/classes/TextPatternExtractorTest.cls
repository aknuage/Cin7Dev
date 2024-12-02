@isTest
public class TextPatternExtractorTest {
    @isTest
    static void testIntRefExtraction() {
        List<TextPatternExtractor.TextPatternRequest> requests = new List<TextPatternExtractor.TextPatternRequest>();
        
        TextPatternExtractor.TextPatternRequest request = new TextPatternExtractor.TextPatternRequest();
        request.inputText = 'Testing back to SF ... int_ref: 108101 ...';
        request.pattern = 'int_ref: ([0-9]+)';
        requests.add(request);
        
        List<TextPatternExtractor.TextPatternResult> results = TextPatternExtractor.extractTextPattern(requests);
        System.assertEquals(1, results.size());
        System.assertEquals('108101', results[0].matchedText);
    }
}