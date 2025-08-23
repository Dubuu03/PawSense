import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';

class UserSummaryCards extends StatelessWidget {
  final int totalUsers;
  final int activeUsers;
  final int inactiveUsers; // Keep parameter name for compatibility
  final int adminUsers;

  const UserSummaryCards({
    Key? key,
    required this.totalUsers,
    required this.activeUsers,
    required this.inactiveUsers,
    required this.adminUsers,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            title: 'Total Users',
            count: totalUsers,
            color: AppColors.primary,
            icon: Icons.people,
            bgColor: AppColors.primary.withOpacity(0.1),
          ),
        ),
        SizedBox(width: kSpacingMedium),
        Expanded(
          child: _buildSummaryCard(
            title: 'Active Users',
            count: activeUsers,
            color: AppColors.success,
            icon: Icons.person_add_outlined,
            bgColor: AppColors.statusResolvedBg,
          ),
        ),
        SizedBox(width: kSpacingMedium),
        Expanded(
          child: _buildSummaryCard(
            title: 'Suspended Users',
            count: inactiveUsers,
            color: AppColors.error,
            icon: Icons.person_off_outlined,
            bgColor: AppColors.statusOpenBg,
          ),
        ),
        SizedBox(width: kSpacingMedium),
        Expanded(
          child: _buildSummaryCard(
            title: 'Admin Users',
            count: adminUsers,
            color: AppColors.roleSuperAdmin,
            icon: Icons.admin_panel_settings_outlined,
            bgColor: AppColors.roleSuperAdminBg,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required int count,
    required Color color,
    required IconData icon,
    required Color bgColor,
  }) {
    return Container(
      padding: EdgeInsets.all(kSpacingLarge),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(kBorderRadius),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(kShadowOpacity),
            spreadRadius: kShadowSpreadRadius,
            blurRadius: kShadowBlurRadius,
            offset: kShadowOffset,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(kSpacingSmall),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: kIconSizeLarge,
                ),
              ),
              Text(
                count.toString(),
                style: kTextStyleTitle.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: kSpacingMedium),
          Text(
            title,
            style: kTextStyleSmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
