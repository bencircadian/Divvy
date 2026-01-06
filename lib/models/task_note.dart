class TaskNote {
  final String id;
  final String taskId;
  final String userId;
  final String content;
  final DateTime createdAt;
  final String? userName;

  TaskNote({
    required this.id,
    required this.taskId,
    required this.userId,
    required this.content,
    required this.createdAt,
    this.userName,
  });

  factory TaskNote.fromJson(Map<String, dynamic> json) {
    return TaskNote(
      id: json['id'] as String,
      taskId: json['task_id'] as String,
      userId: json['user_id'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      userName: json['profiles']?['display_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_id': taskId,
      'user_id': userId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
