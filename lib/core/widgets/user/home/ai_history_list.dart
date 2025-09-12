import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';

enum AIDetectionType {
  mange,
  ringworm,
  pyoderma,
  hotSpot,
  fleaAllergy,
}

class AIHistoryData {
  final String id; // Added ID field for navigation
  final String title;
  final String subtitle;
  final AIDetectionType type;
  final DateTime timestamp;
  final double? confidence;

  AIHistoryData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.timestamp,
    this.confidence,
  });
}

class AIHistoryList extends StatelessWidget {
  final List<AIHistoryData> aiHistory;

  const AIHistoryList({
    super.key,
    required this.aiHistory,
  });

  @override
  Widget build(BuildContext context) {
    if (aiHistory.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        ...aiHistory.take(3).map((item) => AIHistoryItem(
          data: item,
          onTap: () {
            context.go('/ai-history/${item.id}');
          },
        )),
        if (aiHistory.length > 3) ...[
          const SizedBox(height: kMobileSizedBoxMedium),
          Text(
            '${aiHistory.length - 3} more detections',
            style: kMobileTextStyleSubtitle.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: kMobilePaddingLarge),
      child: Column(
        children: [
          Icon(
            Icons.pets,
            size: 32,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: kMobileSizedBoxMedium),
          Text(
            'No AI detections yet',
            style: kMobileTextStyleSubtitle.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class AIHistoryItem extends StatelessWidget {
  final AIHistoryData data;
  final VoidCallback? onTap;

  const AIHistoryItem({
    super.key,
    required this.data,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: kMobileSizedBoxMedium),
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
        borderRadius: kMobileBorderRadiusSmallPreset,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: kMobileBorderRadiusSmallPreset,
          child: Padding(
            padding: const EdgeInsets.all(kMobilePaddingSmall),
            child: Row(
              children: [
                // Detection icon/avatar
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.healing,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ),
                
                const SizedBox(width: kMobileSizedBoxLarge),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.title,
                        style: kMobileTextStyleTitle.copyWith(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        data.subtitle,
                        style: kMobileTextStyleSubtitle.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Detection tag
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getDetectionColor().withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _getDetectionLabel(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _getDetectionColor(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getDetectionColor() {
    switch (data.type) {
      case AIDetectionType.mange:
        return const Color(0xFFFF9500);
      case AIDetectionType.ringworm:
        return const Color(0xFF007AFF);
      case AIDetectionType.pyoderma:
        return const Color(0xFFE74C3C);
      case AIDetectionType.hotSpot:
        return const Color(0xFF8E44AD);
      case AIDetectionType.fleaAllergy:
        return const Color(0xFF34C759);
    }
  }

  String _getDetectionLabel() {
    switch (data.type) {
      case AIDetectionType.mange:
        return 'Mange';
      case AIDetectionType.ringworm:
        return 'Ringworm';
      case AIDetectionType.pyoderma:
        return 'Pyoderma';
      case AIDetectionType.hotSpot:
        return 'Hot Spot';
      case AIDetectionType.fleaAllergy:
        return 'Flea Allergy';
    }
  }
}
