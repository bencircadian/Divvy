import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_profile.dart';
import '../services/supabase_service.dart';

enum AuthStatus { initial, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.initial;
  User? _user;
  UserProfile? _profile;
  String? _errorMessage;
  bool _isLoading = false;

  StreamSubscription<AuthState>? _authSubscription;

  AuthStatus get status => _status;
  User? get user => _user;
  UserProfile? get profile => _profile;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  /// Get list of linked identity providers for current user
  List<String> get linkedProviders {
    return _user?.identities?.map((i) => i.provider).toList() ?? [];
  }

  /// Check if a specific provider is linked
  bool hasProvider(String provider) {
    return linkedProviders.contains(provider);
  }

  /// Check if user has email/password identity
  bool get hasEmailIdentity => hasProvider('email');

  /// Check if user has Google identity
  bool get hasGoogleIdentity => hasProvider('google');

  /// Check if user has Apple identity
  bool get hasAppleIdentity => hasProvider('apple');

  AuthProvider() {
    _init();
  }

  void _init() {
    _user = SupabaseService.currentUser;
    _status = _user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated;

    _authSubscription = SupabaseService.authStateChanges.listen((data) {
      final event = data.event;
      final session = data.session;

      if (event == AuthChangeEvent.signedIn && session != null) {
        _user = session.user;
        _status = AuthStatus.authenticated;
        _loadProfile();
      } else if (event == AuthChangeEvent.signedOut) {
        _user = null;
        _profile = null;
        _status = AuthStatus.unauthenticated;
      }
      notifyListeners();
    });

    if (_user != null) {
      _loadProfile();
    }
  }

