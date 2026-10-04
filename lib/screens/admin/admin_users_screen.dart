import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../core/models.dart';
import '../../core/session.dart';
import '../../core/ui_helpers.dart';

Color _roleColor(String role) {
  switch (role) {
    case 'admin':
      return kBurntOrange;
    case 'staff':
      return const Color(0xFF2563EB);
    case 'resident':
      return const Color(0xFF059669);
    default:
      return Colors.grey;
  }
}

const _roleOrder = {'admin': 0, 'staff': 1, 'resident': 2};

InputDecoration _fieldDecoration(String label) => InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: kDarkBrown),
      border: const OutlineInputBorder(),
      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: kDarkBrown.withOpacity(0.3))),
      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: kBurntOrange, width: 2)),
    );

const _roleItems = [
  DropdownMenuItem(value: 'resident', child: Text('Resident')),
  DropdownMenuItem(value: 'staff', child: Text('Staff')),
  DropdownMenuItem(value: 'admin', child: Text('Admin')),
];

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  String _searchQuery = '';
  String _filterRole = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().fetchUsers();
    });
  }

  Future<void> _run(Future<bool> Function(UserProvider) action, String successMessage) async {
    final provider = context.read<UserProvider>();
    final ok = await action(provider);
    if (!mounted) return;
    showMessage(context, ok ? successMessage : (provider.error ?? 'Something went wrong'), success: ok);
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final currentUser = context.watch<AuthProvider>().user;
    final isAdmin = currentUser?.isAdmin ?? false;
    final users = userProvider.users;
    final query = _searchQuery.trim().toLowerCase();

    final filteredUsers = users.where((user) {
      if (_filterRole == 'inactive') {
        if (user.isActive) return false;
      } else if (_filterRole != 'all' && user.role != _filterRole) {
        return false;
      }
      if (query.isEmpty) return true;
      return user.name.toLowerCase().contains(query) || user.email.toLowerCase().contains(query);
    }).toList()
      // Admins first, then staff, then residents; alphabetical within a role.
      ..sort((a, b) {
        final byRole = (_roleOrder[a.role] ?? 9).compareTo(_roleOrder[b.role] ?? 9);
        return byRole != 0 ? byRole : a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

    final inactiveCount = users.where((u) => !u.isActive).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(isAdmin ? 'Manage Users' : 'Users'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: userProvider.fetchUsers,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search name or email',
                      hintStyle: TextStyle(color: kDarkBrown.withOpacity(0.5)),
                      prefixIcon: const Icon(Icons.search, color: kBurntOrange),
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: kDarkBrown.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: kBurntOrange, width: 2),
                      ),
                    ),
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: kDarkBrown.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _filterRole,
                      dropdownColor: kWhite,
                      items: [
                        const DropdownMenuItem(value: 'all', child: Text('All roles')),
                        const DropdownMenuItem(value: 'admin', child: Text('Admin')),
                        const DropdownMenuItem(value: 'staff', child: Text('Staff')),
                        const DropdownMenuItem(value: 'resident', child: Text('Resident')),
                        if (isAdmin) const DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                      ],
                      onChanged: (value) => setState(() => _filterRole = value ?? 'all'),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _statChip('Total', users.length, kDarkBrown),
                _statChip('Admins', users.where((u) => u.role == 'admin').length, _roleColor('admin')),
                _statChip('Staff', users.where((u) => u.role == 'staff').length, _roleColor('staff')),
                _statChip('Residents', users.where((u) => u.role == 'resident').length, _roleColor('resident')),
                if (inactiveCount > 0) _statChip('Inactive', inactiveCount, Colors.grey),
              ],
            ),
          ),
          if (!isAdmin)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: kCreamGold.withOpacity(0.35),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'View only — only admins can add, edit or delete users.',
                style: TextStyle(fontSize: 12, color: kDarkBrown),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              color: kBurntOrange,
              onRefresh: userProvider.fetchUsers,
              child: userProvider.loading && users.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : filteredUsers.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            const SizedBox(height: 80),
                            Icon(Icons.people_outline, size: 64, color: kDarkBrown.withOpacity(0.3)),
                            const SizedBox(height: 16),
                            Text(
                              userProvider.error ?? 'No users found',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: kDarkBrown.withOpacity(0.6)),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                          itemCount: filteredUsers.length,
                          itemBuilder: (ctx, index) {
                            final user = filteredUsers[index];
                            final isCurrentUser = currentUser?.id == user.id;
                            return _UserCard(
                              user: user,
                              isCurrentUser: isCurrentUser,
                              onEdit: isAdmin ? () => _showEditUserDialog(user, isCurrentUser) : null,
                              onDelete: isAdmin && !isCurrentUser ? () => _confirmDeleteUser(user) : null,
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: _showAddUserDialog,
              icon: const Icon(Icons.person_add),
              label: const Text('Add User'),
              backgroundColor: kBurntOrange,
              foregroundColor: kWhite,
            )
          : null,
    );
  }

  Widget _statChip(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Chip(
        visualDensity: VisualDensity.compact,
        backgroundColor: color.withOpacity(0.08),
        side: BorderSide(color: color.withOpacity(0.3)),
        shape: const StadiumBorder(),
        label: Text(
          '$label  $count',
          style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Future<void> _showAddUserDialog() async {
    final data = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const _UserFormDialog(),
    );
    if (data == null) return;
    await _run((p) => p.createUser(data), 'User created');
  }

  Future<void> _showEditUserDialog(UserModel user, bool isCurrentUser) async {
    final data = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _UserFormDialog(user: user, isCurrentUser: isCurrentUser),
    );
    if (data == null) return;
    await _run((p) => p.updateUser(user.id, data), 'User updated');
  }

  Future<void> _confirmDeleteUser(UserModel user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete User', style: TextStyle(color: kDarkBrown)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Permanently delete ${user.name}?', style: const TextStyle(color: kDarkBrown)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: const Text(
                'Their own requests and notifications are deleted too. This cannot be undone. '
                'To keep their records, deactivate the account instead (Edit → Active).',
                style: TextStyle(fontSize: 12, color: kDarkBrown),
              ),
            ),
            if (user.isAdmin) ...[
              const SizedBox(height: 8),
              const Text(
                'This user is an admin.',
                style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(foregroundColor: kDarkBrown),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: kWhite),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await _run((p) => p.deleteUser(user.id), '${user.name} was deleted');
  }
}

