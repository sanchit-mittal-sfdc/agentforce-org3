public with sharing class ContactTriggerHandler {
  public static void handleAfterInsert(Map<Id, Contact> newMap) {
    Set<Id> setOfAffectedAccountIds = new Set<Id>();

    for (Contact c : newMap.values()) {
      if (c.AccountId != null) {
        setOfAffectedAccountIds.add(c.AccountId);
      }
    }

    if (setOfAffectedAccountIds.size() > 0) {
      queryAndUpdateChildContactsCount(setOfAffectedAccountIds);
    }
  }

  public static void handleAfterUpdate(
    Map<Id, Contact> newMap,
    Map<Id, Contact> oldMap
  ) {
    Set<Id> setOfAffectedAccountIds = new Set<Id>();

    for (Contact c : newMap.values()) {
      if (c.AccountId != oldMap.get(c.Id).AccountId) {
        if (c.AccountId != null) {
          setOfAffectedAccountIds.add(c.AccountId);
        }

        if (oldMap.get(c.Id).AccountId != null) {
          setOfAffectedAccountIds.add(oldMap.get(c.Id).AccountId);
        }
      }
    }

    if (setOfAffectedAccountIds.size() > 0) {
      queryAndUpdateChildContactsCount(setOfAffectedAccountIds);
    }
  }

  public static void handleAfterDelete(Map<Id, Contact> oldMap) {
    Set<Id> setOfAffectedAccountIds = new Set<Id>();

    for (Contact c : oldMap.values()) {
      if (c.AccountId != null) {
        setOfAffectedAccountIds.add(c.AccountId);
      }
    }

    if (setOfAffectedAccountIds.size() > 0) {
      queryAndUpdateChildContactsCount(setOfAffectedAccountIds);
    }
  }

  public static void handleAfterUndelete(Map<Id, Contact> newMap) {
    Set<Id> setOfAffectedAccountIds = new Set<Id>();

    for (Contact c : newMap.values()) {
      if (c.AccountId != null) {
        setOfAffectedAccountIds.add(c.AccountId);
      }
    }

    if (setOfAffectedAccountIds.size() > 0) {
      queryAndUpdateChildContactsCount(setOfAffectedAccountIds);
    }
  }

  public static void queryAndUpdateChildContactsCount(
    Set<Id> setOfAffectedAccountIds
  ) {
    if (setOfAffectedAccountIds.size() != 0) {
      //List<Account> accountsToUpdate = new List<Account>();
      Map<Id, Integer> mapAccIdToConCount = new Map<Id, Integer>();

      for (Id eachAccId : setOfAffectedAccountIds) {
        mapAccIdToConCount.put(eachAccId, 0);
      }

      for (Contact c : [
        SELECT Id, AccountId
        FROM Contact
        WHERE AccountId IN :setOfAffectedAccountIds
      ]) {
        if (mapAccIdToConCount.containsKey(c.AccountId)) {
          mapAccIdToConCount.put(
            c.AccountId,
            mapAccIdToConCount.get(c.AccountId) + 1
          );
        }
      }

      if (mapAccIdToConCount.size() > 0) {
        List<Account> accountsToUpdate = new List<Account>();

        for (Id accId : mapAccIdToConCount.keySet()) {
          accountsToUpdate.add(
            new Account(
              Id = accId,
              Number_Of_Child_Contacts__c = mapAccIdToConCount.get(accId)
            )
          );
        }

        if (accountsToUpdate.size() > 0) {
          update accountsToUpdate;
        }
      }
    }
  }
}
