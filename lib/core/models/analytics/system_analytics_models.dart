/// Enum for analytics time periods
enum AnalyticsPeriod {
  last7Days('Last 7 Days', 7),
  last30Days('Last 30 Days', 30),
  last90Days('Last 90 Days', 90),
  lastYear('Last Year', 365);

  const AnalyticsPeriod(this.label, this.days);
  final String label;
  final int days;
}

/// User statistics model
class UserStats {
  final int totalUsers;
  final int activeUsers;
  final int suspendedUsers;
  final int newUsers; // Within selected period
  final double growthRate; // Percentage change vs previous period
  final Map<String, int> byRole; // {user: 1100, admin: 42, super_admin: 3}

  const UserStats({
    required this.totalUsers,
    required this.activeUsers,
    required this.suspendedUsers,
    required this.newUsers,
    required this.growthRate,
    required this.byRole,
  });

  factory UserStats.empty() => const UserStats(
        totalUsers: 0,
        activeUsers: 0,
        suspendedUsers: 0,
        newUsers: 0,
        growthRate: 0.0,
        byRole: {},
      );

  Map<String, dynamic> toJson() => {
        'totalUsers': totalUsers,
        'activeUsers': activeUsers,
        'suspendedUsers': suspendedUsers,
        'newUsers': newUsers,
        'growthRate': growthRate,
        'byRole': byRole,
      };

  factory UserStats.fromJson(Map<String, dynamic> json) => UserStats(
        totalUsers: json['totalUsers'] ?? 0,
        activeUsers: json['activeUsers'] ?? 0,
        suspendedUsers: json['suspendedUsers'] ?? 0,
        newUsers: json['newUsers'] ?? 0,
        growthRate: json['growthRate']?.toDouble() ?? 0.0,
        byRole: Map<String, int>.from(json['byRole'] ?? {}),
      );
}

/// Clinic statistics model
class ClinicStats {
  final int totalClinics;
  final int activeClinics; // status = 'approved' && isVisible = true
  final int pendingClinics;
  final int rejectedClinics;
  final int suspendedClinics;
  final double approvalRate; // (approved / total applications) * 100
  final double growthRate; // Percentage change vs previous period
  final int newClinics; // Within selected period

  const ClinicStats({
    required this.totalClinics,
    required this.activeClinics,
    required this.pendingClinics,
    required this.rejectedClinics,
    required this.suspendedClinics,
    required this.approvalRate,
    required this.growthRate,
    required this.newClinics,
  });

  factory ClinicStats.empty() => const ClinicStats(
        totalClinics: 0,
        activeClinics: 0,
        pendingClinics: 0,
        rejectedClinics: 0,
        suspendedClinics: 0,
        approvalRate: 0.0,
        growthRate: 0.0,
        newClinics: 0,
      );

  Map<String, dynamic> toJson() => {
        'totalClinics': totalClinics,
        'activeClinics': activeClinics,
        'pendingClinics': pendingClinics,
        'rejectedClinics': rejectedClinics,
        'suspendedClinics': suspendedClinics,
        'approvalRate': approvalRate,
        'growthRate': growthRate,
        'newClinics': newClinics,
      };

  factory ClinicStats.fromJson(Map<String, dynamic> json) => ClinicStats(
        totalClinics: json['totalClinics'] ?? 0,
        activeClinics: json['activeClinics'] ?? 0,
        pendingClinics: json['pendingClinics'] ?? 0,
        rejectedClinics: json['rejectedClinics'] ?? 0,
        suspendedClinics: json['suspendedClinics'] ?? 0,
        approvalRate: json['approvalRate']?.toDouble() ?? 0.0,
        growthRate: json['growthRate']?.toDouble() ?? 0.0,
        newClinics: json['newClinics'] ?? 0,
      );
}

/// Appointment statistics model
class AppointmentStats {
  final int totalAppointments;
  final int completedAppointments;
  final int pendingAppointments;
  final int cancelledAppointments;
  final int rejectedAppointments;
  final double completionRate; // (completed / total) * 100
  final double cancellationRate; // (cancelled + rejected) / total * 100
  final double growthRate; // Percentage change vs previous period
  final int newAppointments; // Within selected period
  final Map<String, int> byStatus; // {pending: 50, completed: 200, ...}

