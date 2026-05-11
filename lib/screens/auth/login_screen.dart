import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  // Color constants
  static const Color white = Color(0xFFFFFFFF);
  static const Color burntOrange = Color(0xFFBE5633);
  static const Color darkBrown = Color(0xFF46291D);

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final ok = await auth.login(_emailCtrl.text.trim(), _passCtrl.text);

    if (!mounted) return;

    if (ok) {
      if (auth.isStaff) {
        Navigator.pushReplacementNamed(context, '/admin');
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Login failed'),
          backgroundColor: burntOrange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo image instead of icon and text
                  Image.asset(
                    'assets/images/BSR_Logo_1.png',
                    height: 100,
                    width: 100,
                  ),
                  const SizedBox(height: 40),
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
                    ),
                    validator: (v) => v!.isEmpty ? 'Enter email' : null,
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
                    validator: (v) => v!.isEmpty ? 'Enter password' : null,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: auth.loading ? null : _login,
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
                        : const Text('Login', style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterScreen()),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: burntOrange,
                    ),
                    child: const Text('Create an account'),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}