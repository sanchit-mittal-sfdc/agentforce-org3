trigger CourseTrigger on Course__c(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  switch on Trigger.OperationType {
    when BEFORE_UPDATE {
      CourseTriggerHandler.handleBeforeUpdate(Trigger.oldMap, Trigger.newMap);
    }
    when AFTER_UPDATE {
      CourseTriggerHandler.handleAfterUpdate(Trigger.oldMap, Trigger.newMap);
    }
  }
}
