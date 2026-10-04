import 'ui_helpers.dart' as ui;

int _toInt(dynamic value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

int? _toIntOrNull(dynamic value) => value == null ? null : _toInt(value);

bool _toBool(dynamic value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) return value == '1' || value.toLowerCase() == 'true';
  return fallback;
}

// User Model
class UserModel {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? address;
  final String role;
  final bool isActive;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.address,
    required this.role,
    this.isActive = true,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: _toInt(json['id']),
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      address: json['address'],
      role: json['role'] ?? 'resident',
      isActive: _toBool(json['is_active'], fallback: true),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'role': role,
      'is_active': isActive,
    };
  }

  bool get isAdmin => role == 'admin';

  /// True for staff and admins — anyone who works the request queue.
  bool get isStaff => role == 'staff' || role == 'admin';
  bool get isResident => role == 'resident';

  String get roleLabel => role.isEmpty ? '' : role[0].toUpperCase() + role.substring(1);

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

// Category Model
class CategoryModel {
  final int id;
  final String name;
  final String slug;
  final String? description;
  final String? icon;
  final String colorHex;
  final bool isActive;
  final int sortOrder;

  CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.icon,
    required this.colorHex,
    this.isActive = true,
    this.sortOrder = 0,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: _toInt(json['id']),
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'],
      icon: json['icon'],
      colorHex: json['color_hex'] ?? '#BE5633',
      isActive: _toBool(json['is_active'], fallback: true),
      sortOrder: _toInt(json['sort_order']),
    );
  }
}

// Request Model
class RequestModel {
  final int id;
  final String trackingCode;
  final String title;
  final String description;
  final String priority;
  final String status;
  final String? remarks;
  final String createdAt;
  final String? updatedAt;
  final String? completedAt;
  final CategoryModel? category;
  final UserModel? user;
  final List<StatusLog> logs;

  RequestModel({
    required this.id,
    required this.trackingCode,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    this.remarks,
    required this.createdAt,
    this.updatedAt,
    this.completedAt,
    this.category,
    this.user,
    this.logs = const [],
  });

  factory RequestModel.fromJson(Map<String, dynamic> json) {
    final logs = (json['logs'] as List? ?? [])
        .map((l) => StatusLog.fromJson(l as Map<String, dynamic>))
        .toList()
      // Newest first, so the latest change is at the top of the history.
      ..sort((a, b) {
        final byDate = b.createdAt.compareTo(a.createdAt);
        return byDate != 0 ? byDate : b.id.compareTo(a.id);
      });

    return RequestModel(
      id: _toInt(json['id']),
      trackingCode: json['tracking_code'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      priority: json['priority'] ?? 'normal',
      status: json['status'] ?? 'pending',
      remarks: json['remarks'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'],
      completedAt: json['completed_at'],
      category: json['category'] is Map<String, dynamic>
          ? CategoryModel.fromJson(json['category'])
          : null,
      user: json['user'] is Map<String, dynamic>
          ? UserModel.fromJson(json['user'])
          : null,
      logs: logs,
    );
  }

  /// Matches the API: residents can only cancel before review starts.
  bool get canCancel => status == 'pending';

  /// Staff can't change a request the resident cancelled.
  bool get canUpdateStatus => status != 'cancelled';
  bool get isCancelled => status == 'cancelled';

  String get statusLabel => ui.statusLabel(status);
}

// Status Log Model
class StatusLog {
  final int id;
  final String? oldStatus;
  final String newStatus;
  final String? note;
  final String createdAt;
  final UserModel? changer;

  StatusLog({
    required this.id,
    this.oldStatus,
    required this.newStatus,
    this.note,
    required this.createdAt,
    this.changer,
  });

  factory StatusLog.fromJson(Map<String, dynamic> json) {
    return StatusLog(
      id: _toInt(json['id']),
      oldStatus: json['old_status'],
      newStatus: json['new_status'] ?? '',
      note: json['note'],
      createdAt: json['created_at'] ?? '',
      changer: json['changer'] is Map<String, dynamic>
          ? UserModel.fromJson(json['changer'])
          : null,
    );
  }

  String get newStatusLabel => ui.statusLabel(newStatus);
}

// Notification Model
class NotificationModel {
  final int id;
  final String type;
  final String title;
  final String body;
  final bool isRead;
  final String createdAt;
  final String? readAt;
  final int? requestId;

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    this.readAt,
    this.requestId,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: _toInt(json['id']),
      type: json['type'] ?? 'general',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      isRead: _toBool(json['is_read']),
      createdAt: json['created_at'] ?? '',
      readAt: json['read_at'],
      requestId: _toIntOrNull(json['request_id']),
    );
  }

  NotificationModel markedRead() => NotificationModel(
        id: id,
        type: type,
        title: title,
        body: body,
        isRead: true,
        createdAt: createdAt,
        readAt: readAt ?? DateTime.now().toUtc().toIso8601String(),
        requestId: requestId,
      );
}

// Dashboard Stats Model
class DashboardStats {
  final int total;
  final int pending;
  final int inReview;
  final int approved;
  final int processing;
  final int completed;
  final int rejected;
  final int cancelled;
  final int today;
  final int thisWeek;
  final int thisMonth;

  const DashboardStats({
    this.total = 0,
    this.pending = 0,
    this.inReview = 0,
    this.approved = 0,
    this.processing = 0,
    this.completed = 0,
    this.rejected = 0,
    this.cancelled = 0,
    this.today = 0,
    this.thisWeek = 0,
    this.thisMonth = 0,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      total: _toInt(json['total']),
      pending: _toInt(json['pending']),
      inReview: _toInt(json['in_review']),
      approved: _toInt(json['approved']),
      processing: _toInt(json['processing']),
      completed: _toInt(json['completed']),
      rejected: _toInt(json['rejected']),
      cancelled: _toInt(json['cancelled']),
      today: _toInt(json['today']),
      thisWeek: _toInt(json['this_week']),
      thisMonth: _toInt(json['this_month']),
    );
  }

  int countFor(String status) {
    switch (status) {
      case 'pending':
        return pending;
      case 'in_review':
        return inReview;
      case 'approved':
        return approved;
      case 'processing':
        return processing;
      case 'completed':
        return completed;
      case 'rejected':
        return rejected;
      case 'cancelled':
        return cancelled;
      default:
        return 0;
    }
  }
}
