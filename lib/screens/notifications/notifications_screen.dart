import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/request_provider.dart';
import '../../core/models.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // Color constants
  static const Color white = Color(0xFFFFFFFF);
  static const Color burntOrange = Color(0xFFBE5633);
  static const Color darkBrown = Color(0xFF46291D);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RequestProvider>().fetchNotifications();
    });
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(dt);

      if (difference.inMinutes < 1) return 'Just now';
      if (difference.inHours < 1) return '${difference.inMinutes}m ago';
      if (difference.inDays < 1) return '${difference.inHours}h ago';
      if (difference.inDays < 7) return '${difference.inDays}d ago';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'status_update':
        return Icons.update;
      case 'new_request':
        return Icons.request_page;
      case 'assignment':
        return Icons.person_add;
      default:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    final rp = context.watch<RequestProvider>();

    return Scaffold(
      backgroundColor: white,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: burntOrange,
        foregroundColor: white,
        elevation: 0,
        actions: [
          if (rp.unreadCount > 0)
            TextButton(
              onPressed: () async {
                await rp.markAllRead();
              },
              style: TextButton.styleFrom(
                foregroundColor: white,
              ),
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => rp.fetchNotifications(),
        color: burntOrange,
        child: rp.notifications.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.notifications_none, size: 64, color: darkBrown.withOpacity(0.3)),
              const SizedBox(height: 16),
              Text('No notifications yet', style: TextStyle(color: darkBrown)),
              const SizedBox(height: 8),
              Text('You\'ll be notified when your requests are updated',
                  style: TextStyle(color: darkBrown.withOpacity(0.6))),
            ],
          ),
        )
            : ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: rp.notifications.length,
          itemBuilder: (ctx, index) {
            final notification = rp.notifications[index];
            return Card(
              color: notification.isRead ? white : burntOrange.withOpacity(0.05),
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: burntOrange.withOpacity(0.1),
                  child: Icon(_getIconForType(notification.type), color: burntOrange),
                ),
                title: Text(
                  notification.title,
                  style: TextStyle(
                    fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                    color: darkBrown,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.body,
                      style: TextStyle(color: darkBrown.withOpacity(0.7)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(notification.createdAt),
                      style: TextStyle(fontSize: 11, color: darkBrown.withOpacity(0.5)),
                    ),
                  ],
                ),
                trailing: notification.isRead
                    ? null
                    : Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: burntOrange,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}