  Future<void> _loadProfile() async {
    if (_user == null) return;

    // Extract OAuth profile data (Google/Apple provide these)
    final metadata = _user!.userMetadata;
    final oauthAvatarUrl = metadata?['avatar_url'] as String? ??
        metadata?['picture'] as String?; // Google uses 'picture'
    final oauthDisplayName = metadata?['display_name'] as String? ??
        metadata?['full_name'] as String? ??
        metadata?['name'] as String?;

    try {
      final response = await SupabaseService.client
          .from('profiles')
          .select()
          .eq('id', _user!.id)
          .maybeSingle();

      if (response != null) {
        _profile = UserProfile.fromJson(response);

        // Update avatar from OAuth if profile doesn't have one
        if (_profile!.avatarUrl == null && oauthAvatarUrl != null) {
          await SupabaseService.client.from('profiles').update({
            'avatar_url': oauthAvatarUrl,
          }).eq('id', _user!.id);
          _profile = _profile!.copyWith(avatarUrl: oauthAvatarUrl);
        }
      } else {
        // Profile doesn't exist (e.g., email verification flow) - create it
        await SupabaseService.client.from('profiles').upsert({
          'id': _user!.id,
          'display_name': oauthDisplayName,
          'avatar_url': oauthAvatarUrl,
          'created_at': DateTime.now().toIso8601String(),
        });
        // Load the newly created profile
        final newProfile = await SupabaseService.client
            .from('profiles')
            .select()
            .eq('id', _user!.id)
            .maybeSingle();
        if (newProfile != null) {
          _profile = UserProfile.fromJson(newProfile);
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading/creating profile: $e');
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await SupabaseService.client.auth.signUp(
        email: email,
        password: password,
        data: {'display_name': displayName},
      );

      if (response.user != null) {
        // Profile will be created on first login (after email verification)
        // via _loadProfile() which handles missing profiles
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
        return true;
      }

      _errorMessage = 'Sign up failed. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await SupabaseService.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _errorMessage = 'Sign in failed. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await SupabaseService.client.auth.signOut();
  }

  /// Sign in with Google using native SDK on mobile, OAuth redirect on web
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (kIsWeb) {
        // Use OAuth redirect flow for web
        await SupabaseService.client.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: kIsWeb ? null : 'io.supabase.divvy://login-callback/',
        );
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        // Use native Google Sign In for mobile
        // Note: You need to configure your Google Cloud Console with your app's
        // iOS client ID and Android client ID
        const webClientId = String.fromEnvironment(
          'GOOGLE_WEB_CLIENT_ID',
          defaultValue: '',
        );
        const iosClientId = String.fromEnvironment(
          'GOOGLE_IOS_CLIENT_ID',
          defaultValue: '',
        );

        final googleSignIn = GoogleSignIn(
          clientId: iosClientId.isNotEmpty ? iosClientId : null,
          serverClientId: webClientId.isNotEmpty ? webClientId : null,
        );

        final googleUser = await googleSignIn.signIn();
        if (googleUser == null) {
          _errorMessage = 'Google sign in was cancelled';
          _isLoading = false;
          notifyListeners();
          return false;
        }

        final googleAuth = await googleUser.authentication;
        final accessToken = googleAuth.accessToken;
        final idToken = googleAuth.idToken;

        if (accessToken == null || idToken == null) {
          _errorMessage = 'Failed to get Google authentication tokens';
          _isLoading = false;
          notifyListeners();
          return false;
        }

        final response = await SupabaseService.client.auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: idToken,
          accessToken: accessToken,
        );

        if (response.user != null) {
          _isLoading = false;
          notifyListeners();
          return true;
        }

        _errorMessage = 'Google sign in failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to sign in with Google: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign in with Apple using native SDK
  Future<bool> signInWithApple() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (kIsWeb) {
        // Use OAuth redirect flow for web
        await SupabaseService.client.auth.signInWithOAuth(
          OAuthProvider.apple,
          redirectTo: kIsWeb ? null : 'io.supabase.divvy://login-callback/',
        );
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        // Generate a random nonce for security
        final rawNonce = _generateNonce();
        final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

        final credential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
          nonce: hashedNonce,
        );

        final idToken = credential.identityToken;
        if (idToken == null) {
          _errorMessage = 'Failed to get Apple ID token';
          _isLoading = false;
          notifyListeners();
          return false;
        }

        final response = await SupabaseService.client.auth.signInWithIdToken(
          provider: OAuthProvider.apple,
          idToken: idToken,
          nonce: rawNonce,
        );

        if (response.user != null) {
          // Apple only returns name on first sign-in, so save it if available
          if (credential.givenName != null || credential.familyName != null) {
            final displayName = [credential.givenName, credential.familyName]
                .where((s) => s != null && s.isNotEmpty)
                .join(' ');
            if (displayName.isNotEmpty) {
              await updateProfile(displayName: displayName);
            }
          }
          _isLoading = false;
          notifyListeners();
          return true;
        }

        _errorMessage = 'Apple sign in failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        _errorMessage = 'Apple sign in was cancelled';
      } else {
        _errorMessage = 'Apple sign in error: ${e.message}';
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to sign in with Apple: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Generates a random nonce string for Apple Sign In
  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  Future<bool> updateProfile({String? displayName, String? avatarUrl}) async {
    if (_user == null) return false;

    try {
      final updates = <String, dynamic>{};
      if (displayName != null) updates['display_name'] = displayName;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

      await SupabaseService.client
          .from('profiles')
          .update(updates)
          .eq('id', _user!.id);

      await _loadProfile();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update profile.';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ============ Identity Linking Methods ============

  /// Link Google identity to current account (triggers OAuth redirect)
  Future<bool> linkGoogleIdentity() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await SupabaseService.client.auth.linkIdentity(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'io.supabase.divvy://login-callback/',
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to link Google account: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Link Apple identity to current account (triggers OAuth redirect)
  Future<bool> linkAppleIdentity() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await SupabaseService.client.auth.linkIdentity(
        OAuthProvider.apple,
        redirectTo: kIsWeb ? null : 'io.supabase.divvy://login-callback/',
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to link Apple account: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Unlink an identity provider (must have at least 2 identities)
  Future<bool> unlinkIdentity(String provider) async {
    if (linkedProviders.length <= 1) {
      _errorMessage = 'Cannot unlink your only sign-in method';
      notifyListeners();
      return false;
    }

    final identity = _user?.identities?.firstWhere(
      (i) => i.provider == provider,
      orElse: () => throw Exception('Identity not found'),
    );

    if (identity == null) {
      _errorMessage = 'Identity not found';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await SupabaseService.client.auth.unlinkIdentity(identity);
      // Refresh user to get updated identities
      final session = SupabaseService.client.auth.currentSession;
      if (session != null) {
        _user = session.user;
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to unlink account: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Get email associated with a specific identity provider
  String? getIdentityEmail(String provider) {
    final identity = _user?.identities?.firstWhere(
      (i) => i.provider == provider,
      orElse: () => throw Exception('Not found'),
    );
    return identity?.identityData?['email'] as String?;
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
