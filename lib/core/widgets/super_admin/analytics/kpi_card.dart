import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';

/// KPI Card Widget - Displays key performance indicators
class KPICard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String changeText;
  final bool isPositive;
  final String? secondaryValue;
  final String? tertiaryValue;
  final Color? color;
  final bool isLoading;

  const KPICard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.changeText,
    required this.isPositive,
    this.secondaryValue,
    this.tertiaryValue,
    this.color,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = color ?? AppColors.primary;

    if (isLoading) {
      return _buildLoadingSkeleton(cardColor);
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: 140, // Minimum height to prevent overflow
        maxHeight: 200, // Maximum height to maintain layout
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Calculate responsive font size based on card width
            final valueFontSize = constraints.maxWidth > 250 ? 32.0 : 24.0; // Reduced from 36/28
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
              // Icon + Title Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: cardColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: cardColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Main Value - with responsive sizing
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: valueFontSize,
                    fontWeight: FontWeight.bold,
                    color: cardColor,
                    height: 1.2,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Change Indicator
              Row(
                children: [
                  Icon(
                    isPositive ? Icons.trending_up : Icons.trending_down,
                    color: isPositive ? AppColors.success : AppColors.error,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      changeText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isPositive ? AppColors.success : AppColors.error,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              if (secondaryValue != null || tertiaryValue != null) ...[
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 8),
              ],

              // Secondary/Tertiary Info
              if (secondaryValue != null)
                _buildInfoRow(
                  AppColors.success,
                  secondaryValue!,
                ),

              if (secondaryValue != null && tertiaryValue != null)
                const SizedBox(height: 6),

              if (tertiaryValue != null)
                _buildInfoRow(
                  AppColors.warning,
                  tertiaryValue!,
                ),
            ],
          );
        },
      ),
    ),
    );
  }

  Widget _buildInfoRow(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingSkeleton(Color cardColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.border.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.border.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 36,
            width: 120,
            decoration: BoxDecoration(
              color: AppColors.border.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 12,
            width: 100,
            decoration: BoxDecoration(
              color: AppColors.border.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ],
      ),
    );
  }
}
