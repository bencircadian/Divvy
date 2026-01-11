import 'package:flutter_test/flutter_test.dart';
import 'package:divvy/services/task_history_service.dart';

void main() {
  group('TaskHistoryService', () {
    group('Action Constants', () {
      test('has correct action constant values', () {
        expect(TaskHistoryService.actionCreated, 'created');
        expect(TaskHistoryService.actionUpdated, 'updated');
        expect(TaskHistoryService.actionCompleted, 'completed');
        expect(TaskHistoryService.actionUncompleted, 'uncompleted');
        expect(TaskHistoryService.actionAssigned, 'assigned');
        expect(TaskHistoryService.actionUnassigned, 'unassigned');
        expect(TaskHistoryService.actionDeleted, 'deleted');
        expect(TaskHistoryService.actionNoteAdded, 'note_added');
        expect(TaskHistoryService.actionNoteDeleted, 'note_deleted');
      });

      test('all action constants are unique', () {
        final actions = [
          TaskHistoryService.actionCreated,
          TaskHistoryService.actionUpdated,
          TaskHistoryService.actionCompleted,
          TaskHistoryService.actionUncompleted,
          TaskHistoryService.actionAssigned,
          TaskHistoryService.actionUnassigned,
          TaskHistoryService.actionDeleted,
          TaskHistoryService.actionNoteAdded,
          TaskHistoryService.actionNoteDeleted,
        ];
        expect(actions.toSet().length, actions.length);
      });
    });
  });
}
