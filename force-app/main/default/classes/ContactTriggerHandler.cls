/**
 * Handler class for the Contact trigger.
 *
 * PURPOSE:
 *   Keeps the Account field Number_Of_Child_Contacts__c in sync with the
 *   actual number of Contacts under that Account (roll-up count, done in Apex
 *   because Contact -> Account is a lookup, not master-detail).
 *
 * APPROACH:
 *   Instead of doing +1 / -1 math on the existing Account value (which can go
 *   out of sync), every handler method only collects the IDs of the Accounts
 *   that are "affected" by the DML. Then queryAndUpdateChildContactsCount()
 *   re-counts the Contacts from the database and overwrites the Account value.
 *   This is self-healing and works the same way for every trigger event.
 *
 * FLOW:
 *   Trigger event -> handleAfterXxx() collects affected Account Ids
 *                 -> queryAndUpdateChildContactsCount() recounts + updates Accounts
 */
public with sharing class ContactTriggerHandler {
  /**
   * AFTER INSERT
   * New Contacts were created. Every Account that got a new Contact
   * (AccountId != null) needs its count recalculated.
   */
  public static void handleAfterInsert(Map<Id, Contact> newMap) {
    // Set is used so an Account shared by many Contacts is only recounted once
    Set<Id> setOfAffectedAccountIds = new Set<Id>();

    for (Contact c : newMap.values()) {
      // Contacts without an Account (private contacts) don't affect any count
      if (c.AccountId != null) {
        setOfAffectedAccountIds.add(c.AccountId);
      }
    }

    // Skip the SOQL/DML entirely if there is nothing to recount
    if (setOfAffectedAccountIds.size() > 0) {
      queryAndUpdateChildContactsCount(setOfAffectedAccountIds);
    }
  }

  /**
   * AFTER UPDATE
   * The count only changes if the Contact is moved to a different Account,
   * i.e. the AccountId field changed. Any other field change is ignored.
   *
   * When a Contact moves from Account A -> Account B, BOTH are affected:
   *   - A (old Account) lost a Contact
   *   - B (new Account) gained a Contact
   * Also handles: null -> B (Contact attached to an Account) and
   *               A -> null (Contact detached from an Account).
   */
  public static void handleAfterUpdate(
    Map<Id, Contact> newMap,
    Map<Id, Contact> oldMap
  ) {
    Set<Id> setOfAffectedAccountIds = new Set<Id>();

    for (Contact c : newMap.values()) {
      // Only act when the parent Account actually changed
      if (c.AccountId != oldMap.get(c.Id).AccountId) {
        // New Account (gained a Contact) - skip if Contact was detached (null)
        if (c.AccountId != null) {
          setOfAffectedAccountIds.add(c.AccountId);
        }

        // Old Account (lost a Contact) - skip if Contact had no Account before
        if (oldMap.get(c.Id).AccountId != null) {
          setOfAffectedAccountIds.add(oldMap.get(c.Id).AccountId);
        }
      }
    }

    if (setOfAffectedAccountIds.size() > 0) {
      queryAndUpdateChildContactsCount(setOfAffectedAccountIds);
    }
  }

  /**
   * AFTER DELETE
   * Contacts were deleted. Trigger.new does not exist on delete, so we use
   * the old records (oldMap) to find which Accounts lost a Contact.
   * Deleted Contacts are no longer returned by the recount query, so the
   * count automatically goes down.
   */
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

  /**
   * AFTER UNDELETE
   * Contacts were restored from the Recycle Bin. They count again, so their
   * Accounts need to be recounted (same as insert).
   */
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

  /**
   * Core method: recounts child Contacts for the given Accounts and writes
   * the result to Account.Number_Of_Child_Contacts__c.
   *
   * Steps:
   *   1. Default every affected Account to a count of 0.
   *   2. Query all Contacts of those Accounts and increment the count per Account.
   *   3. Update all Accounts with their fresh count.
   *
   * WHY STEP 1 (corner case):
   *   The SOQL only returns Accounts that still have at least one Contact.
   *   If an Account lost its LAST Contact (delete, or Contact moved to another
   *   Account / set to null), it would not appear in the query result at all and
   *   its old count would stay stale. Pre-filling 0 for every affected Account
   *   guarantees such Accounts get updated to 0.
   *   e.g. Account B has 1 Contact; that Contact is moved to Account A.
   *        Query returns only A's Contacts, B never shows up -> without the
   *        default, B would wrongly keep count = 1 instead of 0.
   */
  public static void queryAndUpdateChildContactsCount(
    Set<Id> setOfAffectedAccountIds
  ) {
    // Safety check in case this public method is called directly with an empty set
    if (setOfAffectedAccountIds.size() != 0) {
      //List<Account> accountsToUpdate = new List<Account>();

      // Key = Account Id, Value = number of Contacts under that Account
      Map<Id, Integer> mapAccIdToConCount = new Map<Id, Integer>();

      // Step 1: default every affected Account to 0 (see corner case above)
      for (Id eachAccId : setOfAffectedAccountIds) {
        mapAccIdToConCount.put(eachAccId, 0);
      }

      // Step 2: count the Contacts currently in the DB for these Accounts
      // (one SOQL for all Accounts - bulk safe)
      for (AggregateResult ar : [
        SELECT COUNT(Id) ContactsCount, AccountId
        FROM Contact
        WHERE AccountId IN :setOfAffectedAccountIds
        GROUP BY AccountId
      ]) {
        //  containsKey is always true here (map was pre-filled), kept as a guard
        // if (mapAccIdToConCount.containsKey(c.AccountId)) {
        //   mapAccIdToConCount.put(
        //     c.AccountId,
        //     mapAccIdToConCount.get(c.AccountId) + 1
        //   );
        // }

        String accId = (String) ar.get('AccountId');
        Integer count = (Integer) ar.get('ContactsCount');
        mapAccIdToConCount.put(accId, count);
      }

      // Step 3: build Account records with the new count and update them
      // (one DML for all Accounts - bulk safe)
      if (mapAccIdToConCount.size() > 0) {
        List<Account> accountsToUpdate = new List<Account>();

        for (Id accId : mapAccIdToConCount.keySet()) {
          // Only Id + count field are set, so no other Account field is touched
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
