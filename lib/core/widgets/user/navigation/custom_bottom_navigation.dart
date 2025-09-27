import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';

class CustomBottomNavItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  CustomBottomNavItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

class CustomBottomNavigation extends StatelessWidget {
  final List<CustomBottomNavItem> items;
  final int currentIndex;
  final VoidCallback? onCenterButtonPressed;

  const CustomBottomNavigation({
    super.key,
    required this.items,
    required this.currentIndex,
    this.onCenterButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left nav items
          if (items.isNotEmpty) _buildNavItem(items[0], 0),
          if (items.length > 1) _buildNavItem(items[1], 1),
          
          // Center floating button
          Expanded(
            child: Center(
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onCenterButtonPressed,
                    borderRadius: BorderRadius.circular(28),
                    child: Icon(
                      Icons.camera_alt,
                      color: AppColors.white,
                      size: kIconSizeLarge,
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Right nav items  
          if (items.length > 2) _buildNavItem(items[2], 2),
          if (items.length > 3) _buildNavItem(items[3], 3),
        ],
      ),
    );
  }

  Widget _buildNavItem(CustomBottomNavItem item, int index) {
    final isSelected = currentIndex == index;
    
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: item.onTap,
          child: SizedBox(
            height: 80,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  item.icon,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  size: kIconSizeLarge,
                ),
                SizedBox(height: kSpacingSmall),
                Text(
                  item.label,
                  style: kTextStyleSmall.copyWith(
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
