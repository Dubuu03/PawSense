import 'package:flutter/material.dart';
import '../../../models/disease_data.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/constants.dart';
import 'disease_item.dart';

class CommonDiseasesChart extends StatelessWidget {
  const CommonDiseasesChart({super.key});

  @override
  Widget build(BuildContext context) {
    final diseases = [
      DiseaseData(name: 'Skin Allergies', count: 15, color: AppColors.primary),
      DiseaseData(name: 'Ear Infections', count: 8, color: AppColors.primary),
      DiseaseData(name: 'Dental Issues', count: 6, color: AppColors.primary),
      DiseaseData(name: 'Parasites', count: 5, color: AppColors.primary),
      DiseaseData(name: 'Digestive', count: 4, color: AppColors.primary),
    ];

    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Most Common Diseases',
            style: TextStyle(
              fontSize: kFontSizeRegular,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 24),
          Expanded(
            child: ListView.separated(
              itemCount: diseases.length,
              separatorBuilder: (context, index) => SizedBox(height: 20),
              itemBuilder: (context, index) {
                final disease = diseases[index];
                return DiseaseItem(disease: disease, maxValue: 15);
              },
            ),
          ),
        ],
      ),
    );
  }
}