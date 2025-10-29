import 'package:flutter/material.dart';
import 'package:pawsense/core/models/system/system_settings_model.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';
import 'package:pawsense/core/guards/auth_guard.dart';
import 'package:pawsense/core/models/user/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


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
  
  UserModel? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _loadCurrentUser();
  }
  
  Future<void> _loadCurrentUser() async {
    try {
      final user = await AuthGuard.getCurrentUser();
      if (user != null && mounted) {
        setState(() {
          _currentUser = user;
          _firstNameController.text = user.firstName ?? '';
          _lastNameController.text = user.lastName ?? '';
          _emailController.text = user.email;
          _phoneController.text = user.contactNumber ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading current user: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
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
    
    if (_currentUser == null) {
      return Center(
        child: Text(
          'Failed to load user profile',
          style: kTextStyleRegular.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      );
    }
    
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
                  '${(_currentUser!.firstName?.isNotEmpty == true ? _currentUser!.firstName![0] : _currentUser!.username[0]).toUpperCase()}${(_currentUser!.lastName?.isNotEmpty == true ? _currentUser!.lastName![0] : _currentUser!.username.length > 1 ? _currentUser!.username[1] : '').toUpperCase()}',
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
                  '${_currentUser!.firstName ?? _currentUser!.username} ${_currentUser!.lastName ?? ''}',
                  style: kTextStyleTitle.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: kSpacingSmall / 2),
                Text(
                  _currentUser!.role.replaceAll('_', ' ').split(' ').map((word) => word[0].toUpperCase() + word.substring(1)).join(' '),
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
        
        SizedBox(height: kSpacingLarge),
        
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
    // Update local state only - actual save happens on Save button click
  }

  Future<void> _saveChanges() async {
    if (_currentUser == null) return;
    
    try {
      // Update user in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .update({
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'contactNumber': _phoneController.text.trim(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
      
      // Reload user data
      await _loadCurrentUser();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      print('Error saving profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
