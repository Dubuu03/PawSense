import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';

class BreedStatisticsCards extends StatelessWidget {
  final Map<String, int> statistics;
  final bool isLoading;

  const BreedStatisticsCards({
    super.key,
    required this.statistics,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Breeds',
            statistics['total']?.toString() ?? '0',
            Icons.pets,
            AppColors.primary,
          ),
        ),
        SizedBox(width: kSpacingLarge),
        Expanded(
          child: _buildStatCard(
            'Cat Breeds',
            statistics['catBreeds']?.toString() ?? '0',
            Icons.pets,
            Color(0xFFFF9500), // Orange
          ),
        ),
        SizedBox(width: kSpacingLarge),
        Expanded(
          child: _buildStatCard(
            'Dog Breeds',
            statistics['dogBreeds']?.toString() ?? '0',
            Icons.pets,
            Color(0xFF007AFF), // Blue
          ),
        ),
        SizedBox(width: kSpacingLarge),
        Expanded(
          child: _buildStatCard(
            'Recently Added',
            statistics['recentlyAdded']?.toString() ?? '0',
            Icons.add_circle_outline,
            AppColors.success,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
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
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: kIconSizeLarge,
                ),
              ),
              Text(
                value,
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
