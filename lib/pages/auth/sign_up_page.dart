import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'verify_email_page.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _contactController = TextEditingController();
  final _addressController = TextEditingController();

  DateTime? _dateOfBirth;
  bool _agreedToTerms = false;
  bool _isLoading = false;

  @override
  void dispose() {
    for (var c in [
      _usernameController,
      _emailController,
      _passwordController,
      _confirmPasswordController,
      _contactController,
      _addressController
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_dateOfBirth == null) {
      _showSnack('Please select your date of birth');
      return;
    }
    if (!_agreedToTerms) {
      _showSnack('You must agree to the terms');
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnack('Passwords do not match');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Check if username is already taken
      final usernameTaken = await _authService.isUsernameTaken(_usernameController.text.trim());
      if (usernameTaken) {
        _showSnack('Username is already taken');
        setState(() => _isLoading = false);
        return;
      }

      final uid = await _authService.signUpWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        username: _usernameController.text.trim(),
        contactNumber: _contactController.text.trim(),
        dateOfBirth: _dateOfBirth!,
        agreedToTerms: _agreedToTerms,
        address: _addressController.text.trim(),
      );

      if (uid != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => VerifyEmailPage(
              username: _usernameController.text.trim(),
              email: _emailController.text.trim(),
              uid: uid,
              contactNumber: _contactController.text.trim(),
              dateOfBirth: _dateOfBirth!,
              agreedToTerms: _agreedToTerms,
              address: _addressController.text.trim(),
            ),
          ),
        );
      }
    } catch (e) {
      _showSnack('Sign up failed: $e');
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
      appBar: AppBar(title: const Text('Sign Up')),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildTextField(_usernameController, 'Username', validator: (v) => requiredValidator(v, 'Username')),
                      _buildTextField(_emailController, 'Email', validator: emailValidator),
                      _buildTextField(_contactController, 'Contact Number', keyboardType: TextInputType.phone, validator: phoneValidator),
                      _buildTextField(_addressController, 'Address', validator: (v) => requiredValidator(v, 'Address')),
                      _buildDOBPicker(),
                      _buildTextField(_passwordController, 'Password', obscureText: true, validator: passwordValidator),
                      _buildTextField(_confirmPasswordController, 'Confirm Password', obscureText: true, validator: (v) => confirmPasswordValidator(v, _passwordController.text)),
                      _buildTermsCheckbox(),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _agreedToTerms ? _register : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _agreedToTerms ? Colors.blue : Colors.grey,
                        ),
                        child: const Text('Sign Up'),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {bool obscureText = false,
      TextInputType keyboardType = TextInputType.text,
      String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: StatefulBuilder(
        builder: (context, setFieldState) {
          return TextFormField(
            controller: controller,
            decoration: InputDecoration(labelText: label),
            obscureText: obscureText,
            keyboardType: keyboardType,
            validator: validator ??
                (v) => v == null || v.isEmpty ? 'Enter $label' : null,
            onChanged: (_) {
              // Clear error when user types
              setState(() {
                _formKey.currentState?.validate();
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildDOBPicker() {
    return Row(
      children: [
        Expanded(
          child: Text(
      _dateOfBirth == null
        ? 'No date selected'
        : 'DOB: ${_dateOfBirth!.toLocal().toString().split(' ')[0]}',
          ),
        ),
        TextButton(
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime(2000, 1, 1),
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
            );
            if (picked != null) setState(() => _dateOfBirth = picked);
          },
          child: const Text('Select Date'),
        ),
      ],
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      children: [
        Checkbox(
          value: _agreedToTerms,
          onChanged: (val) => setState(() => _agreedToTerms = val ?? false),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
            child: const Text('I agree to the Terms and Conditions'),
          ),
        ),
      ],
    );
  }
}
