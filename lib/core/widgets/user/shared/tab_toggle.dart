import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';

class TabToggle extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTabChanged;
  final List<String> tabs;

  const TabToggle({
    super.key,
    required this.selectedIndex,
    required this.onTabChanged,
    required this.tabs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: kMobileBorderRadiusIconPreset,
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: List.generate(
          tabs.length,
          (index) => Expanded(
            child: GestureDetector(
              onTap: () => onTabChanged(index),
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: selectedIndex == index 
                      ? AppColors.primary 
                      : Colors.transparent,
                  borderRadius: kMobileBorderRadiusButtonPreset,
                ),
                child: Center(
                  child: Text(
                    tabs[index],
                    style: kMobileTextStyleSubtitle.copyWith(
                      fontWeight: FontWeight.w500,
                      color: selectedIndex == index 
                          ? Colors.white
                          : AppColors.textSecondary,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
