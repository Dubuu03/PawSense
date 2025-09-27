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
  final String? imageUrl; // Added image URL for displaying assessment images

  AIHistoryData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.timestamp,
    this.confidence,
    this.imageUrl,
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
            context.push('/ai-history/${item.id}');
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
                
                // Assessment image instead of detection tag
                if (data.imageUrl != null && data.imageUrl!.isNotEmpty)
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: Image.network(
                        data.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: AppColors.border,
                            child: Icon(
                              Icons.pets,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: AppColors.border,
                            child: Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  )
                else
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.pets,
                      color: AppColors.textSecondary,
                      size: 20,
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
