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
      bottomNavigationBar: FlatNavBar(
        selectedIndex: _selectedIndex,
        onSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.space_dashboard_outlined),
            selectedIcon: Icon(Icons.space_dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Requests',
          ),
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'Users'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
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
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => Future.wait([rp.fetchDashboard(), rp.fetchAdminRequests()]),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            children: [
              Greeting(name: user?.name ?? 'Admin', initials: user?.initials ?? 'A'),
              const SizedBox(height: 20),
              HeroCard(
                stats: [
                  ('Today', stats.today),
                  ('This week', stats.thisWeek),
                  ('This month', stats.thisMonth),
                ],
                title: '${stats.countFor('pending')} waiting\nfor review',
                onTap: () => onOpenRequests('pending'),
              ),
              const SizedBox(height: 32),
              const SectionTitle('Requests by Status'),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 180,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  mainAxisExtent: 92,
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
              const SizedBox(height: 32),
              SectionTitle(
                'Recent Requests',
                trailing: ArrowButton(onPressed: () => onOpenRequests('all'), tooltip: 'See all'),
              ),
              const SizedBox(height: 12),
              if (rp.loading && rp.requests.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (rp.requests.isEmpty)
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Text(rp.error ?? 'No requests yet', style: const TextStyle(color: kBlack)),
                    ),
                  ),
                )
              else
                ...rp.requests.take(8).map((req) => AdminRequestCard(request: req)),
            ],
          ),
        ),
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
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$value',
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w300, color: kBlack, height: 1.1),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Dot(statusColor(status)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      statusLabel(status),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: kGray, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
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
    final urgent = request.priority == 'high' || request.priority == 'urgent';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showRequestDetails(context, request),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconBox(categoryIcon(request.category?.icon), size: 44, color: kBlack),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kBlack),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${request.user?.name ?? 'Unknown'} · ${request.category?.name ?? 'General'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, color: kBlack),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  StatusChip(status: request.status),
                  if (urgent) ...[
                    const SizedBox(height: 6),
                    Tag(
                      label: priorityLabel(request.priority).toUpperCase(),
                      color: priorityColor(request.priority),
                      fontSize: 9,
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
    builder: (_) => _RequestDetailsDialog(request: request, parentContext: context),
  );
}

/// The usual next steps from each status, offered as one-tap buttons (the last is the main one).
const Map<String, List<String>> _nextSteps = {
  'pending': ['rejected', 'in_review'],
  'in_review': ['rejected', 'approved'],
  'approved': ['processing', 'completed'],
  'processing': ['completed'],
};

const Map<String, String> _stepLabels = {
  'in_review': 'Start review',
  'approved': 'Approve',
  'rejected': 'Reject',
  'processing': 'Start processing',
  'completed': 'Mark completed',
};

class _RequestDetailsDialog extends StatefulWidget {
  final RequestModel request;
  // The screen behind the dialog, which outlives it for the snackbar
  final BuildContext parentContext;

  const _RequestDetailsDialog({required this.request, required this.parentContext});

  @override
  State<_RequestDetailsDialog> createState() => _RequestDetailsDialogState();
}

class _RequestDetailsDialogState extends State<_RequestDetailsDialog> {
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _apply(String status) {
    Navigator.pop(context);
    applyStatus(widget.parentContext, widget.request, status, _note.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final request = widget.request;
    final dialogContext = context;
    final steps = request.canUpdateStatus ? (_nextSteps[request.status] ?? const <String>[]) : const <String>[];
    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(24, 16, 8, 0),
      title: Row(
        children: [
          const Expanded(
            child: Text('Request Details'),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: kBlack),
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
                decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Tracking Code', style: TextStyle(fontSize: 11, color: kGray)),
                          Text(request.trackingCode,
                              style: const TextStyle(fontWeight: FontWeight.bold, color: kBlack)),
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
                subtitle:
                    [request.user?.email, request.user?.phone].where((v) => v != null && v.isNotEmpty).join(' · '),
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
              if (steps.isNotEmpty) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _note,
                  maxLength: 1000,
                  minLines: 1,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Note for the resident',
                    hintText: 'Optional, e.g. Bring a valid ID',
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        if (request.canUpdateStatus && steps.isEmpty)
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              showStatusDialog(widget.parentContext, request);
            },
            child: const Text('Change status'),
          ),
        if (steps.isNotEmpty)
          Row(
            children: [
              IconButton(
                tooltip: 'Other status',
                icon: const Icon(Icons.more_horiz),
                onPressed: () {
                  Navigator.pop(dialogContext);
                  showStatusDialog(widget.parentContext, request);
                },
              ),
              for (final step in steps) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: step == steps.last
                      ? ElevatedButton(
                          onPressed: () => _apply(step),
                          style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14)),
                          child: Text(_stepLabels[step]!, textAlign: TextAlign.center),
                        )
                      : OutlinedButton(
                          onPressed: () => _apply(step),
                          style: step == 'rejected'
                              ? OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                                  foregroundColor: kRed,
                                  side: const BorderSide(color: kRed, width: 1.2),
                                )
                              : OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14)),
                          child: Text(_stepLabels[step]!, textAlign: TextAlign.center),
                        ),
                ),
              ],
            ],
          ),
      ],
    );
  }
}

