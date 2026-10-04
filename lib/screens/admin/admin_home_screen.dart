import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/request_provider.dart';
import '../../core/models.dart';
import '../../core/session.dart';
import '../../core/ui_helpers.dart';
import 'admin_users_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _selectedIndex = 0;

  /// Status filter on the Requests tab; the dashboard sets it when a
  /// status tile is tapped.
  final ValueNotifier<String> _requestFilter = ValueNotifier('all');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final rp = context.read<RequestProvider>();
      rp.fetchDashboard();
      rp.fetchAdminRequests();
    });
  }

  @override
  void dispose() {
    _requestFilter.dispose();
    super.dispose();
  }

  void _openRequests(String status) {
    _requestFilter.value = status;
    setState(() => _selectedIndex = 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          AdminDashboardPage(onOpenRequests: _openRequests),
          AdminRequestsPage(filter: _requestFilter),
          const AdminUsersScreen(),
          const AdminProfilePage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: kWhite,
        selectedItemColor: kBurntOrange,
        unselectedItemColor: kDarkBrown.withOpacity(0.5),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Requests'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Users'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class AdminDashboardPage extends StatelessWidget {
  final void Function(String status) onOpenRequests;

  const AdminDashboardPage({super.key, required this.onOpenRequests});

  @override
  Widget build(BuildContext context) {
    final rp = context.watch<RequestProvider>();
    final user = context.watch<AuthProvider>().user;
    final stats = rp.dashboard;

    return Scaffold(
      appBar: AppBar(title: Text(user?.isAdmin == true ? 'Admin Dashboard' : 'Staff Dashboard')),
      body: RefreshIndicator(
        color: kBurntOrange,
        onRefresh: () => Future.wait([rp.fetchDashboard(), rp.fetchAdminRequests()]),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Welcome
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: kBurntOrange.withOpacity(0.1),
                          child: Text(
                            user?.initials ?? 'A',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kBurntOrange),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Welcome,', style: TextStyle(color: kDarkBrown.withOpacity(0.6))),
                              Text(
                                user?.name ?? 'Admin',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kDarkBrown),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Divider(height: 24, color: kDarkBrown.withOpacity(0.12)),
                    Row(
                      children: [
                        _PeriodStat(label: 'Today', value: stats.today),
                        _PeriodStat(label: 'This week', value: stats.thisWeek),
                        _PeriodStat(label: 'This month', value: stats.thisMonth),
                        _PeriodStat(label: 'All time', value: stats.total),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Requests by Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kDarkBrown),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 180,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                mainAxisExtent: 88,
              ),
              itemCount: kStaffSettableStatuses.length,
              itemBuilder: (ctx, i) {
                final status = kStaffSettableStatuses[i];
                return _AdminStatCard(
                  status: status,
                  value: stats.countFor(status),
                  onTap: () => onOpenRequests(status),
                );
              },
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Requests',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kDarkBrown),
                ),
                TextButton(
                  onPressed: () => onOpenRequests('all'),
                  style: TextButton.styleFrom(foregroundColor: kBurntOrange),
                  child: const Text('See all'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (rp.loading && rp.requests.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (rp.requests.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Text(rp.error ?? 'No requests yet', style: const TextStyle(color: kDarkBrown)),
                  ),
                ),
              )
            else
              ...rp.requests.take(8).map((req) => AdminRequestCard(request: req)),
          ],
        ),
      ),
    );
  }
}

class _PeriodStat extends StatelessWidget {
  final String label;
  final int value;

  const _PeriodStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text('$value', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kBurntOrange)),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: kDarkBrown.withOpacity(0.6)),
          ),
        ],
      ),
    );
  }
}

class _AdminStatCard extends StatelessWidget {
  final String status;
  final int value;
  final VoidCallback onTap;

