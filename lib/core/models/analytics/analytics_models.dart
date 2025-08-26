// Analytics Data Models for System Analytics Screen

class SystemAnalyticsModel {
  final OverviewMetrics overview;
  final UserAnalytics userAnalytics;
  final ClinicPerformance clinicPerformance;
  final AppointmentAnalytics appointmentAnalytics;
  final SystemPerformance systemPerformance;
  final RevenueAnalytics revenueAnalytics;
  final DateTime lastUpdated;

  SystemAnalyticsModel({
    required this.overview,
    required this.userAnalytics,
    required this.clinicPerformance,
    required this.appointmentAnalytics,
    required this.systemPerformance,
    required this.revenueAnalytics,
    required this.lastUpdated,
  });

  factory SystemAnalyticsModel.fromJson(Map<String, dynamic> json) {
    return SystemAnalyticsModel(
      overview: OverviewMetrics.fromJson(json['overview'] ?? {}),
      userAnalytics: UserAnalytics.fromJson(json['userAnalytics'] ?? {}),
      clinicPerformance: ClinicPerformance.fromJson(json['clinicPerformance'] ?? {}),
      appointmentAnalytics: AppointmentAnalytics.fromJson(json['appointmentAnalytics'] ?? {}),
      systemPerformance: SystemPerformance.fromJson(json['systemPerformance'] ?? {}),
      revenueAnalytics: RevenueAnalytics.fromJson(json['revenueAnalytics'] ?? {}),
      lastUpdated: DateTime.parse(json['lastUpdated'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class OverviewMetrics {
  final int totalUsers;
  final double userGrowthPercentage;
  final int activeClinics;
  final int totalClinics;
  final int totalAppointments;
  final double appointmentTrend;
  final double systemUptime;
  final SystemHealthStatus healthStatus;

  OverviewMetrics({
    required this.totalUsers,
    required this.userGrowthPercentage,
    required this.activeClinics,
    required this.totalClinics,
    required this.totalAppointments,
    required this.appointmentTrend,
    required this.systemUptime,
    required this.healthStatus,
  });

  factory OverviewMetrics.fromJson(Map<String, dynamic> json) {
    return OverviewMetrics(
      totalUsers: json['totalUsers'] ?? 0,
      userGrowthPercentage: (json['userGrowthPercentage'] ?? 0.0).toDouble(),
      activeClinics: json['activeClinics'] ?? 0,
      totalClinics: json['totalClinics'] ?? 0,
      totalAppointments: json['totalAppointments'] ?? 0,
      appointmentTrend: (json['appointmentTrend'] ?? 0.0).toDouble(),
      systemUptime: (json['systemUptime'] ?? 99.0).toDouble(),
      healthStatus: SystemHealthStatus.values.firstWhere(
        (status) => status.name == json['healthStatus'],
        orElse: () => SystemHealthStatus.good,
      ),
    );
  }
}

class UserAnalytics {
  final List<TrendDataPoint> registrationTrends;
  final Map<String, int> userTypeDistribution;
  final List<ActivityHeatmapData> activityHeatmap;
  final List<TrendDataPoint> activeSessions;

  UserAnalytics({
    required this.registrationTrends,
    required this.userTypeDistribution,
    required this.activityHeatmap,
    required this.activeSessions,
  });

  factory UserAnalytics.fromJson(Map<String, dynamic> json) {
    return UserAnalytics(
      registrationTrends: (json['registrationTrends'] as List<dynamic>?)
          ?.map((e) => TrendDataPoint.fromJson(e))
          .toList() ?? [],
      userTypeDistribution: Map<String, int>.from(json['userTypeDistribution'] ?? {}),
      activityHeatmap: (json['activityHeatmap'] as List<dynamic>?)
          ?.map((e) => ActivityHeatmapData.fromJson(e))
          .toList() ?? [],
      activeSessions: (json['activeSessions'] as List<dynamic>?)
          ?.map((e) => TrendDataPoint.fromJson(e))
          .toList() ?? [],
    );
  }
}

class ClinicPerformance {
  final List<TrendDataPoint> registrationTrends;
  final Map<String, int> geographicDistribution;
  final Map<String, double> utilizationRates;
  final Map<String, int> servicePopularity;

  ClinicPerformance({
    required this.registrationTrends,
    required this.geographicDistribution,
    required this.utilizationRates,
    required this.servicePopularity,
  });

  factory ClinicPerformance.fromJson(Map<String, dynamic> json) {
    return ClinicPerformance(
      registrationTrends: (json['registrationTrends'] as List<dynamic>?)
          ?.map((e) => TrendDataPoint.fromJson(e))
          .toList() ?? [],
      geographicDistribution: Map<String, int>.from(json['geographicDistribution'] ?? {}),
      utilizationRates: Map<String, double>.from(json['utilizationRates'] ?? {}),
      servicePopularity: Map<String, int>.from(json['servicePopularity'] ?? {}),
    );
  }
}

class AppointmentAnalytics {
  final List<TrendDataPoint> volumeTrends;
  final Map<int, int> peakHours; // hour -> count
  final Map<String, int> appointmentTypes;
  final double cancellationRate;
  final double noShowRate;

  AppointmentAnalytics({
    required this.volumeTrends,
    required this.peakHours,
    required this.appointmentTypes,
    required this.cancellationRate,
    required this.noShowRate,
  });

  factory AppointmentAnalytics.fromJson(Map<String, dynamic> json) {
    return AppointmentAnalytics(
      volumeTrends: (json['volumeTrends'] as List<dynamic>?)
          ?.map((e) => TrendDataPoint.fromJson(e))
          .toList() ?? [],
      peakHours: Map<int, int>.from(json['peakHours'] ?? {}),
      appointmentTypes: Map<String, int>.from(json['appointmentTypes'] ?? {}),
      cancellationRate: (json['cancellationRate'] ?? 0.0).toDouble(),
      noShowRate: (json['noShowRate'] ?? 0.0).toDouble(),
    );
  }
}

class SystemPerformance {
  final double avgResponseTime;
  final double errorRate;
  final double databasePerformance;
  final double storageUsage;
  final List<TrendDataPoint> responseTimeTrends;
  final List<TrendDataPoint> errorRateTrends;

  SystemPerformance({
    required this.avgResponseTime,
    required this.errorRate,
    required this.databasePerformance,
    required this.storageUsage,
    required this.responseTimeTrends,
    required this.errorRateTrends,
  });

  factory SystemPerformance.fromJson(Map<String, dynamic> json) {
    return SystemPerformance(
      avgResponseTime: (json['avgResponseTime'] ?? 0.0).toDouble(),
      errorRate: (json['errorRate'] ?? 0.0).toDouble(),
      databasePerformance: (json['databasePerformance'] ?? 100.0).toDouble(),
      storageUsage: (json['storageUsage'] ?? 0.0).toDouble(),
      responseTimeTrends: (json['responseTimeTrends'] as List<dynamic>?)
          ?.map((e) => TrendDataPoint.fromJson(e))
          .toList() ?? [],
      errorRateTrends: (json['errorRateTrends'] as List<dynamic>?)
          ?.map((e) => TrendDataPoint.fromJson(e))
          .toList() ?? [],
    );
  }
}

class RevenueAnalytics {
  final List<TrendDataPoint> revenueTrends;
  final Map<String, double> serviceRevenue;
  final double avgAppointmentValue;
  final Map<String, double> paymentMethods;

  RevenueAnalytics({
    required this.revenueTrends,
    required this.serviceRevenue,
    required this.avgAppointmentValue,
    required this.paymentMethods,
  });

  factory RevenueAnalytics.fromJson(Map<String, dynamic> json) {
    return RevenueAnalytics(
      revenueTrends: (json['revenueTrends'] as List<dynamic>?)
          ?.map((e) => TrendDataPoint.fromJson(e))
          .toList() ?? [],
      serviceRevenue: Map<String, double>.from(json['serviceRevenue'] ?? {}),
      avgAppointmentValue: (json['avgAppointmentValue'] ?? 0.0).toDouble(),
      paymentMethods: Map<String, double>.from(json['paymentMethods'] ?? {}),
    );
  }
}

// Supporting Data Models
class TrendDataPoint {
  final DateTime date;
  final double value;
  final String? label;

  TrendDataPoint({
    required this.date,
    required this.value,
    this.label,
  });

  factory TrendDataPoint.fromJson(Map<String, dynamic> json) {
    return TrendDataPoint(
      date: DateTime.parse(json['date']),
      value: (json['value'] ?? 0.0).toDouble(),
      label: json['label'],
    );
  }
}

class ActivityHeatmapData {
  final int hour;
  final int dayOfWeek;
  final int intensity;

  ActivityHeatmapData({
    required this.hour,
    required this.dayOfWeek,
    required this.intensity,
  });

  factory ActivityHeatmapData.fromJson(Map<String, dynamic> json) {
    return ActivityHeatmapData(
      hour: json['hour'] ?? 0,
      dayOfWeek: json['dayOfWeek'] ?? 0,
      intensity: json['intensity'] ?? 0,
    );
  }
}

// Enums
enum SystemHealthStatus { excellent, good, warning, critical }

enum DateRangeFilter { last7Days, last30Days, last90Days, custom }

class DateRangeData {
  final DateRangeFilter filter;
  final DateTime startDate;
  final DateTime endDate;
  final String displayName;

  DateRangeData({
    required this.filter,
    required this.startDate,
    required this.endDate,
    required this.displayName,
  });

  static DateRangeData getLast7Days() {
    final now = DateTime.now();
    return DateRangeData(
      filter: DateRangeFilter.last7Days,
      startDate: now.subtract(Duration(days: 7)),
      endDate: now,
      displayName: 'Last 7 Days',
    );
  }

  static DateRangeData getLast30Days() {
    final now = DateTime.now();
    return DateRangeData(
      filter: DateRangeFilter.last30Days,
      startDate: now.subtract(Duration(days: 30)),
      endDate: now,
      displayName: 'Last 30 Days',
    );
  }

  static DateRangeData getLast90Days() {
    final now = DateTime.now();
    return DateRangeData(
      filter: DateRangeFilter.last90Days,
      startDate: now.subtract(Duration(days: 90)),
      endDate: now,
      displayName: 'Last 90 Days',
    );
  }
}
