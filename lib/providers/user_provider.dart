import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../core/api_service.dart';
import '../core/models.dart';

class UserProvider extends ChangeNotifier {
  List<UserModel> _users = [];
  bool _loading = false;
  String? _error;

  List<UserModel> get users => _users;
  bool get loading => _loading;
  String? get error => _error;

  void _setError(String? error) {
    _error = error;
    debugPrint('UserProvider Error: $error');
    notifyListeners();
    Future.delayed(const Duration(seconds: 3), () {
      if (_error == error) {
        _error = null;
        notifyListeners();
      }
    });
  }

  Future<void> fetchUsers() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await ApiService.get('/admin/users');
      debugPrint('Fetch users response: ${res.statusCode}');

      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        _users = data.map((u) => UserModel.fromJson(u)).toList();
        debugPrint('Loaded ${_users.length} users');
        _error = null;
      } else if (res.statusCode == 403) {
        _setError('View only mode. Admin privileges required for modifications.');
      } else if (res.statusCode == 401) {
        _setError('Session expired. Please login again.');
      } else {
        _setError('Failed to load users');
      }
    } catch (e) {
      _setError('Network error: Could not load users');
      debugPrint('Fetch users error: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> createUser(Map<String, dynamic> userData) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await ApiService.post('/admin/users', userData);
      debugPrint('Create user response: ${res.statusCode}');
      debugPrint('Create user body: ${res.body}');

      if (res.statusCode == 201) {
        await fetchUsers();
        _loading = false;
        notifyListeners();
        return true;
      } else if (res.statusCode == 403) {
        _setError('Access denied. Only admins can create users.');
        _loading = false;
        notifyListeners();
        return false;
      } else if (res.statusCode == 422) {
        final body = jsonDecode(res.body);
        String errorMessage = 'Validation failed';

        // Handle validation errors properly
        if (body['errors'] != null && body['errors'] is Map) {
          final errors = body['errors'] as Map<String, dynamic>;
          final messages = <String>[];
          errors.forEach((key, value) {
            if (value is List) {
              messages.add('${key.toUpperCase()}: ${value.join(', ')}');
            } else {
              messages.add('${key.toUpperCase()}: $value');
            }
          });
          errorMessage = messages.join('; ');
        } else if (body['message'] != null) {
          errorMessage = body['message'];
        }

        _setError(errorMessage);
        _loading = false;
        notifyListeners();
        return false;
      } else {
        final body = jsonDecode(res.body);
        _setError(body['message'] ?? 'Failed to create user');
        _loading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _setError('Network error: Could not create user');
      debugPrint('Create user error: $e');
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateUser(int id, Map<String, dynamic> userData) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await ApiService.put('/admin/users/$id', userData);
      debugPrint('Update user response: ${res.statusCode}');
      debugPrint('Update user body: ${res.body}');

      if (res.statusCode == 200) {
        await fetchUsers();
        _loading = false;
        notifyListeners();
        return true;
      } else if (res.statusCode == 403) {
        _setError('Access denied. Only admins can update users.');
        _loading = false;
        notifyListeners();
        return false;
      } else if (res.statusCode == 404) {
        _setError('User not found');
        _loading = false;
        notifyListeners();
        return false;
      } else if (res.statusCode == 422) {
        final body = jsonDecode(res.body);
        String errorMessage = 'Validation failed';

        if (body['errors'] != null && body['errors'] is Map) {
          final errors = body['errors'] as Map<String, dynamic>;
          final messages = <String>[];
          errors.forEach((key, value) {
            if (value is List) {
              messages.add('${key.toUpperCase()}: ${value.join(', ')}');
            } else {
              messages.add('${key.toUpperCase()}: $value');
            }
          });
          errorMessage = messages.join('; ');
        } else if (body['message'] != null) {
          errorMessage = body['message'];
        }

        _setError(errorMessage);
        _loading = false;
        notifyListeners();
        return false;
      } else {
        final body = jsonDecode(res.body);
        _setError(body['message'] ?? 'Failed to update user');
        _loading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _setError('Network error: Could not update user');
      debugPrint('Update user error: $e');
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteUser(int id) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await ApiService.delete('/admin/users/$id');
      debugPrint('Delete user response: ${res.statusCode}');

      if (res.statusCode == 200) {
        await fetchUsers();
        _loading = false;
        notifyListeners();
        return true;
      } else if (res.statusCode == 403) {
        _setError('Access denied. Only admins can delete users.');
        _loading = false;
        notifyListeners();
        return false;
      } else if (res.statusCode == 404) {
        _setError('User not found');
        _loading = false;
        notifyListeners();
        return false;
      } else if (res.statusCode == 409) {
        final body = jsonDecode(res.body);
        _setError(body['message'] ?? 'Cannot delete user with existing requests');
        _loading = false;
        notifyListeners();
        return false;
      } else {
        _setError('Failed to delete user');
        _loading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _setError('Network error: Could not delete user');
      debugPrint('Delete user error: $e');
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void reset() {
    _users = [];
    _loading = false;
    _error = null;
    notifyListeners();
  }
}