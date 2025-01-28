public class ContactAccountWrapper {
    @InvocableVariable(label='Contact Id' description='The Id of the Contact')
    public Id contactId;

    @InvocableVariable(label='Account Id' description='The Id of the Account related to the Contact')
    public Id accountId;

    // Constructor to initialize ContactId and AccountId
    public ContactAccountWrapper(Id contactId, Id accountId) {
        this.contactId = contactId;
        this.accountId = accountId;
    }
}
