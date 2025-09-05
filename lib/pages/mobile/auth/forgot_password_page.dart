import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/services/auth/auth_service_mobile.dart';
import '../../../core/utils/constants_mobile.dart';
import '../../../core/utils/validators.dart';
import '../../../core/services/user/user_services.dart';
import '../../../core/utils/errors.dart';
import '../../../core/utils/app_colors.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage>
    with TickerProviderStateMixin {
  final _userServices = UserServices();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  String? _errorMessage;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
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

  Future<void> _sendReset() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim().toLowerCase();
      // Check if user exists in Firestore
      final user = await _userServices.getUserByEmail(email);
      if (user == null) {
        setState(() {
          _errorMessage = 'Account not found.';
          _isLoading = false;
        });
        return;
      }
      await _authService.sendPasswordResetEmail(email);
      if (mounted) {
        _showSuccessDialog();
      }
    } on FirebaseAuthException catch (e) {
      final mapped = AuthErrorMapper.mapSignInError(e.code);
      setState(() {
        if (mapped.field == 'email') {
          _errorMessage = mapped.message;
        } else {
          _errorMessage = mapped.generalMessage ?? 'Failed to send reset link. Please try again.';
        }
      });
    } catch (e) {
      setState(() => _errorMessage = 'Failed to send reset link. Please try again.');
    } finally {
      setState(() => _isLoading = false);
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
              padding: EdgeInsets.all(kMobilePaddingSmall),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.mark_email_read_rounded,
                color: AppColors.primary,
                size: 36,
              ),
            ),
            SizedBox(height: kMobileSizedBoxXXLarge),
            Text(
              'Check Your Email',
              style: kMobileTextStyleTitle.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontSize: 18,
              ),
            ),
            SizedBox(height: kMobileSizedBoxLarge),
            Text(
              'Weve sent a password reset link to:',
              style: kMobileTextStyleSubtitle.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: kMobileSizedBoxMedium),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: kMobilePaddingMedium,
                vertical: kMobileSizedBoxMedium,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(kMobileBorderRadiusButton),
              ),
              child: Text(
                _emailController.text.trim(),
                style: kMobileTextStyleSubtitle.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: kMobilePaddingMedium),
            Text(
              'Click the link in the email to reset your password. The link will expire in 24 hours.',
              style: kMobileTextStyleSubtitle.copyWith(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: kMobileSizedBoxHuge),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // close dialog
                      Navigator.pop(context); // back to login
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
                      'Back to Login',
                      style: kMobileTextStyleSubtitle.copyWith(
                        color: Colors.white,
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
    );
  }

Widget _buildEmailField(void Function() onChanged) {
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
            borderSide: BorderSide(color: AppColors.textTertiary, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(kMobileBorderRadiusCard),
            borderSide: BorderSide(color: AppColors.textTertiary, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(kMobileBorderRadiusCard),
            borderSide: BorderSide(color: AppColors.primary, width: 2),
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
          contentPadding: EdgeInsets.symmetric(
            horizontal: kMobilePaddingMedium,
            vertical: kMobilePaddingMedium,
          ),
          filled: true,
          fillColor: AppColors.background,
        ),
        validator: emailValidator,
        keyboardType: TextInputType.emailAddress,
        autofillHints: const [AutofillHints.email],
        style: kMobileTextStyleSubtitle.copyWith(
          fontWeight: FontWeight.normal,
        ),
        onChanged: (_) => onChanged(),
      ),
    ],
  );
}
  Widget _buildInfoCard() {
    return Container(
      padding: EdgeInsets.all(kMobilePaddingMedium),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(kMobileBorderRadiusCard),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: AppColors.primary,
            size: 24,
          ),
          SizedBox(height: kMobileSizedBoxLarge),
          Text(
            'Having trouble?',
            style: kMobileTextStyleSubtitle.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: kMobileSizedBoxMedium),
          Text(
            'If you dont receive an email within a few minutes, check your spam folder or contact support.',
            style: kMobileTextStyleSubtitle.copyWith(
              color: AppColors.primary.withOpacity(0.8),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
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
          child: _isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 3,
                      ),
                      SizedBox(height: kMobileSizedBoxXLarge),
                      Text(
                        'Sending reset link...',
                        style: kMobileTextStyleSubtitle.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                      kMobilePaddingLarge,
                      _errorMessage != null ? 70 : 85,
                      kMobilePaddingLarge,
                      kMobilePaddingLarge,
                    ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: kMobileSizedBoxXXLarge),
                        // Illustration/Icon
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
                        Text(
                          'Forgot Password',
                          style: kMobileTextStyleTitle.copyWith(
                            color: AppColors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: kMobileSizedBoxLarge),
                        Text(
                          'Dont worry! Enter your email address below and well send you a link to reset your password.',
                          style: kMobileTextStyleSubtitle.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: kMobileSizedBoxHuge + kMobileSizedBoxMedium),
                        _buildEmailField(() {
                          final email = _emailController.text.trim();
                          // Hide custom error if any
                          if (_errorMessage != null) {
                            setState(() => _errorMessage = null);
                          }
                          // Hide validator error if email is now valid
                          if (_formKey.currentState != null) {
                            final isValid = emailValidator(email) == null;
                            if (isValid) {
                              // Revalidate the form to clear error
                              _formKey.currentState!.validate();
                            }
                          }
                        }),
                        SizedBox(height: kMobileSizedBoxXXLarge),
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
                          SizedBox(height: kMobileSizedBoxXXLarge),
                        ],
                        ElevatedButton(
                          onPressed: _sendReset,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.white,
                            padding: EdgeInsets.symmetric(vertical: kMobilePaddingSmall),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(kMobileBorderRadiusSmall),
                            ),
                          ),
                          child: Text(
                            'Reset Password',
                            style: kMobileTextStyleSubtitle.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(height: kMobileSizedBoxHuge),
                        _buildInfoCard(),
                        SizedBox(height: kMobileSizedBoxXXLarge),
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
                              onTap: () => Navigator.pop(context),
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