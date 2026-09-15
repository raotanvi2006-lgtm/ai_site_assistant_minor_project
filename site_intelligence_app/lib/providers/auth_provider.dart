import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

enum AuthStatus { unknown, loggedIn, loggedOut }

class AuthProvider extends ChangeNotifier {
  final AuthService _service = AuthService();

  AuthStatus _status = AuthStatus.unknown;
  AppUser? _user;
  String? _error;

  AuthStatus get status => _status;
  AppUser? get user => _user;
  String? get error => _error;
  bool get isLoggedIn => _status == AuthStatus.loggedIn;

  // Called on app start to check if session exists
  Future<void> checkSession() async {
    _user = await _service.getLoggedInUser();
    _status = _user != null ? AuthStatus.loggedIn : AuthStatus.loggedOut;
    notifyListeners();
  }

  Future<bool> login(String phone, String password) async {
    _error = null;
    final err = await _service.login(phone: phone, password: password);
    if (err != null) {
      _error = err;
      notifyListeners();
      return false;
    }
    _user = await _service.getLoggedInUser();
    _status = AuthStatus.loggedIn;
    notifyListeners();
    return true;
  }

  Future<bool> register(String name, String phone, String password) async {
    _error = null;
    final err = await _service.register(name: name, phone: phone, password: password);
    if (err != null) {
      _error = err;
      notifyListeners();
      return false;
    }
    _user = await _service.getLoggedInUser();
    _status = AuthStatus.loggedIn;
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    await _service.logout();
    _user = null;
    _status = AuthStatus.loggedOut;
    notifyListeners();
  }
}