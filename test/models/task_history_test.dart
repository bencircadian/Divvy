import 'package:flutter_test/flutter_test.dart';
import 'package:divvy/models/task_history.dart';
import '../helpers/test_data.dart';

void main() {
  group('TaskHistory', () {
    group('fromJson', () {
      test('parses all fields correctly', () {
        final json = TestData.createTaskHistoryJson(
          id: 'history-123',
          taskId: 'task-456',
          userId: 'user-789',
          action: 'completed',
          details: {'note': 'Done!'},
          userName: 'John Doe',
        );

        final history = TaskHistory.fromJson(json);

        expect(history.id, 'history-123');
        expect(history.taskId, 'task-456');
        expect(history.userId, 'user-789');
        expect(history.action, TaskAction.completed);
        expect(history.details, {'note': 'Done!'});
        expect(history.userName, 'John Doe');
        expect(history.createdAt, isNotNull);
      });

      test('parses all action types', () {
        expect(
          TaskHistory.fromJson(TestData.createTaskHistoryJson(action: 'created')).action,
          TaskAction.created,
        );
        expect(
          TaskHistory.fromJson(TestData.createTaskHistoryJson(action: 'completed')).action,
          TaskAction.completed,
        );
        expect(
          TaskHistory.fromJson(TestData.createTaskHistoryJson(action: 'uncompleted')).action,
          TaskAction.uncompleted,
        );
        expect(
          TaskHistory.fromJson(TestData.createTaskHistoryJson(action: 'edited')).action,
          TaskAction.edited,
        );
        expect(
          TaskHistory.fromJson(TestData.createTaskHistoryJson(action: 'assigned')).action,
          TaskAction.assigned,
        );
        expect(
          TaskHistory.fromJson(TestData.createTaskHistoryJson(action: 'note_added')).action,
          TaskAction.noteAdded,
        );
      });

      test('defaults to created for unknown action', () {
        final json = TestData.createTaskHistoryJson(action: 'unknown_action');
        final history = TaskHistory.fromJson(json);

        expect(history.action, TaskAction.created);
      });

      test('handles null details', () {
        final json = TestData.createTaskHistoryJson(details: null);
        final history = TaskHistory.fromJson(json);

        expect(history.details, isNull);
      });
    });

    group('actionText', () {
      test('returns correct text for created', () {
        final history = TestData.createTaskHistory(action: TaskAction.created);
        expect(history.actionText, 'created this task');
      });

      test('returns correct text for completed', () {
        final history = TestData.createTaskHistory(action: TaskAction.completed);
        expect(history.actionText, 'completed this task');
      });

      test('returns correct text for uncompleted', () {
        final history = TestData.createTaskHistory(action: TaskAction.uncompleted);
        expect(history.actionText, 'marked as pending');
      });

      test('returns correct text for edited', () {
        final history = TestData.createTaskHistory(action: TaskAction.edited);
        expect(history.actionText, 'edited this task');
      });

      test('returns correct text for assigned with assignee name', () {
        final history = TestData.createTaskHistory(
          action: TaskAction.assigned,
          details: {'assignee_name': 'Jane'},
        );
        expect(history.actionText, 'assigned to Jane');
      });

      test('returns correct text for assigned without assignee name', () {
        final history = TestData.createTaskHistory(
          action: TaskAction.assigned,
          details: null,
        );
        expect(history.actionText, 'unassigned this task');
      });

      test('returns correct text for noteAdded', () {
        final history = TestData.createTaskHistory(action: TaskAction.noteAdded);
        expect(history.actionText, 'added a note');
      });
    });
  });

  group('TaskAction enum', () {
    test('has correct values', () {
      expect(TaskAction.values.length, 6);
      expect(TaskAction.created.name, 'created');
      expect(TaskAction.completed.name, 'completed');
      expect(TaskAction.uncompleted.name, 'uncompleted');
      expect(TaskAction.edited.name, 'edited');
      expect(TaskAction.assigned.name, 'assigned');
      expect(TaskAction.noteAdded.name, 'noteAdded');
    });
  });
}
