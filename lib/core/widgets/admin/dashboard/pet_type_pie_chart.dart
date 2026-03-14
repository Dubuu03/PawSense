import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../utils/app_colors.dart';

class PetTypePieChart extends StatelessWidget {
  final Map<String, int> petTypeDistribution;
  final bool isLoading;

  const PetTypePieChart({
    Key? key,
    required this.petTypeDistribution,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (petTypeDistribution.isEmpty) {
      return _buildEmptyState();
    }

    final total = petTypeDistribution.values.fold(0, (sum, count) => sum + count);
    final colors = _getPetTypeColors();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
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
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.pets, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Pet Type Distribution',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 250,
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 360) {
                  return Column(
                    children: [
                      Expanded(
                        flex: 3,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 40,
                            sections: _buildPieChartSections(total, colors),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        flex: 2,
                        child: SingleChildScrollView(
                          child: _buildLegend(total, colors),
                        ),
                      ),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 60,
                          sections: _buildPieChartSections(total, colors),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: _buildLegend(total, colors),
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

  List<PieChartSectionData> _buildPieChartSections(int total, Map<String, Color> colors) {
    return petTypeDistribution.entries.map((entry) {
      final percentage = (entry.value / total * 100);
      final color = colors[entry.key] ?? Colors.grey;

      return PieChartSectionData(
        value: entry.value.toDouble(),
        title: '${percentage.toStringAsFixed(1)}%',
        color: color,
        radius: 60,
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
        badgeWidget: percentage > 10 ? _buildBadge(entry.key, color) : null,
        badgePositionPercentageOffset: 0.8,
      );
    }).toList();
  }

  Widget _buildLegend(int total, Map<String, Color> colors) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: petTypeDistribution.entries.map((entry) {
        final percentage = (entry.value / total * 100);
        final color = colors[entry.key] ?? Colors.grey;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${entry.value} (${percentage.toStringAsFixed(1)}%)',
                      style: TextStyle(
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

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.pets,
              size: 48,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Pet Data Available',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildBadge(String petType, Color color) {
    // Don't show badges for Cat and Dog
    if (petType == 'Cat' || petType == 'Dog') {
      return null;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        petType,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Map<String, Color> _getPetTypeColors() {
    return {
      'Dog': const Color(0xFF4CAF50),
      'Cat': const Color(0xFF2196F3),
      'Bird': const Color(0xFFFF9800),
      'Rabbit': const Color(0xFF9C27B0),
      'Hamster': const Color(0xFFFFEB3B),
      'Fish': const Color(0xFF00BCD4),
      'Reptile': const Color(0xFF8BC34A),
      'Other': const Color(0xFF757575),
    };
  }
}
