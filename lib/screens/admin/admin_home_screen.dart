import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/request_provider.dart';
import '../../core/models.dart';
import 'admin_users_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _selectedIndex = 0;

  // Color constants
  static const Color white = Color(0xFFFFFFFF);
  static const Color burntOrange = Color(0xFFBE5633);
  static const Color darkBrown = Color(0xFF46291D);

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
  Widget build(BuildContext context) {
    final pages = [
      const AdminDashboardPage(),
      const AdminRequestsPage(),
      const AdminUsersScreen(),
      const AdminProfilePage(),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: burntOrange,
        unselectedItemColor: darkBrown.withOpacity(0.5),
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
  const AdminDashboardPage({super.key});

  static const Color white = Color(0xFFFFFFFF);
  static const Color burntOrange = Color(0xFFBE5633);
  static const Color darkBrown = Color(0xFF46291D);

  @override
  Widget build(BuildContext context) {
    final rp = Provider.of<RequestProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final dashboard = rp.dashboard;

    return Scaffold(
      backgroundColor: white,
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: burntOrange,
        foregroundColor: white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await rp.fetchDashboard();
          await rp.fetchAdminRequests();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: burntOrange.withOpacity(0.1),
                        child: Text(
                          auth.user?.initials ?? 'A',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: burntOrange),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome, ${auth.user?.name ?? 'Admin'}',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkBrown),
                            ),
                            Text(
                              'Today: ${dashboard['today'] ?? 0} new requests',
                              style: TextStyle(color: darkBrown.withOpacity(0.6)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Stats Grid
              Text(
                'Overview',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkBrown),
              ),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: [
                  _AdminStatCard(title: 'Total', value: '${dashboard['total'] ?? 0}', color: burntOrange),
                  _AdminStatCard(title: 'Pending', value: '${dashboard['pending'] ?? 0}', color: Colors.orange),
                  _AdminStatCard(title: 'In Review', value: '${dashboard['in_review'] ?? 0}', color: Colors.purple),
                  _AdminStatCard(title: 'Completed', value: '${dashboard['completed'] ?? 0}', color: Colors.green),
                ],
              ),
              const SizedBox(height: 24),

              // Recent Requests
              Text(
                'Recent Requests',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkBrown),
              ),
              const SizedBox(height: 12),
              if (rp.loading)
                const Center(child: CircularProgressIndicator())
              else if (rp.requests.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(child: Text('No requests', style: TextStyle(color: darkBrown))),
                  ),
                )
              else
                ...rp.requests.take(10).map((req) => _AdminRequestCard(request: req)),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminStatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _AdminStatCard({
    required this.title,
    required this.value,
    required this.color,
  });

  static const Color darkBrown = Color(0xFF46291D);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(color: darkBrown.withOpacity(0.6))),
          ],
        ),
      ),
    );
  }
}

class _AdminRequestCard extends StatelessWidget {
  final RequestModel request;

  const _AdminRequestCard({required this.request});

