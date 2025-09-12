import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';
import '../../../core/services/auth/auth_service_mobile.dart';
import 'forgot_password_page.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/errors.dart';
import '../../../core/utils/app_colors.dart';

/// Sign In Page
///
/// Allows users to sign in using email and password with Firebase Authentication.
class SignInPage extends StatefulWidget {
  /// Widget for the sign in page.
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

/// State for SignInPage.
class _SignInPageState extends State<SignInPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final Map<String, String?> _fieldErrors = {
    'email': null,
    'password': null,
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
    _emailController.dispose();
    _passwordController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  String? _passwordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    return null;
  }

  Future<void> _signIn() async {
    // Close any existing snackbar to prevent stacking
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    
    setState(() {
      _fieldErrors.updateAll((key, value) => null);
    });

    bool hasError = false;
    List<String> errorMessages = [];

    // Validate fields using validators
    String? emailError = emailValidator(_emailController.text.trim());
    if (emailError != null) {
      _fieldErrors['email'] = emailError;
      errorMessages.add(emailError);
      hasError = true;
    }

    String? passwordError = _passwordValidator(_passwordController.text.trim());
    if (passwordError != null) {
      _fieldErrors['password'] = passwordError;
      errorMessages.add(passwordError);
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
        
        if (_emailController.text.trim().isEmpty && _fieldErrors['email'] != null) hasEmptyFields = true;
        if (_passwordController.text.trim().isEmpty && _fieldErrors['password'] != null) hasEmptyFields = true;
        
        if (!hasEmptyFields) {
          // Only check for invalid inputs if no empty fields
          if (_emailController.text.trim().isNotEmpty && _fieldErrors['email'] != null) hasInvalidInputs = true;
          if (_passwordController.text.trim().isNotEmpty && _fieldErrors['password'] != null) hasInvalidInputs = true;
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
      final user = await _authService.signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (user == null) {
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
                    'No user found for that email.',
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
      } else if (!user.emailVerified) {
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
                    'Please verify your email before signing in.',
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
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Sign in successful! Welcome back.',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );
        context.go('/home');
      }
    } on FirebaseAuthException catch (e) {
      final mapped = AuthErrorMapper.mapSignInError(e.code);
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
    } catch (e, stack) {
      debugPrint('Unexpected sign-in error: $e\n$stack');
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
                  'An unexpected error occurred. Please try again.',
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
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
                      SizedBox(height: 120),
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
                      SizedBox(height: 8),
                      Text(
                        'Your pet\'s health, our priority',
                        style: kTextStyleSmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      SizedBox(height: 84),

                      _buildCompactTextFormField(
                        keyName: 'email',
                        controller: _emailController,
                        label: 'Email',
                        keyboardType: TextInputType.emailAddress,
                      ),
                      SizedBox(height: 12),

                      _buildCompactTextFormField(
                        keyName: 'password',
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
                            size: 20,
                          ),
                        ),
                      ),
                      SizedBox(height: 8),

                      // Forgot password link
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ForgotPasswordPage(),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Forgot Password?',
                            style: kTextStyleSmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 40),

                      // Sign in button
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
                          onPressed: _isLoading ? null : _signIn,
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
                                  'Sign In',
                                  style: kTextStyleRegular.copyWith(
                                    fontSize: 14,
                                    color: AppColors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),

                      SizedBox(height: 16),

                      // Sign up link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: kTextStyleSmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              context.pushReplacement('/signup');
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Sign Up',
                              style: kTextStyleSmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 173),

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
  }) {
    return Container(
      height: 48,
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
        onChanged: (_) {
          if (_fieldErrors[keyName] != null) {
            setState(() => _fieldErrors[keyName] = null);
          }
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
        ),
      ),
    );
  }
}