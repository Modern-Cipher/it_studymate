import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../services/account_service.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../utils/recovery_code.dart';
import '../utils/validators.dart';

class ResetTarget {
  const ResetTarget({required this.email, required this.hasCode});

  final String email;
  final bool hasCode;
}

class AuthProvider extends ChangeNotifier {
  AuthProvider({
    DatabaseService? database,
    AuthService? session,
    AccountService? accounts,
  }) : _database = database ?? DatabaseService.instance,
       _session = session ?? AuthService.instance,
       _accounts = accounts ?? AccountService.instance;

  final DatabaseService _database;
  final AuthService _session;
  final AccountService _accounts;

  AppUser? _user;
  bool _booting = true;
  bool _busy = false;
  String? _lastRecoveryCode;
  ResetTarget? _resetTarget;

  AppUser? get user => _user;
  bool get booting => _booting;
  bool get busy => _busy;
  bool get isAuthenticated => _user != null;
  String? get lastRecoveryCode => _lastRecoveryCode;
  bool get resetRequiresCode => _resetTarget?.hasCode ?? true;
  String? get resetEmail => _resetTarget?.email;

  Future<void> bootstrap() async {
    final int? id = await _session.readSession();
    if (id != null) {
      _user = await _database.userById(id);
      if (_user == null) await _session.clearSession();
    }
    _booting = false;
    notifyListeners();
  }

  Future<String?> login(String identifier, String password) async {
    final String? identifierFailure = Validators.identifierError(identifier);
    if (identifierFailure != null) return identifierFailure;
    if (password.isEmpty) return 'Password is required.';
    _busy = true;
    notifyListeners();
    try {
      final AppUser? user = await _database.authenticate(identifier, password);
      if (user == null) return 'Invalid email, username, or password.';
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
    required String username,
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
    final String? usernameError = Validators.optionalUsernameError(username);
    if (usernameError != null) return usernameError;
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
      final String recoveryCode = RecoveryCode.generate();
      final AppUser user = await _database.createUser(
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        username: username.trim(),
        email: email.trim(),
        password: password,
        recoveryCode: recoveryCode,
        course: course.trim(),
        yearLevel: yearLevel,
        section: section.trim(),
      );
      _user = user;
      _lastRecoveryCode = recoveryCode;
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

  Future<String?> updateProfile({
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String course,
    required int yearLevel,
    required String section,
    required String currentPassword,
  }) async {
    final AppUser? current = _user;
    if (current == null) return 'You are not signed in.';
    final Map<String, Object?> changes = <String, Object?>{};

    final String firstNameText = firstName.trim();
    if (firstNameText != current.firstName) {
      final String? failure = Validators.nameError(firstNameText, 'First name');
      if (failure != null) return failure;
      changes['first_name'] = firstNameText;
    }

    final String lastNameText = lastName.trim();
    if (lastNameText != current.lastName) {
      final String? failure = Validators.nameError(lastNameText, 'Last name');
      if (failure != null) return failure;
      changes['last_name'] = lastNameText;
    }

    final String usernameText = username.trim().toLowerCase();
    if (usernameText != current.username) {
      final String? failure = Validators.optionalUsernameError(username);
      if (failure != null) return failure;
      changes['username'] = usernameText;
    }

    final String emailText = email.trim().toLowerCase();
    if (emailText != current.email) {
      final String? failure = Validators.emailError(email);
      if (failure != null) return failure;
      changes['email'] = emailText;
    }

    final String courseText = course.trim();
    if (courseText != current.course) {
      if (courseText.isEmpty) return 'Course cannot be empty.';
      changes['course'] = courseText;
    }

    if (yearLevel != current.yearLevel) {
      changes['year_level'] = yearLevel;
    }

    final String sectionText = section.trim();
    if (sectionText != current.section) {
      if (sectionText.isEmpty) return 'Section cannot be empty.';
      changes['section'] = sectionText;
    }

    if (changes.isEmpty) return 'No changes to save.';
    if (currentPassword.isEmpty) {
      return 'Enter your current password to save changes.';
    }

    _busy = true;
    notifyListeners();
    try {
      final String? failure = await _accounts.updateFields(
        userId: current.id,
        values: changes,
        currentPassword: currentPassword,
      );
      if (failure != null) return failure;
      _user = await _database.userById(current.id);
      return null;
    } catch (_) {
      return 'Could not save the changes.';
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final AppUser? current = _user;
    if (current == null) return 'You are not signed in.';
    if (currentPassword.isEmpty) return 'Enter your current password.';
    final String? policy = Validators.passwordError(newPassword);
    if (policy != null) return policy;
    if (newPassword != confirmPassword) return 'Passwords do not match.';
    if (newPassword == currentPassword) {
      return 'Choose a password different from the current one.';
    }
    _busy = true;
    notifyListeners();
    try {
      return await _accounts.changePassword(
        userId: current.id,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
    } catch (_) {
      return 'Could not update the password.';
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<String?> startReset(String email) async {
    final String? emailError = Validators.emailError(email);
    if (emailError != null) return emailError;
    _busy = true;
    notifyListeners();
    try {
      final String normalized = email.trim().toLowerCase();
      final bool exists = await _database.accountExists(normalized);
      if (!exists) return 'No account is registered with this email.';
      final bool hasCode = await _database.hasRecoveryCode(normalized);
      _resetTarget = ResetTarget(email: normalized, hasCode: hasCode);
      return null;
    } catch (_) {
      return 'Could not read the local database.';
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<String?> verifyResetCode(String code) async {
    final ResetTarget? target = _resetTarget;
    if (target == null) return 'Start again from the email step.';
    if (!RecoveryCode.isWellFormed(code)) {
      return 'Enter the 8-character recovery code.';
    }
    _busy = true;
    notifyListeners();
    try {
      final bool ok = await _database.verifyRecoveryCode(target.email, code);
      return ok ? null : 'That recovery code does not match.';
    } catch (_) {
      return 'Could not verify the code.';
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<String?> verifyResetIdentity({
    required String firstName,
    required String lastName,
    required String section,
  }) async {
    final ResetTarget? target = _resetTarget;
    if (target == null) return 'Start again from the email step.';
    if (firstName.trim().isEmpty ||
        lastName.trim().isEmpty ||
        section.trim().isEmpty) {
      return 'Complete all three fields.';
    }
    _busy = true;
    notifyListeners();
    try {
      final bool ok = await _database.verifyLegacyIdentity(
        email: target.email,
        firstName: firstName,
        lastName: lastName,
        section: section,
      );
      return ok ? null : 'Those details do not match this account.';
    } catch (_) {
      return 'Could not verify the details.';
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<String?> resetPassword({
    required String password,
    required String confirmPassword,
  }) async {
    final ResetTarget? target = _resetTarget;
    if (target == null) return 'Start again from the email step.';
    final String? policy = Validators.passwordError(password);
    if (policy != null) return policy;
    if (password != confirmPassword) return 'Passwords do not match.';
    _busy = true;
    notifyListeners();
    try {
      final bool updated = await _database.updatePassword(
        target.email,
        password,
      );
      if (!updated) return 'Password could not be updated.';
      _resetTarget = null;
      return null;
    } catch (_) {
      return 'Password could not be updated.';
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _user = null;
    _lastRecoveryCode = null;
    _resetTarget = null;
    await _session.clearSession();
    notifyListeners();
  }
}
