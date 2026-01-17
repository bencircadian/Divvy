import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_notification.dart';
import '../models/notification_preferences.dart';
import '../services/supabase_service.dart';

class NotificationProvider extends ChangeNotifier {
  List<AppNotification> _notifications = [];
  NotificationPreferences? _preferences;
  bool _isLoading = false;
  RealtimeChannel? _notificationsChannel;

  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  List<AppNotification> get unreadNotifications =>
      _notifications.where((n) => !n.read).toList();
  int get unreadCount => unreadNotifications.length;
  NotificationPreferences? get preferences => _preferences;
  bool get isLoading => _isLoading;

  Future<void> loadNotifications() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final response = await SupabaseService.client
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);

      _notifications = (response as List)
          .map((json) => AppNotification.fromJson(json))
          .toList();

      // Subscribe to realtime updates
      _subscribeToNotifications(userId);
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  void _subscribeToNotifications(String userId) {
    _notificationsChannel?.unsubscribe();

    _notificationsChannel = SupabaseService.client
        .channel('notifications:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            final newNotification = AppNotification.fromJson(payload.newRecord);
            _notifications.insert(0, newNotification);
            notifyListeners();
          },
        )
        .subscribe();
  }

  Future<void> loadPreferences() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return;

    try {
      final response = await SupabaseService.client
          .from('notification_preferences')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null) {
        _preferences = NotificationPreferences.fromJson(response);
      } else {
        // Create default preferences
        _preferences = NotificationPreferences(userId: userId);
        await savePreferences(_preferences!);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading preferences: $e');
    }
  }

  Future<void> savePreferences(NotificationPreferences prefs) async {
    try {
      await SupabaseService.client
          .from('notification_preferences')
          .upsert(prefs.toJson());
      _preferences = prefs;
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving preferences: $e');
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await SupabaseService.client
          .from('notifications')
          .update({'read': true})
          .eq('id', notificationId);

      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(read: true);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return;

    try {
      await SupabaseService.client
          .from('notifications')
          .update({'read': true})
          .eq('user_id', userId)
          .eq('read', false);

      _notifications = _notifications
          .map((n) => n.copyWith(read: true))
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error marking all as read: $e');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await SupabaseService.client
          .from('notifications')
          .delete()
          .eq('id', notificationId);

      _notifications.removeWhere((n) => n.id == notificationId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  Future<void> clearAllNotifications() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return;

    try {
      await SupabaseService.client
          .from('notifications')
          .delete()
          .eq('user_id', userId);

      _notifications.clear();
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing notifications: $e');
    }
  }

  @override
  void dispose() {
    _notificationsChannel?.unsubscribe();
    super.dispose();
  }
}
