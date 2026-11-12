import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  AuthService._internal();

  static final AuthService instance = AuthService._internal();

  static const String _keyUserId = 'session_user_id';

  Future<int?> readSession() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyUserId);
  }

  Future<void> saveSession(int userId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyUserId, userId);
  }

  Future<void> clearSession() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserId);
  }
}
