import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/constants.dart';
import '../../../utils/validators.dart';
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

  bool _isLoading = true;
  bool _isSaving = false;

  // Field errors tracking for real-time validation
  final Map<String, String?> _fieldErrors = {
    'firstName': null,
    'lastName': null,
    'email': null,
    'phone': null,
  };

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

  /// Validate individual field
  String? _validateField(String fieldKey, String value) {
    switch (fieldKey) {
      case 'firstName':
        return nameValidator(value.trim(), 'First name');
      case 'lastName':
        return nameValidator(value.trim(), 'Last name');
      case 'email':
        return emailValidator(value.trim());
      case 'phone':
        return phoneValidator(value.trim());
      default:
        return null;
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

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
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
                  errorText: _fieldErrors['firstName'],
                  onChanged: (value) {
                    setState(() {
                      _fieldErrors['firstName'] = _validateField('firstName', value);
                    });
                  },
                ),
              ),
              SizedBox(width: kSpacingLarge),
              Expanded(
                child: SettingsFormField(
                  label: 'Last Name',
                  controller: _lastNameController,
                  errorText: _fieldErrors['lastName'],
                  onChanged: (value) {
                    setState(() {
                      _fieldErrors['lastName'] = _validateField('lastName', value);
                    });
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: kSpacingLarge),
          
          SettingsFormField(
            label: 'Email Address',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            errorText: _fieldErrors['email'],
            onChanged: (value) {
              setState(() {
                _fieldErrors['email'] = _validateField('email', value);
              });
            },
          ),
          SizedBox(height: kSpacingLarge),
          
          SettingsFormField(
            label: 'Phone Number',
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            errorText: _fieldErrors['phone'],
            onChanged: (value) {
              setState(() {
                _fieldErrors['phone'] = _validateField('phone', value);
              });
            },
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
        ],
      ),
    );
  }
}
