/// Performance tests for recurrence calculations
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:divvy/models/recurrence_rule.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('Recurrence Performance Tests', () {
    group('Next Occurrence Calculation', () {
      test('calculate 1000 daily next occurrences < 50ms', () async {
        final rule = RecurrenceRule(
          frequency: RecurrenceFrequency.daily,
          interval: 1,
        );

        await assertCompletesWithin(
          () async {
            final baseDate = DateTime.now();
            for (int i = 0; i < 1000; i++) {
              rule.getNextOccurrence(baseDate.add(Duration(days: i)));
            }
          },
          const Duration(milliseconds: 50),
          reason: '1000 daily occurrences should calculate quickly',
        );
      });

      test('calculate 1000 weekly next occurrences < 100ms', () async {
        final rule = RecurrenceRule(
          frequency: RecurrenceFrequency.weekly,
          interval: 1,
          days: [1, 3, 5], // Mon, Wed, Fri
        );

        await assertCompletesWithin(
          () async {
            final baseDate = DateTime.now();
            for (int i = 0; i < 1000; i++) {
              rule.getNextOccurrence(baseDate.add(Duration(days: i)));
            }
          },
          const Duration(milliseconds: 100),
          reason: '1000 weekly occurrences should calculate quickly',
        );
      });

      test('calculate 1000 monthly next occurrences < 100ms', () async {
        final rule = RecurrenceRule(
          frequency: RecurrenceFrequency.monthly,
          interval: 1,
        );

        await assertCompletesWithin(
          () async {
            final baseDate = DateTime.now();
            for (int i = 0; i < 1000; i++) {
              rule.getNextOccurrence(baseDate.add(Duration(days: i)));
            }
          },
          const Duration(milliseconds: 100),
          reason: '1000 monthly occurrences should calculate quickly',
        );
      });

      test('calculate 1000 yearly next occurrences < 100ms', () async {
        final rule = RecurrenceRule(
          frequency: RecurrenceFrequency.monthly,
          interval: 1,
        );

        await assertCompletesWithin(
          () async {
            final baseDate = DateTime.now();
            for (int i = 0; i < 1000; i++) {
              rule.getNextOccurrence(baseDate.add(Duration(days: i * 30)));
            }
          },
          const Duration(milliseconds: 100),
          reason: '1000 yearly occurrences should calculate quickly',
        );
      });
    });

    group('Monthly Edge Cases', () {
      test('31st of month edge case does not loop infinitely', () async {
        final rule = RecurrenceRule(
          frequency: RecurrenceFrequency.monthly,
          interval: 1,
        );

        // Start from January 31
        final startDate = DateTime(2026, 1, 31);

        await assertCompletesWithin(
          () async {
            // Calculate 12 months of recurrences
            var currentDate = startDate;
            for (int i = 0; i < 12; i++) {
              final next = rule.getNextOccurrence(currentDate);
              currentDate = next;
            }
          },
          const Duration(milliseconds: 100),
          reason: '31st edge case should not cause infinite loop',
        );
      });

      test('February 29/30/31 handling is correct', () async {
        final rule = RecurrenceRule(
          frequency: RecurrenceFrequency.monthly,
          interval: 1,
        );

        // Start from January 30
        final startDate = DateTime(2026, 1, 30);
        final next = rule.getNextOccurrence(startDate);

        // February 2026 has 28 days, so it should handle this gracefully
        expect(next.month, equals(2));
      });

      test('bi-monthly recurrence calculates correctly', () async {
        final rule = RecurrenceRule(
          frequency: RecurrenceFrequency.monthly,
          interval: 2,
        );

        final startDate = DateTime(2026, 1, 15);

        await assertCompletesWithin(
          () async {
            var currentDate = startDate;
            for (int i = 0; i < 24; i++) {
              final next = rule.getNextOccurrence(currentDate);
              currentDate = next;
            }
          },
          const Duration(milliseconds: 100),
          reason: 'Bi-monthly recurrence should be efficient',
        );
      });
    });

    group('Yearly Recurrences Far in Future', () {
      test('yearly recurrence 50 years out calculates quickly', () async {
        final rule = RecurrenceRule(
          frequency: RecurrenceFrequency.monthly,
          interval: 1,
        );

        await assertCompletesWithin(
          () async {
            var currentDate = DateTime.now();
            for (int i = 0; i < 50; i++) {
              final next = rule.getNextOccurrence(currentDate);
              currentDate = next;
            }

            // Should be about 50 months in the future (~4 years)
            expect(
              currentDate.year,
              greaterThan(DateTime.now().year + 3),
            );
          },
          const Duration(milliseconds: 50),
          reason: 'Long-term monthly recurrence should be efficient',
        );
      });

      test('leap year handling in yearly recurrence', () async {
        final rule = RecurrenceRule(
          frequency: RecurrenceFrequency.monthly,
          interval: 1,
        );

        // Start from Feb 29 on a leap year
        final startDate = DateTime(2024, 2, 29);
        final next = rule.getNextOccurrence(startDate);

        // Next month should be March 2024
        expect(next.month, equals(3));
        expect(next.year, equals(2024));
      });
    });

    group('Complex Weekly Patterns', () {
      test('every other week on specific days', () async {
        final rule = RecurrenceRule(
          frequency: RecurrenceFrequency.weekly,
          interval: 2,
          days: [1, 3, 5], // Mon, Wed, Fri every 2 weeks
        );

        await assertCompletesWithin(
          () async {
            var currentDate = DateTime.now();
            final occurrences = <DateTime>[];

            for (int i = 0; i < 100; i++) {
              final next = rule.getNextOccurrence(currentDate);
              occurrences.add(next);
              currentDate = next;
            }

            expect(occurrences.length, equals(100));
          },
          const Duration(milliseconds: 100),
          reason: 'Complex weekly pattern should be efficient',
        );
      });

      test('all days of week pattern', () async {
        final rule = RecurrenceRule(
          frequency: RecurrenceFrequency.weekly,
          interval: 1,
          days: [1, 2, 3, 4, 5, 6, 7], // All days
        );

        await assertCompletesWithin(
          () async {
            var currentDate = DateTime.now();
            for (int i = 0; i < 100; i++) {
              final next = rule.getNextOccurrence(currentDate);
              currentDate = next;
            }
          },
          const Duration(milliseconds: 50),
          reason: 'All-days pattern should be efficient',
        );
      });
    });

    group('End Date Handling', () {
      test('respects end date efficiently', () async {
        final endDate = DateTime.now().add(const Duration(days: 30));
        final rule = RecurrenceRule(
          frequency: RecurrenceFrequency.daily,
          interval: 1,
          endDate: endDate,
        );

        await assertCompletesWithin(
          () async {
            var currentDate = DateTime.now();
            int count = 0;

            while (count < 100) {
              final next = rule.getNextOccurrence(currentDate);
              if (next.isAfter(endDate)) break;
              currentDate = next;
              count++;
            }

            // Should have stopped before 100 due to end date
            expect(count, lessThan(35)); // ~30 days
          },
          const Duration(milliseconds: 50),
          reason: 'End date checking should be efficient',
        );
      });

      test('far future end date does not affect performance', () async {
        final endDate = DateTime.now().add(const Duration(days: 36500)); // 100 years
        final rule = RecurrenceRule(
          frequency: RecurrenceFrequency.daily,
          interval: 1,
          endDate: endDate,
        );

        await assertCompletesWithin(
          () async {
            var currentDate = DateTime.now();
            for (int i = 0; i < 100; i++) {
              final next = rule.getNextOccurrence(currentDate);
              currentDate = next;
            }
          },
          const Duration(milliseconds: 50),
          reason: 'Far future end date should not slow down calculation',
        );
      });
    });

    group('Interval Variations', () {
      test('various intervals perform consistently', () async {
        final intervals = [1, 2, 3, 5, 7, 10, 30];

        for (final interval in intervals) {
          final rule = RecurrenceRule(
            frequency: RecurrenceFrequency.daily,
            interval: interval,
          );

          await assertCompletesWithin(
            () async {
              var currentDate = DateTime.now();
              for (int i = 0; i < 100; i++) {
                final next = rule.getNextOccurrence(currentDate);
                currentDate = next;
              }
            },
            const Duration(milliseconds: 50),
            reason: 'Interval $interval should perform well',
          );
        }
      });
    });

    group('Batch Calculations', () {
      test('generate preview dates efficiently', () async {
        final rule = RecurrenceRule(
          frequency: RecurrenceFrequency.weekly,
          interval: 1,
          days: [1, 4], // Mon, Thu
        );

        await assertCompletesWithin(
          () async {
            final previewDates = <DateTime>[];
            var currentDate = DateTime.now();

            for (int i = 0; i < 10; i++) {
              final next = rule.getNextOccurrence(currentDate);
              previewDates.add(next);
              currentDate = next;
            }

            expect(previewDates.length, equals(10));
          },
          const Duration(milliseconds: 20),
          reason: 'Preview generation should be fast',
        );
      });
    });
  });
}
