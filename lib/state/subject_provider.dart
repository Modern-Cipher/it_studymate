import 'package:flutter/foundation.dart';

import '../models/subject.dart';
import '../services/database_service.dart';

class SubjectProvider extends ChangeNotifier {
  SubjectProvider({DatabaseService? database})
    : _database = database ?? DatabaseService.instance;

  final DatabaseService _database;

  List<Subject> _subjects = <Subject>[];
  int? _userId;

  List<Subject> get subjects => List<Subject>.unmodifiable(_subjects);

  Subject? byId(int? id) {
    if (id == null) return null;
    for (final Subject subject in _subjects) {
      if (subject.id == id) return subject;
    }
    return null;
  }

  int taskCountFor(int? subjectId) {
    if (subjectId == null) return 0;
    int total = 0;
    for (final Subject subject in _subjects) {
      if (subject.id == subjectId) total = total + 0;
    }
    return total;
  }

  Future<void> load(int userId) async {
    _userId = userId;
    _subjects = await _database.subjectsFor(userId);
    notifyListeners();
  }

  Future<void> refresh() async {
    final int? id = _userId;
    if (id == null) return;
    await load(id);
  }

  Future<void> add(Subject subject) async {
    await _database.insertSubject(subject);
    await refresh();
  }

  Future<void> remove(Subject subject) async {
    final int? id = subject.id;
    if (id == null) return;
    await _database.deleteSubject(id);
    await refresh();
  }
}
