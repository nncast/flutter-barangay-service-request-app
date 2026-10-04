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

  static const _priorities = [
    ('low', Icons.arrow_downward),
    ('normal', Icons.remove),
    ('high', Icons.arrow_upward),
    ('urgent', Icons.priority_high),
  ];

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

    final ok = await rp.submitRequest({
      'category_id': _selectedCategoryId,
      'title': _titleCtrl.text.trim(),
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

  InputDecoration _inputDecoration(String hint, {IconData? icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: kDarkBrown.withOpacity(0.5)),
      prefixIcon: icon != null ? Icon(icon, color: kBurntOrange) : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: kDarkBrown.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kBurntOrange, width: 2),
      ),
      filled: true,
      fillColor: kWhite,
    );
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
                const _SectionHeader(icon: Icons.category, label: 'Select Service Type', required: true),
                const SizedBox(height: 12),
                if (rp.categories.isEmpty && rp.categoriesFailed)
                  Row(
                    children: [
                      const Expanded(
                        child: Text('Couldn\'t load services.', style: TextStyle(color: kDarkBrown)),
                      ),
                      TextButton(
                        onPressed: rp.fetchCategories,
                        style: TextButton.styleFrom(foregroundColor: kBurntOrange),
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
                      final color = colorFromHex(cat.colorHex);
                      return FilterChip(
                        label: Text(
                          cat.name,
                          style: TextStyle(
                            color: isSelected ? kWhite : color,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                        selected: isSelected,
                        showCheckmark: false,
                        onSelected: (_) => setState(() => _selectedCategoryId = cat.id),
                        backgroundColor: kWhite,
                        selectedColor: color,
                        avatar: Icon(categoryIcon(cat.icon), size: 16, color: isSelected ? kWhite : color),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(color: isSelected ? color : kDarkBrown.withOpacity(0.2)),
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 24),

                const _SectionHeader(icon: Icons.title, label: 'Request Title', required: true),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _titleCtrl,
                  maxLength: 255,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: _inputDecoration('e.g., Request for Barangay Clearance', icon: Icons.edit_note),
                  validator: (v) {
                    final value = (v ?? '').trim();
                    if (value.isEmpty) return 'Title is required';
                    if (value.length < 5) return 'Title must be at least 5 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                const _SectionHeader(icon: Icons.description, label: 'Description', required: true),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descCtrl,
                  minLines: 4,
                  maxLines: 8,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: _inputDecoration(
                    'Provide details about your request — purpose, dates, anything that helps staff process it faster.',
                  ),
                  validator: (v) {
                    final value = (v ?? '').trim();
                    if (value.isEmpty) return 'Description is required';
                    if (value.length < 10) return 'Please provide more details (at least 10 characters)';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                const _SectionHeader(icon: Icons.flag_outlined, label: 'Priority Level'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    for (final (value, icon) in _priorities) ...[
                      Expanded(child: _priorityOption(value, icon)),
                      if (value != _priorities.last.$1) const SizedBox(width: 8),
                    ],
                  ],
                ),
                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kBurntOrange.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kBurntOrange.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: kBurntOrange, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your request will be reviewed by barangay staff. You will receive notifications when its status changes.',
                          style: TextStyle(fontSize: 12, color: kDarkBrown.withOpacity(0.8)),
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
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: rp.submitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: kWhite),
                          )
                        : const Icon(Icons.send, size: 18),
                    label: Text(
                      rp.submitting ? 'Submitting...' : 'Submit Request',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

  Widget _priorityOption(String value, IconData icon) {
    final isSelected = _priority == value;
    final color = priorityColor(value);
    return InkWell(
      onTap: () => setState(() => _priority = value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? color : kDarkBrown.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : kDarkBrown.withOpacity(0.5), size: 20),
            const SizedBox(height: 4),
            Text(
              priorityLabel(value),
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : kDarkBrown.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool required;

  const _SectionHeader({required this.icon, required this.label, this.required = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kBurntOrange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: kBurntOrange),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: kDarkBrown)),
          if (required) const Text(' *', style: TextStyle(color: Colors.red)),
        ],
      ),
    );
  }
}