  const AppointmentStats({
    required this.totalAppointments,
    required this.completedAppointments,
    required this.pendingAppointments,
    required this.cancelledAppointments,
    required this.rejectedAppointments,
    required this.completionRate,
    required this.cancellationRate,
    required this.growthRate,
    required this.newAppointments,
    required this.byStatus,
  });

  factory AppointmentStats.empty() => const AppointmentStats(
        totalAppointments: 0,
        completedAppointments: 0,
        pendingAppointments: 0,
        cancelledAppointments: 0,
        rejectedAppointments: 0,
        completionRate: 0.0,
        cancellationRate: 0.0,
        growthRate: 0.0,
        newAppointments: 0,
        byStatus: {},
      );

  Map<String, dynamic> toJson() => {
        'totalAppointments': totalAppointments,
        'completedAppointments': completedAppointments,
        'pendingAppointments': pendingAppointments,
        'cancelledAppointments': cancelledAppointments,
        'rejectedAppointments': rejectedAppointments,
        'completionRate': completionRate,
        'cancellationRate': cancellationRate,
        'growthRate': growthRate,
        'newAppointments': newAppointments,
        'byStatus': byStatus,
      };

  factory AppointmentStats.fromJson(Map<String, dynamic> json) =>
      AppointmentStats(
        totalAppointments: json['totalAppointments'] ?? 0,
        completedAppointments: json['completedAppointments'] ?? 0,
        pendingAppointments: json['pendingAppointments'] ?? 0,
        cancelledAppointments: json['cancelledAppointments'] ?? 0,
        rejectedAppointments: json['rejectedAppointments'] ?? 0,
        completionRate: json['completionRate']?.toDouble() ?? 0.0,
        cancellationRate: json['cancellationRate']?.toDouble() ?? 0.0,
        growthRate: json['growthRate']?.toDouble() ?? 0.0,
        newAppointments: json['newAppointments'] ?? 0,
        byStatus: Map<String, int>.from(json['byStatus'] ?? {}),
      );
}

/// AI usage statistics model
class AIUsageStats {
  final int totalScans;
  final int newScans; // Within selected period
  final int highConfidenceScans; // confidence > 80%
  final double avgConfidence; // Average confidence score (0-100)
  final double growthRate; // Percentage change vs previous period
  final int scanToAppointmentConversions; // Users who booked after scan

  const AIUsageStats({
    required this.totalScans,
    required this.newScans,
    required this.highConfidenceScans,
    required this.avgConfidence,
    required this.growthRate,
    required this.scanToAppointmentConversions,
  });

  factory AIUsageStats.empty() => const AIUsageStats(
        totalScans: 0,
        newScans: 0,
        highConfidenceScans: 0,
        avgConfidence: 0.0,
        growthRate: 0.0,
        scanToAppointmentConversions: 0,
      );

  Map<String, dynamic> toJson() => {
        'totalScans': totalScans,
        'newScans': newScans,
        'highConfidenceScans': highConfidenceScans,
        'avgConfidence': avgConfidence,
        'growthRate': growthRate,
        'scanToAppointmentConversions': scanToAppointmentConversions,
      };

  factory AIUsageStats.fromJson(Map<String, dynamic> json) => AIUsageStats(
        totalScans: json['totalScans'] ?? 0,
        newScans: json['newScans'] ?? 0,
        highConfidenceScans: json['highConfidenceScans'] ?? 0,
        avgConfidence: json['avgConfidence']?.toDouble() ?? 0.0,
        growthRate: json['growthRate']?.toDouble() ?? 0.0,
        scanToAppointmentConversions:
            json['scanToAppointmentConversions'] ?? 0,
      );
}

/// Pet statistics model
class PetStats {
  final int totalPets;
  final int newPets; // Within selected period
  final double growthRate; // Percentage change vs previous period
  final Map<String, int> byType; // {Dog: 1489, Cat: 628, ...}
  final int dogsCount;
  final int catsCount;
  final int othersCount;

