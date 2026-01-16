/// Security tests for deep link handling
library;

import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('Deep Link Security Tests', () {
    group('Directory Traversal Prevention', () {
      test('rejects directory traversal with ../', () {
        final maliciousCode = '../../../etc/passwd';
        expect(isValidInviteCode(maliciousCode), isFalse);
      });

      test('rejects directory traversal with ..\\', () {
        final maliciousCode = '..\\..\\..\\windows\\system32';
        expect(isValidInviteCode(maliciousCode), isFalse);
      });

      test('rejects encoded directory traversal', () {
        final maliciousCode = '..%2F..%2F..%2Fetc';
        expect(isValidInviteCode(maliciousCode), isFalse);
      });

      test('rejects double-encoded directory traversal', () {
        final maliciousCode = '..%252f..%252f..%252f';
        expect(isValidInviteCode(maliciousCode), isFalse);
      });

      test('all directory traversal payloads are rejected', () {
        for (final payload in getDirectoryTraversalPayloads()) {
          expect(
            isValidInviteCode(payload),
            isFalse,
            reason: 'Payload should be rejected: $payload',
          );
        }
      });
    });

    group('Null Byte Injection Prevention', () {
      test('rejects null bytes in invite code', () {
        final maliciousCode = 'ABC123\x00malicious';
        expect(isValidInviteCode(maliciousCode), isFalse);
      });

      test('rejects URL-encoded null bytes', () {
        final maliciousCode = 'ABC123%00malicious';
        expect(isValidInviteCode(maliciousCode), isFalse);
      });
    });

    group('Code Length Validation', () {
      test('rejects excessively long codes (>100 chars)', () {
        final longCode = 'A' * 101;
        expect(isValidInviteCode(longCode), isFalse);
      });

      test('accepts valid length codes', () {
        expect(isValidInviteCode('ABC123'), isTrue);
        expect(isValidInviteCode('ABCDEF789012'), isTrue);
      });

      test('rejects empty code', () {
        expect(isValidInviteCode(''), isFalse);
      });

      test('rejects too short code', () {
        expect(isValidInviteCode('ABC'), isFalse);
      });
    });

    group('Character Validation', () {
      test('rejects non-alphanumeric characters in invite codes', () {
        expect(isValidInviteCode('ABC-123'), isFalse);
        expect(isValidInviteCode('ABC_123'), isFalse);
        expect(isValidInviteCode('ABC 123'), isFalse);
        expect(isValidInviteCode('ABC@123'), isFalse);
        expect(isValidInviteCode('ABC#123'), isFalse);
      });

      test('accepts alphanumeric codes', () {
        expect(isValidInviteCode('ABC123'), isTrue);
        expect(isValidInviteCode('abc123'), isTrue);
        expect(isValidInviteCode('AbCdEf'), isTrue);
        expect(isValidInviteCode('123456'), isTrue);
      });

      test('rejects unicode characters', () {
        expect(isValidInviteCode('ABC123\u202E'), isFalse);
        expect(isValidInviteCode('ABC\u0000123'), isFalse);
      });
    });

    group('Malformed URI Handling', () {
      test('all malformed URI payloads are rejected as invite codes', () {
        for (final payload in getMalformedUriPayloads()) {
          // Extract just the "code" part if present
          final uri = Uri.tryParse(payload);
          if (uri != null && uri.pathSegments.length > 1) {
            final code = uri.pathSegments.last;
            expect(
              isValidInviteCode(code),
              isFalse,
              reason: 'Malformed URI code should be rejected: $code',
            );
          }
        }
      });
    });

    group('OAuth Callback Security', () {
      test('validates OAuth state parameter format', () {
        // Valid state should be alphanumeric (6-12 chars)
        expect(isValidInviteCode('state123'), isTrue);

        // Invalid states
        expect(isValidInviteCode('<script>'), isFalse);
        expect(isValidInviteCode("'; DROP TABLE"), isFalse);
      });

      test('rejects script injection in callback parameters', () {
        final xssPayloads = getXssPayloads();
        for (final payload in xssPayloads) {
          expect(
            isStringSafe(payload),
            isFalse,
            reason: 'XSS payload should be detected: $payload',
          );
        }
      });
    });

    group('Deep Link Scheme Validation', () {
      test('javascript: scheme URLs are unsafe', () {
        expect(isUrlSafe('javascript:alert(1)'), isFalse);
      });

      test('data: scheme URLs are unsafe', () {
        expect(isUrlSafe('data:text/html,<script>alert(1)</script>'), isFalse);
      });

      test('vbscript: scheme URLs are unsafe', () {
        expect(isUrlSafe('vbscript:msgbox(1)'), isFalse);
      });

      test('file: scheme URLs are unsafe', () {
        expect(isUrlSafe('file:///etc/passwd'), isFalse);
      });

      test('http/https schemes are safe', () {
        expect(isUrlSafe('https://example.com'), isTrue);
        expect(isUrlSafe('http://example.com'), isTrue);
      });

      test('custom app scheme is safe', () {
        expect(isUrlSafe('divvy://join/ABC123'), isTrue);
      });
    });

    group('URL Validation Edge Cases', () {
      test('handles malformed URLs gracefully', () {
        expect(isUrlSafe('not a valid url'), isFalse);
        expect(isUrlSafe(''), isFalse);
        expect(isUrlSafe('://missing-scheme'), isFalse);
      });

      test('handles URLs with special characters', () {
        expect(isUrlSafe('https://example.com/path?query=value'), isTrue);
        expect(isUrlSafe('https://example.com/path#fragment'), isTrue);
      });
    });
  });
}
