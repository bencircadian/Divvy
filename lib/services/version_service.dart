import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// Conditional import for web
import 'version_service_stub.dart'
    if (dart.library.html) 'version_service_web.dart' as platform;

/// Service for checking app version and detecting updates.
class VersionService {
  static final VersionService _instance = VersionService._internal();
  factory VersionService() => _instance;
  VersionService._internal();

  /// Current app build number (increment this with each deploy).
  static const int currentBuildNumber = 7;

  /// Stream controller for update availability.
  final _updateAvailableController = StreamController<bool>.broadcast();

  /// Stream that emits true when an update is available.
  Stream<bool> get updateAvailable => _updateAvailableController.stream;

  Timer? _checkTimer;
  bool _updateDetected = false;

  /// Whether an update has been detected.
  bool get hasUpdate => _updateDetected;

  /// Start periodic version checks.
  void startChecking({Duration interval = const Duration(minutes: 5)}) {
    // Only check on web platform
    if (!kIsWeb) return;

    // Check immediately
    checkForUpdate();

    // Then check periodically
    _checkTimer?.cancel();
    _checkTimer = Timer.periodic(interval, (_) => checkForUpdate());
  }

  /// Stop version checking.
  void stopChecking() {
    _checkTimer?.cancel();
    _checkTimer = null;
  }

  /// Check for updates manually.
  Future<bool> checkForUpdate() async {
    if (!kIsWeb) return false;

    try {
      // Add cache-busting query param
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final response = await http.get(
        Uri.parse('/version.json?_=$timestamp'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final remoteBuildNumber = data['buildNumber'] as int? ?? 0;

        if (remoteBuildNumber > currentBuildNumber) {
          _updateDetected = true;
          _updateAvailableController.add(true);
          return true;
        }
      }
    } catch (e) {
      debugPrint('Version check failed: $e');
    }

    return false;
  }

  /// Reload the app to get the latest version.
  void reloadApp() {
    platform.reloadPage();
  }

  /// Dispose resources.
  void dispose() {
    stopChecking();
    _updateAvailableController.close();
  }
}
