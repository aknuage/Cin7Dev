@isTest
public class ReplaceTextInvocableTest {

    @isTest
    public static void testConvertToHtml() {
        // Create test data
        List<String> inputTextList = new List<String>();
        inputTextList.add('Hello, World!');
        inputTextList.add('This is a\nmulti-line\rtext.');

        // Call the invocable method
        List<String> result = ReplaceTextInvocable.convertToHtml(inputTextList);

        // Verify the results
        System.assertEquals(2, result.size());
        System.assertEquals('Hello, World!', result[0]);
        System.assertEquals('This is a<br/>multi-line<br/>text.', result[1]);
    }

    @isTest
    public static void testConvertToHtmlWithBlankText() {
        // Create test data with blank text
        List<String> inputTextList = new List<String>();
        inputTextList.add('');
        inputTextList.add(null);

        // Call the invocable method
        List<String> result = ReplaceTextInvocable.convertToHtml(inputTextList);

        // Verify the results
        System.assertEquals(2, result.size());
        System.assertEquals('', result[0]);
        System.assertEquals(null, result[1]);
    }
}