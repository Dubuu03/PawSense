import 'package:flutter/material.dart';
import '../../../models/user/disease_data.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/constants.dart';

class DiseaseItem extends StatelessWidget {
  final DiseaseData disease;
  final int maxValue;

  const DiseaseItem({
    super.key,
    required this.disease,
    required this.maxValue,
  });

  @override
  Widget build(BuildContext context) {
    // Ensure percentage is between 0 and 1, handle division by zero
    final percentage = maxValue > 0 ? (disease.count / maxValue).clamp(0.0, 1.0) : 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                disease.name,
                style: TextStyle(
                  fontSize: kFontSizeSmall,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: 8),
            Text(
              '${disease.count}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Container(
          height: 6,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(3),
          ),
          child: percentage > 0 
              ? FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: percentage,
                  child: Container(
                    decoration: BoxDecoration(
                      color: disease.color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                )
              : SizedBox.shrink(),
        ),
      ],
    );
  }
}