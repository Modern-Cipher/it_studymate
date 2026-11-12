import 'package:flutter/foundation.dart';

import '../models/task.dart';
import '../services/database_service.dart';

class TaskProvider extends ChangeNotifier {
  TaskProvider({DatabaseService? database})
    : _database = database ?? DatabaseService.instance;

  final DatabaseService _database;

  List<Task> _tasks = <Task>[];
  int? _userId;
  bool _loading = false;
  int _todaySeconds = 0;
  int _weekSeconds = 0;

  List<Task> get tasks => List<Task>.unmodifiable(_tasks);
  bool get loading => _loading;
  int get todaySeconds => _todaySeconds;
  int get weekSeconds => _weekSeconds;

  int get doneCount => _tasks.where((Task task) => task.isDone).length;
  int get totalCount => _tasks.length;
  double get completionRate => totalCount == 0 ? 0 : doneCount / totalCount;

  List<Task> get todayTasks =>
      _tasks.where((Task task) => !task.isDone && task.isToday).toList();

  List<Task> get overdueTasks =>
      _tasks.where((Task task) => task.isOverdue).toList();

  List<Task> get upcomingTasks =>
      _tasks.where((Task task) => task.isUpcoming).toList();

  List<Task> get completedTasks =>
      _tasks.where((Task task) => task.isDone).toList();

  List<Task> get openTasks =>
      _tasks.where((Task task) => !task.isDone).toList();

  Future<void> load(int userId) async {
    _userId = userId;
    _loading = true;
    notifyListeners();
    await _reload();
    _loading = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    final int? id = _userId;
    if (id == null) return;
    await _reload();
    notifyListeners();
  }

  Future<void> _reload() async {
    final int? id = _userId;
    if (id == null) return;
    _tasks = await _database.tasksFor(id);
    _todaySeconds = await _database.todayStudySeconds(id);
    _weekSeconds = await _database.weekStudySeconds(id);
  }

  Future<void> addTask(Task task) async {
    await _database.insertTask(task);
    await refresh();
  }

  Future<void> updateTask(Task task) async {
    await _database.updateTask(task);
    await refresh();
  }

  Future<void> toggle(Task task) async {
    final int? id = task.id;
    if (id == null) return;
    await _database.setTaskDone(id, !task.isDone);
    await refresh();
  }

  Future<void> remove(Task task) async {
    final int? id = task.id;
    if (id == null) return;
    await _database.deleteTask(id);
    await refresh();
  }

  Future<void> logSession({int? subjectId, required int seconds}) async {
    final int? id = _userId;
    if (id == null) return;
    await _database.logSession(
      userId: id,
      subjectId: subjectId,
      seconds: seconds,
    );
    await refresh();
  }
}
