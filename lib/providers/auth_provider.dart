import 'dart:convert';
import 'package:flutter/foundation.dart';
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

  /// Restores the session from a saved token. Called once by the splash screen.
  Future<void> tryAutoLogin() async {
    final token = await ApiService.getToken();
    if (token == null) return;

    try {
      final res = await ApiService.get('/me');
      if (res.statusCode == 200) {
        _user = UserModel.fromJson(jsonDecode(res.body));
        notifyListeners();
      } else if (res.statusCode == 401 || res.statusCode == 403) {
        // Token revoked or expired: sign in again.
        await ApiService.clearToken();
      }
    } catch (e) {
      // Server unreachable: keep the token so the user isn't logged out
      // just for opening the app offline. They land on the login screen.
      debugPrint('Auto login error: $e');
    }
  }

  Future<bool> login(String email, String password) async {
    return _authenticate(
      () => ApiService.post('/login', {'email': email, 'password': password}, auth: false),
      okStatus: 200,
      fallbackError: 'Login failed',
    );
  }

  Future<bool> register(Map<String, dynamic> data) async {
    return _authenticate(
      () => ApiService.post('/register', data, auth: false),
      okStatus: 201,
      fallbackError: 'Registration failed',
    );
  }

  Future<bool> _authenticate(
    Future<dynamic> Function() send, {
    required int okStatus,
    required String fallbackError,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await send();
      if (res.statusCode == okStatus) {
        final body = jsonDecode(res.body);
        await ApiService.saveToken(body['token']);
        _user = UserModel.fromJson(body['user']);
        return true;
      }
      _error = ApiService.errorMessage(res, fallbackError);
      return false;
    } catch (e) {
      debugPrint('Auth error: $e');
      _error = 'Unable to connect to the server. Check that the API is running.';
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      await ApiService.post('/logout', {});
    } catch (_) {}

    await ApiService.clearToken();
    _user = null;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
