// User Model
class UserModel {
  final int id;
  final String name;  // This matches Laravel's 'name' field
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
      id: json['id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      address: json['address'],
      role: json['role'] ?? 'resident',
      isActive: json['is_active'] == 1 || json['is_active'] == true,
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
  bool get isStaff => role == 'staff' || role == 'admin';
  bool get isResident => role == 'resident';

  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
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
      id: json['id'],
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'],
      icon: json['icon'],
      colorHex: json['color_hex'] ?? '#BE5633',
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      sortOrder: json['sort_order'] ?? 0,
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
  final String? completedAt;
  final CategoryModel? category;
  final UserModel? user;
  final UserModel? assignedTo;
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
    this.completedAt,
    this.category,
    this.user,
    this.assignedTo,
    this.logs = const [],
  });

  factory RequestModel.fromJson(Map<String, dynamic> json) {
    return RequestModel(
      id: json['id'],
      trackingCode: json['tracking_code'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      priority: json['priority'] ?? 'normal',
      status: json['status'] ?? 'pending',
      remarks: json['remarks'],
      createdAt: json['created_at'] ?? '',
      completedAt: json['completed_at'],
      category: json['category'] != null
          ? CategoryModel.fromJson(json['category'])
          : null,
      user: json['user'] != null
          ? UserModel.fromJson(json['user'])
          : null,
      assignedTo: json['assigned_to'] != null && json['assigned_to'] is Map
          ? UserModel.fromJson(json['assigned_to'])
          : null,
      logs: (json['logs'] as List? ?? [])
          .map((l) => StatusLog.fromJson(l))
          .toList(),
    );
  }

  bool get canCancel => status == 'pending' || status == 'in_review';
  bool get isPending => status == 'pending';
  bool get isInReview => status == 'in_review';
  bool get isApproved => status == 'approved';
  bool get isProcessing => status == 'processing';
  bool get isCompleted => status == 'completed';
  bool get isRejected => status == 'rejected';
  bool get isCancelled => status == 'cancelled';

  String get statusLabel {
    switch (status) {
      case 'in_review': return 'In Review';
      case 'approved': return 'Approved';
      case 'processing': return 'Processing';
      case 'completed': return 'Completed';
      case 'rejected': return 'Rejected';
      case 'cancelled': return 'Cancelled';
      default: return status[0].toUpperCase() + status.substring(1);
    }
  }
}

// Status Log Model
class StatusLog {
  final int id;
  final String oldStatus;
  final String newStatus;
  final String? note;
  final String createdAt;
  final UserModel? changer;

  StatusLog({
    required this.id,
    required this.oldStatus,
    required this.newStatus,
    this.note,
    required this.createdAt,
    this.changer,
  });

  factory StatusLog.fromJson(Map<String, dynamic> json) {
    return StatusLog(
      id: json['id'],
      oldStatus: json['old_status'] ?? '',
      newStatus: json['new_status'] ?? '',
      note: json['note'],
      createdAt: json['created_at'] ?? '',
      changer: json['changer'] != null
          ? UserModel.fromJson(json['changer'])
          : null,
    );
  }

  String get newStatusLabel {
    switch (newStatus) {
      case 'in_review': return 'In Review';
      case 'approved': return 'Approved';
      case 'processing': return 'Processing';
      case 'completed': return 'Completed';
      case 'rejected': return 'Rejected';
      case 'cancelled': return 'Cancelled';
      default: return newStatus[0].toUpperCase() + newStatus.substring(1);
    }
  }
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
      id: json['id'],
      type: json['type'] ?? 'general',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      isRead: json['is_read'] == 1 || json['is_read'] == true,
      createdAt: json['created_at'] ?? '',
      readAt: json['read_at'],
      requestId: json['request_id'],
    );
  }
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
  final int today;
  final int thisWeek;
  final int thisMonth;

  DashboardStats({
    required this.total,
    required this.pending,
    required this.inReview,
    required this.approved,
    required this.processing,
    required this.completed,
    required this.rejected,
    required this.today,
    required this.thisWeek,
    required this.thisMonth,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      total: json['total'] ?? 0,
      pending: json['pending'] ?? 0,
      inReview: json['in_review'] ?? 0,
      approved: json['approved'] ?? 0,
      processing: json['processing'] ?? 0,
      completed: json['completed'] ?? 0,
      rejected: json['rejected'] ?? 0,
      today: json['today'] ?? 0,
      thisWeek: json['this_week'] ?? 0,
      thisMonth: json['this_month'] ?? 0,
    );
  }
}