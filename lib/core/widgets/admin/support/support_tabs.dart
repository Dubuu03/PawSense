import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/constants.dart';

class SupportTabs extends StatelessWidget {
  final TabController tabController;
  final Function(int) onTabChanged;

  const SupportTabs({
    super.key,
    required this.tabController,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.border,
            width: 1,
          ),
        ),
      ),
      child: TabBar(
        controller: tabController,
        onTap: onTabChanged,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        indicatorWeight: 2,
        labelStyle: TextStyle(
          fontSize: kFontSizeRegular,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: kFontSizeRegular,
          fontWeight: FontWeight.normal,
        ),
        tabs: [
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Support Tickets'),
                SizedBox(width: kSpacingSmall),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '3',
                    style: TextStyle(
                      fontSize: kFontSizeSmall,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Tab(text: 'FAQ Management'),
        ],
      ),
    );
  }
}