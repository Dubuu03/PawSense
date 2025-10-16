import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/constants.dart';
import '../../../services/shared/settings_service.dart';
import 'settings_form_field.dart';

class SecuritySettings extends StatefulWidget {
  const SecuritySettings({super.key});

  @override
  State<SecuritySettings> createState() => _SecuritySettingsState();
}

class _SecuritySettingsState extends State<SecuritySettings> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isChangingPassword = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Get password requirements status
  Map<String, bool> _getPasswordRequirements(String password, String currentPassword) {
    return {
      'lowercase': RegExp(r'[a-z]').hasMatch(password),
      'uppercase': RegExp(r'[A-Z]').hasMatch(password),
      'number': RegExp(r'[0-9]').hasMatch(password),
      'minLength': password.length >= 8,
      'differentFromCurrent': password.isNotEmpty && password != currentPassword,
    };
  }

  Future<void> _changePassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('New passwords do not match'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Check password requirements
    final requirements = _getPasswordRequirements(
      _newPasswordController.text,
      _currentPasswordController.text,
    );
    final allMet = requirements.values.every((met) => met);
    
    if (!allMet) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password does not meet all requirements'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isChangingPassword = true;
    });

    try {
      final success = await SettingsService.updatePassword(
        _currentPasswordController.text,
        _newPasswordController.text,
      );

      if (success && mounted) {
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password updated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update password'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating password: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isChangingPassword = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Security Settings',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: kSpacingLarge),
          
          // Password Change Section
          Text(
            'Change Password',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: kSpacingMedium),
          
          Text(
            'Update your password to keep your account secure',
            style: TextStyle(
              fontSize: kFontSizeSmall,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: kSpacingLarge),
          
          SettingsFormField(
            label: 'Current Password',
            controller: _currentPasswordController,
            isPassword: true,
            onChanged: (value) {
              setState(() {}); // Trigger rebuild to check "different from current"
            },
          ),
          SizedBox(height: kSpacingLarge),
          
          SettingsFormField(
            label: 'New Password',
            controller: _newPasswordController,
            isPassword: true,
            onChanged: (value) {
              setState(() {}); // Trigger rebuild to update checklist
            },
          ),
          SizedBox(height: kSpacingLarge),
          
          SettingsFormField(
            label: 'Confirm New Password',
            controller: _confirmPasswordController,
            isPassword: true,
          ),
          SizedBox(height: kSpacingLarge),

          // Password Requirements (Dynamic)
          if (_newPasswordController.text.isNotEmpty)
            Container(
              padding: EdgeInsets.all(kSpacingMedium),
              margin: EdgeInsets.only(bottom: kSpacingLarge),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                border: Border.all(color: AppColors.border.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Password Requirements',
                        style: TextStyle(
                          fontSize: kFontSizeSmall,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  _buildDynamicRequirement(
                    'A lowercase letter',
                    _getPasswordRequirements(
                      _newPasswordController.text,
                      _currentPasswordController.text,
                    )['lowercase']!,
                  ),
                  _buildDynamicRequirement(
                    'A capital (uppercase) letter',
                    _getPasswordRequirements(
                      _newPasswordController.text,
                      _currentPasswordController.text,
                    )['uppercase']!,
                  ),
                  _buildDynamicRequirement(
                    'A number',
                    _getPasswordRequirements(
                      _newPasswordController.text,
                      _currentPasswordController.text,
                    )['number']!,
                  ),
                  _buildDynamicRequirement(
                    'Minimum 8 characters',
                    _getPasswordRequirements(
                      _newPasswordController.text,
                      _currentPasswordController.text,
                    )['minLength']!,
                  ),
                  _buildDynamicRequirement(
                    'Different from your current password',
                    _getPasswordRequirements(
                      _newPasswordController.text,
                      _currentPasswordController.text,
                    )['differentFromCurrent']!,
                  ),
                ],
              ),
            ),

          // Change Password Button
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _isChangingPassword ? null : _changePassword,
              icon: _isChangingPassword
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(Icons.lock_reset, size: 18),
              label: Text(_isChangingPassword ? 'Changing Password...' : 'Change Password'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicRequirement(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
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
              style: TextStyle(
                fontSize: kFontSizeSmall,
                color: isMet ? Colors.green : Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