/// Add/edit form. Returns the data to send, or null if cancelled.
class _UserFormDialog extends StatefulWidget {
  final UserModel? user;
  final bool isCurrentUser;

  const _UserFormDialog({this.user, this.isCurrentUser = false});

  @override
  State<_UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<_UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.user?.name ?? '');
  late final _email = TextEditingController(text: widget.user?.email ?? '');
  late final _phone = TextEditingController(text: widget.user?.phone ?? '');
  late final _address = TextEditingController(text: widget.user?.address ?? '');
  final _password = TextEditingController();
  late String _role = widget.user?.role ?? 'resident';
  late bool _active = widget.user?.isActive ?? true;

  bool get _isEdit => widget.user != null;

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _address, _password]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final phone = _phone.text.trim();
    final address = _address.text.trim();
    Navigator.pop(context, <String, dynamic>{
      'name': _name.text.trim(),
      'phone': phone.isEmpty ? null : phone,
      'address': address.isEmpty ? null : address,
      if (!widget.isCurrentUser) 'role': _role,
      if (_isEdit && !widget.isCurrentUser) 'is_active': _active,
      if (!_isEdit) ...{
        'email': _email.text.trim(),
        'password': _password.text,
        'password_confirmation': _password.text,
      },
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'Edit User' : 'Add New User', style: const TextStyle(color: kDarkBrown)),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  decoration: _fieldDecoration('Full Name'),
                  validator: (v) => (v ?? '').trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _email,
                  enabled: !_isEdit,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _fieldDecoration(_isEdit ? 'Email (can\'t be changed)' : 'Email'),
                  validator: (v) {
                    if (_isEdit) return null;
                    final email = (v ?? '').trim();
                    if (email.isEmpty) return 'Required';
                    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: _fieldDecoration('Phone (optional)'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _address,
                  decoration: _fieldDecoration('Address (optional)'),
                  maxLines: 2,
                ),
                if (!_isEdit) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _password,
                    decoration: _fieldDecoration('Password'),
                    obscureText: true,
                    validator: (v) => (v ?? '').length < 8 ? 'At least 8 characters' : null,
                  ),
                ],
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _role,
                  decoration: _fieldDecoration(widget.isCurrentUser ? 'Role (your own — can\'t change)' : 'Role'),
                  items: _roleItems,
                  onChanged: widget.isCurrentUser ? null : (value) => setState(() => _role = value ?? _role),
                ),
                if (_isEdit && !widget.isCurrentUser)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Active', style: TextStyle(color: kDarkBrown)),
                    subtitle: Text(
                      _active ? 'Can sign in' : 'Signed out and blocked from signing in',
                      style: TextStyle(fontSize: 12, color: kDarkBrown.withOpacity(0.6)),
                    ),
                    value: _active,
                    onChanged: (v) => setState(() => _active = v),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(foregroundColor: kDarkBrown),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _save, child: Text(_isEdit ? 'Save' : 'Create')),
      ],
    );
  }
}

class _UserCard extends StatelessWidget {
  final UserModel user;
  final bool isCurrentUser;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _UserCard({
    required this.user,
    required this.isCurrentUser,
    this.onEdit,
    this.onDelete,
  });

  Widget _badge(String text, Color color) => Container(
        margin: const EdgeInsets.only(right: 6, top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(text, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
      );

  @override
  Widget build(BuildContext context) {
    final color = user.isActive ? _roleColor(user.role) : Colors.grey;

    return Opacity(
      opacity: user.isActive ? 1 : 0.65,
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        elevation: 1.5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          contentPadding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
          leading: CircleAvatar(
            backgroundColor: color.withOpacity(0.12),
            child: Text(user.initials, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ),
          title: Text(
            user.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600, color: kDarkBrown),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: kDarkBrown.withOpacity(0.7)),
              ),
              Wrap(
                children: [
                  _badge(user.roleLabel, color),
                  if (isCurrentUser) _badge('You', kBurntOrange),
                  if (!user.isActive) _badge('Inactive', Colors.grey),
                ],
              ),
            ],
          ),
          trailing: (onEdit == null && onDelete == null)
              ? null
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onEdit != null)
                      IconButton(
                        tooltip: 'Edit',
                        icon: const Icon(Icons.edit_outlined, color: kBurntOrange),
                        onPressed: onEdit,
                      ),
                    if (onDelete != null)
                      IconButton(
                        tooltip: 'Delete',
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: onDelete,
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}
