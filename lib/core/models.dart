// User Model
class UserModel {
  final int id;
  final String name;
  final String fullName;
  final String email;
  final String? phone;
  final String? address;
  final String role;

  UserModel({
    required this.id,
    required this.name,
    required this.fullName,
    required this.email,
    this.phone,
    this.address,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'] ?? '',
      fullName: json['full_name'] ?? json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      address: json['address'],
      role: json['role'] ?? 'resident',
    );
  }

  bool get isAdmin => role == 'admin';
  bool get isStaff => role == 'staff' || role == 'admin';
  String get initials {
    final parts = fullName.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U';
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

  CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.icon,
    required this.colorHex,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'],
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'],
      icon: json['icon'],
      colorHex: json['color_hex'] ?? '#2563EB',
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
  final CategoryModel? category;
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
    this.category,
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
      category: json['category'] != null
          ? CategoryModel.fromJson(json['category'])
          : null,
      logs: (json['logs'] as List? ?? [])
          .map((l) => StatusLog.fromJson(l))
          .toList(),
    );
  }

  bool get canCancel => status == 'pending';
}

// Status Log Model
class StatusLog {
  final int id;
  final String oldStatus;
  final String newStatus;
  final String? note;
  final String createdAt;

  StatusLog({
    required this.id,
    required this.oldStatus,
    required this.newStatus,
    this.note,
    required this.createdAt,
  });

  factory StatusLog.fromJson(Map<String, dynamic> json) {
    return StatusLog(
      id: json['id'],
      oldStatus: json['old_status'] ?? '',
      newStatus: json['new_status'] ?? '',
      note: json['note'],
      createdAt: json['created_at'] ?? '',
    );
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

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      isRead: json['is_read'] == 1 || json['is_read'] == true,
      createdAt: json['created_at'] ?? '',
    );
  }
}