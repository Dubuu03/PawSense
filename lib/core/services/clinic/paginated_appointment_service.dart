import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawsense/core/models/clinic/appointment_booking_model.dart';
import 'package:pawsense/core/models/clinic/appointment_models.dart' as AppointmentModels;
import 'package:pawsense/core/models/user/pet_model.dart' as UserModels;

/// Paginated appointment service for efficient data loading
class PaginatedAppointmentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get paginated appointments for a clinic with page-based pagination
  static Future<PaginatedAppointmentResult> getClinicAppointmentsPaginated({
    required String clinicId,
    DocumentSnapshot? lastDocument,
    DateTime? startDate,
    DateTime? endDate,
    AppointmentStatus? status,
    int page = 1,
    int itemsPerPage = 10,
  }) async {
    try {
      Query query = _firestore
          .collection('appointments')
          .where('clinicId', isEqualTo: clinicId);

  // Add date filters if provided - filter by booking creation date (createdAt / bookedAt)
  // Normalize to start and end of day so UI date pickers behave as expected
  if (startDate != null) {
    // Set to start of day (00:00:00)
    final normalizedStartDate = DateTime(startDate.year, startDate.month, startDate.day, 0, 0, 0);
    query = query.where('createdAt',
    isGreaterThanOrEqualTo: Timestamp.fromDate(normalizedStartDate));
  }
  if (endDate != null) {
    // Set to end of day (23:59:59)
    final normalizedEndDate = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
    query = query.where('createdAt',
    isLessThanOrEqualTo: Timestamp.fromDate(normalizedEndDate));
  }

      // Add status filter if provided
      if (status != null) {
        query = query.where('status', isEqualTo: status.toString().split('.').last);
      }

      // Order by created date descending (newest first)
      query = query.orderBy('createdAt', descending: true);

      // Get total count for pagination info
      final countSnapshot = await query.count().get();
      final totalCount = countSnapshot.count ?? 0;
      final totalPages = (totalCount / itemsPerPage).ceil();

      // Load enough documents to support pagination
      // For small datasets, we can afford to load more and slice
      final maxToLoad = math.min(totalCount, 500); // Cap at 500 for performance
      query = query.limit(maxToLoad);

      final querySnapshot = await query.get();
      
      // Calculate pagination slice
      final startIndex = (page - 1) * itemsPerPage;
      final endIndex = math.min(startIndex + itemsPerPage, querySnapshot.docs.length);
      
      final docs = startIndex < querySnapshot.docs.length 
          ? querySnapshot.docs.sublist(startIndex, endIndex)
          : <QueryDocumentSnapshot>[];
      
      print('📊 Pagination Debug: page=$page, itemsPerPage=$itemsPerPage, totalDocs=${querySnapshot.docs.length}, showing=${docs.length}');
      
      // Check if there are more pages
      final hasMore = page < totalPages;
      
      final appointments = <AppointmentModels.Appointment>[];

      // Convert bookings to appointments in parallel for faster loading
      final futures = docs.map((doc) async {
        final data = doc.data() as Map<String, dynamic>;
        
        // Check if this is a follow-up appointment with embedded data
        if (data['pet'] != null && data['owner'] != null) {
          return await _convertFollowUpAppointment(data, doc.id);
        } else {
          // Legacy booking format - fetch pet/owner separately
          final booking = AppointmentBooking.fromMap(data, doc.id);
          return await _convertBookingToAppointment(booking);
        }
      });

      final results = await Future.wait(futures);
      
      for (final appointment in results) {
        if (appointment != null) {
          appointments.add(appointment);
        }
      }

      return PaginatedAppointmentResult(
        appointments: appointments,
        lastDocument: docs.isNotEmpty ? docs.last : null,
        hasMore: hasMore,
        totalCount: totalCount,
        totalPages: totalPages,
        currentPage: page,
      );
    } catch (e) {
      print('❌ Error getting paginated appointments: $e');
      return PaginatedAppointmentResult(
        appointments: [],
        lastDocument: null,
        hasMore: false,
        totalCount: 0,
        totalPages: 0,
        currentPage: page,
      );
    }
  }

  /// Get total count of appointments for a clinic (for statistics)
  static Future<int> getAppointmentCount({
    required String clinicId,
    AppointmentStatus? status,
  }) async {
    try {
      Query query = _firestore
          .collection('appointments')
          .where('clinicId', isEqualTo: clinicId);

      if (status != null) {
        query = query.where('status', isEqualTo: status.toString().split('.').last);
      }

      final snapshot = await query.count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      print('❌ Error getting appointment count: $e');
      return 0;
    }
  }

  /// Get count of follow-up appointments for a clinic
  static Future<int> getFollowUpAppointmentCount({
    required String clinicId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('appointments')
          .where('clinicId', isEqualTo: clinicId)
          .where('isFollowUp', isEqualTo: true)
          .count()
          .get();
      
      return snapshot.count ?? 0;
    } catch (e) {
      print('❌ Error getting follow-up appointment count: $e');
      return 0;
    }
  }

  /// Get appointment counts by status for a clinic (for status badges/summary)
  static Future<AppointmentStatusCounts> getAppointmentStatusCounts({
    required String clinicId,
  }) async {
    try {
      // Fetch all counts in parallel for better performance
      final futures = await Future.wait([
        getAppointmentCount(clinicId: clinicId, status: AppointmentStatus.pending),
        getAppointmentCount(clinicId: clinicId, status: AppointmentStatus.confirmed),
        getAppointmentCount(clinicId: clinicId, status: AppointmentStatus.completed),
        getAppointmentCount(clinicId: clinicId, status: AppointmentStatus.cancelled),
        getFollowUpAppointmentCount(clinicId: clinicId),
      ]);

      return AppointmentStatusCounts(
        pendingCount: futures[0],
        confirmedCount: futures[1],
        completedCount: futures[2],
        cancelledCount: futures[3],
        followUpCount: futures[4],
      );
    } catch (e) {
      print('❌ Error getting appointment status counts: $e');
      return AppointmentStatusCounts(
        pendingCount: 0,
        confirmedCount: 0,
        completedCount: 0,
        cancelledCount: 0,
        followUpCount: 0,
      );
    }
  }

  /// Convert follow-up appointment with embedded data to Appointment for display
  static Future<AppointmentModels.Appointment?> _convertFollowUpAppointment(
      Map<String, dynamic> data, String documentId) async {
    try {
      // Helper function to safely convert Timestamp to DateTime
      DateTime _safeTimestampToDate(dynamic value, DateTime defaultValue) {
        if (value == null) return defaultValue;
        if (value is Timestamp) return value.toDate();
        if (value is DateTime) return value;
        return defaultValue;
      }

      // Helper function for nullable DateTime
      DateTime? _safeTimestampToDateNullable(dynamic value) {
        if (value == null) return null;
        if (value is Timestamp) return value.toDate();
        if (value is DateTime) return value;
        return null;
      }

      final now = DateTime.now();
      
      // Extract embedded pet data
      final petData = data['pet'] as Map<String, dynamic>? ?? {};
      final pet = AppointmentModels.Pet(
        id: petData['id'] ?? '',
        name: petData['name'] ?? 'Unknown Pet',
        type: petData['type'] ?? 'Unknown',
        emoji: petData['emoji'] ?? _getPetEmoji(petData['type'] ?? ''),
        breed: petData['breed'] ?? 'Unknown',
        age: petData['age'] ?? 0,
        imageUrl: petData['imageUrl'],
      );

      // Extract embedded owner data
      final ownerData = data['owner'] as Map<String, dynamic>? ?? {};
      final owner = AppointmentModels.Owner(
        id: ownerData['id'] ?? '',
        name: ownerData['name'] ?? 'Unknown Owner',
        phone: ownerData['phone'] ?? 'N/A',
        email: ownerData['email'] ?? 'N/A',
      );

      // Parse time slot or create from time
      final timeSlot = data['timeSlot'] ?? _createTimeSlot(data['time'] ?? '');

      // Parse status (convert string to AppointmentModels.AppointmentStatus)
      AppointmentModels.AppointmentStatus status;
      if (data['status'] != null) {
        try {
          final statusStr = data['status'].toString();
          status = AppointmentModels.AppointmentStatus.values.firstWhere(
            (e) => e.name == statusStr,
            orElse: () => AppointmentModels.AppointmentStatus.pending,
          );
        } catch (e) {
          status = AppointmentModels.AppointmentStatus.pending;
        }
      } else {
        status = AppointmentModels.AppointmentStatus.pending;
      }

      final appointment = AppointmentModels.Appointment(
        id: documentId,
        clinicId: data['clinicId'] ?? '',
        date: data['date'] ?? '',
        time: data['time'] ?? '',
        timeSlot: timeSlot,
        pet: pet,
        diseaseReason: data['diseaseReason'] ?? 'N/A',
        owner: owner,
        status: status,
        createdAt: _safeTimestampToDate(data['createdAt'], now),
        updatedAt: _safeTimestampToDate(data['updatedAt'], now),
        cancelReason: data['cancelReason'],
        cancelledAt: _safeTimestampToDateNullable(data['cancelledAt']),
        assessmentResultId: data['assessmentResultId'],
        completedAt: _safeTimestampToDateNullable(data['completedAt']),
        isFollowUp: data['isFollowUp'] == true,
        previousAppointmentId: data['previousAppointmentId'],
        notes: data['notes'],
        // Clinic evaluation fields
        diagnosis: data['diagnosis'],
        treatment: data['treatment'],
        prescription: data['prescription'],
        clinicNotes: data['clinicNotes'],
        needsFollowUp: data['needsFollowUp'],
        followUpDate: data['followUpDate'],
        followUpTime: data['followUpTime'],
      );

      return appointment;
    } catch (e) {
      print('❌ Error converting follow-up appointment to display model: $e');
      return null;
    }
  }

  /// Convert AppointmentBooking to Appointment for display
  static Future<AppointmentModels.Appointment?> _convertBookingToAppointment(
      AppointmentBooking booking) async {
    try {
      // Fetch pet and owner data in parallel
      final futures = await Future.wait([
        _fetchPet(booking.petId, booking.userId),
        _fetchOwner(booking.userId),
      ]);

      final pet = futures[0] as UserModels.Pet;
      final owner = futures[1] as AppointmentModels.Owner;

      // Create time slot from appointment time
      final timeSlot = _createTimeSlot(booking.appointmentTime);

      final appointment = AppointmentModels.Appointment(
        id: booking.id ?? '',
        clinicId: booking.clinicId,
        date: _formatDate(booking.appointmentDate),
        time: booking.appointmentTime,
        timeSlot: timeSlot,
        pet: AppointmentModels.Pet(
          id: pet.id ?? booking.petId,
          name: pet.petName,
          type: pet.petType,
          emoji: _getPetEmoji(pet.petType),
          breed: pet.breed,
          age: pet.age,
          imageUrl: pet.imageUrl,
        ),
        diseaseReason:
            booking.serviceName.isNotEmpty ? booking.serviceName : 'N/A',
        owner: owner,
        status: _convertBookingStatus(booking.status),
        createdAt: booking.createdAt,
        updatedAt: booking.updatedAt,
        cancelReason: booking.cancelReason,
        cancelledAt: booking.cancelledAt,
        assessmentResultId: booking.assessmentResultId,
        completedAt: booking.completedAt,
        // Clinic evaluation fields
        diagnosis: booking.diagnosis,
        treatment: booking.treatment,
        prescription: booking.prescription,
        clinicNotes: booking.clinicNotes,
        isFollowUp: booking.isFollowUp,
        previousAppointmentId: booking.previousAppointmentId,
      );

      return appointment;
    } catch (e) {
      print('❌ Error converting booking to appointment: $e');
      return null;
    }
  }

  /// Fetch pet details with fallback
  static Future<UserModels.Pet> _fetchPet(String petId, String userId) async {
    try {
      final petDoc = await _firestore.collection('pets').doc(petId).get();
      if (petDoc.exists) {
        return UserModels.Pet.fromMap(petDoc.data()!, petDoc.id);
      }
    } catch (e) {
      print('⚠️ Error fetching pet $petId: $e');
    }

    // Return default pet if not found
    return UserModels.Pet(
      id: petId,
      userId: userId,
      petName: 'Unknown Pet',
      petType: 'Unknown',
      age: 0,
      weight: 0.0,
      breed: 'Unknown',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Fetch owner details with fallback
  static Future<AppointmentModels.Owner> _fetchOwner(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;

        // Build full name from firstName + lastName, with fallbacks
        String fullName = '';
        if (userData['firstName'] != null && userData['lastName'] != null) {
          fullName = '${userData['firstName']} ${userData['lastName']}'.trim();
        } else if (userData['fullName'] != null) {
          fullName = userData['fullName'];
        } else if (userData['username'] != null) {
          fullName = userData['username'];
        } else {
          fullName = 'Unknown Owner';
        }

        // Get contact information
        String phone = userData['contactNumber'] ?? userData['phone'] ?? 'N/A';
        String email = userData['email'] ?? 'N/A';

        return AppointmentModels.Owner(
          id: userId,
          name: fullName,
          phone: phone,
          email: email,
        );
      }
    } catch (e) {
      print('⚠️ Error fetching owner $userId: $e');
    }

    // Return default owner if not found
    return AppointmentModels.Owner(
      id: userId,
      name: 'Unknown Owner',
      phone: 'N/A',
      email: 'N/A',
    );
  }

  /// Create time slot from appointment time
  static String _createTimeSlot(String appointmentTime) {
    try {
      final parts = appointmentTime.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      // Assume 20-minute slots
      final endMinute = minute + 20;
      final endHour = hour + (endMinute >= 60 ? 1 : 0);
      final finalEndMinute = endMinute % 60;

      final endTime =
          '${endHour.toString().padLeft(2, '0')}:${finalEndMinute.toString().padLeft(2, '0')}';
      return '$appointmentTime-$endTime';
    } catch (e) {
      return '$appointmentTime-$appointmentTime';
    }
  }

  /// Format DateTime to string
  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Convert booking status to appointment status
  static AppointmentModels.AppointmentStatus _convertBookingStatus(
      AppointmentStatus bookingStatus) {
    switch (bookingStatus) {
      case AppointmentStatus.pending:
        return AppointmentModels.AppointmentStatus.pending;
      case AppointmentStatus.confirmed:
        return AppointmentModels.AppointmentStatus.confirmed;
      case AppointmentStatus.completed:
        return AppointmentModels.AppointmentStatus.completed;
      case AppointmentStatus.cancelled:
        return AppointmentModels.AppointmentStatus.cancelled;
      case AppointmentStatus.rescheduled:
        return AppointmentModels.AppointmentStatus.confirmed; // Treat rescheduled as confirmed
    }
  }

  /// Get pet emoji based on type
  static String _getPetEmoji(String petType) {
    switch (petType.toLowerCase()) {
      case 'dog':
        return '🐕';
      case 'cat':
        return '🐈';
      case 'bird':
        return '🐦';
      case 'rabbit':
        return '🐰';
      case 'hamster':
        return '🐹';
      case 'fish':
        return '🐠';
      case 'reptile':
        return '🦎';
      default:
        return '🐾';
    }
  }
}

/// Result class for paginated appointments
class PaginatedAppointmentResult {
  final List<AppointmentModels.Appointment> appointments;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;
  final int? totalCount;
  final int? totalPages;
  final int? currentPage;

  PaginatedAppointmentResult({
    required this.appointments,
    required this.lastDocument,
    required this.hasMore,
    this.totalCount,
    this.totalPages,
    this.currentPage,
  });
}

/// Result class for appointment status counts
class AppointmentStatusCounts {
  final int pendingCount;
  final int confirmedCount;
  final int completedCount;
  final int cancelledCount;
  final int followUpCount;

  AppointmentStatusCounts({
    required this.pendingCount,
    required this.confirmedCount,
    required this.completedCount,
    required this.cancelledCount,
    this.followUpCount = 0,
  });

  /// Get total count of all appointments
  int get totalCount => pendingCount + confirmedCount + completedCount + cancelledCount;

  @override
  String toString() {
    return 'AppointmentStatusCounts(pending: $pendingCount, confirmed: $confirmedCount, completed: $completedCount, cancelled: $cancelledCount, followUp: $followUpCount, total: $totalCount)';
  }
}
