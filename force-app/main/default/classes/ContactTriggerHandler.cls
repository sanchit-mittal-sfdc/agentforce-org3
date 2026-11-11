public with sharing class ContactTriggerHandler {
  public static void handleAfterInsert(Map<Id, Contact> newMap) {
    Map<Id, Integer> mapAccIdToNewInsertedContactsCount = new Map<Id, Integer>();

    for (Contact c : newMap.values()) {
      if (c.AccountId != null) {
        if (mapAccIdToNewInsertedContactsCount.containsKey(c.AccountId)) {
          mapAccIdToNewInsertedContactsCount.put(
            c.AccountId,
            mapAccIdToNewInsertedContactsCount.get(c.AccountId) + 1
          );
        } else {
          mapAccIdToNewInsertedContactsCount.put(c.AccountId, 1);
        }
      }
    }

    if (mapAccIdToNewInsertedContactsCount.size() != 0) {
      List<Account> accountsToUpdate = new List<Account>();

      for (Account a : [
        SELECT Id, Number_Of_Child_Contacts__c
        FROM Account
        WHERE Id IN :mapAccIdToNewInsertedContactsCount.keySet()
      ]) {
        if (a.Number_Of_Child_Contacts__c != null) {
          a.Number_Of_Child_Contacts__c =
            a.Number_Of_Child_Contacts__c +
            mapAccIdToNewInsertedContactsCount.get(a.Id);
        } else {
          a.Number_Of_Child_Contacts__c = mapAccIdToNewInsertedContactsCount.get(
            a.Id
          );
        }

        accountsToUpdate.add(a);
      }

      if (accountsToUpdate.size() > 0) {
        update accountsToUpdate;
      }
    }
  }

  public static void handleAfterUpdate(
    Map<Id, Contact> newMap,
    Map<Id, Contact> oldMap
  ) {
  }

  public static void handleAfterDelete(Map<Id, Contact> oldMap) {
  }

  public static void handleAfterUndelete(Map<Id, Contact> newMap) {
  }
}
