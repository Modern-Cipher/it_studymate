import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/app_user.dart';
import '../models/subject.dart';
import '../models/task.dart';
import '../utils/app_format.dart';

class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

class DatabaseService {
  DatabaseService._internal();

  static final DatabaseService instance = DatabaseService._internal();

  static const String _dbName = 'it_studymate.db';
  static const int _dbVersion = 2;

  Database? _database;

  Future<Database> get database async {
    final Database? existing = _database;
    if (existing != null) return existing;
    final Database opened = await _open();
    _database = opened;
    return opened;
  }

  String _hash(String password, String salt) =>
      sha256.convert(utf8.encode('$salt::$password')).toString();

  int _asInt(Object? value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  Future<Database> _open() async {
    final String base = await getDatabasesPath();
    final String path = p.join(base, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (Database db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (Database db, int version) async {
        await _createSchema(db);
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        await db.execute('DROP TABLE IF EXISTS sessions');
        await db.execute('DROP TABLE IF EXISTS tasks');
        await db.execute('DROP TABLE IF EXISTS subjects');
        await db.execute('DROP TABLE IF EXISTS users');
        await _createSchema(db);
      },
    );
  }

  Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        first_name TEXT NOT NULL,
        last_name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        salt TEXT NOT NULL,
        course TEXT NOT NULL,
        year_level INTEGER NOT NULL,
        section TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE subjects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        code TEXT NOT NULL,
        name TEXT NOT NULL,
        units INTEGER NOT NULL,
        color TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        subject_id INTEGER,
        title TEXT NOT NULL,
        note TEXT NOT NULL DEFAULT '',
        due_date TEXT NOT NULL,
        priority INTEGER NOT NULL DEFAULT 1,
        is_done INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (subject_id) REFERENCES subjects (id) ON DELETE SET NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        subject_id INTEGER,
        seconds INTEGER NOT NULL,
        started_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_tasks_user_due ON tasks (user_id, is_done, due_date)',
    );
    await db.execute(
      'CREATE INDEX idx_sessions_user_started ON sessions (user_id, started_at)',
    );
  }

  Future<AppUser?> authenticate(String email, String password) async {
    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.query(
      'users',
      where: 'LOWER(email) = ?',
      whereArgs: <Object?>[email.trim().toLowerCase()],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final Map<String, Object?> row = rows.first;
    final String salt = row['salt'] as String;
    if (_hash(password, salt) != row['password_hash']) return null;
    return AppUser.fromMap(row);
  }

  Future<AppUser?> userById(int id) async {
    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return AppUser.fromMap(rows.first);
  }

  Future<AppUser> createUser({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String course,
    required int yearLevel,
    required String section,
  }) async {
    final Database db = await database;
    final String normalized = email.trim().toLowerCase();
    final List<Map<String, Object?>> existing = await db.query(
      'users',
      where: 'LOWER(email) = ?',
      whereArgs: <Object?>[normalized],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      throw const AuthFailure('This email is already registered.');
    }
    final String salt = DateTime.now().microsecondsSinceEpoch.toString();
    final int id = await db.insert('users', <String, Object?>{
      'first_name': firstName.trim(),
      'last_name': lastName.trim(),
      'email': normalized,
      'password_hash': _hash(password, salt),
      'salt': salt,
      'course': course.trim(),
      'year_level': yearLevel,
      'section': section.trim(),
      'created_at': DateTime.now().toIso8601String(),
    });
    return AppUser(
      id: id,
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      email: normalized,
      course: course.trim(),
      yearLevel: yearLevel,
      section: section.trim(),
    );
  }

  Future<List<Subject>> subjectsFor(int userId) async {
    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.query(
      'subjects',
      where: 'user_id = ?',
      whereArgs: <Object?>[userId],
      orderBy: 'code ASC',
    );
    return rows.map(Subject.fromMap).toList();
  }

  Future<int> insertSubject(Subject subject) async {
    final Database db = await database;
    return db.insert('subjects', subject.toMap());
  }

  Future<void> deleteSubject(int id) async {
    final Database db = await database;
    await db.delete('subjects', where: 'id = ?', whereArgs: <Object?>[id]);
  }

  Future<List<Task>> tasksFor(int userId) async {
    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.rawQuery(
      '''
      SELECT t.id, t.user_id, t.subject_id, t.title, t.note, t.due_date,
             t.priority, t.is_done, t.created_at,
             s.code AS subject_code, s.color AS subject_color
      FROM tasks t
      LEFT JOIN subjects s ON s.id = t.subject_id
      WHERE t.user_id = ?
      ORDER BY t.is_done ASC, t.due_date ASC
      ''',
      <Object?>[userId],
    );
    return rows.map(Task.fromMap).toList();
  }

  Future<int> insertTask(Task task) async {
    final Database db = await database;
    return db.insert('tasks', task.toInsertMap());
  }

  Future<void> updateTask(Task task) async {
    final int? id = task.id;
    if (id == null) return;
    final Database db = await database;
    await db.update(
      'tasks',
      task.toUpdateMap(),
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  Future<void> setTaskDone(int id, bool done) async {
    final Database db = await database;
    await db.update(
      'tasks',
      <String, Object?>{'is_done': done ? 1 : 0},
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  Future<void> deleteTask(int id) async {
    final Database db = await database;
    await db.delete('tasks', where: 'id = ?', whereArgs: <Object?>[id]);
  }

  Future<void> logSession({
    required int userId,
    int? subjectId,
    required int seconds,
  }) async {
    final Database db = await database;
    await db.insert('sessions', <String, Object?>{
      'user_id': userId,
      'subject_id': subjectId,
      'seconds': seconds,
      'started_at': DateTime.now().toIso8601String(),
    });
  }

  Future<int> todayStudySeconds(int userId) async {
    final Database db = await database;
    final String start = AppDate.startOfDay(DateTime.now()).toIso8601String();
    final List<Map<String, Object?>> rows = await db.rawQuery(
      'SELECT SUM(seconds) AS total FROM sessions WHERE user_id = ? AND started_at >= ?',
      <Object?>[userId, start],
    );
    return _asInt(rows.first['total']);
  }

  Future<int> weekStudySeconds(int userId) async {
    final Database db = await database;
    final DateTime now = DateTime.now();
    final DateTime start = AppDate.startOfDay(
      now,
    ).subtract(Duration(days: now.weekday - 1));
    final List<Map<String, Object?>> rows = await db.rawQuery(
      'SELECT SUM(seconds) AS total FROM sessions WHERE user_id = ? AND started_at >= ?',
      <Object?>[userId, start.toIso8601String()],
    );
    return _asInt(rows.first['total']);
  }
}