  const PetStats({
    required this.totalPets,
    required this.newPets,
    required this.growthRate,
    required this.byType,
    required this.dogsCount,
    required this.catsCount,
    required this.othersCount,
  });

  factory PetStats.empty() => const PetStats(
        totalPets: 0,
        newPets: 0,
        growthRate: 0.0,
        byType: {},
        dogsCount: 0,
        catsCount: 0,
        othersCount: 0,
      );

  Map<String, dynamic> toJson() => {
        'totalPets': totalPets,
        'newPets': newPets,
        'growthRate': growthRate,
        'byType': byType,
        'dogsCount': dogsCount,
        'catsCount': catsCount,
        'othersCount': othersCount,
      };

  factory PetStats.fromJson(Map<String, dynamic> json) => PetStats(
        totalPets: json['totalPets'] ?? 0,
        newPets: json['newPets'] ?? 0,
        growthRate: json['growthRate']?.toDouble() ?? 0.0,
        byType: Map<String, int>.from(json['byType'] ?? {}),
        dogsCount: json['dogsCount'] ?? 0,
        catsCount: json['catsCount'] ?? 0,
        othersCount: json['othersCount'] ?? 0,
      );
}

/// System health score model (composite metric)
class SystemHealthScore {
  final double score; // 0-100
  final double userActivityScore; // 0-100
  final double appointmentCompletionScore; // 0-100
  final double aiConfidenceScore; // 0-100
  final List<String> issues; // Health warnings
  final DateTime lastCalculated;

  const SystemHealthScore({
    required this.score,
    required this.userActivityScore,
    required this.appointmentCompletionScore,
    required this.aiConfidenceScore,
    required this.issues,
    required this.lastCalculated,
  });

  factory SystemHealthScore.empty() => SystemHealthScore(
        score: 0.0,
        userActivityScore: 0.0,
        appointmentCompletionScore: 0.0,
        aiConfidenceScore: 0.0,
        issues: [],
        lastCalculated: DateTime.now(),
      );

  /// Calculate composite health score
  /// Formula: userActivity*0.3 + appointmentCompletion*0.4 + aiConfidence*0.3
  static SystemHealthScore calculate({
    required double userActivityScore,
    required double appointmentCompletionScore,
    required double aiConfidenceScore,
  }) {
    final score = (userActivityScore * 0.3) +
        (appointmentCompletionScore * 0.4) +
        (aiConfidenceScore * 0.3);

    final issues = <String>[];
    if (userActivityScore < 60) issues.add('Low user activity');
    if (appointmentCompletionScore < 70)
      issues.add('Low appointment completion rate');
    if (aiConfidenceScore < 75) issues.add('Low AI confidence scores');

    return SystemHealthScore(
      score: score,
      userActivityScore: userActivityScore,
      appointmentCompletionScore: appointmentCompletionScore,
      aiConfidenceScore: aiConfidenceScore,
      issues: issues,
      lastCalculated: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'score': score,
        'userActivityScore': userActivityScore,
        'appointmentCompletionScore': appointmentCompletionScore,
        'aiConfidenceScore': aiConfidenceScore,
        'issues': issues,
        'lastCalculated': lastCalculated.toIso8601String(),
      };

  factory SystemHealthScore.fromJson(Map<String, dynamic> json) =>
      SystemHealthScore(
        score: json['score']?.toDouble() ?? 0.0,
        userActivityScore: json['userActivityScore']?.toDouble() ?? 0.0,
        appointmentCompletionScore:
            json['appointmentCompletionScore']?.toDouble() ?? 0.0,
        aiConfidenceScore: json['aiConfidenceScore']?.toDouble() ?? 0.0,
        issues: List<String>.from(json['issues'] ?? []),
        lastCalculated: DateTime.parse(
            json['lastCalculated'] ?? DateTime.now().toIso8601String()),
      );
}

/// Time series data for charts
class TimeSeriesData {
  final String date; // YYYY-MM-DD
  final int value;
  final String label; // Optional label for display

  const TimeSeriesData({
    required this.date,
    required this.value,
    this.label = '',
  });

