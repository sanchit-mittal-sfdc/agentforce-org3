trigger ContactTrigger on Contact(
  after insert,
  after update,
  after delete,
  after undelete
) {
  switch on Trigger.operationType {
    when AFTER_INSERT {
      ContactTriggerHandler.handleAfterInsert(Trigger.newMap);
    }
    when AFTER_UPDATE {
      ContactTriggerHandler.handleAfterUpdate(Trigger.newMap, Trigger.oldMap);
    }
    when AFTER_DELETE {
      ContactTriggerHandler.handleAfterDelete(Trigger.oldMap);
    }
    when AFTER_UNDELETE {
      ContactTriggerHandler.handleAfterUndelete(Trigger.newMap);
    }
  }
}
