import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';

class LeftSidebar extends StatelessWidget {
  final VoidCallback? onClose;

  const LeftSidebar({
    super.key,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      height: MediaQuery.of(context).size.height,
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(5, 0),
            spreadRadius: 0,
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 20, 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.08),
                    AppColors.primary.withValues(alpha: 0.03),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  // PawSense Logo
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.pets,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Title and subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PawSense',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Quick Access Menu',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Close Button
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      onPressed: onClose ?? () {},
                      icon: const Icon(
                        Icons.close,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ],
              ),
            ),

            // Main Menu Section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section Title
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 16, 8, 12),
                      child: Text(
                        'Quick Services',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),

                    // Menu Items
                    _buildMenuItem(
                      icon: Icons.chat_bubble_outline_rounded,
                      title: 'Chat Support',
                      subtitle: 'Get instant help and support',
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF4A90E2).withValues(alpha: 0.1),
                          const Color(0xFF4A90E2).withValues(alpha: 0.05),
                        ],
                      ),
                      iconColor: const Color(0xFF4A90E2),
                      onTap: () {
                        onClose?.call();
                        // Navigate to chat support
                      },
                    ),

                    const SizedBox(height: 12),

                    _buildMenuItem(
                      icon: Icons.medical_information_outlined,
                      title: 'Skin Disease Info',
                      subtitle: 'Learn about skin conditions',
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF8E44AD).withValues(alpha: 0.1),
                          const Color(0xFF8E44AD).withValues(alpha: 0.05),
                        ],
                      ),
                      iconColor: const Color(0xFF8E44AD),
                      onTap: () {
                        onClose?.call();
                        // Navigate to skin disease info
                      },
                    ),

                    const SizedBox(height: 12),

                    _buildMenuItem(
                      icon: Icons.lightbulb_outline_rounded,
                      title: 'Pet Care Tips',
                      subtitle: 'Expert advice for your pets',
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFFF9500).withValues(alpha: 0.1),
                          const Color(0xFFFF9500).withValues(alpha: 0.05),
                        ],
                      ),
                      iconColor: const Color(0xFFFF9500),
                      onTap: () {
                        onClose?.call();
                        // Navigate to pet care tips
                      },
                    ),

                    // Divider
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 24),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 1,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    AppColors.border.withValues(alpha: 0.3),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Additional Info Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primary.withValues(alpha: 0.06),
                            AppColors.primary.withValues(alpha: 0.02),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Need Help?',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Access our comprehensive support resources and get instant answers to your pet care questions.',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: AppColors.border.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite,
                    color: AppColors.primary,
                    size: 14,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Made with love for your pets',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textTertiary,
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
    required String subtitle,
    required LinearGradient gradient,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: iconColor.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Icon Container
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: kFontSizeRegular,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Arrow Icon
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: iconColor.withValues(alpha: 0.6),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
