class Task {
  final String id;
  String title;
  String description;
  bool isCompleted;
  int priority; // 0=low, 1=medium, 2=high
  DateTime? dueDate;
  DateTime? reminderTime;
  final DateTime createdAt;

  Task({
    required this.id,
    required this.title,
    this.description = '',
    this.isCompleted = false,
    this.priority = 1,
    this.dueDate,
    this.reminderTime,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'isCompleted': isCompleted,
    'priority': priority,
    'dueDate': dueDate?.toIso8601String(),
    'reminderTime': reminderTime?.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
  };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String? ?? '',
    isCompleted: json['isCompleted'] as bool? ?? false,
    priority: json['priority'] as int? ?? 1,
    dueDate: json['dueDate'] != null
        ? DateTime.parse(json['dueDate'] as String)
        : null,
    reminderTime: json['reminderTime'] != null
        ? DateTime.parse(json['reminderTime'] as String)
        : null,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}
