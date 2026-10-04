import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/request_provider.dart';
import '../../core/ui_helpers.dart';
import '../home/home_screen.dart';
import 'submit_request_screen.dart';

class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> with SingleTickerProviderStateMixin {
  static const List<String> _tabs = ['all', ...kRequestStatuses];
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Filtering is local, so switching tabs doesn't hit the API again.
    _tabController = TabController(length: _tabs.length, vsync: this)
      ..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rp = context.watch<RequestProvider>();
    final current = _tabs[_tabController.index];
    final filtered = current == 'all' ? rp.requests : rp.requests.where((r) => r.status == current).toList();

    int countFor(String status) =>
        status == 'all' ? rp.requests.length : rp.requests.where((r) => r.status == status).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Requests'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: kWhite,
          labelColor: kWhite,
          unselectedLabelColor: kWhite.withOpacity(0.7),
          tabs: _tabs.map((status) {
            final label = status == 'all' ? 'All' : statusLabel(status);
            final count = countFor(status);
            return Tab(text: count > 0 ? '$label ($count)' : label);
          }).toList(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SubmitRequestScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('New Request'),
        backgroundColor: kBurntOrange,
        foregroundColor: kWhite,
      ),
      body: RefreshIndicator(
        color: kBurntOrange,
        onRefresh: rp.fetchRequests,
        child: rp.loading && rp.requests.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : filtered.isEmpty
                ? _EmptyState(
                    message: rp.error ??
                        (current == 'all'
                            ? 'No requests yet'
                            : 'No ${statusLabel(current).toLowerCase()} requests'),
                    hint: rp.error != null
                        ? 'Pull down to try again'
                        : current == 'all'
                            ? 'Tap + New Request to create one'
                            : null,
                    onShowAll: current == 'all' ? null : () => _tabController.animateTo(0),
                  )
                : ListView.builder(
                    // Leaves room so the last card isn't hidden behind the button.
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, index) => RequestListCard(request: filtered[index], showRemarks: true),
                  ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  final String? hint;
  final VoidCallback? onShowAll;

  const _EmptyState({required this.message, this.hint, this.onShowAll});

  @override
  Widget build(BuildContext context) {
    // A scrollable child so pull-to-refresh works on an empty list.
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 120),
        Icon(Icons.inbox, size: 64, color: kDarkBrown.withOpacity(0.3)),
        const SizedBox(height: 16),
        Text(message, textAlign: TextAlign.center, style: const TextStyle(color: kDarkBrown)),
        if (hint != null) ...[
          const SizedBox(height: 8),
          Text(hint!, textAlign: TextAlign.center, style: TextStyle(color: kDarkBrown.withOpacity(0.6))),
        ],
        if (onShowAll != null)
          Center(
            child: TextButton(
              onPressed: onShowAll,
              style: TextButton.styleFrom(foregroundColor: kBurntOrange),
              child: const Text('View all requests'),
            ),
          ),
      ],
    );
  }
}
