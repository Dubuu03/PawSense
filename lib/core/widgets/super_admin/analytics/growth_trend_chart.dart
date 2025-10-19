import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pawsense/core/models/analytics/system_analytics_models.dart';
import 'package:pawsense/core/utils/app_colors.dart';

/// Growth Trend Chart - Professional multi-line chart using fl_chart
class GrowthTrendChart extends StatelessWidget {
  final List<TimeSeriesData> userTrend;
  final List<TimeSeriesData> clinicTrend;
  final List<TimeSeriesData> petTrend;
  final bool isLoading;

  const GrowthTrendChart({
    super.key,
    required this.userTrend,
    required this.clinicTrend,
    required this.petTrend,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              const Text(
                'Growth Trends',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              if (!isLoading && (userTrend.isNotEmpty || clinicTrend.isNotEmpty || petTrend.isNotEmpty)) ...[
                if (userTrend.isNotEmpty) _buildLegend('Users', AppColors.primary),
                if (userTrend.isNotEmpty && (clinicTrend.isNotEmpty || petTrend.isNotEmpty)) 
                  const SizedBox(width: 16),
                if (clinicTrend.isNotEmpty) _buildLegend('Clinics', AppColors.success),
                if (clinicTrend.isNotEmpty && petTrend.isNotEmpty) 
                  const SizedBox(width: 16),
                if (petTrend.isNotEmpty) _buildLegend('Pets', AppColors.warning),
              ],
            ],
          ),

          const SizedBox(height: 24),

          // Chart Area
          if (isLoading)
            const SizedBox(
              height: 280,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (userTrend.isEmpty &&
              clinicTrend.isEmpty &&
              petTrend.isEmpty)
            Container(
              height: 280,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.show_chart,
                      size: 48,
                      color: AppColors.textTertiary,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'No trend data available',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Data will appear as users, clinics, and pets are added',
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 280,
              child: Padding(
                padding: const EdgeInsets.only(top: 16, right: 16),
                child: LineChart(
                  _buildChartData(),
                  duration: const Duration(milliseconds: 250),
                ),
              ),
            ),
        ],
      ),
    );
  }

  LineChartData _buildChartData() {
    // Find max value for Y-axis scaling
    final allValues = [
      ...userTrend.map((d) => d.value.toDouble()),
      ...clinicTrend.map((d) => d.value.toDouble()),
      ...petTrend.map((d) => d.value.toDouble()),
    ];
    final maxValue = allValues.isEmpty ? 10.0 : allValues.reduce((a, b) => a > b ? a : b);
    final maxY = (maxValue * 1.2).ceilToDouble(); // Add 20% padding

    final lines = <LineChartBarData>[];
    
    // Add user trend line
    if (userTrend.isNotEmpty) {
      lines.add(_buildLineData(userTrend, AppColors.primary));
    }
    
    // Add clinic trend line
    if (clinicTrend.isNotEmpty) {
      lines.add(_buildLineData(clinicTrend, AppColors.success));
    }
    
    // Add pet trend line
    if (petTrend.isNotEmpty) {
      lines.add(_buildLineData(petTrend, AppColors.warning));
    }

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: maxY / 5,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: AppColors.border,
            strokeWidth: 1,
          );
        },
        getDrawingVerticalLine: (value) {
          return FlLine(
            color: AppColors.border.withValues(alpha: 0.5),
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 42,
            interval: maxY / 5,
            getTitlesWidget: (value, meta) {
              return Text(
                value.toInt().toString(),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0) return const SizedBox.shrink();
              
              // Use the longest available trend for labels
              final trend = userTrend.isNotEmpty ? userTrend 
                          : clinicTrend.isNotEmpty ? clinicTrend 
                          : petTrend;
              
              if (index >= trend.length) return const SizedBox.shrink();
              
              // Show every other label to avoid crowding
              if (trend.length > 8 && index % 2 != 0) {
                return const SizedBox.shrink();
              }
              
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  trend[index].label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              );
            },
          ),
        ),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: AppColors.border),
      ),
      minX: 0,
      maxX: (userTrend.isNotEmpty ? userTrend.length : clinicTrend.isNotEmpty ? clinicTrend.length : petTrend.length).toDouble() - 1,
      minY: 0,
      maxY: maxY,
      lineBarsData: lines,
      lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              String label = 'Value';
              if (spot.barIndex == 0 && userTrend.isNotEmpty) label = 'Users';
              if (spot.barIndex == 1 && clinicTrend.isNotEmpty) label = 'Clinics';
              if (spot.barIndex == 2 && petTrend.isNotEmpty) label = 'Pets';
              // Handle case where not all lines exist
              if (userTrend.isEmpty && spot.barIndex == 0 && clinicTrend.isNotEmpty) label = 'Clinics';
              if (userTrend.isEmpty && spot.barIndex == 1 && petTrend.isNotEmpty) label = 'Pets';
              
              return LineTooltipItem(
                '$label\n${spot.y.toInt()}',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            }).toList();
          },
        ),
      ),
    );
  }

  LineChartBarData _buildLineData(List<TimeSeriesData> data, Color color) {
    return LineChartBarData(
      spots: List.generate(
        data.length,
        (index) => FlSpot(index.toDouble(), data[index].value.toDouble()),
      ),
      isCurved: true,
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) {
          return FlDotCirclePainter(
            radius: 4,
            color: color,
            strokeWidth: 2,
            strokeColor: AppColors.white,
          );
        },
      ),
      belowBarData: BarAreaData(
        show: true,
        color: color.withValues(alpha: 0.1),
      ),
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
