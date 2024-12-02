@isTest
private class loginErrorCaseFormTest {
    
    @isTest
    static void testVerifyCaptchaResponseV2() {
        Test.setMock(HttpCalloutMock.class, new loginErrorCaseFormTest.GoogleHTTPCalloutMock('{"success": true}', 200));
        Test.startTest();
        System.assertEquals('Success - v2', loginErrorCaseForm.verifyCaptchaResponse('response'));
        Test.stopTest();
  	}
    
    @isTest
    static void testVerifyCaptchaResponseV3() {
        Test.setMock(HttpCalloutMock.class, new loginErrorCaseFormTest.GoogleHTTPCalloutMock('{"success": true, "score": 0.5}', 200));
        Test.startTest();
        System.assertEquals('Success - v3', loginErrorCaseForm.verifyCaptchaResponse('response'));
        Test.stopTest();
  	}
    
    @isTest
    static void testVerifyCaptchaResponseNoSuccess() {
        Test.setMock(HttpCalloutMock.class, new loginErrorCaseFormTest.GoogleHTTPCalloutMock('{"success": false}', 200));
        Test.startTest();
        System.assertEquals('Invalid Verification', loginErrorCaseForm.verifyCaptchaResponse('response'));
        Test.stopTest();
  	}
 
    @isTest
    static void testVerifyCaptchaResponse404() {
        Test.setMock(HttpCalloutMock.class, new loginErrorCaseFormTest.GoogleHTTPCalloutMock('{"success": false}', 404));
        Test.startTest();
        System.assertEquals('Invalid Verification Request', loginErrorCaseForm.verifyCaptchaResponse('response'));
        Test.stopTest();
  	}
    
    @isTest
    static void testInsertCaseBlankFields() {
        
        String outputTest = loginErrorCaseForm.insertCase('Success - v2', '', '', '', '', '');
        System.assertEquals('Blank Fields', outputTest);

    }

    @isTest
    static void testInsertCaseSuccess() {
        
        Test.startTest();
        String outputTest = loginErrorCaseForm.insertCase('Success - v2', 'MicadoName', 'MicadoCompany', 'MicadoSubject', 'MicadoDescription', 'micado@micado.ai');
        System.assertEquals('Success', outputTest);
        Case testCase = [SELECT Id, suppliedName, suppliedCompany, subject, description, suppliedEmail FROM Case LIMIT 1];
        System.assertEquals('micado@micado.ai', testCase.SuppliedEmail);
        System.assertEquals('MicadoCompany', testCase.SuppliedCompany);
        System.assertEquals('MicadoName', testCase.SuppliedName);
        //System.assertEquals('MicadoSubject', testCase.Subject);
        System.assertEquals('MicadoDescription', testCase.Description);
		Test.stopTest();
        
    }

  public class GoogleHTTPCalloutMock implements HttpCalloutMock {
    private String responseBody;
    private Integer statusCode; 
      
    public GoogleHTTPCalloutMock(String responseBody, Integer statusCode) {
          this.responseBody = responseBody;
          this.statusCode = statusCode;
      }
    // Implement this interface method
    public HTTPResponse respond(HTTPRequest req) {
      // Create a fake response
      HttpResponse res = new HttpResponse();
      res.setHeader('Content-Type', 'application/json');
      res.setBody(this.responseBody);
      res.setStatusCode(this.statusCode);
      return res;
    }
  }
        
}