  const _AdminStatCard({required this.status, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = statusColor(status);
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: color.withOpacity(0.12),
                child: Icon(statusIcon(status), size: 18, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$value', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
                    Text(
                      statusLabel(status),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: kDarkBrown.withOpacity(0.65)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Request row for staff, with the requester's name. Tapping opens the
/// details dialog, from which the status can be updated.
class AdminRequestCard extends StatelessWidget {
  final RequestModel request;

  const AdminRequestCard({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    final color = statusColor(request.status);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showRequestDetails(context, request),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.12),
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
                      '${request.user?.name ?? 'Unknown'} · ${request.category?.name ?? 'General'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: kDarkBrown.withOpacity(0.65)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${request.trackingCode} · ${formatRelative(request.createdAt)}',
                      style: TextStyle(fontSize: 11, color: kDarkBrown.withOpacity(0.5)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  StatusChip(status: request.status, fontSize: 10),
                  if (request.priority == 'high' || request.priority == 'urgent') ...[
                    const SizedBox(height: 6),
                    Text(
                      priorityLabel(request.priority).toUpperCase(),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: priorityColor(request.priority),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void showRequestDetails(BuildContext context, RequestModel request) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(24, 16, 8, 0),
      title: Row(
        children: [
          const Expanded(
            child: Text('Request Details', style: TextStyle(color: kDarkBrown, fontWeight: FontWeight.bold)),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: kDarkBrown),
            onPressed: () => Navigator.pop(dialogContext),
          ),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor(request.status).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tracking Code', style: TextStyle(fontSize: 11, color: kDarkBrown.withOpacity(0.6))),
                          Text(request.trackingCode,
                              style: const TextStyle(fontWeight: FontWeight.bold, color: kDarkBrown)),
                        ],
                      ),
                    ),
                    StatusChip(status: request.status, fontSize: 12),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _InfoSection(
                icon: Icons.person,
                title: 'Requested By',
                content: request.user?.name ?? 'Unknown',
                subtitle: [request.user?.email, request.user?.phone]
                    .where((v) => v != null && v.isNotEmpty)
                    .join(' · '),
              ),
              _InfoSection(icon: Icons.title, title: 'Title', content: request.title),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _InfoSection(
                      icon: Icons.category,
                      title: 'Category',
                      content: request.category?.name ?? 'Unknown',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _InfoSection(
                      icon: Icons.flag_outlined,
                      title: 'Priority',
                      content: priorityLabel(request.priority),
                      contentColor: priorityColor(request.priority),
                    ),
                  ),
                ],
              ),
              _InfoSection(
                icon: Icons.description,
                title: 'Description',
                content: request.description,
                isLongText: true,
              ),
              _InfoSection(
                icon: Icons.calendar_today,
                title: 'Submitted',
                content: formatDateTime(request.createdAt),
              ),
              if (request.remarks?.isNotEmpty ?? false)
                _InfoSection(
                  icon: Icons.comment,
                  title: 'Remarks',
                  content: request.remarks!,
                  isLongText: true,
                ),
              if (request.logs.isNotEmpty) _HistorySection(logs: request.logs),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          style: TextButton.styleFrom(foregroundColor: kDarkBrown),
          child: const Text('Close'),
        ),
        if (request.canUpdateStatus)
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(dialogContext);
              showStatusDialog(context, request);
            },
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('Update Status'),
          ),
      ],
    ),
  );
}

Future<void> showStatusDialog(BuildContext context, RequestModel request) async {
  // Look these up before any await: `context` may be gone by the time the
  // request finishes, but the messenger and provider live above the routes.
  final messenger = ScaffoldMessenger.of(context);
  final requestProvider = context.read<RequestProvider>();

  final result = await showDialog<(String, String)>(
    context: context,
    builder: (_) => _StatusDialog(request: request),
  );
  if (result == null) return;

  final (status, remarks) = result;
  final ok = await requestProvider.updateStatus(request.id, status, remarks: remarks);

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(ok
          ? '${request.trackingCode} is now ${statusLabel(status)}'
          : (requestProvider.error ?? 'Failed to update status')),
      backgroundColor: ok ? Colors.green.shade700 : kBurntOrange,
    ));
}

