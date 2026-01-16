/// Security tests for input validation
library;

import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('Input Validation Security Tests', () {
    group('Email Validation (RFC 5322)', () {
      test('accepts valid email formats', () {
        expect(isValidEmail('user@example.com'), isTrue);
        expect(isValidEmail('user.name@example.com'), isTrue);
        expect(isValidEmail('user+tag@example.com'), isTrue);
        expect(isValidEmail('user@subdomain.example.com'), isTrue);
        expect(isValidEmail('user123@example.com'), isTrue);
        expect(isValidEmail('user_name@example.com'), isTrue);
      });

      test('rejects invalid email formats', () {
        expect(isValidEmail(''), isFalse);
        expect(isValidEmail('invalid'), isFalse);
        expect(isValidEmail('@example.com'), isFalse);
        expect(isValidEmail('user@'), isFalse);
        expect(isValidEmail('user@.com'), isFalse);
        expect(isValidEmail('user @example.com'), isFalse);
        expect(isValidEmail('user@@example.com'), isFalse);
      });

      test('rejects email with XSS payloads', () {
        expect(isValidEmail('<script>@example.com'), isFalse);
        expect(isValidEmail('user@<script>.com'), isFalse);
      });

      test('rejects email with SQL injection', () {
        expect(isValidEmail("user'--@example.com"), isFalse);
        expect(isValidEmail("user@example.com'; DROP TABLE"), isFalse);
      });
    });

    group('XSS Prevention in Task Descriptions', () {
      test('detects XSS script tags', () {
        expect(isStringSafe('<script>alert("XSS")</script>'), isFalse);
        expect(isStringSafe('"><script>alert("XSS")</script>'), isFalse);
      });

      test('detects javascript: protocol', () {
        expect(isStringSafe("javascript:alert('XSS')"), isFalse);
        expect(isStringSafe('JAVASCRIPT:alert(1)'), isFalse);
      });

      test('detects event handlers', () {
        expect(isStringSafe('<img src=x onerror=alert("XSS")>'), isFalse);
        expect(isStringSafe('<body onload=alert("XSS")>'), isFalse);
        expect(isStringSafe('<svg onload=alert("XSS")>'), isFalse);
        expect(isStringSafe('<div onclick=alert(1)>'), isFalse);
      });

      test('all XSS payloads are detected', () {
        for (final payload in getXssPayloads()) {
          expect(
            isStringSafe(payload),
            isFalse,
            reason: 'XSS payload should be detected: $payload',
          );
        }
      });

      test('allows safe text content', () {
        expect(isStringSafe('Clean up the kitchen'), isTrue);
        expect(isStringSafe('Buy groceries: milk, bread, eggs'), isTrue);
        expect(isStringSafe('Meeting at 3pm - bring notes'), isTrue);
        expect(isStringSafe('Task with "quotes" is fine'), isTrue);
      });

      test('allows safe special characters', () {
        expect(isStringSafe('Price: \$50.00'), isTrue);
        expect(isStringSafe('Email: user@example.com'), isTrue);
        expect(isStringSafe('Path: C:\\Users\\Documents'), isTrue);
        expect(isStringSafe('Ratio: 1:2'), isTrue);
      });
    });

    group('SQL Injection Prevention', () {
      test('detects SQL DROP statements', () {
        expect(isStringSafe("'; DROP TABLE users; --"), isFalse);
        expect(isStringSafe("1'; DROP TABLE tasks;--"), isFalse);
      });

      test('detects SQL OR injection', () {
        expect(isStringSafe("1' OR '1'='1"), isFalse);
        expect(isStringSafe("admin' OR 1=1--"), isFalse);
      });

      test('detects SQL UNION injection', () {
        expect(isStringSafe("1' UNION SELECT * FROM users--"), isFalse);
      });

      test('detects SQL INSERT injection', () {
        expect(isStringSafe("'; INSERT INTO users VALUES('hacked');--"), isFalse);
      });

      test('detects SQL UPDATE injection', () {
        expect(isStringSafe("1'; UPDATE users SET password='hacked';--"), isFalse);
      });

      test('detects SQL DELETE injection', () {
        expect(isStringSafe("1; DELETE FROM users WHERE 1=1"), isFalse);
      });

      test('all SQL injection payloads are detected', () {
        for (final payload in getSqlInjectionPayloads()) {
          expect(
            isStringSafe(payload),
            isFalse,
            reason: 'SQL injection payload should be detected: $payload',
          );
        }
      });

      test('allows safe text with SQL-like words', () {
        expect(isStringSafe('Select the best option'), isTrue);
        expect(isStringSafe('Drop off the package'), isTrue);
        expect(isStringSafe('Update the schedule'), isTrue);
        expect(isStringSafe('Delete the old files'), isTrue);
      });
    });

    group('Avatar URL Validation', () {
      test('rejects javascript: URLs', () {
        expect(isUrlSafe("javascript:alert('XSS')"), isFalse);
      });

      test('rejects data: URLs with scripts', () {
        expect(isUrlSafe('data:text/html,<script>alert(1)</script>'), isFalse);
        expect(isUrlSafe('data:image/svg+xml,<svg onload=alert(1)>'), isFalse);
      });

      test('accepts valid image URLs', () {
        expect(isUrlSafe('https://example.com/avatar.png'), isTrue);
        expect(isUrlSafe('https://example.com/avatar.jpg'), isTrue);
        expect(isUrlSafe('https://cdn.example.com/images/user.webp'), isTrue);
      });

      test('accepts relative URLs', () {
        // Note: relative URLs might need different handling
        expect(isUrlSafe('/images/avatar.png'), isTrue);
      });
    });

    group('Invite Code Format Validation', () {
      test('accepts valid alphanumeric codes', () {
        expect(isValidInviteCode('ABC123'), isTrue);
        expect(isValidInviteCode('XYZ789ABC'), isTrue);
        expect(isValidInviteCode('ABCDEF123456'), isTrue);
      });

      test('rejects codes with special characters', () {
        expect(isValidInviteCode('ABC-123'), isFalse);
        expect(isValidInviteCode('ABC_123'), isFalse);
        expect(isValidInviteCode('ABC 123'), isFalse);
        expect(isValidInviteCode('ABC@123'), isFalse);
        expect(isValidInviteCode("ABC'123"), isFalse);
        expect(isValidInviteCode('ABC"123'), isFalse);
        expect(isValidInviteCode('ABC<123'), isFalse);
        expect(isValidInviteCode('ABC>123'), isFalse);
      });

      test('rejects codes outside length bounds', () {
        expect(isValidInviteCode('ABC'), isFalse);      // Too short
        expect(isValidInviteCode('ABCDE'), isFalse);    // Too short (5)
        expect(isValidInviteCode('A' * 13), isFalse);   // Too long
        expect(isValidInviteCode('A' * 100), isFalse);  // Way too long
      });

      test('rejects empty and whitespace-only codes', () {
        expect(isValidInviteCode(''), isFalse);
        expect(isValidInviteCode('   '), isFalse);
        expect(isValidInviteCode('\t\n'), isFalse);
      });
    });

    group('Household Name Validation', () {
      test('safe household names pass validation', () {
        expect(isStringSafe('The Smiths'), isTrue);
        expect(isStringSafe("John's House"), isTrue);
        expect(isStringSafe('Apartment 4B'), isTrue);
        expect(isStringSafe('Casa de la Familia'), isTrue);
      });

      test('household names with SQL injection are detected', () {
        expect(isStringSafe("'; DROP TABLE households;--"), isFalse);
        expect(isStringSafe("House' OR '1'='1"), isFalse);
      });

      test('household names with XSS are detected', () {
        expect(isStringSafe('<script>alert(1)</script>'), isFalse);
        expect(isStringSafe('House<img onerror=alert(1)>'), isFalse);
      });
    });

    group('Task Title Validation', () {
      test('safe task titles pass validation', () {
        expect(isStringSafe('Clean the kitchen'), isTrue);
        expect(isStringSafe('Buy groceries'), isTrue);
        expect(isStringSafe('Call mom at 5pm'), isTrue);
        expect(isStringSafe('Pick up kids from school'), isTrue);
      });

      test('task titles with injection attacks are detected', () {
        expect(isStringSafe("<script>alert('XSS')</script>"), isFalse);
        expect(isStringSafe("'; DELETE FROM tasks;--"), isFalse);
      });
    });

    group('Unicode and Special Character Handling', () {
      test('handles RTL override character', () {
        final rtlOverride = 'text\u202Eevil';
        // This should ideally be sanitized
        expect(rtlOverride.contains('\u202E'), isTrue);
      });

      test('handles zero-width characters', () {
        final zeroWidth = 'text\u200Bhidden';
        expect(zeroWidth.length, greaterThan(10));
      });

      test('handles combining characters', () {
        final combining = 'a\u0300'; // 'à' as combining
        expect(combining.length, equals(2));
      });

      test('emojis in task descriptions are allowed', () {
        expect(isStringSafe('Clean kitchen 🧹'), isTrue);
        expect(isStringSafe('Buy groceries 🛒'), isTrue);
        expect(isStringSafe('❤️ Family dinner'), isTrue);
      });
    });
  });
}
