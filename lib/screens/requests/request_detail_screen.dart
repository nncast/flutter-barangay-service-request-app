import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/request_provider.dart';
import '../../core/models.dart';
import '../../core/session.dart';
import '../../core/ui_helpers.dart';

class RequestDetailScreen extends StatefulWidget {
  final int requestId;
  const RequestDetailScreen({super.key, required this.requestId});

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  RequestModel? _request;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRequest();
  }

  Future<void> _loadRequest() async {
    final rp = context.read<RequestProvider>();
    final req = await rp.fetchRequest(widget.requestId);
    if (!mounted) return;
    setState(() {
      _request = req;
      _error = req == null ? (rp.error ?? 'Request not found') : null;
      _loading = false;
    });
  }

  String _statusMessage(String status) {
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
        return 'You cancelled this request.';
      default:
        return '';
    }
  }

  Future<void> _cancelRequest() async {
    final request = _request!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Request', style: TextStyle(color: kDarkBrown)),
        content: Text(
          'Are you sure you want to cancel "${request.title}"? This can\'t be undone.',
          style: const TextStyle(color: kDarkBrown),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(foregroundColor: kDarkBrown),
            child: const Text('Keep Request'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    final rp = context.read<RequestProvider>();
    final ok = await rp.cancelRequest(request.id);
    if (!mounted) return;

    if (ok) {
      showMessage(context, 'Request cancelled', success: true);
      Navigator.pop(context, true);
    } else {
      showMessage(context, rp.error ?? 'Failed to cancel request');
    }
  }

  @override
  Widget build(BuildContext context) {
    final req = _request;

    if (_loading || req == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Request')),
        body: Center(
          child: _loading
              ? const CircularProgressIndicator()
              : Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search_off, size: 56, color: kDarkBrown.withValues(alpha: 0.3)),
                      const SizedBox(height: 12),
                      Text(_error ?? 'Request not found', style: const TextStyle(color: kDarkBrown)),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          setState(() => _loading = true);
                          _loadRequest();
                        },
                        style: TextButton.styleFrom(foregroundColor: kBurntOrange),
                        child: const Text('Try again'),
                      ),
                    ],
                  ),
                ),
        ),
      );
    }

    final color = statusColor(req.status);
    final cancelling = context.select<RequestProvider, bool>((rp) => rp.submitting);

    return Scaffold(
      appBar: AppBar(title: Text(req.trackingCode)),
      bottomNavigationBar: req.canCancel
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: OutlinedButton.icon(
                  onPressed: cancelling ? null : _cancelRequest,
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancel Request'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    side: BorderSide(color: Colors.red.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            )
          : null,
      body: RefreshIndicator(
        color: kBurntOrange,
        onRefresh: _loadRequest,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Status Card
            _SectionCard(
              title: 'Current Status',
              dotColor: color,
              children: [
                Row(
                  children: [
                    Icon(statusIcon(req.status), color: color),
                    const SizedBox(width: 8),
                    StatusChip(status: req.status, fontSize: 13),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _statusMessage(req.status),
                  style: TextStyle(color: kDarkBrown.withValues(alpha: 0.75), fontSize: 14, height: 1.4),
                ),
                if (req.remarks?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kCreamGold.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: kCreamGold),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Remarks from the barangay',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: kDarkBrown),
                        ),
                        const SizedBox(height: 4),
                        Text(req.remarks!, style: const TextStyle(fontSize: 13, color: kDarkBrown)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // Details Card
            _SectionCard(
              title: 'Request Details',
              children: [
                _detailRow('Title', req.title),
                _detailRow('Category', req.category?.name ?? '-'),
                _detailRow('Priority', priorityLabel(req.priority), valueColor: priorityColor(req.priority)),
                _detailRow('Submitted', formatDateTime(req.createdAt)),
                if (req.completedAt != null) _detailRow('Completed', formatDateTime(req.completedAt!)),
                const SizedBox(height: 4),
                Text(
                  'Description',
                  style: TextStyle(fontWeight: FontWeight.w500, color: kDarkBrown.withValues(alpha: 0.6)),
                ),
                const SizedBox(height: 4),
                Text(req.description, style: const TextStyle(color: kDarkBrown, height: 1.4)),
              ],
            ),
            const SizedBox(height: 16),

            // Status History Card
            if (req.logs.isNotEmpty)
              _SectionCard(
                title: 'Status History',
                children: [
                  for (final log in req.logs) _HistoryEntry(log: log),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w500, color: kDarkBrown.withValues(alpha: 0.6)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? kDarkBrown,
                fontWeight: valueColor != null ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Color dotColor;
  final List<Widget> children;

  const _SectionCard({required this.title, this.dotColor = kBurntOrange, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kDarkBrown),
                ),
              ],
            ),
            Divider(height: 24, color: kDarkBrown.withValues(alpha: 0.15)),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _HistoryEntry extends StatelessWidget {
  final StatusLog log;

  const _HistoryEntry({required this.log});

  @override
  Widget build(BuildContext context) {
    final color = statusColor(log.newStatus);
    final by = log.changer?.name;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(log.newStatusLabel, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                if (log.note?.isNotEmpty ?? false)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(log.note!, style: TextStyle(fontSize: 13, color: kDarkBrown.withValues(alpha: 0.75))),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    by != null ? '${formatDateTime(log.createdAt)} · $by' : formatDateTime(log.createdAt),
                    style: TextStyle(fontSize: 11, color: kDarkBrown.withValues(alpha: 0.5)),
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
