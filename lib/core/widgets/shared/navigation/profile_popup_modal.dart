import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/constants.dart';

class ProfilePopupModal extends StatelessWidget {
  final String userInitials;
  final String userName;
  final String userRole;
  final VoidCallback? onViewProfile;
  final VoidCallback? onSettings;
  final VoidCallback? onToggleDarkMode;
  final VoidCallback? onHelpSupport;
  final VoidCallback? onSignOut;
  final bool isDarkMode;

  const ProfilePopupModal({
    super.key,
    required this.userInitials,
    required this.userName,
    required this.userRole,
    this.onViewProfile,
    this.onSettings,
    this.onToggleDarkMode,
    this.onHelpSupport,
    this.onSignOut,
    this.isDarkMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: AppColors.white, 
        borderRadius: BorderRadius.circular(kBorderRadius),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(kShadowOpacity * 4),
            blurRadius: kShadowBlurRadius * 1.5,
            offset: const Offset(0, 4),
            spreadRadius: kShadowSpreadRadius,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Section
          Container(
            color: AppColors.background,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(kSpacingMedium, kSpacingLarge, kSpacingMedium, kSpacingSmall),
              child: Column(
                children: [
                  // Large Avatar
                  CircleAvatar(
                    radius: kSpacingLarge,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      userInitials,
                      style: kTextStyleLarge.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: kSpacingSmall),
                  // User Name
                  Text(
                    userName,
                    style: kTextStyleRegular.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: kSpacingSmall / 2),
                  // User Role
                  Text(
                    userRole,
                    style: kTextStyleSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: kSpacingSmall),
                  // Online Status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: kSpacingSmall,
                        height: kSpacingSmall,
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          borderRadius: BorderRadius.circular(kSpacingSmall / 2),
                        ),
                      ),
                      const SizedBox(width: kSpacingSmall),
                      Text(
                        'Online',
                        style: kTextStyleRegular.copyWith(
                          fontSize: kFontSizeSmall-2,
                          color: AppColors.success,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: kSpacingSmall),
          // Menu Items
          Padding(
            padding: const EdgeInsets.only(bottom: kSpacingMedium),
            child: Column(
              children: [
                _buildMenuItem(
                  icon: Icons.person_outline,
                  title: 'View Profile',
                  onTap: onViewProfile ?? () {
                    Navigator.of(context).pop();
                  },
                ),
                _buildMenuItem(
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  onTap: onSettings ?? () {
                    Navigator.of(context).pop();
                    context.go('/admin/settings');
                  },
                ),
                _buildMenuItem(
                  icon: isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                  title: 'Dark Mode',
                  onTap: onToggleDarkMode ?? () {
                    Navigator.of(context).pop();
                  },
                ),
                _buildMenuItem(
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  onTap: onHelpSupport ?? () {
                    Navigator.of(context).pop();
                    context.go('/admin/support');
                  },
                ),
                // Divider
                Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(vertical: kSpacingSmall),
                  color: AppColors.border,
                ),
                _buildMenuItem(
                  icon: Icons.logout_outlined,
                  title: 'Sign Out',
                  onTap: onSignOut ?? () {
                    Navigator.of(context).pop();
                    context.go('/web_login');
                  },
                  isDestructive: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(kBorderRadiusSmall),
        splashColor: isDestructive 
            ? AppColors.error.withOpacity(0.1) 
            : AppColors.primary.withOpacity(0.1),
        highlightColor: isDestructive 
            ? AppColors.error.withOpacity(0.05) 
            : AppColors.primary.withOpacity(0.05),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: kSpacingMedium,
            vertical: kSpacingSmall 
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: kIconSizeMedium,
                color: isDestructive 
                    ? AppColors.error
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: kSpacingSmall),
              Text(
                title,
                style: kTextStyleRegular.copyWith(
                  fontWeight: FontWeight.w500,
                  color: isDestructive 
                      ? AppColors.error
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}