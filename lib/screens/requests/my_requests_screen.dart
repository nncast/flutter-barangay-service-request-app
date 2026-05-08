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
      case 'in_review': return Colors.blue;
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
      appBar: AppBar(
        title: const Text('My Requests'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
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
      ),
      body: rp.loading
          ? const Center(child: CircularProgressIndicator())
          : filteredRequests.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('No ${_currentStatus == 'all' ? '' : _getStatusLabel(_currentStatus)} requests found'),
            const SizedBox(height: 8),
            if (_currentStatus != 'all')
              TextButton(
                onPressed: () {
                  _tabController.animateTo(0);
                },
                child: const Text('View all requests'),
              )
            else
              const Text('Tap the + button to create one', style: TextStyle(color: Colors.grey)),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: () => _loadRequests(_currentStatus == 'all' ? null : _currentStatus),
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: filteredRequests.length,
          itemBuilder: (ctx, index) {
            final req = filteredRequests[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getStatusColor(req.status).withOpacity(0.1),
                  child: Icon(Icons.assignment, color: _getStatusColor(req.status)),
                ),
                title: Text(req.title),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(req.trackingCode, style: const TextStyle(fontSize: 12)),
                    Text(
                      req.category?.name ?? '',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
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
            );
          },
        ),
      ),
    );
  }
}