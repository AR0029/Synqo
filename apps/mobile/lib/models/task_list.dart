class TaskList {
  final String id;
  final String title;
  final String ownerId;
  final bool isShared;

  TaskList({
    required this.id,
    required this.title,
    required this.ownerId,
    required this.isShared,
  });

  factory TaskList.fromJson(Map<String, dynamic> json) {
    return TaskList(
      id: json['id'] as String,
      title: json['title'] as String,
      ownerId: json['owner_id'] as String,
      isShared: json['is_shared'] as bool? ?? false,
    );
  }
}
