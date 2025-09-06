import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';

class AlertEmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const AlertEmptyState({
    super.key,
    this.title = 'No alerts',
    this.subtitle = 'You\'re all caught up! No new notifications.',
    this.icon = Icons.notifications_none,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: kMobileMarginCard,
      padding: const EdgeInsets.all(kMobilePaddingLarge * 2),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: kMobileBorderRadiusCardPreset,
        boxShadow: kMobileCardShadowSmall,
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(
              icon,
              size: 40,
              color: AppColors.primary.withValues(alpha: 0.6),
            ),
          ),
          
          const SizedBox(height: kMobileSizedBoxXLarge),
          
          Text(
            title,
            style: kMobileTextStyleTitle.copyWith(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const SizedBox(height: kMobileSizedBoxMedium),
          
          Text(
            subtitle,
            style: kMobileTextStyleSubtitle.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
