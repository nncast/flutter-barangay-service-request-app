import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/request_provider.dart';
import '../../core/models.dart';

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

  CategoryModel? _selectedCategory;
  String _priority = 'normal';
  bool _submitting = false;

  // Color constants
  static const Color white = Color(0xFFFFFFFF);
  static const Color burntOrange = Color(0xFFBE5633);
  static const Color darkBrown = Color(0xFF46291D);

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.preSelectedCategory;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final rp = context.read<RequestProvider>();
      rp.fetchCategories();

      if (widget.preSelectedCategory != null && rp.categories.isNotEmpty) {
        final fullCategory = rp.categories.firstWhere(
              (cat) => cat.id == widget.preSelectedCategory!.id,
          orElse: () => widget.preSelectedCategory!,
        );
        if (mounted && fullCategory.id == widget.preSelectedCategory!.id) {
          setState(() {
            _selectedCategory = fullCategory;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Please select a category'), backgroundColor: burntOrange),
      );
      return;
    }

    setState(() => _submitting = true);

    final rp = context.read<RequestProvider>();
    final ok = await rp.submitRequest({
      'category_id': _selectedCategory!.id,
      'title': _titleCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'priority': _priority,
    });

    setState(() => _submitting = false);

    if (!mounted) return;

    if (ok) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✓ Request submitted successfully!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit request. Please try again.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Color _getColorForCategory(String colorHex) {
    try {
      final hex = colorHex.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return burntOrange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final rp = context.watch<RequestProvider>();

    return Scaffold(
      backgroundColor: white,
      appBar: AppBar(
        title: const Text('Submit Request'),
        backgroundColor: burntOrange,
        foregroundColor: white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Selection Header
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: burntOrange.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.category, color: burntOrange),
                    const SizedBox(width: 12),
                    Text(
                      'Select Service Type',
                      style: TextStyle(fontWeight: FontWeight.bold, color: darkBrown),
                    ),
                    const Text(' *', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              if (rp.categories.isEmpty)
                const Center(child: CircularProgressIndicator())
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: rp.categories.map((cat) {
                    final isSelected = _selectedCategory?.id == cat.id;
                    final categoryColor = _getColorForCategory(cat.colorHex);
                    return FilterChip(
                      label: Text(
                        cat.name,
                        style: TextStyle(
                          color: isSelected ? white : categoryColor,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _selectedCategory = cat),
                      backgroundColor: white,
                      selectedColor: categoryColor,
                      avatar: Icon(
                        Icons.category,
                        size: 16,
                        color: isSelected ? white : categoryColor,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? categoryColor : darkBrown.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                    );
                  }).toList(),
                ),

              const SizedBox(height: 24),

              // Title Field Header
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: burntOrange.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.title, color: burntOrange),
                    const SizedBox(width: 12),
                    Text(
                      'Request Title',
                      style: TextStyle(fontWeight: FontWeight.bold, color: darkBrown),
                    ),
                    const Text(' *', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleCtrl,
                decoration: InputDecoration(
                  hintText: 'e.g., Request for Barangay Clearance',
                  hintStyle: TextStyle(color: darkBrown.withOpacity(0.5)),
                  prefixIcon: Icon(Icons.edit_note, color: burntOrange),
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
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Title is required';
                  if (v.length < 5) return 'Title must be at least 5 characters';
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Description Field Header
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: burntOrange.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.description, color: burntOrange),
                    const SizedBox(width: 12),
                    Text(
                      'Description',
                      style: TextStyle(fontWeight: FontWeight.bold, color: darkBrown),
                    ),
                    const Text(' *', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: 'Provide detailed information about your request...\n\nInclude any relevant details that will help us process your request faster.',
                  hintStyle: TextStyle(color: darkBrown.withOpacity(0.5)),
                  alignLabelWithHint: true,
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
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Description is required';
                  if (v.length < 10) return 'Please provide more details (at least 10 characters)';
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Priority Selection Header
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: burntOrange.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.priority_high, color: burntOrange),
                    const SizedBox(width: 12),
                    Text(
                      'Priority Level',
                      style: TextStyle(fontWeight: FontWeight.bold, color: darkBrown),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildPriorityOption('low', Icons.arrow_downward, Colors.green),
                      _buildPriorityOption('normal', Icons.remove, burntOrange),
                      _buildPriorityOption('high', Icons.arrow_upward, Colors.orange),
                      _buildPriorityOption('urgent', Icons.priority_high, Colors.red),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Info note
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: burntOrange.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: burntOrange.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: burntOrange, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your request will be reviewed by barangay staff. You will receive notifications when your request status changes.',
                        style: TextStyle(fontSize: 12, color: darkBrown.withOpacity(0.8)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: burntOrange,
                    foregroundColor: white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _submitting
                      ? SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(white),
                    ),
                  )
                      : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.send, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Submit Request',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityOption(String value, IconData icon, Color color) {
    final isSelected = _priority == value;
    return GestureDetector(
      onTap: () => setState(() => _priority = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : darkBrown.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : darkBrown.withOpacity(0.5), size: 20),
            const SizedBox(height: 4),
            Text(
              value[0].toUpperCase() + value.substring(1),
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : darkBrown.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}