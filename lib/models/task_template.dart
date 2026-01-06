class TaskTemplate {
  final String id;
  final String category;
  final String title;
  final String? description;
  final Map<String, dynamic>? suggestedRecurrence;
  final bool isSystem;

  TaskTemplate({
    required this.id,
    required this.category,
    required this.title,
    this.description,
    this.suggestedRecurrence,
    this.isSystem = true,
  });

  factory TaskTemplate.fromJson(Map<String, dynamic> json) {
    return TaskTemplate(
      id: json['id'] as String,
      category: json['category'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      suggestedRecurrence: json['suggested_recurrence'] as Map<String, dynamic>?,
      isSystem: json['is_system'] as bool? ?? true,
    );
  }

  String get categoryDisplayName {
    switch (category) {
      case 'kitchen':
        return 'Kitchen';
      case 'bathroom':
        return 'Bathroom';
      case 'living':
        return 'Living Areas';
      case 'outdoor':
        return 'Outdoor';
      case 'pet':
        return 'Pet Care';
      case 'children':
        return 'Children';
      case 'laundry':
        return 'Laundry';
      case 'grocery':
        return 'Grocery & Meals';
      case 'maintenance':
        return 'Maintenance';
      case 'admin':
        return 'Finance & Admin';
      default:
        return category;
    }
  }

  String get categoryIconPath {
    switch (category) {
      case 'kitchen':
        return 'assets/icons/kitchen.svg';
      case 'bathroom':
        return 'assets/icons/bathroom.svg';
      case 'living':
        return 'assets/icons/living.svg';
      case 'outdoor':
        return 'assets/icons/outdoor.svg';
      case 'pet':
        return 'assets/icons/pet.svg';
      case 'children':
        return 'assets/icons/children.svg';
      case 'laundry':
        return 'assets/icons/laundry.svg';
      case 'grocery':
        return 'assets/icons/grocery.svg';
      case 'maintenance':
        return 'assets/icons/maintenance.svg';
      case 'admin':
        return 'assets/icons/admin.svg';
      default:
        return 'assets/icons/default.svg';
    }
  }

  bool get needsPetName => title.contains('{pet_name}') || (description?.contains('{pet_name}') ?? false);

  bool get needsChildName => title.contains('{child_name}') || (description?.contains('{child_name}') ?? false);
}
