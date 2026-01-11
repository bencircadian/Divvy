import 'package:flutter_test/flutter_test.dart';
import 'package:divvy/models/household_member.dart';
import '../helpers/test_data.dart';

void main() {
  group('HouseholdMember', () {
    group('fromJson', () {
      test('parses all fields correctly', () {
        final json = TestData.createHouseholdMemberJson(
          householdId: 'household-123',
          userId: 'user-456',
          role: 'admin',
          displayName: 'John Admin',
          avatarUrl: 'https://example.com/avatar.jpg',
        );

        final member = HouseholdMember.fromJson(json);

        expect(member.householdId, 'household-123');
        expect(member.userId, 'user-456');
        expect(member.role, 'admin');
        expect(member.displayName, 'John Admin');
        expect(member.avatarUrl, 'https://example.com/avatar.jpg');
        expect(member.joinedAt, isNotNull);
      });

      test('defaults role to member when null', () {
        final json = {
          'household_id': 'h-1',
          'user_id': 'u-1',
          'role': null,
          'joined_at': DateTime.now().toIso8601String(),
        };

        final member = HouseholdMember.fromJson(json);

        expect(member.role, 'member');
      });

      test('handles missing profile data', () {
        final json = {
          'household_id': 'h-1',
          'user_id': 'u-1',
          'role': 'member',
          'joined_at': DateTime.now().toIso8601String(),
        };

        final member = HouseholdMember.fromJson(json);

        expect(member.displayName, isNull);
        expect(member.avatarUrl, isNull);
      });
    });

    group('toJson', () {
      test('serializes all fields correctly', () {
        final member = TestData.createHouseholdMember(
          householdId: 'h-123',
          userId: 'u-456',
          role: 'admin',
        );

        final json = member.toJson();

        expect(json['household_id'], 'h-123');
        expect(json['user_id'], 'u-456');
        expect(json['role'], 'admin');
        expect(json['joined_at'], isNotNull);
      });

      test('does not include profile data in toJson', () {
        final member = TestData.createHouseholdMember(
          displayName: 'Test User',
          avatarUrl: 'https://avatar.jpg',
        );

        final json = member.toJson();

        expect(json.containsKey('display_name'), false);
        expect(json.containsKey('avatar_url'), false);
        expect(json.containsKey('profiles'), false);
      });
    });

    group('isAdmin', () {
      test('returns true for admin role', () {
        final adminMember = TestData.createHouseholdMember(role: 'admin');
        expect(adminMember.isAdmin, true);
      });

      test('returns false for member role', () {
        final regularMember = TestData.createHouseholdMember(role: 'member');
        expect(regularMember.isAdmin, false);
      });

      test('returns false for unknown role', () {
        final unknownMember = TestData.createHouseholdMember(role: 'unknown');
        expect(unknownMember.isAdmin, false);
      });
    });

    group('roundtrip serialization', () {
      test('fromJson -> toJson produces equivalent core data', () {
        final originalJson = TestData.createHouseholdMemberJson(
          householdId: 'rt-household',
          userId: 'rt-user',
          role: 'admin',
        );

        final member = HouseholdMember.fromJson(originalJson);
        final resultJson = member.toJson();

        expect(resultJson['household_id'], originalJson['household_id']);
        expect(resultJson['user_id'], originalJson['user_id']);
        expect(resultJson['role'], originalJson['role']);
      });
    });
  });
}
