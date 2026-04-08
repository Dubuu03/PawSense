import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../services/admin/dashboard_service.dart';
import '../../../utils/app_colors.dart';

class CommonDiseasesPieChart extends StatelessWidget {
  final DiseaseEvaluationData? diseaseData;
  final bool isLoading;

  const CommonDiseasesPieChart({
    super.key,
    this.diseaseData,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
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
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.medical_services,
                  size: 18,
                  color: AppColors.warning,
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
          SizedBox(
            height: 280,
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  )
                : diseaseData == null || diseaseData!.total == 0
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.medical_services_outlined,
                              size: 48,
                              color: AppColors.textSecondary,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No common diseases found',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth < 360) {
                            return Column(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: PieChart(
                                    PieChartData(
                                      sections: _generatePieChartSections(),
                                      centerSpaceRadius: 40,
                                      sectionsSpace: 2,
                                      startDegreeOffset: -90,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Expanded(
                                  flex: 2,
                                  child: SingleChildScrollView(
                                    child: _buildLegend(),
                                  ),
                                ),
                              ],
                            );
                          }
                          return Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: AspectRatio(
                                  aspectRatio: 1,
                                  child: PieChart(
                                    PieChartData(
                                      sections: _generatePieChartSections(),
                                      centerSpaceRadius: 50,
                                      sectionsSpace: 2,
                                      startDegreeOffset: -90,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                flex: 2,
                                child: SingleChildScrollView(
                                  physics: const BouncingScrollPhysics(),
                                  child: _buildLegend(),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _generatePieChartSections() {
    if (diseaseData == null || diseaseData!.total == 0) return [];

    final pieData = diseaseData!.toPieChartData();
    
    return pieData.map((data) {
      final percentage = (data.value / diseaseData!.total * 100);
      return PieChartSectionData(
        color: data.color,
        value: data.value.toDouble(),
        title: percentage > 8 ? '${percentage.toStringAsFixed(0)}%' : '',
        radius: 70,
        titleStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [
            Shadow(
              color: Colors.black26,
              offset: Offset(1, 1),
              blurRadius: 2,
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildLegend() {
    if (diseaseData == null || diseaseData!.total == 0) return const SizedBox.shrink();

    final pieData = diseaseData!.toPieChartData();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: pieData.map((data) {
        final percentage = (data.value / diseaseData!.total * 100);
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: data.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${data.value} (${percentage.toStringAsFixed(1)}%)',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}