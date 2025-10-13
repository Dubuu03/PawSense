import 'package:flutter/material.dart';
import 'package:pawsense/core/models/skin_disease/skin_disease_model.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';

class DiseaseCard extends StatefulWidget {
  final SkinDiseaseModel disease;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const DiseaseCard({
    super.key,
    required this.disease,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<DiseaseCard> createState() => _DiseaseCardState();
}

class _DiseaseCardState extends State<DiseaseCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap,
      onHover: (hovering) {
        setState(() {
          _isHovered = hovering;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: kSpacingMedium,
          vertical: kSpacingSmall,
        ),
        decoration: BoxDecoration(
          color: _isHovered ? AppColors.background : Colors.transparent,
          border: Border(
            bottom: BorderSide(color: AppColors.border),
          ),
        ),
        child: Row(
          children: [
            // Name - Flex 3
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildName(),
              ),
            ),

            // Detection Badge - Fixed 100px
            SizedBox(
              width: 100,
              child: _buildDetectionBadge(),
            ),
            const SizedBox(width: 16),

            // Species - Fixed 120px
            SizedBox(
              width: 120,
              child: _buildSpeciesChips(),
            ),
            const SizedBox(width: 16),

            // Severity - Fixed 100px
            SizedBox(
              width: 100,
              child: Center(child: _buildSeverityBadge()),
            ),
            const SizedBox(width: 16),

            // Categories - Fixed 120px
            SizedBox(
              width: 120,
              child: _buildCategories(),
            ),
            const SizedBox(width: 16),

            // Contagious - Fixed 100px
            SizedBox(
              width: 100,
              child: Center(child: _buildContagiousIndicator()),
            ),
            const SizedBox(width: 16),

            // Actions - Fixed 80px
            SizedBox(
              width: 80,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Tooltip(
                    message: 'Edit',
                    child: IconButton(
                      icon: Icon(Icons.edit_outlined, size: kIconSizeSmall),
                      color: AppColors.textSecondary,
                      onPressed: widget.onEdit,
                      padding: EdgeInsets.all(kSpacingXSmall),
                      constraints: const BoxConstraints(),
                    ),
                  ),
                  SizedBox(width: kSpacingXSmall),
                  Tooltip(
                    message: 'Delete',
                    child: IconButton(
                      icon: Icon(Icons.delete_outline, size: kIconSizeSmall),
                      color: AppColors.error,
                      onPressed: widget.onDelete,
                      padding: EdgeInsets.all(kSpacingXSmall),
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildName() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          widget.disease.name,
          style: kTextStyleRegular.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: kSpacingXSmall / 2),
        Text(
          widget.disease.description,
          style: kTextStyleSmall.copyWith(
            color: AppColors.textSecondary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildDetectionBadge() {
    final isAI = widget.disease.detectionMethod == 'ai';
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: kSpacingSmall,
        vertical: kSpacingXSmall,
      ),
      decoration: BoxDecoration(
        color: isAI
            ? AppColors.primary.withOpacity(0.1)
            : AppColors.background,
        borderRadius: BorderRadius.circular(kBorderRadiusSmall),
        border: Border.all(
          color: isAI 
              ? AppColors.primary.withOpacity(0.3) 
              : AppColors.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isAI ? '✨' : 'ℹ️',
            style: const TextStyle(fontSize: 12),
          ),
          SizedBox(width: kSpacingXSmall),
          Flexible(
            child: Text(
              isAI ? 'AI' : 'Info',
              style: kTextStyleSmall.copyWith(
                fontWeight: FontWeight.w600,
                color: isAI ? AppColors.primary : AppColors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeciesChips() {
    final speciesLower = widget.disease.species.map((s) => s.toLowerCase()).toList();
    final supportsCats = speciesLower.any((s) => s.contains('cat'));
    final supportsDogs = speciesLower.any((s) => s.contains('dog'));
    final supportsBoth = speciesLower.contains('both');

    if (!supportsCats && !supportsDogs && !supportsBoth) {
      return Text(
        'Not specified',
        style: kTextStyleSmall.copyWith(
          color: AppColors.textTertiary,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (supportsCats || supportsBoth)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: kSpacingXSmall,
              vertical: kSpacingXSmall / 2,
            ),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              border: Border.all(color: AppColors.warning),
              borderRadius: BorderRadius.circular(kBorderRadiusSmall),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🐱', style: TextStyle(fontSize: 11)),
                SizedBox(width: kSpacingXSmall / 2),
                Text(
                  'Cats',
                  style: kTextStyleSmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        if ((supportsCats || supportsBoth) && (supportsDogs || supportsBoth))
          SizedBox(width: kSpacingXSmall),
        if (supportsDogs || supportsBoth)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: kSpacingXSmall,
              vertical: kSpacingXSmall / 2,
            ),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              border: Border.all(color: AppColors.info),
              borderRadius: BorderRadius.circular(kBorderRadiusSmall),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🐶', style: TextStyle(fontSize: 11)),
                SizedBox(width: kSpacingXSmall / 2),
                Text(
                  'Dogs',
                  style: kTextStyleSmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSeverityBadge() {
    final severity = widget.disease.severity.toLowerCase();
    Color bgColor;
    Color textColor;

    switch (severity) {
      case 'mild':
        bgColor = AppColors.success.withOpacity(0.1);
        textColor = AppColors.success;
        break;
      case 'moderate':
        bgColor = AppColors.warning.withOpacity(0.1);
        textColor = AppColors.warning;
        break;
      case 'severe':
        bgColor = AppColors.error.withOpacity(0.1);
        textColor = AppColors.error;
        break;
      default: // varies
        bgColor = AppColors.background;
        textColor = AppColors.textSecondary;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: kSpacingSmall,
        vertical: kSpacingXSmall,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(kBorderRadiusSmall),
      ),
      child: Text(
        widget.disease.severity,
        style: kTextStyleSmall.copyWith(
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildCategories() {
    if (widget.disease.categories.isEmpty) {
      return Text(
        'No categories',
        style: kTextStyleSmall.copyWith(
          color: AppColors.textTertiary,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    final categoriesText = widget.disease.categories.join(', ');

    return Tooltip(
      message: categoriesText,
      child: Text(
        categoriesText,
        style: kTextStyleSmall.copyWith(
          color: AppColors.textSecondary,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }

  Widget _buildContagiousIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: kSpacingSmall,
        vertical: kSpacingXSmall,
      ),
      decoration: BoxDecoration(
        color: widget.disease.isContagious
            ? AppColors.error.withOpacity(0.1)
            : AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(kBorderRadiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            widget.disease.isContagious ? '⚠️' : '✓',
            style: const TextStyle(fontSize: 12),
          ),
          SizedBox(width: kSpacingXSmall),
          Text(
            widget.disease.isContagious ? 'Yes' : 'No',
            style: kTextStyleSmall.copyWith(
              fontWeight: FontWeight.w600,
              color: widget.disease.isContagious
                  ? AppColors.error
                  : AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

}