class _StatusDialog extends StatefulWidget {
  final RequestModel request;

  const _StatusDialog({required this.request});

  @override
  State<_StatusDialog> createState() => _StatusDialogState();
}

class _StatusDialogState extends State<_StatusDialog> {
  late String _status = kStaffSettableStatuses.contains(widget.request.status) ? widget.request.status : 'pending';
  late final TextEditingController _remarks = TextEditingController(text: widget.request.remarks ?? '');

  @override
  void dispose() {
    // Disposed with the dialog's widget, after its closing animation.
    _remarks.dispose();
    super.dispose();
  }

  bool get _unchanged =>
      _status == widget.request.status && _remarks.text.trim() == (widget.request.remarks ?? '').trim();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Update ${widget.request.trackingCode}', style: const TextStyle(color: kDarkBrown)),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                items: kStaffSettableStatuses
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Row(
                            children: [
                              Icon(statusIcon(s), size: 18, color: statusColor(s)),
                              const SizedBox(width: 8),
                              Text(statusLabel(s), style: const TextStyle(color: kDarkBrown)),
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _status = v ?? _status),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _remarks,
                onChanged: (_) => setState(() {}),
                maxLength: 1000,
                decoration: const InputDecoration(
                  labelText: 'Remarks for the resident (optional)',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
                minLines: 2,
                maxLines: 4,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(foregroundColor: kDarkBrown),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _unchanged ? null : () => Navigator.pop(context, (_status, _remarks.text.trim())),
          child: const Text('Update'),
        ),
      ],
    );
  }
}

