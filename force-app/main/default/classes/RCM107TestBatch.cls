public with sharing class RCM107TestBatch implements Database.Batchable<Account>, Database.Stateful
{
    Contact c1;
    Contact c2;

    public List<Account> start(Database.BatchableContext bc) 
    {
        return [Select id from Account where id = '0019j00000atSheAAE'];
    }

    public void execute(Database.BatchableContext bc, List<Account> accounts)
    {    
        Account a = accounts[0];

        c1 = new Contact(FirstName = 'Testy5', LastName = 'McTesterson', Email='testy5@email.com', AccountId = a.Id);
        c2 = new Contact(FirstName = 'Testy6', LastName = 'McTesterson', Email='testy6@email.com', AccountId = a.Id);

    }

    public void finish(Database.BatchableContext bc)
    {
        insert new list<Contact> {c1, c2};
    }
}