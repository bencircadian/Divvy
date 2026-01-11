/// Represents an appreciation/thanks given for completing a task.
class Appreciation {
  final String id;
  final String taskId;
  final String fromUserId;
  final String toUserId;
  final String reactionType;
  final DateTime createdAt;

  /// Optional task title for display purposes.
  final String? taskTitle;

  /// Optional sender display name.
  final String? fromUserName;

  const Appreciation({
    required this.id,
    required this.taskId,
    required this.fromUserId,
    required this.toUserId,
    this.reactionType = 'thanks',
    required this.createdAt,
    this.taskTitle,
    this.fromUserName,
  });

  factory Appreciation.fromJson(Map<String, dynamic> json) {
    return Appreciation(
      id: json['id'] as String,
      taskId: json['task_id'] as String,
      fromUserId: json['from_user_id'] as String,
      toUserId: json['to_user_id'] as String,
      reactionType: json['reaction_type'] as String? ?? 'thanks',
      createdAt: DateTime.parse(json['created_at'] as String),
      taskTitle: json['task_title'] as String?,
      fromUserName: json['from_user_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_id': taskId,
      'from_user_id': fromUserId,
      'to_user_id': toUserId,
      'reaction_type': reactionType,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Get the reaction emoji based on type.
  String get emoji {
    switch (reactionType) {
      case 'thanks':
        return '🙏';
      case 'heart':
        return '❤️';
      case 'star':
        return '⭐';
      case 'clap':
        return '👏';
      case 'thumbsup':
        return '👍';
      default:
        return '🙏';
    }
  }

  /// Get the reaction display text.
  String get displayText {
    switch (reactionType) {
      case 'thanks':
        return 'said thanks';
      case 'heart':
        return 'sent love';
      case 'star':
        return 'gave a star';
      case 'clap':
        return 'applauded';
      case 'thumbsup':
        return 'gave a thumbs up';
      default:
        return 'said thanks';
    }
  }

  /// Available reaction types.
  static const List<String> reactionTypes = [
    'thanks',
    'heart',
    'star',
    'clap',
    'thumbsup',
  ];

  /// Get emoji for a reaction type.
  static String getEmoji(String type) {
    switch (type) {
      case 'thanks':
        return '🙏';
      case 'heart':
        return '❤️';
      case 'star':
        return '⭐';
      case 'clap':
        return '👏';
      case 'thumbsup':
        return '👍';
      default:
        return '🙏';
    }
  }
}
