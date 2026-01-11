import 'package:flutter_test/flutter_test.dart';
import 'package:divvy/models/household.dart';
import '../helpers/test_data.dart';

void main() {
  group('Household', () {
    group('fromJson', () {
      test('parses all fields correctly', () {
        final json = TestData.createHouseholdJson(
          id: 'household-123',
          name: 'Smith Family',
          inviteCode: 'XYZ789',
          createdBy: 'user-456',
        );

        final household = Household.fromJson(json);

        expect(household.id, 'household-123');
        expect(household.name, 'Smith Family');
        expect(household.inviteCode, 'XYZ789');
        expect(household.createdBy, 'user-456');
        expect(household.createdAt, isNotNull);
      });
    });

    group('toJson', () {
      test('serializes all fields correctly', () {
        final household = TestData.createHousehold(
          id: 'h-1',
          name: 'Test Home',
          inviteCode: 'ABC123',
          createdBy: 'creator-id',
        );

        final json = household.toJson();

        expect(json['id'], 'h-1');
        expect(json['name'], 'Test Home');
        expect(json['invite_code'], 'ABC123');
        expect(json['created_by'], 'creator-id');
        expect(json['created_at'], isNotNull);
      });
    });

    group('copyWith', () {
      test('creates copy with updated name', () {
        final original = TestData.createHousehold(name: 'Original Name');
        final copy = original.copyWith(name: 'New Name');

        expect(copy.name, 'New Name');
        expect(copy.id, original.id);
        expect(original.name, 'Original Name');
      });

      test('creates copy with updated invite code', () {
        final original = TestData.createHousehold(inviteCode: 'OLD123');
        final copy = original.copyWith(inviteCode: 'NEW456');

        expect(copy.inviteCode, 'NEW456');
        expect(original.inviteCode, 'OLD123');
      });

      test('preserves all fields when not specified', () {
        final original = TestData.createHousehold(
          id: 'id-1',
          name: 'My House',
          inviteCode: 'CODE',
          createdBy: 'creator',
        );
        final copy = original.copyWith();

        expect(copy.id, original.id);
        expect(copy.name, original.name);
        expect(copy.inviteCode, original.inviteCode);
        expect(copy.createdBy, original.createdBy);
        expect(copy.createdAt, original.createdAt);
      });
    });

    group('roundtrip serialization', () {
      test('fromJson -> toJson produces equivalent data', () {
        final originalJson = TestData.createHouseholdJson(
          id: 'roundtrip-household',
          name: 'Roundtrip Family',
          inviteCode: 'RTRP01',
          createdBy: 'creator-rt',
        );

        final household = Household.fromJson(originalJson);
        final resultJson = household.toJson();

        expect(resultJson['id'], originalJson['id']);
        expect(resultJson['name'], originalJson['name']);
        expect(resultJson['invite_code'], originalJson['invite_code']);
        expect(resultJson['created_by'], originalJson['created_by']);
      });
    });
  });
}
