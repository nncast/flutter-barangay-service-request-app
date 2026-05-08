import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  bool _isEmailValid = true;

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
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();

    // Register using 'name' field (not 'full_name')
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
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      String errorMessage = auth.error ?? 'Registration failed';

      // Check if error is about duplicate email
      if (errorMessage.toLowerCase().contains('email') &&
          (errorMessage.toLowerCase().contains('already') ||
              errorMessage.toLowerCase().contains('taken') ||
              errorMessage.toLowerCase().contains('unique'))) {
        errorMessage = 'This email is already registered. Please use a different email or login.';
        _setEmailError(true);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: burntOrange,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _setEmailError(bool hasError) {
    setState(() {
      _isEmailValid = !hasError;
    });
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      _setEmailError(false);
      return 'Enter email';
    }
    if (!value.contains('@') || !value.contains('.')) {
      _setEmailError(false);
      return 'Enter a valid email address';
    }
    _setEmailError(false);
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
              Icon(Icons.person_add, size: 60, color: burntOrange),
              const SizedBox(height: 20),
              Text(
                'Register as Resident',
                style: TextStyle(
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
                  labelStyle: TextStyle(color: darkBrown),
                  prefixIcon: Icon(Icons.person, color: burntOrange),
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
                validator: (v) => v!.isEmpty ? 'Enter your name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailCtrl,
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(color: darkBrown),
                  prefixIcon: Icon(Icons.email, color: burntOrange),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: darkBrown),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: darkBrown.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: burntOrange, width: 2),
                  ),
                  errorText: !_isEmailValid ? null : null,
                ),
                validator: _validateEmail,
                onChanged: (value) {
                  _setEmailError(false);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneCtrl,
                decoration: InputDecoration(
                  labelText: 'Phone (optional)',
                  labelStyle: TextStyle(color: darkBrown),
                  prefixIcon: Icon(Icons.phone, color: burntOrange),
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
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressCtrl,
                decoration: InputDecoration(
                  labelText: 'Address (optional)',
                  labelStyle: TextStyle(color: darkBrown),
                  prefixIcon: Icon(Icons.home, color: burntOrange),
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
              const SizedBox(height: 16),
              TextFormField(
                controller: _passCtrl,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: TextStyle(color: darkBrown),
                  prefixIcon: Icon(Icons.lock, color: burntOrange),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off, color: darkBrown),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
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
                validator: (v) => v!.length < 6 ? 'Password must be at least 6 characters' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmCtrl,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  labelStyle: TextStyle(color: darkBrown),
                  prefixIcon: Icon(Icons.lock_outline, color: burntOrange),
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
                    ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(white),
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