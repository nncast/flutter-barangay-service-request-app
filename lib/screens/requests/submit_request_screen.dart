import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/request_provider.dart';
import '../../core/models.dart';
import '../../core/session.dart';
import '../../core/ui_helpers.dart';

class SubmitRequestScreen extends StatefulWidget {
  final CategoryModel? preSelectedCategory;

  const SubmitRequestScreen({super.key, this.preSelectedCategory});

  @override
  State<SubmitRequestScreen> createState() => _SubmitRequestScreenState();
}

class _SubmitRequestScreenState extends State<SubmitRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  int? _selectedCategoryId;
  String _priority = 'normal';

  static const _priorities = ['low', 'normal', 'high', 'urgent'];

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.preSelectedCategory?.id;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final rp = context.read<RequestProvider>();
      if (rp.categories.isEmpty && !rp.categoriesLoading) rp.fetchCategories();
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final rp = context.read<RequestProvider>();
    if (rp.submitting || !_formKey.currentState!.validate()) return;

    if (_selectedCategoryId == null) {
      showMessage(context, 'Please select a service type');
      return;
    }

    // The title is optional: most requests are just "Barangay Clearance" and so on
    final title = _titleCtrl.text.trim();
    final ok = await rp.submitRequest({
      'category_id': _selectedCategoryId,
      'title': title.isNotEmpty ? title : rp.categories.firstWhere((c) => c.id == _selectedCategoryId).name,
      'description': _descCtrl.text.trim(),
      'priority': _priority,
    });

    if (!mounted) return;

    if (ok) {
      showMessage(context, 'Request submitted. You\'ll be notified when it\'s updated.', success: true);
      Navigator.pop(context, true);
    } else {
      showMessage(context, rp.error ?? 'Failed to submit request. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final rp = context.watch<RequestProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Submit Request')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _SectionHeader('Select Service Type', required: true),
                const SizedBox(height: 12),
                if (rp.categories.isEmpty && rp.categoriesFailed)
                  Row(
                    children: [
                      const Expanded(
                        child: Text('Couldn\'t load services.', style: TextStyle(color: kCharcoal)),
                      ),
                      TextButton(
                        onPressed: rp.fetchCategories,
                        child: const Text('Retry'),
                      ),
                    ],
                  )
                else if (rp.categories.isEmpty)
                  const Center(child: CircularProgressIndicator())
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: rp.categories.map((cat) {
                      final isSelected = _selectedCategoryId == cat.id;
                      final fg = isSelected ? kWhite : kCharcoal;
                      return FilterChip(
                        label: Text(cat.name),
                        labelStyle: TextStyle(color: fg, fontWeight: FontWeight.w600),
                        selected: isSelected,
                        showCheckmark: false,
                        onSelected: (_) => setState(() => _selectedCategoryId = cat.id),
                        backgroundColor: kSurface,
                        selectedColor: kCharcoal,
                        avatar: Icon(categoryIcon(cat.icon), size: 16, color: fg),
                        side: BorderSide.none,
                        shape: const StadiumBorder(),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 24),

                const _SectionHeader('Request Title (optional)'),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _titleCtrl,
                  maxLength: 255,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Leave blank to use the service name',
                    prefixIcon: Icon(Icons.edit_note),
                  ),
                  validator: (v) {
                    final value = (v ?? '').trim();
                    if (value.isNotEmpty && value.length < 5) return 'Title must be at least 5 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                const _SectionHeader('Description', required: true),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descCtrl,
                  minLines: 4,
                  maxLines: 8,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText:
                        'Provide details about your request — purpose, dates, anything that helps staff process it faster.',
                    hintMaxLines: 3,
                  ),
                  validator: (v) {
                    final value = (v ?? '').trim();
                    if (value.isEmpty) return 'Description is required';
                    if (value.length < 10) return 'Please provide more details (at least 10 characters)';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                const _SectionHeader('Priority Level'),
                const SizedBox(height: 12),
                SegmentedButton<String>(
                  segments: [
                    for (final p in _priorities) ButtonSegment(value: p, label: Text(priorityLabel(p))),
                  ],
                  selected: {_priority},
                  showSelectedIcon: false,
                  onSelectionChanged: (selected) => setState(() => _priority = selected.first),
                ),
                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(12)),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: kCharcoal, size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your request will be reviewed by barangay staff. You will receive notifications when its status changes.',
                          style: TextStyle(fontSize: 12, color: kGray),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: rp.submitting ? null : _submit,
                    icon: rp.submitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: kCharcoal),
                          )
                        : const Icon(Icons.send, size: 18),
                    label: Text(
                      rp.submitting ? 'Submitting...' : 'Submit Request',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final bool required;

  const _SectionHeader(this.label, {this.required = false});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: label,
        children: [if (required) const TextSpan(text: ' *', style: TextStyle(color: kRed))],
      ),
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: kCharcoal),
    );
  }
}
