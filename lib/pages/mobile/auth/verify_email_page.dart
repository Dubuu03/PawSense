import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/auth/auth_service_mobile.dart';
import '../../../core/models/user/user_model.dart';
import '../../../core/utils/constants_mobile.dart';
import '../../../core/utils/errors.dart';
import '../../../core/utils/app_colors.dart';
import '../../../core/utils/text_utils.dart';

/// Verify Email Page
///
/// Instructs users to verify their email address after sign up.
class VerifyEmailPage extends StatefulWidget {
/// Widget for the verify email page.
  final String firstName;
  final String lastName;
  final String email;
  final String uid;
  final String contactNumber;
  final DateTime? dateOfBirth;
  final bool agreedToTerms;
  final String address;

  const VerifyEmailPage({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.uid,
    required this.contactNumber,
    this.dateOfBirth,
    required this.agreedToTerms,
    required this.address,
  });

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

/// State for VerifyEmailPage. Handles email verification logic and user saving.
class _VerifyEmailPageState extends State<VerifyEmailPage> 
    with TickerProviderStateMixin {
  final _authService = AuthService();

  bool _saved = false;
  bool _navigated = false;
  int _seconds = 60;
  Timer? _timer;
  late StreamSubscription<bool> _emailVerifiedSub;
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
    
    _startTimer();

    _emailVerifiedSub = _authService.emailVerifiedStream.listen((verified) {
      if (verified) {
        _handleVerified();
      }
    });
  }

  void _startTimer() {
    _seconds = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_seconds > 0) {
        setState(() => _seconds--);
      } else {
        timer.cancel();
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _emailVerifiedSub.cancel();
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _resendEmail() async {
    try {
      await _authService.resendVerificationEmail();
      _startTimer();
      _showSuccessSnack('Verification email resent successfully!');
    } on Exception catch (e) {
      final mapped = AuthErrorMapper.mapSignInError(e.toString());
      _showErrorSnack(mapped.generalMessage ?? 'Failed to resend email. Please try again.');
    } catch (e) {
      _showErrorSnack('Failed to resend email. Please try again.');
    }
  }

  Future<void> _saveUser() async {
    final user = _authService.currentUser;
    if (!_saved && user != null) {
      // Create a username with proper capitalization using utility
      final capitalizedFirstName = TextUtils.capitalizeWords(widget.firstName);
      final capitalizedLastName = TextUtils.capitalizeWords(widget.lastName);
      final username = TextUtils.formatFullName(widget.firstName, widget.lastName);
      
      await _authService.saveUser(
        UserModel(
          uid: widget.uid,
          username: username,
          email: widget.email,
          contactNumber: widget.contactNumber,
          dateOfBirth: widget.dateOfBirth,
          agreedToTerms: widget.agreedToTerms,
          createdAt: DateTime.now(),
          address: widget.address,
          firstName: capitalizedFirstName,
          lastName: capitalizedLastName,
        ),
      );
      _saved = true;
    }
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

  void _showErrorSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.error_outline,
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
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kMobileBorderRadiusSmall),
        ),
        margin: EdgeInsets.all(kMobilePaddingMedium),
      ),
    );
  }

  Future<void> _handleVerified() async {
    if (!_navigated && mounted) {
      _navigated = true;
      _stopTimer();
      await _saveUser();
      context.pushReplacement('/home');
    }
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
            'Verification email sent to:',
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
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(kMobilePaddingLarge, 90, kMobilePaddingLarge, kMobilePaddingLarge),
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
                          Icons.mark_email_unread_rounded,
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
                'We\'ve sent a verification link to your email address. Click the link to verify your account and get started.',
                style: kMobileTextStyleSubtitle.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: kMobileSizedBoxHuge),
              
              _buildEmailCard(),
              
              SizedBox(height: kMobileSizedBoxXXLarge),
              
              // Resend button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _resendEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    padding: EdgeInsets.symmetric(vertical: kMobilePaddingSmall),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(kMobileBorderRadiusSmall),
                    ),
                  ),
                  child: Text(
                    'Resend Email',
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
                        'Still having trouble? Contact our support team for assistance.',
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