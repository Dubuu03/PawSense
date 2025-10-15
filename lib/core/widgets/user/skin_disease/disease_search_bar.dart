import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';

/// Search bar component for Skin Disease Library
class DiseaseSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onChanged;
  final bool hasQuery;

  const DiseaseSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.hasQuery,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: kMobileMarginHorizontal,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: kMobileCardShadowSmall,
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Search skin diseases...',
          hintStyle: TextStyle(
            fontSize: 15,
            color: AppColors.textTertiary,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: AppColors.textSecondary,
            size: 22,
          ),
          suffixIcon: hasQuery
              ? GestureDetector(
                  onTap: () {
                    controller.clear();
                    onChanged('');
                  },
                  child: Icon(
                    Icons.clear,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        style: const TextStyle(
          fontSize: 15,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
