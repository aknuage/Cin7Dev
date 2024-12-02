@isTest
private class PreChatValuesControllerTest {

    @isTest
    static void testFetchUserDetails() {
        // Create a new user
        User testUser = new User(
            FirstName = 'John',
            LastName = 'Doe',
            Username = 'john.doe@test123.com',
            Email = 'john.doe@test.com',
            Phone = '555-555-5555',
            Alias = 'jdoe',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = UserInfo.getProfileId()
        );
        insert testUser;

        // Set the current user to the test user
        System.runAs(testUser) {
            // Call the fetchUserDetails method
            User result = PreChatValuesController.fetchUserDetails();

            // Verify that the returned user details are correct
            System.assertEquals(testUser.Id, result.Id);
            System.assertEquals(testUser.FirstName, result.FirstName);
            System.assertEquals(testUser.LastName, result.LastName);
            System.assertEquals(testUser.Email, result.Email);
            System.assertEquals(testUser.Phone, result.Phone);
            System.assertEquals(testUser.Account.Name, result.Account.Name);
        }
    }
}