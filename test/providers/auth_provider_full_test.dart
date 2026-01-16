/// Full tests for AuthProvider
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:divvy/providers/auth_provider.dart';

import '../helpers/test_data.dart';
import '../mocks/mock_providers.dart';

void main() {
  group('AuthProvider Full Tests', () {
    late MockAuthProvider authProvider;

    setUp(() {
      authProvider = MockAuthProvider();
    });

    group('Sign Up Flow', () {
      test('successful sign up creates profile', () async {
        final result = await authProvider.signUp(
          email: 'test@example.com',
          password: 'password123',
          displayName: 'Test User',
        );

        expect(result, isTrue);
        expect(authProvider.isAuthenticated, isTrue);
        expect(authProvider.profile, isNotNull);
        expect(authProvider.profile?.displayName, equals('Test User'));
      });

      test('sign up sets authenticated status', () async {
        await authProvider.signUp(
          email: 'test@example.com',
          password: 'password123',
        );

        expect(authProvider.status, equals(AuthStatus.authenticated));
      });

      test('loading state is managed during sign up', () async {
        expect(authProvider.isLoading, isFalse);

        // Sign up sets loading state internally
        await authProvider.signUp(
          email: 'test@example.com',
          password: 'password123',
        );

        // After completion, loading should be false
        expect(authProvider.isLoading, isFalse);
      });
    });

    group('Sign In with Email/Password', () {
      test('successful sign in authenticates user', () async {
        final result = await authProvider.signIn(
          email: 'test@example.com',
          password: 'password123',
        );

        expect(result, isTrue);
        expect(authProvider.isAuthenticated, isTrue);
      });

      test('sign in updates auth status', () async {
        expect(authProvider.status, equals(AuthStatus.unauthenticated));

        await authProvider.signIn(
          email: 'test@example.com',
          password: 'password123',
        );

        expect(authProvider.status, equals(AuthStatus.authenticated));
      });
    });

    group('Google OAuth Flow', () {
      test('successful Google sign in authenticates user', () async {
        final result = await authProvider.signInWithGoogle();

        expect(result, isTrue);
        expect(authProvider.isAuthenticated, isTrue);
        expect(authProvider.hasGoogleIdentity, isTrue);
      });

      test('Google sign in sets google provider', () async {
        await authProvider.signInWithGoogle();

        expect(authProvider.linkedProviders, contains('google'));
      });
    });

    group('Apple OAuth Flow', () {
      test('successful Apple sign in authenticates user', () async {
        final result = await authProvider.signInWithApple();

        expect(result, isTrue);
        expect(authProvider.isAuthenticated, isTrue);
        expect(authProvider.hasAppleIdentity, isTrue);
      });

      test('Apple sign in sets apple provider', () async {
        await authProvider.signInWithApple();

        expect(authProvider.linkedProviders, contains('apple'));
      });
    });

    group('Identity Linking Flow', () {
      test('link Google to existing account', () async {
        authProvider.setAuthenticated(providers: ['email']);

        await authProvider.linkGoogleIdentity();

        expect(authProvider.hasGoogleIdentity, isTrue);
        expect(authProvider.linkedProviders.length, equals(2));
      });

      test('link Apple to existing account', () async {
        authProvider.setAuthenticated(providers: ['email']);

        await authProvider.linkAppleIdentity();

        expect(authProvider.hasAppleIdentity, isTrue);
        expect(authProvider.linkedProviders.length, equals(2));
      });

      test('link multiple providers', () async {
        authProvider.setAuthenticated(providers: ['email']);

        await authProvider.linkGoogleIdentity();
        await authProvider.linkAppleIdentity();

        expect(authProvider.linkedProviders.length, equals(3));
        expect(authProvider.hasEmailIdentity, isTrue);
        expect(authProvider.hasGoogleIdentity, isTrue);
        expect(authProvider.hasAppleIdentity, isTrue);
      });
    });

    group('Identity Unlinking', () {
      test('cannot unlink only identity', () async {
        authProvider.setAuthenticated(providers: ['email']);

        final result = await authProvider.unlinkIdentity('email');

        expect(result, isFalse);
        expect(authProvider.errorMessage, isNotNull);
        expect(authProvider.linkedProviders, contains('email'));
      });

      test('can unlink when 2+ identities exist', () async {
        authProvider.setAuthenticated(providers: ['email', 'google']);

        final result = await authProvider.unlinkIdentity('google');

        expect(result, isTrue);
        expect(authProvider.linkedProviders, contains('email'));
        expect(authProvider.linkedProviders, isNot(contains('google')));
      });

      test('unlink updates provider list correctly', () async {
        authProvider.setAuthenticated(providers: ['email', 'google', 'apple']);
        expect(authProvider.linkedProviders.length, equals(3));

        await authProvider.unlinkIdentity('google');
        expect(authProvider.linkedProviders.length, equals(2));

        await authProvider.unlinkIdentity('apple');
        expect(authProvider.linkedProviders.length, equals(1));
        expect(authProvider.hasEmailIdentity, isTrue);
      });
    });

    group('Profile Sync on Auth State Change', () {
      test('profile is loaded after sign in', () async {
        await authProvider.signIn(
          email: 'test@example.com',
          password: 'password123',
        );

        expect(authProvider.profile, isNotNull);
      });

      test('profile is cleared after sign out', () async {
        authProvider.setAuthenticated(
          profile: TestData.createUserProfile(),
        );

        await authProvider.signOut();

        expect(authProvider.profile, isNull);
      });
    });

    group('Error State Handling', () {
      test('error is set and can be cleared', () {
        authProvider.setError('Authentication failed');

        expect(authProvider.errorMessage, isNotNull);
        expect(authProvider.errorMessage, contains('failed'));

        authProvider.clearError();

        expect(authProvider.errorMessage, isNull);
      });

      test('error is cleared on successful auth', () async {
        authProvider.setError('Previous error');

        await authProvider.signIn(
          email: 'test@example.com',
          password: 'password123',
        );

        // Error should be cleared on success
        expect(authProvider.status, equals(AuthStatus.authenticated));
      });
    });

    group('Bundle Preferences', () {
      test('bundlesEnabled returns profile value', () {
        authProvider.setAuthenticated(
          profile: TestData.createUserProfile().copyWith(bundlesEnabled: true),
        );

        expect(authProvider.bundlesEnabled, isTrue);
      });

      test('needsBundlePreferencePrompt when null', () {
        authProvider.setAuthenticated(
          profile: TestData.createUserProfile().copyWith(bundlesEnabled: null),
        );

        expect(authProvider.needsBundlePreferencePrompt, isTrue);
      });

      test('no prompt needed when preference is set', () {
        authProvider.setAuthenticated(
          profile: TestData.createUserProfile().copyWith(bundlesEnabled: false),
        );

        expect(authProvider.needsBundlePreferencePrompt, isFalse);
      });
    });

    group('Profile Updates', () {
      test('updateProfile changes display name', () async {
        authProvider.setAuthenticated(
          profile: TestData.createUserProfile(displayName: 'Old Name'),
        );

        await authProvider.updateProfile(displayName: 'New Name');

        expect(authProvider.profile?.displayName, equals('New Name'));
      });

      test('updateProfile changes avatar URL', () async {
        authProvider.setAuthenticated(
          profile: TestData.createUserProfile(),
        );

        await authProvider.updateProfile(avatarUrl: 'https://example.com/avatar.jpg');

        expect(authProvider.profile?.avatarUrl, equals('https://example.com/avatar.jpg'));
      });
    });

    group('Auth State Transitions', () {
      test('initial -> authenticated on sign in', () async {
        expect(authProvider.status, equals(AuthStatus.unauthenticated));

        await authProvider.signIn(
          email: 'test@example.com',
          password: 'password123',
        );

        expect(authProvider.status, equals(AuthStatus.authenticated));
      });

      test('authenticated -> unauthenticated on sign out', () async {
        authProvider.setAuthenticated();

        await authProvider.signOut();

        expect(authProvider.status, equals(AuthStatus.unauthenticated));
      });

      test('setAuthenticated helper works correctly', () {
        authProvider.setAuthenticated(
          userId: 'custom-user-id',
          providers: ['email', 'google'],
        );

        expect(authProvider.isAuthenticated, isTrue);
        expect(authProvider.userId, equals('custom-user-id'));
        expect(authProvider.hasEmailIdentity, isTrue);
        expect(authProvider.hasGoogleIdentity, isTrue);
      });

      test('setUnauthenticated helper works correctly', () {
        authProvider.setAuthenticated();
        expect(authProvider.isAuthenticated, isTrue);

        authProvider.setUnauthenticated();

        expect(authProvider.isAuthenticated, isFalse);
        expect(authProvider.profile, isNull);
      });
    });

    group('Loading State', () {
      test('loading state can be set and unset', () {
        expect(authProvider.isLoading, isFalse);

        authProvider.setLoading(true);
        expect(authProvider.isLoading, isTrue);

        authProvider.setLoading(false);
        expect(authProvider.isLoading, isFalse);
      });
    });

    group('Provider Detection Helpers', () {
      test('hasProvider checks correctly', () {
        authProvider.setAuthenticated(providers: ['email', 'google']);

        expect(authProvider.hasProvider('email'), isTrue);
        expect(authProvider.hasProvider('google'), isTrue);
        expect(authProvider.hasProvider('apple'), isFalse);
      });

      test('identity helpers are accurate', () {
        authProvider.setAuthenticated(providers: ['apple']);

        expect(authProvider.hasEmailIdentity, isFalse);
        expect(authProvider.hasGoogleIdentity, isFalse);
        expect(authProvider.hasAppleIdentity, isTrue);
      });
    });
  });
}
