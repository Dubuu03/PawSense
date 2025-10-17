import 'package:flutter/material.dart';
import '../../../core/models/analytics/system_analytics_models.dart';
import '../../../core/services/super_admin/system_analytics_service.dart';
import '../../../core/utils/app_colors.dart';
import '../../../core/utils/constants.dart';
import '../../../core/widgets/shared/page_header.dart';
import '../../../core/widgets/super_admin/analytics/kpi_card.dart';
import '../../../core/widgets/super_admin/analytics/analytics_filters.dart';
import '../../../core/widgets/super_admin/analytics/growth_trend_chart.dart';

class SystemAnalyticsScreen extends StatefulWidget {
  const SystemAnalyticsScreen({super.key});

  @override
  State<SystemAnalyticsScreen> createState() => _SystemAnalyticsScreenState();
}

class _SystemAnalyticsScreenState extends State<SystemAnalyticsScreen> {
  AnalyticsPeriod selectedPeriod = AnalyticsPeriod.last30Days;
  bool isLoading = true;
  DateTime? lastUpdated;

  // KPI Data
  UserStats? userStats;
  ClinicStats? clinicStats;
  AppointmentStats? appointmentStats;
  AIUsageStats? aiStats;
  PetStats? petStats;
  SystemHealthScore? systemHealth;

  // Chart Data
  List<TimeSeriesData> userTrend = [];
  List<TimeSeriesData> clinicTrend = [];
  List<TimeSeriesData> petTrend = [];

  // Table Data
  List<ClinicPerformance> topClinics = [];
  List<ClinicAlert> clinicAlerts = [];
  List<DiseaseData> topDiseases = [];

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Load KPIs in parallel
      final results = await Future.wait([
        SystemAnalyticsService.getUserStats(selectedPeriod),
        SystemAnalyticsService.getClinicStats(selectedPeriod),
        SystemAnalyticsService.getAppointmentStats(selectedPeriod),
        SystemAnalyticsService.getAIUsageStats(selectedPeriod),
        SystemAnalyticsService.getPetStats(selectedPeriod),
        SystemAnalyticsService.getSystemHealth(),
      ]);

      // Load chart data
      final trendResults = await Future.wait([
        SystemAnalyticsService.getUserGrowthTrend(selectedPeriod),
        SystemAnalyticsService.getClinicGrowthTrend(selectedPeriod),
        SystemAnalyticsService.getPetGrowthTrend(selectedPeriod),
      ]);

      // Load table data
      final tableResults = await Future.wait([
        SystemAnalyticsService.getTopClinicsByAppointments(limit: 10),
        SystemAnalyticsService.getClinicsNeedingAttention(),
        SystemAnalyticsService.getTopDetectedDiseases(limit: 10),
      ]);

