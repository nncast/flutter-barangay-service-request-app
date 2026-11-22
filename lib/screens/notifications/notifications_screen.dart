import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/request_provider.dart';
import '../../core/models.dart';
import '../../core/ui_helpers.dart';
import '../requests/request_detail_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  IconData _iconForType(String type) {
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

  void _open(BuildContext context, NotificationModel notification) {
    context.read<RequestProvider>().markRead(notification);
    final requestId = notification.requestId;
    if (requestId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => RequestDetailScreen(requestId: requestId)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final rp = context.watch<RequestProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (rp.unreadCount > 0)
            TextButton(
              onPressed: rp.markAllRead,
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: rp.fetchNotifications,
        child: rp.notifications.isEmpty
            ? const EmptyState(
                icon: Icons.notifications_none,
                message: 'No notifications yet',
                hint: 'You\'ll be notified when your requests are updated',
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: rp.notifications.length,
                itemBuilder: (ctx, index) {
                  final notification = rp.notifications[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      onTap: () => _open(context, notification),
                      leading: IconBox(_iconForType(notification.type), size: 40, color: notification.isRead ? kSurface : kYellow),
                      title: Text(
                        notification.title,
                        style: TextStyle(
                          fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.w800,
                          color: kBlack,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 2),
                          Text(notification.body, style: TextStyle(color: kBlack.withValues(alpha: 0.75))),
                          const SizedBox(height: 4),
                          Text(
                            formatRelative(notification.createdAt),
                            style: const TextStyle(fontSize: 12, color: kGray),
                          ),
                        ],
                      ),
                      trailing: notification.isRead
                          ? null
                          : Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(color: kOrange, shape: BoxShape.circle),
                            ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
