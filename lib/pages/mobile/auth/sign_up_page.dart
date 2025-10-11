import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';
import '../../../core/services/auth/auth_service_mobile.dart';
import 'terms_and_conditions_modal.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/errors.dart';
import '../../../core/utils/app_colors.dart';
import '../../../core/utils/text_utils.dart'; // Import TextUtils

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
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  bool _acceptTerms = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final Map<String, String?> _fieldErrors = {
    'firstName': null,
    'lastName': null,
    'email': null,
    'phone': null,
    'address': null,
    'password': null,
    'confirmPassword': null,
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
      _firstNameController,
      _lastNameController,
      _emailController,
      _passwordController,
      _confirmPasswordController,
      _phoneController,
      _addressController,
    ]) {
      c.dispose();
    }
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  String? _validateField(String keyName, String value) {
    switch (keyName) {
      case 'firstName':
        return nameValidator(value.trim(), 'First name');
      case 'lastName':
        return nameValidator(value.trim(), 'Last name');
      case 'email':
        return emailValidator(value.trim());
      case 'phone':
        return phoneValidator(value.trim());
      case 'address':
        return addressValidator(value.trim());
      case 'password':
        // Also validate confirm password when password changes
        if (_confirmPasswordController.text.isNotEmpty) {
          _fieldErrors['confirmPassword'] = confirmPasswordValidator(
            _confirmPasswordController.text.trim(), 
            value.trim()
          );
        }
        // Don't return error text for password field - we'll show requirements instead
        return null;
      case 'confirmPassword':
        return confirmPasswordValidator(value.trim(), _passwordController.text.trim());
      default:
        return null;
    }
  }

  Map<String, bool> _getPasswordRequirements(String password) {
    return {
      'lowercase': RegExp(r'[a-z]').hasMatch(password),
      'uppercase': RegExp(r'[A-Z]').hasMatch(password),
      'number': RegExp(r'[0-9]').hasMatch(password),
      'minLength': password.length >= 8,
    };
  }

  Widget _buildPasswordRequirements() {
    final password = _passwordController.text;
    final requirements = _getPasswordRequirements(password);
    
    if (password.isEmpty) return SizedBox.shrink();
    
    return Container(
      margin: EdgeInsets.only(top: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRequirementItem('A lowercase letter', requirements['lowercase']!),
          SizedBox(height: 4),
          _buildRequirementItem('A capital (uppercase) letter', requirements['uppercase']!),
          SizedBox(height: 4),
          _buildRequirementItem('A number', requirements['number']!),
          SizedBox(height: 4),
          _buildRequirementItem('Minimum 8 characters', requirements['minLength']!),
        ],
      ),
    );
  }

  Widget _buildRequirementItem(String text, bool isMet) {
    return Row(
      children: [
        Icon(
          isMet ? Icons.check : Icons.close,
          color: isMet ? Colors.green : Colors.red,
          size: 16,
        ),
        SizedBox(width: 8),
        Text(
          text,
          style: kTextStyleSmall.copyWith(
            color: isMet ? Colors.green : Colors.red,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Future<void> _handleSignup() async {
    // Close any existing snackbar to prevent stacking
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    
    setState(() {
      _fieldErrors.updateAll((key, value) => null);
    });

    bool hasError = false;
    List<String> errorMessages = [];

    // Validate fields using improved validators
    String? firstNameError = nameValidator(_firstNameController.text.trim(), 'First name');
    if (firstNameError != null) {
      _fieldErrors['firstName'] = firstNameError;
      errorMessages.add(firstNameError);
      hasError = true;
    }

    String? lastNameError = nameValidator(_lastNameController.text.trim(), 'Last name');
    if (lastNameError != null) {
      _fieldErrors['lastName'] = lastNameError;
      errorMessages.add(lastNameError);
      hasError = true;
    }

    String? emailError = emailValidator(_emailController.text.trim());
    if (emailError != null) {
      _fieldErrors['email'] = emailError;
      errorMessages.add(emailError);
      hasError = true;
    }

    String? phoneError = phoneValidator(_phoneController.text.trim());
    if (phoneError != null) {
      _fieldErrors['phone'] = phoneError;
      errorMessages.add(phoneError);
      hasError = true;
    }

    String? addressError = addressValidator(_addressController.text.trim());
    if (addressError != null) {
      _fieldErrors['address'] = addressError;
      errorMessages.add(addressError);
      hasError = true;
    }

    // Check if password meets all requirements
    final passwordValue = _passwordController.text.trim();
    final passwordRequirements = _getPasswordRequirements(passwordValue);
    final allRequirementsMet = passwordRequirements.values.every((met) => met);
    
    if (passwordValue.isEmpty) {
      _fieldErrors['password'] = 'Enter password';
      errorMessages.add('Enter password');
      hasError = true;
    } else if (!allRequirementsMet) {
      _fieldErrors['password'] = 'Password does not meet requirements';
      errorMessages.add('Password does not meet requirements');
      hasError = true;
    } else {
      _fieldErrors['password'] = null;
    }

    String? confirmPasswordError = confirmPasswordValidator(_confirmPasswordController.text.trim(), _passwordController.text.trim());
    if (confirmPasswordError != null) {
      _fieldErrors['confirmPassword'] = confirmPasswordError;
      errorMessages.add(confirmPasswordError);
      hasError = true;
    }

    if (!_acceptTerms) {
      _fieldErrors['terms'] = 'You must agree to the Terms and Conditions';
      errorMessages.add('You must agree to the Terms and Conditions');
      hasError = true;
    }

    if (hasError) {
      String snackMessage;

      if (errorMessages.length == 1) {
        snackMessage = errorMessages.first; // Show specific error
      } else {
        // Check for empty/null fields first (priority)
        bool hasEmptyFields = false;
        bool hasInvalidInputs = false;
        
        if (_firstNameController.text.trim().isEmpty && _fieldErrors['firstName'] != null) hasEmptyFields = true;
        if (_lastNameController.text.trim().isEmpty && _fieldErrors['lastName'] != null) hasEmptyFields = true;
        if (_emailController.text.trim().isEmpty && _fieldErrors['email'] != null) hasEmptyFields = true;
        if (_phoneController.text.trim().isEmpty && _fieldErrors['phone'] != null) hasEmptyFields = true;
        if (_addressController.text.trim().isEmpty && _fieldErrors['address'] != null) hasEmptyFields = true;
        if (_passwordController.text.trim().isEmpty && _fieldErrors['password'] != null) hasEmptyFields = true;
        if (_confirmPasswordController.text.trim().isEmpty && _fieldErrors['confirmPassword'] != null) hasEmptyFields = true;
        if (!_acceptTerms && _fieldErrors['terms'] != null) hasEmptyFields = true;
        
        if (!hasEmptyFields) {
          // Only check for invalid inputs if no empty fields
          if (_firstNameController.text.trim().isNotEmpty && _fieldErrors['firstName'] != null) hasInvalidInputs = true;
          if (_lastNameController.text.trim().isNotEmpty && _fieldErrors['lastName'] != null) hasInvalidInputs = true;
          if (_emailController.text.trim().isNotEmpty && _fieldErrors['email'] != null) hasInvalidInputs = true;
          if (_phoneController.text.trim().isNotEmpty && _fieldErrors['phone'] != null) hasInvalidInputs = true;
          if (_addressController.text.trim().isNotEmpty && _fieldErrors['address'] != null) hasInvalidInputs = true;
          if (_passwordController.text.trim().isNotEmpty && _fieldErrors['password'] != null) hasInvalidInputs = true;
          if (_confirmPasswordController.text.trim().isNotEmpty && _fieldErrors['confirmPassword'] != null) hasInvalidInputs = true;
        }
        
        if (hasEmptyFields) {
          snackMessage = 'Fill up required fields'; // Priority: Empty/null fields
        } else if (hasInvalidInputs) {
          snackMessage = 'Invalid inputs'; // Secondary: Invalid inputs
        } else {
          snackMessage = 'Please check your inputs'; // Fallback
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), 
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  snackMessage,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 18), 
                padding: EdgeInsets.zero,   
                constraints: const BoxConstraints(),
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
            ],
          ),
        ),
      );

      return;
    }

    setState(() => _isLoading = true);

    try {
      final formattedFirstName = TextUtils.capitalizeWords(_firstNameController.text.trim());
      final formattedLastName = TextUtils.capitalizeWords(_lastNameController.text.trim());
      final fullName = TextUtils.formatFullName(
        _firstNameController.text.trim(), 
        _lastNameController.text.trim()
      );

      final uid = await _authService.signUpWithEmail(
        email: _emailController.text.trim().toLowerCase(),
        password: _passwordController.text.trim(),
        firstName: formattedFirstName,
        lastName: formattedLastName,
        contactNumber: _phoneController.text.trim(),
        agreedToTerms: _acceptTerms,
        address: _addressController.text.trim(),
      );

      if (uid != null && mounted) {
        context.pushReplacement('/verify-email', extra: {
          'firstName': formattedFirstName,
          'lastName': formattedLastName,
          'username': fullName,
          'email': _emailController.text.trim().toLowerCase(),
          'uid': uid,
          'contactNumber': _phoneController.text.trim(),
          'agreedToTerms': _acceptTerms,
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
      });
      
      // Show general error message in snackbar (no auto-close)
      if (mapped.generalMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            duration: const Duration(days: 365), // Effectively no auto-close
            behavior: SnackBarBehavior.floating,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), 
            content: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    mapped.generalMessage!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 18), 
                  padding: EdgeInsets.zero,   
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  },
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      // Show general error message in snackbar (no auto-close)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          duration: const Duration(days: 365), // Effectively no auto-close
          behavior: SnackBarBehavior.floating,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), 
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Sign up failed: ${e.toString()}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 18), 
                padding: EdgeInsets.zero,   
                constraints: const BoxConstraints(),
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
            ],
          ),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFDFF9),
      body: SafeArea(
        bottom: false,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: kSpacingLarge),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(height: 40),
                      Image.asset('assets/img/logo.png', height: 80),
                      SizedBox(height: 12),
                      Text(
                        'PawSense.',
                        style: kMobileTextStyleTitle.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      SizedBox(height: 32),

                      _buildCompactTextFormField(
                        keyName: 'firstName',
                        controller: _firstNameController,
                        label: 'First Name',
                        maxLength: 30,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z\s\-']")),
                          LengthLimitingTextInputFormatter(30),
                        ],
                      ),
                      SizedBox(height: 16),

                      _buildCompactTextFormField(
                        keyName: 'lastName',
                        controller: _lastNameController,
                        label: 'Last Name',
                        maxLength: 30,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z\s\-']")),
                          LengthLimitingTextInputFormatter(30),
                        ],
                      ),
                      SizedBox(height: 16),

                      _buildCompactTextFormField(
                        keyName: 'email',
                        controller: _emailController,
                        label: 'Email',
                        keyboardType: TextInputType.emailAddress,
                        inputFormatters: [
                          FilteringTextInputFormatter.deny(RegExp(r'^\s')), // Prevent starting with space
                          FilteringTextInputFormatter.deny(RegExp(r'\s$')), // Prevent ending with space
                        ],
                      ),
                      SizedBox(height: 12),

                      _buildCompactTextFormField(
                        keyName: 'phone',
                        controller: _phoneController,
                        label: 'Contact number',
                        keyboardType: TextInputType.phone,
                        maxLength: 11,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(11),
                        ],
                      ),
                      SizedBox(height: 12),

                      _buildCompactTextFormField(
                        keyName: 'address',
                        controller: _addressController,
                        label: 'Address',
                        maxLength: 200,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z0-9\s\-'.,#/]")),
                          LengthLimitingTextInputFormatter(200),
                        ],
                      ),
                      SizedBox(height: 12),

                      _buildCompactTextFormField(
                        keyName: 'password',
                        controller: _passwordController,
                        label: 'Password',
                        obscureText: _obscurePassword,
                        maxLength: 128,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(128),
                        ],
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
                            size: 20,
                          ),
                        ),
                      ),
                      
                      // Password requirements
                      _buildPasswordRequirements(),
                      
                      SizedBox(height: 12),

                      _buildCompactTextFormField(
                        keyName: 'confirmPassword',
                        controller: _confirmPasswordController,
                        label: 'Confirm Password',
                        obscureText: _obscureConfirmPassword,
                        maxLength: 128,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(128),
                        ],
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
                            size: 20,
                          ),
                        ),
                      ),
                      SizedBox(height: 12),

                      // Terms and conditions checkbox
                      Container(
                        width: double.infinity,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Checkbox(
                              value: _acceptTerms,
                              side: BorderSide(
                                color: _fieldErrors['terms'] != null 
                                  ? AppColors.error 
                                  : AppColors.textTertiary,
                                width: 2,
                              ),
                              onChanged: (value) async {
                                if (value == true && !_acceptTerms) {
                                  final agreed = await showDialog<bool>(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (context) => const TermsAndConditionsModal(),
                                  );
                                  setState(() {
                                    _acceptTerms = agreed == true;
                                    if (_acceptTerms) {
                                      _fieldErrors['terms'] = null;
                                    }
                                  });
                                } else if (value == false) {
                                  setState(() => _acceptTerms = false);
                                }
                              },
                              activeColor: AppColors.primary,
                              checkColor: AppColors.background,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),

                            GestureDetector(
                              onTap: () async {
                                if (!_acceptTerms) {
                                  final agreed = await showDialog<bool>(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (context) => const TermsAndConditionsModal(),
                                  );
                                  setState(() {
                                    _acceptTerms = agreed == true;
                                    if (_acceptTerms) {
                                      _fieldErrors['terms'] = null;
                                    }
                                  });
                                } else {
                                  setState(() => _acceptTerms = false);
                                }
                              },
                              child: Text(
                                'I agree to the Terms and Conditions',
                                textAlign: TextAlign.center,
                                style: kTextStyleSmall.copyWith(
                                  color: _fieldErrors['terms'] != null 
                                    ? AppColors.error 
                                    : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 12),

                      // Sign up button
                      SizedBox(
                        width: double.infinity,
                        height: 40,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(kButtonRadius),
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            elevation: 2,
                            shadowColor: Colors.black.withOpacity(0.1),
                            disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
                          ),
                          onPressed: _isLoading ? null : _handleSignup,
                          child: _isLoading
                              ? SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  'Sign Up',
                                  style: kTextStyleRegular.copyWith(
                                    fontSize: 14,
                                    color: AppColors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),

                      SizedBox(height: 16),

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
                              context.pushReplacement('/signin');
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
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
                      SizedBox(height: 70),

                      Image.asset(
                        'assets/img/image 9.png',
                        height: 108,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactTextFormField({
    required String keyName,
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    bool obscureText = false,
    bool readOnly = false,
    Widget? suffixIcon,
    VoidCallback? onTap,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
  }) {
    return Container(
      // Remove fixed height to allow for error text
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: Offset(0, 2),
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        readOnly: readOnly,
        onTap: onTap,
        inputFormatters: inputFormatters,
        maxLength: maxLength,
        onChanged: (value) {
          // Real-time validation
          setState(() {
            _fieldErrors[keyName] = _validateField(keyName, value);
          });
        },
        style: kTextStyleSmall.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: kTextStyleSmall.copyWith(
            color: AppColors.textPrimary,
            fontSize: 14,
          ),
          filled: true,
          fillColor: AppColors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: _fieldErrors[keyName] != null ? AppColors.error : AppColors.border,
              width: _fieldErrors[keyName] != null ? 1.5 : 0.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: _fieldErrors[keyName] != null ? AppColors.error : AppColors.primary,
              width: 1.5,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.error, width: 2.0),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.error, width: 1.5),
          ),
          suffixIcon: suffixIcon,
          suffixIconConstraints: suffixIcon != null 
            ? BoxConstraints(minWidth: 48, maxWidth: 48, minHeight: 32, maxHeight: 32)
            : null,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          isDense: true,
          counterText: "", // Always hide character counter
          errorText: _fieldErrors[keyName],
          errorStyle: kTextStyleSmall.copyWith(
            color: AppColors.error,
            fontSize: 12,
            height: 1.2,
          ),
          errorMaxLines: 2,
        ),
      ),
    );
  }
}
