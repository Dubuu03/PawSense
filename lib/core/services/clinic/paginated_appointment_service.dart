import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawsense/core/models/clinic/appointment_booking_model.dart';
import 'package:pawsense/core/models/clinic/appointment_models.dart' as AppointmentModels;
import 'package:pawsense/core/models/user/pet_model.dart' as UserModels;

/// Paginated appointment service for efficient data loading
class PaginatedAppointmentService {
  static const int _pageSize = 10; // Load 10 appointments at a time for faster initial load
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get paginated appointments for a clinic
  static Future<PaginatedAppointmentResult> getClinicAppointmentsPaginated({
    required String clinicId,
    DocumentSnapshot? lastDocument,
    DateTime? startDate,
    DateTime? endDate,
    AppointmentStatus? status,
  }) async {
    try {
      Query query = _firestore
          .collection('appointments')
          .where('clinicId', isEqualTo: clinicId);

      // Add date filters if provided
      if (startDate != null) {
        query = query.where('appointmentDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      if (endDate != null) {
        query = query.where('appointmentDate',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      // Add status filter if provided
      if (status != null) {
        query = query.where('status', isEqualTo: status.toString().split('.').last);
      }

      // Order by appointment date
      query = query.orderBy('appointmentDate', descending: false);

      // Pagination: start after last document if provided
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      // Limit to page size + 1 to check if there are more pages
      query = query.limit(_pageSize + 1);

      final querySnapshot = await query.get();
      
      // Check if there are more pages
      final hasMore = querySnapshot.docs.length > _pageSize;
      
      // Take only the requested page size
      final docs = hasMore 
          ? querySnapshot.docs.sublist(0, _pageSize)
          : querySnapshot.docs;
      
      final appointments = <AppointmentModels.Appointment>[];

      // Convert bookings to appointments in parallel for faster loading
      final futures = docs.map((doc) async {
        final booking = AppointmentBooking.fromMap(
          doc.data() as Map<String, dynamic>, 
          doc.id
        );
        return await _convertBookingToAppointment(booking);
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
      );
    } catch (e) {
      print('❌ Error getting paginated appointments: $e');
      return PaginatedAppointmentResult(
        appointments: [],
        lastDocument: null,
        hasMore: false,
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

  PaginatedAppointmentResult({
    required this.appointments,
    required this.lastDocument,
    required this.hasMore,
  });
}
