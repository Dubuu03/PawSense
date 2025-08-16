import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/constants.dart';

class StatsCard extends StatelessWidget {
  final String title;
  final String value;
  final String change;
  final Color changeColor;
  final IconData icon;
  final Color iconColor;

  const StatsCard({
    super.key,
    required this.title,
    required this.value,
    required this.change,
    required this.changeColor,
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
          Text(
            value,
            style: kTextStyleHeader.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: kSpacingSmall),
          Text(
            change,
            style: kTextStyleSmall.copyWith(
              color: changeColor,
            ),
          ),
        ],
      ),
    );
  }
}