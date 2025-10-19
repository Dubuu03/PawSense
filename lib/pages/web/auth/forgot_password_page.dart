import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/user/user_services.dart';
import '../../../core/utils/app_colors.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/errors.dart';

class WebForgotPasswordPage extends StatefulWidget {
  const WebForgotPasswordPage({super.key});

  @override
  State<WebForgotPasswordPage> createState() => _WebForgotPasswordPageState();
}

class _WebForgotPasswordPageState extends State<WebForgotPasswordPage>
    with SingleTickerProviderStateMixin {
  final _userServices = UserServices();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  
  bool _isLoading = false;
  String? _errorMessage;
  
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
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim().toLowerCase();
      
      print('🔍 Checking user account for: $email');
      
      // Check if user exists in Firestore
      final user = await _userServices.getUserByEmail(email);
      
      if (user == null) {
        setState(() {
          _errorMessage = 'No admin account found with this email address.';
          _isLoading = false;
        });
        return;
      }

      print('✅ User found: ${user.firstName} ${user.lastName}, Role: ${user.role}');

      // Security checks for web admin panel
      // 1. Block super_admin (they should contact system administrator)
      if (user.role == 'super_admin') {
        setState(() {
          _errorMessage = 
              'Super admin accounts cannot reset password via this form. '
              'Please contact the system administrator for assistance.';
          _isLoading = false;
        });
        return;
      }

      // 2. Only allow admin role
      if (user.role != 'admin') {
        setState(() {
          _errorMessage = 
              'This password reset is for admin accounts only. '
              'Mobile users should use the PawSense mobile app to reset their password.';
          _isLoading = false;
        });
        return;
      }

      // 3. Check if admin account is suspended/inactive
      if (!user.isActive || user.suspendedAt != null) {
        setState(() {
          _errorMessage = 
              'Your admin account has been suspended or deactivated. '
              'Please contact the system administrator for assistance.';
          _isLoading = false;
        });
        return;
      }

      print('🔒 Security checks passed. Sending reset email...');

      // Send password reset email
      await _auth.sendPasswordResetEmail(email: email);
      
      print('✅ Password reset email sent successfully');

      if (mounted) {
        _showSuccessDialog();
      }
    } on FirebaseAuthException catch (e) {
      print('❌ FirebaseAuthException: ${e.code} - ${e.message}');
      final mapped = AuthErrorMapper.mapSignInError(e.code);
      setState(() {
        if (mapped.field == 'email') {
          _errorMessage = mapped.message;
        } else {
          _errorMessage = mapped.generalMessage ?? 
              'Failed to send reset link. Please try again.';
        }
      });
    } catch (e) {
      print('❌ Error sending reset email: $e');
      setState(() {
        _errorMessage = 'Failed to send reset link. Please try again.';
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
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.mark_email_read_rounded,
                  color: AppColors.success,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              
              // Title
              Text(
                'Check Your Email',
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
                'We\'ve sent a password reset link to:',
                style: kTextStyleRegular.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              
              // Email Display
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.2),
                  ),
                ),
                child: Text(
                  _emailController.text.trim(),
                  style: kTextStyleRegular.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              
              // Instructions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.border.withOpacity(0.5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppColors.info,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Next Steps:',
                          style: kTextStyleSmall.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInstructionStep('1', 'Check your email inbox'),
                    const SizedBox(height: 8),
                    _buildInstructionStep('2', 'Click the password reset link'),
                    const SizedBox(height: 8),
                    _buildInstructionStep('3', 'Create a new password'),
                    const SizedBox(height: 8),
                    _buildInstructionStep('4', 'Return to login page'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Warning
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    color: AppColors.warning,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'The reset link will expire in 24 hours.',
                      style: kTextStyleSmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context); // Close dialog
                        // Stay on forgot password page
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Resend Email',
                        style: kTextStyleRegular.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
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
                        'Back to Login',
                        style: kTextStyleRegular.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
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

  Widget _buildInstructionStep(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: kTextStyleSmall.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: kTextStyleSmall.copyWith(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
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
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: AppColors.primary,
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
            onChanged: (_) {
              if (_errorMessage != null) {
                setState(() => _errorMessage = null);
              }
            },
            onFieldSubmitted: (_) => _sendResetEmail(),
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
                    child: _isLoading
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
                                'Sending reset link...',
                                style: kTextStyleRegular.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          )
                        : Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Icon with circular background (matching mobile design)
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
                                  'Forgot Password',
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
                                  'Don\'t worry! Enter your email address below and we\'ll send you a link to reset your password.',
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
                                
                                // Reset Button (matching mobile purple button)
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _sendResetEmail,
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
                                      'Reset Password',
                                      style: kTextStyleRegular.copyWith(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                        color: AppColors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                
                                // Having Trouble Card (matching mobile design)
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.primary.withOpacity(0.2),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.info_outline_rounded,
                                        color: AppColors.primary,
                                        size: 24,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Having trouble?',
                                        style: kTextStyleRegular.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primary,
                                          fontSize: 15,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'If you don\'t receive an email within a few minutes, check your spam folder or contact support.',
                                        style: kTextStyleSmall.copyWith(
                                          color: AppColors.primary.withOpacity(0.9),
                                          fontSize: 13,
                                          height: 1.4,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 32),
                                
                                // Back to Login (matching mobile design)
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
      ),
    );
  }
}
