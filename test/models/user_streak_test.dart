import 'package:flutter_test/flutter_test.dart';
import 'package:divvy/models/user_streak.dart';
import '../helpers/test_data.dart';

void main() {
  group('UserStreak', () {
    group('fromJson', () {
      test('parses all fields correctly', () {
        final json = TestData.createUserStreakJson(
          id: 'streak-123',
          userId: 'user-456',
          householdId: 'household-789',
          currentStreak: 5,
          longestStreak: 10,
          lastCompletionDate: '2026-01-10',
          displayName: 'John Doe',
        );

        final streak = UserStreak.fromJson(json);

        expect(streak.id, 'streak-123');
        expect(streak.userId, 'user-456');
        expect(streak.householdId, 'household-789');
        expect(streak.currentStreak, 5);
        expect(streak.longestStreak, 10);
        expect(streak.lastCompletionDate, isNotNull);
        expect(streak.displayName, 'John Doe');
        expect(streak.createdAt, isNotNull);
        expect(streak.updatedAt, isNotNull);
      });

      test('defaults streak values to 0', () {
        final json = {
          'id': 's-1',
          'user_id': 'u-1',
          'household_id': 'h-1',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        final streak = UserStreak.fromJson(json);

        expect(streak.currentStreak, 0);
        expect(streak.longestStreak, 0);
      });

      test('handles null lastCompletionDate', () {
        final json = TestData.createUserStreakJson(lastCompletionDate: null);
        final streak = UserStreak.fromJson(json);

        expect(streak.lastCompletionDate, isNull);
      });

      test('handles missing profile data', () {
        final json = {
          'id': 's-1',
          'user_id': 'u-1',
          'household_id': 'h-1',
          'current_streak': 3,
          'longest_streak': 5,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        final streak = UserStreak.fromJson(json);

        expect(streak.displayName, isNull);
      });
    });

    group('toJson', () {
      test('serializes all fields correctly', () {
        final streak = TestData.createUserStreak(
          id: 's-1',
          userId: 'u-1',
          householdId: 'h-1',
          currentStreak: 7,
          longestStreak: 14,
          lastCompletionDate: DateTime(2026, 1, 10),
        );

        final json = streak.toJson();

        expect(json['id'], 's-1');
        expect(json['user_id'], 'u-1');
        expect(json['household_id'], 'h-1');
        expect(json['current_streak'], 7);
        expect(json['longest_streak'], 14);
        expect(json['last_completion_date'], '2026-01-10');
        expect(json['updated_at'], isNotNull);
      });

      test('formats lastCompletionDate as date only', () {
        final streak = TestData.createUserStreak(
          lastCompletionDate: DateTime(2026, 1, 15, 14, 30, 45),
        );

        final json = streak.toJson();

        expect(json['last_completion_date'], '2026-01-15');
      });

      test('does not include displayName in toJson', () {
        final streak = TestData.createUserStreak(displayName: 'Test User');
        final json = streak.toJson();

        expect(json.containsKey('display_name'), false);
        expect(json.containsKey('profiles'), false);
      });
    });

    group('copyWith', () {
      test('creates copy with updated currentStreak', () {
        final original = TestData.createUserStreak(currentStreak: 5);
        final copy = original.copyWith(currentStreak: 6);

        expect(copy.currentStreak, 6);
        expect(original.currentStreak, 5);
      });

      test('creates copy with updated longestStreak', () {
        final original = TestData.createUserStreak(longestStreak: 10);
        final copy = original.copyWith(longestStreak: 15);

        expect(copy.longestStreak, 15);
      });

      test('creates copy with updated lastCompletionDate', () {
        final original = TestData.createUserStreak(lastCompletionDate: DateTime(2026, 1, 1));
        final newDate = DateTime(2026, 1, 11);
        final copy = original.copyWith(lastCompletionDate: newDate);

        expect(copy.lastCompletionDate, newDate);
      });

      test('updates updatedAt on copy', () {
        final original = TestData.createUserStreak(
          updatedAt: DateTime(2026, 1, 1),
        );
        final copy = original.copyWith(currentStreak: 1);

        expect(copy.updatedAt.isAfter(original.updatedAt), true);
      });

      test('preserves immutable fields', () {
        final original = TestData.createUserStreak(
          id: 'original-id',
          userId: 'original-user',
          householdId: 'original-household',
        );
        final copy = original.copyWith(currentStreak: 10);

        expect(copy.id, original.id);
        expect(copy.userId, original.userId);
        expect(copy.householdId, original.householdId);
        expect(copy.displayName, original.displayName);
      });
    });
  });
}
