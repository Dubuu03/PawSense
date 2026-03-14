import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../utils/app_colors.dart';
import '../../../services/admin/dashboard_service.dart';

class MonthlyComparisonChart extends StatelessWidget {
  final MonthlyComparison comparisonData;
  final bool isLoading;

  const MonthlyComparisonChart({
    Key? key,
    required this.comparisonData,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingState();
    }

    final hasChartData = _hasChartData();
    final chartMax = _getChartMaxValue();
    final horizontalInterval = chartMax / 5;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
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
        children: [
          Row(
            children: [
              Icon(Icons.compare_arrows, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Monthly Comparison',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (hasChartData)
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: chartMax,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        String label;
                        if (groupIndex == 0) {
                          label = rodIndex == 0 ? 'Last Month\nAppointments' : 'Last Month\nCompleted';
                        } else {
                          label = rodIndex == 0 ? 'This Month\nAppointments' : 'This Month\nCompleted';
                        }
                        return BarTooltipItem(
                          '$label\n${rod.toY.toInt()}',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          switch (value.toInt()) {
                            case 0:
                              return const Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Text(
                                  'Last Month',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              );
                            case 1:
                              return const Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Text(
                                  'This Month',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              );
                            default:
                              return const Text('');
                          }
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      bottom: BorderSide(
                        color: AppColors.border.withValues(alpha: 0.5),
                        width: 1,
                      ),
                      left: BorderSide(
                        color: AppColors.border.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                  ),
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(
                          toY: comparisonData.lastMonthAppointments.toDouble(),
                          color: AppColors.info.withValues(alpha: 0.7),
                          width: 30,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(6),
                            topRight: Radius.circular(6),
                          ),
                        ),
                        BarChartRodData(
                          toY: comparisonData.lastMonthCompleted.toDouble(),
                          color: AppColors.success.withValues(alpha: 0.7),
                          width: 30,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(6),
                            topRight: Radius.circular(6),
                          ),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(
                          toY: comparisonData.currentMonthAppointments.toDouble(),
                          color: AppColors.info,
                          width: 30,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(6),
                            topRight: Radius.circular(6),
                          ),
                        ),
                        BarChartRodData(
                          toY: comparisonData.currentMonthCompleted.toDouble(),
                          color: AppColors.success,
                          width: 30,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(6),
                            topRight: Radius.circular(6),
                          ),
                        ),
                      ],
                    ),
                  ],
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: horizontalInterval,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: AppColors.border.withValues(alpha: 0.3),
                        strokeWidth: 1,
                      );
                    },
                  ),
                ),
              ),
            )
          else
            _buildEmptyChartState(),
          const SizedBox(height: 16),
          _buildLegend(),
          const SizedBox(height: 12),
          _buildChangeIndicators(),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem('Total Appointments', AppColors.info),
        const SizedBox(width: 24),
        _buildLegendItem('Completed', AppColors.success),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
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
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildChangeIndicators() {
    final appointmentChange = comparisonData.appointmentChange;
    final completionChange = comparisonData.completionChange;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildChangeItem(
            'Appointments',
            appointmentChange,
            appointmentChange >= 0,
          ),
          Container(
            width: 1,
            height: 30,
            color: AppColors.border.withValues(alpha: 0.3),
          ),
          _buildChangeItem(
            'Completion',
            completionChange,
            completionChange >= 0,
          ),
        ],
      ),
    );
  }

  Widget _buildChangeItem(String label, double change, bool isPositive) {
    return Row(
      children: [
        Icon(
          isPositive ? Icons.trending_up : Icons.trending_down,
          color: isPositive ? AppColors.success : AppColors.error,
          size: 20,
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              '${isPositive ? '+' : ''}${change.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isPositive ? AppColors.success : AppColors.error,
              ),
            ),
          ],
        ),
      ],
    );
  }

  double _getMaxValue() {
    return [
      comparisonData.currentMonthAppointments,
      comparisonData.lastMonthAppointments,
      comparisonData.currentMonthCompleted,
      comparisonData.lastMonthCompleted,
    ].reduce((a, b) => a > b ? a : b).toDouble();
  }

  bool _hasChartData() {
    return _getMaxValue() > 0;
  }

  double _getChartMaxValue() {
    final maxValue = _getMaxValue();
    if (maxValue <= 0) {
      return 1;
    }

    final padded = maxValue * 1.2;
    return padded < 1 ? 1 : padded;
  }

  Widget _buildEmptyChartState() {
    return Container(
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
      ),
      child: Center(
        child: Text(
          'No appointment comparison data yet for this period.',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary.withValues(alpha: 0.9),
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: const Center(
        heightFactor: 8,
        child: CircularProgressIndicator(),
      ),
    );
  }
}