Future<void> showStatusDialog(BuildContext context, RequestModel request) async {
  final result = await showDialog<(String, String)>(
    context: context,
    builder: (_) => _StatusDialog(request: request),
  );
  if (result == null || !context.mounted) return;
  final (status, remarks) = result;
  await applyStatus(context, request, status, remarks);
}

Future<void> applyStatus(BuildContext context, RequestModel request, String status, String remarks) async {
  // Look these up before any await: `context` may be gone by the time the
  // request finishes, but the messenger and provider live above the routes.
  final messenger = ScaffoldMessenger.of(context);
  final requestProvider = context.read<RequestProvider>();

  final ok = await requestProvider.updateStatus(request.id, status, remarks: remarks);

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(ok
          ? '${request.trackingCode} is now ${statusLabel(status)}'
          : (requestProvider.error ?? 'Failed to update status')),
      backgroundColor: ok ? kBlack : kRed,
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
      title: Text('Update ${widget.request.trackingCode}'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: kStaffSettableStatuses
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Row(
                            children: [
                              Dot(statusColor(s)),
                              const SizedBox(width: 8),
                              Text(statusLabel(s), style: const TextStyle(color: kBlack)),
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
  final bool isLongText;

  const _InfoSection({
    required this.icon,
    required this.title,
    required this.content,
    this.subtitle,
    this.isLongText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBox(icon, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 11, color: kGray)),
                const SizedBox(height: 2),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: isLongText ? 13 : 14,
                    fontWeight: isLongText ? FontWeight.normal : FontWeight.w600,
                    color: kBlack,
                    height: isLongText ? 1.4 : null,
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty)
                  Text(subtitle!, style: const TextStyle(fontSize: 12, color: kGray)),
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
      decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.history, size: 18, color: kBlack),
              SizedBox(width: 8),
              Text('Status History', style: TextStyle(fontWeight: FontWeight.w800, color: kBlack)),
            ],
          ),
          const SizedBox(height: 12),
          for (final log in logs)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Tag(label: log.newStatusLabel, color: statusColor(log.newStatus), fontSize: 10),
                  if (log.note?.isNotEmpty ?? false)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(log.note!, style: const TextStyle(fontSize: 12, color: kBlack)),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    [formatDateTime(log.createdAt), if (log.changer != null) log.changer!.name].join(' · '),
                    style: const TextStyle(fontSize: 11, color: kGray),
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
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                isDense: true,
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
                  style: const TextStyle(fontSize: 12, color: kGray),
                ),
                const Spacer(),
                if (_searchQuery.isNotEmpty || status != 'all')
                  TextButton(
                    onPressed: _clearFilters,
                    child: const Text('Clear filters'),
                  ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: rp.fetchAdminRequests,
              child: rp.loading && rp.requests.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : filtered.isEmpty
                      ? EmptyState(icon: Icons.inbox_outlined, message: rp.error ?? 'No requests found')
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
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
    final count = status == 'all' ? all.length : all.where((r) => r.status == status).length;

    return FilterChip(
      label: Text('${status == 'all' ? 'All' : statusLabel(status)} ($count)'),
      labelStyle: TextStyle(color: isSelected ? kWhite : kBlack, fontWeight: FontWeight.w600),
      avatar: status == 'all' ? null : Dot(statusColor(status)),
      selected: isSelected,
      showCheckmark: false,
      onSelected: (_) => widget.filter.value = status,
      backgroundColor: kSurface,
      selectedColor: kBlack,
      side: BorderSide.none,
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
          Center(child: InitialsAvatar(initials: user?.initials ?? 'A', radius: 44)),
          const SizedBox(height: 16),
          Text(
            user?.name ?? 'Admin',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: kBlack, letterSpacing: -0.3),
          ),
          const SizedBox(height: 4),
          Text(user?.email ?? '', textAlign: TextAlign.center, style: const TextStyle(color: kGray)),
          const SizedBox(height: 12),
          Center(child: Tag(label: (user?.roleLabel ?? 'Admin').toUpperCase(), color: kBlack)),
          const SizedBox(height: 40),
          OutlinedButton.icon(
            onPressed: () => confirmLogout(context),
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
