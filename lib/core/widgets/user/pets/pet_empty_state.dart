import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';

class PetEmptyState extends StatelessWidget {
  final bool isSearching;
  final String? customTitle;
  final String? customSubtitle;
  final Widget? customIcon;

  const PetEmptyState({
    super.key,
    this.isSearching = false,
    this.customTitle,
    this.customSubtitle,
    this.customIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: kMobileSizedBoxXXLarge * 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // Icon
          customIcon ?? Icon(
            Icons.pets,
            size: 64,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          
          const SizedBox(height: kMobileSizedBoxXLarge),
          
          // Title
          Text(
            customTitle ?? (isSearching ? 'No pets found' : 'No pets added yet'),
            style: kMobileTextStyleTitle.copyWith(
              fontSize: 18,
              color: AppColors.textSecondary,
            ),
          ),
          
          const SizedBox(height: kMobileSizedBoxMedium),
          
          // Subtitle
          Text(
            customSubtitle ?? (isSearching 
                ? 'Try adjusting your search terms'
                : 'Add your first pet using the + button'),
            style: kMobileTextStyleServiceSubtitle.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}