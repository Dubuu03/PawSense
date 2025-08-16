import 'package:flutter/material.dart';
import 'package:pawsense/core/widgets/admin/dashboard/recent_activity_list.dart';
import '../../../core/widgets/admin/dashboard/stats_cards_list.dart';
import '../../../core/widgets/admin/dashboard/dashboard_header.dart';
import '../../../core/widgets/admin/dashboard/common_diseases_chart.dart';
import '../../../core/utils/app_colors.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String selectedPeriod = 'Daily';

  final Map<String, List<Map<String, dynamic>>> statsData = {
    "Daily": [
      {
        'title': 'Total Appointments',
        'value': '12',
        'change': '+12% from last day',
        'changeColor': AppColors.success,
        'icon': Icons.calendar_today,
        'iconColor': AppColors.primary,
      },
      {
        'title': 'Consultations Completed',
        'value': '8',
        'change': '+6% from last day',
        'changeColor': AppColors.success,
        'icon': Icons.check_circle_outline,
        'iconColor': AppColors.success,
      },
      {
        'title': 'Active Patients',
        'value': '142',
        'change': '+5 new this day',
        'changeColor': AppColors.info,
        'icon': Icons.favorite_outline,
        'iconColor': AppColors.info,
      },
    ],
    "Weekly": [
      {
        'title': 'Total Appointments',
        'value': '85',
        'change': '+8% from last week',
        'changeColor': AppColors.success,
        'icon': Icons.calendar_today,
        'iconColor': AppColors.primary,
      },
      {
        'title': 'Consultations Completed',
        'value': '60',
        'change': '+5% from last week',
        'changeColor': AppColors.success,
        'icon': Icons.check_circle_outline,
        'iconColor': AppColors.success,
      },
      {
        'title': 'Active Patients',
        'value': '500',
        'change': '+20 new this week',
        'changeColor': AppColors.info,
        'icon': Icons.favorite_outline,
        'iconColor': AppColors.info,
      },
    ],
    "Monthly": [
      {
        'title': 'Total Appointments',
        'value': '320',
        'change': '+15% from last month',
        'changeColor': AppColors.success,
        'icon': Icons.calendar_today,
        'iconColor': AppColors.primary,
      },
      {
        'title': 'Consultations Completed',
        'value': '250',
        'change': '+12% from last month',
        'changeColor': AppColors.success,
        'icon': Icons.check_circle_outline,
        'iconColor': AppColors.success,
      },
      {
        'title': 'Active Patients',
        'value': '1200',
        'change': '+50 new this month',
        'changeColor': AppColors.info,
        'icon': Icons.favorite_outline,
        'iconColor': AppColors.info,
      },
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DashboardHeader(
            selectedPeriod: selectedPeriod,
            onPeriodChanged: (period) {
              setState(() {
                selectedPeriod = period;
              });
            },
          ),
          SizedBox(height: 24),
          StatsCards(statsList: statsData[selectedPeriod]!),
          SizedBox(height: 32),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 1, child: CommonDiseasesChart()),
                SizedBox(width: 24),
                Expanded(flex: 1, child: RecentActivityList()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
