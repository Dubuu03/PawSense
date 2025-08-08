import 'package:flutter/material.dart';
import '../../services/auth/auth_service.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendReset() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final email = _emailController.text.trim();
      // Check if email exists in Firebase Auth
      final methods = await _authService.fetchSignInMethodsForEmail(email);
      if (methods.isEmpty) {
        _showSnack('No account found for that email.');
      } else {
        await _authService.sendPasswordResetEmail(email);
        _showSnack('Password reset link sent! Check your email.');
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      _showSnack('Failed to send reset link: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(labelText: 'Email'),
                        validator: (v) => v != null && v.contains('@') ? null : 'Enter valid email',
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _sendReset,
                        child: const Text('Send Reset Link'),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
