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
    Widget alerts(IconData icon) => Badge(label: Text('$unread'), isLabelVisible: unread > 0, child: Icon(icon));

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
      bottomNavigationBar: FlatNavBar(
        selectedIndex: _selectedIndex,
        onSelected: _selectTab,
        destinations: [
          const NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          const NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'My Requests',
          ),
          NavigationDestination(
            icon: alerts(Icons.notifications_outlined),
            selectedIcon: alerts(Icons.notifications),
            label: 'Alerts',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
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
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => Future.wait([
            rp.fetchRequests(),
            rp.fetchNotifications(),
            if (rp.categories.isEmpty) rp.fetchCategories(),
          ]),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            children: [
              Greeting(name: user?.name ?? 'Resident', initials: user?.initials ?? 'U'),
              const SizedBox(height: 20),
              HeroCard(
                stats: [
                  ('Total', requests.length),
                  ('Active', active),
                  ('Completed', requests.where((r) => r.status == 'completed').length),
                ],
                title: 'Submit a new\nrequest',
                onTap: () => _openSubmit(context),
              ),
              const SizedBox(height: 32),
              const SectionTitle('Available Services'),
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
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    mainAxisExtent: 116,
                  ),
                  itemCount: rp.categories.length,
                  itemBuilder: (ctx, i) {
                    final cat = rp.categories[i];
                    return _CategoryCard(category: cat, onTap: () => _openSubmit(context, cat));
                  },
                ),
              const SizedBox(height: 32),
              SectionTitle(
                'Recent Requests',
                trailing: requests.isEmpty ? null : ArrowButton(onPressed: onSeeAll, tooltip: 'See all'),
              ),
              const SizedBox(height: 12),
              if (rp.loading && requests.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (rp.error != null && requests.isEmpty)
                _RetryCard(message: rp.error!, onRetry: rp.fetchRequests)
              else if (requests.isEmpty)
                const Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      children: [
                        IconBox(Icons.inbox_outlined, size: 56, color: kWhite),
                        SizedBox(height: 12),
                        Text('No requests yet', style: TextStyle(fontWeight: FontWeight.w700, color: kCharcoal)),
                        SizedBox(height: 4),
                        Text(
                          'Tap the card above to submit your first request',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: kGray),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...requests.take(5).map((req) => RequestListCard(request: req)),
            ],
          ),
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
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                category.name,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kCharcoal, height: 1.2),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Align(
                alignment: Alignment.bottomRight,
                child: Icon(categoryIcon(category.icon), size: 34, color: kOrange),
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
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Row(
          children: [
            const Icon(Icons.wifi_off, color: kGray),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(color: kCharcoal))),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
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
    final hasRemarks = showRemarks && (request.remarks?.isNotEmpty ?? false);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
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
                  IconBox(categoryIcon(request.category?.icon), size: 44, color: kCharcoal),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kCharcoal),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          request.category?.name ?? 'General',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, color: kCharcoal),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${request.trackingCode} · ${formatRelative(request.createdAt)}',
                          style: const TextStyle(fontSize: 12, color: kGray),
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
                  margin: const EdgeInsets.only(top: 10, left: 56),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: kYellowSoft, borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    request.remarks!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: kCharcoal),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
