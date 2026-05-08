import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_service.dart';
import '../core/models.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _loading = false;
  String? _error;

  UserModel? get user => _user;
  bool get loading => _loading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;
  bool get isAdmin => _user?.isAdmin ?? false;
  bool get isStaff => _user?.isStaff ?? false;

  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return;

    try {
      final res = await ApiService.get('/me');
      if (res.statusCode == 200) {
        _user = UserModel.fromJson(jsonDecode(res.body));
        notifyListeners();
      } else {
        await prefs.remove('auth_token');
      }
    } catch (e) {
      debugPrint('Auto login error: $e');
    }
  }

  Future<bool> login(String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await ApiService.post(
        '/login',
        {'email': email, 'password': password},
        auth: false,
      );

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', body['token']);
        _user = UserModel.fromJson(body['user']);
        _loading = false;
        notifyListeners();
        return true;
      } else {
        final body = jsonDecode(res.body);
        _error = body['message'] ?? 'Login failed';
        _loading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Connection error: ${e.toString()}';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(Map<String, String> data) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await ApiService.post('/register', data, auth: false);

      if (res.statusCode == 201) {
        final body = jsonDecode(res.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', body['token']);
        _user = UserModel.fromJson(body['user']);
        _loading = false;
        notifyListeners();
        return true;
      } else {
        final body = jsonDecode(res.body);
        _error = body['message'] ?? 'Registration failed';
        _loading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Connection error: ${e.toString()}';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await ApiService.post('/logout', {});
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    _user = null;
    notifyListeners();
  }
}