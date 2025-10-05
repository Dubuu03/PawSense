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
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 24),
          Expanded(
            child: ListView.separated(
              itemCount: displayDiseases.length,
              separatorBuilder: (context, index) => SizedBox(height: 20),
              itemBuilder: (context, index) {
                final disease = displayDiseases[index];
                return DiseaseItem(disease: disease, maxValue: maxValue);
              },
            ),
          ),
        ],
      ),
    );
  }
}