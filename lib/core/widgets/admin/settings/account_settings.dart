import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/constants.dart';
import '../../../services/shared/settings_service.dart';
import 'settings_form_field.dart';

class AccountSettings extends StatefulWidget {
  const AccountSettings({super.key});

  @override
  State<AccountSettings> createState() => _AccountSettingsState();
}

class _AccountSettingsState extends State<AccountSettings> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadAccountData();
  }

  Future<void> _loadAccountData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final accountData = await SettingsService.getAccountSettings();
      
      if (accountData != null && mounted) {
        setState(() {
          _firstNameController.text = accountData['firstName'] ?? '';
          _lastNameController.text = accountData['lastName'] ?? '';
          _emailController.text = accountData['email'] ?? '';
          _phoneController.text = accountData['contactNumber'] ?? '';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading account data: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveAccountSettings() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final success = await SettingsService.updateAccountSettings({
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'username': '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
        'contactNumber': _phoneController.text.trim(),
      });

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Account settings saved successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save account settings'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving account settings: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
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

    if (_newPasswordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password must be at least 6 characters'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

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
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Settings',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: kSpacingLarge),
          
          // Personal Information
          Row(
            children: [
              Expanded(
                child: SettingsFormField(
                  label: 'First Name',
                  controller: _firstNameController,
                ),
              ),
              SizedBox(width: kSpacingLarge),
              Expanded(
                child: SettingsFormField(
                  label: 'Last Name',
                  controller: _lastNameController,
                ),
              ),
            ],
          ),
          SizedBox(height: kSpacingLarge),
          
          SettingsFormField(
            label: 'Email Address',
            controller: _emailController,
          ),
          SizedBox(height: kSpacingLarge),
          
          SettingsFormField(
            label: 'Phone Number',
            controller: _phoneController,
          ),
          SizedBox(height: kSpacingLarge),

          // Save Account Settings Button
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveAccountSettings,
              icon: _isSaving
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(Icons.save_outlined, size: 18),
              label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
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
          SizedBox(height: kSpacingLarge * 2),
          
          // Password Change Section
          Text(
            'Change Password',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: kSpacingLarge),
          
          SettingsFormField(
            label: 'Current Password',
            controller: _currentPasswordController,
            isPassword: true,
          ),
          SizedBox(height: kSpacingLarge),
          
          SettingsFormField(
            label: 'New Password',
            controller: _newPasswordController,
            isPassword: true,
          ),
          SizedBox(height: kSpacingLarge),
          
          SettingsFormField(
            label: 'Confirm New Password',
            controller: _confirmPasswordController,
            isPassword: true,
          ),
          SizedBox(height: kSpacingLarge),

          // Change Password Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _changePassword(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.info,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Change Password',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
