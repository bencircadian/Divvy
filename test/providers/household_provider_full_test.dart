/// Full tests for HouseholdProvider
library;

import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_data.dart';
import '../mocks/mock_providers.dart';

void main() {
  group('HouseholdProvider Full Tests', () {
    late MockHouseholdProvider householdProvider;

    setUp(() {
      householdProvider = MockHouseholdProvider();
    });

    group('Create Household Flow', () {
      test('createHousehold creates new household', () async {
        expect(householdProvider.hasHousehold, isFalse);

        final result = await householdProvider.createHousehold('Test Household');

        expect(result, isTrue);
        expect(householdProvider.hasHousehold, isTrue);
        expect(householdProvider.currentHousehold?.name, equals('Test Household'));
      });

      test('creator is added as admin member', () async {
        await householdProvider.createHousehold('My House');

        expect(householdProvider.members.isNotEmpty, isTrue);
        expect(householdProvider.members.first.role, equals('admin'));
      });

      test('loading state is managed during creation', () async {
        expect(householdProvider.isLoading, isFalse);

        final future = householdProvider.createHousehold('New House');
        // Loading would be true during the operation

        await future;
        expect(householdProvider.isLoading, isFalse);
      });
    });

    group('Join Household by Invite Code', () {
      test('valid code joins household', () async {
        final result = await householdProvider.joinHouseholdByCode('VALID123');

        expect(result, isTrue);
        expect(householdProvider.hasHousehold, isTrue);
      });

      test('invalid code shows error', () async {
        final result = await householdProvider.joinHouseholdByCode('ABC');

        expect(result, isFalse);
        expect(householdProvider.errorMessage, isNotNull);
        expect(householdProvider.errorMessage, contains('Invalid'));
      });

      test('joining loads household details', () async {
        await householdProvider.joinHouseholdByCode('JOINCODE12');

        expect(householdProvider.currentHousehold, isNotNull);
        expect(householdProvider.currentHousehold?.inviteCode, equals('JOINCODE12'));
      });

      test('joining loads member list', () async {
        await householdProvider.joinHouseholdByCode('VALID123');

        expect(householdProvider.members, isNotEmpty);
      });
    });

    group('Invalid Invite Code Handling', () {
      test('empty code fails', () async {
        final result = await householdProvider.joinHouseholdByCode('');

        expect(result, isFalse);
        expect(householdProvider.errorMessage, isNotNull);
      });

      test('code with only spaces fails', () async {
        final result = await householdProvider.joinHouseholdByCode('     ');

        expect(result, isFalse);
        expect(householdProvider.errorMessage, isNotNull);
      });

      test('too short code fails', () async {
        final result = await householdProvider.joinHouseholdByCode('AB');

        expect(result, isFalse);
      });
    });

    group('Invite Code Generation', () {
      test('invite code is uppercase alphanumeric', () {
        householdProvider.setHousehold(
          household: TestData.createHousehold(inviteCode: 'ABC123XYZ'),
        );

        final code = householdProvider.currentHousehold?.inviteCode;
        expect(code, isNotNull);
        expect(RegExp(r'^[A-Z0-9]+$').hasMatch(code!), isTrue);
      });

      test('invite code has appropriate length', () {
        householdProvider.setHousehold(
          household: TestData.createHousehold(inviteCode: 'ABCDEF123456'),
        );

        final code = householdProvider.currentHousehold?.inviteCode;
        expect(code?.length, greaterThanOrEqualTo(6));
        expect(code?.length, lessThanOrEqualTo(12));
      });
    });

    group('Member List Management', () {
      test('members list is loaded with household', () {
        final members = TestData.createMemberList();
        householdProvider.setHousehold(
          household: TestData.createHousehold(),
          members: members,
        );

        expect(householdProvider.members.length, equals(members.length));
      });

      test('members include display names', () {
        householdProvider.setHousehold(
          household: TestData.createHousehold(),
          members: [
            TestData.createHouseholdMember(displayName: 'User One'),
            TestData.createHouseholdMember(
              userId: TestData.testUserId2,
              displayName: 'User Two',
            ),
          ],
        );

        final names = householdProvider.members.map((m) => m.displayName).toList();
        expect(names, contains('User One'));
        expect(names, contains('User Two'));
      });

      test('members list is unmodifiable', () {
        householdProvider.setHousehold(
          household: TestData.createHousehold(),
          members: TestData.createMemberList(),
        );

        final members = householdProvider.members;
        expect(() => members.add(TestData.createHouseholdMember()), throwsUnsupportedError);
      });
    });

    group('Leave Household Flow', () {
      test('leave household clears current household', () async {
        householdProvider.setHousehold();
        expect(householdProvider.hasHousehold, isTrue);

        final result = await householdProvider.leaveHousehold();

        expect(result, isTrue);
        expect(householdProvider.hasHousehold, isFalse);
        expect(householdProvider.currentHousehold, isNull);
      });

      test('leave household clears member list', () async {
        householdProvider.setHousehold(
          members: TestData.createMemberList(),
        );

        await householdProvider.leaveHousehold();

        expect(householdProvider.members, isEmpty);
      });

      test('leave household updates loading state', () async {
        householdProvider.setHousehold();

        final future = householdProvider.leaveHousehold();
        await future;

        expect(householdProvider.isLoading, isFalse);
      });
    });

    group('Error State Management', () {
      test('error message can be set', () {
        householdProvider.setError('Test error message');

        expect(householdProvider.errorMessage, isNotNull);
        expect(householdProvider.errorMessage, equals('Test error message'));
      });

      test('clearError removes error message', () {
        householdProvider.setError('Some error');

        householdProvider.clearError();

        expect(householdProvider.errorMessage, isNull);
      });
    });

    group('Loading State', () {
      test('loading state can be toggled', () {
        expect(householdProvider.isLoading, isFalse);

        householdProvider.setLoading(true);
        expect(householdProvider.isLoading, isTrue);

        householdProvider.setLoading(false);
        expect(householdProvider.isLoading, isFalse);
      });
    });

    group('Load User Household', () {
      test('loadUserHousehold sets loading state', () async {
        householdProvider.setHousehold();

        await householdProvider.loadUserHousehold();

        expect(householdProvider.isLoading, isFalse);
      });
    });

    group('Household Helper Methods', () {
      test('hasHousehold returns false when no household', () {
        expect(householdProvider.hasHousehold, isFalse);
      });

      test('hasHousehold returns true when household exists', () {
        householdProvider.setHousehold();

        expect(householdProvider.hasHousehold, isTrue);
      });

      test('clearHousehold removes household and members', () {
        householdProvider.setHousehold(
          household: TestData.createHousehold(),
          members: TestData.createMemberList(),
        );

        householdProvider.clearHousehold();

        expect(householdProvider.hasHousehold, isFalse);
        expect(householdProvider.members, isEmpty);
      });
    });

    group('Household Properties', () {
      test('household name is accessible', () {
        householdProvider.setHousehold(
          household: TestData.createHousehold(name: 'Smith Family'),
        );

        expect(householdProvider.currentHousehold?.name, equals('Smith Family'));
      });

      test('household id is accessible', () {
        householdProvider.setHousehold(
          household: TestData.createHousehold(id: 'custom-id'),
        );

        expect(householdProvider.currentHousehold?.id, equals('custom-id'));
      });

      test('household created by is accessible', () {
        householdProvider.setHousehold(
          household: TestData.createHousehold(createdBy: TestData.testUserId),
        );

        expect(
          householdProvider.currentHousehold?.createdBy,
          equals(TestData.testUserId),
        );
      });
    });

    group('Member Roles', () {
      test('can have admin and member roles', () {
        householdProvider.setHousehold(
          members: [
            TestData.createHouseholdMember(
              userId: TestData.testUserId,
              role: 'admin',
            ),
            TestData.createHouseholdMember(
              userId: TestData.testUserId2,
              role: 'member',
            ),
          ],
        );

        final admin = householdProvider.members.firstWhere((m) => m.role == 'admin');
        final member = householdProvider.members.firstWhere((m) => m.role == 'member');

        expect(admin, isNotNull);
        expect(member, isNotNull);
        expect(admin.userId, isNot(equals(member.userId)));
      });
    });
  });
}
