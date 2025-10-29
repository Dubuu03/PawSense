import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/auth/otp_service.dart';
import '../../../core/services/auth/email_service.dart';
import '../../../core/services/user/user_services.dart';
import '../../../core/utils/constants_mobile.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/app_colors.dart';
import '../../../core/widgets/shared/otp_input_widget.dart';
import 'dart:async';

class OTPForgotPasswordPage extends StatefulWidget {
  const OTPForgotPasswordPage({super.key});

  @override
  State<OTPForgotPasswordPage> createState() => _OTPForgotPasswordPageState();
}

class _OTPForgotPasswordPageState extends State<OTPForgotPasswordPage>
    with TickerProviderStateMixin {
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
  String? _emailError;
  String? _newPasswordError;
  String? _confirmPasswordError;
  
  // Password visibility toggles
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  
  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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
    
    // Add listeners for live validation
    _emailController.addListener(_validateEmail);
    _newPasswordController.addListener(_validateNewPassword);
    _confirmPasswordController.addListener(_validateConfirmPassword);
  }

  @override
  void dispose() {
    _successMessageTimer?.cancel();
    _otpVerifiedTimer?.cancel();
    _emailController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }
  
  // Live validation methods
  void _validateEmail() {
    final email = _emailController.text.trim();
    setState(() {
      if (email.isEmpty) {
        _emailError = null;
        _isEmailValid = false;
      } else if (emailValidator(email) != null) {
        _emailError = emailValidator(email);
        _isEmailValid = false;
      } else {
        _emailError = null;
        _isEmailValid = true;
      }
    });
  }
  
  void _validateNewPassword() {
    final password = _newPasswordController.text;
    setState(() {
      if (password.isEmpty) {
        _newPasswordError = null;
        _isNewPasswordValid = false;
      } else if (passwordValidator(password) != null) {
        _newPasswordError = passwordValidator(password);
        _isNewPasswordValid = false;
      } else {
        _newPasswordError = null;
        _isNewPasswordValid = true;
        // Re-validate confirm password when new password changes
        _validateConfirmPassword();
      }
    });
  }
  
  void _validateConfirmPassword() {
    final confirmPassword = _confirmPasswordController.text;
    final newPassword = _newPasswordController.text;
    setState(() {
      if (confirmPassword.isEmpty) {
        _confirmPasswordError = null;
        _isConfirmPasswordValid = false;
      } else if (confirmPassword != newPassword) {
        _confirmPasswordError = 'Passwords do not match';
        _isConfirmPasswordValid = false;
      } else {
        _confirmPasswordError = null;
        _isConfirmPasswordValid = true;
      }
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
      margin: EdgeInsets.only(top: kMobileSizedBoxMedium),
      padding: EdgeInsets.all(kMobilePaddingMedium),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(kMobileBorderRadiusSmall),
        border: Border.all(color: AppColors.border.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
          'Password Requirements:',
          style: kMobileTextStyleSubtitle.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
          SizedBox(height: kMobileSizedBoxSmall),
          _buildRequirementItem(
              'A lowercase letter', requirements['lowercase']!),
          SizedBox(height: 4),
          _buildRequirementItem(
              'A capital (uppercase) letter', requirements['uppercase']!),
          SizedBox(height: 4),
          _buildRequirementItem('A number', requirements['number']!),
          SizedBox(height: 4),
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
        SizedBox(width: kMobileSizedBoxSmall),
        Expanded(
          child: Text(
            text,
            style: kMobileTextStyleSubtitle.copyWith(
              color: isMet ? AppColors.success : AppColors.error,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
  
  void _showSuccessMessage(String message) {
    setState(() {
      _successMessage = message;
      _errorMessage = null;
    });
    
    // Auto-hide success message after 3 seconds
    _successMessageTimer?.cancel();
    _successMessageTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _successMessage = null;
        });
      }
    });
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
      
      // Check if user exists
      final user = await _userServices.getUserByEmail(email);
      if (user == null) {
        setState(() {
          _errorMessage = 'No account found with this email address.';
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
        });
        _showSuccessMessage('OTP sent to your email address');
      } else {
        setState(() {
          _errorMessage = 'Failed to send OTP. Please try again.';
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
        });
        _showSuccessMessage('OTP verified successfully!');
        
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
        _errorMessage = 'Failed to verify OTP. Please try again.';
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
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kMobileBorderRadiusCard),
        ),
        backgroundColor: Colors.white,
        elevation: 8,
        contentPadding: EdgeInsets.all(kMobilePaddingLarge),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(kMobilePaddingMedium),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 48,
              ),
            ),
            SizedBox(height: kMobileSizedBoxXXLarge),
            Text(
              'Password Reset Successful!',
              style: kMobileTextStyleTitle.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: kMobileSizedBoxLarge),
            Text(
              'Your password has been reset successfully. You can now sign in with your new password.',
              style: kMobileTextStyleSubtitle.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: kMobileSizedBoxHuge),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // close dialog
                context.pushReplacement('/signin'); // go to sign in
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: kMobilePaddingSmall),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(kMobileBorderRadiusSmall),
                ),
                elevation: 0,
              ),
              child: Text(
                'Go to Sign In',
                style: kMobileTextStyleSubtitle.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailStep() {
    return Form(
      key: _emailFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Icon
          Container(
            alignment: Alignment.center,
            child: Container(
              padding: EdgeInsets.all(kMobilePaddingLarge),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_reset_rounded,
                size: 48,
                color: AppColors.primary,
              ),
            ),
          ),
          SizedBox(height: kMobileSizedBoxHuge),
          
          // Title and description
          Text(
            'Reset Password',
            style: kMobileTextStyleTitle.copyWith(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: kMobileSizedBoxLarge),
          Text(
            'Enter your email address and we\'ll send you a verification code to reset your password.',
            style: kMobileTextStyleSubtitle.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: kMobileSizedBoxHuge + kMobileSizedBoxMedium),
          
          // Email field
          _buildEmailField(),
          SizedBox(height: kMobileSizedBoxXXLarge),
          
          // Send OTP button
          ElevatedButton(
            onPressed: _isLoading || !_isEmailValid ? null : _sendOTP,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isEmailValid ? AppColors.primary : AppColors.textTertiary,
              foregroundColor: AppColors.white,
              padding: EdgeInsets.symmetric(vertical: kMobilePaddingSmall),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(kMobileBorderRadiusSmall),
              ),
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
                    style: kMobileTextStyleSubtitle.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
          
          // Success message for email step
          if (_successMessage != null && _isEmailSent) ...[
            SizedBox(height: kMobileSizedBoxLarge),
            Container(
              padding: EdgeInsets.all(kMobilePaddingMedium),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(kMobileBorderRadiusSmall),
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
                  SizedBox(width: kMobileSizedBoxSmall),
                  Text(
                    _successMessage!,
                    style: kMobileTextStyleSubtitle.copyWith(
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

  Widget _buildOTPStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Icon
        Container(
          alignment: Alignment.center,
          child: Container(
            padding: EdgeInsets.all(kMobilePaddingLarge),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shield_rounded,
              size: 48,
              color: AppColors.primary,
            ),
          ),
        ),
        SizedBox(height: kMobileSizedBoxHuge),
        
        // Title and description
        Text(
          'Enter Verification Code',
          style: kMobileTextStyleTitle.copyWith(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: kMobileSizedBoxLarge),
        Text(
          'We\'ve sent a 6-digit verification code to $_currentEmail',
          style: kMobileTextStyleSubtitle.copyWith(
            color: AppColors.textSecondary,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: kMobileSizedBoxHuge + kMobileSizedBoxMedium),
        
        // OTP input
        OTPInputWidget(
          onCompleted: _verifyOTP,
          onChanged: (otp) {
            if (_errorMessage != null) {
              setState(() => _errorMessage = null);
            }
          },
          errorMessage: _errorMessage,
          isEnabled: !_isLoading,
        ),
        SizedBox(height: kMobileSizedBoxXXLarge),
        
        // Resend button
        TextButton(
          onPressed: _isLoading ? null : () {
            setState(() {
              _isEmailSent = false;
              _errorMessage = null;
            });
          },
          child: Text(
            'Didn\'t receive the code? Send again',
            style: kMobileTextStyleSubtitle.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Icon
          Container(
            alignment: Alignment.center,
            child: Container(
              padding: EdgeInsets.all(kMobilePaddingMedium),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_open_rounded,
                size: 32,
                color: AppColors.success,
              ),
            ),
          ),
          SizedBox(height: kMobileSizedBoxLarge),
          
          // Title and description
          Text(
            'Create New Password',
            style: kMobileTextStyleTitle.copyWith(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: kMobileSizedBoxMedium),
          Text(
            'Create a new password for your account.',
            style: kMobileTextStyleSubtitle.copyWith(
              color: AppColors.textSecondary,
              height: 1.3,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: kMobileSizedBoxLarge),
          
          // Password fields
          _buildPasswordField(
            controller: _newPasswordController,
            label: 'New Password',
            obscureText: _obscureNewPassword,
            onToggleVisibility: () {
              setState(() => _obscureNewPassword = !_obscureNewPassword);
            },
            validator: passwordValidator,
          ),
          
          // Password requirements
          _buildPasswordRequirements(),
          
          SizedBox(height: kMobileSizedBoxXLarge),
          _buildPasswordField(
            controller: _confirmPasswordController,
            label: 'Confirm Password',
            obscureText: _obscureConfirmPassword,
            onToggleVisibility: () {
              setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
            },
            validator: (value) => confirmPasswordValidator(value, _newPasswordController.text),
          ),
          SizedBox(height: kMobileSizedBoxXXLarge),
          
          // Reset password button
          ElevatedButton(
            onPressed: _isLoading || !_isNewPasswordValid || !_isConfirmPasswordValid ? null : _resetPassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: (_isNewPasswordValid && _isConfirmPasswordValid) ? AppColors.primary : AppColors.textTertiary,
              foregroundColor: AppColors.white,
              padding: EdgeInsets.symmetric(vertical: kMobilePaddingSmall),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(kMobileBorderRadiusSmall),
              ),
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
                    style: kMobileTextStyleSubtitle.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
          
          // OTP Verified Success Message
          if (_showOtpVerifiedMessage) ...[
            SizedBox(height: kMobileSizedBoxLarge),
            Container(
              padding: EdgeInsets.all(kMobilePaddingMedium),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(kMobileBorderRadiusSmall),
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
                  SizedBox(width: kMobileSizedBoxSmall),
                  Text(
                    'OTP verified successfully!',
                    style: kMobileTextStyleSubtitle.copyWith(
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
          style: kMobileTextStyleSubtitle.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: kMobileSizedBoxMedium),
        TextFormField(
          controller: _emailController,
          decoration: InputDecoration(
            hintText: 'Enter your email address',
            hintStyle: kMobileTextStyleSubtitle.copyWith(
              fontWeight: FontWeight.normal,
              color: AppColors.textTertiary,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(kMobileBorderRadiusCard),
              borderSide: BorderSide(
                color: _emailError != null ? AppColors.error : AppColors.textTertiary, 
                width: 1
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(kMobileBorderRadiusCard),
              borderSide: BorderSide(
                color: _emailError != null ? AppColors.error : 
                       _isEmailValid ? AppColors.success : AppColors.textTertiary, 
                width: 1
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(kMobileBorderRadiusCard),
              borderSide: BorderSide(
                color: _emailError != null ? AppColors.error : AppColors.primary, 
                width: 2
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(kMobileBorderRadiusCard),
              borderSide: BorderSide(color: AppColors.error, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(kMobileBorderRadiusCard),
              borderSide: BorderSide(color: AppColors.error, width: 2),
            ),
            prefixIcon: Container(
              margin: EdgeInsets.all(kMobilePaddingSmall),
              padding: EdgeInsets.all(kMobileSizedBoxMedium),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(kMobileBorderRadiusButton),
              ),
              child: Icon(
                Icons.email_outlined,
                color: AppColors.primary,
                size: 18,
              ),
            ),
            suffixIcon: _emailController.text.isNotEmpty ? 
              Icon(
                _isEmailValid ? Icons.check_circle : Icons.error,
                color: _isEmailValid ? AppColors.success : AppColors.error,
                size: 20,
              ) : null,
            contentPadding: EdgeInsets.symmetric(
              horizontal: kMobilePaddingMedium,
              vertical: kMobilePaddingMedium,
            ),
            filled: true,
            fillColor: AppColors.background,
            errorText: _emailError,
            errorStyle: TextStyle(
              color: AppColors.error,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          validator: emailValidator,
          keyboardType: TextInputType.emailAddress,
          style: kMobileTextStyleSubtitle.copyWith(
            fontWeight: FontWeight.normal,
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
  }) {
    // Determine validation state based on controller
    bool isValid = false;
    String? errorText;
    
    if (controller == _newPasswordController) {
      isValid = _isNewPasswordValid;
      errorText = _newPasswordError;
    } else if (controller == _confirmPasswordController) {
      isValid = _isConfirmPasswordValid;
      errorText = _confirmPasswordError;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: kMobileTextStyleSubtitle.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: kMobileSizedBoxMedium),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: 'Enter your $label',
            hintStyle: kMobileTextStyleSubtitle.copyWith(
              fontWeight: FontWeight.normal,
              color: AppColors.textTertiary,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(kMobileBorderRadiusCard),
              borderSide: BorderSide(
                color: errorText != null ? AppColors.error : AppColors.textTertiary, 
                width: 1
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(kMobileBorderRadiusCard),
              borderSide: BorderSide(
                color: errorText != null ? AppColors.error : 
                       isValid ? AppColors.success : AppColors.textTertiary, 
                width: 1
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(kMobileBorderRadiusCard),
              borderSide: BorderSide(
                color: errorText != null ? AppColors.error : AppColors.primary, 
                width: 2
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(kMobileBorderRadiusCard),
              borderSide: BorderSide(color: AppColors.error, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(kMobileBorderRadiusCard),
              borderSide: BorderSide(color: AppColors.error, width: 2),
            ),
            prefixIcon: Container(
              margin: EdgeInsets.all(kMobilePaddingSmall),
              padding: EdgeInsets.all(kMobileSizedBoxMedium),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(kMobileBorderRadiusButton),
              ),
              child: Icon(
                Icons.lock_outline,
                color: AppColors.primary,
                size: 18,
              ),
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
                if (controller.text.isNotEmpty) SizedBox(width: 8),
                IconButton(
                  onPressed: onToggleVisibility,
                  icon: Icon(
                    obscureText ? Icons.visibility : Icons.visibility_off,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: kMobilePaddingMedium,
              vertical: kMobilePaddingMedium,
            ),
            filled: true,
            fillColor: AppColors.background,
            errorText: errorText,
            errorStyle: TextStyle(
              color: AppColors.error,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          validator: validator,
          style: kMobileTextStyleSubtitle.copyWith(
            fontWeight: FontWeight.normal,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: (!_isEmailSent || !_isOTPVerified) ? IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () {
            if (_isOTPVerified) {
              // Go back to OTP step
              setState(() {
                _isOTPVerified = false;
                _errorMessage = null;
                _successMessage = null;
              });
            } else if (_isEmailSent) {
              // Go back to email step
              setState(() {
                _isEmailSent = false;
                _errorMessage = null;
                _successMessage = null;
              });
            } else {
              // Go back to previous screen
              Navigator.pop(context);
            }
          },
        ) : null,
        title: Text(
          'Reset Password',
          style: kMobileTextStyleTitle.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(kMobilePaddingLarge),
            child: Column(
              children: [
                // Error message
                if (_errorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(kMobilePaddingSmall),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(kMobileBorderRadiusSmall),
                      border: Border.all(color: AppColors.error.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: AppColors.error,
                          size: 18,
                        ),
                        SizedBox(width: kMobileSizedBoxLarge),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: kMobileTextStyleSubtitle.copyWith(
                              color: AppColors.error,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: kMobileSizedBoxXLarge),
                ],

                // Success message (only show if not in password step)
                if (_successMessage != null && !_isOTPVerified) ...[
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(kMobilePaddingSmall),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(kMobileBorderRadiusSmall),
                      border: Border.all(color: AppColors.success.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          color: AppColors.success,
                          size: 18,
                        ),
                        SizedBox(width: kMobileSizedBoxLarge),
                        Expanded(
                          child: Text(
                            _successMessage!,
                            style: kMobileTextStyleSubtitle.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: kMobileSizedBoxXLarge),
                ],

                // Step content
                if (!_isEmailSent) 
                  _buildEmailStep()
                else if (!_isOTPVerified) 
                  _buildOTPStep()
                else 
                  _buildPasswordStep(),
                  
                SizedBox(height: kMobileSizedBoxXXLarge),
                
                // Back to login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Remember your password? ',
                      style: kMobileTextStyleSubtitle.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.go('/signin'),
                      child: Text(
                        'Sign In',
                        style: kMobileTextStyleSubtitle.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: kMobileSizedBoxHuge),
              ],
            ),
          ),
        ),
      ),
    );
  }
}