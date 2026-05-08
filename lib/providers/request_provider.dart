import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../core/api_service.dart';
import '../core/models.dart';

class RequestProvider extends ChangeNotifier {
  List<RequestModel> _requests = [];
  List<CategoryModel> _categories = [];
  List<NotificationModel> _notifications = [];
  Map<String, dynamic> _dashboard = {};
  bool _loading = false;
  bool _submitting = false;
  String? _error;

  List<RequestModel> get requests => _requests;
  List<CategoryModel> get categories => _categories;
  List<NotificationModel> get notifications => _notifications;
  Map<String, dynamic> get dashboard => _dashboard;
  bool get loading => _loading;
  bool get submitting => _submitting;
  String? get error => _error;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void _setError(String? error) {
    _error = error;
    debugPrint('Provider Error: $error');
    notifyListeners();

    Future.delayed(const Duration(seconds: 3), () {
      if (_error == error) {
        _error = null;
        notifyListeners();
      }
    });
  }

  Future<void> fetchCategories() async {
    try {
      final res = await ApiService.get('/categories', auth: false);
      debugPrint('Categories Response: ${res.statusCode}');

      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        _categories = data.map((c) => CategoryModel.fromJson(c)).toList();
        debugPrint('Loaded ${_categories.length} categories');
        notifyListeners();
      } else {
        _setError('Failed to load categories');
      }
    } catch (e) {
      _setError('Connection error: $e');
      debugPrint('Fetch categories error: $e');
    }
  }

  Future<void> fetchRequests({String? status}) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      String endpoint = '/requests';
      if (status != null && status != 'all' && status.isNotEmpty) {
        endpoint += '?status=$status';
      }

      debugPrint('Fetching requests from: $endpoint');
      final res = await ApiService.get(endpoint);
      debugPrint('Response status: ${res.statusCode}');

      if (res.statusCode == 200) {
        final dynamic body = jsonDecode(res.body);

        List<dynamic> data;
        if (body is List) {
          data = body;
        } else if (body is Map && body.containsKey('data')) {
          data = body['data'];
        } else {
          data = [];
        }

        _requests = data.map((r) => RequestModel.fromJson(r)).toList();

        debugPrint('Loaded ${_requests.length} requests');
        _error = null;
        notifyListeners();
      } else if (res.statusCode == 401) {
        _setError('Session expired. Please login again.');
      } else {
        _setError('Failed to load requests (${res.statusCode})');
      }
    } catch (e) {
      _setError('Network error: Unable to connect to server');
      debugPrint('Fetch requests error: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<RequestModel?> fetchRequest(int id) async {
    try {
      debugPrint('Fetching request $id');
      final res = await ApiService.get('/requests/$id');
      debugPrint('Response status: ${res.statusCode}');

      if (res.statusCode == 200) {
        return RequestModel.fromJson(jsonDecode(res.body));
      } else if (res.statusCode == 404) {
        _setError('Request not found');
      }
      return null;
    } catch (e) {
      debugPrint('Fetch request error: $e');
      _setError('Network error: Could not fetch request');
      return null;
    }
  }

  Future<bool> submitRequest(Map<String, dynamic> data) async {
    _submitting = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('Submitting request: $data');
      final res = await ApiService.post('/requests', data);
      debugPrint('Response status: ${res.statusCode}');

      if (res.statusCode == 201) {
        debugPrint('Request submitted successfully');
        await fetchRequests();
        _submitting = false;
        notifyListeners();
        return true;
      } else {
        final body = jsonDecode(res.body);
        _setError(body['message'] ?? 'Failed to submit request');
        _submitting = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _setError('Network error: Could not submit request');
      debugPrint('Submit request error: $e');
      _submitting = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelRequest(int id) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('Cancelling request $id');
      final res = await ApiService.delete('/requests/$id');
      debugPrint('Response status: ${res.statusCode}');

      if (res.statusCode == 200) {
        debugPrint('Request cancelled successfully');
        await fetchRequests();
        _loading = false;
        notifyListeners();
        return true;
      } else {
        final body = jsonDecode(res.body);
        _setError(body['message'] ?? 'Failed to cancel request');
        _loading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _setError('Network error: Could not cancel request');
      debugPrint('Cancel request error: $e');
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchAdminRequests({String? status, String? search}) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      String endpoint = '/admin/requests';
      final List<String> params = [];

      if (status != null && status != 'all' && status.isNotEmpty) {
        params.add('status=$status');
      }
      if (search != null && search.isNotEmpty) {
        params.add('search=$search');
      }

      if (params.isNotEmpty) {
        endpoint += '?${params.join('&')}';
      }

      debugPrint('Fetching admin requests from: $endpoint');
      final res = await ApiService.get(endpoint);
      debugPrint('GET Response Status: ${res.statusCode}');
      debugPrint('GET Response Body: ${res.body}'); // Add this to see the response

      if (res.statusCode == 200) {
        print('RAW RESPONSE BODY: ${res.body}'); // See what's actually returned

        final dynamic body = jsonDecode(res.body);
        print('PARSED RESPONSE TYPE: ${body.runtimeType}');
        print('PARSED RESPONSE: $body');

        // Your parsing code here...
      }

      if (res.statusCode == 200) {
        final dynamic body = jsonDecode(res.body);

        // Handle different response formats
        List<dynamic> data;
        if (body is List) {
          // Direct list response
          data = body;
        } else if (body is Map && body.containsKey('data')) {
          // Wrapped in 'data' key
          data = body['data'];
        } else if (body is Map && body.containsKey('requests')) {
          // Wrapped in 'requests' key
          data = body['requests'];
        } else {
          data = [];
        }

        _requests = data.map((r) => RequestModel.fromJson(r)).toList();
        debugPrint('Loaded ${_requests.length} admin requests');
        _error = null;
        notifyListeners();
      } else if (res.statusCode == 403) {
        _setError('Access denied. Admin/Staff privileges required.');
      } else if (res.statusCode == 401) {
        _setError('Session expired. Please login again.');
      } else {
        _setError('Failed to load admin requests (${res.statusCode})');
      }
    } catch (e, stackTrace) {
      debugPrint('Fetch admin requests error: $e');
      debugPrint('Stack trace: $stackTrace');
      _setError('Network error: Could not load admin requests');
    } finally {
      _loading = false;
      notifyListeners();
    }


  }

  Future<bool> updateStatus(int id, String status, {String? remarks}) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final body = {
        'status': status,
        if (remarks != null && remarks.isNotEmpty) 'remarks': remarks
      };
      debugPrint('Updating status for request $id to $status');

      final res = await ApiService.put('/admin/requests/$id/status', body);
      debugPrint('PUT Response Status: ${res.statusCode}');
      debugPrint('PUT Response Body: ${res.body}');

      if (res.statusCode == 200) {
        debugPrint('Status updated successfully');
        // Refresh both lists
        await fetchAdminRequests();
        await fetchDashboard();
        await fetchNotifications();
        _loading = false;
        notifyListeners();
        return true;
      } else {
        final responseBody = jsonDecode(res.body);
        _setError(responseBody['message'] ?? 'Failed to update status');
        _loading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _setError('Network error: Could not update status');
      debugPrint('Update status error: $e');
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchDashboard() async {
    try {
      debugPrint('Fetching dashboard');
      final res = await ApiService.get('/admin/dashboard');
      debugPrint('Dashboard response status: ${res.statusCode}');

      if (res.statusCode == 200) {
        _dashboard = jsonDecode(res.body);
        debugPrint('Dashboard data: $_dashboard');
        notifyListeners();
      } else if (res.statusCode == 403) {
        _setError('Access denied. Admin/Staff privileges required.');
      } else {
        _setError('Failed to load dashboard');
      }
    } catch (e) {
      _setError('Network error: Could not load dashboard');
      debugPrint('Fetch dashboard error: $e');
    }
  }

  Future<void> fetchNotifications() async {
    try {
      final res = await ApiService.get('/notifications');
      debugPrint('Notifications response status: ${res.statusCode}');

      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        _notifications = data.map((n) => NotificationModel.fromJson(n)).toList();
        debugPrint('Loaded ${_notifications.length} notifications');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Fetch notifications error: $e');
    }
  }

  Future<void> markAllRead() async {
    try {
      final res = await ApiService.put('/notifications/read-all', {});
      if (res.statusCode == 200) {
        await fetchNotifications();
      }
    } catch (e) {
      debugPrint('Mark all read error: $e');
      _setError('Failed to mark notifications as read');
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void reset() {
    _requests = [];
    _categories = [];
    _notifications = [];
    _dashboard = {};
    _loading = false;
    _submitting = false;
    _error = null;
    notifyListeners();
  }
}