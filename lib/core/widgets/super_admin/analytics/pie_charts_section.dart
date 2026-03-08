import 'package:flutter/material.dart';
import 'package:pawsense/core/models/analytics/system_analytics_models.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'pie_chart_widget.dart';
import 'diseases_pie_chart.dart';

/// Collection of Pie Charts for Analytics Dashboard
class AnalyticsPieChartsSection extends StatelessWidget {
  final UserStats? userStats;
  final PetStats? petStats;
  final AppointmentStats? appointmentStats;
  final List<DiseaseData> topDiseases;
  final bool isLoading;

  const AnalyticsPieChartsSection({
    super.key,
    this.userStats,
    this.petStats,
    this.appointmentStats,
    this.topDiseases = const [],
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Data Distribution',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            // Max 2 columns — keeps charts readable at any screen width
            int columns = 2;
            if (constraints.maxWidth < 800) columns = 1;

            final charts = _buildCharts();
            
            if (columns == 1) {
              return Column(
                children: charts.map((chart) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: chart,
                )).toList(),
              );
            }

            // Create rows of charts
            final rows = <Widget>[];
            for (int i = 0; i < charts.length; i += columns) {
              final rowCharts = charts.skip(i).take(columns).toList();
              rows.add(
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: rowCharts.asMap().entries.map((entry) {
                    final isLast = entry.key == rowCharts.length - 1;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: isLast ? 0 : 16),
                        child: entry.value,
                      ),
                    );
                  }).toList(),
                ),
              );
              
              if (i + columns < charts.length) {
                rows.add(const SizedBox(height: 16));
              }
            }

            return Column(children: rows);
          },
        ),
      ],
    );
  }

  List<Widget> _buildCharts() {
    final charts = <Widget>[];

    // User Distribution by Role
    if (userStats != null && userStats!.byRole.isNotEmpty) {
      charts.add(_buildUserRoleChart());
    }

    // Pet Distribution by Type
    if (petStats != null && petStats!.byType.isNotEmpty) {
      charts.add(_buildPetTypeChart());
    }

    // Appointment Status Distribution and Diseases - individual items (grid handles layout)
    final hasAppointments = appointmentStats != null && appointmentStats!.byStatus.isNotEmpty;
    final hasDiseases = topDiseases.isNotEmpty;

    if (hasAppointments) {
      charts.add(_buildAppointmentStatusChart());
    }
    if (hasDiseases) {
      charts.add(DiseasesPieChart(
        topDiseases: topDiseases,
        isLoading: isLoading,
      ));
    }

    return charts;
  }

  Widget _buildUserRoleChart() {
    final roleColors = {
      'user': AppColors.primary,
      'admin': AppColors.success,
      'super_admin': AppColors.warning,
      'clinic_admin': AppColors.info,
      'vet': AppColors.error.withValues(alpha: 0.8),
    };

    final data = userStats!.byRole.entries.map((entry) {
      return PieChartDataSection(
        label: _formatRoleLabel(entry.key),
        value: entry.value.toDouble(),
        color: roleColors[entry.key] ?? AppColors.textSecondary,
        displayValue: entry.value.toString(),
      );
    }).toList();

    return AnalyticsPieChart(
      title: 'User Distribution by Role',
      data: data,
      isLoading: isLoading,
      height: 320,
    );
  }

  Widget _buildPetTypeChart() {
    final typeColors = {
      'Dog': AppColors.primary,
      'Cat': AppColors.warning,
      'Bird': AppColors.info,
      'Rabbit': AppColors.success,
      'Hamster': AppColors.error.withValues(alpha: 0.7),
      'Guinea Pig': AppColors.textSecondary,
      'Fish': AppColors.primary.withValues(alpha: 0.7),
      'Reptile': AppColors.warning.withValues(alpha: 0.7),
      'Other': AppColors.textTertiary,
    };

    final data = petStats!.byType.entries.map((entry) {
      return PieChartDataSection(
        label: entry.key,
        value: entry.value.toDouble(),
        color: typeColors[entry.key] ?? AppColors.textSecondary,
        displayValue: entry.value.toString(),
      );
    }).toList();

    return AnalyticsPieChart(
      title: 'Pet Distribution by Type',
      data: data,
      isLoading: isLoading,
      height: 320,
    );
  }

  Widget _buildAppointmentStatusChart() {
    final statusColors = {
      'completed': AppColors.success,
      'pending': AppColors.warning,
      'confirmed': AppColors.info,
      'cancelled': AppColors.error,
      'rejected': AppColors.error.withValues(alpha: 0.7),
      'no_show': AppColors.textSecondary,
    };

    final data = appointmentStats!.byStatus.entries.map((entry) {
      return PieChartDataSection(
        label: _formatStatusLabel(entry.key),
        value: entry.value.toDouble(),
        color: statusColors[entry.key] ?? AppColors.textSecondary,
        displayValue: entry.value.toString(),
      );
    }).toList();

    return AnalyticsPieChart(
      title: 'Appointment Status Distribution',
      data: data,
      isLoading: isLoading,
      height: 320,
    );
  }

  String _formatRoleLabel(String role) {
    switch (role) {
      case 'user':
        return 'Pet Owners';
      case 'admin':
        return 'Clinic Admins';
      case 'super_admin':
        return 'Super Admins';
      case 'clinic_admin':
        return 'Clinic Staff';
      case 'vet':
        return 'Veterinarians';
      default:
        return role.split('_').map((word) => 
          word.substring(0, 1).toUpperCase() + word.substring(1)
        ).join(' ');
    }
  }

  String _formatStatusLabel(String status) {
    switch (status) {
      case 'completed':
        return 'Completed';
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'cancelled':
        return 'Cancelled';
      case 'rejected':
        return 'Rejected';
      case 'no_show':
        return 'No Show';
      default:
        return status.split('_').map((word) => 
          word.substring(0, 1).toUpperCase() + word.substring(1)
        ).join(' ');
    }
  }
}