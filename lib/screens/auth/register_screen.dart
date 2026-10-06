import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/session.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure = true;

  // Color constants
  static const Color white = Color(0xFFFFFFFF);
  static const Color burntOrange = Color(0xFFBE5633);
  static const Color darkBrown = Color(0xFF46291D);

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final auth = context.read<AuthProvider>();
    if (auth.loading || !_formKey.currentState!.validate()) return;

    final ok = await auth.register({
      'name': _nameCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'address': _addressCtrl.text.trim(),
      'password': _passCtrl.text,
      'password_confirmation': _confirmCtrl.text,
    });

    if (!mounted) return;

    if (ok) {
      goToHome(context);
    } else {
      showMessage(context, auth.error ?? 'Registration failed');
    }
  }

  String? _validateEmail(String? value) {
    final email = (value ?? '').trim();
    if (email.isEmpty) return 'Enter email';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: white,
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: burntOrange,
        foregroundColor: white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              const Icon(Icons.person_add, size: 60, color: burntOrange),
              const SizedBox(height: 20),
              const Text(
                'Register as Resident',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: darkBrown,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  labelStyle: const TextStyle(color: darkBrown),
                  prefixIcon: const Icon(Icons.person, color: burntOrange),
                  border: const OutlineInputBorder(
                    borderSide: const BorderSide(color: darkBrown),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: darkBrown.withValues(alpha: 0.3)),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: const BorderSide(color: burntOrange, width: 2),
                  ),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) => (v ?? '').trim().isEmpty ? 'Enter your name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailCtrl,
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: const TextStyle(color: darkBrown),
                  prefixIcon: const Icon(Icons.email, color: burntOrange),
                  border: const OutlineInputBorder(
                    borderSide: const BorderSide(color: darkBrown),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: darkBrown.withValues(alpha: 0.3)),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: const BorderSide(color: burntOrange, width: 2),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone (optional)',
                  labelStyle: const TextStyle(color: darkBrown),
                  prefixIcon: const Icon(Icons.phone, color: burntOrange),
                  border: const OutlineInputBorder(
                    borderSide: const BorderSide(color: darkBrown),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: darkBrown.withValues(alpha: 0.3)),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: const BorderSide(color: burntOrange, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressCtrl,
                decoration: InputDecoration(
                  labelText: 'Address (optional)',
                  labelStyle: const TextStyle(color: darkBrown),
                  prefixIcon: const Icon(Icons.home, color: burntOrange),
                  border: const OutlineInputBorder(
                    borderSide: const BorderSide(color: darkBrown),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: darkBrown.withValues(alpha: 0.3)),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: const BorderSide(color: burntOrange, width: 2),
                  ),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passCtrl,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: const TextStyle(color: darkBrown),
                  prefixIcon: const Icon(Icons.lock, color: burntOrange),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off, color: darkBrown),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  border: const OutlineInputBorder(
                    borderSide: const BorderSide(color: darkBrown),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: darkBrown.withValues(alpha: 0.3)),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: const BorderSide(color: burntOrange, width: 2),
                  ),
                ),
                validator: (v) => (v ?? '').length < 8 ? 'Password must be at least 8 characters' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmCtrl,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  labelStyle: const TextStyle(color: darkBrown),
                  prefixIcon: const Icon(Icons.lock_outline, color: burntOrange),
                  border: const OutlineInputBorder(
                    borderSide: const BorderSide(color: darkBrown),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: darkBrown.withValues(alpha: 0.3)),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: const BorderSide(color: burntOrange, width: 2),
                  ),
                ),
                validator: (v) => v != _passCtrl.text ? 'Passwords do not match' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: auth.loading ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: burntOrange,
                  foregroundColor: white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: auth.loading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: const AlwaysStoppedAnimation<Color>(white),
                  ),
                )
                    : const Text('Register', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: burntOrange,
                ),
                child: const Text('Already have an account? Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}