import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawsense/core/models/clinic/appointment_booking_model.dart';
import 'package:pawsense/core/models/user/pet_model.dart';
import 'package:pawsense/core/models/user/user_model.dart';

/// Service for managing patient records (pets with appointment history)
class PatientRecordService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const int _pageSize = 20; // Load 20 patients at a time

  /// Get paginated patient records for a clinic
  /// Includes pets with confirmed or completed appointments
  static Future<PaginatedPatientResult> getClinicPatients({
    required String clinicId,
    DocumentSnapshot? lastDocument,
    String? searchQuery,
    String? petType, // Filter by pet type (Dog, Cat, etc.)
    PatientHealthStatus? healthStatus,
  }) async {
    try {
      print('🔍 Fetching patients for clinic: $clinicId');
      
      // Get appointments for this clinic (confirmed or completed)
      Query query = _firestore
          .collection('appointments')
          .where('clinicId', isEqualTo: clinicId)
          .where('status', whereIn: ['confirmed', 'completed']);

      // Order by appointment date (most recent first)
      query = query.orderBy('appointmentDate', descending: true);

      // Add pagination
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      query = query.limit(_pageSize);

      final querySnapshot = await query.get();
      print('📋 Found ${querySnapshot.docs.length} appointments');

      if (querySnapshot.docs.isEmpty) {
        return PaginatedPatientResult(
          patients: [],
          lastDocument: null,
          hasMore: false,
        );
      }

      // Extract unique pets from appointments
      final Map<String, PatientRecord> uniquePatients = {};
      
      for (final doc in querySnapshot.docs) {
        final appointmentData = doc.data() as Map<String, dynamic>;
        final appointment = AppointmentBooking.fromMap(appointmentData, doc.id);

        // Skip if pet already processed
        if (uniquePatients.containsKey(appointment.petId)) {
          // Update last visit if this is more recent
          final existingPatient = uniquePatients[appointment.petId]!;
          if (appointment.appointmentDate.isAfter(existingPatient.lastVisit)) {
            uniquePatients[appointment.petId] = existingPatient.copyWith(
              lastVisit: appointment.appointmentDate,
              lastDiagnosis: appointment.serviceName,
            );
          }
          continue;
        }

        // Fetch pet and owner details
        final pet = await _fetchPet(appointment.petId);
        if (pet == null) continue;

        // Apply filters
        if (petType != null && petType != 'All Types' && 
            pet.petType.toLowerCase() != petType.toLowerCase()) {
          continue;
        }

        if (searchQuery != null && searchQuery.isNotEmpty) {
          final query = searchQuery.toLowerCase();
          if (!pet.petName.toLowerCase().contains(query) &&
              !pet.breed.toLowerCase().contains(query)) {
            continue;
          }
        }

        final owner = await _fetchOwner(appointment.userId);

        // Get appointment count and health status
        final appointmentCount = await _getAppointmentCount(
          clinicId,
          appointment.petId,
        );

        final healthStatus = await _determineHealthStatus(
          clinicId,
          appointment.petId,
        );

        // Get last assessment result if available
        String? assessmentResultId;
        if (appointment.assessmentResultId != null && 
            appointment.assessmentResultId!.isNotEmpty) {
          assessmentResultId = appointment.assessmentResultId;
        }

        // Build owner name from firstName + lastName, with fallbacks
        String ownerName = 'Unknown Owner';
        if (owner != null) {
          if (owner.firstName != null && owner.lastName != null) {
            ownerName = '${owner.firstName} ${owner.lastName}'.trim();
          } else if (owner.username.isNotEmpty) {
            ownerName = owner.username;
          }
        }

        final patientRecord = PatientRecord(
          petId: pet.id ?? appointment.petId,
          petName: pet.petName,
          petType: pet.petType,
          breed: pet.breed,
          age: pet.age,
          weight: pet.weight,
          imageUrl: pet.imageUrl,
          ownerId: appointment.userId,
          ownerName: ownerName,
          ownerPhone: owner?.contactNumber ?? 'N/A',
          ownerEmail: owner?.email ?? 'N/A',
          lastVisit: appointment.appointmentDate,
          lastDiagnosis: appointment.serviceName,
          appointmentCount: appointmentCount,
          healthStatus: healthStatus,
          assessmentResultId: assessmentResultId,
        );

        uniquePatients[appointment.petId] = patientRecord;
      }

      // Apply health status filter
      List<PatientRecord> filteredPatients = uniquePatients.values.toList();
      if (healthStatus != null && healthStatus != PatientHealthStatus.all) {
        filteredPatients = filteredPatients
            .where((p) => p.healthStatus == healthStatus)
            .toList();
      }

      print('✅ Returning ${filteredPatients.length} unique patients');

      return PaginatedPatientResult(
        patients: filteredPatients,
        lastDocument: querySnapshot.docs.isNotEmpty 
            ? querySnapshot.docs.last 
            : null,
        hasMore: querySnapshot.docs.length == _pageSize,
      );
    } catch (e) {
      print('❌ Error fetching patients: $e');
      return PaginatedPatientResult(
        patients: [],
        lastDocument: null,
        hasMore: false,
      );
    }
  }

  /// Get patient record by pet ID
  static Future<PatientRecord?> getPatientByPetId({
    required String clinicId,
    required String petId,
  }) async {
    try {
      // Get pet details
      final pet = await _fetchPet(petId);
      if (pet == null) return null;

      // Get most recent appointment for this pet at this clinic
      final appointmentQuery = await _firestore
          .collection('appointments')
          .where('clinicId', isEqualTo: clinicId)
          .where('petId', isEqualTo: petId)
          .where('status', whereIn: ['confirmed', 'completed'])
          .orderBy('appointmentDate', descending: true)
          .limit(1)
          .get();

      if (appointmentQuery.docs.isEmpty) return null;

      final appointment = AppointmentBooking.fromMap(
        appointmentQuery.docs.first.data(),
        appointmentQuery.docs.first.id,
      );

      // Get owner details
      final owner = await _fetchOwner(appointment.userId);

      // Get appointment count and health status
      final appointmentCount = await _getAppointmentCount(clinicId, petId);
      final healthStatus = await _determineHealthStatus(clinicId, petId);

      // Build owner name from firstName + lastName, with fallbacks
      String ownerName = 'Unknown Owner';
      if (owner != null) {
        if (owner.firstName != null && owner.lastName != null) {
          ownerName = '${owner.firstName} ${owner.lastName}'.trim();
        } else if (owner.username.isNotEmpty) {
          ownerName = owner.username;
        }
      }

      return PatientRecord(
        petId: pet.id ?? petId,
        petName: pet.petName,
        petType: pet.petType,
        breed: pet.breed,
        age: pet.age,
        weight: pet.weight,
        imageUrl: pet.imageUrl,
        ownerId: appointment.userId,
        ownerName: ownerName,
        ownerPhone: owner?.contactNumber ?? 'N/A',
        ownerEmail: owner?.email ?? 'N/A',
        lastVisit: appointment.appointmentDate,
        lastDiagnosis: appointment.serviceName,
        appointmentCount: appointmentCount,
        healthStatus: healthStatus,
        assessmentResultId: appointment.assessmentResultId,
      );
    } catch (e) {
      print('❌ Error fetching patient by pet ID: $e');
      return null;
    }
  }

  /// Get appointment history for a patient
  static Future<List<AppointmentBooking>> getPatientHistory({
    required String clinicId,
    required String petId,
  }) async {
    try {
      // Query without orderBy to avoid needing complex index
      final query = await _firestore
          .collection('appointments')
          .where('clinicId', isEqualTo: clinicId)
          .where('petId', isEqualTo: petId)
          .get();

      // Convert to list and sort in memory
      final appointments = query.docs
          .map((doc) => AppointmentBooking.fromMap(doc.data(), doc.id))
          .toList();

      // Sort by appointment date descending
      appointments.sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));

      return appointments;
    } catch (e) {
      print('❌ Error fetching patient history: $e');
      return [];
    }
  }

  // Private helper methods

  static Future<Pet?> _fetchPet(String petId) async {
    try {
      final petDoc = await _firestore.collection('pets').doc(petId).get();
      if (petDoc.exists) {
        return Pet.fromMap(petDoc.data()!, petDoc.id);
      }
    } catch (e) {
      print('⚠️ Error fetching pet $petId: $e');
    }
    return null;
  }

  static Future<UserModel?> _fetchOwner(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        return UserModel.fromMap(userDoc.data()!);
      }
    } catch (e) {
      print('⚠️ Error fetching owner $userId: $e');
    }
    return null;
  }

  static Future<int> _getAppointmentCount(String clinicId, String petId) async {
    try {
      final query = await _firestore
          .collection('appointments')
          .where('clinicId', isEqualTo: clinicId)
          .where('petId', isEqualTo: petId)
          .count()
          .get();
      return query.count ?? 0;
    } catch (e) {
      print('⚠️ Error getting appointment count: $e');
      return 0;
    }
  }

  static Future<PatientHealthStatus> _determineHealthStatus(
    String clinicId,
    String petId,
  ) async {
    try {
      // Get all appointments for this pet at this clinic
      final query = await _firestore
          .collection('appointments')
          .where('clinicId', isEqualTo: clinicId)
          .where('petId', isEqualTo: petId)
          .get();

      if (query.docs.isEmpty) {
        return PatientHealthStatus.unknown;
      }

      // Filter and sort in memory to avoid complex index
      final appointments = query.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'status': data['status'] as String,
          'date': (data['appointmentDate'] as Timestamp).toDate(),
          'assessmentResultId': data['assessmentResultId'] as String?,
        };
      }).toList();

      // Sort by date descending
      appointments.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

      // Find most recent completed appointment
      final completedAppointment = appointments.firstWhere(
        (apt) => apt['status'] == 'completed',
        orElse: () => {},
      );

      if (completedAppointment.isEmpty) {
        // No completed appointments yet, check if confirmed
        final hasConfirmed = appointments.any((apt) => apt['status'] == 'confirmed');
        return hasConfirmed
            ? PatientHealthStatus.scheduled
            : PatientHealthStatus.unknown;
      }

      // Check if there's an assessment result
      final assessmentResultId = completedAppointment['assessmentResultId'] as String?;
      if (assessmentResultId != null && assessmentResultId.isNotEmpty) {
        final assessmentDoc = await _firestore
            .collection('assessment_results')
            .doc(assessmentResultId)
            .get();

        if (assessmentDoc.exists) {
          final detectionResults = 
              assessmentDoc.data()?['detectionResults'] as List?;
          
          if (detectionResults != null && detectionResults.isNotEmpty) {
            // Has disease detection
            return PatientHealthStatus.treatment;
          }
        }
      }

      // Check diagnosis from completed appointment
      final appointmentDoc = await _firestore
          .collection('appointments')
          .doc(completedAppointment['id'] as String)
          .get();

      if (appointmentDoc.exists) {
        final data = appointmentDoc.data();
        final diagnosis = data?['diagnosis'] as String?;
        
        if (diagnosis != null && diagnosis.isNotEmpty) {
          // Check for healthy indicators
          final healthyKeywords = ['healthy', 'normal', 'good', 'routine'];
          if (healthyKeywords.any((keyword) => 
              diagnosis.toLowerCase().contains(keyword))) {
            return PatientHealthStatus.healthy;
          }
          return PatientHealthStatus.treatment;
        }
      }

      return PatientHealthStatus.healthy;
    } catch (e) {
      print('⚠️ Error determining health status: $e');
      return PatientHealthStatus.unknown;
    }
  }

  /// Get patient statistics for the clinic
  static Future<PatientStatistics> getPatientStatistics(String clinicId) async {
    try {
      // Get all unique patients
      final allPatients = await getClinicPatients(clinicId: clinicId);
      
      final totalPatients = allPatients.patients.length;
      final healthyCount = allPatients.patients
          .where((p) => p.healthStatus == PatientHealthStatus.healthy)
          .length;
      final treatmentCount = allPatients.patients
          .where((p) => p.healthStatus == PatientHealthStatus.treatment)
          .length;
      final scheduledCount = allPatients.patients
          .where((p) => p.healthStatus == PatientHealthStatus.scheduled)
          .length;

      return PatientStatistics(
        totalPatients: totalPatients,
        healthyCount: healthyCount,
        treatmentCount: treatmentCount,
        scheduledCount: scheduledCount,
      );
    } catch (e) {
      print('❌ Error getting patient statistics: $e');
      return PatientStatistics(
        totalPatients: 0,
        healthyCount: 0,
        treatmentCount: 0,
        scheduledCount: 0,
      );
    }
  }
}

