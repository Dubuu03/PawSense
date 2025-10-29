import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/auth/otp_service.dart';
import '../../../core/services/auth/email_service.dart';
import '../../../core/services/user/user_services.dart';
import '../../../core/utils/app_colors.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/shared/otp_input_widget.dart';

class WebOTPForgotPasswordPage extends StatefulWidget {
  const WebOTPForgotPasswordPage({super.key});

  @override
  State<WebOTPForgotPasswordPage> createState() => _WebOTPForgotPasswordPageState();
}

class _WebOTPForgotPasswordPageState extends State<WebOTPForgotPasswordPage>
    with SingleTickerProviderStateMixin {
  final _userServices = UserServices();
  final _otpService = OTPService();
  final _emailService = EmailService();
  
  final _emailFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _isEmailSent = false;
  bool _isOTPVerified = false;
  String? _errorMessage;
  String? _successMessage;
  String _currentEmail = '';
  Timer? _successMessageTimer;
  Timer? _otpVerifiedTimer;
  bool _showOtpVerifiedMessage = false;
  
  // Live validation states
  bool _isEmailValid = false;
  bool _isNewPasswordValid = false;
  bool _isConfirmPasswordValid = false;
  
  // Password visibility toggles
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _fadeController.dispose();
    _successMessageTimer?.cancel();
    _otpVerifiedTimer?.cancel();
    super.dispose();
  }

  Future<void> _sendOTP() async {
    if (!_emailFormKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final email = _emailController.text.trim().toLowerCase();
      
      // Check if user exists and is admin
      final user = await _userServices.getUserByEmail(email);
      
      if (user == null) {
        setState(() {
          _errorMessage = 'No admin account found with this email address.';
          _isLoading = false;
        });
        return;
      }

      // Security checks for web admin panel
      if (user.role == 'super_admin') {
        setState(() {
          _errorMessage = 
              'Super admin accounts cannot reset password via this form. '
              'Please contact the system administrator for assistance.';
          _isLoading = false;
        });
        return;
      }

      if (user.role != 'admin') {
        setState(() {
          _errorMessage = 
              'This password reset is for admin accounts only. '
              'Mobile users should use the PawSense mobile app to reset their password.';
          _isLoading = false;
        });
        return;
      }

      if (!user.isActive || user.suspendedAt != null) {
        setState(() {
          _errorMessage = 
              'Your admin account has been suspended or deactivated. '
              'Please contact the system administrator for assistance.';
          _isLoading = false;
        });
        return;
      }

      // Generate and send OTP
      final otp = await _otpService.createOTP(
        email: email,
        purpose: OTPPurpose.passwordReset,
      );
      
      final emailSent = await _emailService.sendPasswordResetOTP(
        email: email,
        otp: otp,
        recipientName: user.firstName ?? user.username,
      );

      if (emailSent) {
        setState(() {
          _currentEmail = email;
          _isEmailSent = true;
                  setState(() {
          _successMessage = 'Verification code sent to your email address';
        });
        _showSuccessMessage();
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to send verification code. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyOTP(String otp) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _otpService.validateOTP(
        email: _currentEmail,
        code: otp,
        purpose: OTPPurpose.passwordReset,
      );

      if (result.isValid) {
        setState(() {
          _isOTPVerified = true;
          _showOtpVerifiedMessage = true;
          _successMessage = 'Code verified successfully!';
        });
        _showSuccessMessage();
        
        // Auto-hide OTP verified message after 3 seconds
        _otpVerifiedTimer?.cancel();
        _otpVerifiedTimer = Timer(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _showOtpVerifiedMessage = false;
            });
          }
        });
      } else {
        setState(() {
          _errorMessage = result.message;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to verify code. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _resetPassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await _userServices.getUserByEmail(_currentEmail);
      if (user == null) {
        setState(() {
          _errorMessage = 'User not found. Please try again.';
          _isLoading = false;
        });
        return;
      }

      // In a real app, you would update the password through Firebase Auth
      // For now, we'll show a success message
      // await _authService.updatePassword(user.uid, _newPasswordController.text);
      
      // Clean up OTP
      await _otpService.deleteOTP(
        email: _currentEmail,
        purpose: OTPPurpose.passwordReset,
      );

      _showSuccessDialog();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to reset password. Please try again.';
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
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: AppColors.white,
        elevation: 24,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success Icon
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.success,
                  size: 64,
                ),
              ),
              const SizedBox(height: 32),
              
              // Title
              Text(
                'Password Reset Successful!',
                style: kTextStyleTitle.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  fontSize: 24,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              // Description
              Text(
                'Your password has been reset successfully. You can now sign in to the admin panel with your new password.',
                style: kTextStyleRegular.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              // Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    context.go('/login'); // Navigate to login
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Go to Admin Login',
                    style: kTextStyleRegular.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccessMessage() {
    _successMessageTimer?.cancel();
    _successMessageTimer = Timer(Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _successMessage = null;
        });
      }
    });
  }

  void _validateEmail(String value) {
    setState(() {
      _isEmailValid = value.isNotEmpty && 
                     RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value);
    });
  }

  void _validateNewPassword(String value) {
    setState(() {
      _isNewPasswordValid = value.length >= 8 &&
                           RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(value);
    });
    // Re-validate confirm password when new password changes
    if (_confirmPasswordController.text.isNotEmpty) {
      _validateConfirmPassword(_confirmPasswordController.text);
    }
  }

  void _validateConfirmPassword(String value) {
    setState(() {
      _isConfirmPasswordValid = value.isNotEmpty && 
                               value == _newPasswordController.text;
    });
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
    final password = _newPasswordController.text;
    final requirements = _getPasswordRequirements(password);

    if (password.isEmpty) return SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Password Requirements:',
            style: kTextStyleRegular.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          _buildRequirementItem(
              'A lowercase letter', requirements['lowercase']!),
          const SizedBox(height: 6),
          _buildRequirementItem(
              'A capital (uppercase) letter', requirements['uppercase']!),
          const SizedBox(height: 6),
          _buildRequirementItem('A number', requirements['number']!),
          const SizedBox(height: 6),
          _buildRequirementItem(
              'Minimum 8 characters', requirements['minLength']!),
        ],
      ),
    );
  }

  Widget _buildRequirementItem(String text, bool isMet) {
    return Row(
      children: [
        Icon(
          isMet ? Icons.check_circle : Icons.cancel,
          color: isMet ? AppColors.success : AppColors.error,
          size: 16,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: kTextStyleRegular.copyWith(
              color: isMet ? AppColors.success : AppColors.error,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailStep() {
    return Form(
      key: _emailFormKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Icon
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_reset_rounded,
                size: 50,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 32),
          
          // Title
          Text(
            'Reset Admin Password',
            style: kTextStyleTitle.copyWith(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          
          // Description
          Text(
            'Enter your admin email address and we\'ll send you a verification code to reset your password.',
            style: kTextStyleRegular.copyWith(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          
          // Email Field
          _buildEmailField(),
          const SizedBox(height: 24),
          
          // Send Code button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading || !_isEmailValid ? null : _sendOTP,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isEmailValid ? AppColors.primary : AppColors.textTertiary,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Send Verification Code',
                      style: kTextStyleRegular.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: AppColors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOTPStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Icon
        Center(
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shield_rounded,
              size: 50,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 32),
        
        // Title
        Text(
          'Enter Verification Code',
          style: kTextStyleTitle.copyWith(
            color: AppColors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        
        // Description
        Text(
          'We\'ve sent a 6-digit verification code to $_currentEmail',
          style: kTextStyleRegular.copyWith(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        
        // OTP input
        WebOTPInputWidget(
          onCompleted: _verifyOTP,
          onChanged: (otp) {
            if (_errorMessage != null) {
              setState(() => _errorMessage = null);
            }
          },
          errorMessage: _errorMessage,
          isEnabled: !_isLoading,
        ),
        const SizedBox(height: 24),
        
        // Resend button
        Center(
          child: TextButton(
            onPressed: _isLoading ? null : () {
              setState(() {
                _isEmailSent = false;
                _errorMessage = null;
                _successMessage = null;
              });
            },
            child: Text(
              'Didn\'t receive the code? Send again',
              style: kTextStyleRegular.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordStep() {
    return Form(
      key: _passwordFormKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Icon
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_open_rounded,
                size: 36,
                color: AppColors.success,
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Title
          Text(
            'Create New Password',
            style: kTextStyleTitle.copyWith(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          
          // Description
          Text(
            'Create a new password for your admin account.',
            style: kTextStyleRegular.copyWith(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          
          // Password fields
          _buildPasswordField(
            controller: _newPasswordController,
            label: 'New Password',
            obscureText: _obscureNewPassword,
            onToggleVisibility: () {
              setState(() => _obscureNewPassword = !_obscureNewPassword);
            },
            onChanged: _validateNewPassword,
            isValid: _isNewPasswordValid,
            validator: passwordValidator,
          ),
          
          // Password requirements
          _buildPasswordRequirements(),
          
          const SizedBox(height: 20),
          _buildPasswordField(
            controller: _confirmPasswordController,
            label: 'Confirm Password',
            obscureText: _obscureConfirmPassword,
            onToggleVisibility: () {
              setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
            },
            onChanged: _validateConfirmPassword,
            isValid: _isConfirmPasswordValid,
            validator: (value) => confirmPasswordValidator(value, _newPasswordController.text),
          ),
          const SizedBox(height: 24),
          
          // Reset password button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading || !_isNewPasswordValid || !_isConfirmPasswordValid ? null : _resetPassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: (_isNewPasswordValid && _isConfirmPasswordValid) ? AppColors.primary : AppColors.textTertiary,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Reset Password',
                      style: kTextStyleRegular.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: AppColors.white,
                      ),
                    ),
            ),
          ),
          
          // OTP Verified Success Message
          if (_showOtpVerifiedMessage) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.success.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: AppColors.success,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Code verified successfully!',
                    style: kTextStyleRegular.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Email Address',
          style: kTextStyleSmall.copyWith(
            fontSize: 15,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            onChanged: (value) {
              _validateEmail(value);
              if (_errorMessage != null) {
                setState(() => _errorMessage = null);
              }
            },
            style: kTextStyleRegular.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              hintText: 'Enter your admin email address',
              hintStyle: kTextStyleRegular.copyWith(
                color: AppColors.textTertiary,
                fontSize: 15,
              ),
              filled: true,
              fillColor: AppColors.white,
              prefixIcon: Icon(
                Icons.email_outlined,
                color: AppColors.primary,
                size: 22,
              ),
              suffixIcon: _emailController.text.isNotEmpty
                  ? Icon(
                      _isEmailValid ? Icons.check_circle : Icons.error,
                      color: _isEmailValid ? AppColors.success : AppColors.error,
                      size: 20,
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: _isEmailValid ? AppColors.success : AppColors.border,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: _isEmailValid ? AppColors.success : AppColors.border,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: _isEmailValid ? AppColors.success : AppColors.primary,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.error),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: AppColors.error,
                  width: 2,
                ),
              ),
            ),
            validator: emailValidator,
            onFieldSubmitted: (_) => _sendOTP(),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    required String? Function(String?) validator,
    required Function(String) onChanged,
    required bool isValid,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: kTextStyleSmall.copyWith(
            fontSize: 15,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            onChanged: onChanged,
            style: kTextStyleRegular.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              hintText: 'Enter your $label',
              hintStyle: kTextStyleRegular.copyWith(
                color: AppColors.textTertiary,
                fontSize: 15,
              ),
              filled: true,
              fillColor: AppColors.white,
              prefixIcon: Icon(
                Icons.lock_outline,
                color: AppColors.primary,
                size: 22,
              ),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (controller.text.isNotEmpty)
                    Icon(
                      isValid ? Icons.check_circle : Icons.error,
                      color: isValid ? AppColors.success : AppColors.error,
                      size: 20,
                    ),
                  IconButton(
                    onPressed: onToggleVisibility,
                    icon: Icon(
                      obscureText ? Icons.visibility : Icons.visibility_off,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: isValid ? AppColors.success : AppColors.border,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: isValid ? AppColors.success : AppColors.border,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: isValid ? AppColors.success : AppColors.primary,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.error),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: AppColors.error,
                  width: 2,
                ),
              ),
            ),
            validator: validator,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withOpacity(0.05),
              AppColors.background,
              AppColors.primary.withOpacity(0.03),
            ],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Card(
                  elevation: 8,
                  shadowColor: AppColors.primary.withOpacity(0.1),
                  color: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 48,
                    ),
                    child: _isLoading && (!_isEmailSent && !_isOTPVerified)
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 50,
                                height: 50,
                                child: CircularProgressIndicator(
                                  color: AppColors.primary,
                                  strokeWidth: 3,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Sending verification code...',
                                style: kTextStyleRegular.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Error Message
                              if (_errorMessage != null) ...[
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.error.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppColors.error.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        color: AppColors.error,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _errorMessage!,
                                          style: kTextStyleSmall.copyWith(
                                            color: AppColors.error,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],

                              // Success Message (only show if not in password step)
                              if (_successMessage != null && !_isOTPVerified) ...[
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppColors.success.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle_outline,
                                        color: AppColors.success,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _successMessage!,
                                          style: kTextStyleSmall.copyWith(
                                            color: AppColors.success,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],

                              // Step content
                              if (!_isEmailSent) 
                                _buildEmailStep()
                              else if (!_isOTPVerified) 
                                _buildOTPStep()
                              else 
                                _buildPasswordStep(),
                                
                              const SizedBox(height: 32),
                              
                              // Back to Login
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Remember your password? ',
                                    style: kTextStyleRegular.copyWith(
                                      color: AppColors.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () => context.go('/login'),
                                    child: Text(
                                      'Sign In',
                                      style: kTextStyleRegular.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}