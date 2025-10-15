import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';
import 'package:pawsense/core/models/system/system_settings_model.dart';

class SecurityTab extends StatefulWidget {
  final SystemSettingsModel settings;
  final Function(SystemSettingsModel) onSettingsChanged;

  const SecurityTab({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
  });

  @override
  State<SecurityTab> createState() => _SecurityTabState();
}

class _SecurityTabState extends State<SecurityTab> {
  late TextEditingController _currentPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Change Password Section
        Text(
          'Change Password',
          style: kTextStyleLarge.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: kSpacingLarge),
        
        _buildPasswordField(
          'Current Password',
          _currentPasswordController,
          _obscureCurrentPassword,
          () => setState(() => _obscureCurrentPassword = !_obscureCurrentPassword),
        ),
        
        SizedBox(height: kSpacingLarge),
        
        _buildPasswordField(
          'New Password',
          _newPasswordController,
          _obscureNewPassword,
          () => setState(() => _obscureNewPassword = !_obscureNewPassword),
        ),
        
        SizedBox(height: kSpacingLarge),
        
        _buildPasswordField(
          'Confirm New Password',
          _confirmPasswordController,
          _obscureConfirmPassword,
          () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
        ),
        
        SizedBox(height: kSpacingXLarge),
        
        // Recent Security Events
        // Text(
        //   'Recent Security Events',
        //   style: kTextStyleLarge.copyWith(
        //     color: AppColors.textPrimary,
        //   ),
        // ),
        // SizedBox(height: kSpacingLarge),
        
        // // Fixed height container for security events
        // SizedBox(
        //   height: 300,
        //   child: ListView.separated(
        //     itemCount: widget.settings.recentSecurityEvents.length,
        //     separatorBuilder: (context, index) => SizedBox(height: kSpacingMedium),
        //     itemBuilder: (context, index) {
        //       final event = widget.settings.recentSecurityEvents[index];
        //       return _buildSecurityEvent(event);
        //     },
        //   ),
        // ),
        
        // SizedBox(height: kSpacingLarge),
        
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

  Widget _buildPasswordField(
    String label,
    TextEditingController controller,
    bool obscureText,
    VoidCallback toggleVisibility,
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
          obscureText: obscureText,
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
            suffixIcon: IconButton(
              icon: Icon(
                obscureText ? Icons.visibility_off : Icons.visibility,
                color: AppColors.textSecondary,
              ),
              onPressed: toggleVisibility,
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

  // Widget _buildSecurityEvent(SecurityEventModel event) {
  //   Color statusColor;
  //   switch (event.type) {
  //     case SecurityEventType.success:
  //       statusColor = AppColors.success;
  //       break;
  //     case SecurityEventType.warning:
  //       statusColor = AppColors.warning;
  //       break;
  //     case SecurityEventType.error:
  //       statusColor = AppColors.error;
  //       break;
  //     case SecurityEventType.info:
  //       statusColor = AppColors.info;
  //       break;
  //   }

  //   return Container(
  //     padding: EdgeInsets.all(kSpacingMedium),
  //     decoration: BoxDecoration(
  //       color: AppColors.white,
  //       borderRadius: BorderRadius.circular(kBorderRadius),
  //       border: Border.all(color: AppColors.border),
  //     ),
  //     child: Row(
  //       children: [
  //         Container(
  //           width: 8,
  //           height: 8,
  //           decoration: BoxDecoration(
  //             color: statusColor,
  //             shape: BoxShape.circle,
  //           ),
  //         ),
  //         SizedBox(width: kSpacingMedium),
  //         Expanded(
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Text(
  //                 event.title,
  //                 style: kTextStyleRegular.copyWith(
  //                   color: AppColors.textPrimary,
  //                   fontWeight: FontWeight.w500,
  //                 ),
  //               ),
  //               if (event.description.isNotEmpty) ...[
  //                 SizedBox(height: kSpacingSmall / 2),
  //                 Text(
  //                   event.description,
  //                   style: kTextStyleSmall.copyWith(
  //                     color: AppColors.textSecondary,
  //                   ),
  //                 ),
  //               ],
  //             ],
  //           ),
  //         ),
  //         Text(
  //           event.timeAgo,
  //           style: kTextStyleSmall.copyWith(
  //             color: AppColors.textSecondary,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  void _saveChanges() {
    // Add save logic here
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Security settings updated successfully'),
        backgroundColor: AppColors.success,
      ),
    );
  }
}