/// Patient health status enum
enum PatientHealthStatus {
  all,
  healthy,
  treatment,
  scheduled,
  unknown,
}

/// Patient record model
class PatientRecord {
  final String petId;
  final String petName;
  final String petType;
  final String breed;
  final int age; // in months
  final double weight; // in kg
  final String? imageUrl;
  final String ownerId;
  final String ownerName;
  final String ownerPhone;
  final String ownerEmail;
  final DateTime lastVisit;
  final String lastDiagnosis;
  final int appointmentCount;
  final PatientHealthStatus healthStatus;
  final String? assessmentResultId;

  PatientRecord({
    required this.petId,
    required this.petName,
    required this.petType,
    required this.breed,
    required this.age,
    required this.weight,
    this.imageUrl,
    required this.ownerId,
    required this.ownerName,
    required this.ownerPhone,
    required this.ownerEmail,
    required this.lastVisit,
    required this.lastDiagnosis,
    required this.appointmentCount,
    required this.healthStatus,
    this.assessmentResultId,
  });

  PatientRecord copyWith({
    String? petId,
    String? petName,
    String? petType,
    String? breed,
    int? age,
    double? weight,
    String? imageUrl,
    String? ownerId,
    String? ownerName,
    String? ownerPhone,
    String? ownerEmail,
    DateTime? lastVisit,
    String? lastDiagnosis,
    int? appointmentCount,
    PatientHealthStatus? healthStatus,
    String? assessmentResultId,
  }) {
    return PatientRecord(
      petId: petId ?? this.petId,
      petName: petName ?? this.petName,
      petType: petType ?? this.petType,
      breed: breed ?? this.breed,
      age: age ?? this.age,
      weight: weight ?? this.weight,
      imageUrl: imageUrl ?? this.imageUrl,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      ownerPhone: ownerPhone ?? this.ownerPhone,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      lastVisit: lastVisit ?? this.lastVisit,
      lastDiagnosis: lastDiagnosis ?? this.lastDiagnosis,
      appointmentCount: appointmentCount ?? this.appointmentCount,
      healthStatus: healthStatus ?? this.healthStatus,
      assessmentResultId: assessmentResultId ?? this.assessmentResultId,
    );
  }

