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
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          indicatorPadding: const EdgeInsets.symmetric(vertical: 6),
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
      ),
      body: RefreshIndicator(
        onRefresh: rp.fetchRequests,
        child: rp.loading && rp.requests.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : filtered.isEmpty
                ? EmptyState(
                    icon: Icons.inbox_outlined,
                    message: rp.error ??
                        (current == 'all'
                            ? 'No requests yet'
                            : 'No ${statusLabel(current).toLowerCase()} requests'),
                    hint: rp.error != null
                        ? 'Pull down to try again'
                        : current == 'all'
                            ? 'Tap + New Request to create one'
                            : null,
                    action: current == 'all'
                        ? null
                        : TextButton(
                            onPressed: () => _tabController.animateTo(0),
                            child: const Text('View all requests'),
                          ),
                  )
                : ListView.builder(
                    // Leaves room so the last card isn't hidden behind the button.
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, index) => RequestListCard(request: filtered[index], showRemarks: true),
                  ),
      ),
    );
  }
}
