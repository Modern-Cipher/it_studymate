class Subject {
  const Subject({
    this.id,
    required this.userId,
    required this.code,
    required this.name,
    required this.units,
    required this.color,
  });

  final int? id;
  final int userId;
  final String code;
  final String name;
  final int units;
  final String color;

  factory Subject.fromMap(Map<String, Object?> map) => Subject(
    id: map['id'] as int?,
    userId: map['user_id'] as int,
    code: map['code'] as String,
    name: map['name'] as String,
    units: map['units'] as int,
    color: map['color'] as String,
  );

  Map<String, Object?> toMap() => <String, Object?>{
    'user_id': userId,
    'code': code,
    'name': name,
    'units': units,
    'color': color,
    'created_at': DateTime.now().toIso8601String(),
  };
}
