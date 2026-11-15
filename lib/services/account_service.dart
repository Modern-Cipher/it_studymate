import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';

import 'database_service.dart';

class AccountService {
  AccountService._internal();

  static final AccountService instance = AccountService._internal();

  String _hash(String value, String salt) =>
      sha256.convert(utf8.encode('$salt::$value')).toString();

  Future<bool> verifyPassword(int userId, String password) async {
    final Database db = await DatabaseService.instance.database;
    final List<Map<String, Object?>> rows = await db.query(
      'users',
      columns: <String>['password_hash', 'salt'],
      where: 'id = ?',
      whereArgs: <Object?>[userId],
      limit: 1,
    );
    if (rows.isEmpty) return false;
    final Map<String, Object?> row = rows.first;
    return _hash(password, row['salt'] as String) == row['password_hash'];
  }

  Future<String?> updateFields({
    required int userId,
    required Map<String, Object?> values,
    required String currentPassword,
  }) async {
    if (values.isEmpty) return 'No changes to save.';
    final Database db = await DatabaseService.instance.database;
    if (!await verifyPassword(userId, currentPassword)) {
      return 'Current password is incorrect.';
    }
    if (values.containsKey('email')) {
      final String email = values['email'] as String;
      final List<Map<String, Object?>> dupe = await db.query(
        'users',
        columns: <String>['id'],
        where: 'LOWER(email) = ? AND id <> ?',
        whereArgs: <Object?>[email, userId],
        limit: 1,
      );
      if (dupe.isNotEmpty) return 'This email is already registered.';
    }
    if (values.containsKey('username')) {
      final String username = values['username'] as String;
      if (username.isNotEmpty) {
        final List<Map<String, Object?>> dupe = await db.query(
          'users',
          columns: <String>['id'],
          where: 'LOWER(username) = ? AND id <> ?',
          whereArgs: <Object?>[username, userId],
          limit: 1,
        );
        if (dupe.isNotEmpty) return 'This username is already taken.';
      }
    }
    final int updated = await db.update(
      'users',
      values,
      where: 'id = ?',
      whereArgs: <Object?>[userId],
    );
    return updated > 0 ? null : 'Could not save the changes.';
  }

  Future<String?> changePassword({
    required int userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    final Database db = await DatabaseService.instance.database;
    if (!await verifyPassword(userId, currentPassword)) {
      return 'Current password is incorrect.';
    }
    final String salt = DateTime.now().microsecondsSinceEpoch.toString();
    final int updated = await db.update(
      'users',
      <String, Object?>{
        'password_hash': _hash(newPassword, salt),
        'salt': salt,
      },
      where: 'id = ?',
      whereArgs: <Object?>[userId],
    );
    return updated > 0 ? null : 'Could not update the password.';
  }
}
