import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';
import 'package:pawsense/core/utils/constants.dart';
import 'package:pawsense/core/services/auth/auth_service_mobile.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  // Controllers
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final Map<String, String?> _fieldErrors = {
    'currentPassword': null,
    'newPassword': null,
    'confirmPassword': null,
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
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  String? _validateField(String keyName, String value) {
    switch (keyName) {
      case 'currentPassword':
        if (value.trim().isEmpty) {
          return 'Current password is required';
        }
        return null;
      case 'newPassword':
        if (value.trim().isEmpty) {
          return 'New password is required';
        }
        // Check if new password is same as current password
        if (_currentPasswordController.text.trim().isNotEmpty &&
            value.trim() == _currentPasswordController.text.trim()) {
          return 'New password must be different from current password';
        }
        // Check all requirements
        final requirements = _getPasswordRequirements(value);
        final allRequirementsMet = requirements.values.every((met) => met);
        if (!allRequirementsMet) {
          return 'Password does not meet requirements';
        }
        // Also validate confirm password when new password changes
        if (_confirmPasswordController.text.isNotEmpty) {
          _fieldErrors['confirmPassword'] = _validateConfirmPassword(
            _confirmPasswordController.text.trim(),
            value.trim(),
          );
        }
        return null;
      case 'confirmPassword':
        return _validateConfirmPassword(
          value.trim(),
          _newPasswordController.text.trim(),
        );
      default:
        return null;
    }
  }

  String? _validateConfirmPassword(String confirmPassword, String newPassword) {
    if (confirmPassword.isEmpty) {
      return 'Confirm password is required';
    }
    if (confirmPassword != newPassword) {
      return 'Passwords do not match';
    }
    return null;
  }

  Map<String, bool> _getPasswordRequirements(String password) {
    return {
      'lowercase': RegExp(r'[a-z]').hasMatch(password),
      'uppercase': RegExp(r'[A-Z]').hasMatch(password),
      'number': RegExp(r'[0-9]').hasMatch(password),
      'minLength': password.length >= 8,
      'notSameAsCurrent': _currentPasswordController.text.trim().isEmpty ||
          password != _currentPasswordController.text.trim(),
    };
  }

  Widget _buildPasswordRequirements() {
    final password = _newPasswordController.text;
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
          SizedBox(height: 4),
          _buildRequirementItem(
              'Different from current password', requirements['notSameAsCurrent']!),
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
        Expanded(
          child: Text(
            text,
            style: kTextStyleSmall.copyWith(
              color: isMet ? Colors.green : Colors.red,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleChangePassword() async {
    // Close any existing snackbar to prevent stacking
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    setState(() {
      _fieldErrors.updateAll((key, value) => null);
    });

    bool hasError = false;
    List<String> errorMessages = [];

    // Validate current password
    String? currentPasswordError = _validateField(
        'currentPassword', _currentPasswordController.text.trim());
    if (currentPasswordError != null) {
      _fieldErrors['currentPassword'] = currentPasswordError;
      errorMessages.add(currentPasswordError);
      hasError = true;
    }

    // Validate new password
    final newPasswordValue = _newPasswordController.text.trim();
    final passwordRequirements = _getPasswordRequirements(newPasswordValue);
    final allRequirementsMet = passwordRequirements.values.every((met) => met);

    if (newPasswordValue.isEmpty) {
      _fieldErrors['newPassword'] = 'New password is required';
      errorMessages.add('New password is required');
      hasError = true;
    } else if (newPasswordValue == _currentPasswordController.text.trim()) {
      _fieldErrors['newPassword'] =
          'New password must be different from current password';
      errorMessages.add('New password must be different from current password');
      hasError = true;
    } else if (!allRequirementsMet) {
      _fieldErrors['newPassword'] = 'Password does not meet requirements';
      errorMessages.add('Password does not meet requirements');
      hasError = true;
    } else {
      _fieldErrors['newPassword'] = null;
    }

    // Validate confirm password
    String? confirmPasswordError = _validateConfirmPassword(
      _confirmPasswordController.text.trim(),
      _newPasswordController.text.trim(),
    );
    if (confirmPasswordError != null) {
      _fieldErrors['confirmPassword'] = confirmPasswordError;
      errorMessages.add(confirmPasswordError);
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

        if (_currentPasswordController.text.trim().isEmpty &&
            _fieldErrors['currentPassword'] != null) hasEmptyFields = true;
        if (_newPasswordController.text.trim().isEmpty &&
            _fieldErrors['newPassword'] != null) hasEmptyFields = true;
        if (_confirmPasswordController.text.trim().isEmpty &&
            _fieldErrors['confirmPassword'] != null) hasEmptyFields = true;

        if (!hasEmptyFields) {
          // Only check for invalid inputs if no empty fields
          if (_currentPasswordController.text.trim().isNotEmpty &&
              _fieldErrors['currentPassword'] != null) hasInvalidInputs = true;
          if (_newPasswordController.text.trim().isNotEmpty &&
              _fieldErrors['newPassword'] != null) hasInvalidInputs = true;
          if (_confirmPasswordController.text.trim().isNotEmpty &&
              _fieldErrors['confirmPassword'] != null) hasInvalidInputs = true;
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
                  maxLines: 2,
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

      setState(() {}); // Trigger UI update to show field errors
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Change password using auth service
      await _authService.changePassword(
        currentPassword: _currentPasswordController.text.trim(),
        newPassword: _newPasswordController.text.trim(),
      );

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Password changed successfully!',
                    style: const TextStyle(
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

        // Navigate back after a short delay
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            context.pop();
          }
        });
      }
    } catch (e) {
      String errorMessage = 'Failed to change password';
      
      // Handle specific error cases
      if (e.toString().contains('wrong-password') || 
          e.toString().contains('invalid-credential')) {
        errorMessage = 'Current password is incorrect';
        _fieldErrors['currentPassword'] = 'Current password is incorrect';
      } else if (e.toString().contains('requires-recent-login')) {
        errorMessage = 'Please sign in again to change your password';
      }

      if (mounted) {
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
                    errorMessage,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      height: 1.2,
                    ),
                    maxLines: 2,
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
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgsecond,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Change Password',
          style: kMobileTextStyleTitle.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: kSpacingLarge),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // Info card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColors.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Choose a strong password to keep your account secure',
                              style: kTextStyleSmall.copyWith(
                                color: AppColors.textPrimary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Current Password
                    _buildPasswordField(
                      keyName: 'currentPassword',
                      controller: _currentPasswordController,
                      label: 'Current Password',
                      obscureText: _obscureCurrentPassword,
                      onToggleVisibility: () {
                        setState(() {
                          _obscureCurrentPassword = !_obscureCurrentPassword;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    // New Password
                    _buildPasswordField(
                      keyName: 'newPassword',
                      controller: _newPasswordController,
                      label: 'New Password',
                      obscureText: _obscureNewPassword,
                      onToggleVisibility: () {
                        setState(() {
                          _obscureNewPassword = !_obscureNewPassword;
                        });
                      },
                    ),

                    // Password requirements
                    _buildPasswordRequirements(),

                    const SizedBox(height: 16),

                    // Confirm Password
                    _buildPasswordField(
                      keyName: 'confirmPassword',
                      controller: _confirmPasswordController,
                      label: 'Confirm New Password',
                      obscureText: _obscureConfirmPassword,
                      onToggleVisibility: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),

                    const SizedBox(height: 40),

                    // Change Password Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(kButtonRadius),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          elevation: 2,
                          shadowColor: Colors.black.withOpacity(0.1),
                          disabledBackgroundColor:
                              AppColors.primary.withOpacity(0.6),
                        ),
                        onPressed: _isLoading ? null : _handleChangePassword,
                        child: _isLoading
                            ? const SizedBox(
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
                                'Change Password',
                                style: kTextStyleRegular.copyWith(
                                  fontSize: 14,
                                  color: AppColors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required String keyName,
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
  }) {
    return Container(
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
        obscureText: obscureText,
        maxLength: 128,
        inputFormatters: [
          LengthLimitingTextInputFormatter(128),
        ],
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
              color: _fieldErrors[keyName] != null
                  ? AppColors.error
                  : AppColors.border,
              width: _fieldErrors[keyName] != null ? 1.5 : 0.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: _fieldErrors[keyName] != null
                  ? AppColors.error
                  : AppColors.primary,
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
          suffixIcon: IconButton(
            onPressed: onToggleVisibility,
            icon: Icon(
              obscureText
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ),
          suffixIconConstraints: BoxConstraints(
              minWidth: 48, maxWidth: 48, minHeight: 32, maxHeight: 32),
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
