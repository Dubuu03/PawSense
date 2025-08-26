import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/utils/app_colors.dart';
import '../../../core/utils/constants.dart';
import '../../../core/models/analytics/analytics_models.dart';

class UserAnalyticsChart extends StatefulWidget {
  final UserAnalytics userAnalytics;

  const UserAnalyticsChart({
    super.key,
    required this.userAnalytics,
  });

  @override
  State<UserAnalyticsChart> createState() => _UserAnalyticsChartState();
}

class _UserAnalyticsChartState extends State<UserAnalyticsChart> {
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
                'User Analytics',
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
                          child: Text('User Registrations', style: kTextStyleRegular),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 1,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: kSpacingMedium),
                          child: Text('Active Users', style: kTextStyleRegular),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 2,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: kSpacingMedium),
                          child: Text('User Distribution', style: kTextStyleRegular),
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
        return _buildRegistrationChart();
      case 1:
        return _buildActiveUsersChart();
      case 2:
        return _buildUserDistributionChart();
      default:
        return _buildRegistrationChart();
    }
  }

  Widget _buildRegistrationChart() {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          drawHorizontalLine: true,
          horizontalInterval: 5,
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
                final chartData = widget.userAnalytics.registrationTrends;
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
              interval: 5,
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
        maxX: (widget.userAnalytics.registrationTrends.length - 1).toDouble(),
        minY: 0,
        maxY: widget.userAnalytics.registrationTrends
            .map((e) => e.value)
            .reduce((a, b) => a > b ? a : b)
            .toDouble() + 5,
        lineBarsData: [
          LineChartBarData(
            spots: widget.userAnalytics.registrationTrends
                .asMap()
                .entries
                .map((entry) => FlSpot(
                      entry.key.toDouble(),
                      entry.value.value.toDouble(),
                    ))
                .toList(),
            isCurved: true,
            color: AppColors.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primary.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveUsersChart() {
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
                final chartData = widget.userAnalytics.activeSessions;
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
        maxX: (widget.userAnalytics.activeSessions.length - 1).toDouble(),
        minY: 0,
        maxY: widget.userAnalytics.activeSessions
            .map((e) => e.value)
            .reduce((a, b) => a > b ? a : b)
            .toDouble() + 10,
        lineBarsData: [
          LineChartBarData(
            spots: widget.userAnalytics.activeSessions
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

  Widget _buildUserDistributionChart() {
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
        sections: [
          PieChartSectionData(
            color: AppColors.primary,
            value: widget.userAnalytics.userTypeDistribution['admin']?.toDouble() ?? 0,
            title: 'Admin\n${widget.userAnalytics.userTypeDistribution['admin'] ?? 0}',
            radius: 50,
            titleStyle: kTextStyleSmall.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          PieChartSectionData(
            color: AppColors.success,
            value: widget.userAnalytics.userTypeDistribution['vet']?.toDouble() ?? 0,
            title: 'Vet\n${widget.userAnalytics.userTypeDistribution['vet'] ?? 0}',
            radius: 50,
            titleStyle: kTextStyleSmall.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          PieChartSectionData(
            color: AppColors.info,
            value: widget.userAnalytics.userTypeDistribution['user']?.toDouble() ?? 0,
            title: 'User\n${widget.userAnalytics.userTypeDistribution['user'] ?? 0}',
            radius: 50,
            titleStyle: kTextStyleSmall.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartStats() {
    switch (selectedChartIndex) {
      case 0:
        return _buildRegistrationStats();
      case 1:
        return _buildActivityStats();
      case 2:
        return _buildDistributionStats();
      default:
        return Container();
    }
  }

  Widget _buildRegistrationStats() {
    final total = widget.userAnalytics.registrationTrends.fold(0.0, (sum, data) => sum + data.value);
    final average = total / widget.userAnalytics.registrationTrends.length;
    
    return Row(
      children: [
        _buildStatCard('Total Registrations', total.toStringAsFixed(0), AppColors.primary),
        SizedBox(width: kSpacingMedium),
        _buildStatCard('Daily Average', average.toStringAsFixed(1), AppColors.info),
        SizedBox(width: kSpacingMedium),
        _buildStatCard('Peak Day', widget.userAnalytics.registrationTrends
            .reduce((a, b) => a.value > b.value ? a : b)
            .value.toStringAsFixed(0), AppColors.success),
      ],
    );
  }

  Widget _buildActivityStats() {
    final total = widget.userAnalytics.activeSessions.fold(0.0, (sum, data) => sum + data.value);
    final average = total / widget.userAnalytics.activeSessions.length;
    
    return Row(
      children: [
        _buildStatCard('Total Active Users', total.toStringAsFixed(0), AppColors.success),
        SizedBox(width: kSpacingMedium),
        _buildStatCard('Daily Average', average.toStringAsFixed(1), AppColors.info),
        SizedBox(width: kSpacingMedium),
        _buildStatCard('Peak Activity', widget.userAnalytics.activeSessions
            .reduce((a, b) => a.value > b.value ? a : b)
            .value.toStringAsFixed(0), AppColors.primary),
      ],
    );
  }

  Widget _buildDistributionStats() {
    final totalUsers = widget.userAnalytics.userTypeDistribution.values.fold(0, (sum, count) => sum + count);
    
    return Row(
      children: [
        _buildStatCard('Total Users', totalUsers.toString(), AppColors.primary),
        SizedBox(width: kSpacingMedium),
        _buildStatCard('Admins', widget.userAnalytics.userTypeDistribution['admin'].toString(), AppColors.primary),
        SizedBox(width: kSpacingMedium),
        _buildStatCard('Vets', widget.userAnalytics.userTypeDistribution['vet'].toString(), AppColors.success),
        SizedBox(width: kSpacingMedium),
        _buildStatCard('Users', widget.userAnalytics.userTypeDistribution['user'].toString(), AppColors.info),
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
