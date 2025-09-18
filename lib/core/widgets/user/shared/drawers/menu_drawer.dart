import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';
import 'package:pawsense/core/models/user/user_model.dart';
import 'package:pawsense/core/widgets/shared/profile_avatar.dart';
import 'package:pawsense/core/services/auth/auth_service_mobile.dart';

class MenuDrawer extends StatelessWidget {
  final UserModel? user;
  final VoidCallback? onClose;

  const MenuDrawer({
    super.key,
    this.user,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Header with user info
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.border.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // User avatar
                  ProfileAvatar(
                    user: user,
                    size: 50,
                  ),
                  const SizedBox(width: 12),
                  // User info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user != null 
                              ? '${user!.firstName ?? ''} ${user!.lastName ?? ''}'.trim()
                              : 'Guest User',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.email ?? 'No email',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Close button
                  IconButton(
                    onPressed: onClose ?? () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            
            // Menu items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildMenuItem(
                    icon: Icons.home_outlined,
                    title: 'Home',
                    onTap: () {
                      Navigator.pop(context);
                      // Navigate to home
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.pets_outlined,
                    title: 'My Pets',
                    onTap: () {
                      Navigator.pop(context);
                      // Navigate to pets
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.calendar_today_outlined,
                    title: 'Appointments',
                    onTap: () {
                      Navigator.pop(context);
                      // Navigate to appointments
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.medical_services_outlined,
                    title: 'Health Records',
                    onTap: () {
                      Navigator.pop(context);
                      // Navigate to health records
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.local_hospital_outlined,
                    title: 'Find Clinics',
                    onTap: () {
                      Navigator.pop(context);
                      // Navigate to clinic finder
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.camera_alt_outlined,
                    title: 'Skin Analysis',
                    onTap: () {
                      Navigator.pop(context);
                      // Navigate to skin analysis
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.message_outlined,
                    title: 'Messages',
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/messaging');
                    },
                  ),
                  
                  // Divider
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Divider(
                      color: AppColors.border.withValues(alpha: 0.2),
                      thickness: 1,
                    ),
                  ),
                  
                  _buildMenuItem(
                    icon: Icons.notifications_outlined,
                    title: 'Notifications',
                    onTap: () {
                      Navigator.pop(context);
                      // Navigate to notifications
                    },
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        '3',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  _buildMenuItem(
                    icon: Icons.help_outline,
                    title: 'Help & Support',
                    onTap: () {
                      Navigator.pop(context);
                      // Navigate to help
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    onTap: () {
                      Navigator.pop(context);
                      // Navigate to settings
                    },
                  ),
                ],
              ),
            ),
            
            // Footer
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: AppColors.border.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  _buildMenuItem(
                    icon: Icons.logout_outlined,
                    title: 'Sign Out',
                    titleColor: AppColors.error,
                    iconColor: AppColors.error,
                    onTap: () async {
                      Navigator.pop(context);
                      // Handle sign out
                      try {
                        final authService = AuthService();
                        await authService.signOut();
                        if (context.mounted) {
                          context.go('/signin');
                        }
                      } catch (e) {
                        // Handle sign out error - still navigate to signin
                        if (context.mounted) {
                          context.go('/signin');
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'PawSense v1.0.0',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Widget? trailing,
    Color? titleColor,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: iconColor ?? AppColors.textSecondary,
        size: 22,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: kFontSizeRegular,
          fontWeight: FontWeight.w500,
          color: titleColor ?? AppColors.textPrimary,
        ),
      ),
      trailing: trailing,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      visualDensity: VisualDensity.compact,
    );
  }
}
