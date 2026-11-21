public with sharing class ReInsertCourseManualSharesQueueable implements Queueable {
  List<Course__Share> listOfManualShares;

  public ReInsertCourseManualSharesQueueable(
    List<Course__Share> listOfManualShares
  ) {
    this.listOfManualShares = listOfManualShares;
  }

  public void execute(QueueableContext qc) {
    System.debug(
      'ReInsertAccountManualSharesQueueable exceute-> listOfManualShares=' +
      listOfManualShares
    );
    List<Course__Share> reInsertList = new List<Course__Share>();

    for (Course__Share accShare : listOfManualShares) {
      Course__Share newAs = new Course__Share();
      newAs.parentId = accShare.parentId;
      newAs.UserOrGroupId = accShare.UserOrGroupId;
      newAs.AccessLevel = accShare.AccessLevel;
      newAs.RowCause = accShare.RowCause;

      reInsertList.add(newAs);
    }
    insert as system reInsertList;
  }
}
