import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';

class SpecializationBadge extends StatelessWidget {
  final String title;
  final String level;
  final bool hasCertification;
  final String? certificateUrl;
  final VoidCallback? onDelete;
  final VoidCallback? onPreview;

  const SpecializationBadge({
    super.key,
    required this.title,
    required this.level,
    this.hasCertification = false,
    this.certificateUrl,
    this.onDelete,
    this.onPreview,
  });

  Color _getLevelColor() {
    switch (level.toLowerCase()) {
      case 'expert':
        return AppColors.success;
      case 'intermediate':
        return AppColors.warning;
      case 'basic':
        return AppColors.info;
      default:
        return AppColors.textSecondary;
    }
  }

  Color _getLevelBackgroundColor() {
    switch (level.toLowerCase()) {
      case 'expert':
        return AppColors.success.withOpacity(0.1);
      case 'intermediate':
        return AppColors.warning.withOpacity(0.1);
      case 'basic':
        return AppColors.info.withOpacity(0.1);
      default:
        return AppColors.textSecondary.withOpacity(0.1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasDocument = certificateUrl != null && certificateUrl!.isNotEmpty;
    final bool isClickable = hasDocument && onPreview != null;
    
    // Debug logging
    print('🔍 SpecializationBadge - $title:');
    print('  - hasCertification: $hasCertification');
    print('  - certificateUrl: $certificateUrl');
    print('  - hasDocument: $hasDocument'); 
    print('  - onPreview != null: ${onPreview != null}');
    print('  - isClickable: $isClickable');
    
    return MouseRegion(
      cursor: isClickable ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: Tooltip(
        message: isClickable 
            ? 'Click to view certificate' 
            : hasCertification 
                ? 'No certificate uploaded' 
                : 'No certification required',
        child: InkWell(
          onTap: isClickable ? onPreview : null,
          borderRadius: BorderRadius.circular(kBorderRadius),
          hoverColor: hasDocument ? AppColors.primary.withOpacity(0.02) : null,
          child: Container(
            width: double.infinity,
            margin: EdgeInsets.only(bottom: kSpacingSmall + 4), // 12px equivalent
            padding: EdgeInsets.all(kSpacingMedium),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(kBorderRadius),
              border: Border.all(
                color: hasDocument 
                    ? AppColors.primary.withOpacity(0.3) 
                    : AppColors.border,
              ),
              boxShadow: hasDocument 
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: kFontSizeRegular,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (hasDocument) ...[
                            SizedBox(width: kSpacingSmall),
                            Tooltip(
                              message: 'Click to view certificate',
                              child: Icon(
                                Icons.visibility,
                                color: AppColors.primary,
                                size: 16,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (onDelete != null)
                      IconButton(
                        onPressed: onDelete,
                        icon: Icon(
                          Icons.delete_outline,
                          color: AppColors.error,
                          size: kIconSizeSmall,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                        splashRadius: 15,
                      ),
                  ],
                ),
                SizedBox(height: kSpacingSmall),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: kSpacingSmall + 4, // 12px
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getLevelBackgroundColor(),
                        borderRadius: BorderRadius.circular(kBorderRadiusLarge),
                      ),
                      child: Text(
                        level,
                        style: TextStyle(
                          color: _getLevelColor(),
                          fontSize: kFontSizeSmall,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (hasCertification) ...[
                      SizedBox(width: kSpacingSmall),
                      Tooltip(
                        message: hasDocument 
                            ? 'Certificate uploaded' 
                            : 'Certified (no document uploaded)',
                        child: Icon(
                          hasDocument ? Icons.verified : Icons.check_circle_outline,
                          color: hasDocument ? AppColors.primary : AppColors.success,
                          size: kIconSizeMedium,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
