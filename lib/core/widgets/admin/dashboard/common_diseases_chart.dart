import 'package:flutter/material.dart';
import '../../../models/user/disease_data.dart';
import '../../../utils/app_colors.dart';
import '../../../services/admin/dashboard_service.dart' as DashboardSvc;
import 'disease_item.dart';

class CommonDiseasesChart extends StatelessWidget {
  final List<DashboardSvc.DiseaseData> diseaseData;
  
  const CommonDiseasesChart({
    super.key,
    this.diseaseData = const [],
  });

  @override
  Widget build(BuildContext context) {
    // Convert DashboardService.DiseaseData to widget's DiseaseData model
    final diseases = diseaseData.map((d) => 
      DiseaseData(
        name: d.name, 
        count: d.count, 
        color: AppColors.primary,
      )
    ).toList();
    
    // Use default data if no diseases available
    final displayDiseases = diseases.isEmpty ? [
      DiseaseData(name: 'No data available', count: 0, color: AppColors.textSecondary),
    ] : diseases;
    
    final maxValue = displayDiseases.isEmpty ? 1 : displayDiseases.map((d) => d.count).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.03),
            blurRadius: 40,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.bar_chart,
                  size: 18,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Common Diseases',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...displayDiseases.asMap().entries.map((entry) {
            final disease = entry.value;
            return Padding(
              padding: EdgeInsets.only(bottom: entry.key < displayDiseases.length - 1 ? 20 : 0),
              child: DiseaseItem(disease: disease, maxValue: maxValue),
            );
          }),
        ],
      ),
    );
  }
}