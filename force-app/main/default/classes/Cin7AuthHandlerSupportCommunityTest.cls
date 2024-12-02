@isTest
private class Cin7AuthHandlerSupportCommunityTest {
  @isTest
  static void testNewUserNoContactId() {
    Cin7AuthHandlerSupportCommunity handler = new Cin7AuthHandlerSupportCommunity();
    list<UserRole> portalRoles = [
      SELECT Id
      FROM UserRole
      WHERE PortalType = 'None'
    ];
    User usr = [
      SELECT Id, UserRoleId
      FROM User
      WHERE
        UserRoleId IN :new Map<id, Userrole>(portalRoles).keyset()
        AND IsActive = TRUE
      LIMIT 1
    ];
    test.startTest();
    System.runAs(usr) {
      Auth.UserData sampleData = new Auth.UserData(
        'testId',
        'testFirst',
        'testLast',
        'testFirst testLast',
        'testuse7777rb@example.org',
        null,
        'testuserlong1@example.org',
        'en_US',
        'facebook',
        null,
        new Map<String, String>{
          'language' => 'en_US',
          'locale' => 'en-US',
          'zoneinfo' => 'America/Los_Angeles',
          'salesforce_account_id' => 'test',
          'salesforce_contact_id' => 'test'
        }
      );
      try {
        User u = handler.createUser(null, sampleData);
      } catch (Exception e) {
        Assert.fail();
      }

      test.stopTest();
    }

  }

  @isTest
  static void testNewUserWithContactId() {
    Cin7AuthHandlerSupportCommunity handler = new Cin7AuthHandlerSupportCommunity();

    list<UserRole> portalRoles = [
      SELECT Id
      FROM UserRole
      WHERE PortalType = 'None'
    ];
    User usr = [
      SELECT Id, UserRoleId
      FROM User
      WHERE
        UserRoleId IN :new Map<id, Userrole>(portalRoles).keyset()
        AND IsActive = TRUE
      LIMIT 1
    ];
    System.runAs(usr) {
      Contact newContact = new Contact();
      newContact.FirstName = 'Joe';
      newContact.LastName = 'Doe';
      newContact.Email = 'testuse8888rb@example.org';
      insert newContact;

      Auth.UserData sampleData = new Auth.UserData(
        'testId',
        'testFirst',
        'testLast',
        'testFirst testLast',
        'testuse8888rb@example.org',
        null,
        'testuserlong2@example.org',
        'en_US',
        'facebook',
        null,
        new Map<String, String>{
          'language' => 'en_US',
          'locale' => 'en-US',
          'zoneinfo' => 'America/Los_Angeles',
          'salesforce_account_id' => 'test',
          'salesforce_contact_id' => String.valueOf(newContact.Id)
        }
      );
      try {
        User u = handler.createUser(null, sampleData);
      } catch (Exception e) {
        Assert.fail();
      }
    }

  }

  @isTest
  static void testNewAccount() {
    Cin7AuthHandlerSupportCommunity handler = new Cin7AuthHandlerSupportCommunity();

    list<UserRole> portalRoles = [
      SELECT Id
      FROM UserRole
      WHERE PortalType = 'None'
    ];
    User usr = [
      SELECT Id, UserRoleId
      FROM User
      WHERE
        UserRoleId IN :new Map<id, Userrole>(portalRoles).keyset()
        AND IsActive = TRUE
      LIMIT 1
    ];
    System.runAs(usr) {
      Account newAccount = new Account(Name = 'test');
      insert newAccount;

      Auth.UserData sampleData = new Auth.UserData(
        'testId',
        'testFirst',
        'testLast',
        'testFirst testLast',
        'testuse9999rb@example.org',
        null,
        'testuserlong3@example.org',
        'en_US',
        'facebook',
        null,
        new Map<String, String>{
          'language' => 'en_US',
          'locale' => 'en-US',
          'zoneinfo' => 'America/Los_Angeles',
          'salesforce_account_id' => String.valueOf(newAccount.Id),
          'salesforce_contact_id' => 'test'
        }
      );
      try {
        User u = handler.createUser(null, sampleData);
      } catch (Exception e) {
        Assert.fail();
      }
    }

  }
}