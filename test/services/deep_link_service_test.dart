/// Tests for DeepLinkService
library;

import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('DeepLinkService Tests', () {
    group('Parse Join Household Links', () {
      test('parses divvy://join/CODE format', () {
        final uri = Uri.parse('divvy://join/ABC123');

        expect(uri.scheme, equals('divvy'));
        // In divvy://join/ABC123, 'join' is the host, '/ABC123' is the path
        expect(uri.host, equals('join'));
        expect(uri.pathSegments.length, equals(1));
        expect(uri.pathSegments[0], equals('ABC123'));
      });

      test('parses join link with trailing slash', () {
        final uri = Uri.parse('divvy://join/ABC123/');

        expect(uri.host, equals('join'));
        // Trailing slash creates empty segment at end
        expect(uri.pathSegments.first, equals('ABC123'));
      });

      test('handles uppercase and lowercase codes', () {
        final upperUri = Uri.parse('divvy://join/ABCDEF');
        final lowerUri = Uri.parse('divvy://join/abcdef');

        expect(upperUri.pathSegments[0], equals('ABCDEF'));
        expect(lowerUri.pathSegments[0], equals('abcdef'));
      });

      test('handles numeric codes', () {
        final uri = Uri.parse('divvy://join/123456');

        expect(uri.pathSegments[0], equals('123456'));
      });

      test('handles mixed alphanumeric codes', () {
        final uri = Uri.parse('divvy://join/ABC123XYZ');

        expect(uri.pathSegments[0], equals('ABC123XYZ'));
      });
    });

    group('Parse Task Deep Links', () {
      test('parses task view link', () {
        final uri = Uri.parse('divvy://task/task-id-123');

        expect(uri.scheme, equals('divvy'));
        // In divvy://task/task-id-123, 'task' is the host
        expect(uri.host, equals('task'));
        expect(uri.pathSegments[0], equals('task-id-123'));
      });

      test('parses task link with UUID', () {
        final uri = Uri.parse('divvy://task/550e8400-e29b-41d4-a716-446655440000');

        expect(uri.pathSegments[0], contains('-'));
      });
    });

    group('Handle Malformed URIs Gracefully', () {
      test('handles empty path', () {
        final uri = Uri.parse('divvy://');

        expect(uri.pathSegments, isEmpty);
      });

      test('handles just scheme', () {
        final uri = Uri.tryParse('divvy:');

        expect(uri, isNotNull);
        expect(uri!.scheme, equals('divvy'));
      });

      test('handles missing code in join', () {
        final uri = Uri.parse('divvy://join');

        // 'join' is the host, path segments are empty
        expect(uri.host, equals('join'));
        expect(uri.pathSegments, isEmpty);
      });

      test('handles special characters in path', () {
        final uri = Uri.parse('divvy://join/ABC%20123');

        // URL decoding should happen - 'join' is host, encoded value is in pathSegments[0]
        expect(Uri.decodeComponent(uri.pathSegments[0]), contains(' '));
      });

      test('tryParse returns null for invalid URIs', () {
        // Technically 'not a valid uri' parses as a path, let's check invalid scheme
        final invalidScheme = Uri.tryParse('://invalid');
        // Either the parse returns null or has an empty scheme
        expect(invalidScheme == null || invalidScheme.scheme.isEmpty, isTrue);
      });
    });

    group('OAuth Callback Routing', () {
      test('parses login callback URL', () {
        final uri = Uri.parse('io.supabase.divvy://login-callback');

        expect(uri.scheme, equals('io.supabase.divvy'));
        expect(uri.host, equals('login-callback'));
      });

      test('parses callback with query parameters', () {
        final uri = Uri.parse(
          'io.supabase.divvy://login-callback?access_token=abc&refresh_token=xyz'
        );

        expect(uri.queryParameters['access_token'], equals('abc'));
        expect(uri.queryParameters['refresh_token'], equals('xyz'));
      });

      test('handles callback with fragment', () {
        final uri = Uri.parse(
          'io.supabase.divvy://login-callback#access_token=abc'
        );

        expect(uri.fragment, contains('access_token'));
      });
    });

    group('URL Security Validation', () {
      test('validates safe URLs', () {
        expect(isUrlSafe('divvy://join/ABC123'), isTrue);
        expect(isUrlSafe('https://example.com'), isTrue);
        expect(isUrlSafe('http://example.com'), isTrue);
      });

      test('rejects javascript: URLs', () {
        expect(isUrlSafe('javascript:alert(1)'), isFalse);
      });

      test('rejects data: URLs', () {
        expect(isUrlSafe('data:text/html,<script>'), isFalse);
      });

      test('rejects file: URLs', () {
        expect(isUrlSafe('file:///etc/passwd'), isFalse);
      });
    });

    group('Invite Code Validation', () {
      test('validates alphanumeric codes', () {
        expect(isValidInviteCode('ABC123'), isTrue);
        expect(isValidInviteCode('ABCDEF'), isTrue);
        expect(isValidInviteCode('123456'), isTrue);
        expect(isValidInviteCode('abc123xyz'), isTrue);
      });

      test('rejects codes with special characters', () {
        expect(isValidInviteCode('ABC-123'), isFalse);
        expect(isValidInviteCode('ABC_123'), isFalse);
        expect(isValidInviteCode('ABC 123'), isFalse);
        expect(isValidInviteCode('ABC@123'), isFalse);
      });

      test('rejects too short codes', () {
        expect(isValidInviteCode('ABC'), isFalse);
        expect(isValidInviteCode('12345'), isFalse);
      });

      test('rejects too long codes', () {
        expect(isValidInviteCode('ABCDEFGHIJKLM'), isFalse);
        expect(isValidInviteCode('A' * 20), isFalse);
      });

      test('rejects empty codes', () {
        expect(isValidInviteCode(''), isFalse);
      });
    });

    group('URI Path Parsing', () {
      test('correctly identifies join path', () {
        final uri = Uri.parse('divvy://join/CODE123');

        // 'join' is the host in this URI scheme
        expect(uri.host, equals('join'));
        expect(uri.pathSegments.isNotEmpty, isTrue);
        expect(uri.pathSegments[0], equals('CODE123'));
      });

      test('correctly identifies task path', () {
        final uri = Uri.parse('divvy://task/ID123');

        // 'task' is the host
        expect(uri.host, equals('task'));
        expect(uri.pathSegments[0], equals('ID123'));
      });

      test('handles unknown paths', () {
        final uri = Uri.parse('divvy://unknown/path');

        // 'unknown' is the host
        expect(uri.host, equals('unknown'));
        expect(uri.pathSegments[0], equals('path'));
      });
    });

    group('Query Parameter Handling', () {
      test('extracts code from query parameter', () {
        final uri = Uri.parse('divvy://join-household?code=ABC123');

        expect(uri.queryParameters['code'], equals('ABC123'));
      });

      test('handles multiple query parameters', () {
        final uri = Uri.parse('divvy://task?id=123&action=view');

        expect(uri.queryParameters['id'], equals('123'));
        expect(uri.queryParameters['action'], equals('view'));
      });

      test('handles URL-encoded query values', () {
        final uri = Uri.parse('divvy://search?q=hello%20world');

        expect(uri.queryParameters['q'], equals('hello world'));
      });
    });

    group('Scheme Detection', () {
      test('detects divvy scheme', () {
        final uri = Uri.parse('divvy://join/ABC');
        expect(uri.scheme, equals('divvy'));
      });

      test('detects supabase callback scheme', () {
        final uri = Uri.parse('io.supabase.divvy://callback');
        expect(uri.scheme, equals('io.supabase.divvy'));
      });

      test('detects http/https schemes', () {
        expect(Uri.parse('http://example.com').scheme, equals('http'));
        expect(Uri.parse('https://example.com').scheme, equals('https'));
      });
    });
  });
}
