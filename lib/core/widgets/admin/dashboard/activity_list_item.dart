import 'package:flutter/material.dart';
import '../../../models/activity_item.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/constants.dart';

class ActivityListItem extends StatelessWidget {
  final ActivityItem activity;

  const ActivityListItem({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: activity.iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            activity.icon,
            color: activity.iconColor,
            size: 20,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                  Text(
                    activity.title,
                    style: TextStyle(
                      fontSize: kFontSizeRegular,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
              SizedBox(height: 4),
              Text(
                activity.subtitle,
                style: TextStyle(
                      fontSize: kFontSizeSmall,
                  color: AppColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.access_time, size: 12, color: AppColors.textTertiary),
                  SizedBox(width: 4),
                  Text(
                    activity.time,
                    style: TextStyle(
                          fontSize: kFontSizeSmall,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}