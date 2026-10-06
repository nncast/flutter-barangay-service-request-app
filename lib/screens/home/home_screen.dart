import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/request_provider.dart';
import '../../core/models.dart';
import '../../core/ui_helpers.dart';
import '../requests/my_requests_screen.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_screen.dart';
import '../requests/submit_request_screen.dart';
import '../requests/request_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final rp = context.read<RequestProvider>();
      rp.fetchCategories();
      rp.fetchRequests();
      rp.fetchNotifications();
    });
  }

  void _selectTab(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    final unread = context.select<RequestProvider, int>((rp) => rp.unreadCount);

    return Scaffold(
      // IndexedStack keeps each tab's scroll position and filters.
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          DashboardPage(onSeeAll: () => _selectTab(1)),
          const MyRequestsScreen(),
          const NotificationsScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _selectTab,
        type: BottomNavigationBarType.fixed,
        backgroundColor: kWhite,
        selectedItemColor: kBurntOrange,
        unselectedItemColor: kDarkBrown.withValues(alpha: 0.5),
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          const BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'My Requests'),
          BottomNavigationBarItem(
            icon: Badge(
              label: Text('$unread'),
              isLabelVisible: unread > 0,
              child: const Icon(Icons.notifications),
            ),
            label: 'Alerts',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  final VoidCallback? onSeeAll;

  const DashboardPage({super.key, this.onSeeAll});

  Future<void> _openSubmit(BuildContext context, [CategoryModel? category]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SubmitRequestScreen(preSelectedCategory: category)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final rp = context.watch<RequestProvider>();
    final requests = rp.requests;
    final active = requests.where((r) => !['completed', 'rejected', 'cancelled'].contains(r.status)).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: RefreshIndicator(
        color: kBurntOrange,
        onRefresh: () => Future.wait([
          rp.fetchRequests(),
          rp.fetchNotifications(),
          if (rp.categories.isEmpty) rp.fetchCategories(),
        ]),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Welcome Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: kBurntOrange.withValues(alpha: 0.1),
                      child: Text(
                        user?.initials ?? 'U',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kBurntOrange),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Welcome,', style: TextStyle(color: kDarkBrown.withValues(alpha: 0.6))),
                          Text(
                            user?.name ?? 'Resident',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kDarkBrown),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Quick Stats
            Row(
              children: [
                Expanded(child: _StatCard(title: 'Total', value: requests.length, color: kBurntOrange)),
                const SizedBox(width: 12),
                Expanded(child: _StatCard(title: 'Active', value: active, color: statusColor('in_review'))),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Completed',
                    value: requests.where((r) => r.status == 'completed').length,
                    color: statusColor('completed'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Submit Request Button
            ElevatedButton.icon(
              onPressed: () => _openSubmit(context),
              icon: const Icon(Icons.add),
              label: const Text('Submit New Request'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),

            // Categories
            const Text(
              'Available Services',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kDarkBrown),
            ),
            const SizedBox(height: 12),
            if (rp.categories.isEmpty && rp.categoriesFailed)
              _RetryCard(
                message: 'Couldn\'t load services.',
                onRetry: rp.fetchCategories,
              )
            else if (rp.categories.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 220,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  mainAxisExtent: 110,
                ),
                itemCount: rp.categories.length,
                itemBuilder: (ctx, i) {
                  final cat = rp.categories[i];
                  return _CategoryCard(category: cat, onTap: () => _openSubmit(context, cat));
                },
              ),
            const SizedBox(height: 24),

            // Recent Requests
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Requests',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kDarkBrown),
                ),
                if (requests.isNotEmpty)
                  TextButton(
                    onPressed: onSeeAll,
                    style: TextButton.styleFrom(foregroundColor: kBurntOrange),
                    child: const Text('See all'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (rp.loading && requests.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (rp.error != null && requests.isEmpty)
              _RetryCard(message: rp.error!, onRetry: rp.fetchRequests)
            else if (requests.isEmpty)
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.inbox, size: 48, color: kDarkBrown.withValues(alpha: 0.3)),
                      const SizedBox(height: 8),
                      const Text('No requests yet', style: TextStyle(color: kDarkBrown)),
                      const SizedBox(height: 4),
                      Text(
                        'Tap the button above to submit your first request',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: kDarkBrown.withValues(alpha: 0.6)),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...requests.take(5).map((req) => RequestListCard(request: req)),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final int value;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Text(
              '$value',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(color: kDarkBrown.withValues(alpha: 0.6))),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback onTap;

  const _CategoryCard({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = colorFromHex(category.colorHex);
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(categoryIcon(category.icon), size: 22, color: color),
              ),
              const SizedBox(height: 8),
              Text(
                category.name,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kDarkBrown),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RetryCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _RetryCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.wifi_off, color: kDarkBrown.withValues(alpha: 0.5)),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(color: kDarkBrown))),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(foregroundColor: kBurntOrange),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Request row used on the resident dashboard and the My Requests list.
class RequestListCard extends StatelessWidget {
  final RequestModel request;
  final bool showRemarks;

  const RequestListCard({super.key, required this.request, this.showRemarks = false});

  @override
  Widget build(BuildContext context) {
    final color = statusColor(request.status);
    final hasRemarks = showRemarks && (request.remarks?.isNotEmpty ?? false);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => RequestDetailScreen(requestId: request.id)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.12),
                    child: Icon(statusIcon(request.status), color: color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: kDarkBrown, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${request.trackingCode} · ${request.category?.name ?? 'General'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: kDarkBrown.withValues(alpha: 0.6)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formatRelative(request.createdAt),
                          style: TextStyle(fontSize: 11, color: kDarkBrown.withValues(alpha: 0.5)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusChip(status: request.status),
                ],
              ),
              if (hasRemarks)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 10, left: 52),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kCreamGold.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    request.remarks!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: kDarkBrown),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
