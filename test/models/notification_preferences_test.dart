import 'package:flutter_test/flutter_test.dart';
import 'package:divvy/models/notification_preferences.dart';
import '../helpers/test_data.dart';

void main() {
  group('NotificationPreferences', () {
    group('fromJson', () {
      test('parses all fields correctly', () {
        final json = TestData.createNotificationPreferencesJson(
          userId: 'user-123',
          pushEnabled: false,
          taskAssignedEnabled: false,
          taskCompletedEnabled: false,
          mentionsEnabled: false,
          dueRemindersEnabled: false,
          reminderBeforeMinutes: 30,
        );

        final prefs = NotificationPreferences.fromJson(json);

        expect(prefs.userId, 'user-123');
        expect(prefs.pushEnabled, false);
        expect(prefs.taskAssignedEnabled, false);
        expect(prefs.taskCompletedEnabled, false);
        expect(prefs.mentionsEnabled, false);
        expect(prefs.dueRemindersEnabled, false);
        expect(prefs.reminderBeforeMinutes, 30);
      });

      test('uses default values when fields are null', () {
        final json = {
          'user_id': 'user-123',
        };

        final prefs = NotificationPreferences.fromJson(json);

        expect(prefs.pushEnabled, true);
        expect(prefs.taskAssignedEnabled, true);
        expect(prefs.taskCompletedEnabled, true);
        expect(prefs.mentionsEnabled, true);
        expect(prefs.dueRemindersEnabled, true);
        expect(prefs.reminderBeforeMinutes, 60);
      });
    });

    group('toJson', () {
      test('serializes all fields correctly', () {
        final prefs = TestData.createNotificationPreferences(
          userId: 'u-1',
          pushEnabled: false,
          taskAssignedEnabled: true,
          taskCompletedEnabled: false,
          mentionsEnabled: true,
          dueRemindersEnabled: false,
          reminderBeforeMinutes: 120,
        );

        final json = prefs.toJson();

        expect(json['user_id'], 'u-1');
        expect(json['push_enabled'], false);
        expect(json['task_assigned_enabled'], true);
        expect(json['task_completed_enabled'], false);
        expect(json['mentions_enabled'], true);
        expect(json['due_reminders_enabled'], false);
        expect(json['reminder_before_minutes'], 120);
      });
    });

    group('copyWith', () {
      test('creates copy with updated pushEnabled', () {
        final original = TestData.createNotificationPreferences(pushEnabled: true);
        final copy = original.copyWith(pushEnabled: false);

        expect(copy.pushEnabled, false);
        expect(original.pushEnabled, true);
      });

      test('creates copy with updated taskAssignedEnabled', () {
        final original = TestData.createNotificationPreferences(taskAssignedEnabled: true);
        final copy = original.copyWith(taskAssignedEnabled: false);

        expect(copy.taskAssignedEnabled, false);
      });

      test('creates copy with updated taskCompletedEnabled', () {
        final original = TestData.createNotificationPreferences(taskCompletedEnabled: true);
        final copy = original.copyWith(taskCompletedEnabled: false);

        expect(copy.taskCompletedEnabled, false);
      });

      test('creates copy with updated mentionsEnabled', () {
        final original = TestData.createNotificationPreferences(mentionsEnabled: true);
        final copy = original.copyWith(mentionsEnabled: false);

        expect(copy.mentionsEnabled, false);
      });

      test('creates copy with updated dueRemindersEnabled', () {
        final original = TestData.createNotificationPreferences(dueRemindersEnabled: true);
        final copy = original.copyWith(dueRemindersEnabled: false);

        expect(copy.dueRemindersEnabled, false);
      });

      test('creates copy with updated reminderBeforeMinutes', () {
        final original = TestData.createNotificationPreferences(reminderBeforeMinutes: 60);
        final copy = original.copyWith(reminderBeforeMinutes: 15);

        expect(copy.reminderBeforeMinutes, 15);
      });

      test('preserves userId (cannot be changed)', () {
        final original = TestData.createNotificationPreferences(userId: 'original-user');
        final copy = original.copyWith(pushEnabled: false);

        expect(copy.userId, 'original-user');
      });
    });

    group('roundtrip serialization', () {
      test('fromJson -> toJson produces equivalent data', () {
        final originalJson = TestData.createNotificationPreferencesJson(
          userId: 'rt-user',
          pushEnabled: false,
          taskAssignedEnabled: true,
          reminderBeforeMinutes: 90,
        );

        final prefs = NotificationPreferences.fromJson(originalJson);
        final resultJson = prefs.toJson();

        expect(resultJson['user_id'], originalJson['user_id']);
        expect(resultJson['push_enabled'], originalJson['push_enabled']);
        expect(resultJson['task_assigned_enabled'], originalJson['task_assigned_enabled']);
        expect(resultJson['reminder_before_minutes'], originalJson['reminder_before_minutes']);
      });
    });
  });
}
