import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import '../../../utils/constants.dart';

class ServiceCard extends StatelessWidget {
  final String title;
  final String description;
  final String duration;      // Changed to String to match ClinicService model
  final String price;         // keep as String from your data
  final String category;
  final bool isActive;
  final VoidCallback? onToggle;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ServiceCard({
    super.key,
    required this.title,
    required this.description,
    required this.duration,
    required this.price,
    required this.category,
    this.isActive = true,
    this.onToggle,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(kSpacingMedium),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(kBorderRadius),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(kShadowOpacity),
            blurRadius: kShadowBlurRadius / 2, // 5px
            offset: kShadowOffset,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // let height follow content
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: title + actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title + category chip
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: kFontSizeRegular,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: kSpacingSmall,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(kBorderRadiusLarge),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          fontSize: kFontSizeSmall,
                          color: AppColors.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              // Actions
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: isActive,
                      onChanged: onToggle != null ? (_) => onToggle!() : null,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  if (onEdit != null)
                    IconButton(
                      icon: Icon(Icons.edit_rounded, size: kIconSizeMedium),
                      onPressed: onEdit,
                      color: AppColors.primary,
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                      tooltip: 'Edit Service',
                    ),
                  if (onDelete != null)
                    IconButton(
                      icon: Icon(Icons.delete_rounded, size: kIconSizeMedium),
                      onPressed: onDelete,
                      color: AppColors.error,
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                      tooltip: 'Delete Service',
                    ),
                ],
              ),
            ],
          ),

          SizedBox(height: kSpacingSmall + 4), // 12px

          // Description
          Text(
            description,
            style: TextStyle(
              fontSize: kFontSizeSmall,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),

          SizedBox(height: kSpacingSmall + 4), // 12px

          // Duration + Price row
          Row(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: kIconSizeSmall,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: 4),
                  Text(
                    duration,
                    style: TextStyle(
                      fontSize: kFontSizeSmall,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              SizedBox(width: kSpacingMedium),
              Row(
                children: [
                  Icon(
                    Icons.payments_rounded,
                    size: kIconSizeSmall,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: 4),
                  Text(
                    price,
                    style: TextStyle(
                      fontSize: kFontSizeSmall,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
