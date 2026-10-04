import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../core/api_service.dart';
import '../core/models.dart';

class RequestProvider extends ChangeNotifier {
  List<RequestModel> _requests = [];
  List<CategoryModel> _categories = [];
  List<NotificationModel> _notifications = [];
  DashboardStats _dashboard = const DashboardStats();
  bool _loading = false;
  bool _categoriesLoading = false;
  bool _categoriesFailed = false;
  bool _submitting = false;
  String? _error;

  List<RequestModel> get requests => _requests;
  List<CategoryModel> get categories => _categories;
  List<NotificationModel> get notifications => _notifications;
  DashboardStats get dashboard => _dashboard;
  bool get loading => _loading;
  bool get categoriesLoading => _categoriesLoading;
  bool get categoriesFailed => _categoriesFailed;
  bool get submitting => _submitting;

  /// Message from the last failed action, for the screen to show.
  String? get error => _error;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  static List<dynamic> _asList(dynamic body) {
    if (body is List) return body;
    if (body is Map && body['data'] is List) return body['data'];
    return const [];
  }

  String _statusError(int status, String fallback) {
    if (status == 401) return 'Your session has expired. Please log in again.';
    if (status == 403) return 'You don\'t have permission to do that.';
    return fallback;
  }

  Future<void> fetchCategories() async {
    _categoriesLoading = true;
    _categoriesFailed = false;
    notifyListeners();

    try {
      final res = await ApiService.get('/categories', auth: false);
      if (res.statusCode == 200) {
        _categories = _asList(jsonDecode(res.body))
            .map((c) => CategoryModel.fromJson(c))
            .toList();
      } else {
        _categoriesFailed = true;
      }
    } catch (e) {
      debugPrint('Fetch categories error: $e');
      _categoriesFailed = true;
    } finally {
      _categoriesLoading = false;
      notifyListeners();
    }
  }

  /// The signed-in resident's own requests.
  Future<void> fetchRequests() => _fetchRequestList('/requests');

  /// Every request (staff and admins).
  Future<void> fetchAdminRequests() => _fetchRequestList('/admin/requests');

  Future<void> _fetchRequestList(String endpoint) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await ApiService.get(endpoint);
      if (res.statusCode == 200) {
        _requests = _asList(jsonDecode(res.body))
            .map((r) => RequestModel.fromJson(r))
            .toList();
      } else {
        _error = _statusError(res.statusCode, 'Failed to load requests (${res.statusCode})');
      }
    } catch (e) {
      debugPrint('Fetch requests error: $e');
      _error = 'Unable to connect to the server.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<RequestModel?> fetchRequest(int id) async {
    try {
      final res = await ApiService.get('/requests/$id');
      if (res.statusCode == 200) {
        return RequestModel.fromJson(jsonDecode(res.body));
      }
      _error = res.statusCode == 404
          ? 'Request not found'
          : _statusError(res.statusCode, 'Failed to load request');
    } catch (e) {
      debugPrint('Fetch request error: $e');
      _error = 'Unable to connect to the server.';
    }
    notifyListeners();
    return null;
  }

  Future<bool> submitRequest(Map<String, dynamic> data) async {
    _submitting = true;
    _error = null;
    notifyListeners();

    try {
      final res = await ApiService.post('/requests', data);
      if (res.statusCode == 201) {
        await fetchRequests();
        return true;
      }
      _error = ApiService.errorMessage(res, 'Failed to submit request');
      return false;
    } catch (e) {
      debugPrint('Submit request error: $e');
      _error = 'Unable to connect to the server.';
      return false;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }

  Future<bool> cancelRequest(int id) async {
    _submitting = true;
    _error = null;
    notifyListeners();

    try {
      final res = await ApiService.delete('/requests/$id');
      if (res.statusCode == 200) {
        await fetchRequests();
        return true;
      }
      _error = ApiService.errorMessage(res, 'Failed to cancel request');
      return false;
    } catch (e) {
      debugPrint('Cancel request error: $e');
      _error = 'Unable to connect to the server.';
      return false;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }

  Future<bool> updateStatus(int id, String status, {String? remarks}) async {
    _submitting = true;
    _error = null;
    notifyListeners();

    try {
      final res = await ApiService.put('/admin/requests/$id/status', {
        'status': status,
        'remarks': (remarks == null || remarks.isEmpty) ? null : remarks,
      });
      if (res.statusCode == 200) {
        await Future.wait([fetchAdminRequests(), fetchDashboard()]);
        return true;
      }
      _error = ApiService.errorMessage(res, 'Failed to update status');
      return false;
    } catch (e) {
      debugPrint('Update status error: $e');
      _error = 'Unable to connect to the server.';
      return false;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }

  Future<void> fetchDashboard() async {
    try {
      final res = await ApiService.get('/admin/dashboard');
      if (res.statusCode == 200) {
        _dashboard = DashboardStats.fromJson(jsonDecode(res.body));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Fetch dashboard error: $e');
    }
  }

  Future<void> fetchNotifications() async {
    try {
      final res = await ApiService.get('/notifications');
      if (res.statusCode == 200) {
        _notifications = _asList(jsonDecode(res.body))
            .map((n) => NotificationModel.fromJson(n))
            .toList();
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
        _notifications = _notifications.map((n) => n.markedRead()).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Mark all read error: $e');
    }
  }

  Future<void> markRead(NotificationModel notification) async {
    if (notification.isRead) return;
    // Update the badge right away; the server call is fire-and-forget.
    _notifications = _notifications
        .map((n) => n.id == notification.id ? n.markedRead() : n)
        .toList();
    notifyListeners();
    try {
      await ApiService.put('/notifications/${notification.id}/read', {});
    } catch (e) {
      debugPrint('Mark read error: $e');
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Clears everything on logout so the next account never sees stale data.
  void reset() {
    _requests = [];
    _categories = [];
    _notifications = [];
    _dashboard = const DashboardStats();
    _loading = false;
    _categoriesLoading = false;
    _categoriesFailed = false;
    _submitting = false;
    _error = null;
    notifyListeners();
  }
}
