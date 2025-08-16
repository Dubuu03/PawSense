import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../../../core/services/auth/auth_service_web.dart';
import '../../../core/utils/app_colors.dart';
import '../../../core/utils/constants.dart';
import '../../../core/models/clinic_model.dart';
import '../../../core/models/clinic_details_model.dart';

class AdminSignupPage extends StatefulWidget {
  const AdminSignupPage({super.key});

  @override
  State<AdminSignupPage> createState() => _AdminSignupPageState();
}

class _AdminSignupPageState extends State<AdminSignupPage> {
  final _formKeys = [
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
  ];

  final _authService = AuthServiceWeb();
  final PageController _pageController = PageController();

  int _currentStep = 0;
  bool _isLoading = false;
  String? _errorMessage;

  // Step 1: Account Info
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _usernameController = TextEditingController();

  // Step 2: Clinic Info
  final _clinicNameController = TextEditingController();
  final _clinicAddressController = TextEditingController();
  final _clinicPhoneController = TextEditingController();
  final _clinicEmailController = TextEditingController();
  final _servicesController = TextEditingController();

  // Step 3: Clinic Details
  final _certificationNameController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  DateTime? _issuedDate;
  DateTime? _expiryDate;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameController.dispose();
    _clinicNameController.dispose();
    _clinicAddressController.dispose();
    _clinicPhoneController.dispose();
    _clinicEmailController.dispose();
    _servicesController.dispose();
    _certificationNameController.dispose();
    _licenseNumberController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKeys[2].currentState!.validate()) return;
    if (!_agreedToTerms) {
      setState(() {
        _errorMessage = 'Please agree to the terms and conditions';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Create the auth account without file upload for testing
      final result = await _authService.signUpClinicAdmin(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        username: _usernameController.text.trim(),
        clinic: Clinic(
          id: '', // Will be set to uid
          name: _clinicNameController.text.trim(),
          address: _clinicAddressController.text.trim(),
          phone: _clinicPhoneController.text.trim(),
          email: _clinicEmailController.text.trim(),
          services: _servicesController.text.trim(),
          createdAt: DateTime.now(),
        ),
        clinicDetails: ClinicDetails(
          id: '', // Will be generated
          clinicId: '', // Will be set to uid
          certificationName: _certificationNameController.text.trim(),
          licenseNumber: _licenseNumberController.text.trim(),
          issuedDate: _issuedDate!,
          expiryDate: _expiryDate!,
          documentImage: '', // Empty for now (testing)
          createdAt: DateTime.now(),
        ),
        documentBytes: null, // No upload for testing
        documentName: null,
      );

      if (result.success) {
        // Show success message and navigate to login
        _showSuccessDialog();
      } else {
        setState(() {
          _errorMessage = result.error ?? 'Signup failed. Please try again.';
        });
      }
    } catch (e) {
      print('Signup error: $e'); // Add debug print
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.check_circle, color: AppColors.success, size: 64),
        title: Text(
          'Account Created Successfully!',
          style: kTextStyleRegular.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Your admin account has been created. You can now sign in to access the admin panel.',
          style: kTextStyleRegular.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushReplacementNamed(context, '/web_login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Continue to Sign In'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(bool isIssuedDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isIssuedDate
          ? (_issuedDate ?? DateTime.now())
          : (_expiryDate ?? DateTime.now().add(const Duration(days: 365))),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (isIssuedDate) {
          _issuedDate = picked;
        } else {
          _expiryDate = picked;
        }
      });
    }
  }

  void _nextStep() {
    if (_currentStep < 2) {
      if (_formKeys[_currentStep].currentState!.validate()) {
        setState(() {
          _currentStep++;
        });
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } else {
      _handleSignup();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final isActive = index == _currentStep;
        final isCompleted = index < _currentStep;

        return Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? AppColors.success
                    : isActive
                    ? AppColors.primary
                    : AppColors.border,
              ),
              child: Icon(
                isCompleted ? Icons.check : Icons.circle,
                color: AppColors.white,
                size: 16,
              ),
            ),
            if (index < 2)
              Container(
                width: 40,
                height: 2,
                color: index < _currentStep
                    ? AppColors.success
                    : AppColors.border,
                margin: const EdgeInsets.symmetric(horizontal: 8),
              ),
          ],
        );
      }),
    );
  }

  Widget _buildAccountInfoStep() {
    return Form(
      key: _formKeys[0],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Information',
            style: kTextStyleTitle.copyWith(
              fontSize: 24,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your admin account credentials',
            style: kTextStyleRegular.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),

          // Email
          _buildTextField(
            controller: _emailController,
            label: 'Email Address',
            hint: 'Enter your email address',
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email address';
              }
              if (!RegExp(
                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
              ).hasMatch(value)) {
                return 'Please enter a valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Username
          _buildTextField(
            controller: _usernameController,
            label: 'Username',
            hint: 'Enter your username',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a username';
              }
              if (value.length < 3) {
                return 'Username must be at least 3 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Password
          _buildTextField(
            controller: _passwordController,
            label: 'Password',
            hint: 'Enter your password',
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.textSecondary,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a password';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Confirm Password
          _buildTextField(
            controller: _confirmPasswordController,
            label: 'Confirm Password',
            hint: 'Confirm your password',
            obscureText: _obscureConfirmPassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.textSecondary,
              ),
              onPressed: () => setState(
                () => _obscureConfirmPassword = !_obscureConfirmPassword,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please confirm your password';
              }
              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildClinicInfoStep() {
    return Form(
      key: _formKeys[1],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Clinic Information',
            style: kTextStyleTitle.copyWith(
              fontSize: 24,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tell us about your veterinary clinic',
            style: kTextStyleRegular.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),

          // Clinic Name
          _buildTextField(
            controller: _clinicNameController,
            label: 'Clinic Name',
            hint: 'Enter your clinic name',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your clinic name';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Clinic Address
          _buildTextField(
            controller: _clinicAddressController,
            label: 'Clinic Address',
            hint: 'Enter your clinic address',
            maxLines: 3,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your clinic address';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Phone and Email Row
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _clinicPhoneController,
                  label: 'Phone Number',
                  hint: 'Enter phone number',
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter phone number';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _clinicEmailController,
                  label: 'Clinic Email',
                  hint: 'Enter clinic email',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter clinic email';
                    }
                    if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Services Offered
          _buildTextField(
            controller: _servicesController,
            label: 'Services Offered',
            hint: 'Describe the services your clinic offers',
            maxLines: 4,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please describe your services';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildClinicDetailsStep() {
    return Form(
      key: _formKeys[2],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Certification Details',
            style: kTextStyleTitle.copyWith(
              fontSize: 24,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Provide your veterinary certification information',
            style: kTextStyleRegular.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),

          // Certification Name
          _buildTextField(
            controller: _certificationNameController,
            label: 'Certification Name',
            hint: 'Enter certification name',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter certification name';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          // License Number
          _buildTextField(
            controller: _licenseNumberController,
            label: 'License Number',
            hint: 'Enter license number',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter license number';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Date Row
          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  label: 'Issued Date',
                  value: _issuedDate,
                  onTap: () => _selectDate(true),
                  validator: () =>
                      _issuedDate == null ? 'Please select issued date' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDateField(
                  label: 'Expiry Date',
                  value: _expiryDate,
                  onTap: () => _selectDate(false),
                  validator: () =>
                      _expiryDate == null ? 'Please select expiry date' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Document Upload - TEMPORARILY DISABLED
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Document upload is temporarily disabled for testing. You can add certification documents later from your admin panel.',
                    style: kTextStyleSmall.copyWith(
                      fontSize: 14,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Terms and Conditions
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: _agreedToTerms,
                onChanged: (value) =>
                    setState(() => _agreedToTerms = value ?? false),
                activeColor: AppColors.primary,
              ),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: kTextStyleSmall.copyWith(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                    children: [
                      const TextSpan(text: 'I agree to the '),
                      TextSpan(
                        text: 'Terms and Conditions',
                        style: kTextStyleSmall.copyWith(
                          fontSize: 14,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            // Handle terms and conditions tap
                          },
                      ),
                      const TextSpan(text: ' and '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: kTextStyleSmall.copyWith(
                          fontSize: 14,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            // Handle privacy policy tap
                          },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    int? maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: kTextStyleSmall.copyWith(
            fontSize: 14,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLines: maxLines,
          style: kTextStyleRegular.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: kTextStyleRegular.copyWith(
              color: AppColors.textTertiary,
            ),
            filled: true,
            fillColor: AppColors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.border, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.border, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.error, width: 1),
            ),
            suffixIcon: suffixIcon,
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
    required String? Function() validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: kTextStyleSmall.copyWith(
            fontSize: 14,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(
                color: validator() != null ? AppColors.error : AppColors.border,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(8),
              color: AppColors.white,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value != null
                        ? '${value.day}/${value.month}/${value.year}'
                        : 'Select date',
                    style: kTextStyleRegular.copyWith(
                      color: value != null
                          ? AppColors.textPrimary
                          : AppColors.textTertiary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  Icons.calendar_today_outlined,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (validator() != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              validator()!,
              style: kTextStyleSmall.copyWith(
                fontSize: 12,
                color: AppColors.error,
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          margin: const EdgeInsets.all(20),
          child: Card(
            elevation: 0,
            color: AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    children: [
                      IconButton(
                        onPressed: _currentStep > 0
                            ? _previousStep
                            : () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back),
                        color: AppColors.textSecondary,
                      ),
                      Expanded(
                        child: Text(
                          'Create Admin Account',
                          style: kTextStyleTitle.copyWith(
                            fontSize: 28,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 48), // Balance the back button
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Step Indicator
                  _buildStepIndicator(),
                  const SizedBox(height: 40),

                  // Error Message
                  if (_errorMessage != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: kTextStyleSmall.copyWith(
                                fontSize: 14,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Form Content
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        SingleChildScrollView(child: _buildAccountInfoStep()),
                        SingleChildScrollView(child: _buildClinicInfoStep()),
                        SingleChildScrollView(child: _buildClinicDetailsStep()),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Navigation Buttons
                  Row(
                    children: [
                      if (_currentStep > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isLoading ? null : _previousStep,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(color: AppColors.border),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Previous',
                              style: kTextStyleRegular.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      if (_currentStep > 0) const SizedBox(width: 16),
                      Expanded(
                        flex: _currentStep == 0 ? 1 : 1,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _nextStep,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                            disabledBackgroundColor: AppColors.primary
                                .withOpacity(0.6),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  _currentStep == 2 ? 'Create Account' : 'Next',
                                  style: kTextStyleRegular.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Footer
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: kTextStyleSmall.copyWith(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                      children: [
                        const TextSpan(text: 'Already have an account? '),
                        TextSpan(
                          text: 'Sign in here',
                          style: kTextStyleSmall.copyWith(
                            fontSize: 14,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.pushReplacementNamed(
                                context,
                                '/web_login',
                              );
                            },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
