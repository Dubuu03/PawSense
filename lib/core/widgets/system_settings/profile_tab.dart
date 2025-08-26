import 'package:flutter/material.dart';
import '../../../core/utils/app_colors.dart';
import '../../../core/utils/constants.dart';
import '../../../core/models/system/system_settings_model.dart';

class ProfileTab extends StatefulWidget {
  final SystemSettingsModel settings;
  final Function(SystemSettingsModel) onSettingsChanged;

  const ProfileTab({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
  });

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.settings.firstName);
    _lastNameController = TextEditingController(text: widget.settings.lastName);
    _emailController = TextEditingController(text: widget.settings.email);
    _phoneController = TextEditingController(text: widget.settings.phoneNumber);
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Profile Information',
          style: kTextStyleLarge.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: kSpacingLarge),
        
        // User Avatar and Info
        Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(40),
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Text(
                  '${widget.settings.firstName[0]}${widget.settings.lastName[0]}',
                  style: kTextStyleLarge.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
              ),
            ),
            SizedBox(width: kSpacingLarge),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.settings.firstName} ${widget.settings.lastName}',
                  style: kTextStyleTitle.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: kSpacingSmall / 2),
                Text(
                  widget.settings.role,
                  style: kTextStyleRegular.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: kSpacingSmall),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: kSpacingMedium,
                    vertical: kSpacingSmall / 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.roleSuperAdminBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'System Administration',
                    style: kTextStyleSmall.copyWith(
                      color: AppColors.roleSuperAdmin,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        
        SizedBox(height: kSpacingXLarge),
        
        // Form Fields
        Row(
          children: [
            Expanded(
              child: _buildFormField(
                'First Name',
                _firstNameController,
                (value) => _updateSettings(firstName: value),
              ),
            ),
            SizedBox(width: kSpacingLarge),
            Expanded(
              child: _buildFormField(
                'Last Name',
                _lastNameController,
                (value) => _updateSettings(lastName: value),
              ),
            ),
          ],
        ),
        
        SizedBox(height: kSpacingLarge),
        
        Row(
          children: [
            Expanded(
              child: _buildFormField(
                'Email Address',
                _emailController,
                (value) => _updateSettings(email: value),
              ),
            ),
            SizedBox(width: kSpacingLarge),
            Expanded(
              child: _buildFormField(
                'Phone Number',
                _phoneController,
                (value) => _updateSettings(phoneNumber: value),
              ),
            ),
          ],
        ),
        
        SizedBox(height: kSpacingXLarge),
        
        // Save Button
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton.icon(
              onPressed: _saveChanges,
              icon: Icon(Icons.save, size: kIconSizeMedium),
              label: Text('Save Changes'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: kSpacingLarge,
                  vertical: kSpacingMedium,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(kBorderRadius),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFormField(
    String label,
    TextEditingController controller,
    Function(String) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: kTextStyleRegular.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: kSpacingSmall),
        TextFormField(
          controller: controller,
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(kBorderRadius),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(kBorderRadius),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(kBorderRadius),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: kSpacingMedium,
              vertical: kSpacingMedium,
            ),
            filled: true,
            fillColor: AppColors.white,
          ),
          style: kTextStyleRegular.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  void _updateSettings({
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
  }) {
    widget.onSettingsChanged(
      widget.settings.copyWith(
        firstName: firstName,
        lastName: lastName,
        email: email,
        phoneNumber: phoneNumber,
      ),
    );
  }

  void _saveChanges() {
    // Add save logic here
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Profile updated successfully'),
        backgroundColor: AppColors.success,
      ),
    );
  }
}
