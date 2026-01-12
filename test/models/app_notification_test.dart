import 'package:flutter_test/flutter_test.dart';
import 'package:divvy/models/app_notification.dart';
import '../helpers/test_data.dart';

void main() {
  group('AppNotification', () {
    group('fromJson', () {
      test('parses all fields correctly', () {
        final json = TestData.createAppNotificationJson(
          id: 'notif-123',
          userId: 'user-456',
          type: 'task_completed',
          title: 'Task Done',
          body: 'Someone completed a task',
          data: {'task_id': 'task-789'},
          read: true,
        );

        final notification = AppNotification.fromJson(json);

        expect(notification.id, 'notif-123');
        expect(notification.userId, 'user-456');
        expect(notification.type, NotificationType.taskCompleted);
        expect(notification.title, 'Task Done');
        expect(notification.body, 'Someone completed a task');
        expect(notification.data, {'task_id': 'task-789'});
        expect(notification.read, true);
        expect(notification.createdAt, isNotNull);
      });

      test('parses all notification types', () {
        expect(
          AppNotification.fromJson(TestData.createAppNotificationJson(type: 'task_assigned')).type,
          NotificationType.taskAssigned,
        );
        expect(
          AppNotification.fromJson(TestData.createAppNotificationJson(type: 'task_completed')).type,
          NotificationType.taskCompleted,
        );
        expect(
          AppNotification.fromJson(TestData.createAppNotificationJson(type: 'mentioned')).type,
          NotificationType.mentioned,
        );
        expect(
          AppNotification.fromJson(TestData.createAppNotificationJson(type: 'due_reminder')).type,
          NotificationType.dueReminder,
        );
      });

      test('defaults to taskAssigned for unknown type', () {
        final json = TestData.createAppNotificationJson(type: 'unknown_type');
        final notification = AppNotification.fromJson(json);

        expect(notification.type, NotificationType.taskAssigned);
      });

      test('defaults read to false', () {
        final json = {
          'id': 'n-1',
          'user_id': 'u-1',
          'type': 'task_assigned',
          'title': 'Title',
          'body': 'Body',
          'created_at': DateTime.now().toIso8601String(),
        };

        final notification = AppNotification.fromJson(json);

        expect(notification.read, false);
      });

      test('defaults data to empty map', () {
        final json = {
          'id': 'n-1',
          'user_id': 'u-1',
          'type': 'task_assigned',
          'title': 'Title',
          'body': 'Body',
          'created_at': DateTime.now().toIso8601String(),
        };

        final notification = AppNotification.fromJson(json);

        expect(notification.data, {});
      });
    });

    group('typeToString', () {
      test('converts taskAssigned correctly', () {
        expect(AppNotification.typeToString(NotificationType.taskAssigned), 'task_assigned');
      });

      test('converts taskCompleted correctly', () {
        expect(AppNotification.typeToString(NotificationType.taskCompleted), 'task_completed');
      });

      test('converts mentioned correctly', () {
        expect(AppNotification.typeToString(NotificationType.mentioned), 'mentioned');
      });

      test('converts dueReminder correctly', () {
        expect(AppNotification.typeToString(NotificationType.dueReminder), 'due_reminder');
      });
    });

    group('copyWith', () {
      test('creates copy with updated read status', () {
        final original = TestData.createAppNotification(read: false);
        final copy = original.copyWith(read: true);

        expect(copy.read, true);
        expect(original.read, false);
      });

      test('preserves other fields when updating read', () {
        final original = TestData.createAppNotification(
          id: 'notif-1',
          title: 'Test Title',
          body: 'Test Body',
          read: false,
        );
        final copy = original.copyWith(read: true);

        expect(copy.id, original.id);
        expect(copy.title, original.title);
        expect(copy.body, original.body);
        expect(copy.type, original.type);
        expect(copy.userId, original.userId);
        expect(copy.data, original.data);
        expect(copy.createdAt, original.createdAt);
      });
    });
  });

  group('NotificationType enum', () {
    test('has correct values', () {
      expect(NotificationType.values.length, 5);
      expect(NotificationType.taskAssigned.name, 'taskAssigned');
      expect(NotificationType.taskCompleted.name, 'taskCompleted');
      expect(NotificationType.mentioned.name, 'mentioned');
      expect(NotificationType.dueReminder.name, 'dueReminder');
      expect(NotificationType.appreciation.name, 'appreciation');
    });
  });
}
