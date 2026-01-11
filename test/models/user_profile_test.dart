import 'package:flutter_test/flutter_test.dart';
import 'package:divvy/models/user_profile.dart';
import '../helpers/test_data.dart';

void main() {
  group('UserProfile', () {
    group('fromJson', () {
      test('parses all fields correctly', () {
        final json = TestData.createUserProfileJson(
          id: 'user-123',
          displayName: 'John Doe',
          avatarUrl: 'https://example.com/avatar.jpg',
        );

        final profile = UserProfile.fromJson(json);

        expect(profile.id, 'user-123');
        expect(profile.displayName, 'John Doe');
        expect(profile.avatarUrl, 'https://example.com/avatar.jpg');
        expect(profile.createdAt, isNotNull);
      });

      test('handles null optional fields', () {
        final json = {
          'id': 'user-123',
          'created_at': DateTime.now().toIso8601String(),
        };

        final profile = UserProfile.fromJson(json);

        expect(profile.displayName, isNull);
        expect(profile.avatarUrl, isNull);
      });
    });

    group('toJson', () {
      test('serializes all fields correctly', () {
        final profile = TestData.createUserProfile(
          id: 'user-123',
          displayName: 'Jane Doe',
          avatarUrl: 'https://example.com/avatar.png',
        );

        final json = profile.toJson();

        expect(json['id'], 'user-123');
        expect(json['display_name'], 'Jane Doe');
        expect(json['avatar_url'], 'https://example.com/avatar.png');
        expect(json['created_at'], isNotNull);
      });

      test('includes null values for optional fields', () {
        final profile = TestData.createUserProfile(
          displayName: null,
          avatarUrl: null,
        );

        final json = profile.toJson();

        expect(json.containsKey('display_name'), true);
        expect(json.containsKey('avatar_url'), true);
      });
    });

    group('copyWith', () {
      test('creates copy with updated displayName', () {
        final original = TestData.createUserProfile(displayName: 'Original');
        final copy = original.copyWith(displayName: 'Updated');

        expect(copy.displayName, 'Updated');
        expect(copy.id, original.id);
        expect(original.displayName, 'Original');
      });

      test('creates copy with updated avatarUrl', () {
        final original = TestData.createUserProfile(avatarUrl: null);
        final copy = original.copyWith(avatarUrl: 'https://new-avatar.jpg');

        expect(copy.avatarUrl, 'https://new-avatar.jpg');
        expect(original.avatarUrl, isNull);
      });

      test('preserves all fields when not specified', () {
        final original = TestData.createUserProfile(
          id: 'id-1',
          displayName: 'Name',
          avatarUrl: 'url',
        );
        final copy = original.copyWith();

        expect(copy.id, original.id);
        expect(copy.displayName, original.displayName);
        expect(copy.avatarUrl, original.avatarUrl);
        expect(copy.createdAt, original.createdAt);
      });
    });

    group('roundtrip serialization', () {
      test('fromJson -> toJson produces equivalent data', () {
        final originalJson = TestData.createUserProfileJson(
          id: 'roundtrip-id',
          displayName: 'Roundtrip User',
          avatarUrl: 'https://example.com/rt.jpg',
        );

        final profile = UserProfile.fromJson(originalJson);
        final resultJson = profile.toJson();

        expect(resultJson['id'], originalJson['id']);
        expect(resultJson['display_name'], originalJson['display_name']);
        expect(resultJson['avatar_url'], originalJson['avatar_url']);
      });
    });
  });
}
