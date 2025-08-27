import 'package:flutter/material.dart';
import '../../../core/utils/app_colors.dart';
import '../../../core/utils/constants.dart';

class SettingsTabBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabChanged;

  const SettingsTabBar({
    super.key,
    required this.currentIndex,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _TabItem(
        icon: Icons.person_outline,
        label: 'Profile',
        isSelected: currentIndex == 0,
        onTap: () => onTabChanged(0),
      ),
      _TabItem(
        icon: Icons.security_outlined,
        label: 'Security',
        isSelected: currentIndex == 1,
        onTap: () => onTabChanged(1),
      ),
      _TabItem(
        icon: Icons.notifications_outlined,
        label: 'Notifications',
        isSelected: currentIndex == 2,
        onTap: () => onTabChanged(2),
      ),
      _TabItem(
        icon: Icons.settings_outlined,
        label: 'System',
        isSelected: currentIndex == 3,
        onTap: () => onTabChanged(3),
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(kBorderRadius),
          topRight: Radius.circular(kBorderRadius),
        ),
        border: Border(
          bottom: BorderSide(
            color: AppColors.border,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: tabs.map((tab) => Expanded(child: tab)).toList(),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: kSpacingMedium,
          horizontal: kSpacingLarge,
        ),
        decoration: BoxDecoration(
          border: isSelected
              ? Border(
                  bottom: BorderSide(
                    color: AppColors.primary,
                    width: 3,
                  ),
                )
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: kIconSizeMedium,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            SizedBox(width: kSpacingSmall),
            Text(
              label,
              style: kTextStyleRegular.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