class _InfoSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;
  final String? subtitle;
  final Color? contentColor;
  final bool isLongText;

  const _InfoSection({
    required this.icon,
    required this.title,
    required this.content,
    this.subtitle,
    this.contentColor,
    this.isLongText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: kBurntOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: kBurntOrange),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 11, color: kDarkBrown.withOpacity(0.6))),
                const SizedBox(height: 2),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: isLongText ? 13 : 14,
                    fontWeight: isLongText ? FontWeight.normal : FontWeight.w600,
                    color: contentColor ?? kDarkBrown,
                    height: isLongText ? 1.4 : null,
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty)
                  Text(subtitle!, style: TextStyle(fontSize: 12, color: kDarkBrown.withOpacity(0.55))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistorySection extends StatelessWidget {
  final List<StatusLog> logs;

  const _HistorySection({required this.logs});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kDarkBrown.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.history, size: 18, color: kBurntOrange),
              SizedBox(width: 8),
              Text('Status History', style: TextStyle(fontWeight: FontWeight.bold, color: kDarkBrown)),
            ],
          ),
          const SizedBox(height: 12),
          for (final log in logs)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 5),
                    decoration: BoxDecoration(color: statusColor(log.newStatus), shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          log.newStatusLabel,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: statusColor(log.newStatus),
                            fontSize: 12,
                          ),
                        ),
                        if (log.note?.isNotEmpty ?? false)
                          Text(log.note!, style: TextStyle(fontSize: 12, color: kDarkBrown.withOpacity(0.75))),
                        Text(
                          [formatDateTime(log.createdAt), if (log.changer != null) log.changer!.name].join(' · '),
                          style: TextStyle(fontSize: 10, color: kDarkBrown.withOpacity(0.5)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class AdminRequestsPage extends StatefulWidget {
  final ValueNotifier<String> filter;

  const AdminRequestsPage({super.key, required this.filter});

  @override
  State<AdminRequestsPage> createState() => _AdminRequestsPageState();
}

class _AdminRequestsPageState extends State<AdminRequestsPage> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.filter.addListener(_onFilterChanged);
  }

  @override
  void dispose() {
    widget.filter.removeListener(_onFilterChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onFilterChanged() => setState(() {});

  void _clearFilters() {
    _searchController.clear();
    setState(() => _searchQuery = '');
    widget.filter.value = 'all';
  }

  @override
  Widget build(BuildContext context) {
    final rp = context.watch<RequestProvider>();
    final status = widget.filter.value;
    final query = _searchQuery.trim().toLowerCase();

    final filtered = rp.requests.where((r) {
      if (status != 'all' && r.status != status) return false;
      if (query.isEmpty) return true;
      return r.title.toLowerCase().contains(query) ||
          r.trackingCode.toLowerCase().contains(query) ||
          (r.user?.name.toLowerCase().contains(query) ?? false) ||
          (r.category?.name.toLowerCase().contains(query) ?? false);
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Requests'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: rp.fetchAdminRequests,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search title, code, requester, category',
                hintStyle: TextStyle(color: kDarkBrown.withOpacity(0.5)),
                prefixIcon: const Icon(Icons.search, color: kBurntOrange),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: kDarkBrown),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: kDarkBrown.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: kBurntOrange, width: 2),
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final s in ['all', ...kRequestStatuses])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildFilterChip(s, rp.requests),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '${filtered.length} request${filtered.length == 1 ? '' : 's'}',
                  style: TextStyle(fontSize: 12, color: kDarkBrown.withOpacity(0.6)),
                ),
                const Spacer(),
                if (_searchQuery.isNotEmpty || status != 'all')
                  TextButton(
                    onPressed: _clearFilters,
                    style: TextButton.styleFrom(foregroundColor: kBurntOrange),
                    child: const Text('Clear filters'),
                  ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: kBurntOrange,
              onRefresh: rp.fetchAdminRequests,
              child: rp.loading && rp.requests.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : filtered.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            const SizedBox(height: 80),
                            Icon(Icons.inbox, size: 64, color: kDarkBrown.withOpacity(0.3)),
                            const SizedBox(height: 16),
                            Text(
                              rp.error ?? 'No requests found',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: kDarkBrown),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                          itemCount: filtered.length,
                          itemBuilder: (ctx, index) => AdminRequestCard(request: filtered[index]),
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String status, List<RequestModel> all) {
    final isSelected = widget.filter.value == status;
    final color = status == 'all' ? kBurntOrange : statusColor(status);
    final count = status == 'all' ? all.length : all.where((r) => r.status == status).length;

    return FilterChip(
      label: Text(
        '${status == 'all' ? 'All' : statusLabel(status)} ($count)',
        style: TextStyle(
          color: isSelected ? kWhite : color,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        ),
      ),
      selected: isSelected,
      showCheckmark: false,
      onSelected: (_) => widget.filter.value = status,
      backgroundColor: kWhite,
      selectedColor: color,
      side: BorderSide(color: isSelected ? color : kDarkBrown.withOpacity(0.25)),
      shape: const StadiumBorder(),
    );
  }
}

class AdminProfilePage extends StatelessWidget {
  const AdminProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 24),
          Center(
            child: CircleAvatar(
              radius: 50,
              backgroundColor: kBurntOrange.withOpacity(0.1),
              child: Text(
                user?.initials ?? 'A',
                style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: kBurntOrange),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            user?.name ?? 'Admin',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kDarkBrown),
          ),
          const SizedBox(height: 6),
          Text(
            user?.email ?? '',
            textAlign: TextAlign.center,
            style: TextStyle(color: kDarkBrown.withOpacity(0.6)),
          ),
          const SizedBox(height: 10),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: kBurntOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                (user?.roleLabel ?? 'Admin').toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold, color: kBurntOrange),
              ),
            ),
          ),
          const SizedBox(height: 40),
          OutlinedButton.icon(
            onPressed: () => confirmLogout(context),
            icon: const Icon(Icons.logout, color: kBurntOrange),
            label: const Text('Logout', style: TextStyle(color: kBurntOrange)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: kBurntOrange),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }
}
