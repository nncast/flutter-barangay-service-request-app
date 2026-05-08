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

  @override
  void initState() {
    super.initState();
    // Set pre-selected category if provided
    _selectedCategory = widget.preSelectedCategory;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final rp = context.read<RequestProvider>();
      rp.fetchCategories();

      // If categories are loaded and we have a pre-selected category,
      // find the full category object with all data
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
        const SnackBar(content: Text('Please select a category'), backgroundColor: Colors.orange),
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
        Navigator.pop(context, true); // Return true to indicate success
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
      return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final rp = context.watch<RequestProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Request'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Selection
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.category, color: Colors.blue[700]),
                    const SizedBox(width: 12),
                    const Text(
                      'Select Service Type',
                      style: TextStyle(fontWeight: FontWeight.bold),
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
                          color: isSelected ? Colors.white : categoryColor,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _selectedCategory = cat),
                      backgroundColor: Colors.grey[100],
                      selectedColor: categoryColor,
                      avatar: Icon(
                        Icons.category,
                        size: 16,
                        color: isSelected ? Colors.white : categoryColor,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? categoryColor : Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                    );
                  }).toList(),
                ),

              const SizedBox(height: 24),

              // Title Field
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.title, color: Colors.blue[700]),
                    const SizedBox(width: 12),
                    const Text(
                      'Request Title',
                      style: TextStyle(fontWeight: FontWeight.bold),
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
                  prefixIcon: const Icon(Icons.edit_note),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Title is required';
                  if (v.length < 5) return 'Title must be at least 5 characters';
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Description Field
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.description, color: Colors.blue[700]),
                    const SizedBox(width: 12),
                    const Text(
                      'Description',
                      style: TextStyle(fontWeight: FontWeight.bold),
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
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Description is required';
                  if (v.length < 10) return 'Please provide more details (at least 10 characters)';
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Priority Selection
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.priority_high, color: Colors.blue[700]),
                    const SizedBox(width: 12),
                    const Text(
                      'Priority Level',
                      style: TextStyle(fontWeight: FontWeight.bold),
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
                      _buildPriorityOption('normal', Icons.remove, Colors.blue),
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
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber[700], size: 20),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Your request will be reviewed by barangay staff. You will receive notifications when your request status changes.',
                        style: TextStyle(fontSize: 12),
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
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _submitting
                      ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
            color: isSelected ? color : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : Colors.grey, size: 20),
            const SizedBox(height: 4),
            Text(
              value[0].toUpperCase() + value.substring(1),
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}