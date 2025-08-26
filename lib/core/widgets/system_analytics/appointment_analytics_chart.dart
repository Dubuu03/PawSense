import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/utils/app_colors.dart';
import '../../../core/utils/constants.dart';
import '../../../core/models/analytics/analytics_models.dart';

class AppointmentAnalyticsChart extends StatefulWidget {
  final AppointmentAnalytics appointmentAnalytics;

  const AppointmentAnalyticsChart({
    super.key,
    required this.appointmentAnalytics,
  });

  @override
  State<AppointmentAnalyticsChart> createState() => _AppointmentAnalyticsChartState();
}

class _AppointmentAnalyticsChartState extends State<AppointmentAnalyticsChart> {
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
                'Appointment Analytics',
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
                          child: Text('Volume Trends', style: kTextStyleRegular),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 1,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: kSpacingMedium),
                          child: Text('Peak Hours', style: kTextStyleRegular),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 2,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: kSpacingMedium),
                          child: Text('Appointment Types', style: kTextStyleRegular),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 3,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: kSpacingMedium),
                          child: Text('Status Distribution', style: kTextStyleRegular),
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
        return _buildVolumeTrendsChart();
      case 1:
        return _buildPeakHoursChart();
      case 2:
        return _buildAppointmentTypesChart();
      case 3:
        return _buildStatusDistributionChart();
      default:
        return _buildVolumeTrendsChart();
    }
  }

  Widget _buildVolumeTrendsChart() {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          drawHorizontalLine: true,
          horizontalInterval: 10,
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
                final chartData = widget.appointmentAnalytics.volumeTrends;
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
              interval: 10,
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
        maxX: (widget.appointmentAnalytics.volumeTrends.length - 1).toDouble(),
        minY: 0,
        maxY: widget.appointmentAnalytics.volumeTrends
            .map((e) => e.value)
            .reduce((a, b) => a > b ? a : b)
            .toDouble() + 10,
        lineBarsData: [
          LineChartBarData(
            spots: widget.appointmentAnalytics.volumeTrends
                .asMap()
                .entries
                .map((entry) => FlSpot(
                      entry.key.toDouble(),
                      entry.value.value.toDouble(),
                    ))
                .toList(),
            isCurved: true,
            color: AppColors.warning,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.warning.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeakHoursChart() {
    final hourlyData = widget.appointmentAnalytics.peakHours.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: hourlyData.map((e) => e.value).reduce((a, b) => a > b ? a : b).toDouble() + 5,
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
                if (value.toInt() < hourlyData.length) {
                  final hour = hourlyData[value.toInt()].key;
                  return Text(
                    '${hour.toString().padLeft(2, '0')}:00',
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
        barGroups: hourlyData
            .asMap()
            .entries
            .map((entry) => BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      toY: entry.value.value.toDouble(),
                      color: _getHourColor(entry.value.key),
                      width: 20,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ))
            .toList(),
      ),
    );
  }

  Widget _buildAppointmentTypesChart() {
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
        sections: widget.appointmentAnalytics.appointmentTypes.entries
            .toList()
            .asMap()
            .entries
            .map((entry) => PieChartSectionData(
                  color: _getTypeColor(entry.key),
                  value: entry.value.value.toDouble(),
                  title: '${entry.value.key}\n${entry.value.value}',
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

  Widget _buildStatusDistributionChart() {
    // Calculate status distribution based on rates
    final totalAppointments = widget.appointmentAnalytics.volumeTrends.fold(0.0, (sum, data) => sum + data.value);
    final cancelledCount = (totalAppointments * widget.appointmentAnalytics.cancellationRate / 100).round();
    final noShowCount = (totalAppointments * widget.appointmentAnalytics.noShowRate / 100).round();
    final completedCount = (totalAppointments - cancelledCount - noShowCount).round();
    final scheduledCount = (totalAppointments * 0.15).round(); // Assume 15% are scheduled
    
    final statusDistribution = {
      'completed': completedCount,
      'scheduled': scheduledCount,
      'cancelled': cancelledCount,
      'no_show': noShowCount,
    };

    final statusColors = {
      'completed': AppColors.success,
      'scheduled': AppColors.info,
      'cancelled': AppColors.error,
      'no_show': AppColors.warning,
    };

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
        sections: statusDistribution.entries
            .map((entry) => PieChartSectionData(
                  color: statusColors[entry.key] ?? AppColors.textSecondary,
                  value: entry.value.toDouble(),
                  title: '${_formatStatus(entry.key)}\n${entry.value}',
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

  Color _getHourColor(int hour) {
    // Morning (6-12): Blue
    if (hour >= 6 && hour < 12) return AppColors.info;
    // Afternoon (12-18): Green
    if (hour >= 12 && hour < 18) return AppColors.success;
    // Evening (18-22): Orange
    if (hour >= 18 && hour < 22) return AppColors.warning;
    // Night/Early morning: Red
    return AppColors.error;
  }

  Color _getTypeColor(int index) {
    final colors = [
      AppColors.primary,
      AppColors.success,
      AppColors.info,
      AppColors.warning,
      AppColors.error,
    ];
    return colors[index % colors.length];
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'completed':
        return 'Completed';
      case 'scheduled':
        return 'Scheduled';
      case 'cancelled':
        return 'Cancelled';
      case 'no_show':
        return 'No Show';
      default:
        return status;
    }
  }

  Widget _buildChartStats() {
    switch (selectedChartIndex) {
      case 0:
        return _buildVolumeStats();
      case 1:
        return _buildPeakHourStats();
      case 2:
        return _buildTypeStats();
      case 3:
        return _buildStatusStats();
      default:
        return Container();
    }
  }

  Widget _buildVolumeStats() {
    final total = widget.appointmentAnalytics.volumeTrends.fold(0.0, (sum, data) => sum + data.value);
    final average = total / widget.appointmentAnalytics.volumeTrends.length;
    final peak = widget.appointmentAnalytics.volumeTrends
        .reduce((a, b) => a.value > b.value ? a : b);
    
    return Row(
      children: [
        _buildStatCard('Total Appointments', total.toStringAsFixed(0), AppColors.warning),
        SizedBox(width: kSpacingMedium),
        _buildStatCard('Daily Average', average.toStringAsFixed(1), AppColors.info),
        SizedBox(width: kSpacingMedium),
        _buildStatCard('Peak Day', peak.value.toStringAsFixed(0), AppColors.success),
      ],
    );
  }

  Widget _buildPeakHourStats() {
    final totalHourly = widget.appointmentAnalytics.peakHours.values.fold(0, (sum, count) => sum + count);
    final peakHour = widget.appointmentAnalytics.peakHours.entries
        .reduce((a, b) => a.value > b.value ? a : b);
    
    return Row(
      children: [
        _buildStatCard('Total Hours Tracked', widget.appointmentAnalytics.peakHours.length.toString(), AppColors.info),
        SizedBox(width: kSpacingMedium),
        _buildStatCard('Total Appointments', totalHourly.toString(), AppColors.warning),
        SizedBox(width: kSpacingMedium),
        _buildStatCard('Peak Hour', '${peakHour.key}:00 (${peakHour.value})', AppColors.success),
      ],
    );
  }

  Widget _buildTypeStats() {
    final totalTypes = widget.appointmentAnalytics.appointmentTypes.values.fold(0, (sum, count) => sum + count);
    final mostPopular = widget.appointmentAnalytics.appointmentTypes.entries
        .reduce((a, b) => a.value > b.value ? a : b);
    
    return Row(
      children: [
        _buildStatCard('Service Types', widget.appointmentAnalytics.appointmentTypes.length.toString(), AppColors.info),
        SizedBox(width: kSpacingMedium),
        _buildStatCard('Total Bookings', totalTypes.toString(), AppColors.warning),
        SizedBox(width: kSpacingMedium),
        _buildStatCard('Most Popular', mostPopular.key, AppColors.primary),
      ],
    );
  }

  Widget _buildStatusStats() {
    final totalAppointments = widget.appointmentAnalytics.volumeTrends.fold(0.0, (sum, data) => sum + data.value);
    final completionRate = 100 - widget.appointmentAnalytics.cancellationRate - widget.appointmentAnalytics.noShowRate;
    
    return Row(
      children: [
        _buildStatCard('Total Appointments', totalAppointments.toStringAsFixed(0), AppColors.info),
        SizedBox(width: kSpacingMedium),
        _buildStatCard('Completion Rate', '${completionRate.toStringAsFixed(1)}%', AppColors.success),
        SizedBox(width: kSpacingMedium),
        _buildStatCard('Cancellation Rate', '${widget.appointmentAnalytics.cancellationRate.toStringAsFixed(1)}%', AppColors.error),
        SizedBox(width: kSpacingMedium),
        _buildStatCard('No-Show Rate', '${widget.appointmentAnalytics.noShowRate.toStringAsFixed(1)}%', AppColors.warning),
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
