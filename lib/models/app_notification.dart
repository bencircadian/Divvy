enum NotificationType {
  taskAssigned,
  taskCompleted,
  mentioned,
  dueReminder,
}

class AppNotification {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final bool read;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.data = const {},
    this.read = false,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: _parseType(json['type'] as String),
      title: json['title'] as String,
      body: json['body'] as String,
      data: json['data'] as Map<String, dynamic>? ?? {},
      read: json['read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  static NotificationType _parseType(String type) {
    switch (type) {
      case 'task_assigned':
        return NotificationType.taskAssigned;
      case 'task_completed':
        return NotificationType.taskCompleted;
      case 'mentioned':
        return NotificationType.mentioned;
      case 'due_reminder':
        return NotificationType.dueReminder;
      default:
        return NotificationType.taskAssigned;
    }
  }

  static String typeToString(NotificationType type) {
    switch (type) {
      case NotificationType.taskAssigned:
        return 'task_assigned';
      case NotificationType.taskCompleted:
        return 'task_completed';
      case NotificationType.mentioned:
        return 'mentioned';
      case NotificationType.dueReminder:
        return 'due_reminder';
    }
  }

  AppNotification copyWith({bool? read}) {
    return AppNotification(
      id: id,
      userId: userId,
      type: type,
      title: title,
      body: body,
      data: data,
      read: read ?? this.read,
      createdAt: createdAt,
    );
  }
}
