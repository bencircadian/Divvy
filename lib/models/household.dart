class Household {
  final String id;
  final String name;
  final String inviteCode;
  final String createdBy;
  final DateTime createdAt;

  Household({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.createdBy,
    required this.createdAt,
  });

  factory Household.fromJson(Map<String, dynamic> json) {
    return Household(
      id: json['id'] as String,
      name: json['name'] as String,
      inviteCode: json['invite_code'] as String,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'invite_code': inviteCode,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Household copyWith({
    String? id,
    String? name,
    String? inviteCode,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return Household(
      id: id ?? this.id,
      name: name ?? this.name,
      inviteCode: inviteCode ?? this.inviteCode,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
