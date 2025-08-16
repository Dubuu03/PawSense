import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';

class SettingsNavigation extends StatelessWidget {
  final String selectedSection;
  final ValueChanged<String> onSectionChanged;

  const SettingsNavigation({
    Key? key,
    required this.selectedSection,
    required this.onSectionChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      padding: EdgeInsets.all(kSpacingLarge),
      child: Column(
        children: [
          _buildNavigationItem(
            icon: Icons.person_outline,
            title: 'Account',
            value: 'account',
            isSelected: selectedSection == 'account',
          ),
          SizedBox(height: kSpacingSmall),
          _buildNavigationItem(
            icon: Icons.location_city_outlined,
            title: 'Clinic',
            value: 'clinic',
            isSelected: selectedSection == 'clinic',
          ),
          SizedBox(height: kSpacingSmall),
          _buildNavigationItem(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            value: 'notifications',
            isSelected: selectedSection == 'notifications',
          ),
          SizedBox(height: kSpacingSmall),
          _buildNavigationItem(
            icon: Icons.security_outlined,
            title: 'Security',
            value: 'security',
            isSelected: selectedSection == 'security',
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationItem({
    required IconData icon,
    required String title,
    required String value,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () => onSectionChanged(value),
      borderRadius: BorderRadius.circular(kBorderRadiusSmall),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: kSpacingMedium, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(kBorderRadiusSmall),
          border: isSelected 
              ? Border.all(color: AppColors.primary.withOpacity(0.2))
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            SizedBox(width: kSpacingMedium),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: kFontSizeRegular,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
