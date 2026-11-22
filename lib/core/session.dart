import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/request_provider.dart';
import '../providers/user_provider.dart';
import 'ui_helpers.dart';

/// Opens the dashboard that matches the signed-in user's role.
void goToHome(BuildContext context) {
  final route = context.read<AuthProvider>().isStaff ? '/admin' : '/home';
  Navigator.of(context).pushNamedAndRemoveUntil(route, (_) => false);
}

/// Asks for confirmation, signs out, clears cached data and returns to login.
Future<void> confirmLogout(BuildContext context) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Logout'),
      content: const Text('Are you sure you want to logout?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Logout'),
        ),
      ],
    ),
  );
  if (confirm != true || !context.mounted) return;

  final auth = context.read<AuthProvider>();
  final requests = context.read<RequestProvider>();
  final users = context.read<UserProvider>();
  await auth.logout();
  requests.reset();
  users.reset();

  if (context.mounted) {
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
  }
}

void showMessage(BuildContext context, String message, {bool success = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: success ? kNavy : kRed,
    ));
}
