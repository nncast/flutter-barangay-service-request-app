import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/request_provider.dart';
import '../../core/models.dart';

class RequestDetailScreen extends StatefulWidget {
  final int requestId;
  const RequestDetailScreen({super.key, required this.requestId});

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  RequestModel? _request;
  bool _loading = true;

  // Color constants based on your scheme
  static const Color white = Color(0xFFFFFFFF);
  static const Color creamGold = Color(0xFFFAD793);
  static const Color burntOrange = Color(0xFFBE5633);
  static const Color darkBrown = Color(0xFF46291D);

  @override
  void initState() {
    super.initState();
    _loadRequest();
  }

  Future<void> _loadRequest() async {
    final rp = context.read<RequestProvider>();
    final req = await rp.fetchRequest(widget.requestId);
    if (mounted) {
      setState(() {
        _request = req;
        _loading = false;
      });
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
      case 'cancelled': return Colors.grey;
      default: return Colors.grey;
    }
  }

  String _getStatusMessage(String status) {
    switch (status) {
      case 'pending':
        return 'Your request has been submitted and is waiting to be reviewed.';
      case 'in_review':
        return 'Your request is currently being reviewed by barangay staff.';
      case 'approved':
        return 'Your request has been approved and will be processed soon.';
      case 'processing':
        return 'Your request is now being processed.';
      case 'completed':
        return 'Your request has been completed. Thank you for using our service.';
      case 'rejected':
        return 'We regret to inform you that your request has been rejected.';
      case 'cancelled':
        return 'This request has been cancelled.';
      default:
        return '';
    }
  }

  bool _canCancel(String status) {
    return status == 'pending';
  }

  Future<void> _cancelRequest() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: white,
        title: Text('Cancel Request', style: TextStyle(color: darkBrown)),
        content: Text(
          'Are you sure you want to cancel "${_request?.title}"?',
          style: TextStyle(color: darkBrown),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(foregroundColor: darkBrown),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: burntOrange),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final rp = context.read<RequestProvider>();
      final ok = await rp.cancelRequest(_request!.id);
      if (context.mounted) {
        if (ok) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Request cancelled successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to cancel request'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_request == null) {
      return const Scaffold(body: Center(child: Text('Request not found')));
    }

    final req = _request!;
    final canCancel = _canCancel(req.status);

    return Scaffold(
      backgroundColor: white,
      appBar: AppBar(
        title: Text(req.trackingCode, style: const TextStyle(color: white)),
        backgroundColor: burntOrange,
        foregroundColor: white,
        elevation: 0,
        actions: [
          // Cancel button - only for pending requests
          if (canCancel)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ElevatedButton.icon(
                onPressed: _cancelRequest,
                icon: const Icon(Icons.cancel_outlined, size: 18),
                label: const Text('Cancel Request'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkBrown,
                  foregroundColor: creamGold,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _getStatusColor(req.status),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Current Status',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: darkBrown,
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: darkBrown),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getStatusColor(req.status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            req.status.toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(req.status),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _getStatusMessage(req.status),
                      style: TextStyle(color: darkBrown.withOpacity(0.7), fontSize: 14, height: 1.4),
                    ),
                    if (req.remarks != null && req.remarks!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: creamGold.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: creamGold),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Remarks:',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                color: darkBrown,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              req.remarks!,
                              style: TextStyle(
                                fontSize: 13,
                                color: darkBrown,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Details Card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: burntOrange,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Request Details',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: darkBrown,
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: darkBrown),
                    const SizedBox(height: 8),
                    _detailRow('Title', req.title),
                    _detailRow('Category', req.category?.name ?? '-'),
                    _detailRow('Priority', req.priority.toUpperCase()),
                    _detailRow('Submitted', _formatDate(req.createdAt)),
                    const SizedBox(height: 8),
                    Text(
                      'Description',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: darkBrown.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      req.description,
                      style: TextStyle(color: darkBrown, height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Status History Card
            if (req.logs.isNotEmpty)
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: burntOrange,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Status History',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: darkBrown,
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: darkBrown),
                      const SizedBox(height: 8),
                      ...req.logs.map((log) => Padding(
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
                                    log.newStatus.toUpperCase(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _getStatusColor(log.newStatus),
                                    ),
                                  ),
                                  if (log.note != null && log.note!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        log.note!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: darkBrown.withOpacity(0.6),
                                        ),
                                      ),
                                    ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      _formatDate(log.createdAt),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: darkBrown.withOpacity(0.5),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: darkBrown.withOpacity(0.6),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: darkBrown),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }
}