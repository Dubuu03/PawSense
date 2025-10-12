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
            isLoading,
          ),
        ),
        SizedBox(width: kSpacingLarge),
        Expanded(
          child: _buildStatCard(
            'AI-Detectable',
            statistics['ai'] ?? 0,
            Icons.auto_awesome,
            Color(0xFF8B5CF6),
            isLoading,
          ),
        ),
        SizedBox(width: kSpacingLarge),
        Expanded(
          child: _buildStatCard(
            'Info Only',
            statistics['info'] ?? 0,
            Icons.info_outline,
            Color(0xFF6B7280),
            isLoading,
          ),
        ),
        SizedBox(width: kSpacingLarge),
        Expanded(
          child: _buildStatCard(
            'Total Categories',
            statistics['categories'] ?? 0,
            Icons.category_outlined,
            Color(0xFF10B981),
            isLoading,
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
    bool loading,
  ) {
    return Container(
      padding: EdgeInsets.all(kSpacingLarge),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(kBorderRadius),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: EdgeInsets.all(kSpacingMedium),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(kBorderRadiusSmall),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          SizedBox(width: kSpacingMedium),
          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: kTextStyleSmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                loading
                    ? Text(
                        'Loading...',
                        style: kTextStyleLarge.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : Text(
                        value.toString(),
                        style: kTextStyleLarge.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 28,
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
