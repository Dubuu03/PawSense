import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/auth/otp_service.dart';
import '../../../core/services/auth/email_service.dart';
import '../../../core/services/auth/auth_service_mobile.dart';
import '../../../core/models/user/user_model.dart';
import '../../../core/utils/constants_mobile.dart';
import '../../../core/utils/app_colors.dart';
import '../../../core/utils/text_utils.dart';
import '../../../core/widgets/shared/otp_input_widget.dart';

/// OTP-based Email Verification Page
/// 
/// Replaces the external email verification with an in-app OTP flow
class OTPVerifyEmailPage extends StatefulWidget {
  final String firstName;
  final String lastName;
  final String email;
  final String uid;
  final String contactNumber;
  final bool agreedToTerms;
  final String address;

  const OTPVerifyEmailPage({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.uid,
    required this.contactNumber,
    required this.agreedToTerms,
    required this.address,
  });

  @override
  State<OTPVerifyEmailPage> createState() => _OTPVerifyEmailPageState();
}

class _OTPVerifyEmailPageState extends State<OTPVerifyEmailPage> 
    with TickerProviderStateMixin {
  final _authService = AuthService();
  final _otpService = OTPService();
  final _emailService = EmailService();

  bool _isLoading = false;
  bool _saved = false;
  bool _navigated = false;
  String? _errorMessage;
  String? _successMessage;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;
  Timer? _successMessageTimer;
  
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _fadeController.forward();
    _pulseController.repeat(reverse: true);
    
    // Send initial OTP
    _sendInitialOTP();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _successMessageTimer?.cancel();
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _sendInitialOTP() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Generate and send OTP
      final otp = await _otpService.createOTP(
        email: widget.email,
        purpose: OTPPurpose.emailVerification,
      );
      
      final capitalizedName = TextUtils.formatFullName(widget.firstName, widget.lastName);
      final emailSent = await _emailService.sendEmailVerificationOTP(
        email: widget.email,
        otp: otp,
        recipientName: capitalizedName,
      );

      if (emailSent) {
        setState(() {
          _successMessage = 'Verification code sent to your email';
        });
        _showSuccessMessage();
        _startCooldown();
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

  Future<void> _resendOTP() async {
    if (_resendCooldown > 0) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      // Generate and send new OTP
      final otp = await _otpService.createOTP(
        email: widget.email,
        purpose: OTPPurpose.emailVerification,
      );
      
      final capitalizedName = TextUtils.formatFullName(widget.firstName, widget.lastName);
      final emailSent = await _emailService.sendEmailVerificationOTP(
        email: widget.email,
        otp: otp,
        recipientName: capitalizedName,
      );

      if (emailSent) {
        setState(() {
          _successMessage = 'New verification code sent to your email';
        });
        _showSuccessMessage();
        _startCooldown();
        _showSuccessSnack('Verification code resent successfully!');
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
        email: widget.email,
        code: otp,
        purpose: OTPPurpose.emailVerification,
      );

      if (result.isValid) {
        await _saveUserAndComplete();
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

  Future<void> _saveUserAndComplete() async {
    if (!_saved && !_navigated) {
      try {
        // Create a username with proper capitalization using utility
        final capitalizedFirstName = TextUtils.capitalizeWords(widget.firstName);
        final capitalizedLastName = TextUtils.capitalizeWords(widget.lastName);
        final username = TextUtils.formatFullName(widget.firstName, widget.lastName);
        
        // Save user data to Firestore with email verification status
        await _authService.saveUser(
          UserModel(
            uid: widget.uid,
            username: username,
            email: widget.email.trim().toLowerCase(),
            contactNumber: widget.contactNumber,
            agreedToTerms: widget.agreedToTerms,
            createdAt: DateTime.now(),
            address: widget.address,
            firstName: capitalizedFirstName,
            lastName: capitalizedLastName,
            role: 'user',
            emailVerified: true, // Mark email as verified after OTP validation
            emailVerifiedAt: DateTime.now(),
          ),
        );
        
        _saved = true;
        
        // Clean up OTP
        await _otpService.deleteOTP(
          email: widget.email,
          purpose: OTPPurpose.emailVerification,
        );

        // Navigate to home
        if (mounted && !_navigated) {
          _navigated = true;
          context.pushReplacement('/home');
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Failed to complete verification. Please try again.';
        });
      }
    }
  }

  void _startCooldown() {
    _resendCooldown = 60; // 60 seconds cooldown
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown > 0) {
        setState(() => _resendCooldown--);
      } else {
        timer.cancel();
      }
    });
  }

  void _showSuccessSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 18,
            ),
            SizedBox(width: kMobileSizedBoxLarge),
            Expanded(
              child: Text(
                message,
                style: kMobileTextStyleSubtitle.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kMobileBorderRadiusSmall),
        ),
        margin: EdgeInsets.all(kMobilePaddingMedium),
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

  Widget _buildEmailCard() {
    return Container(
      padding: EdgeInsets.all(kMobilePaddingMedium),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(kMobileBorderRadiusCard),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.mark_email_read_outlined,
            color: AppColors.primary,
            size: 24,
          ),
          SizedBox(height: kMobileSizedBoxLarge),
          Text(
            'Verification code sent to:',
            style: kMobileTextStyleSubtitle.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: kMobileSizedBoxMedium),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: kMobilePaddingSmall,
              vertical: kMobileSizedBoxSmall,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(kMobileBorderRadiusButton),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Text(
              widget.email,
              style: kMobileTextStyleSubtitle.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.push('/signup'),
        ),
        title: Text(
          'Verify Email',
          style: kMobileTextStyleTitle.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(kMobilePaddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: kMobileSizedBoxXXLarge),
              
              // Email verification icon with animation
              Center(
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        padding: EdgeInsets.all(kMobilePaddingLarge),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                          boxShadow: kMobileCardShadow,
                        ),
                        child: Icon(
                          Icons.verified_user_rounded,
                          size: 48,
                          color: AppColors.primary,
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              SizedBox(height: kMobileSizedBoxHuge),
              
              Text(
                'Verify Your Email',
                style: kMobileTextStyleTitle.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: kMobileSizedBoxLarge),
              
              Text(
                'We\'ve sent a 6-digit verification code to your email address. Enter the code below to verify your account.',
                style: kMobileTextStyleSubtitle.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: kMobileSizedBoxHuge),
              
              _buildEmailCard(),
              
              SizedBox(height: kMobileSizedBoxHuge),

              // Success message
              if (_successMessage != null) ...[
                Container(
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

              // Error message
              if (_errorMessage != null) ...[
                Container(
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
              
              // OTP Input
              OTPInputWidget(
                onCompleted: _verifyOTP,
                onChanged: (otp) {
                  if (_errorMessage != null) {
                    setState(() => _errorMessage = null);
                  }
                },
                errorMessage: _isLoading ? null : _errorMessage,
                isEnabled: !_isLoading,
              ),
              
              SizedBox(height: kMobileSizedBoxXXLarge),
              
              // Resend button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_resendCooldown > 0 || _isLoading) ? null : _resendOTP,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    padding: EdgeInsets.symmetric(vertical: kMobilePaddingSmall),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(kMobileBorderRadiusSmall),
                    ),
                    disabledBackgroundColor: AppColors.textTertiary,
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
                          _resendCooldown > 0 
                              ? 'Resend in ${_resendCooldown}s' 
                              : 'Resend Code',
                          style: kMobileTextStyleSubtitle.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              
              SizedBox(height: kMobileSizedBoxXXLarge),
              
              // Help text
              Container(
                padding: EdgeInsets.all(kMobilePaddingMedium),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(kMobileBorderRadiusSmall),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.help_outline,
                      color: AppColors.primary,
                      size: 18,
                    ),
                    SizedBox(width: kMobileSizedBoxLarge),
                    Expanded(
                      child: Text(
                        'Check your spam folder if you don\'t see the email. Contact support if you need help.',
                        style: kMobileTextStyleSubtitle.copyWith(
                          color: AppColors.primary.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: kMobileSizedBoxXXLarge),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Use a different email? ',
                    style: kMobileTextStyleSubtitle.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.push('/signup'),
                    child: Text(
                      'Sign Up',
                      style: kMobileTextStyleSubtitle.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}