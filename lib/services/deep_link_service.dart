import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  GoRouter? _router;

  Future<void> initialize(GoRouter router) async {
    _router = router;
    _appLinks = AppLinks();

    // Handle link when app is started from a link
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        _handleDeepLink(initialLink);
      }
    } catch (e) {
      debugPrint('Error getting initial link: $e');
    }

    // Handle links when app is already running
    _linkSubscription = _appLinks.uriLinkStream.listen(
      _handleDeepLink,
      onError: (error) {
        debugPrint('Deep link error: $error');
      },
    );
  }

  void _handleDeepLink(Uri uri) {
    debugPrint('Received deep link: $uri');

    // Handle different deep link schemes and paths
    // divvy://join/ABC123 -> Navigate to join household with code
    // io.supabase.divvy://login-callback -> Auth callback (handled by Supabase)

    if (uri.scheme == 'divvy') {
      final pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty && pathSegments[0] == 'join') {
        if (pathSegments.length > 1) {
          final code = pathSegments[1];
          _router?.go('/join-household?code=$code');
        } else {
          _router?.go('/join-household');
        }
      }
    }
    // Auth callbacks are handled automatically by Supabase
  }

  void dispose() {
    _linkSubscription?.cancel();
  }
}
