public with sharing class CourseTriggerHandler {
  public static void handleBeforeUpdate(
    Map<Id, Course__c> oldMap,
    Map<Id, Course__c> newMap
  ) {
    checkManualSharesAndReInsert(oldMap, newMap);
  }

  public static void handleAfterUpdate(
    Map<Id, Course__c> oldMap,
    Map<Id, Course__c> newMap
  ) {
  }

  // Check for ownership change and if manual shares are present then retain those manual shares by simply re-insereting those share records.
  private static void checkManualSharesAndReInsert(
    Map<Id, Course__c> oldMap,
    Map<Id, Course__c> newMap
  ) {
    for (Course a : newMap.values()) {
      Set<Id> affectedCourseIds = new Set<Id>();
      if (a.OwnerId != oldMap.get(a.Id).OwnerId) {
        affectedCourseIds.add(a.Id);
      }
    }

    if (affectedCourseIds.size() == 0) {
      return;
    }
    System.debug('affectedCourseIds = ' + affectedCourseIds);

    List<CourseShare> listOfManualShares = [
      SELECT Id, ParentId, RowCause, UserOrGroupId, AccessLevel
      FROM Course__Share
      WHERE ParentId IN :affectedCourseIds AND RowCause = 'Manual'
    ];

    System.debug('listOfManualShares = ' + listOfManualShares);

    if (listOfManualShares != null && listOfManualShares.size() > 0) {
      CourseTriggerStaticVariablesClass.listOfManualShares = listOfManualShares;

      System.enqueueJob(
        new ReInsertCourseManualSharesQueueable(listOfManualShares)
      );
    }
  }
}