  static const Color white = Color(0xFFFFFFFF);
  static const Color burntOrange = Color(0xFFBE5633);
  static const Color darkBrown = Color(0xFF46291D);

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'in_review': return Colors.purple;
      case 'approved': return Colors.green;
      case 'processing': return burntOrange;
      case 'completed': return Colors.teal;
      case 'rejected': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'in_review': return 'In Review';
      default: return status[0].toUpperCase() + status.substring(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(request.status).withOpacity(0.1),
          child: Icon(Icons.assignment, color: _getStatusColor(request.status)),
        ),
        title: Text(
          request.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: darkBrown, fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(request.trackingCode, style: TextStyle(fontSize: 11, color: darkBrown.withOpacity(0.6))),
            Text('From: ${request.user?.name ?? 'Unknown'}', style: TextStyle(fontSize: 10, color: darkBrown.withOpacity(0.5))),
            Text('Category: ${request.category?.name ?? 'Unknown'}', style: TextStyle(fontSize: 10, color: darkBrown.withOpacity(0.5))),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getStatusColor(request.status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _getStatusLabel(request.status),
            style: TextStyle(fontSize: 10, color: _getStatusColor(request.status), fontWeight: FontWeight.bold),
          ),
        ),
        onTap: () {
          _showRequestDetailsDialog(context, request);
        },
      ),
    );
  }

  void _showRequestDetailsDialog(BuildContext context, RequestModel request) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Expanded(
              child: Text(
                'Request Details',
                style: TextStyle(color: darkBrown, fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              icon: Icon(Icons.close, color: darkBrown),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tracking Code & Status
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getStatusColor(request.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.qr_code, color: _getStatusColor(request.status)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tracking Code',
                            style: TextStyle(fontSize: 11, color: darkBrown.withOpacity(0.6)),
                          ),
                          Text(
                            request.trackingCode,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: darkBrown,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(request.status).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getStatusLabel(request.status),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(request.status),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Requester Info
              _buildInfoSection(
                icon: Icons.person,
                title: 'Requested By',
                content: request.user?.name ?? 'Unknown',
                subtitle: request.user?.email ?? '',
              ),
              const SizedBox(height: 16),

              // Title
              _buildInfoSection(
                icon: Icons.title,
                title: 'Title',
                content: request.title,
              ),
              const SizedBox(height: 16),

              // Category & Priority
              Row(
                children: [
                  Expanded(
                    child: _buildInfoSection(
                      icon: Icons.category,
                      title: 'Category',
                      content: request.category?.name ?? 'Unknown',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInfoSection(
                      icon: Icons.priority_high,
                      title: 'Priority',
                      content: request.priority.toUpperCase(),
                      contentColor: _getPriorityColor(request.priority),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Description
              _buildInfoSection(
                icon: Icons.description,
                title: 'Description',
                content: request.description,
                isLongText: true,
              ),
              const SizedBox(height: 16),

              // Submitted Date
              _buildInfoSection(
                icon: Icons.calendar_today,
                title: 'Submitted',
                content: _formatDate(request.createdAt),
              ),

              if (request.remarks != null && request.remarks!.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildInfoSection(
                  icon: Icons.comment,
                  title: 'Remarks',
                  content: request.remarks!,
                  isLongText: true,
                ),
              ],

              // Status History
              if (request.logs.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildHistorySection(request.logs),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(foregroundColor: darkBrown),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _showStatusDialog(context, request);
            },
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('Update Status'),
            style: ElevatedButton.styleFrom(
              backgroundColor: burntOrange,
              foregroundColor: white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection({
    required IconData icon,
    required String title,
    required String content,
    String? subtitle,
    Color? contentColor,
    bool isLongText = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: burntOrange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: burntOrange),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 11, color: darkBrown.withOpacity(0.6)),
              ),
              const SizedBox(height: 4),
              Text(
                content,
                style: TextStyle(
                  fontSize: isLongText ? 13 : 14,
                  fontWeight: isLongText ? FontWeight.normal : FontWeight.w500,
                  color: contentColor ?? darkBrown,
                ),
                maxLines: isLongText ? 10 : 2,
                overflow: isLongText ? TextOverflow.visible : TextOverflow.ellipsis,
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: darkBrown.withOpacity(0.5)),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHistorySection(List<StatusLog> logs) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: darkBrown.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, size: 18, color: burntOrange),
              const SizedBox(width: 8),
              Text(
                'Status History',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: darkBrown,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...logs.map((log) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(log.newStatus),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        log.newStatusLabel,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(log.newStatus),
                          fontSize: 12,
                        ),
                      ),
                      if (log.note != null && log.note!.isNotEmpty)
                        Text(
                          log.note!,
                          style: TextStyle(fontSize: 11, color: darkBrown.withOpacity(0.7)),
                        ),
                      Text(
                        _formatDate(log.createdAt),
                        style: TextStyle(fontSize: 10, color: darkBrown.withOpacity(0.5)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'low': return Colors.green;
      case 'normal': return burntOrange;
      case 'high': return Colors.orange;
      case 'urgent': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }

  void _showStatusDialog(BuildContext context, RequestModel request) {
    String selectedStatus = request.status;
    final remarksCtrl = TextEditingController(text: request.remarks ?? '');

    // Store provider reference before showing dialog
    final requestProvider = Provider.of<RequestProvider>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: Text('Update Status: ${request.trackingCode}', style: TextStyle(color: darkBrown)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: InputDecoration(
                    labelText: 'Status',
                    labelStyle: TextStyle(color: darkBrown),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: darkBrown),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: darkBrown.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: burntOrange, width: 2),
                    ),
                  ),
                  items: ['pending', 'in_review', 'approved', 'processing', 'completed', 'rejected']
                      .map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(s.toUpperCase().replaceAll('_', ' '), style: TextStyle(color: darkBrown)),
                  ))
                      .toList(),
                  onChanged: (v) => setState(() => selectedStatus = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: remarksCtrl,
                  decoration: InputDecoration(
                    labelText: 'Remarks (optional)',
                    labelStyle: TextStyle(color: darkBrown),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: darkBrown),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: darkBrown.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: burntOrange, width: 2),
                    ),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  remarksCtrl.dispose();
                  Navigator.pop(ctx);
                },
                style: TextButton.styleFrom(foregroundColor: darkBrown),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  // Close dialog first
                  Navigator.pop(ctx);

                  // Show loading indicator
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            ),
                            SizedBox(width: 10),
                            Text('Updating status...'),
                          ],
                        ),
                        backgroundColor: burntOrange,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }

                  // Use the stored provider reference
                  final success = await requestProvider.updateStatus(
                      request.id,
                      selectedStatus,
                      remarks: remarksCtrl.text.trim()
                  );

                  remarksCtrl.dispose();

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success ? 'Status updated successfully' : 'Failed to update status'),
                        backgroundColor: success ? Colors.green : burntOrange,
                      ),
                    );

                    if (success) {
                      await requestProvider.fetchAdminRequests();
                      await requestProvider.fetchDashboard();
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: burntOrange,
                  foregroundColor: white,
                ),
                child: const Text('Update'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class AdminRequestsPage extends StatefulWidget {
  const AdminRequestsPage({super.key});

  @override
  State<AdminRequestsPage> createState() => _AdminRequestsPageState();
}

class _AdminRequestsPageState extends State<AdminRequestsPage> {
  String _searchQuery = '';
  String _filterStatus = 'all';
  final TextEditingController _searchController = TextEditingController();

  static const Color white = Color(0xFFFFFFFF);
  static const Color burntOrange = Color(0xFFBE5633);
  static const Color darkBrown = Color(0xFF46291D);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rp = Provider.of<RequestProvider>(context);

    // Filter requests based on search query and status
    List<RequestModel> filteredRequests = rp.requests.where((request) {
      // Filter by status
      if (_filterStatus != 'all' && request.status != _filterStatus) {
        return false;
      }

      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return request.title.toLowerCase().contains(query) ||
            request.trackingCode.toLowerCase().contains(query) ||
            request.user?.name?.toLowerCase().contains(query) == true ||
            request.category?.name?.toLowerCase().contains(query) == true;
      }

      return true;
    }).toList();

    // Sort by date (newest first)
    filteredRequests.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Scaffold(
      backgroundColor: white,
      appBar: AppBar(
        title: const Text('All Requests'),
        backgroundColor: burntOrange,
        foregroundColor: white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => rp.fetchAdminRequests(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by title, tracking code, requester, or category...',
                    hintStyle: TextStyle(color: darkBrown.withOpacity(0.5)),
                    prefixIcon: Icon(Icons.search, color: burntOrange),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                      icon: Icon(Icons.clear, color: darkBrown),
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                          _searchController.clear();
                        });
                      },
                    )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: darkBrown),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: darkBrown.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: burntOrange, width: 2),
                    ),
                    filled: true,
                    fillColor: white,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                // Status Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', 'all'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Pending', 'pending'),
                      const SizedBox(width: 8),
                      _buildFilterChip('In Review', 'in_review'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Approved', 'approved'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Processing', 'processing'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Completed', 'completed'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Rejected', 'rejected'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Results Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '${filteredRequests.length} request(s) found',
                  style: TextStyle(
                    fontSize: 12,
                    color: darkBrown.withOpacity(0.6),
                  ),
                ),
                const Spacer(),
                if (_searchQuery.isNotEmpty || _filterStatus != 'all')
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                        _searchController.clear();
                        _filterStatus = 'all';
                      });
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: burntOrange,
                    ),
                    child: const Text('Clear Filters'),
                  ),
              ],
            ),
          ),
          // Requests List
          Expanded(
            child: rp.loading
                ? const Center(child: CircularProgressIndicator())
                : filteredRequests.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox,
                    size: 64,
                    color: darkBrown.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No requests found',
                    style: TextStyle(color: darkBrown),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try adjusting your search or filter',
                    style: TextStyle(
                      fontSize: 12,
                      color: darkBrown.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            )
                : RefreshIndicator(
              onRefresh: () => rp.fetchAdminRequests(),
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: filteredRequests.length,
                itemBuilder: (ctx, index) => _AdminRequestCard(request: filteredRequests[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String statusValue) {
    final isSelected = _filterStatus == statusValue;
    Color chipColor = burntOrange;

    // Set color based on status
    switch (statusValue) {
      case 'pending': chipColor = Colors.orange; break;
      case 'in_review': chipColor = Colors.purple; break;
      case 'approved': chipColor = Colors.green; break;
      case 'processing': chipColor = burntOrange; break;
      case 'completed': chipColor = Colors.teal; break;
      case 'rejected': chipColor = Colors.red; break;
      default: chipColor = burntOrange;
    }

    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : chipColor,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterStatus = statusValue;
        });
      },
      backgroundColor: white,
      selectedColor: chipColor,
      side: BorderSide(
        color: isSelected ? chipColor : darkBrown.withOpacity(0.3),
        width: 1,
      ),
      shape: StadiumBorder(),
    );
  }
}