  factory TimeSeriesData.empty() => TimeSeriesData(
        date: DateTime.now().toIso8601String().split('T')[0],
        value: 0,
      );

  Map<String, dynamic> toJson() => {
        'date': date,
        'value': value,
        'label': label,
      };

  factory TimeSeriesData.fromJson(Map<String, dynamic> json) => TimeSeriesData(
        date: json['date'] ?? '',
        value: json['value'] ?? 0,
        label: json['label'] ?? '',
      );
}

/// Clinic performance model for rankings
class ClinicPerformance {
  final String clinicId;
  final String clinicName;
  final int appointmentCount;
  final double completionRate; // 0-100
  final double score; // appointmentCount * (completionRate / 100)
  final double averageRating; // 0-5.0 from clinic ratings
  final int totalRatings; // Number of ratings
  final int rank; // 1, 2, 3, ...

  const ClinicPerformance({
    required this.clinicId,
    required this.clinicName,
    required this.appointmentCount,
    required this.completionRate,
    required this.score,
    this.averageRating = 0.0,
    this.totalRatings = 0,
    required this.rank,
  });

  factory ClinicPerformance.empty() => const ClinicPerformance(
        clinicId: '',
        clinicName: '',
        appointmentCount: 0,
        completionRate: 0.0,
        score: 0.0,
        averageRating: 0.0,
        totalRatings: 0,
        rank: 0,
      );

  Map<String, dynamic> toJson() => {
        'clinicId': clinicId,
        'clinicName': clinicName,
        'appointmentCount': appointmentCount,
        'completionRate': completionRate,
        'score': score,
        'averageRating': averageRating,
        'totalRatings': totalRatings,
        'rank': rank,
      };

  factory ClinicPerformance.fromJson(Map<String, dynamic> json) =>
      ClinicPerformance(
        clinicId: json['clinicId'] ?? '',
        clinicName: json['clinicName'] ?? '',
        appointmentCount: json['appointmentCount'] ?? 0,
        completionRate: json['completionRate']?.toDouble() ?? 0.0,
        score: json['score']?.toDouble() ?? 0.0,
        averageRating: json['averageRating']?.toDouble() ?? 0.0,
        totalRatings: json['totalRatings'] ?? 0,
        rank: json['rank'] ?? 0,
      );
}

/// Clinic alert model for underperforming clinics
class ClinicAlert {
  final String clinicId;
  final String clinicName;
  final String alertType; // 'low_completion', 'high_cancellation', 'no_appointments'
  final String message;
  final Map<String, dynamic> details; // Additional context

  const ClinicAlert({
    required this.clinicId,
    required this.clinicName,
    required this.alertType,
    required this.message,
    required this.details,
  });

  factory ClinicAlert.empty() => const ClinicAlert(
        clinicId: '',
        clinicName: '',
        alertType: '',
        message: '',
        details: {},
      );

  Map<String, dynamic> toJson() => {
        'clinicId': clinicId,
        'clinicName': clinicName,
        'alertType': alertType,
        'message': message,
        'details': details,
      };

  factory ClinicAlert.fromJson(Map<String, dynamic> json) => ClinicAlert(
        clinicId: json['clinicId'] ?? '',
        clinicName: json['clinicName'] ?? '',
        alertType: json['alertType'] ?? '',
        message: json['message'] ?? '',
        details: Map<String, dynamic>.from(json['details'] ?? {}),
      );
}

/// Disease detection data model
class DiseaseData {
  final String diseaseName;
  final int count; // Number of detections
  final double percentage; // % of total detections

  const DiseaseData({
    required this.diseaseName,
    required this.count,
    required this.percentage,
  });

  factory DiseaseData.empty() => const DiseaseData(
        diseaseName: '',
        count: 0,
        percentage: 0.0,
      );

  Map<String, dynamic> toJson() => {
        'diseaseName': diseaseName,
        'count': count,
        'percentage': percentage,
      };

  factory DiseaseData.fromJson(Map<String, dynamic> json) => DiseaseData(
        diseaseName: json['diseaseName'] ?? '',
        count: json['count'] ?? 0,
        percentage: json['percentage']?.toDouble() ?? 0.0,
      );
}
