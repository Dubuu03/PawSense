import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';

/// Empty state widget for skin disease library
/// 
/// Displayed when no diseases match the current filters
class SkinDiseaseEmptyState extends StatelessWidget {
  final String message;
  final String? submessage;
  final VoidCallback? onReset;

  const SkinDiseaseEmptyState({
    super.key,
    this.message = 'No skin diseases found',
    this.submessage,
    this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off,
                size: 64,
                color: AppColors.primary.withValues(alpha: 0.5),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Message
            Text(
              message,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            
            if (submessage != null) ...[
              const SizedBox(height: 8),
              Text(
                submessage!,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            
            if (onReset != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onReset,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Clear Filters',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
