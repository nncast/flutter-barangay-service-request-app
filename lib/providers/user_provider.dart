import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/api_service.dart';
import '../core/models.dart';

class UserProvider extends ChangeNotifier {
  List<UserModel> _users = [];
  bool _loading = false;
  bool _saving = false;
  String? _error;

  List<UserModel> get users => _users;
  bool get loading => _loading;
  bool get saving => _saving;

  /// Message from the last failed action, for the screen to show.
  String? get error => _error;

  Future<void> fetchUsers() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await ApiService.get('/admin/users');
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        _users = data.map((u) => UserModel.fromJson(u)).toList();
      } else {
        _error = ApiService.errorMessage(res, 'Failed to load users');
      }
    } catch (e) {
      debugPrint('Fetch users error: $e');
      _error = 'Unable to connect to the server.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> createUser(Map<String, dynamic> userData) =>
      _save(() => ApiService.post('/admin/users', userData), okStatus: 201, fallback: 'Failed to create user');

  Future<bool> updateUser(int id, Map<String, dynamic> userData) =>
      _save(() => ApiService.put('/admin/users/$id', userData), fallback: 'Failed to update user');

  Future<bool> deleteUser(int id) =>
      _save(() => ApiService.delete('/admin/users/$id'), fallback: 'Failed to delete user');

  Future<bool> _save(
    Future<http.Response> Function() send, {
    int okStatus = 200,
    required String fallback,
  }) async {
    _saving = true;
    _error = null;
    notifyListeners();

    try {
      final res = await send();
      if (res.statusCode == okStatus) {
        await fetchUsers();
        return true;
      }
      _error = ApiService.errorMessage(res, fallback);
      return false;
    } catch (e) {
      debugPrint('User save error: $e');
      _error = 'Unable to connect to the server.';
      return false;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void reset() {
    _users = [];
    _loading = false;
    _saving = false;
    _error = null;
    notifyListeners();
  }
}
