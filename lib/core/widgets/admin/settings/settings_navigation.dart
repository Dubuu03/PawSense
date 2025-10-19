import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/constants.dart';

class SettingsNavigation extends StatelessWidget {
  final String selectedSection;
  final ValueChanged<String> onSectionChanged;

  const SettingsNavigation({
    super.key,
    required this.selectedSection,
    required this.onSectionChanged,
  });

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
            icon: Icons.lock_outline,
            title: 'Security',
            value: 'security',
            isSelected: selectedSection == 'security',
          ),
          SizedBox(height: kSpacingSmall),
          _buildNavigationItem(
            icon: Icons.description_outlined,
            title: 'Legal Documents',
            value: 'legal',
            isSelected: selectedSection == 'legal',
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
