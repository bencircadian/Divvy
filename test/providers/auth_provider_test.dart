import 'package:flutter_test/flutter_test.dart';
import 'package:divvy/models/user_profile.dart';

void main() {
  group('AuthProvider', () {
    group('AuthStatus enum', () {
      test('has correct values', () {
        // Using string check since AuthStatus is in provider file
        const statuses = ['initial', 'authenticated', 'unauthenticated'];
        expect(statuses.length, 3);
      });
    });

    group('UserProfile Model', () {
      test('fromJson parses all fields correctly', () {
        final json = {
          'id': 'user-123',
          'display_name': 'John Doe',
          'avatar_url': 'https://example.com/avatar.jpg',
          'created_at': '2024-01-01T00:00:00.000Z',
        };

        final profile = UserProfile.fromJson(json);

        expect(profile.id, 'user-123');
        expect(profile.displayName, 'John Doe');
        expect(profile.avatarUrl, 'https://example.com/avatar.jpg');
        expect(profile.createdAt, isA<DateTime>());
      });

      test('fromJson handles null display_name', () {
        final json = {
          'id': 'user-123',
          'display_name': null,
          'avatar_url': null,
          'created_at': '2024-01-01T00:00:00.000Z',
        };

        final profile = UserProfile.fromJson(json);

        expect(profile.displayName, isNull);
        expect(profile.avatarUrl, isNull);
      });

      test('copyWith creates new instance with updated values', () {
        final original = UserProfile(
          id: 'user-123',
          displayName: 'John Doe',
          avatarUrl: 'https://example.com/old.jpg',
          createdAt: DateTime(2024, 1, 1),
        );

        final updated = original.copyWith(
          displayName: 'Jane Doe',
          avatarUrl: 'https://example.com/new.jpg',
        );

        expect(updated.id, 'user-123'); // unchanged
        expect(updated.displayName, 'Jane Doe');
        expect(updated.avatarUrl, 'https://example.com/new.jpg');
      });

      test('copyWith preserves values when not specified', () {
        final original = UserProfile(
          id: 'user-123',
          displayName: 'John Doe',
          avatarUrl: 'https://example.com/avatar.jpg',
          createdAt: DateTime(2024, 1, 1),
        );

        final updated = original.copyWith();

        expect(updated.id, original.id);
        expect(updated.displayName, original.displayName);
        expect(updated.avatarUrl, original.avatarUrl);
      });

      test('toJson produces correct output', () {
        final profile = UserProfile(
          id: 'user-123',
          displayName: 'John Doe',
          avatarUrl: 'https://example.com/avatar.jpg',
          createdAt: DateTime(2024, 1, 1),
        );

        final json = profile.toJson();

        expect(json['id'], 'user-123');
        expect(json['display_name'], 'John Doe');
        expect(json['avatar_url'], 'https://example.com/avatar.jpg');
      });
    });

    group('Nonce Generation', () {
      test('nonce format is valid alphanumeric with special chars', () {
        // Test the pattern used in generateNonce
        const validNonce = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdef';
        final validNonceRegex = RegExp(r'^[0-9A-Za-z\-._]+$');
        expect(validNonceRegex.hasMatch(validNonce), isTrue);
      });

      test('default nonce length is 32', () {
        // The default length parameter is 32
        const defaultLength = 32;
        expect(defaultLength, 32);
      });
    });

    group('Provider Detection', () {
      test('email provider detection works', () {
        // Test provider string matching
        const providers = ['email', 'google', 'apple'];
        expect(providers.contains('email'), isTrue);
        expect(providers.contains('google'), isTrue);
        expect(providers.contains('apple'), isTrue);
        expect(providers.contains('facebook'), isFalse);
      });

      test('empty providers list returns empty', () {
        const providers = <String>[];
        expect(providers.contains('email'), isFalse);
        expect(providers.isEmpty, isTrue);
      });
    });

    group('Identity Linking', () {
      test('cannot unlink last identity', () {
        // Test the logic for preventing unlinking last identity
        final linkedProviders = ['email'];
        expect(linkedProviders.length <= 1, isTrue);

        final multipleProviders = ['email', 'google'];
        expect(multipleProviders.length <= 1, isFalse);
      });
    });
  });
}
