import 'package:flutter/material.dart';
import 'package:pawsense/core/models/user/user_model.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/widgets/shared/profile_avatar.dart';

class SimpleUserAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onMenuTap;
  final VoidCallback? onProfileTap;
  final UserModel? user;

  const SimpleUserAppBar({
    super.key,
    this.onMenuTap,
    this.onProfileTap,
    this.user,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          // Hamburger menu
          IconButton(
            onPressed: onMenuTap ?? () {},
            icon: const Icon(
              Icons.menu,
              color: AppColors.textPrimary,
              size: 24,
            ),
          ),
          const SizedBox(width: 8), 
          // PawSense logo and text
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Paw icon replaced with logo
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.asset(
                      'assets/img/logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.pets,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // PawSense text
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'PawSense',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        height: 1.0,
                      ),
                    ),
                    const Text(
                      'AI-powered pet skin care',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Profile avatar
          GestureDetector(
            onTap: onProfileTap ?? () {},
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              child: ProfileAvatar(
                user: user,
                size: 32,
              ),
            ),
          ),
        ],
      ),
    );
  }
}