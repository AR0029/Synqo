class TaskModel {
  final String id;
  final String listId;
  final String title;
  final String? description;
  final bool isCompleted;
  final String? priority;
  final DateTime? dueDate;
  final String? blockedById;
  final DateTime? createdAt;

  TaskModel({
    required this.id,
    required this.listId,
    required this.title,
    this.description,
    required this.isCompleted,
    this.priority,
    this.dueDate,
    this.blockedById,
    this.createdAt,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      listId: json['list_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      isCompleted: json['is_completed'] as bool? ?? false,
      priority: json['priority'] as String?,
      dueDate: json['due_date'] != null ? DateTime.tryParse(json['due_date'] as String) : null,
      blockedById: json['blocked_by_id'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
    );
  }

  TaskModel copyWith({
    String? id,
    String? listId,
    String? title,
    String? description,
    bool? isCompleted,
    String? priority,
    DateTime? dueDate,
    String? blockedById,
    DateTime? createdAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      listId: listId ?? this.listId,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      blockedById: blockedById ?? this.blockedById,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
