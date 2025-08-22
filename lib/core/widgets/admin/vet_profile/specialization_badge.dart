import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';

class SpecializationBadge extends StatelessWidget {
  final String title;
  final String level;
  final bool hasCertification;
  final VoidCallback? onDelete;

  const SpecializationBadge({
    super.key,
    required this.title,
    required this.level,
    this.hasCertification = false,
    this.onDelete,
  });

  Color _getLevelColor() {
    switch (level.toLowerCase()) {
      case 'expert':
        return AppColors.success;
      case 'intermediate':
        return AppColors.warning;
      case 'basic':
        return AppColors.info;
      default:
        return AppColors.textSecondary;
    }
  }

  Color _getLevelBackgroundColor() {
    switch (level.toLowerCase()) {
      case 'expert':
        return AppColors.success.withOpacity(0.1);
      case 'intermediate':
        return AppColors.warning.withOpacity(0.1);
      case 'basic':
        return AppColors.info.withOpacity(0.1);
      default:
        return AppColors.textSecondary.withOpacity(0.1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: kSpacingSmall + 4), // 12px equivalent
      padding: EdgeInsets.all(kSpacingMedium),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(kBorderRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: kFontSizeRegular,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (onDelete != null)
                IconButton(
                  onPressed: onDelete,
                  icon: Icon(
                    Icons.delete_outline,
                    color: AppColors.error,
                    size: kIconSizeSmall,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                  splashRadius: 15,
                ),
            ],
          ),
          SizedBox(height: kSpacingSmall),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: kSpacingSmall + 4, // 12px
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getLevelBackgroundColor(),
                  borderRadius: BorderRadius.circular(kBorderRadiusLarge),
                ),
                child: Text(
                  level,
                  style: TextStyle(
                    color: _getLevelColor(),
                    fontSize: kFontSizeSmall,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (hasCertification) ...[
                SizedBox(width: kSpacingSmall),
                Icon(
                  Icons.verified,
                  color: AppColors.primary,
                  size: kIconSizeMedium,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
