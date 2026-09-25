import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

/// Handles local, per-user persistence. All financial data for a user is
/// stored under a key namespaced to that username, so one user can never
/// read another user's transactions/budgets/goals from this device.
///
/// NOTE: password hashing here is SHA-256 with no salt/pepper — adequate
/// for a local demo, but a production build should use a proper backend
/// with salted hashing (e.g. bcrypt/argon2) rather than on-device storage.
class StorageService {
  static const _usersKey = 'bm_users';
  static const _sessionKey = 'bm_session';

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  String hash(String s) => sha256.convert(utf8.encode(s)).toString();

  Future<Map<String, String>> _loadUsers() async {
    final p = await _prefs;
    final raw = p.getString(_usersKey);
    if (raw == null) return {};
    return Map<String, String>.from(jsonDecode(raw));
  }

  Future<void> _saveUsers(Map<String, String> users) async {
    final p = await _prefs;
    await p.setString(_usersKey, jsonEncode(users));
  }

  Future<String?> currentSession() async {
    final p = await _prefs;
    return p.getString(_sessionKey);
  }

  Future<void> setSession(String? username) async {
    final p = await _prefs;
    if (username == null) {
      await p.remove(_sessionKey);
    } else {
      await p.setString(_sessionKey, username);
    }
  }

  Future<String?> signUp(String username, String password) async {
    final users = await _loadUsers();
    if (username.trim().isEmpty || password.length < 6) {
      return 'Username required, password min 6 characters.';
    }
    if (users.containsKey(username)) return 'Username already exists.';
    users[username] = hash(password);
    await _saveUsers(users);
    await saveUserData(username, UserData());
    await setSession(username);
    return null; // success
  }

  Future<String?> logIn(String username, String password) async {
    final users = await _loadUsers();
    if (!users.containsKey(username) || users[username] != hash(password)) {
      return 'Invalid username or password.';
    }
    await setSession(username);
    return null;
  }

  Future<String?> resetPassword(String username, String newPassword) async {
    final users = await _loadUsers();
    if (!users.containsKey(username)) return 'No such user.';
    if (newPassword.length < 6) return 'Password min 6 characters.';
    users[username] = hash(newPassword);
    await _saveUsers(users);
    return null;
  }

  Future<String?> changePassword(String username, String current, String next) async {
    final users = await _loadUsers();
    if (users[username] != hash(current)) return 'Current password incorrect.';
    if (next.length < 6) return 'New password min 6 characters.';
    users[username] = hash(next);
    await _saveUsers(users);
    return null;
  }

  String _dataKey(String username) => 'bm_data_$username';

  Future<UserData> loadUserData(String username) async {
    final p = await _prefs;
    final raw = p.getString(_dataKey(username));
    if (raw == null) return UserData();
    return UserData.fromJson(Map<String, dynamic>.from(jsonDecode(raw)));
  }

  Future<void> saveUserData(String username, UserData data) async {
    final p = await _prefs;
    await p.setString(_dataKey(username), jsonEncode(data.toJson()));
  }
}
