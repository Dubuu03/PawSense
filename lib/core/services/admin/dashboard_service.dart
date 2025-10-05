import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawsense/core/guards/auth_guard.dart';

/// Service to fetch dynamic dashboard data for admin clinics
class DashboardService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get dashboard statistics for a specific clinic
  static Future<DashboardStats> getClinicDashboardStats(
    String clinicId, {
    required String period, // 'daily', 'weekly', 'monthly'
  }) async {
    try {
      final now = DateTime.now();
      DateTime startDate;
      DateTime endDate;
      DateTime previousStartDate;
      DateTime previousEndDate;

      // Calculate date ranges based on period with accurate time boundaries
      switch (period.toLowerCase()) {
        case 'daily':
          // Today: 00:00:00 to 23:59:59
          startDate = DateTime(now.year, now.month, now.day, 0, 0, 0);
          endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
          
          // Yesterday: 00:00:00 to 23:59:59
          final yesterday = now.subtract(Duration(days: 1));
          previousStartDate = DateTime(yesterday.year, yesterday.month, yesterday.day, 0, 0, 0);
          previousEndDate = DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);
          break;
          
        case 'weekly':
          // This week: Monday 00:00:00 to Sunday 23:59:59
          final weekday = now.weekday; // Monday = 1, Sunday = 7
          final monday = now.subtract(Duration(days: weekday - 1));
          startDate = DateTime(monday.year, monday.month, monday.day, 0, 0, 0);
          
          final sunday = monday.add(Duration(days: 6));
          endDate = DateTime(sunday.year, sunday.month, sunday.day, 23, 59, 59);
          
          // Last week: Previous Monday to Previous Sunday
          final lastMonday = monday.subtract(Duration(days: 7));
          previousStartDate = DateTime(lastMonday.year, lastMonday.month, lastMonday.day, 0, 0, 0);
          
          final lastSunday = lastMonday.add(Duration(days: 6));
          previousEndDate = DateTime(lastSunday.year, lastSunday.month, lastSunday.day, 23, 59, 59);
          break;
          
        case 'monthly':
          // This month: 1st 00:00:00 to last day 23:59:59
          startDate = DateTime(now.year, now.month, 1, 0, 0, 0);
          
          // Last day of current month
          final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
          endDate = DateTime(lastDayOfMonth.year, lastDayOfMonth.month, lastDayOfMonth.day, 23, 59, 59);
          
          // Last month: 1st to last day of previous month
          previousStartDate = DateTime(now.year, now.month - 1, 1, 0, 0, 0);
          
          // Last day of previous month
          final lastDayOfPrevMonth = DateTime(now.year, now.month, 0);
          previousEndDate = DateTime(lastDayOfPrevMonth.year, lastDayOfPrevMonth.month, lastDayOfPrevMonth.day, 23, 59, 59);
          break;
          
        default:
          // Default to daily
          startDate = DateTime(now.year, now.month, now.day, 0, 0, 0);
          endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
          
          final yesterday = now.subtract(Duration(days: 1));
          previousStartDate = DateTime(yesterday.year, yesterday.month, yesterday.day, 0, 0, 0);
          previousEndDate = DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);
      }

      // Debug: Print date ranges
      print('Dashboard Stats - Period: $period');
      print('Current period: $startDate to $endDate');
      print('Previous period: $previousStartDate to $previousEndDate');
      
      // Fetch appointments
      final currentAppointments = await _getAppointmentsCount(
        clinicId,
        startDate,
        endDate,
      );

      final previousAppointments = await _getAppointmentsCount(
        clinicId,
        previousStartDate,
        previousEndDate,
      );
      
      print('Current appointments: $currentAppointments, Previous: $previousAppointments');

      // Fetch completed consultations
      final currentCompletedConsultations = await _getCompletedConsultationsCount(
        clinicId,
        startDate,
        endDate,
      );

      final previousCompletedConsultations = await _getCompletedConsultationsCount(
        clinicId,
        previousStartDate,
        previousEndDate,
      );

      // Fetch active patients (patients with appointments in the period)
      final activePatients = await _getActivePatientsCount(
        clinicId,
        startDate,
        endDate,
      );

      final previousActivePatients = await _getActivePatientsCount(
        clinicId,
        previousStartDate,
        previousEndDate,
      );

      // Calculate percentage changes
      final appointmentsChange = _calculatePercentageChange(
        previousAppointments,
        currentAppointments,
      );

      final consultationsChange = _calculatePercentageChange(
        previousCompletedConsultations,
        currentCompletedConsultations,
      );

      final patientsChange = _calculatePercentageChange(
        previousActivePatients,
        activePatients,
      );

      return DashboardStats(
        totalAppointments: currentAppointments,
        appointmentsChange: appointmentsChange,
        completedConsultations: currentCompletedConsultations,
        consultationsChange: consultationsChange,
        activePatients: activePatients,
        patientsChange: patientsChange,
        period: period,
      );
    } catch (e) {
      print('Error fetching dashboard stats: $e');
      return DashboardStats.empty(period);
    }
  }

  /// Get count of appointments in a date range
  static Future<int> _getAppointmentsCount(
    String clinicId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final query = await _firestore
          .collection('appointments')
          .where('clinicId', isEqualTo: clinicId)
          .where('appointmentDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('appointmentDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      // Debug: Print each appointment date
      print('Appointments from $startDate to $endDate:');
      for (final doc in query.docs) {
        final data = doc.data();
        final appointmentDate = (data['appointmentDate'] as Timestamp?)?.toDate();
        print('  - Appointment ID: ${doc.id}, Date: $appointmentDate');
      }
      print('Total count: ${query.docs.length}');

      return query.docs.length;
    } catch (e) {
      print('Error getting appointments count: $e');
      return 0;
    }
  }

  /// Get count of completed consultations in a date range
  static Future<int> _getCompletedConsultationsCount(
    String clinicId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      // Fetch all appointments for clinic and filter in memory to avoid complex index
      final query = await _firestore
          .collection('appointments')
          .where('clinicId', isEqualTo: clinicId)
          .where('status', isEqualTo: 'completed')
          .get();

      // Filter by date in memory
      int count = 0;
      for (final doc in query.docs) {
        final data = doc.data();
        final appointmentDate = (data['appointmentDate'] as Timestamp?)?.toDate();
        if (appointmentDate != null &&
            !appointmentDate.isBefore(startDate) &&
            !appointmentDate.isAfter(endDate)) {
          count++;
        }
      }

      return count;
    } catch (e) {
      print('Error getting completed consultations count: $e');
      return 0;
    }
  }

  /// Get count of active patients (unique patients with appointments in the period)
  static Future<int> _getActivePatientsCount(
    String clinicId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final query = await _firestore
          .collection('appointments')
          .where('clinicId', isEqualTo: clinicId)
          .where('appointmentDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('appointmentDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      // Get unique pet IDs
      final uniquePetIds = <String>{};
      for (final doc in query.docs) {
        final data = doc.data();
        if (data['petId'] != null) {
          uniquePetIds.add(data['petId']);
        }
      }

      return uniquePetIds.length;
    } catch (e) {
      print('Error getting active patients count: $e');
      return 0;
    }
  }

  /// Calculate percentage change between two values
  static double _calculatePercentageChange(num oldValue, num newValue) {
    if (oldValue == 0) {
      return newValue > 0 ? 100.0 : 0.0;
    }
    return ((newValue - oldValue) / oldValue * 100);
  }

  /// Get recent activities for the clinic
  static Future<List<RecentActivity>> getRecentActivities(
    String clinicId, {
    int limit = 10,
  }) async {
    try {
      print('📊 Fetching recent activities for clinic: $clinicId');
      
      // Fetch appointments and sort in memory to avoid index requirement
      final query = await _firestore
          .collection('appointments')
          .where('clinicId', isEqualTo: clinicId)
          .get();
      
      print('📋 Fetched ${query.docs.length} appointments');
      
      // Sort by updatedAt in memory
      final sortedDocs = query.docs.toList()
        ..sort((a, b) {
          final aTime = (a.data()['updatedAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
          final bTime = (b.data()['updatedAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
          return bTime.compareTo(aTime); // Descending order
        });
      
      // Take only the limit
      final limitedDocs = sortedDocs.take(limit).toList();
      
      // Collect unique petIds and userIds
      final petIds = <String>{};
      final userIds = <String>{};
      
      for (final doc in limitedDocs) {
        final data = doc.data();
        final petId = data['petId']?.toString();
        final userId = data['userId']?.toString();
        
        if (petId != null && petId.isNotEmpty) petIds.add(petId);
        if (userId != null && userId.isNotEmpty) userIds.add(userId);
      }
      
      print('🔍 Need to fetch ${petIds.length} pets and ${userIds.length} users');
      
      // Batch fetch all pets (Firestore 'in' query supports up to 10 items)
      final petsMap = <String, String>{};
      final petIdsList = petIds.toList();
      for (var i = 0; i < petIdsList.length; i += 10) {
        final batch = petIdsList.skip(i).take(10).toList();
        if (batch.isEmpty) break;
        
        final petsQuery = await _firestore
            .collection('pets')
            .where(FieldPath.documentId, whereIn: batch)
            .get();
        
        for (final petDoc in petsQuery.docs) {
          final petData = petDoc.data();
          String petName = 'Unknown Pet';
          
          if (petData['petName'] != null && petData['petName'].toString().isNotEmpty) {
            petName = petData['petName'].toString();
          } else if (petData['name'] != null && petData['name'].toString().isNotEmpty) {
            petName = petData['name'].toString();
          }
          
          petsMap[petDoc.id] = petName;
        }
      }
      
      print('✅ Fetched ${petsMap.length} pets');
      
      // Batch fetch all users
      final usersMap = <String, String>{};
      final userIdsList = userIds.toList();
      for (var i = 0; i < userIdsList.length; i += 10) {
        final batch = userIdsList.skip(i).take(10).toList();
        if (batch.isEmpty) break;
        
        final usersQuery = await _firestore
            .collection('users')
            .where(FieldPath.documentId, whereIn: batch)
            .get();
        
        for (final userDoc in usersQuery.docs) {
          final userData = userDoc.data();
          String ownerName = 'Unknown Owner';
          
          if (userData['firstName'] != null && userData['lastName'] != null) {
            ownerName = '${userData['firstName']} ${userData['lastName']}'.trim();
          } else if (userData['fullName'] != null) {
            ownerName = userData['fullName'].toString();
          } else if (userData['name'] != null) {
            ownerName = userData['name'].toString();
          } else if (userData['username'] != null) {
            ownerName = userData['username'].toString();
          }
          
          usersMap[userDoc.id] = ownerName;
        }
      }
      
      print('✅ Fetched ${usersMap.length} users');
      
      // Build activities using the cached maps
      final activities = <RecentActivity>[];
      for (final doc in limitedDocs) {
        final data = doc.data();
        final petId = data['petId']?.toString();
        final userId = data['userId']?.toString();
        
        final petName = petId != null ? (petsMap[petId] ?? 'Unknown Pet') : 'Unknown Pet';
        final ownerName = userId != null ? (usersMap[userId] ?? 'Unknown Owner') : 'Unknown Owner';
        final status = data['status'] ?? 'pending';
        final timestamp = (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now();

        activities.add(RecentActivity(
          petName: petName,
          ownerName: ownerName,
          status: status,
          timestamp: timestamp,
        ));
      }
      
      print('✅ Built ${activities.length} activities');

      return activities;
    } catch (e) {
      print('Error getting recent activities: $e');
      return [];
    }
  }

  /// Get common diseases for the clinic based on appointments
  static Future<List<DiseaseData>> getCommonDiseases(
    String clinicId, {
    int limit = 5,
  }) async {
    try {
      print('🔍 Fetching diseases for clinic: $clinicId');
      
      // Get all appointments for this clinic that have assessment results
      final appointmentsQuery = await _firestore
          .collection('appointments')
          .where('clinicId', isEqualTo: clinicId)
          .get();

      print('📋 Found ${appointmentsQuery.docs.length} total appointments');

      // Collect all unique assessment result IDs
      final assessmentResultIds = <String>{};
      int appointmentsWithAssessment = 0;
      
      for (final appointmentDoc in appointmentsQuery.docs) {
        final appointmentData = appointmentDoc.data();
        
        // Debug: Print all keys in the appointment document
        print('   📋 Appointment ${appointmentDoc.id} keys: ${appointmentData.keys.toList()}');
        
        final assessmentResultId = appointmentData['assessmentResultId'] as String?;
        
        if (assessmentResultId != null && assessmentResultId.isNotEmpty) {
          appointmentsWithAssessment++;
          assessmentResultIds.add(assessmentResultId);
          print('   📝 Found assessmentResultId: $assessmentResultId');
        } else {
          print('   ⚠️  Appointment ${appointmentDoc.id} has NO assessmentResultId');
        }
      }
      
      print('🔍 Found ${appointmentsWithAssessment}/${appointmentsQuery.docs.length} appointments with assessmentResultId');
      print('🔍 Need to fetch ${assessmentResultIds.length} unique assessment results');
      
      if (assessmentResultIds.isEmpty) {
        print('⚠️  No appointments have assessmentResultId field - returning empty disease list');
        return [];
      }

      // Batch fetch all assessment results (Firestore 'in' query supports up to 10 items)
      final assessmentResultsMap = <String, Map<String, dynamic>>{};
      final assessmentIdsList = assessmentResultIds.toList();
      
      for (var i = 0; i < assessmentIdsList.length; i += 10) {
        final batch = assessmentIdsList.skip(i).take(10).toList();
        if (batch.isEmpty) break;
        
        print('   🔎 Querying assessment_results with IDs: $batch');
        
        final assessmentsQuery = await _firestore
            .collection('assessment_results')
            .where(FieldPath.documentId, whereIn: batch)
            .get();
        
        print('   📦 Query returned ${assessmentsQuery.docs.length} documents');
        
        for (final assessmentDoc in assessmentsQuery.docs) {
          if (assessmentDoc.exists) {
            final data = assessmentDoc.data();
            assessmentResultsMap[assessmentDoc.id] = data;
            print('   ✓ Found document: ${assessmentDoc.id}');
          }
        }
      }
      
      print('✅ Fetched ${assessmentResultsMap.length} assessment results');

      // Count diseases from assessment results
      final diseaseMap = <String, int>{};
      int conditionsFound = 0;
      int assessmentsWithResults = 0;
      
      for (final entry in assessmentResultsMap.entries) {
        final assessmentData = entry.value;
        
        // Get analysisResults array directly from the document
        final analysisResults = assessmentData['analysisResults'] as List?;
        
        if (analysisResults != null && analysisResults.isNotEmpty) {
          assessmentsWithResults++;
          print('   📄 Assessment has ${analysisResults.length} results');
          
          // Process each analysis result
          for (final result in analysisResults) {
            if (result is Map<String, dynamic>) {
              final condition = result['condition'] as String?;
              final percentage = result['percentage'] as num?;
              
              print('      🔬 Condition: $condition, Percentage: $percentage');
              
              // Only count conditions with confidence > 50%
              if (condition != null && 
                  condition.isNotEmpty && 
                  percentage != null && 
                  percentage > 50) {
                diseaseMap[condition] = (diseaseMap[condition] ?? 0) + 1;
                conditionsFound++;
                print('      ✅ Added: $condition');
              } else {
                print('      ⏭️  Skipped (percentage <= 50 or invalid)');
              }
            }
          }
        } else {
          print('   ⚠️  Assessment has no analysisResults array');
        }
      }

      print('📊 Found $conditionsFound conditions from $assessmentsWithResults/${assessmentResultsMap.length} assessments');
      print('🦠 Disease summary: $diseaseMap');

      // Sort by count and take top N
      final sortedDiseases = diseaseMap.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final topDiseases = sortedDiseases.take(limit).toList();

      // Calculate total for percentage
      final total = topDiseases.fold<int>(0, (sum, entry) => sum + entry.value);

      final result = topDiseases.map((entry) {
        final percentage = total > 0 ? (entry.value / total * 100) : 0.0;
        return DiseaseData(
          name: entry.key,
          count: entry.value,
          percentage: percentage,
        );
      }).toList();

      print('✅ Returning ${result.length} common diseases');
      return result;
    } catch (e) {
      print('❌ Error getting common diseases: $e');
      return [];
    }
  }

  /// Get the current user's clinic ID
  static Future<String?> getCurrentUserClinicId() async {
    try {
      final user = await AuthGuard.getCurrentUser();
      if (user == null) return null;

      // For admin users, their UID is the clinic ID
      if (user.role == 'admin') {
        return user.uid;
      }

      // For other roles, look up their clinic association
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        return data?['clinicId'] as String?;
      }

      return null;
    } catch (e) {
      print('Error getting current user clinic ID: $e');
      return null;
    }
  }
}

/// Dashboard statistics model
class DashboardStats {
  final int totalAppointments;
  final double appointmentsChange;
  final int completedConsultations;
  final double consultationsChange;
  final int activePatients;
  final double patientsChange;
  final String period;

  DashboardStats({
    required this.totalAppointments,
    required this.appointmentsChange,
    required this.completedConsultations,
    required this.consultationsChange,
    required this.activePatients,
    required this.patientsChange,
    required this.period,
  });

  factory DashboardStats.empty(String period) {
    return DashboardStats(
      totalAppointments: 0,
      appointmentsChange: 0.0,
      completedConsultations: 0,
      consultationsChange: 0.0,
      activePatients: 0,
      patientsChange: 0.0,
      period: period,
    );
  }
}

/// Recent activity model
class RecentActivity {
  final String petName;
  final String ownerName;
  final String status;
  final DateTime timestamp;

  RecentActivity({
    required this.petName,
    required this.ownerName,
    required this.status,
    required this.timestamp,
  });
}

/// Disease data model for charts
class DiseaseData {
  final String name;
  final int count;
  final double percentage;

  DiseaseData({
    required this.name,
    required this.count,
    required this.percentage,
  });
}
