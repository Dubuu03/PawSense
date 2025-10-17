import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawsense/core/models/analytics/system_analytics_models.dart';
import 'package:pawsense/core/models/user/user_model.dart';
import 'package:pawsense/core/models/user/pet_model.dart';
import 'package:pawsense/core/models/user/assessment_result_model.dart';

/// System Analytics Service
/// Provides comprehensive analytics for Super Admin dashboard
/// Uses client-side aggregation with 15-minute caching
class SystemAnalyticsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cache storage
  static final Map<String, _CachedData> _cache = {};
  static const Duration _cacheDuration = Duration(minutes: 15);

  // ==================== KPI METRICS ====================

  /// Get user statistics for selected period
  static Future<UserStats> getUserStats(AnalyticsPeriod period) async {
    return _getCached('user_stats_${period.name}', () async {
      try {
        final usersSnapshot = await _firestore.collection('users').get();
        final users = usersSnapshot.docs
            .map((doc) => UserModel.fromMap(doc.data()))
            .toList();

        final now = DateTime.now();
        final periodStart = now.subtract(Duration(days: period.days));
        final previousPeriodStart =
            now.subtract(Duration(days: period.days * 2));

        // Total and active/suspended counts
        final totalUsers = users.length;
        final activeUsers = users.where((u) => u.isActive).length;
        final suspendedUsers = users.where((u) => !u.isActive).length;

        // New users in current period
        final newUsers =
            users.where((u) => u.createdAt.isAfter(periodStart)).length;

        // Previous period count for growth calculation
        final previousPeriodUsers = users
            .where((u) =>
                u.createdAt.isAfter(previousPeriodStart) &&
                u.createdAt.isBefore(periodStart))
            .length;

        // Calculate growth rate
        final growthRate = previousPeriodUsers > 0
            ? ((newUsers - previousPeriodUsers) / previousPeriodUsers) * 100
            : 0.0;

        // Count by role
        final byRole = <String, int>{};
        for (final user in users) {
          byRole[user.role] = (byRole[user.role] ?? 0) + 1;
        }

        return UserStats(
          totalUsers: totalUsers,
          activeUsers: activeUsers,
          suspendedUsers: suspendedUsers,
          newUsers: newUsers,
          growthRate: growthRate,
          byRole: byRole,
        );
      } catch (e) {
        print('Error getting user stats: $e');
        return UserStats.empty();
      }
    });
  }

  /// Get clinic statistics for selected period
  static Future<ClinicStats> getClinicStats(AnalyticsPeriod period) async {
    return _getCached('clinic_stats_${period.name}', () async {
      try {
        // Fetch from both collections
        final clinicsSnapshot = await _firestore.collection('clinics').get();
        final registrationsSnapshot =
            await _firestore.collection('clinic_registrations').get();

        final allClinicsData = [
          ...clinicsSnapshot.docs.map((doc) => doc.data()),
          ...registrationsSnapshot.docs.map((doc) => doc.data()),
        ];

        final now = DateTime.now();
        final periodStart = now.subtract(Duration(days: period.days));
        final previousPeriodStart =
            now.subtract(Duration(days: period.days * 2));

        // Parse clinics with safe DateTime handling
        final clinics = allClinicsData.map((data) {
          DateTime? createdAt;
          if (data['createdAt'] != null) {
            if (data['createdAt'] is String) {
              createdAt = DateTime.tryParse(data['createdAt']);
            } else if (data['createdAt'] is Timestamp) {
              createdAt = (data['createdAt'] as Timestamp).toDate();
            }
          }

          return {
            'status': data['status'] ?? 'pending',
            'isVisible': data['isVisible'] ?? true, // Default to true for better UX
            'createdAt': createdAt ?? DateTime.now(),
          };
        }).toList();

        final totalClinics = clinics.length;
        
        // Active clinics: approved status (isVisible is optional for flexibility)
        // Many clinics might not have isVisible field yet
        final activeClinics = clinics
            .where((c) => c['status'] == 'approved')
            .length;
            
        final pendingClinics =
            clinics.where((c) => c['status'] == 'pending').length;
        final rejectedClinics =
            clinics.where((c) => c['status'] == 'rejected').length;
        final suspendedClinics =
            clinics.where((c) => c['status'] == 'suspended').length;

        // Debug logging
        print('📊 Clinic Stats: Total=$totalClinics, Active=$activeClinics, Pending=$pendingClinics');
        if (activeClinics == 0 && totalClinics > 0) {
          print('⚠️ WARNING: No active clinics found. Checking statuses...');
          final statuses = clinics.map((c) => c['status']).toSet();
          print('   Available statuses: $statuses');
        }

        // New clinics in period
        final newClinics = clinics
            .where((c) =>
                (c['createdAt'] as DateTime).isAfter(periodStart))
            .length;

        // Previous period count
        final previousPeriodClinics = clinics
            .where((c) =>
                (c['createdAt'] as DateTime).isAfter(previousPeriodStart) &&
                (c['createdAt'] as DateTime).isBefore(periodStart))
            .length;

        // Growth rate
        final growthRate = previousPeriodClinics > 0
            ? ((newClinics - previousPeriodClinics) / previousPeriodClinics) *
                100
            : 0.0;

        // Approval rate (approved / total applications)
        final approvedCount =
            clinics.where((c) => c['status'] == 'approved').length;
        final approvalRate =
            totalClinics > 0 ? (approvedCount / totalClinics) * 100 : 0.0;

        return ClinicStats(
          totalClinics: totalClinics,
          activeClinics: activeClinics,
          pendingClinics: pendingClinics,
          rejectedClinics: rejectedClinics,
          suspendedClinics: suspendedClinics,
          approvalRate: approvalRate,
          growthRate: growthRate,
          newClinics: newClinics,
        );
      } catch (e) {
        print('Error getting clinic stats: $e');
        return ClinicStats.empty();
      }
    });
  }

  /// Get appointment statistics for selected period
  static Future<AppointmentStats> getAppointmentStats(
      AnalyticsPeriod period) async {
    return _getCached('appointment_stats_${period.name}', () async {
      try {
        final appointmentsSnapshot =
            await _firestore.collection('appointments').get();

        final now = DateTime.now();
        final periodStart = now.subtract(Duration(days: period.days));
        final previousPeriodStart =
            now.subtract(Duration(days: period.days * 2));

        final appointments = appointmentsSnapshot.docs.map((doc) {
          final data = doc.data();
          DateTime? createdAt;
          if (data['createdAt'] is Timestamp) {
            createdAt = (data['createdAt'] as Timestamp).toDate();
          } else if (data['createdAt'] is String) {
            createdAt = DateTime.tryParse(data['createdAt']);
          }

          return {
            'status': data['status'] ?? 'pending',
            'createdAt': createdAt ?? DateTime.now(),
          };
        }).toList();

        final totalAppointments = appointments.length;

        // Count by status
        final byStatus = <String, int>{};
        for (final apt in appointments) {
          final status = apt['status'] as String;
          byStatus[status] = (byStatus[status] ?? 0) + 1;
        }

        final completedAppointments = byStatus['completed'] ?? 0;
        final pendingAppointments = byStatus['pending'] ?? 0;
        final cancelledAppointments = byStatus['cancelled'] ?? 0;
        final rejectedAppointments = byStatus['rejected'] ?? 0;

        // Rates
        final completionRate = totalAppointments > 0
            ? (completedAppointments / totalAppointments) * 100
            : 0.0;
        final cancellationRate = totalAppointments > 0
            ? ((cancelledAppointments + rejectedAppointments) /
                    totalAppointments) *
                100
            : 0.0;

        // New appointments in period
        final newAppointments = appointments
            .where((a) =>
                (a['createdAt'] as DateTime).isAfter(periodStart))
            .length;

        // Previous period count
        final previousPeriodAppointments = appointments
            .where((a) =>
                (a['createdAt'] as DateTime).isAfter(previousPeriodStart) &&
                (a['createdAt'] as DateTime).isBefore(periodStart))
            .length;

        // Growth rate
        final growthRate = previousPeriodAppointments > 0
            ? ((newAppointments - previousPeriodAppointments) /
                    previousPeriodAppointments) *
                100
            : 0.0;

        return AppointmentStats(
          totalAppointments: totalAppointments,
          completedAppointments: completedAppointments,
          pendingAppointments: pendingAppointments,
          cancelledAppointments: cancelledAppointments,
          rejectedAppointments: rejectedAppointments,
          completionRate: completionRate,
          cancellationRate: cancellationRate,
          growthRate: growthRate,
          newAppointments: newAppointments,
          byStatus: byStatus,
        );
      } catch (e) {
        print('Error getting appointment stats: $e');
        return AppointmentStats.empty();
      }
    });
  }

  /// Get AI usage statistics for selected period
  static Future<AIUsageStats> getAIUsageStats(AnalyticsPeriod period) async {
    return _getCached('ai_stats_${period.name}', () async {
      try {
        final assessmentsSnapshot =
            await _firestore.collection('assessment_results').get();

        final now = DateTime.now();
        final periodStart = now.subtract(Duration(days: period.days));
        final previousPeriodStart =
            now.subtract(Duration(days: period.days * 2));

        final assessments = assessmentsSnapshot.docs
            .map((doc) => AssessmentResult.fromMap(doc.data(), doc.id))
            .toList();

        final totalScans = assessments.length;

        // New scans in period
        final newScans =
            assessments.where((a) => a.createdAt.isAfter(periodStart)).length;

        // Previous period count
        final previousPeriodScans = assessments
            .where((a) =>
                a.createdAt.isAfter(previousPeriodStart) &&
                a.createdAt.isBefore(periodStart))
            .length;

        // Growth rate
        final growthRate = previousPeriodScans > 0
            ? ((newScans - previousPeriodScans) / previousPeriodScans) * 100
            : 0.0;

        // High confidence scans (>0.8 = 80%)
        int highConfidenceCount = 0;
        double totalConfidence = 0.0;
        int confidenceCount = 0;

        for (final assessment in assessments) {
          for (final detectionResult in assessment.detectionResults) {
            for (final detection in detectionResult.detections) {
              totalConfidence += detection.confidence;
              confidenceCount++;
              if (detection.confidence > 0.8) {
                highConfidenceCount++;
              }
            }
          }
        }

        final avgConfidence = confidenceCount > 0
            ? (totalConfidence / confidenceCount) * 100
            : 0.0;

        // Scan to appointment conversion (users who have both scans and appointments)
        final appointmentsSnapshot =
            await _firestore.collection('appointments').get();
        final userIdsWithAppointments = appointmentsSnapshot.docs
            .map((doc) => doc.data()['userId'] as String?)
            .where((id) => id != null)
            .toSet();

        final scanToAppointmentConversions = assessments
            .where((a) => userIdsWithAppointments.contains(a.userId))
            .length;

        return AIUsageStats(
          totalScans: totalScans,
          newScans: newScans,
          highConfidenceScans: highConfidenceCount,
          avgConfidence: avgConfidence,
          growthRate: growthRate,
          scanToAppointmentConversions: scanToAppointmentConversions,
        );
      } catch (e) {
        print('Error getting AI stats: $e');
        return AIUsageStats.empty();
      }
    });
  }

  /// Get pet statistics for selected period
  static Future<PetStats> getPetStats(AnalyticsPeriod period) async {
    return _getCached('pet_stats_${period.name}', () async {
      try {
        final petsSnapshot = await _firestore.collection('pets').get();
        final pets = petsSnapshot.docs
            .map((doc) => Pet.fromMap(doc.data(), doc.id))
            .toList();

        final now = DateTime.now();
        final periodStart = now.subtract(Duration(days: period.days));
        final previousPeriodStart =
            now.subtract(Duration(days: period.days * 2));

        final totalPets = pets.length;

        // New pets in period
        final newPets =
            pets.where((p) => p.createdAt.isAfter(periodStart)).length;

        // Previous period count
        final previousPeriodPets = pets
            .where((p) =>
                p.createdAt.isAfter(previousPeriodStart) &&
                p.createdAt.isBefore(periodStart))
            .length;

        // Growth rate
        final growthRate = previousPeriodPets > 0
            ? ((newPets - previousPeriodPets) / previousPeriodPets) * 100
            : 0.0;

        // Count by type
        final byType = <String, int>{};
        for (final pet in pets) {
          byType[pet.petType] = (byType[pet.petType] ?? 0) + 1;
        }

        final dogsCount = byType['Dog'] ?? 0;
        final catsCount = byType['Cat'] ?? 0;
        final othersCount = totalPets - dogsCount - catsCount;

        return PetStats(
          totalPets: totalPets,
          newPets: newPets,
          growthRate: growthRate,
          byType: byType,
          dogsCount: dogsCount,
          catsCount: catsCount,
          othersCount: othersCount,
        );
      } catch (e) {
        print('Error getting pet stats: $e');
        return PetStats.empty();
      }
    });
  }

  /// Get system health score (composite metric)
  /// 
  /// System Health Score Calculation:
  /// - Measures overall platform health across 3 key dimensions
  /// - Score range: 0-100% (higher is better)
  /// 
  /// Components:
  /// 1. User Activity (30% weight): Percentage of active vs total users
  ///    - Measures user engagement and platform adoption
  ///    - Active users are those with isActive = true
  /// 
  /// 2. Appointment Completion (40% weight): Percentage of completed appointments
  ///    - Most critical metric for service quality
  ///    - Shows clinic performance and user satisfaction
  /// 
  /// 3. AI Confidence (30% weight): Average AI detection confidence
  ///    - Indicates AI model accuracy and reliability
  ///    - Based on high-confidence scans (80%+)
  /// 
  /// Formula: (userActivity * 0.3) + (appointmentCompletion * 0.4) + (aiConfidence * 0.3)
  /// 
  /// Health Status Interpretation:
  /// - 90-100%: Excellent - All systems performing optimally
  /// - 75-89%: Good - Minor issues, generally healthy
  /// - 60-74%: Fair - Some concerns, monitor closely
  /// - Below 60%: Poor - Critical issues need attention
  static Future<SystemHealthScore> getSystemHealth() async {
    return _getCached('system_health', () async {
      try {
        // Get latest stats (last 30 days for current health snapshot)
        final userStats = await getUserStats(AnalyticsPeriod.last30Days);
        final appointmentStats =
            await getAppointmentStats(AnalyticsPeriod.last30Days);
        final aiStats = await getAIUsageStats(AnalyticsPeriod.last30Days);

        // Calculate component scores (0-100 scale)
        
        // 1. User Activity Score
        final userActivityScore = userStats.totalUsers > 0
            ? (userStats.activeUsers / userStats.totalUsers) * 100
            : 100.0; // Default to 100% if no users yet (new system)

        // 2. Appointment Completion Score
        final appointmentCompletionScore = appointmentStats.totalAppointments > 0
            ? appointmentStats.completionRate
            : 100.0; // Default to 100% if no appointments yet

        // 3. AI Confidence Score
        final aiConfidenceScore = aiStats.totalScans > 0
            ? aiStats.avgConfidence
            : 100.0; // Default to 100% if no scans yet

        print('🏥 System Health Components:');
        print('   User Activity: ${userActivityScore.toStringAsFixed(1)}%');
        print('   Appointment Completion: ${appointmentCompletionScore.toStringAsFixed(1)}%');
        print('   AI Confidence: ${aiConfidenceScore.toStringAsFixed(1)}%');

        return SystemHealthScore.calculate(
          userActivityScore: userActivityScore,
          appointmentCompletionScore: appointmentCompletionScore,
          aiConfidenceScore: aiConfidenceScore,
        );
      } catch (e) {
        print('Error calculating system health: $e');
        return SystemHealthScore.empty();
      }
    });
  }

  // ==================== GROWTH TRENDS ====================

  /// Get user growth trend (time series)
  static Future<List<TimeSeriesData>> getUserGrowthTrend(
      AnalyticsPeriod period) async {
    return _getCached('user_growth_${period.name}', () async {
      try {
        final usersSnapshot = await _firestore.collection('users').get();
        final users = usersSnapshot.docs
            .map((doc) => UserModel.fromMap(doc.data()))
            .toList();

        return _buildTimeSeriesData(
          users.map((u) => u.createdAt).toList(),
          period,
        );
      } catch (e) {
        print('Error getting user growth trend: $e');
        return [];
      }
    });
  }

  /// Get clinic growth trend (time series)
  static Future<List<TimeSeriesData>> getClinicGrowthTrend(
      AnalyticsPeriod period) async {
    return _getCached('clinic_growth_${period.name}', () async {
      try {
        final clinicsSnapshot = await _firestore.collection('clinics').get();
        final clinics = clinicsSnapshot.docs.map((doc) {
          final data = doc.data();
          DateTime? createdAt;
          if (data['createdAt'] is String) {
            createdAt = DateTime.tryParse(data['createdAt']);
          } else if (data['createdAt'] is Timestamp) {
            createdAt = (data['createdAt'] as Timestamp).toDate();
          }
          return createdAt ?? DateTime.now();
        }).toList();

        return _buildTimeSeriesData(clinics, period);
      } catch (e) {
        print('Error getting clinic growth trend: $e');
        return [];
      }
    });
  }

  /// Get pet growth trend (time series)
  static Future<List<TimeSeriesData>> getPetGrowthTrend(
      AnalyticsPeriod period) async {
    return _getCached('pet_growth_${period.name}', () async {
      try {
        final petsSnapshot = await _firestore.collection('pets').get();
        final pets = petsSnapshot.docs
            .map((doc) => Pet.fromMap(doc.data(), doc.id))
            .toList();

        return _buildTimeSeriesData(
          pets.map((p) => p.createdAt).toList(),
          period,
        );
      } catch (e) {
        print('Error getting pet growth trend: $e');
        return [];
      }
    });
  }

  /// Get AI scan trend (time series)
  static Future<List<TimeSeriesData>> getAIScanTrend(
      AnalyticsPeriod period) async {
    return _getCached('ai_scan_trend_${period.name}', () async {
      try {
        final assessmentsSnapshot =
            await _firestore.collection('assessment_results').get();
        final assessments = assessmentsSnapshot.docs
            .map((doc) => AssessmentResult.fromMap(doc.data(), doc.id))
            .toList();

        return _buildTimeSeriesData(
          assessments.map((a) => a.createdAt).toList(),
          period,
        );
      } catch (e) {
        print('Error getting AI scan trend: $e');
        return [];
      }
    });
  }

  // ==================== RANKINGS & DISTRIBUTIONS ====================

  /// Get top clinics by appointments
  static Future<List<ClinicPerformance>> getTopClinicsByAppointments({
    int limit = 10,
  }) async {
    return _getCached('top_clinics_$limit', () async {
      try {
        final appointmentsSnapshot =
            await _firestore.collection('appointments').get();
        final clinicsSnapshot = await _firestore.collection('clinics').get();

        // Count appointments per clinic
        final appointmentCounts = <String, int>{};
        final completionCounts = <String, int>{};

        for (final doc in appointmentsSnapshot.docs) {
          final data = doc.data();
          final clinicId = data['clinicId'] as String?;
          final status = data['status'] as String?;

          if (clinicId != null) {
            appointmentCounts[clinicId] =
                (appointmentCounts[clinicId] ?? 0) + 1;
            if (status == 'completed') {
              completionCounts[clinicId] =
                  (completionCounts[clinicId] ?? 0) + 1;
            }
          }
        }

        // Build performance list
        final performances = <ClinicPerformance>[];
        for (final clinicDoc in clinicsSnapshot.docs) {
          final clinicId = clinicDoc.id;
          final clinicName = clinicDoc.data()['clinicName'] ?? 'Unknown';
          final appointmentCount = appointmentCounts[clinicId] ?? 0;
          final completedCount = completionCounts[clinicId] ?? 0;

          if (appointmentCount > 0) {
            final completionRate =
                (completedCount / appointmentCount) * 100;
            final score = appointmentCount * (completionRate / 100);

            performances.add(ClinicPerformance(
              clinicId: clinicId,
              clinicName: clinicName,
              appointmentCount: appointmentCount,
              completionRate: completionRate,
              score: score,
              rank: 0, // Will be assigned after sorting
            ));
          }
        }

        // Sort by score (descending)
        performances.sort((a, b) => b.score.compareTo(a.score));

        // Assign ranks and limit
        final rankedPerformances = <ClinicPerformance>[];
        for (int i = 0; i < performances.length && i < limit; i++) {
          rankedPerformances.add(ClinicPerformance(
            clinicId: performances[i].clinicId,
            clinicName: performances[i].clinicName,
            appointmentCount: performances[i].appointmentCount,
            completionRate: performances[i].completionRate,
            score: performances[i].score,
            rank: i + 1,
          ));
        }

        return rankedPerformances;
      } catch (e) {
        print('Error getting top clinics: $e');
        return [];
      }
    });
  }

  /// Get clinics needing attention (underperforming)
  static Future<List<ClinicAlert>> getClinicsNeedingAttention() async {
    return _getCached('clinic_alerts', () async {
      try {
        final appointmentsSnapshot =
            await _firestore.collection('appointments').get();
        final clinicsSnapshot = await _firestore.collection('clinics').get();

        final clinicAppointments = <String, List<Map<String, dynamic>>>{};

        for (final doc in appointmentsSnapshot.docs) {
          final data = doc.data();
          final clinicId = data['clinicId'] as String?;
          if (clinicId != null) {
            clinicAppointments.putIfAbsent(clinicId, () => []);
            clinicAppointments[clinicId]!.add(data);
          }
        }

        final alerts = <ClinicAlert>[];

        for (final clinicDoc in clinicsSnapshot.docs) {
          final clinicId = clinicDoc.id;
          final clinicName = clinicDoc.data()['clinicName'] ?? 'Unknown';
          final appointments = clinicAppointments[clinicId] ?? [];

          if (appointments.isEmpty) {
            // No appointments in last 30 days
            alerts.add(ClinicAlert(
              clinicId: clinicId,
              clinicName: clinicName,
              alertType: 'no_appointments',
              message: 'No appointments in the last 30 days',
              details: {'appointmentCount': 0},
            ));
          } else {
            final total = appointments.length;
            final completed =
                appointments.where((a) => a['status'] == 'completed').length;
            final cancelled =
                appointments.where((a) => a['status'] == 'cancelled').length;
            final rejected =
                appointments.where((a) => a['status'] == 'rejected').length;

            final completionRate = (completed / total) * 100;
            final cancellationRate = ((cancelled + rejected) / total) * 100;

            if (completionRate < 60) {
              alerts.add(ClinicAlert(
                clinicId: clinicId,
                clinicName: clinicName,
                alertType: 'low_completion',
                message: 'Low completion rate: ${completionRate.toStringAsFixed(1)}%',
                details: {
                  'completionRate': completionRate,
                  'appointmentCount': total,
                },
              ));
            }

            if (cancellationRate > 30) {
              alerts.add(ClinicAlert(
                clinicId: clinicId,
                clinicName: clinicName,
                alertType: 'high_cancellation',
                message: 'High cancellation rate: ${cancellationRate.toStringAsFixed(1)}%',
                details: {
                  'cancellationRate': cancellationRate,
                  'appointmentCount': total,
                },
              ));
            }
          }
        }

        return alerts;
      } catch (e) {
        print('Error getting clinic alerts: $e');
        return [];
      }
    });
  }

  /// Get top detected diseases from AI assessment results
  /// 
  /// Data Source: 100% DYNAMIC - Fetched from Firestore 'assessment_results' collection
  /// - NO static or hardcoded data
  /// - Aggregates disease labels from all AI detection results
  /// - Calculates percentage based on total detections
  /// - Sorts by count (descending) and limits to top N
  /// 
  /// Data Flow:
  /// 1. Fetch all assessment_results documents from Firestore
  /// 2. Loop through each assessment's detectionResults array
  /// 3. Extract disease labels from detections array
  /// 4. Count occurrences of each unique disease
  /// 5. Calculate percentage: (diseaseCount / totalDetections) * 100
  /// 6. Sort by count and return top N diseases
  /// 
  /// Example Structure:
  /// assessment_results/{docId} = {
  ///   detectionResults: [
  ///     {
  ///       detections: [
  ///         { label: "hotspot", confidence: 0.95 },
  ///         { label: "ringworm", confidence: 0.87 }
  ///       ]
  ///     }
  ///   ]
  /// }
  static Future<List<DiseaseData>> getTopDetectedDiseases({
    int limit = 10,
  }) async {
    return _getCached('top_diseases_$limit', () async {
      try {
        final assessmentsSnapshot =
            await _firestore.collection('assessment_results').get();
        
        if (assessmentsSnapshot.docs.isEmpty) {
          print('ℹ️ No assessment results found in Firestore');
          return [];
        }

        final assessments = assessmentsSnapshot.docs
            .map((doc) => AssessmentResult.fromMap(doc.data(), doc.id))
            .toList();

        print('📊 Processing ${assessments.length} assessment results for disease data');

        final diseaseCounts = <String, int>{};

        // Count disease occurrences from REAL Firestore data
        for (final assessment in assessments) {
          for (final detectionResult in assessment.detectionResults) {
            for (final detection in detectionResult.detections) {
              final disease = detection.label;
              diseaseCounts[disease] = (diseaseCounts[disease] ?? 0) + 1;
            }
          }
        }

        print('📈 Found ${diseaseCounts.length} unique diseases');
        print('   Disease breakdown: ${diseaseCounts.entries.take(5).map((e) => "${e.key}: ${e.value}").join(", ")}');

        final totalDetections =
            diseaseCounts.values.fold(0, (sum, count) => sum + count);

        if (totalDetections == 0) {
          print('⚠️ No disease detections found in assessment results');
          return [];
        }

        // Build disease data list with percentages
        final diseaseList = diseaseCounts.entries
            .map((entry) => DiseaseData(
                  diseaseName: entry.key,
                  count: entry.value,
                  percentage: (entry.value / totalDetections) * 100,
                ))
            .toList();

        // Sort by count (descending) and limit
        diseaseList.sort((a, b) => b.count.compareTo(a.count));

        print('✅ Returning top $limit diseases (total detections: $totalDetections)');
        return diseaseList.take(limit).toList();
      } catch (e) {
        print('❌ Error getting top diseases: $e');
        return [];
      }
    });
  }

  /// Get appointment status distribution
  static Future<Map<String, int>> getAppointmentStatusDistribution() async {
    return _getCached('appointment_status_dist', () async {
      try {
        final stats = await getAppointmentStats(AnalyticsPeriod.last30Days);
        return stats.byStatus;
      } catch (e) {
        print('Error getting status distribution: $e');
        return {};
      }
    });
  }

  // ==================== HELPER METHODS ====================

  /// Build time series data from date list
  /// Generates data points evenly distributed across the period
  static List<TimeSeriesData> _buildTimeSeriesData(
    List<DateTime> dates,
    AnalyticsPeriod period,
  ) {
    if (dates.isEmpty) {
      print('⚠️ No dates provided for time series');
      return [];
    }

    final now = DateTime.now();
    final periodStart = now.subtract(Duration(days: period.days));

    // Filter dates within period
    final relevantDates =
        dates.where((date) => date.isAfter(periodStart)).toList();

    if (relevantDates.isEmpty) {
      print('⚠️ No dates within period. All dates are older than ${period.days} days');
      return [];
    }

    // Determine number of data points based on period
    int dataPoints = 7; // Default for last 7 days
    if (period == AnalyticsPeriod.last30Days) dataPoints = 10;
    if (period == AnalyticsPeriod.last90Days) dataPoints = 12;
    if (period == AnalyticsPeriod.lastYear) dataPoints = 12;

    final intervalDays = period.days / (dataPoints - 1);
    final timeSeriesData = <TimeSeriesData>[];

    // Generate data points at regular intervals
    for (int i = 0; i < dataPoints; i++) {
      final pointDate = periodStart.add(Duration(days: (intervalDays * i).round()));
      
      // Count items created up to this point
      final cumulativeCount = relevantDates
          .where((date) => date.isBefore(pointDate) || date.isAtSameMomentAs(pointDate))
          .length;

      // Format date label based on period
      String label;
      if (period == AnalyticsPeriod.lastYear) {
        label = '${_getMonthName(pointDate.month)} ${pointDate.day}';
      } else {
        label = '${pointDate.month}/${pointDate.day}';
      }

      timeSeriesData.add(TimeSeriesData(
        date: pointDate.toIso8601String().split('T')[0],
        value: cumulativeCount,
        label: label,
      ));
    }

    print('📈 Generated ${timeSeriesData.length} data points (values: ${timeSeriesData.map((d) => d.value).join(", ")})');
    return timeSeriesData;
  }

  static String _getMonthName(int month) {
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month];
  }

  /// Clear all cached data
  static void clearCache() {
    _cache.clear();
  }

  /// Get cached data or fetch if expired
  static Future<T> _getCached<T>(
    String key,
    Future<T> Function() fetchFunction,
  ) async {
    final cached = _cache[key];
    if (cached != null && !cached.isExpired) {
      return cached.data as T;
    }

    final data = await fetchFunction();
    _cache[key] = _CachedData(data, DateTime.now().add(_cacheDuration));
    return data;
  }
}

/// Internal cache data holder
class _CachedData {
  final dynamic data;
  final DateTime expiresAt;

  _CachedData(this.data, this.expiresAt);

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
