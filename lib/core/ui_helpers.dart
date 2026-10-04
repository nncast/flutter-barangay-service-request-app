import 'package:flutter/material.dart';

// Shared colors and formatting so every screen shows statuses the same way.

const Color kWhite = Color(0xFFFFFFFF);
const Color kCreamGold = Color(0xFFFAD793);
const Color kBurntOrange = Color(0xFFBE5633);
const Color kDarkBrown = Color(0xFF46291D);

/// Request statuses in workflow order. `cancelled` is set by residents only.
const List<String> kRequestStatuses = [
  'pending',
  'in_review',
  'approved',
  'processing',
  'completed',
  'rejected',
  'cancelled',
];

/// Statuses staff can set from the app.
const List<String> kStaffSettableStatuses = [
  'pending',
  'in_review',
  'approved',
  'processing',
  'completed',
  'rejected',
];

String statusLabel(String? status) {
  switch (status) {
    case 'pending':
      return 'Pending';
    case 'in_review':
      return 'In Review';
    case 'approved':
      return 'Approved';
    case 'processing':
      return 'Processing';
    case 'completed':
      return 'Completed';
    case 'rejected':
      return 'Rejected';
    case 'cancelled':
      return 'Cancelled';
    case null:
    case '':
      return 'Unknown';
    default:
      return status[0].toUpperCase() + status.substring(1).replaceAll('_', ' ');
  }
}

/// Matches the colors returned by the API's `status_color`.
Color statusColor(String? status) {
  switch (status) {
    case 'pending':
      return const Color(0xFFD97706);
    case 'in_review':
      return const Color(0xFF2563EB);
    case 'approved':
      return const Color(0xFF059669);
    case 'processing':
      return const Color(0xFF7C3AED);
    case 'completed':
      return const Color(0xFF0D9488);
    case 'rejected':
      return const Color(0xFFDC2626);
    default:
      return const Color(0xFF6B7280);
  }
}

IconData statusIcon(String? status) {
  switch (status) {
    case 'pending':
      return Icons.hourglass_empty;
    case 'in_review':
      return Icons.manage_search;
    case 'approved':
      return Icons.thumb_up_alt_outlined;
    case 'processing':
      return Icons.autorenew;
    case 'completed':
      return Icons.check_circle_outline;
    case 'rejected':
      return Icons.block;
    case 'cancelled':
      return Icons.cancel_outlined;
    default:
      return Icons.assignment;
  }
}

String priorityLabel(String priority) =>
    priority.isEmpty ? 'Normal' : priority[0].toUpperCase() + priority.substring(1);

Color priorityColor(String priority) {
  switch (priority) {
    case 'low':
      return Colors.green;
    case 'high':
      return Colors.orange;
    case 'urgent':
      return Colors.red;
    default:
      return kBurntOrange;
  }
}

/// Maps the icon names stored on categories (Heroicons-style) to Material icons.
IconData categoryIcon(String? name) {
  switch (name) {
    case 'document_text':
      return Icons.description_outlined;
    case 'shield_check':
      return Icons.verified_user_outlined;
    case 'briefcase':
      return Icons.business_center_outlined;
    case 'exclamation_circle':
      return Icons.report_problem_outlined;
    case 'document_report':
      return Icons.assignment_late_outlined;
    case 'home':
      return Icons.home_outlined;
    case 'heart':
      return Icons.volunteer_activism_outlined;
    case 'dots_horizontal':
      return Icons.more_horiz;
    default:
      return Icons.category_outlined;
  }
}

Color colorFromHex(String? hex, {Color fallback = kBurntOrange}) {
  if (hex == null) return fallback;
  final value = hex.replaceFirst('#', '');
  if (value.length != 6) return fallback;
  final parsed = int.tryParse(value, radix: 16);
  return parsed == null ? fallback : Color(0xFF000000 | parsed);
}

DateTime? _parseLocal(String value) => DateTime.tryParse(value)?.toLocal();

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// e.g. "Oct 4, 2026 · 2:05 PM", in the device's time zone.
String formatDateTime(String value) {
  final dt = _parseLocal(value);
  if (dt == null) return value;
  final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
  final minute = dt.minute.toString().padLeft(2, '0');
  final suffix = dt.hour < 12 ? 'AM' : 'PM';
  return '${_months[dt.month - 1]} ${dt.day}, ${dt.year} · $hour:$minute $suffix';
}

/// e.g. "Just now", "5m ago", "3h ago", "2d ago", then a date.
String formatRelative(String value) {
  final dt = _parseLocal(value);
  if (dt == null) return value;
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inDays < 1) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${_months[dt.month - 1]} ${dt.day}, ${dt.year}';
}

/// Small rounded label used for request statuses everywhere.
class StatusChip extends StatelessWidget {
  final String status;
  final double fontSize;

  const StatusChip({super.key, required this.status, this.fontSize = 11});

  @override
  Widget build(BuildContext context) {
    final color = statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        statusLabel(status),
        style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}
