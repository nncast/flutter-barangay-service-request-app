import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/request_provider.dart';
import '../../core/models.dart';
import 'request_detail_screen.dart';
import 'submit_request_screen.dart';

class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _currentStatus = 'all';
  final List<String> _statusTabs = ['all', 'pending', 'in_review', 'approved', 'processing', 'completed', 'rejected'];

  // Color constants
  static const Color white = Color(0xFFFFFFFF);
  static const Color burntOrange = Color(0xFFBE5633);
  static const Color darkBrown = Color(0xFF46291D);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statusTabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final newStatus = _statusTabs[_tabController.index];
        if (_currentStatus != newStatus) {
          _currentStatus = newStatus;
          _loadRequests(_currentStatus == 'all' ? null : _currentStatus);
        }
      }
    });
    _loadRequests(null);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRequests(String? status) async {
    final rp = context.read<RequestProvider>();
    await rp.fetchRequests(status: status);
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'all': return 'All';
      case 'in_review': return 'In Review';
      case 'pending': return 'Pending';
      case 'approved': return 'Approved';
      case 'processing': return 'Processing';
      case 'completed': return 'Completed';
      case 'rejected': return 'Rejected';
      default: return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'in_review': return burntOrange;
      case 'approved': return Colors.green;
      case 'processing': return Colors.purple;
      case 'completed': return Colors.teal;
      case 'rejected': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final rp = context.watch<RequestProvider>();

    // Filter requests locally by status for display
    List<RequestModel> filteredRequests = rp.requests;
    if (_currentStatus != 'all') {
      filteredRequests = rp.requests.where((req) => req.status == _currentStatus).toList();
    }

    return Scaffold(
      backgroundColor: white,
      appBar: AppBar(
        title: const Text('My Requests'),
        backgroundColor: burntOrange,
        foregroundColor: white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: white,
          labelColor: white,
          unselectedLabelColor: white.withOpacity(0.7),
          tabs: _statusTabs.map((status) => Tab(text: _getStatusLabel(status))).toList(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SubmitRequestScreen()),
          ).then((_) => _loadRequests(_currentStatus == 'all' ? null : _currentStatus));
        },
        icon: const Icon(Icons.add),
        label: const Text('New Request'),
        backgroundColor: burntOrange,
        foregroundColor: white,
      ),
      body: rp.loading
          ? const Center(child: CircularProgressIndicator())
          : filteredRequests.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: darkBrown.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              'No ${_currentStatus == 'all' ? '' : _getStatusLabel(_currentStatus)} requests found',
              style: TextStyle(color: darkBrown),
            ),
            const SizedBox(height: 8),
            if (_currentStatus != 'all')
              TextButton(
                onPressed: () {
                  _tabController.animateTo(0);
                },
                style: TextButton.styleFrom(foregroundColor: burntOrange),
                child: const Text('View all requests'),
              )
            else
              Text(
                'Tap the + button to create one',
                style: TextStyle(color: darkBrown.withOpacity(0.6)),
              ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: () => _loadRequests(_currentStatus == 'all' ? null : _currentStatus),
        color: burntOrange,
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: filteredRequests.length,
          itemBuilder: (ctx, index) {
            final req = filteredRequests[index];
            final hasRemarks = req.remarks != null && req.remarks!.isNotEmpty;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getStatusColor(req.status).withOpacity(0.1),
                      child: Icon(Icons.assignment, color: _getStatusColor(req.status)),
                    ),
                    title: Text(
                      req.title,
                      style: TextStyle(color: darkBrown, fontWeight: FontWeight.w500),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          req.trackingCode,
                          style: TextStyle(fontSize: 12, color: darkBrown.withOpacity(0.6)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          req.category?.name ?? '',
                          style: TextStyle(fontSize: 11, color: darkBrown.withOpacity(0.5)),
                        ),
                      ],
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(req.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getStatusLabel(req.status),
                        style: TextStyle(
                          fontSize: 11,
                          color: _getStatusColor(req.status),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RequestDetailScreen(requestId: req.id),
                        ),
                      ).then((_) => _loadRequests(_currentStatus == 'all' ? null : _currentStatus));
                    },
                  ),
                  // Remarks Section (if exists)
                  if (hasRemarks)
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.comment,
                            size: 14,
                            color: burntOrange.withOpacity(0.7),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Remarks:',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: darkBrown.withOpacity(0.7),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  req.remarks!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: darkBrown,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
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
          },
        ),
      ),
    );
  }
}