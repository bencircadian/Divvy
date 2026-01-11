import 'package:flutter/foundation.dart';

import '../models/app_notification.dart';
import 'supabase_service.dart';

/// Service for creating notifications without provider dependencies.
/// This decouples TaskProvider from NotificationProvider.
class NotificationService {
  /// Create a single notification
  static Future<void> createNotification({
    required String userId,
    required NotificationType type,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      await SupabaseService.client.from('notifications').insert({
        'user_id': userId,
        'type': AppNotification.typeToString(type),
        'title': title,
        'body': body,
        'data': data ?? {},
      });
    } catch (e) {
      debugPrint('Error creating notification: $e');
    }
  }

  /// Create multiple notifications in a single batch insert
  static Future<void> createNotificationBatch(List<Map<String, dynamic>> notifications) async {
    if (notifications.isEmpty) return;

    try {
      await SupabaseService.client.from('notifications').insert(notifications);
    } catch (e) {
      debugPrint('Error creating notification batch: $e');
    }
  }

  /// Helper to build notification data for batch insert
  static Map<String, dynamic> buildNotificationData({
    required String userId,
    required NotificationType type,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) {
    return {
      'user_id': userId,
      'type': AppNotification.typeToString(type),
      'title': title,
      'body': body,
      'data': data ?? {},
    };
  }
}
