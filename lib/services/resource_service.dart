import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sqflite/sqflite.dart';

import '../models/resource.dart';
import 'database_service.dart';

class StoredPick {
  const StoredPick({required this.path, required this.name});

  final String path;
  final String name;
}

class MediaPermissionException implements Exception {
  const MediaPermissionException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ResourceService {
  ResourceService._internal();

  static final ResourceService instance = ResourceService._internal();

  bool _tableReady = false;

  Future<Database> _database() async {
    final Database db = await DatabaseService.instance.database;
    if (!_tableReady) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS resources (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          subject_id INTEGER,
          kind INTEGER NOT NULL DEFAULT 0,
          title TEXT NOT NULL,
          url TEXT NOT NULL DEFAULT '',
          local_path TEXT NOT NULL DEFAULT '',
          thumbnail_path TEXT NOT NULL DEFAULT '',
          created_at TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
          FOREIGN KEY (subject_id) REFERENCES subjects (id) ON DELETE SET NULL
        )
      ''');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_resources_user ON resources (user_id, created_at)',
      );
      _tableReady = true;
    }
    return db;
  }

  Future<Directory> _mediaDirectory() async {
    final Directory base = await getApplicationDocumentsDirectory();
    final Directory dir = Directory(p.join(base.path, 'media'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<void> _ensurePermission(Permission permission, String label) async {
    final PermissionStatus status = await permission.request();
    if (status.isGranted || status.isLimited) return;
    if (status.isPermanentlyDenied) {
      throw MediaPermissionException(
        '$label permission is blocked. Open Settings and allow it for IT StudyMate.',
      );
    }
    throw MediaPermissionException(
      '$label permission is required. Tap again and choose Allow.',
    );
  }

  Future<StoredPick?> pickVideo() async {
    final PlatformFile? file = await FilePicker.pickFile(type: FileType.video);
    if (file == null) return null;
    return _storePath(file.path, file.name);
  }

  Future<StoredPick?> pickImage() async {
    final PlatformFile? file = await FilePicker.pickFile(type: FileType.image);
    if (file == null) return null;
    return _storePath(file.path, file.name);
  }

  Future<StoredPick?> pickAudio() async {
    final PlatformFile? file = await FilePicker.pickFile(type: FileType.audio);
    if (file == null) return null;
    return _storePath(file.path, file.name);
  }

  Future<StoredPick?> capturePhoto() async {
    await _ensurePermission(Permission.camera, 'Camera');
    final XFile? shot = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );
    if (shot == null) return null;
    return _storePath(shot.path, p.basename(shot.path));
  }

  Future<StoredPick?> captureVideo() async {
    await _ensurePermission(Permission.camera, 'Camera');
    await _ensurePermission(Permission.microphone, 'Microphone');
    final XFile? clip = await ImagePicker().pickVideo(
      source: ImageSource.camera,
      maxDuration: const Duration(minutes: 10),
    );
    if (clip == null) return null;
    return _storePath(clip.path, p.basename(clip.path));
  }

  Future<StoredPick?> _storePath(String? sourcePath, String originalName) async {
    if (sourcePath == null || sourcePath.isEmpty) return null;
    final File source = File(sourcePath);
    if (!await source.exists()) return null;
    final Directory dir = await _mediaDirectory();
    final String stamp = DateTime.now().millisecondsSinceEpoch.toString();
    final String safeName =
        originalName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final String target = p.join(dir.path, '${stamp}_$safeName');
    final File copied = await source.copy(target);
    return StoredPick(path: copied.path, name: originalName);
  }

  Future<void> deleteStoredFile(String path) async {
    if (path.isEmpty) return;
    final File file = File(path);
    if (await file.exists()) await file.delete();
  }

  Future<List<Resource>> forUser(int userId) async {
    final Database db = await _database();
    final List<Map<String, Object?>> rows = await db.rawQuery(
      '''
      SELECT r.id, r.user_id, r.subject_id, r.kind, r.title, r.url,
             r.local_path, r.thumbnail_path, r.created_at,
             s.code AS subject_code, s.color AS subject_color
      FROM resources r
      LEFT JOIN subjects s ON s.id = r.subject_id
      WHERE r.user_id = ?
      ORDER BY r.created_at DESC
      ''',
      <Object?>[userId],
    );
    return rows.map(Resource.fromMap).toList();
  }

  Future<int> insert(Resource resource) async {
    final Database db = await _database();
    return db.insert('resources', resource.toInsertMap());
  }

  Future<void> delete(Resource resource) async {
    final int? id = resource.id;
    if (id == null) return;
    final Database db = await _database();
    await db.delete('resources', where: 'id = ?', whereArgs: <Object?>[id]);
    await deleteStoredFile(resource.localPath);
    await deleteStoredFile(resource.thumbnailPath);
  }
}
