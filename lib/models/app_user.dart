class AppUser {
  const AppUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.email,
    required this.course,
    required this.yearLevel,
    required this.section,
  });

  final int id;
  final String firstName;
  final String lastName;
  final String username;
  final String email;
  final String course;
  final int yearLevel;
  final String section;

  factory AppUser.fromMap(Map<String, Object?> map) => AppUser(
    id: map['id'] as int,
    firstName: map['first_name'] as String,
    lastName: map['last_name'] as String,
    username: (map['username'] as String?) ?? '',
    email: map['email'] as String,
    course: map['course'] as String,
    yearLevel: map['year_level'] as int,
    section: map['section'] as String,
  );

  String get name => '$firstName $lastName';

  String get initials {
    final String first = firstName.trim();
    final String last = lastName.trim();
    if (first.isEmpty && last.isEmpty) return '?';
    if (first.isEmpty) return last.substring(0, 1).toUpperCase();
    if (last.isEmpty) return first.substring(0, 1).toUpperCase();
    return (first.substring(0, 1) + last.substring(0, 1)).toUpperCase();
  }

  String get programLabel => '$course · Year $yearLevel';

  bool get hasUsername => username.isNotEmpty;

  String get handle => hasUsername ? '@$username' : email;
}