      if (mounted) {
        setState(() {
          userStats = results[0] as UserStats;
          clinicStats = results[1] as ClinicStats;
          appointmentStats = results[2] as AppointmentStats;
          aiStats = results[3] as AIUsageStats;
          petStats = results[4] as PetStats;
          systemHealth = results[5] as SystemHealthScore;

          userTrend = trendResults[0];
          clinicTrend = trendResults[1];
          petTrend = trendResults[2];

          topClinics = tableResults[0] as List<ClinicPerformance>;
          clinicAlerts = tableResults[1] as List<ClinicAlert>;
          topDiseases = tableResults[2] as List<DiseaseData>;

          isLoading = false;
          lastUpdated = DateTime.now();
        });
      }
    } catch (e) {
      print('Error loading analytics: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading analytics: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _onPeriodChanged(AnalyticsPeriod newPeriod) {
    setState(() {
      selectedPeriod = newPeriod;
    });
    _loadAnalyticsData();
  }

  void _onRefresh() {
    SystemAnalyticsService.clearCache();
    _loadAnalyticsData();
  }

  void _onExport() {
    // TODO: Implement export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export functionality coming soon!'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                kSpacingLarge, kSpacingLarge, kSpacingLarge, 0),
            child: const PageHeader(
              title: 'System Analytics',
              subtitle: 'Comprehensive system performance and usage analytics',
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(kSpacingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filters
                  AnalyticsFilters(
                    selectedPeriod: selectedPeriod,
                    onPeriodChanged: _onPeriodChanged,
                    onRefresh: _onRefresh,
                    onExport: _onExport,
                    isLoading: isLoading,
                    lastUpdated: lastUpdated,
                  ),

                  const SizedBox(height: kSpacingLarge),

                  // KPI Cards Grid
                  _buildKPIGrid(),

                  const SizedBox(height: kSpacingLarge),

                  // Growth Trends Chart - with responsive height
                  Container(
                    constraints: BoxConstraints(
                      minHeight: 300,
                      maxHeight: MediaQuery.of(context).size.height * 0.5,
                    ),
                    child: GrowthTrendChart(
                      userTrend: userTrend,
                      clinicTrend: clinicTrend,
                      petTrend: petTrend,
                      isLoading: isLoading,
                    ),
                  ),

                  const SizedBox(height: kSpacingLarge),

                  // Additional Analytics - with empty state messages
                  if (!isLoading && topClinics.isEmpty && clinicAlerts.isEmpty && topDiseases.isEmpty)
                    _buildEmptyState(),

                  if (!isLoading && topClinics.isNotEmpty)
                    _buildTopClinicsTable(),

                  if (!isLoading && clinicAlerts.isNotEmpty) ...[
                    const SizedBox(height: kSpacingLarge),
                    _buildClinicsNeedingAttention(),
                  ],

                  if (!isLoading && topDiseases.isNotEmpty) ...[
                    const SizedBox(height: kSpacingLarge),
                    _buildTopDiseasesChart(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 64,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Detailed Analytics Available Yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Start by adding clinics, registering pets, and booking appointments.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKPIGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine grid columns based on width
        int crossAxisCount = 3;
        if (constraints.maxWidth < 1200) crossAxisCount = 2;
        if (constraints.maxWidth < 800) crossAxisCount = 1;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: kSpacingLarge,
          mainAxisSpacing: kSpacingLarge,
          childAspectRatio: 2.5, // Increased from 2.2 to prevent overflow
          children: [
            // Users KPI
            KPICard(
              icon: Icons.people,
              title: 'TOTAL USERS',
              value: userStats?.totalUsers.toString() ?? '0',
              changeText: userStats != null && userStats!.totalUsers > 0
                  ? '${userStats!.growthRate.toStringAsFixed(1)}% vs last period'
                  : 'No users yet',
              isPositive: (userStats?.growthRate ?? 0) >= 0,
              secondaryValue: userStats != null && userStats!.totalUsers > 0
                  ? '${userStats!.activeUsers} Active'
                  : null,
              tertiaryValue: userStats != null && userStats!.suspendedUsers > 0
                  ? '${userStats!.suspendedUsers} Suspended'
                  : null,
              color: AppColors.primary,
              isLoading: isLoading,
            ),

            // Clinics KPI
            KPICard(
              icon: Icons.local_hospital,
              title: 'ACTIVE CLINICS',
              value: clinicStats?.activeClinics.toString() ?? '0',
              changeText: clinicStats != null && clinicStats!.totalClinics > 0
                  ? '${clinicStats!.approvalRate.toStringAsFixed(0)}% approval rate'
                  : 'No clinics registered',
              isPositive: (clinicStats?.approvalRate ?? 0) >= 50,
              secondaryValue: clinicStats != null && clinicStats!.pendingClinics > 0
                  ? '${clinicStats!.pendingClinics} Pending approval'
                  : clinicStats != null && clinicStats!.totalClinics > 0
                      ? 'All clinics processed'
                      : null,
              color: AppColors.success,
              isLoading: isLoading,
            ),

            // Appointments KPI
            KPICard(
              icon: Icons.calendar_today,
              title: 'TOTAL APPOINTMENTS',
              value: appointmentStats?.totalAppointments.toString() ?? '0',
              changeText: appointmentStats != null && appointmentStats!.totalAppointments > 0
                  ? '${appointmentStats!.completionRate.toStringAsFixed(0)}% completion rate'
                  : 'No appointments yet',
              isPositive: (appointmentStats?.completionRate ?? 0) >= 70,
              secondaryValue: appointmentStats != null && appointmentStats!.totalAppointments > 0
                  ? '${appointmentStats!.completedAppointments} Completed'
                  : null,
              tertiaryValue: appointmentStats != null && appointmentStats!.totalAppointments > 0
                  ? '${appointmentStats!.cancelledAppointments} Cancelled'
                  : null,
              color: AppColors.info,
              isLoading: isLoading,
            ),

            // AI Scans KPI
            KPICard(
              icon: Icons.psychology,
              title: 'AI SCANS',
              value: aiStats?.totalScans.toString() ?? '0',
              changeText: aiStats != null && aiStats!.totalScans > 0
                  ? '${aiStats!.avgConfidence.toStringAsFixed(1)}% avg confidence'
                  : 'No AI scans performed',
              isPositive: (aiStats?.avgConfidence ?? 0) >= 75,
              secondaryValue: aiStats != null && aiStats!.totalScans > 0
                  ? '${aiStats!.highConfidenceScans} High Confidence (80%+)'
                  : null,
              tertiaryValue: aiStats != null && aiStats!.scanToAppointmentConversions > 0
                  ? '${aiStats!.scanToAppointmentConversions} Led to appointments'
                  : null,
              color: AppColors.warning,
              isLoading: isLoading,
            ),

            // Pets KPI
            KPICard(
              icon: Icons.pets,
              title: 'REGISTERED PETS',
              value: petStats?.totalPets.toString() ?? '0',
              changeText: petStats != null && petStats!.totalPets > 0
                  ? '${petStats!.newPets} new in period'
                  : 'No pets registered',
              isPositive: (petStats?.growthRate ?? 0) >= 0,
              secondaryValue: petStats != null && petStats!.totalPets > 0
                  ? '${petStats!.dogsCount} Dogs (${((petStats!.dogsCount / petStats!.totalPets) * 100).toStringAsFixed(0)}%)'
                  : null,
              tertiaryValue: petStats != null && petStats!.totalPets > 0
                  ? '${petStats!.catsCount} Cats (${((petStats!.catsCount / petStats!.totalPets) * 100).toStringAsFixed(0)}%)'
                  : null,
              color: AppColors.warning.withValues(alpha: 0.8),
              isLoading: isLoading,
            ),

            // System Health KPI
            KPICard(
              icon: Icons.health_and_safety,
              title: 'SYSTEM HEALTH',
              value: systemHealth != null
                  ? '${systemHealth!.score.toStringAsFixed(1)}%'
                  : '100%',
              changeText: systemHealth != null
                  ? _getHealthStatus(systemHealth!.score)
                  : 'Calculating...',
              isPositive: (systemHealth?.score ?? 100) >= 75,
              secondaryValue: systemHealth != null
                  ? 'User Activity: ${systemHealth!.userActivityScore.toStringAsFixed(0)}%'
                  : null,
              tertiaryValue: systemHealth != null
                  ? 'AI Confidence: ${systemHealth!.aiConfidenceScore.toStringAsFixed(0)}%'
                  : null,
              color: _getHealthColor(systemHealth?.score ?? 100),
              isLoading: isLoading,
            ),
          ],
        );
      },
    );
  }

  Widget _buildTopClinicsTable() {
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
        children: [
          const Text(
            'Top Performing Clinics',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Table(
            columnWidths: const {
              0: FixedColumnWidth(50),
              1: FlexColumnWidth(2),
              2: FlexColumnWidth(1),
              3: FlexColumnWidth(1),
              4: FlexColumnWidth(1),
            },
            children: [
              const TableRow(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.border),
                  ),
                ),
                children: [
                  Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text('Rank',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text('Clinic',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text('Appointments',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text('Completion',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text('Score',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              ...topClinics.take(10).map((clinic) => TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          clinic.rank <= 3
                              ? ['🥇', '🥈', '🥉'][clinic.rank - 1]
                              : '#${clinic.rank}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(clinic.clinicName),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(clinic.appointmentCount.toString()),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                            '${clinic.completionRate.toStringAsFixed(0)}%'),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child:
                            Text(clinic.score.toStringAsFixed(1)),
                      ),
                    ],
                  )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClinicsNeedingAttention() {
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
          const Text(
            'Clinics Needing Attention',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: clinicAlerts.take(5).length,
            itemBuilder: (context, index) {
              final alert = clinicAlerts[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      alert.alertType == 'no_appointments'
                          ? Icons.warning
                          : Icons.trending_down,
                      color: AppColors.error,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            alert.clinicName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            alert.message,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTopDiseasesChart() {
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
        children: [
          const Text(
            'Top Detected Diseases',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: topDiseases.take(10).length,
            itemBuilder: (context, index) {
              final disease = topDiseases[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            disease.diseaseName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${disease.count} (${disease.percentage.toStringAsFixed(1)}%)',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: disease.percentage / 100,
                        minHeight: 8,
                        backgroundColor: AppColors.border.withValues(alpha: 0.3),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getDiseaseColor(disease.percentage),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Color _getDiseaseColor(double percentage) {
    if (percentage >= 30) return AppColors.error;
    if (percentage >= 15) return AppColors.warning;
    return AppColors.primary;
  }

  // Helper method to get health status text
  String _getHealthStatus(double score) {
    if (score >= 90) return 'Excellent - All systems optimal';
    if (score >= 75) return 'Good - Minor issues';
    if (score >= 60) return 'Fair - Monitor closely';
    return 'Poor - Needs attention';
  }

  // Helper method to get health status color
  Color _getHealthColor(double score) {
    if (score >= 90) return AppColors.success;
    if (score >= 75) return AppColors.info;
    if (score >= 60) return AppColors.warning;
    return AppColors.error;
  }
}
