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
              style: TextButton.styleFrom(foregroundColor: kWhite),
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: rp.fetchNotifications,
        color: kBurntOrange,
        child: rp.notifications.isEmpty
            ? ListView(
                // Scrollable so pull-to-refresh works when empty.
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(32),
                children: [
                  const SizedBox(height: 80),
                  Icon(Icons.notifications_none, size: 64, color: kDarkBrown.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  const Text('No notifications yet', textAlign: TextAlign.center, style: TextStyle(color: kDarkBrown)),
                  const SizedBox(height: 8),
                  Text(
                    'You\'ll be notified when your requests are updated',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: kDarkBrown.withValues(alpha: 0.6)),
                  ),
                ],
              )
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: rp.notifications.length,
                itemBuilder: (ctx, index) {
                  final notification = rp.notifications[index];
                  return Card(
                    // Opaque blend: a translucent card color lets the shadow show through.
                    color: notification.isRead ? kWhite : Color.alphaBlend(kCreamGold.withValues(alpha: 0.3), kWhite),
                    margin: const EdgeInsets.only(bottom: 10),
                    elevation: notification.isRead ? 0.5 : 1.5,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      onTap: () => _open(context, notification),
                      leading: CircleAvatar(
                        backgroundColor: kBurntOrange.withValues(alpha: 0.1),
                        child: Icon(_iconForType(notification.type), color: kBurntOrange),
                      ),
                      title: Text(
                        notification.title,
                        style: TextStyle(
                          fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.bold,
                          color: kDarkBrown,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 2),
                          Text(notification.body, style: TextStyle(color: kDarkBrown.withValues(alpha: 0.75))),
                          const SizedBox(height: 4),
                          Text(
                            formatRelative(notification.createdAt),
                            style: TextStyle(fontSize: 11, color: kDarkBrown.withValues(alpha: 0.5)),
                          ),
                        ],
                      ),
                      trailing: notification.isRead
                          ? null
                          : Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(color: kBurntOrange, shape: BoxShape.circle),
                            ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
