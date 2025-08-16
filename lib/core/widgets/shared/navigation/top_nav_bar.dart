import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/constants.dart';

class TopNavBar extends StatelessWidget {
  final String clinicTitle;
  final String userInitials;
  final String userName;
  final String userRole;
  final bool hasNotifications;
  final VoidCallback? onProfileTap; // callback when clicking name + avatar

  const TopNavBar({
    super.key,
    this.clinicTitle = 'Veterinary Clinic Dashboard',
    this.userInitials = 'SJ',
    this.userName = 'Dr. Sarah Johnson',
    this.userRole = 'Veterinarian',
    this.hasNotifications = true,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,            
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left: Clinic title
          Text(
            clinicTitle,
            style: TextStyle(
              fontSize: kFontSizeLarge,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),

          // Notification button
          _buildNotificationButton(),
          const SizedBox(width: 24),

          // User info group (clickable)
          InkWell(
            borderRadius: BorderRadius.circular(40),
            onTap: onProfileTap ?? () {
              debugPrint("Profile clicked!");
            },
            child: Row(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      userName,
                      style: TextStyle(
                        fontSize: kFontSizeRegular-2,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      userRole,
                      style: TextStyle(
                        fontSize: kFontSizeSmall,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    userInitials,
                    style: TextStyle(color: AppColors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationButton() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          Center(
            child: Icon(
              Icons.notifications_outlined,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ),
          if (hasNotifications)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
