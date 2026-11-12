enum TaskPriority { low, medium, high }

TaskPriority priorityFromValue(int value) {
  if (value < 0 || value >= TaskPriority.values.length) return TaskPriority.medium;
  return TaskPriority.values[value];
}

extension TaskPriorityLabel on TaskPriority {
  String get label => switch (this) {
    TaskPriority.low => 'Low',
    TaskPriority.medium => 'Medium',
    TaskPriority.high => 'High',
  };
}

class Task {
  Task({
    this.id,
    required this.userId,
    this.subjectId,
    required this.title,
    this.note = '',
    required this.dueDate,
    this.priority = TaskPriority.medium,
    this.isDone = false,
    DateTime? createdAt,
    this.subjectCode,
    this.subjectColor,
  }) : createdAt = createdAt ?? DateTime.now();

  final int? id;
  final int userId;
  final int? subjectId;
  final String title;
  final String note;
  final DateTime dueDate;
  final TaskPriority priority;
  final bool isDone;
  final DateTime createdAt;
  final String? subjectCode;
  final String? subjectColor;

  factory Task.fromMap(Map<String, Object?> map) => Task(
    id: map['id'] as int?,
    userId: map['user_id'] as int,
    subjectId: map['subject_id'] as int?,
    title: map['title'] as String,
    note: (map['note'] as String?) ?? '',
    dueDate: DateTime.parse(map['due_date'] as String),
    priority: priorityFromValue((map['priority'] as int?) ?? 1),
    isDone: ((map['is_done'] as int?) ?? 0) == 1,
    createdAt: DateTime.parse(map['created_at'] as String),
    subjectCode: map['subject_code'] as String?,
    subjectColor: map['subject_color'] as String?,
  );

  Task copyWith({
    int? id,
    int? userId,
    int? subjectId,
    bool clearSubject = false,
    String? title,
    String? note,
    DateTime? dueDate,
    TaskPriority? priority,
    bool? isDone,
    DateTime? createdAt,
    String? subjectCode,
    String? subjectColor,
  }) => Task(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    subjectId: clearSubject ? null : (subjectId ?? this.subjectId),
    title: title ?? this.title,
    note: note ?? this.note,
    dueDate: dueDate ?? this.dueDate,
    priority: priority ?? this.priority,
    isDone: isDone ?? this.isDone,
    createdAt: createdAt ?? this.createdAt,
    subjectCode: subjectCode ?? this.subjectCode,
    subjectColor: subjectColor ?? this.subjectColor,
  );

  Map<String, Object?> toInsertMap() => <String, Object?>{
    'user_id': userId,
    'subject_id': subjectId,
    'title': title,
    'note': note,
    'due_date': dueDate.toIso8601String(),
    'priority': priority.index,
    'is_done': isDone ? 1 : 0,
    'created_at': createdAt.toIso8601String(),
  };

  Map<String, Object?> toUpdateMap() => <String, Object?>{
    'subject_id': subjectId,
    'title': title,
    'note': note,
    'due_date': dueDate.toIso8601String(),
    'priority': priority.index,
    'is_done': isDone ? 1 : 0,
  };

  bool get isToday => _sameDay(dueDate, DateTime.now());

  bool get isOverdue => !isDone && dueDate.isBefore(DateTime.now()) && !isToday;

  bool get isUpcoming =>
      !isDone && dueDate.isAfter(DateTime.now()) && !isToday;

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
