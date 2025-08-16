import 'package:flutter/material.dart';
import '../../../models/disease_data.dart';
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
    final percentage = (disease.count / maxValue);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              disease.name,
              style: TextStyle(
                    fontSize: kFontSizeSmall,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
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
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: percentage,
            child: Container(
              decoration: BoxDecoration(
                color: disease.color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}