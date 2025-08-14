import 'dart:async';

import 'package:flutter/material.dart';
import '../../services/auth/auth_service.dart';
import '../../models/user_model.dart';
import '../../utils/constants.dart';
import '../../utils/errors.dart';

/// Verify Email Page
///
/// Instructs users to verify their email address after sign up.
class VerifyEmailPage extends StatefulWidget {
/// Widget for the verify email page.
  final String username;
  final String email;
  final String uid;
  final String contactNumber;
  final DateTime dateOfBirth;
  final bool agreedToTerms;
  final String address;

  const VerifyEmailPage({
    super.key,
    required this.username,
    required this.email,
    required this.uid,
    required this.contactNumber,
    required this.dateOfBirth,
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

  bool _isLoading = false;
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
    setState(() => _isLoading = true);
    try {
      await _authService.resendVerificationEmail();
      _startTimer();
      _showSuccessSnack('Verification email resent successfully!');
    } on Exception catch (e) {
      final mapped = AuthErrorMapper.mapSignInError(e.toString());
      _showErrorSnack(mapped.generalMessage ?? 'Failed to resend email. Please try again.');
    } catch (e) {
      _showErrorSnack('Failed to resend email. Please try again.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveUser() async {
    final user = _authService.currentUser;
    if (!_saved && user != null) {
      await _authService.saveUser(
        UserModel(
          uid: widget.uid,
          username: widget.username,
          email: widget.email,
          contactNumber: widget.contactNumber,
          dateOfBirth: widget.dateOfBirth,
          agreedToTerms: widget.agreedToTerms,
          createdAt: DateTime.now(),
          address: widget.address,
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
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
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
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _handleVerified() async {
    if (!_navigated && mounted) {
      _navigated = true;
      _stopTimer();
      await _saveUser();
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  Widget _buildEmailCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        children: [
          Icon(
            Icons.mark_email_read_outlined,
            color: Colors.blue.shade600,
            size: 28,
          ),
          const SizedBox(height: 12),
          Text(
            'Verification email sent to:',
            style: kTextStyleRegular.copyWith(
              color: Colors.blue.shade700,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Text(
              widget.email,
              style: kTextStyleRegular.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade800,
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
      backgroundColor: Colors.white,

      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24,104,24,24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              
              // Email verification icon with animation
              Center(
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.1),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.mark_email_unread_rounded,
                          size: 64,
                          color: Colors.blue.shade600,
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 32),
              
              Text(
                'Check Your Email',
                style: kTextStyleLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 12),
              
              Text(
                'We\'ve sent a verification link to your email address. Click the link to verify your account and get started.',
                style: kTextStyleRegular.copyWith(
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 32),
              
              _buildEmailCard(),
              
              const SizedBox(height: 24),
              
            
              
              // Resend button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _seconds == 0 && !_isLoading ? _resendEmail : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _seconds == 0 && !_isLoading 
                        ? Colors.blue.shade600 
                        : Colors.grey.shade300,
                    foregroundColor: _seconds == 0 && !_isLoading 
                        ? Colors.white 
                        : Colors.grey.shade600,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.grey.shade600,
                            ),
                          ),
                        )
                      : Text(
                          _seconds == 0
                              ? 'Resend Verification Email'
                              : 'Resend in ${_seconds}s',
                          style: kTextStyleRegular.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Help text
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.help_outline,
                      color: Colors.blue.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Still having trouble? Contact our support team for assistance.',
                        style: kTextStyleRegular.copyWith(
                          color: Colors.blue.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),

               Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                          'Use a different email? ',
                            style: kTextStyleRegular.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                      GestureDetector(
                        onTap: () =>Navigator.pushNamed(context, '/signup'),
                            child: Text(
                              'Sign Up',
                              style: kTextStyleRegular.copyWith(
                                color: Colors.blue.shade600,
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