class AdminProfilePage extends StatelessWidget {
  const AdminProfilePage({super.key});

  static const Color white = Color(0xFFFFFFFF);
  static const Color burntOrange = Color(0xFFBE5633);
  static const Color darkBrown = Color(0xFF46291D);

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    return Scaffold(
      backgroundColor: white,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: burntOrange,
        foregroundColor: white,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: burntOrange.withOpacity(0.1),
                child: Text(
                  user?.initials ?? 'A',
                  style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: burntOrange),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                user?.name ?? 'Admin',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: darkBrown),
              ),
              const SizedBox(height: 8),
              Text(
                user?.email ?? '',
                style: TextStyle(color: darkBrown.withOpacity(0.6)),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: burntOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  user?.role.toUpperCase() ?? 'ADMIN',
                  style: TextStyle(fontWeight: FontWeight.bold, color: burntOrange),
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text('Logout', style: TextStyle(color: darkBrown)),
                        content: Text('Are you sure you want to logout?', style: TextStyle(color: darkBrown)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            style: TextButton.styleFrom(foregroundColor: darkBrown),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: TextButton.styleFrom(foregroundColor: burntOrange),
                            child: const Text('Logout'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true && context.mounted) {
                      await auth.logout();
                      if (context.mounted) {
                        Navigator.pushReplacementNamed(context, '/');
                      }
                    }
                  },
                  icon: Icon(Icons.logout, color: burntOrange),
                  label: Text('Logout', style: TextStyle(color: burntOrange)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: burntOrange),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}