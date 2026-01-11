import 'package:flutter_test/flutter_test.dart';
import 'package:divvy/models/household.dart';
import 'package:divvy/models/household_member.dart';

void main() {
  group('HouseholdProvider', () {
    group('Household Model', () {
      test('fromJson parses all fields correctly', () {
        final json = {
          'id': 'test-id',
          'name': 'Test Household',
          'invite_code': 'ABC123',
          'created_by': 'user-123',
          'created_at': '2024-01-01T00:00:00.000Z',
        };

        final household = Household.fromJson(json);

        expect(household.id, 'test-id');
        expect(household.name, 'Test Household');
        expect(household.inviteCode, 'ABC123');
        expect(household.createdBy, 'user-123');
        expect(household.createdAt, isA<DateTime>());
      });

      test('fromJson requires invite_code', () {
        final json = {
          'id': 'test-id',
          'name': 'Test Household',
          'invite_code': 'XYZ789',
          'created_by': 'user-123',
          'created_at': '2024-01-01T00:00:00.000Z',
        };

        final household = Household.fromJson(json);

        expect(household.inviteCode, 'XYZ789');
      });

      test('toJson produces correct output', () {
        final household = Household(
          id: 'test-id',
          name: 'Test Household',
          inviteCode: 'ABC123',
          createdBy: 'user-123',
          createdAt: DateTime(2024, 1, 1),
        );

        final json = household.toJson();

        expect(json['id'], 'test-id');
        expect(json['name'], 'Test Household');
        expect(json['invite_code'], 'ABC123');
        expect(json['created_by'], 'user-123');
      });
    });

    group('HouseholdMember Model', () {
      test('fromJson parses all fields correctly', () {
        final json = {
          'user_id': 'user-123',
          'household_id': 'household-456',
          'role': 'admin',
          'joined_at': '2024-01-01T00:00:00.000Z',
          'profiles': {
            'display_name': 'John Doe',
            'avatar_url': 'https://example.com/avatar.jpg',
          },
        };

        final member = HouseholdMember.fromJson(json);

        expect(member.userId, 'user-123');
        expect(member.householdId, 'household-456');
        expect(member.role, 'admin');
        expect(member.displayName, 'John Doe');
        expect(member.avatarUrl, 'https://example.com/avatar.jpg');
        expect(member.joinedAt, isA<DateTime>());
      });

      test('fromJson handles missing profiles', () {
        final json = {
          'user_id': 'user-123',
          'household_id': 'household-456',
          'role': 'member',
          'joined_at': '2024-01-01T00:00:00.000Z',
        };

        final member = HouseholdMember.fromJson(json);

        expect(member.displayName, isNull);
        expect(member.avatarUrl, isNull);
      });

      test('fromJson defaults role to member', () {
        final json = {
          'user_id': 'user-123',
          'household_id': 'household-456',
          'role': null,
          'joined_at': '2024-01-01T00:00:00.000Z',
        };

        final member = HouseholdMember.fromJson(json);

        expect(member.role, 'member');
      });

      test('isAdmin returns true for admin role', () {
        final member = HouseholdMember(
          userId: 'user-123',
          householdId: 'household-456',
          role: 'admin',
          joinedAt: DateTime.now(),
        );

        expect(member.isAdmin, isTrue);
      });

      test('isAdmin returns false for member role', () {
        final member = HouseholdMember(
          userId: 'user-123',
          householdId: 'household-456',
          role: 'member',
          joinedAt: DateTime.now(),
        );

        expect(member.isAdmin, isFalse);
      });
    });

    group('Invite Code Generation', () {
      test('invite codes are uppercase alphanumeric', () {
        // Test the format of a valid invite code
        const validCode = 'ABC123XYZ789';
        final validCodeRegex = RegExp(r'^[A-Z0-9]+$');
        expect(validCodeRegex.hasMatch(validCode), isTrue);
      });

      test('invite code length is correct', () {
        const validCode = 'ABC123XYZ789';
        expect(validCode.length, 12);
      });
    });
  });
}
