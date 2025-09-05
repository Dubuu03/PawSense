import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/app_colors.dart';
import '../../core/utils/constants.dart';
import '../../core/services/auth/auth_service_mobile.dart';
import 'auth/terms_and_conditions_modal.dart';
import '../../core/utils/errors.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  // Controllers - updated to match sign_up_page.dart naming
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  DateTime? _dateOfBirth;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreedToTerms = false;
  bool _isLoading = false;
  String? _errorMessage;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;

  // Field tracking for validation
  final Map<String, String?> _fieldErrors = {
    'firstName': null,
    'lastName': null,
    'email': null,
    'phone': null,
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
    
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    setState(() {
      _errorMessage = null;
      _fieldErrors.updateAll((key, value) => null);
    });

    bool hasError = false;
    if (!_formKey.currentState!.validate()) {
      hasError = true;
    }

    // Comprehensive validation
    if (_firstNameController.text.trim().isEmpty) {
      _fieldErrors['firstName'] = 'Enter First Name';
      hasError = true;
    }
    if (_lastNameController.text.trim().isEmpty) {
      _fieldErrors['lastName'] = 'Enter Last Name';
      hasError = true;
    }
    if (_emailController.text.trim().isEmpty) {
      _fieldErrors['email'] = 'Enter Email Address';
      hasError = true;
    }
    if (_phoneController.text.trim().isEmpty) {
      _fieldErrors['phone'] = 'Enter Contact Number';
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
      final uid = await _authService.signUpWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        contactNumber: _phoneController.text.trim(),
        dateOfBirth: _dateOfBirth!,
        agreedToTerms: _agreedToTerms,
        address: _addressController.text.trim(),
      );

      if (uid != null && mounted) {
        context.pushReplacement('/verify-email', extra: {
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'email': _emailController.text.trim(),
          'uid': uid,
          'contactNumber': _phoneController.text.trim(),
          'dateOfBirth': _dateOfBirth!,
          'agreedToTerms': _agreedToTerms,
          'address': _addressController.text.trim(),
        });
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
      setState(() => _errorMessage = 'Sign up failed: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(kSpacingLarge),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                SizedBox(height: kSpacingLarge),
                // Logo and title
                Image.asset('assets/img/logo.png', height: 60),
                SizedBox(height: kSpacingSmall),
                Text(
                  'PawSense.',
                  style: kTextStyleTitle.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: kSpacingMedium),

                // Error message display
                if (_errorMessage != null)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(kSpacingMedium),
                    margin: EdgeInsets.only(bottom: kSpacingMedium),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(kBorderRadius),
                      border: Border.all(color: AppColors.error),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: kTextStyleSmall.copyWith(color: AppColors.error),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // Form fields
                _buildTextFormField(
                  controller: _firstNameController,
                  label: 'First Name',
                  validator: (value) {
                    if (_fieldErrors['firstName'] != null) {
                      return _fieldErrors['firstName'];
                    }
                    if (value == null || value.isEmpty) {
                      return 'First name is required';
                    }
                    return null;
                  },
                ),
                SizedBox(height: kSpacingMedium),

                _buildTextFormField(
                  controller: _lastNameController,
                  label: 'Last Name',
                  validator: (value) {
                    if (_fieldErrors['lastName'] != null) {
                      return _fieldErrors['lastName'];
                    }
                    if (value == null || value.isEmpty) {
                      return 'Last name is required';
                    }
                    return null;
                  },
                ),
                SizedBox(height: kSpacingMedium),


                _buildTextFormField(
                  controller: _emailController,
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (_fieldErrors['email'] != null) {
                      return _fieldErrors['email'];
                    }
                    if (value == null || value.isEmpty) {
                      return 'Email is required';
                    }
                    if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                SizedBox(height: kSpacingMedium),

                _buildTextFormField(
                  controller: _phoneController,
                  label: 'Contact number',
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (_fieldErrors['phone'] != null) {
                      return _fieldErrors['phone'];
                    }
                    if (value == null || value.isEmpty) {
                      return 'Contact number is required';
                    }
                    return null;
                  },
                ),
                SizedBox(height: kSpacingMedium),

                _buildTextFormField(
                  controller: _addressController,
                  label: 'Address',
                  validator: (value) {
                    if (_fieldErrors['address'] != null) {
                      return _fieldErrors['address'];
                    }
                    if (value == null || value.isEmpty) {
                      return 'Address is required';
                    }
                    return null;
                  },
                ),
                SizedBox(height: kSpacingMedium),

                _buildTextFormField(
                  controller: TextEditingController(
                    text: _dateOfBirth != null 
                      ? "${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}"
                      : ''
                  ),
                  label: 'Date of birth',
                  readOnly: true,
                  suffixIcon: Icon(
                    Icons.calendar_today,
                    color: AppColors.textSecondary,
                    size: kIconSizeSmall,
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().subtract(Duration(days: 6570)), // 18 years ago
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: ColorScheme.light(
                              primary: AppColors.primary,
                              onPrimary: AppColors.white,
                              surface: AppColors.white,
                              onSurface: AppColors.textPrimary,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (date != null) {
                      setState(() {
                        _dateOfBirth = date;
                        _fieldErrors['dateOfBirth'] = null;
                      });
                    }
                  },
                  validator: (value) {
                    if (_dateOfBirth == null) {
                      return _fieldErrors['dateOfBirth'] ?? 'Date of birth is required';
                    }
                    return null;
                  },
                ),
                SizedBox(height: kSpacingMedium),

                _buildTextFormField(
                  controller: _passwordController,
                  label: 'Password',
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.textSecondary,
                      size: kIconSizeSmall,
                    ),
                  ),
                  validator: (value) {
                    if (_fieldErrors['password'] != null) {
                      return _fieldErrors['password'];
                    }
                    if (value == null || value.isEmpty) {
                      return 'Password is required';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                SizedBox(height: kSpacingMedium),

                _buildTextFormField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  obscureText: _obscureConfirmPassword,
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.textSecondary,
                      size: kIconSizeSmall,
                    ),
                  ),
                  validator: (value) {
                    if (_fieldErrors['confirmPassword'] != null) {
                      return _fieldErrors['confirmPassword'];
                    }
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                SizedBox(height: kSpacingMedium),

                // Terms and conditions checkbox
                Column(
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
                              activeColor: AppColors.primary,
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
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                    const TextSpan(text: ' and '),
                                    TextSpan(
                                      text: 'Privacy Policy',
                                      style: kTextStyleRegular.copyWith(
                                        color: AppColors.primary,
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
                ),
                SizedBox(height: kSpacingLarge),

                // Sign up button
                SizedBox(
                  width: double.infinity,
                  height: kButtonHeight,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(kButtonRadius),
                      ),
                      elevation: 2,
                      shadowColor: Colors.black.withOpacity(0.1),
                    ),
                    onPressed: _isLoading ? null : _handleSignup,
                    child: _isLoading
                        ? CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.white,
                            ),
                          )
                        : Text(
                            'Sign Up',
                            style: kTextStyleRegular.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                SizedBox(height: kSpacingMedium),

                // Sign in link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: kTextStyleSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        context.go('/signin');
                      },
                      child: Text(
                        'Sign In',
                        style: kTextStyleSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: kSpacingLarge),

                // Bottom image
                Image.asset(
                  'assets/img/image 9.png',
                  height: 175,
                  fit: BoxFit.cover,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool obscureText = false,
    bool readOnly = false,
    Widget? suffixIcon,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kBorderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(kShadowOpacity),
            blurRadius: kShadowBlurRadius,
            offset: kShadowOffset,
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        obscureText: obscureText,
        readOnly: readOnly,
        onTap: onTap,
        style: kTextStyleSmall.copyWith(color: AppColors.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: kTextStyleSmall.copyWith(color: AppColors.textSecondary),
          filled: true,
          fillColor: AppColors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(kBorderRadius),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(kBorderRadius),
            borderSide: BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(kBorderRadius),
            borderSide: BorderSide(color: AppColors.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(kBorderRadius),
            borderSide: BorderSide(color: AppColors.error),
          ),
          suffixIcon: suffixIcon,
          contentPadding: EdgeInsets.symmetric(
            horizontal: kSpacingMedium,
            vertical: kSpacingMedium,
          ),
        ),
      ),
    );
  }
}
