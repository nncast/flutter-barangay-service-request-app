import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../core/models.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  String _searchQuery = '';
  String _filterRole = 'all';

  // Color constants
  static const Color white = Color(0xFFFFFFFF);
  static const Color burntOrange = Color(0xFFBE5633);
  static const Color darkBrown = Color(0xFF46291D);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().fetchUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final authProvider = context.watch<AuthProvider>();
    final currentUser = authProvider.user;
    final isAdmin = currentUser?.isAdmin ?? false;

    // Filter users based on search and role
    List<UserModel> filteredUsers = userProvider.users.where((user) {
      if (_filterRole != 'all' && user.role != _filterRole) return false;
      if (_searchQuery.isNotEmpty) {
        return user.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            user.email.toLowerCase().contains(_searchQuery.toLowerCase());
      }
      return true;
    }).toList();

    // Sort by role (admin first, then staff, then resident)
    filteredUsers.sort((a, b) {
      final roleOrder = {'admin': 0, 'staff': 1, 'resident': 2};
      return roleOrder[a.role]!.compareTo(roleOrder[b.role]!);
    });

    return Scaffold(
      backgroundColor: white,
      appBar: AppBar(
        title: const Text('Manage Users'),
        backgroundColor: burntOrange,
        foregroundColor: white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => userProvider.fetchUsers(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search by name or email...',
                      hintStyle: TextStyle(color: darkBrown.withOpacity(0.5)),
                      prefixIcon: Icon(Icons.search, color: burntOrange),
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
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: darkBrown.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButton<String>(
                    value: _filterRole,
                    underline: const SizedBox(),
                    dropdownColor: white,
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All Roles')),
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                      DropdownMenuItem(value: 'staff', child: Text('Staff')),
                      DropdownMenuItem(value: 'resident', child: Text('Resident')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _filterRole = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          // Stats Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _statChip('Total', userProvider.users.length, burntOrange),
                const SizedBox(width: 8),
                _statChip(
                    'Admins',
                    userProvider.users.where((u) => u.role == 'admin').length,
                    burntOrange),
                const SizedBox(width: 8),
                _statChip(
                    'Staff',
                    userProvider.users.where((u) => u.role == 'staff').length,
                    Colors.orange),
                const SizedBox(width: 8),
                _statChip(
                    'Residents',
                    userProvider.users.where((u) => u.role == 'resident').length,
                    Colors.green),
              ],
            ),
          ),
          // Users List
          Expanded(
            child: userProvider.loading
                ? const Center(child: CircularProgressIndicator())
                : filteredUsers.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline,
                      size: 64, color: darkBrown.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  Text(
                    'No users found',
                    style: TextStyle(color: darkBrown.withOpacity(0.6)),
                  ),
                ],
              ),
            )
                : RefreshIndicator(
              onRefresh: () => userProvider.fetchUsers(),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredUsers.length,
                itemBuilder: (ctx, index) {
                  final user = filteredUsers[index];
                  final isCurrentUser = currentUser?.id == user.id;
                  return _UserCard(
                    user: user,
                    isCurrentUser: isCurrentUser,
                    isAdmin: isAdmin,
                    onEdit: isAdmin ? () => _showEditUserDialog(context, user) : null,
                    onDelete: isAdmin ? () => _confirmDeleteUser(context, user, currentUser) : null,
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
        onPressed: () => _showAddUserDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add User'),
        backgroundColor: burntOrange,
        foregroundColor: white,
      )
          : null,
    );
  }

  Widget _statChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddUserDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    String selectedRole = 'resident';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: white,
        title: Text('Add New User', style: TextStyle(color: darkBrown)),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
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
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailCtrl,
                  decoration: InputDecoration(
                    labelText: 'Email',
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
                  validator: (v) {
                    if (v!.isEmpty) return 'Required';
                    if (!v.contains('@')) return 'Enter valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneCtrl,
                  decoration: InputDecoration(
                    labelText: 'Phone',
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
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: addressCtrl,
                  decoration: InputDecoration(
                    labelText: 'Address',
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
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: passCtrl,
                  decoration: InputDecoration(
                    labelText: 'Password',
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
                  obscureText: true,
                  validator: (v) {
                    if (v!.isEmpty) return 'Password required';
                    if (v.length < 6) return 'Min 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: InputDecoration(
                    labelText: 'Role',
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
                  items: const [
                    DropdownMenuItem(value: 'resident', child: Text('Resident')),
                    DropdownMenuItem(value: 'staff', child: Text('Staff')),
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  ],
                  onChanged: (value) => selectedRole = value!,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(foregroundColor: darkBrown),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx);
                // FIXED: Changed 'full_name' to 'name'
                final success = await context.read<UserProvider>().createUser({
                  'name': nameCtrl.text.trim(),
                  'email': emailCtrl.text.trim(),
                  'phone': phoneCtrl.text.trim(),
                  'address': addressCtrl.text.trim(),
                  'password': passCtrl.text,
                  'password_confirmation': passCtrl.text,
                  'role': selectedRole,
                });
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'User created successfully' : 'Failed to create user'),
                      backgroundColor: success ? Colors.green : burntOrange,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: burntOrange,
              foregroundColor: white,
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showEditUserDialog(BuildContext context, UserModel user) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: user.name);
    final phoneCtrl = TextEditingController(text: user.phone ?? '');
    final addressCtrl = TextEditingController(text: user.address ?? '');
    String selectedRole = user.role;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: white,
        title: Text('Edit User', style: TextStyle(color: darkBrown)),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
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
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneCtrl,
                  decoration: InputDecoration(
                    labelText: 'Phone',
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
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: addressCtrl,
                  decoration: InputDecoration(
                    labelText: 'Address',
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
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: InputDecoration(
                    labelText: 'Role',
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
                  items: const [
                    DropdownMenuItem(value: 'resident', child: Text('Resident')),
                    DropdownMenuItem(value: 'staff', child: Text('Staff')),
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  ],
                  onChanged: (value) => selectedRole = value!,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(foregroundColor: darkBrown),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx);
                // FIXED: Changed 'full_name' to 'name'
                final success = await context.read<UserProvider>().updateUser(user.id, {
                  'name': nameCtrl.text.trim(),
                  'phone': phoneCtrl.text.trim(),
                  'address': addressCtrl.text.trim(),
                  'role': selectedRole,
                });
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'User updated successfully' : 'Failed to update user'),
                      backgroundColor: success ? Colors.green : burntOrange,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: burntOrange,
              foregroundColor: white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteUser(BuildContext context, UserModel user, UserModel? currentUser) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: white,
        title: Text('Delete User', style: TextStyle(color: darkBrown)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to permanently delete ${user.name}?',
                style: TextStyle(color: darkBrown)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Text(
                '⚠️ This will PERMANENTLY delete all requests, notifications, and history for this user. This action CANNOT be undone!',
                style: TextStyle(fontSize: 12, color: darkBrown),
              ),
            ),
            const SizedBox(height: 8),
            if (user.role == 'admin')
              Text(
                '⚠️ Warning: This user is an admin!',
                style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            if (currentUser?.id == user.id)
              Text(
                '⚠️ Warning: You cannot delete your own account!',
                style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(foregroundColor: darkBrown),
            child: const Text('Cancel'),
          ),
          if (currentUser?.id != user.id)
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final success = await context.read<UserProvider>().deleteUser(user.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'User deleted successfully' : 'Failed to delete user'),
                      backgroundColor: success ? Colors.green : burntOrange,
                    ),
                  );
                  if (success) {
                    await context.read<UserProvider>().fetchUsers();
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: white,
              ),
              child: const Text('Permanently Delete'),
            ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final UserModel user;
  final bool isCurrentUser;
  final bool isAdmin;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _UserCard({
    required this.user,
    required this.isCurrentUser,
    required this.isAdmin,
    this.onEdit,
    this.onDelete,
  });

  static const Color burntOrange = Color(0xFFBE5633);
  static const Color darkBrown = Color(0xFF46291D);

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return burntOrange;
      case 'staff':
        return Colors.orange;
      case 'resident':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'Admin';
      case 'staff':
        return 'Staff';
      case 'resident':
        return 'Resident';
      default:
        return role;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getRoleColor(user.role).withOpacity(0.1),
          child: Text(
            user.initials,
            style: TextStyle(
              color: _getRoleColor(user.role),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                user.name,
                style: TextStyle(fontWeight: FontWeight.w600, color: darkBrown),
              ),
            ),
            if (isCurrentUser)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: burntOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'You',
                  style: TextStyle(fontSize: 10, color: burntOrange),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email, style: TextStyle(fontSize: 12, color: darkBrown.withOpacity(0.7))),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getRoleColor(user.role).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _getRoleLabel(user.role),
                style: TextStyle(
                  fontSize: 10,
                  color: _getRoleColor(user.role),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isAdmin && onEdit != null)
              IconButton(
                icon: Icon(Icons.edit, color: burntOrange),
                onPressed: onEdit,
              ),
            if (isAdmin && onDelete != null && !isCurrentUser)
              IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    );
  }
}