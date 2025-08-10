import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'verify_email_page.dart';
import 'terms_and_conditions_modal.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';
import '../../utils/errors.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  // Controllers
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _contactController = TextEditingController();
  final _addressController = TextEditingController();

  DateTime? _dateOfBirth;
  bool _agreedToTerms = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final Map<String, bool> _fieldTouched = {
    'username': false,
    'email': false,
    'contact': false,
    'address': false,
    'password': false,
    'confirmPassword': false,
  };

  final Map<String, String?> _fieldErrors = {
    'username': null,
    'email': null,
    'contact': null,
    'address': null,
    'password': null,
    'confirmPassword': null,
    'dateOfBirth': null,
    'terms': null,
  };

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    for (var c in [
      _usernameController,
      _emailController,
      _passwordController,
      _confirmPasswordController,
      _contactController,
      _addressController,
    ]) {
      c.dispose();
    }
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    setState(() {
      _errorMessage = null;
      _fieldErrors.updateAll((key, value) => null);
    });

    bool hasError = false;
    if (!_formKey.currentState!.validate()) {
      hasError = true;
    }

    if (_usernameController.text.trim().isEmpty) {
      _fieldErrors['username'] = 'Enter Username';
      hasError = true;
    }
    if (_emailController.text.trim().isEmpty) {
      _fieldErrors['email'] = 'Enter Email Address';
      hasError = true;
    }
    if (_contactController.text.trim().isEmpty) {
      _fieldErrors['contact'] = 'Enter Contact Number';
      hasError = true;
    }
    if (_addressController.text.trim().isEmpty) {
      _fieldErrors['address'] = 'Enter Address';
      hasError = true;
    }
    if (_passwordController.text.isEmpty) {
      _fieldErrors['password'] = 'Enter Password';
      hasError = true;
    }
    if (_confirmPasswordController.text.isEmpty) {
      _fieldErrors['confirmPassword'] = 'Confirm your password';
      hasError = true;
    }

    if (_dateOfBirth == null) {
      _fieldErrors['dateOfBirth'] = 'Please select your date of birth';
      hasError = true;
    }
    if (!_agreedToTerms) {
      _fieldErrors['terms'] = 'You must agree to the terms and conditions';
      hasError = true;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _fieldErrors['confirmPassword'] = 'Passwords do not match';
      setState(() => _errorMessage = 'Passwords do not match');
      hasError = true;
    }

    setState(() {});
    if (hasError) return;

    setState(() => _isLoading = true);

    try {
      final usernameTaken = await _authService.isUsernameTaken(
        _usernameController.text.trim(),
      );
      if (usernameTaken) {
        setState(() {
          _fieldErrors['username'] = 'Username is already taken. Please choose another.';
          _isLoading = false;
        });
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
    } on Exception catch (e) {
      final error = e.toString();
      final mapped = AuthErrorMapper.mapSignUpError(error);
      setState(() {
        if (mapped.field != null && mapped.message != null) {
          _fieldErrors[mapped.field!] = mapped.message;
        }
        _errorMessage = mapped.generalMessage;
      });
    } catch (e) {
      setState(() => _errorMessage = 'Sign up failed: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildWelcomeSection() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue.shade600,
                Colors.blue.shade700,
              ],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.blue.shade200,
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.person_add_rounded,
            size: 48,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Join Us Today!',
          style: kTextStyleLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Create your account to get started',
          style: kTextStyleRegular.copyWith(
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String keyName,
    required TextEditingController controller,
    required String label,
    required String hintText,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: kTextStyleRegular.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          autovalidateMode: _fieldTouched[keyName]!
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: Colors.grey[500],
              fontWeight: FontWeight.normal,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: _fieldErrors[keyName] != null ? Colors.red : Colors.grey.shade300,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: _fieldErrors[keyName] != null ? Colors.red : Colors.blue.shade600,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.red),
            ),
            prefixIcon: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Colors.blue.shade600,
                size: 20,
              ),
            ),
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            errorText: _fieldErrors[keyName],
          ),
          validator: validator ?? (v) => v == null || v.isEmpty ? 'Enter $label' : null,
          onChanged: (_) {
            if (!_fieldTouched[keyName]!) {
              setState(() => _fieldTouched[keyName] = true);
            }
            if (_fieldErrors[keyName] != null) {
              setState(() => _fieldErrors[keyName] = null);
            }
          },
          style: kTextStyleRegular.copyWith(
            fontWeight: FontWeight.normal,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildPasswordField({
    required String keyName,
    required TextEditingController controller,
    required String label,
    required String hintText,
    required String? Function(String?) validator,
  }) {
    bool isObscure = keyName == 'password'
        ? _obscurePassword
        : _obscureConfirmPassword;

    return _buildTextField(
      keyName: keyName,
      controller: controller,
      label: label,
      hintText: hintText,
      obscureText: isObscure,
      validator: validator,
      icon: Icons.lock_outline,
      suffixIcon: IconButton(
        icon: Icon(
          isObscure ? Icons.visibility_off : Icons.visibility,
          color: Colors.grey[600],
        ),
        onPressed: () => setState(() {
          if (keyName == 'password') {
            _obscurePassword = !_obscurePassword;
          } else {
            _obscureConfirmPassword = !_obscureConfirmPassword;
          }
        }),
      ),
    );
  }

  Widget _buildDOBPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date of Birth',
          style: kTextStyleRegular.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime(2000, 1, 1),
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.light(
                      primary: Colors.blue.shade600,
                      onPrimary: Colors.white,
                      surface: Colors.white,
                      onSurface: Colors.grey.shade700,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) setState(() => _dateOfBirth = picked);
          },
          child: AbsorbPointer(
            child: TextFormField(
              decoration: InputDecoration(
                hintText: 'Select your date of birth',
                 hintStyle: TextStyle(
                  color: Colors.grey[500],
                  fontWeight: FontWeight.normal,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
                ),
                prefixIcon: Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.cake_outlined,
                    color: Colors.blue.shade600,
                    size: 20,
                  ),
                ),
                suffixIcon: Icon(
                  Icons.calendar_today,
                  color: Colors.grey[600],
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                errorText: _fieldErrors['dateOfBirth'],
              ),
              controller: TextEditingController(
                text: _dateOfBirth == null
                    ? ''
                    : '${_dateOfBirth!.day.toString().padLeft(2, '0')}/${_dateOfBirth!.month.toString().padLeft(2, '0')}/${_dateOfBirth!.year}',
              ),
              readOnly: true,
              style: kTextStyleRegular.copyWith(
                fontWeight: FontWeight.normal,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildTermsCheckbox() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: _agreedToTerms,
                  onChanged: (val) async {
                    if (val == true && !_agreedToTerms) {
                      final agreed = await showDialog<bool>(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => const TermsAndConditionsModal(),
                      );
                      setState(() => _agreedToTerms = agreed == true);
                    } else if (val == false) {
                      setState(() => _agreedToTerms = false);
                    }
                  },
                  activeColor: Colors.blue.shade600,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    if (!_agreedToTerms) {
                      final agreed = await showDialog<bool>(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => const TermsAndConditionsModal(),
                      );
                      setState(() => _agreedToTerms = agreed == true);
                    } else {
                      setState(() => _agreedToTerms = false);
                    }
                  },
                  child: RichText(
                    text: TextSpan(
                      style: kTextStyleRegular.copyWith(
                        color: Colors.grey[700],
                      ),
                      children: [
                        const TextSpan(text: 'I agree to the '),
                        TextSpan(
                          text: 'Terms and Conditions',
                          style: kTextStyleRegular.copyWith(
                            color: Colors.blue.shade600,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        const TextSpan(text: ' and '),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: kTextStyleRegular.copyWith(
                            color: Colors.blue.shade600,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_fieldErrors['terms'] != null)
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 6),
            child: Text(
              _fieldErrors['terms']!,
              style: TextStyle(color: Colors.red.shade700, fontSize: 13),
            ),
          ),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: Colors.blue.shade600,
                          strokeWidth: 3,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Creating your account...',
                          style: kTextStyleRegular.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24,44,24,24),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildWelcomeSection(),
                                const SizedBox(height: 32),
                                _buildTextField(
                                  keyName: 'username',
                                  controller: _usernameController,
                                  label: 'Username',
                                  hintText: 'Choose a unique username',
                                  validator: (v) => requiredValidator(v, 'Username'),
                                  icon: Icons.person_outline,
                                ),
                                _buildTextField(
                                  keyName: 'email',
                                  controller: _emailController,
                                  label: 'Email Address',
                                  hintText: 'Enter your email address',
                                  validator: emailValidator,
                                  icon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                ),
                                _buildTextField(
                                  keyName: 'contact',
                                  controller: _contactController,
                                  label: 'Contact Number',
                                  hintText: 'Enter your phone number',
                                  keyboardType: TextInputType.phone,
                                  validator: phoneValidator,
                                  icon: Icons.phone_outlined,
                                ),
                                _buildTextField(
                                  keyName: 'address',
                                  controller: _addressController,
                                  label: 'Address',
                                  hintText: 'Enter your complete address',
                                  validator: (v) => requiredValidator(v, 'Address'),
                                  icon: Icons.home_outlined,
                                ),
                                _buildDOBPicker(),
                                _buildPasswordField(
                                  keyName: 'password',
                                  controller: _passwordController,
                                  label: 'Password',
                                  hintText: 'Create a strong password',
                                  validator: passwordValidator,
                                ),
                                _buildPasswordField(
                                  keyName: 'confirmPassword',
                                  controller: _confirmPasswordController,
                                  label: 'Confirm Password',
                                  hintText: 'Re-enter your password',
                                  validator: (v) =>
                                      confirmPasswordValidator(v, _passwordController.text),
                                ),
                                _buildTermsCheckbox(),
                                const SizedBox(height: 24),
                                if (_errorMessage != null) ...[
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.red.shade200),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.error_outline,
                                          color: Colors.red.shade600,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            _errorMessage!,
                                            style: TextStyle(
                                              color: Colors.red.shade700,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                ],
                                ElevatedButton(
                                  onPressed: _agreedToTerms ? _register : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _agreedToTerms
                                        ? Colors.blue.shade600
                                        : Colors.grey.shade400,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 18),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    'Create Account',
                                    style: kTextStyleRegular.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 32),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Already have an account? ',
                                      style: kTextStyleRegular.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => Navigator.pushReplacementNamed(
                                        context,
                                        '/signin',
                                      ),
                                      child: Text(
                                        'Sign In',
                                        style: kTextStyleRegular.copyWith(
                                          color: Colors.blue.shade600,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 40),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}