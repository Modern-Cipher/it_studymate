import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../utils/validators.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({DatabaseService? database, AuthService? session})
    : _database = database ?? DatabaseService.instance,
      _session = session ?? AuthService.instance;

  final DatabaseService _database;
  final AuthService _session;

  AppUser? _user;
  bool _booting = true;
  bool _busy = false;

  AppUser? get user => _user;
  bool get booting => _booting;
  bool get busy => _busy;
  bool get isAuthenticated => _user != null;

  Future<void> bootstrap() async {
    final int? id = await _session.readSession();
    if (id != null) {
      _user = await _database.userById(id);
      if (_user == null) await _session.clearSession();
    }
    _booting = false;
    notifyListeners();
  }

  Future<String?> login(String email, String password) async {
    final String? emailError = Validators.emailError(email);
    if (emailError != null) return emailError;
    if (password.isEmpty) return 'Password is required.';
    _busy = true;
    notifyListeners();
    try {
      final AppUser? user = await _database.authenticate(email, password);
      if (user == null) return 'Invalid email or password.';
      _user = user;
      await _session.saveSession(user.id);
      return null;
    } catch (_) {
      return 'Could not open the local database. Please try again.';
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<String?> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String confirmPassword,
    required String course,
    required int yearLevel,
    required String section,
  }) async {
    final String? firstError = Validators.nameError(firstName, 'First name');
    if (firstError != null) return firstError;
    final String? lastError = Validators.nameError(lastName, 'Last name');
    if (lastError != null) return lastError;
    final String? emailError = Validators.emailError(email);
    if (emailError != null) return emailError;
    final String? passwordError = Validators.passwordError(password);
    if (passwordError != null) return passwordError;
    if (password != confirmPassword) return 'Passwords do not match.';
    if (course.trim().isEmpty) return 'Course is required.';
    if (section.trim().isEmpty) return 'Section is required.';
    _busy = true;
    notifyListeners();
    try {
      final AppUser user = await _database.createUser(
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        email: email.trim(),
        password: password,
        course: course.trim(),
        yearLevel: yearLevel,
        section: section.trim(),
      );
      _user = user;
      await _session.saveSession(user.id);
      return null;
    } on AuthFailure catch (failure) {
      return failure.message;
    } catch (_) {
      return 'Could not create the account. Please try again.';
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _user = null;
    await _session.clearSession();
    notifyListeners();
  }
}
