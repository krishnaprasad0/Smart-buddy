enum TodoPriority { low, medium, high }

class TodoModel {
  final String id;
  final String title;
  final String? reminderMessage;
  final DateTime? dueDate;
  final TodoPriority priority;
  final bool isCompleted;

  TodoModel({
    required this.id,
    required this.title,
    this.reminderMessage,
    this.dueDate,
    this.priority = TodoPriority.medium,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'reminderMessage': reminderMessage,
      'dueDate': dueDate?.toIso8601String(),
      'priority': priority.name,
      'isCompleted': isCompleted ? 1 : 0,
    };
  }

  factory TodoModel.fromMap(Map<String, dynamic> map) {
    return TodoModel(
      id: map['id'] as String,
      title: map['title'] as String,
      reminderMessage: map['reminderMessage'] as String?,
      dueDate: map['dueDate'] != null
          ? DateTime.parse(map['dueDate'] as String)
          : null,
      priority: TodoPriority.values.firstWhere(
        (e) => e.name == (map['priority'] as String? ?? 'medium'),
        orElse: () => TodoPriority.medium,
      ),
      isCompleted: (map['isCompleted'] as int? ?? 0) == 1,
    );
  }

  TodoModel copyWith({
    String? id,
    String? title,
    String? reminderMessage,
    DateTime? dueDate,
    TodoPriority? priority,
    bool? isCompleted,
  }) {
    return TodoModel(
      id: id ?? this.id,
      title: title ?? this.title,
      reminderMessage: reminderMessage ?? this.reminderMessage,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
