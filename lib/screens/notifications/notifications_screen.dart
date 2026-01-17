import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/app_notification.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/common/empty_state.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notificationProvider = context.watch<NotificationProvider>();
    final notifications = notificationProvider.notifications;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Notifications'),
        actions: [
          if (notificationProvider.unreadCount > 0)
            TextButton(
              onPressed: notificationProvider.markAllAsRead,
              child: const Text('Mark all read'),
            ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clear') {
                _showClearConfirmation();
              } else if (value == 'settings') {
                context.push('/notifications/settings');
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings, size: 20),
                    SizedBox(width: 8),
                    Text('Settings'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep, size: 20),
                    SizedBox(width: 8),
                    Text('Clear all'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: notificationProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
              ? _buildEmptyState()
              : _buildNotificationList(notifications),
    );
  }

  Widget _buildEmptyState() {
    return const EmptyState(
      icon: Icons.notifications_none,
      title: 'No notifications yet',
      subtitle: "You'll see updates about your tasks here",
    );
  }

  Widget _buildNotificationList(List<AppNotification> notifications) {
    return ListView.builder(
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return _NotificationTile(
          key: ValueKey(notification.id),
          notification: notification,
          onTap: () => _handleNotificationTap(notification),
          onDismiss: () => _dismissNotification(notification),
        );
      },
    );
  }

  void _handleNotificationTap(AppNotification notification) {
    // Mark as read
    if (!notification.read) {
      context.read<NotificationProvider>().markAsRead(notification.id);
    }

    // Navigate to related task if available
    final taskId = notification.data['task_id'] as String?;
    if (taskId != null) {
      context.push('/task/$taskId');
    }
  }

  void _dismissNotification(AppNotification notification) {
    context.read<NotificationProvider>().deleteNotification(notification.id);
  }

  void _showClearConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all notifications'),
        content: const Text('Are you sure you want to delete all notifications?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<NotificationProvider>().clearAllNotifications();
            },
            child: const Text('Clear all'),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  IconData _getIcon() {
    switch (notification.type) {
      case NotificationType.taskAssigned:
        return Icons.person_add;
      case NotificationType.taskCompleted:
        return Icons.check_circle;
      case NotificationType.mentioned:
        return Icons.alternate_email;
      case NotificationType.dueReminder:
        return Icons.alarm;
      case NotificationType.appreciation:
        return Icons.favorite;
    }
  }

  Color _getIconColor(BuildContext context) {
    switch (notification.type) {
      case NotificationType.taskAssigned:
        return Colors.blue;
      case NotificationType.taskCompleted:
        return Colors.green;
      case NotificationType.mentioned:
        return Colors.purple;
      case NotificationType.dueReminder:
        return Colors.orange;
      case NotificationType.appreciation:
        return Colors.pink;
    }
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateDay = DateTime(date.year, date.month, date.day);

    final timeStr = DateFormat('h:mm a').format(date).toLowerCase();

    if (dateDay == today) {
      return timeStr;
    } else if (dateDay == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM d').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: ListTile(
        onTap: onTap,
        tileColor: notification.read
            ? null
            : Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
        leading: CircleAvatar(
          backgroundColor: _getIconColor(context).withValues(alpha: 0.15),
          child: Icon(
            _getIcon(),
            color: _getIconColor(context),
            size: 20,
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.read ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Text(
          notification.body,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatTime(notification.createdAt),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            if (!notification.read)
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
