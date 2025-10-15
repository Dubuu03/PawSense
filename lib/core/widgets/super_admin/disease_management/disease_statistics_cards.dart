import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';

class DiseaseStatisticsCards extends StatelessWidget {
  final Map<String, int> statistics;
  final bool isLoading;

  const DiseaseStatisticsCards({
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
            'Total Diseases',
            statistics['total'] ?? 0,
            Icons.medical_services,
            AppColors.primary,
          ),
        ),
        SizedBox(width: kSpacingLarge),
        Expanded(
          child: _buildStatCard(
            'AI-Detectable',
            statistics['ai'] ?? 0,
            Icons.auto_awesome,
            Color(0xFF8B5CF6),
          ),
        ),
        SizedBox(width: kSpacingLarge),
        Expanded(
          child: _buildStatCard(
            'Info Only',
            statistics['info'] ?? 0,
            Icons.info_outline,
            Color(0xFF6B7280),
          ),
        ),
        SizedBox(width: kSpacingLarge),
        Expanded(
          child: _buildStatCard(
            'Total Categories',
            statistics['categories'] ?? 0,
            Icons.category_outlined,
            Color(0xFF10B981),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    int value,
    IconData icon,
    Color color,
  ) {
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
                value.toString(),
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
