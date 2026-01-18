import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import 'supabase_service.dart';
import '../config/supabase_config.dart';

/// Background message handler - must be a top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase if needed (for background isolate)
  await Firebase.initializeApp();
  if (kDebugMode) {
    debugPrint('Background message received: ${message.messageId}');
  }
}

/// Service for handling push notifications via Firebase Cloud Messaging
class PushNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static String? _deviceToken;
  static bool _isInitialized = false;
  static GoRouter? _router;

  /// Get the current device token
  static String? get deviceToken => _deviceToken;

  /// Set the router for navigation on notification tap
  static void setRouter(GoRouter router) {
    _router = router;
  }

  /// Initialize push notifications
  static Future<void> initialize() async {
    if (_isInitialized) return;

    // Skip on web for now (can be enabled later with web push)
    if (kIsWeb) {
      if (kDebugMode) {
        debugPrint('Push notifications not supported on web yet');
      }
      return;
    }

    try {
      // Set up background message handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Request permission
      final settings = await _requestPermission();
      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        if (kDebugMode) {
          debugPrint('Push notification permission denied');
        }
        return;
      }

      // Get the device token
      await _getAndStoreToken();

      // Listen for token refresh
      _messaging.onTokenRefresh.listen(_onTokenRefresh);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification tap when app is in background/terminated
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Check if app was opened from a notification
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      _isInitialized = true;
      if (kDebugMode) {
        debugPrint('Push notifications initialized successfully');
      }
    } catch (e) {
      debugPrint('Error initializing push notifications: $e');
    }
  }

  /// Request notification permission
  static Future<NotificationSettings> _requestPermission() async {
    return await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
    );
  }

  /// Get device token and store in Supabase
  static Future<void> _getAndStoreToken() async {
    try {
      // For iOS, get APNs token first
      if (Platform.isIOS) {
        final apnsToken = await _messaging.getAPNSToken();
        if (apnsToken == null) {
          if (kDebugMode) {
            debugPrint('APNs token not available yet');
          }
          // Wait a bit and retry
          await Future.delayed(const Duration(seconds: 2));
        }
      }

      _deviceToken = await _messaging.getToken();
      if (_deviceToken != null) {
        if (kDebugMode) {
          debugPrint('Device token obtained: ${_deviceToken!.substring(0, 20)}...');
        }
        await _storeTokenInSupabase(_deviceToken!);
      }
    } catch (e) {
      debugPrint('Error getting device token: $e');
    }
  }

  /// Handle token refresh
  static Future<void> _onTokenRefresh(String newToken) async {
    if (kDebugMode) {
      debugPrint('Device token refreshed');
    }
    _deviceToken = newToken;
    await _storeTokenInSupabase(newToken);
  }

  /// Store device token in Supabase
  static Future<void> _storeTokenInSupabase(String token) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) {
      if (kDebugMode) {
        debugPrint('Cannot store token: user not logged in');
      }
      return;
    }

    try {
      // Upsert the device token
      await SupabaseService.client.from('device_tokens').upsert({
        'user_id': userId,
        'token': token,
        'platform': Platform.isIOS ? 'ios' : 'android',
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id, token');

      if (kDebugMode) {
        debugPrint('Device token stored in Supabase');
      }
    } catch (e) {
      debugPrint('Error storing device token: $e');
    }
  }

  /// Handle foreground messages
  static void _handleForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      debugPrint('Foreground message received: ${message.notification?.title}');
    }

    // The notification will automatically show on Android
    // For iOS, we might want to show a local notification or in-app alert
    // For now, we'll rely on the in-app notification system
  }

  /// Handle notification tap
  static void _handleNotificationTap(RemoteMessage message) {
    if (kDebugMode) {
      debugPrint('Notification tapped: ${message.data}');
    }

    // Navigate to relevant screen based on notification data
    final taskId = message.data['task_id'] as String?;
    if (taskId != null && _router != null) {
      _router!.go('/task/$taskId');
      if (kDebugMode) {
        debugPrint('Navigating to task: $taskId');
      }
    }
  }

  /// Remove device token (call on logout)
  static Future<void> removeToken() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null || _deviceToken == null) return;

    try {
      await SupabaseService.client
          .from('device_tokens')
          .delete()
          .eq('user_id', userId)
          .eq('token', _deviceToken!);

      if (kDebugMode) {
        debugPrint('Device token removed from Supabase');
      }
    } catch (e) {
      debugPrint('Error removing device token: $e');
    }
  }

  /// Check if push notifications are enabled
  static Future<bool> areNotificationsEnabled() async {
    if (kIsWeb) return false;

    final settings = await _messaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  /// Open app notification settings
  static Future<void> openSettings() async {
    await _messaging.requestPermission();
  }

  /// Send a push notification to a specific user via Supabase Edge Function
  static Future<bool> sendPushNotification({
    required String userId,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      final supabaseUrl = SupabaseService.client.rest.url.replaceAll('/rest/v1', '');

      final response = await http.post(
        Uri.parse('$supabaseUrl/functions/v1/send-push-notification'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${SupabaseConfig.anonKey}',
        },
        body: jsonEncode({
          'user_id': userId,
          'title': title,
          'body': body,
          'data': data ?? {},
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (kDebugMode) {
          debugPrint('Push notification sent: ${result['message']}');
        }
        return true;
      } else {
        if (kDebugMode) {
          debugPrint('Failed to send push notification: ${response.body}');
        }
        return false;
      }
    } catch (e) {
      debugPrint('Error sending push notification: $e');
      return false;
    }
  }
}
