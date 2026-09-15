import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthService {
  static const _usersKey = 'asi_users';
  static const _loggedInKey = 'asi_logged_in_phone';

  // Simple hash — good enough for local storage
  static String _hash(String input) {
    int hash = 0;
    for (var ch in input.codeUnits) {
      hash = (hash * 31 + ch) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16);
  }

  // Load all registered users from device
  Future<List<AppUser>> _loadUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_usersKey);
    if (raw == null) return [];
    final List<dynamic> list = jsonDecode(raw);
    return list.map((e) => AppUser.fromJson(e as Map<String, dynamic>)).toList();
  }

  // Save all users to device
  Future<void> _saveUsers(List<AppUser> users) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usersKey, jsonEncode(users.map((u) => u.toJson()).toList()));
  }

  // Register new user
  Future<String?> register({
    required String name,
    required String phone,
    required String password,
  }) async {
    final users = await _loadUsers();
    final exists = users.any((u) => u.phone == phone);
    if (exists) return 'Phone number already registered';

    final user = AppUser(
      name: name.trim(),
      phone: phone.trim(),
      passwordHash: _hash(password),
    );
    users.add(user);
    await _saveUsers(users);
    await _setLoggedIn(phone);
    return null; // null = success
  }

  // Login
  Future<String?> login({
    required String phone,
    required String password,
  }) async {
    final users = await _loadUsers();
    final user = users.where((u) => u.phone == phone.trim()).firstOrNull;
    if (user == null) return 'Phone number not registered';
    if (user.passwordHash != _hash(password)) return 'Incorrect password';
    await _setLoggedIn(phone);
    return null; // null = success
  }

  // Save session
  Future<void> _setLoggedIn(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_loggedInKey, phone);
  }

  // Get current logged-in user
  Future<AppUser?> getLoggedInUser() async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString(_loggedInKey);
    if (phone == null) return null;
    final users = await _loadUsers();
    return users.where((u) => u.phone == phone).firstOrNull;
  }

  // Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_loggedInKey);
  }
}