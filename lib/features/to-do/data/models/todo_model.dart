// lib/features/todo/data/models/todo_model.dart

import 'package:hive/hive.dart';

enum TodoPriority { low, medium, high, urgent }

enum TodoCategory { personal, work, shopping, health, learning, other }

@HiveType(typeId: 0)
class Todo {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  final DateTime lastEdited;

  @HiveField(5)
  final bool isCompleted;

  @HiveField(6)
  final bool isImportant;

  @HiveField(7)
  final bool isArchived;

  @HiveField(8)
  final List<String> tags;

  @HiveField(9)
  final DateTime? dueDate;

  @HiveField(10)
  final DateTime? reminderDate;

  @HiveField(11)
  final TodoPriority priority;

  @HiveField(12)
  final TodoCategory category;

  @HiveField(13)
  final int subTasksCount;

  @HiveField(14)
  final int completedSubTasks;

  @HiveField(15)
  final int backgroundColor;

  @HiveField(16)
  final String? colorLabel;

  @HiveField(17)
  final List<String> subTasks;

  @HiveField(18)
  final List<bool> subTasksCompleted;

  const Todo({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.lastEdited,
    this.isCompleted = false,
    this.isImportant = false,
    this.isArchived = false,
    this.tags = const [],
    this.dueDate,
    this.reminderDate,
    this.priority = TodoPriority.medium,
    this.category = TodoCategory.personal,
    this.subTasksCount = 0,
    this.completedSubTasks = 0,
    this.backgroundColor = 0xFFFFFFFF,
    this.colorLabel,
    this.subTasks = const [],
    this.subTasksCompleted = const [],
  });

  factory Todo.create({
    required String title,
    String description = '',
    List<String>? tags,
    DateTime? dueDate,
    TodoPriority priority = TodoPriority.medium,
    TodoCategory category = TodoCategory.personal,
  }) {
    final now = DateTime.now();

    return Todo(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title.trim(),
      description: description.trim(),
      createdAt: now,
      lastEdited: now,
      tags: tags ?? [],
      dueDate: dueDate,
      priority: priority,
      category: category,
    );
  }

  Todo copyWith({
    String? title,
    String? description,
    bool? isCompleted,
    bool? isImportant,
    bool? isArchived,
    List<String>? tags,
    DateTime? dueDate,
    DateTime? reminderDate,
    TodoPriority? priority,
    TodoCategory? category,
    int? subTasksCount,
    int? completedSubTasks,
    int? backgroundColor,
    String? colorLabel,
    List<String>? subTasks,
    List<bool>? subTasksCompleted,
  }) {
    final newSubTasks = subTasks ?? this.subTasks;
    final newSubTasksCompleted = subTasksCompleted ?? this.subTasksCompleted;

    bool? autoCompleted;
    if (newSubTasks.isNotEmpty &&
        newSubTasksCompleted.isNotEmpty &&
        newSubTasksCompleted.every((element) => element == true)) {
      autoCompleted = true;
    }

    return Todo(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt,
      lastEdited: DateTime.now(),
      isCompleted: autoCompleted ?? isCompleted ?? this.isCompleted,
      isImportant: isImportant ?? this.isImportant,
      isArchived: isArchived ?? this.isArchived,
      tags: tags ?? this.tags,
      dueDate: dueDate ?? this.dueDate,
      reminderDate: reminderDate ?? this.reminderDate,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      subTasksCount: subTasksCount ?? newSubTasks.length,
      completedSubTasks:
          completedSubTasks ??
          newSubTasksCompleted.where((e) => e == true).length,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      colorLabel: colorLabel ?? this.colorLabel,
      subTasks: newSubTasks,
      subTasksCompleted: newSubTasksCompleted,
    );
  }

  double get completionPercentage {
    if (subTasksCount == 0) return isCompleted ? 1.0 : 0.0;
    return completedSubTasks / subTasksCount;
  }

  bool get isOverdue {
    if (isCompleted) return false;
    if (dueDate == null) return false;
    return dueDate!.isBefore(DateTime.now());
  }

  bool get isDueToday {
    if (dueDate == null) return false;
    final today = DateTime.now();
    return dueDate!.year == today.year &&
        dueDate!.month == today.month &&
        dueDate!.day == today.day;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'createdAt': createdAt.toIso8601String(),
    'lastEdited': lastEdited.toIso8601String(),
    'isCompleted': isCompleted,
    'isImportant': isImportant,
    'isArchived': isArchived,
    'tags': tags,
    'dueDate': dueDate?.toIso8601String(),
    'reminderDate': reminderDate?.toIso8601String(),
    'priority': priority.index,
    'category': category.index,
    'subTasksCount': subTasksCount,
    'completedSubTasks': completedSubTasks,
    'backgroundColor': backgroundColor,
    'colorLabel': colorLabel,
    'subTasks': subTasks,
    'subTasksCompleted': subTasksCompleted,
  };

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      lastEdited: json['lastEdited'] != null
          ? DateTime.parse(json['lastEdited'])
          : DateTime.parse(json['createdAt']),
      isCompleted: json['isCompleted'] ?? false,
      isImportant: json['isImportant'] ?? false,
      isArchived: json['isArchived'] ?? false,
      tags: (json['tags'] as List?)?.cast<String>() ?? [],
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      reminderDate: json['reminderDate'] != null
          ? DateTime.parse(json['reminderDate'])
          : null,
      priority: TodoPriority.values[json['priority'] ?? 1],
      category: TodoCategory.values[json['category'] ?? 0],
      subTasksCount: json['subTasksCount'] ?? 0,
      completedSubTasks: json['completedSubTasks'] ?? 0,
      backgroundColor: json['backgroundColor'] ?? 0xFFFFFFFF,
      colorLabel: json['colorLabel'],
      subTasks: (json['subTasks'] as List?)?.cast<String>() ?? [],
      subTasksCompleted:
          (json['subTasksCompleted'] as List?)?.cast<bool>() ?? [],
    );
  }
}
