public class ReplaceTextInvocable {
    @InvocableMethod
    public static List<String> convertToHtml(List<String> inputTextList) {
        List<String> result = new List<String>();

        for (String inputText : inputTextList) {
            if (String.isNotBlank(inputText)) {
                // Replace line breaks with HTML line breaks
                String htmlText = inputText.replaceAll('(\n|\r\n|\r)', '<br/>');
                result.add(htmlText);
            } else {
                result.add(inputText);
            }
        }

        return result;
    }
}