import 'package:shared_preferences/shared_preferences.dart';

/// Persists the optionally signed-in Jamendo username locally.
class AuthStorage {
  static const _key = 'signed_in_username';

  Future<String?> readUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  Future<void> saveUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, username);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