  // Get age in human-readable format
  String get ageString {
    if (age < 12) {
      return '$age ${age == 1 ? 'month' : 'months'}';
    } else {
      final years = age ~/ 12;
      final months = age % 12;
      if (months == 0) {
        return '$years ${years == 1 ? 'year' : 'years'}';
      } else {
        return '$years ${years == 1 ? 'year' : 'years'} $months ${months == 1 ? 'month' : 'months'}';
      }
    }
  }

  // Get weight string
  String get weightString => '${weight.toStringAsFixed(1)} kg';

  // Get pet emoji
  String get petEmoji {
    switch (petType.toLowerCase()) {
      case 'dog':
        return '🐕';
      case 'cat':
        return '🐱';
      case 'bird':
        return '🐦';
      case 'rabbit':
        return '🐰';
      case 'hamster':
        return '🐹';
      default:
        return '🐾';
    }
  }
}

/// Paginated patient result
class PaginatedPatientResult {
  final List<PatientRecord> patients;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;

  PaginatedPatientResult({
    required this.patients,
    required this.lastDocument,
    required this.hasMore,
  });
}

/// Patient statistics
class PatientStatistics {
  final int totalPatients;
  final int healthyCount;
  final int treatmentCount;
  final int scheduledCount;

  PatientStatistics({
    required this.totalPatients,
    required this.healthyCount,
    required this.treatmentCount,
    required this.scheduledCount,
  });
}
