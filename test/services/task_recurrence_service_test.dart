/// Tests for TaskRecurrenceService
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:divvy/models/task.dart';
import 'package:divvy/models/recurrence_rule.dart';
import 'package:divvy/services/task_recurrence_service.dart';

import '../helpers/test_data.dart';

void main() {
  group('TaskRecurrenceService Tests', () {
    group('Daily Recurrence', () {
      test('creates correct next date for daily', () {
        final rule = RecurrenceRule(
          frequency: RecurrenceFrequency.daily,
          interval: 1,
        );

        final fromDate = DateTime(2026, 1, 15, 10, 0);
        final nextDate = TaskRecurrenceService.calculateNextDueDate(rule, fromDate);

        expect(nextDate, isNotNull);
        expect(nextDate!.year, equals(2026));
        expect(nextDate.month, equals(1));
        expect(nextDate.day, equals(16));
      });

      test('daily with interval 2 skips a day', () {
        final rule = RecurrenceRule(
          frequency: RecurrenceFrequency.daily,
          interval: 2,
        );

        final fromDate = DateTime(2026, 1, 15);
        final nextDate = TaskRecurrenceService.calculateNextDueDate(rule, fromDate);

        expect(nextDate!.day, equals(17));
      });

      test('daily crosses month boundary', () {
        final rule = RecurrenceRule(
          frequency: RecurrenceFrequency.daily,
          interval: 1,
        );

        final fromDate = DateTime(2026, 1, 31);
        final nextDate = TaskRecurrenceService.calculateNextDueDate(rule, fromDate);

        expect(nextDate!.month, equals(2));
        expect(nextDate.day, equals(1));
      });

      test('daily crosses year boundary', () {
        final rule = RecurrenceRule(
          frequency: RecurrenceFrequency.daily,
          interval: 1,
        );

        final fromDate = DateTime(2026, 12, 31);
        final nextDate = TaskRecurrenceService.calculateNextDueDate(rule, fromDate);

        expect(nextDate!.year, equals(2027));
        expect(nextDate.month, equals(1));
        expect(nextDate.day, equals(1));
      });
    });

    group('Weekly Recurrence', () {
      test('respects selected days', () {
        final rule = RecurrenceRule(
          frequency: RecurrenceFrequency.weekly,
          interval: 1,
          days: [1, 3, 5], // Mon, Wed, Fri
        );

        // Starting from a Tuesday (not in the list)
        final fromDate = DateTime(2026, 1, 20); // Tuesday
        final nextDate = TaskRecurrenceService.calculateNextDueDate(rule, fromDate);

        // Should return a day in the selected days list
        expect(nextDate, isNotNull);
        expect([DateTime.monday, DateTime.wednesday, DateTime.friday], contains(nextDate!.weekday));
      });

      test('wraps to next week when needed', () {
        final rule = RecurrenceRule(
          frequency: RecurrenceFrequency.weekly,
          interval: 1,
          days: [1], // Monday only
        );

        // Starting from a Friday
        final fromDate = DateTime(2026, 1, 16); // Friday
        final nextDate = TaskRecurrenceService.calculateNextDueDate(rule, fromDate);

        // Should be next Monday
        expect(nextDate!.weekday, equals(DateTime.monday));
        expect(nextDate.day, equals(19));
      });

      test('bi-weekly recurrence', () {
        final rule = RecurrenceRule(
          frequency: RecurrenceFrequency.weekly,
          interval: 2,
          days: [1], // Monday
        );

        final fromDate = DateTime(2026, 1, 19); // Monday
        final nextDate = TaskRecurrenceService.calculateNextDueDate(rule, fromDate);

        // Should be 2 weeks later
        expect(nextDate!.day, greaterThanOrEqualTo(26));
      });
    });

    group('Monthly Recurrence', () {
      test('handles 31st edge case', () {
        final rule = RecurrenceRule(
          frequency: RecurrenceFrequency.monthly,
          interval: 1,
        );

        // January 31
        final fromDate = DateTime(2026, 1, 31);
        final nextDate = TaskRecurrenceService.calculateNextDueDate(rule, fromDate);

        // February doesn't have 31st, should handle gracefully
        expect(nextDate, isNotNull);
        expect(nextDate!.month, equals(2));
      });

      test('handles 30th in months with fewer days', () {
        final rule = RecurrenceRule(
          frequency: RecurrenceFrequency.monthly,
          interval: 1,
        );

        // January 30
        final fromDate = DateTime(2026, 1, 30);
        final nextDate = TaskRecurrenceService.calculateNextDueDate(rule, fromDate);

        expect(nextDate!.month, equals(2));
      });

      test('monthly crosses year boundary', () {
        final rule = RecurrenceRule(
          frequency: RecurrenceFrequency.monthly,
          interval: 1,
        );

        final fromDate = DateTime(2026, 12, 15);
        final nextDate = TaskRecurrenceService.calculateNextDueDate(rule, fromDate);

        expect(nextDate!.year, equals(2027));
        expect(nextDate.month, equals(1));
        expect(nextDate.day, equals(15));
      });

      test('quarterly (interval 3) works', () {
        final rule = RecurrenceRule(
          frequency: RecurrenceFrequency.monthly,
          interval: 3,
        );

        final fromDate = DateTime(2026, 1, 15);
        final nextDate = TaskRecurrenceService.calculateNextDueDate(rule, fromDate);

        expect(nextDate!.month, equals(4));
      });
    });

    group('Long-term Monthly Recurrence', () {
      test('monthly with interval 12 simulates yearly', () {
        final rule = RecurrenceRule(
          frequency: RecurrenceFrequency.monthly,
          interval: 12,
        );

        final fromDate = DateTime(2026, 6, 15);
        final nextDate = TaskRecurrenceService.calculateNextDueDate(rule, fromDate);

        expect(nextDate!.year, equals(2027));
        expect(nextDate.month, equals(6));
        expect(nextDate.day, equals(15));
      });

      test('handles Feb 29 with 12-month interval', () {
        final rule = RecurrenceRule(
          frequency: RecurrenceFrequency.monthly,
          interval: 12,
        );

        // Feb 29, 2024 (leap year)
        final fromDate = DateTime(2024, 2, 29);
        final nextDate = TaskRecurrenceService.calculateNextDueDate(rule, fromDate);

        // 2025 is not a leap year, should handle gracefully
        expect(nextDate, isNotNull);
        expect(nextDate!.year, equals(2025));
      });

      test('bi-annual (interval 24)', () {
        final rule = RecurrenceRule(
          frequency: RecurrenceFrequency.monthly,
          interval: 24,
        );

        final fromDate = DateTime(2026, 6, 15);
        final nextDate = TaskRecurrenceService.calculateNextDueDate(rule, fromDate);

        expect(nextDate!.year, equals(2028));
      });
    });

    group('Recurrence Stops After End Date', () {
      test('shouldCreateNextOccurrence respects end date', () {
        // End date checking is done in shouldCreateNextOccurrence, not calculateNextDueDate
        final pastEndDate = DateTime.now().subtract(const Duration(days: 10));
        final task = TestData.createTask(
          isRecurring: true,
          status: TaskStatus.completed,
          recurrenceRule: RecurrenceRule(
            frequency: RecurrenceFrequency.daily,
            interval: 1,
            endDate: pastEndDate,
          ),
        );

        // Should not create occurrence if end date has passed
        expect(TaskRecurrenceService.shouldCreateNextOccurrence(task), isFalse);
      });

      test('shouldCreateNextOccurrence allows before end date', () {
        final futureEndDate = DateTime.now().add(const Duration(days: 10));
        final task = TestData.createTask(
          isRecurring: true,
          status: TaskStatus.completed,
          recurrenceRule: RecurrenceRule(
            frequency: RecurrenceFrequency.daily,
            interval: 1,
            endDate: futureEndDate,
          ),
        );

        // Should allow creation if end date hasn't passed
        expect(TaskRecurrenceService.shouldCreateNextOccurrence(task), isTrue);
      });
    });

    group('No Duplicate Recurrence Creation', () {
      test('shouldCreateNextOccurrence returns false for non-recurring', () {
        final task = TestData.createTask(
          isRecurring: false,
          status: TaskStatus.completed,
        );

        expect(TaskRecurrenceService.shouldCreateNextOccurrence(task), isFalse);
      });

      test('shouldCreateNextOccurrence returns false for incomplete', () {
        final task = TestData.createTask(
          isRecurring: true,
          recurrenceRule: TestData.createRecurrenceRule(),
          status: TaskStatus.pending,
        );

        expect(TaskRecurrenceService.shouldCreateNextOccurrence(task), isFalse);
      });

      test('shouldCreateNextOccurrence returns true for completed recurring', () {
        final task = TestData.createTask(
          isRecurring: true,
          recurrenceRule: TestData.createRecurrenceRule(),
          status: TaskStatus.completed,
        );

        expect(TaskRecurrenceService.shouldCreateNextOccurrence(task), isTrue);
      });

      test('shouldCreateNextOccurrence returns false after end date', () {
        final rule = RecurrenceRule(
          frequency: RecurrenceFrequency.daily,
          interval: 1,
          endDate: DateTime.now().subtract(const Duration(days: 1)),
        );

        final task = TestData.createTask(
          isRecurring: true,
          recurrenceRule: rule,
          status: TaskStatus.completed,
        );

        expect(TaskRecurrenceService.shouldCreateNextOccurrence(task), isFalse);
      });
    });

    group('Edge Cases', () {
      test('handles null recurrence rule', () {
        final task = TestData.createTask(
          isRecurring: true,
          recurrenceRule: null,
        );

        expect(task.recurrenceRule, isNull);
        expect(TaskRecurrenceService.shouldCreateNextOccurrence(task), isFalse);
      });

      test('handles empty days list for weekly', () {
        final rule = RecurrenceRule(
          frequency: RecurrenceFrequency.weekly,
          interval: 1,
          days: [], // No days specified
        );

        final fromDate = DateTime(2026, 1, 15);
        final nextDate = TaskRecurrenceService.calculateNextDueDate(rule, fromDate);

        // Should still calculate a next date
        expect(nextDate, isNotNull);
      });

      test('handles very large interval', () {
        final rule = RecurrenceRule(
          frequency: RecurrenceFrequency.daily,
          interval: 100,
        );

        final fromDate = DateTime(2026, 1, 15);
        final nextDate = TaskRecurrenceService.calculateNextDueDate(rule, fromDate);

        expect(nextDate, isNotNull);
        expect(nextDate!.difference(fromDate).inDays, equals(100));
      });

      test('handles past from date', () {
        final rule = RecurrenceRule(
          frequency: RecurrenceFrequency.daily,
          interval: 1,
        );

        final fromDate = DateTime(2020, 1, 15);
        final nextDate = TaskRecurrenceService.calculateNextDueDate(rule, fromDate);

        expect(nextDate, isNotNull);
        expect(nextDate!.isAfter(fromDate), isTrue);
      });
    });
  });
}
