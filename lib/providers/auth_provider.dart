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
  bool get isResident => _user?.isResident ?? false;

  AuthProvider() {
    tryAutoLogin();
  }

  Future<void> tryAutoLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return;

      final res = await ApiService.get('/me');
      if (res.statusCode == 200) {
        _user = UserModel.fromJson(jsonDecode(res.body));
        notifyListeners();
      } else {
        await prefs.remove('auth_token');
      }
    } catch (e) {
      debugPrint('Auto login error: $e');
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
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
        _error = null;
        notifyListeners();
        return true;
      } else {
        final body = jsonDecode(res.body);
        _error = body['message'] ?? body['errors']?['email']?[0] ?? 'Login failed';
        _loading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Connection error: Unable to connect to server';
      _loading = false;
      debugPrint('Login error: $e');
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(Map<String, dynamic> data) async {
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
        _error = null;
        notifyListeners();
        return true;
      } else if (res.statusCode == 422) {
        final body = jsonDecode(res.body);
        String errorMessage = 'Registration failed';

        // Handle validation errors (including duplicate email)
        if (body['errors'] != null) {
          final errors = body['errors'] as Map<String, dynamic>;
          if (errors.containsKey('email')) {
            final emailErrors = errors['email'] as List;
            if (emailErrors.isNotEmpty) {
              errorMessage = emailErrors.first;
            }
          } else if (errors.containsKey('name')) {
            final nameErrors = errors['name'] as List;
            if (nameErrors.isNotEmpty) {
              errorMessage = nameErrors.first;
            }
          } else {
            errorMessage = errors.values.first.first;
          }
        } else if (body['message'] != null) {
          errorMessage = body['message'];
        }

        _error = errorMessage;
        _loading = false;
        notifyListeners();
        return false;
      } else {
        final body = jsonDecode(res.body);
        _error = body['message'] ?? 'Registration failed';
        _loading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Connection error: Unable to connect to server';
      _loading = false;
      debugPrint('Register error: $e');
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
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}