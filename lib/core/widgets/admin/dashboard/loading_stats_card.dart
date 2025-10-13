import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/constants.dart';

class LoadingStatsCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;

  const LoadingStatsCard({
    super.key,
    required this.title,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(kSpacingLarge),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(kBorderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(kShadowOpacity),
            blurRadius: kShadowBlurRadius,
            offset: kShadowOffset,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: kTextStyleRegular.copyWith(
                  fontSize: kFontSizeRegular - 2,
                  color: AppColors.textSecondary,
                ),
              ),
              Icon(icon, color: iconColor, size: kIconSizeMedium),
            ],
          ),
          SizedBox(height: kSpacingMedium),
          // Show initial value as 0
          Text(
            '0',
            style: kTextStyleHeader.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: kSpacingSmall),
          // Hide change indicator until data is loaded
          SizedBox(height: 16),
        ],
      ),
    );
  }
}
