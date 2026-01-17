enum TaskAction {
  created,
  completed,
  uncompleted,
  edited,
  assigned,
  noteAdded,
}

class TaskHistory {
  final String id;
  final String taskId;
  final String userId;
  final TaskAction action;
  final Map<String, dynamic>? details;
  final DateTime createdAt;
  final String? userName;

  TaskHistory({
    required this.id,
    required this.taskId,
    required this.userId,
    required this.action,
    this.details,
    required this.createdAt,
    this.userName,
  });

  factory TaskHistory.fromJson(Map<String, dynamic> json) {
    return TaskHistory(
      id: json['id'] as String,
      taskId: json['task_id'] as String,
      userId: json['user_id'] as String,
      action: _parseAction(json['action'] as String),
      details: json['details'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
      userName: json['profiles']?['display_name'] as String?,
    );
  }

  static TaskAction _parseAction(String action) {
    switch (action) {
      case 'created':
        return TaskAction.created;
      case 'completed':
        return TaskAction.completed;
      case 'uncompleted':
        return TaskAction.uncompleted;
      case 'edited':
        return TaskAction.edited;
      case 'assigned':
        return TaskAction.assigned;
      case 'note_added':
        return TaskAction.noteAdded;
      default:
        return TaskAction.created;
    }
  }

  String get actionText {
    switch (action) {
      case TaskAction.created:
        return 'created this task';
      case TaskAction.completed:
        return 'completed this task';
      case TaskAction.uncompleted:
        return 'marked as pending';
      case TaskAction.edited:
        return 'edited this task';
      case TaskAction.assigned:
        final assignee = details?['assignee_name'] as String?;
        if (assignee != null) {
          return 'assigned to $assignee';
        }
        return 'unassigned this task';
      case TaskAction.noteAdded:
        return 'added a note';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_id': taskId,
      'user_id': userId,
      'action': action.name,
      'details': details,
      'created_at': createdAt.toIso8601String(),
    };
  }

  TaskHistory copyWith({
    String? id,
    String? taskId,
    String? userId,
    TaskAction? action,
    Map<String, dynamic>? details,
    DateTime? createdAt,
    String? userName,
  }) {
    return TaskHistory(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      userId: userId ?? this.userId,
      action: action ?? this.action,
      details: details ?? this.details,
      createdAt: createdAt ?? this.createdAt,
      userName: userName ?? this.userName,
    );
  }
}
