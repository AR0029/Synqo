class TaskModel {
  final String id;
  final String listId;
  final String title;
  final String? description;
  final bool isCompleted;
  final String? priority;

  TaskModel({
    required this.id,
    required this.listId,
    required this.title,
    this.description,
    required this.isCompleted,
    this.priority,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      listId: json['list_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      isCompleted: json['is_completed'] as bool? ?? false,
      priority: json['priority'] as String?,
    );
  }
}
