import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/utils/app_colors.dart';
import '../../../core/utils/constants.dart';
import '../../../core/models/analytics/analytics_models.dart';

class ClinicPerformanceChart extends StatefulWidget {
  final ClinicPerformance clinicPerformance;

  const ClinicPerformanceChart({
    super.key,
    required this.clinicPerformance,
  });

  @override
  State<ClinicPerformanceChart> createState() => _ClinicPerformanceChartState();
}

class _ClinicPerformanceChartState extends State<ClinicPerformanceChart> {
  int selectedChartIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(kSpacingLarge),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(kBorderRadius),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: kShadowOpacity),
            blurRadius: kShadowBlurRadius,
            offset: kShadowOffset,
            spreadRadius: kShadowSpreadRadius,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with chart selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Clinic Performance',
                style: kTextStyleLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(kBorderRadiusSmall),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: selectedChartIndex,
                    onChanged: (int? newValue) {
                      if (newValue != null) {
                        setState(() {
                          selectedChartIndex = newValue;
                        });
                      }
                    },
                    items: [
                      DropdownMenuItem(
                        value: 0,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: kSpacingMedium),
                          child: Text('Clinic Registrations', style: kTextStyleRegular),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 1,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: kSpacingMedium),
                          child: Text('Geographic Distribution', style: kTextStyleRegular),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 2,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: kSpacingMedium),
                          child: Text('Utilization Rates', style: kTextStyleRegular),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 3,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: kSpacingMedium),
                          child: Text('Service Popularity', style: kTextStyleRegular),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: kSpacingLarge),
          
          // Chart Content
          SizedBox(
            height: 300,
            child: _buildSelectedChart(),
          ),
          
          SizedBox(height: kSpacingLarge),
          
          // Legend and Stats
          _buildChartStats(),
        ],
      ),
    );
  }

  Widget _buildSelectedChart() {
    switch (selectedChartIndex) {
      case 0:
        return _buildRegistrationsChart();
      case 1:
        return _buildGeographicChart();
      case 2:
        return _buildUtilizationChart();
      case 3:
        return _buildServicePopularityChart();
      default:
        return _buildRegistrationsChart();
    }
  }

  Widget _buildRegistrationsChart() {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          drawHorizontalLine: true,
          horizontalInterval: 2,
          verticalInterval: 1,
          getDrawingHorizontalLine: (value) => FlLine(
            color: AppColors.border,
            strokeWidth: 1,
          ),
          getDrawingVerticalLine: (value) => FlLine(
            color: AppColors.border,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (double value, TitleMeta meta) {
                final chartData = widget.clinicPerformance.registrationTrends;
                if (value.toInt() < chartData.length) {
                  final date = chartData[value.toInt()].date;
                  return Text(
                    '${date.day}/${date.month}',
                    style: kTextStyleSmall.copyWith(color: AppColors.textSecondary),
                  );
                }
                return Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 2,
              reservedSize: 42,
              getTitlesWidget: (double value, TitleMeta meta) {
                return Text(
                  value.toInt().toString(),
                  style: kTextStyleSmall.copyWith(color: AppColors.textSecondary),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: AppColors.border),
        ),
        minX: 0,
        maxX: (widget.clinicPerformance.registrationTrends.length - 1).toDouble(),
        minY: 0,
        maxY: widget.clinicPerformance.registrationTrends
            .map((e) => e.value)
            .reduce((a, b) => a > b ? a : b)
            .toDouble() + 2,
        lineBarsData: [
          LineChartBarData(
            spots: widget.clinicPerformance.registrationTrends
                .asMap()
                .entries
                .map((entry) => FlSpot(
                      entry.key.toDouble(),
                      entry.value.value.toDouble(),
                    ))
                .toList(),
            isCurved: true,
            color: AppColors.success,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.success.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeographicChart() {
    final sortedData = widget.clinicPerformance.geographicDistribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: sortedData.first.value.toDouble() + 5,
        barTouchData: BarTouchData(
          enabled: false,
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (double value, TitleMeta meta) {
                if (value.toInt() < sortedData.length) {
                  return Text(
                    sortedData[value.toInt()].key,
                    style: kTextStyleSmall.copyWith(color: AppColors.textSecondary),
                  );
                }
                return Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              getTitlesWidget: (double value, TitleMeta meta) {
                return Text(
                  value.toInt().toString(),
                  style: kTextStyleSmall.copyWith(color: AppColors.textSecondary),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: AppColors.border),
        ),
        barGroups: sortedData
            .asMap()
            .entries
            .map((entry) => BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      toY: entry.value.value.toDouble(),
                      color: AppColors.info,
                      width: 30,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ))
            .toList(),
      ),
    );
  }

  Widget _buildUtilizationChart() {
    final utilizationData = widget.clinicPerformance.utilizationRates.entries.toList();

    return PieChart(
      PieChartData(
        pieTouchData: PieTouchData(
          touchCallback: (FlTouchEvent event, pieTouchResponse) {
            // Handle touch events if needed
          },
        ),
        borderData: FlBorderData(show: false),
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: utilizationData
            .asMap()
            .entries
            .map((entry) => PieChartSectionData(
                  color: _getUtilizationColor(entry.key),
                  value: entry.value.value,
                  title: '${entry.value.key}\n${entry.value.value.toStringAsFixed(1)}%',
                  radius: 50,
                  titleStyle: kTextStyleSmall.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildServicePopularityChart() {
    final sortedServices = widget.clinicPerformance.servicePopularity.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: sortedServices.first.value.toDouble() + 10,
        barTouchData: BarTouchData(
          enabled: false,
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (double value, TitleMeta meta) {
                if (value.toInt() < sortedServices.length) {
                  final serviceName = sortedServices[value.toInt()].key;
                  return Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Transform.rotate(
                      angle: -0.5,
                      child: Text(
                        serviceName,
                        style: kTextStyleSmall.copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                  );
                }
                return Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              getTitlesWidget: (double value, TitleMeta meta) {
                return Text(
                  value.toInt().toString(),
                  style: kTextStyleSmall.copyWith(color: AppColors.textSecondary),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: AppColors.border),
        ),
        barGroups: sortedServices
            .asMap()
            .entries
            .map((entry) => BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      toY: entry.value.value.toDouble(),
                      color: AppColors.primary,
                      width: 25,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ))
            .toList(),
      ),
    );
  }

  Color _getUtilizationColor(int index) {
    final colors = [
      AppColors.primary,
      AppColors.success,
      AppColors.info,
      AppColors.warning,
      AppColors.error,
    ];
    return colors[index % colors.length];
  }

  Widget _buildChartStats() {
    switch (selectedChartIndex) {
      case 0:
        return _buildRegistrationStats();
      case 1:
        return _buildGeographicStats();
      case 2:
        return _buildUtilizationStats();
      case 3:
        return _buildServiceStats();
      default:
        return Container();
    }
  }

  Widget _buildRegistrationStats() {
    final total = widget.clinicPerformance.registrationTrends.fold(0.0, (sum, data) => sum + data.value);
    final average = total / widget.clinicPerformance.registrationTrends.length;
    
    return Row(
      children: [
        _buildStatCard('Total Clinics', total.toStringAsFixed(0), AppColors.success),
        SizedBox(width: kSpacingMedium),
        _buildStatCard('Monthly Average', average.toStringAsFixed(1), AppColors.info),
        SizedBox(width: kSpacingMedium),
        _buildStatCard('Peak Month', widget.clinicPerformance.registrationTrends
            .reduce((a, b) => a.value > b.value ? a : b)
            .value.toStringAsFixed(0), AppColors.primary),
      ],
    );
  }

  Widget _buildGeographicStats() {
    final totalClinics = widget.clinicPerformance.geographicDistribution.values.fold(0, (sum, count) => sum + count);
    final topLocation = widget.clinicPerformance.geographicDistribution.entries
        .reduce((a, b) => a.value > b.value ? a : b);
    
    return Row(
      children: [
        _buildStatCard('Total Locations', widget.clinicPerformance.geographicDistribution.length.toString(), AppColors.info),
        SizedBox(width: kSpacingMedium),
        _buildStatCard('Total Clinics', totalClinics.toString(), AppColors.success),
        SizedBox(width: kSpacingMedium),
        _buildStatCard('Top Location', '${topLocation.key} (${topLocation.value})', AppColors.primary),
      ],
    );
  }

  Widget _buildUtilizationStats() {
    final avgUtilization = widget.clinicPerformance.utilizationRates.values.fold(0.0, (sum, rate) => sum + rate) /
        widget.clinicPerformance.utilizationRates.length;
    final maxUtilization = widget.clinicPerformance.utilizationRates.values.reduce((a, b) => a > b ? a : b);
    
    return Row(
      children: [
        _buildStatCard('Average Utilization', '${avgUtilization.toStringAsFixed(1)}%', AppColors.info),
        SizedBox(width: kSpacingMedium),
        _buildStatCard('Max Utilization', '${maxUtilization.toStringAsFixed(1)}%', AppColors.success),
        SizedBox(width: kSpacingMedium),
        _buildStatCard('Active Clinics', widget.clinicPerformance.utilizationRates.length.toString(), AppColors.primary),
      ],
    );
  }

  Widget _buildServiceStats() {
    final totalServices = widget.clinicPerformance.servicePopularity.values.fold(0, (sum, count) => sum + count);
    final topService = widget.clinicPerformance.servicePopularity.entries
        .reduce((a, b) => a.value > b.value ? a : b);
    
    return Row(
      children: [
        _buildStatCard('Service Types', widget.clinicPerformance.servicePopularity.length.toString(), AppColors.info),
        SizedBox(width: kSpacingMedium),
        _buildStatCard('Total Bookings', totalServices.toString(), AppColors.success),
        SizedBox(width: kSpacingMedium),
        _buildStatCard('Most Popular', topService.key, AppColors.primary),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(kSpacingMedium),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(kBorderRadiusSmall),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: kTextStyleLarge.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: kSpacingSmall),
            Text(
              title,
              textAlign: TextAlign.center,
              style: kTextStyleSmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
