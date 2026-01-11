import 'package:flutter_test/flutter_test.dart';
import 'package:divvy/models/recurrence_rule.dart';
import '../helpers/test_data.dart';

void main() {
  group('RecurrenceRule', () {
    group('fromJson', () {
      test('parses daily frequency', () {
        final json = TestData.createRecurrenceRuleJson(frequency: 'daily', interval: 2);
        final rule = RecurrenceRule.fromJson(json);

        expect(rule.frequency, RecurrenceFrequency.daily);
        expect(rule.interval, 2);
      });

      test('parses weekly frequency with days', () {
        final json = TestData.createRecurrenceRuleJson(
          frequency: 'weekly',
          interval: 1,
          days: [1, 3, 5], // Mon, Wed, Fri
        );
        final rule = RecurrenceRule.fromJson(json);

        expect(rule.frequency, RecurrenceFrequency.weekly);
        expect(rule.days, [1, 3, 5]);
      });

      test('parses monthly frequency', () {
        final json = TestData.createRecurrenceRuleJson(frequency: 'monthly', interval: 3);
        final rule = RecurrenceRule.fromJson(json);

        expect(rule.frequency, RecurrenceFrequency.monthly);
        expect(rule.interval, 3);
      });

      test('parses end date', () {
        final json = TestData.createRecurrenceRuleJson(endDate: '2026-12-31T00:00:00.000Z');
        final rule = RecurrenceRule.fromJson(json);

        expect(rule.endDate, isNotNull);
        expect(rule.endDate!.year, 2026);
        expect(rule.endDate!.month, 12);
      });

      test('defaults interval to 1 when not provided', () {
        final json = {'frequency': 'daily'};
        final rule = RecurrenceRule.fromJson(json);

        expect(rule.interval, 1);
      });

      test('defaults to daily for unknown frequency', () {
        final json = {'frequency': 'unknown'};
        final rule = RecurrenceRule.fromJson(json);

        expect(rule.frequency, RecurrenceFrequency.daily);
      });
    });

    group('toJson', () {
      test('serializes all fields', () {
        final rule = TestData.createRecurrenceRule(
          frequency: RecurrenceFrequency.weekly,
          interval: 2,
          days: [0, 6], // Sun, Sat
          endDate: DateTime(2026, 12, 31),
        );

        final json = rule.toJson();

        expect(json['frequency'], 'weekly');
        expect(json['interval'], 2);
        expect(json['days'], [0, 6]);
        expect(json['endDate'], isNotNull);
      });

      test('omits null days and endDate', () {
        final rule = TestData.createRecurrenceRule();
        final json = rule.toJson();

        expect(json.containsKey('days'), false);
        expect(json.containsKey('endDate'), false);
      });
    });

    group('getNextOccurrence', () {
      test('calculates next daily occurrence', () {
        final rule = TestData.createRecurrenceRule(
          frequency: RecurrenceFrequency.daily,
          interval: 1,
        );
        final from = DateTime(2026, 1, 10);
        final next = rule.getNextOccurrence(from);

        expect(next, DateTime(2026, 1, 11));
      });

      test('calculates next daily occurrence with interval', () {
        final rule = TestData.createRecurrenceRule(
          frequency: RecurrenceFrequency.daily,
          interval: 3,
        );
        final from = DateTime(2026, 1, 10);
        final next = rule.getNextOccurrence(from);

        expect(next, DateTime(2026, 1, 13));
      });

      test('calculates next weekly occurrence without days', () {
        final rule = TestData.createRecurrenceRule(
          frequency: RecurrenceFrequency.weekly,
          interval: 1,
        );
        final from = DateTime(2026, 1, 10); // Friday
        final next = rule.getNextOccurrence(from);

        expect(next, DateTime(2026, 1, 17)); // Next Friday
      });

      test('calculates next monthly occurrence', () {
        final rule = TestData.createRecurrenceRule(
          frequency: RecurrenceFrequency.monthly,
          interval: 1,
        );
        final from = DateTime(2026, 1, 15);
        final next = rule.getNextOccurrence(from);

        expect(next.month, 2);
        expect(next.day, 15);
      });

      test('handles monthly overflow for short months', () {
        final rule = TestData.createRecurrenceRule(
          frequency: RecurrenceFrequency.monthly,
          interval: 1,
        );
        final from = DateTime(2026, 1, 31); // Jan 31
        final next = rule.getNextOccurrence(from);

        // Feb doesn't have 31 days, should adjust
        expect(next.month, 2);
        expect(next.day, lessThanOrEqualTo(28));
      });
    });

    group('hasEnded', () {
      test('returns false when no end date', () {
        final rule = TestData.createRecurrenceRule();
        expect(rule.hasEnded(DateTime.now()), false);
      });

      test('returns false before end date', () {
        final rule = TestData.createRecurrenceRule(
          endDate: DateTime(2026, 12, 31),
        );
        expect(rule.hasEnded(DateTime(2026, 6, 15)), false);
      });

      test('returns true after end date', () {
        final rule = TestData.createRecurrenceRule(
          endDate: DateTime(2026, 6, 15),
        );
        expect(rule.hasEnded(DateTime(2026, 12, 31)), true);
      });
    });

    group('description', () {
      test('returns "Daily" for daily interval 1', () {
        final rule = TestData.createRecurrenceRule(
          frequency: RecurrenceFrequency.daily,
          interval: 1,
        );
        expect(rule.description, 'Daily');
      });

      test('returns "Every N days" for daily interval > 1', () {
        final rule = TestData.createRecurrenceRule(
          frequency: RecurrenceFrequency.daily,
          interval: 3,
        );
        expect(rule.description, 'Every 3 days');
      });

      test('returns "Weekly" for weekly interval 1 without days', () {
        final rule = TestData.createRecurrenceRule(
          frequency: RecurrenceFrequency.weekly,
          interval: 1,
        );
        expect(rule.description, 'Weekly');
      });

      test('returns "Weekly on X, Y" with specific days', () {
        final rule = TestData.createRecurrenceRule(
          frequency: RecurrenceFrequency.weekly,
          interval: 1,
          days: [1, 3], // Mon, Wed
        );
        expect(rule.description, 'Weekly on Mon, Wed');
      });

      test('returns "Monthly" for monthly interval 1', () {
        final rule = TestData.createRecurrenceRule(
          frequency: RecurrenceFrequency.monthly,
          interval: 1,
        );
        expect(rule.description, 'Monthly');
      });

      test('returns "Every N months" for monthly interval > 1', () {
        final rule = TestData.createRecurrenceRule(
          frequency: RecurrenceFrequency.monthly,
          interval: 2,
        );
        expect(rule.description, 'Every 2 months');
      });
    });

    group('copyWith', () {
      test('creates copy with updated values', () {
        final original = TestData.createRecurrenceRule(interval: 1);
        final copy = original.copyWith(interval: 5);

        expect(copy.interval, 5);
        expect(copy.frequency, original.frequency);
      });
    });

    group('equality', () {
      test('equal rules have same hashCode', () {
        final rule1 = TestData.createRecurrenceRule(
          frequency: RecurrenceFrequency.daily,
          interval: 2,
        );
        final rule2 = TestData.createRecurrenceRule(
          frequency: RecurrenceFrequency.daily,
          interval: 2,
        );

        expect(rule1 == rule2, true);
        expect(rule1.hashCode, rule2.hashCode);
      });

      test('different rules are not equal', () {
        final rule1 = TestData.createRecurrenceRule(interval: 1);
        final rule2 = TestData.createRecurrenceRule(interval: 2);

        expect(rule1 == rule2, false);
      });
    });
  });

  group('RecurrenceFrequency enum', () {
    test('has correct values', () {
      expect(RecurrenceFrequency.values.length, 3);
      expect(RecurrenceFrequency.daily.name, 'daily');
      expect(RecurrenceFrequency.weekly.name, 'weekly');
      expect(RecurrenceFrequency.monthly.name, 'monthly');
    });
  });
}
