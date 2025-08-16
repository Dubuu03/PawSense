import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import 'settings_form_field.dart';

class AccountSettings extends StatefulWidget {
  const AccountSettings({Key? key}) : super(key: key);

  @override
  State<AccountSettings> createState() => _AccountSettingsState();
}

class _AccountSettingsState extends State<AccountSettings> {
  final _firstNameController = TextEditingController(text: 'Sarah');
  final _lastNameController = TextEditingController(text: 'Johnson');
  final _emailController = TextEditingController(text: 'dr.sarah@pawsense.com');
  final _phoneController = TextEditingController(text: '+1 (555) 123-4567');
  final _emergencyController = TextEditingController(text: '+1 (555) 987-6543');
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _emergencyController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          
          SettingsFormField(
            label: 'Emergency Contact',
            controller: _emergencyController,
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
        ],
      ),
    );
  }
}
