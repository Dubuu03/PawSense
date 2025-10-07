import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawsense/core/models/clinic/appointment_booking_model.dart';
import 'package:pawsense/core/models/user/pet_model.dart';
import 'package:pawsense/core/models/user/user_model.dart';

/// Service for managing patient records (pets with appointment history)
class PatientRecordService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const int _pageSize = 20; // Load 20 patients at a time
  
  // Memory cache for performance
  static final Map<String, Pet> _petCache = <String, Pet>{};
  static final Map<String, UserModel> _ownerCache = <String, UserModel>{};
  static final Map<String, int> _appointmentCountCache = <String, int>{};
  static final Map<String, PatientHealthStatus> _healthStatusCache = <String, PatientHealthStatus>{};
  
  // Cache expiry time (5 minutes)
  static final Map<String, DateTime> _cacheTimestamps = <String, DateTime>{};
  static const Duration _cacheExpiry = Duration(minutes: 5);
  
  // Prevent concurrent calls to same clinic
  static final Set<String> _loadingClinics = <String>{};

  /// Check if cache entry is valid
  static bool _isCacheValid(String key) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _cacheExpiry;
  }



  /// Batch fetch pets to reduce network calls
  static Future<Map<String, Pet>> _batchFetchPets(List<String> petIds) async {
    final Map<String, Pet> result = {};
    final List<String> uncachedPetIds = [];

    // Check cache first
    for (final petId in petIds) {
      if (_isCacheValid('pet_$petId') && _petCache.containsKey(petId)) {
        result[petId] = _petCache[petId]!;
      } else {
        uncachedPetIds.add(petId);
      }
    }

    // Batch fetch uncached pets
    if (uncachedPetIds.isNotEmpty) {
      // Split into chunks of 10 for Firestore 'in' query limit
      const chunkSize = 10;
      for (int i = 0; i < uncachedPetIds.length; i += chunkSize) {
        final chunk = uncachedPetIds.skip(i).take(chunkSize).toList();
        
        final querySnapshot = await _firestore
            .collection('pets')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        for (final doc in querySnapshot.docs) {
          final pet = Pet.fromMap(doc.data(), doc.id);
          result[doc.id] = pet;
          _petCache[doc.id] = pet;
          _cacheTimestamps['pet_${doc.id}'] = DateTime.now();
        }
      }
    }

    return result;
  }

  /// Batch fetch owners to reduce network calls
  static Future<Map<String, UserModel>> _batchFetchOwners(List<String> ownerIds) async {
    final Map<String, UserModel> result = {};
    final List<String> uncachedOwnerIds = [];

    // Check cache first
    for (final ownerId in ownerIds) {
      if (_isCacheValid('owner_$ownerId') && _ownerCache.containsKey(ownerId)) {
        result[ownerId] = _ownerCache[ownerId]!;
      } else {
        uncachedOwnerIds.add(ownerId);
      }
    }

    // Batch fetch uncached owners
    if (uncachedOwnerIds.isNotEmpty) {
      // Split into chunks of 10 for Firestore 'in' query limit
      const chunkSize = 10;
      for (int i = 0; i < uncachedOwnerIds.length; i += chunkSize) {
        final chunk = uncachedOwnerIds.skip(i).take(chunkSize).toList();
        
        final querySnapshot = await _firestore
            .collection('users')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        for (final doc in querySnapshot.docs) {
          final ownerData = doc.data();
          ownerData['id'] = doc.id; // Add ID to data
          final owner = UserModel.fromMap(ownerData);
          result[doc.id] = owner;
          _ownerCache[doc.id] = owner;
          _cacheTimestamps['owner_${doc.id}'] = DateTime.now();
        }
      }
    }

    return result;
  }

  /// Batch get appointment counts for multiple pets
  static Future<Map<String, int>> _batchGetAppointmentCounts(String clinicId, List<String> petIds) async {
    final Map<String, int> result = {};
    final List<String> uncachedPetIds = [];

    // Check cache first
    for (final petId in petIds) {
      final cacheKey = 'count_${clinicId}_$petId';
      if (_isCacheValid(cacheKey) && _appointmentCountCache.containsKey(cacheKey)) {
        result[petId] = _appointmentCountCache[cacheKey]!;
      } else {
        uncachedPetIds.add(petId);
      }
    }

    // Batch fetch uncached counts
    if (uncachedPetIds.isNotEmpty) {
      // Get all appointments for these pets in one query
      final querySnapshot = await _firestore
          .collection('appointments')
          .where('clinicId', isEqualTo: clinicId)
          .where('petId', whereIn: uncachedPetIds.length > 10 
              ? uncachedPetIds.take(10).toList() 
              : uncachedPetIds)
          .get();

      // Count appointments per pet
      final counts = <String, int>{};
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final petId = data['petId'] as String;
        counts[petId] = (counts[petId] ?? 0) + 1;
      }

      // Handle remaining pets if more than 10
      if (uncachedPetIds.length > 10) {
        for (int i = 10; i < uncachedPetIds.length; i += 10) {
          final chunk = uncachedPetIds.skip(i).take(10).toList();
          final chunkQuery = await _firestore
              .collection('appointments')
              .where('clinicId', isEqualTo: clinicId)
              .where('petId', whereIn: chunk)
              .get();

          for (final doc in chunkQuery.docs) {
            final data = doc.data();
            final petId = data['petId'] as String;
            counts[petId] = (counts[petId] ?? 0) + 1;
          }
        }
      }

      // Update cache and result
      for (final petId in uncachedPetIds) {
        final count = counts[petId] ?? 0;
        result[petId] = count;
        final cacheKey = 'count_${clinicId}_$petId';
        _appointmentCountCache[cacheKey] = count;
        _cacheTimestamps[cacheKey] = DateTime.now();
      }
    }

    return result;
  }

  /// Batch determine health status for multiple pets
  static Future<Map<String, PatientHealthStatus>> _batchDetermineHealthStatus(String clinicId, List<String> petIds) async {
    final Map<String, PatientHealthStatus> result = {};
    final List<String> uncachedPetIds = [];

    // Check cache first
    for (final petId in petIds) {
      final cacheKey = 'health_${clinicId}_$petId';
      if (_isCacheValid(cacheKey) && _healthStatusCache.containsKey(cacheKey)) {
        result[petId] = _healthStatusCache[cacheKey]!;
      } else {
        uncachedPetIds.add(petId);
      }
    }

    // Batch determine health status for uncached pets
    if (uncachedPetIds.isNotEmpty) {
      // Get latest appointments for all pets in batch
      final querySnapshot = await _firestore
          .collection('appointments')
          .where('clinicId', isEqualTo: clinicId)
          .where('petId', whereIn: uncachedPetIds.length > 10 
              ? uncachedPetIds.take(10).toList() 
              : uncachedPetIds)
          .orderBy('appointmentDate', descending: true)
          .get();

      // Process latest appointments to determine health status
      final latestAppointments = <String, Map<String, dynamic>>{};
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final petId = data['petId'] as String;
        
        // Keep only the latest appointment per pet
        if (!latestAppointments.containsKey(petId)) {
          latestAppointments[petId] = data;
        }
      }

      // Handle remaining pets if more than 10
      if (uncachedPetIds.length > 10) {
        for (int i = 10; i < uncachedPetIds.length; i += 10) {
          final chunk = uncachedPetIds.skip(i).take(10).toList();
          final chunkQuery = await _firestore
              .collection('appointments')
              .where('clinicId', isEqualTo: clinicId)
              .where('petId', whereIn: chunk)
              .orderBy('appointmentDate', descending: true)
              .get();

          for (final doc in chunkQuery.docs) {
            final data = doc.data();
            final petId = data['petId'] as String;
            
            if (!latestAppointments.containsKey(petId)) {
              latestAppointments[petId] = data;
            }
          }
        }
      }

      // Determine health status based on latest appointments
      for (final petId in uncachedPetIds) {
        PatientHealthStatus status = PatientHealthStatus.healthy; // Default
        
        final latestAppt = latestAppointments[petId];
        if (latestAppt != null) {
          final appointmentStatus = latestAppt['status'] as String?;
          final appointmentDate = (latestAppt['appointmentDate'] as Timestamp?)?.toDate();
          
          if (appointmentStatus == 'confirmed') {
            // Has upcoming appointment
            status = PatientHealthStatus.scheduled;
          } else if (appointmentStatus == 'completed') {
            // Check if recent completion suggests ongoing treatment
            if (appointmentDate != null) {
              final daysSinceVisit = DateTime.now().difference(appointmentDate).inDays;
              if (daysSinceVisit <= 7) {
                // Recent visit, might need follow-up
                status = PatientHealthStatus.treatment;
              } else {
                status = PatientHealthStatus.healthy;
              }
            }
          }
        }
        
        result[petId] = status;
        final cacheKey = 'health_${clinicId}_$petId';
        _healthStatusCache[cacheKey] = status;
        _cacheTimestamps[cacheKey] = DateTime.now();
      }
    }

    return result;
  }

  /// Get paginated patient records for a clinic with performance optimizations
  /// Includes pets with confirmed or completed appointments
  static Future<PaginatedPatientResult> getClinicPatients({
    required String clinicId,
    DocumentSnapshot? lastDocument,
    String? searchQuery,
    String? petType, // Filter by pet type (Dog, Cat, etc.)
    PatientHealthStatus? healthStatus,
  }) async {
    // Prevent concurrent calls to the same clinic
    final callKey = '${clinicId}_${lastDocument?.id ?? 'initial'}';
    if (_loadingClinics.contains(callKey)) {
      print('⚠️ Already loading patients for clinic $clinicId, skipping duplicate');
      return PaginatedPatientResult(
        patients: [],
        lastDocument: null,
        hasMore: false,
      );
    }
    
    _loadingClinics.add(callKey);
    
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

      // Step 1: Extract appointments and collect unique pet/owner IDs
      final Map<String, AppointmentBooking> latestAppointments = {};
      final Set<String> uniquePetIds = {};
      final Set<String> uniqueOwnerIds = {};
      
      for (final doc in querySnapshot.docs) {
        final appointmentData = doc.data() as Map<String, dynamic>;
        final appointment = AppointmentBooking.fromMap(appointmentData, doc.id);

        uniquePetIds.add(appointment.petId);
        uniqueOwnerIds.add(appointment.userId);

        // Keep track of latest appointment per pet
        if (!latestAppointments.containsKey(appointment.petId) ||
            appointment.appointmentDate.isAfter(latestAppointments[appointment.petId]!.appointmentDate)) {
          latestAppointments[appointment.petId] = appointment;
        }
      }

      print('🔄 Batch fetching ${uniquePetIds.length} pets and ${uniqueOwnerIds.length} owners');

      // Step 2: Batch fetch all pets and owners concurrently
      final futures = <Future>[
        _batchFetchPets(uniquePetIds.toList()),
        _batchFetchOwners(uniqueOwnerIds.toList()),
      ];

      final results = await Future.wait(futures);
      final Map<String, Pet> petsMap = results[0] as Map<String, Pet>;
      final Map<String, UserModel> ownersMap = results[1] as Map<String, UserModel>;

      print('✅ Fetched ${petsMap.length} pets and ${ownersMap.length} owners');

      // Step 3: Batch fetch appointment counts and health statuses
      final petIds = latestAppointments.keys.toList();
      final appointmentCounts = await _batchGetAppointmentCounts(clinicId, petIds);
      final healthStatuses = await _batchDetermineHealthStatus(clinicId, petIds);

      print('🩺 Calculated health data for ${petIds.length} pets');

      // Step 4: Process patient records
      final Map<String, PatientRecord> uniquePatients = {};

      for (final appointment in latestAppointments.values) {
        final pet = petsMap[appointment.petId];
        if (pet == null) continue;

        // Apply filters early to avoid unnecessary processing
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

        final owner = ownersMap[appointment.userId];

        // Get cached data
        final appointmentCount = appointmentCounts[appointment.petId] ?? 0;
        final healthStatus = healthStatuses[appointment.petId] ?? PatientHealthStatus.healthy;

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
    } finally {
      _loadingClinics.remove(callKey);
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
