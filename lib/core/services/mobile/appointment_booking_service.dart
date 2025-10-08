import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawsense/core/models/clinic/appointment_booking_model.dart';
import 'package:pawsense/core/guards/auth_guard.dart';
import 'package:pawsense/core/services/notifications/appointment_booking_integration.dart';

class AppointmentBookingService {
  static const String _collection = 'appointments';
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Book a new appointment
  static Future<String?> bookAppointment({
    required String petId,
    required String clinicId,
    required String serviceName,
    required String serviceId,
    required DateTime appointmentDate,
    required String appointmentTime,
    String notes = '',
    double? estimatedPrice,
    String? duration,
    String? assessmentResultId,
  }) async {
    try {
      final currentUser = await AuthGuard.getCurrentUser();
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final now = DateTime.now();
      final appointment = AppointmentBooking(
        userId: currentUser.uid,
        petId: petId,
        clinicId: clinicId,
        serviceName: serviceName,
        serviceId: serviceId,
        appointmentDate: appointmentDate,
        appointmentTime: appointmentTime,
        notes: notes,
        status: AppointmentStatus.pending,
        type: AppointmentType.general,
        estimatedPrice: estimatedPrice,
        duration: duration,
        createdAt: now,
        updatedAt: now,
        assessmentResultId: assessmentResultId,
      );

      final docRef = await _firestore
          .collection(_collection)
          .add(appointment.toMap());

      print('📋 MOBILE DEBUG: Appointment booked successfully with ID: ${docRef.id}');
      print('🏥 MOBILE DEBUG: Saved with clinicId: $clinicId');
      print('👤 MOBILE DEBUG: Saved with userId: ${currentUser.uid}');
      print('🐾 MOBILE DEBUG: Saved with petId: $petId');
      print('📅 MOBILE DEBUG: Saved for date: $appointmentDate at $appointmentTime');
      print('🔧 MOBILE DEBUG: Service: $serviceName (ID: $serviceId)');
      
      return docRef.id;
    } catch (e) {
      print('Error booking appointment: $e');
      return null;
    }
  }

  /// Get user's appointments
  static Future<List<AppointmentBooking>> getUserAppointments(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .get();

      final appointments = querySnapshot.docs
          .map((doc) => AppointmentBooking.fromMap(doc.data(), doc.id))
          .toList();
      
      // Sort by appointment date in descending order (latest first)
      appointments.sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));
      
      return appointments;
    } catch (e) {
      print('Error getting user appointments: $e');
      return [];
    }
  }

  /// Get upcoming appointments for user
  static Future<List<AppointmentBooking>> getUpcomingAppointments(String userId) async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('appointmentDate', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
          .where('status', whereIn: ['pending', 'confirmed'])
          .orderBy('appointmentDate', descending: false)
          .get();

      return querySnapshot.docs
          .map((doc) => AppointmentBooking.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting upcoming appointments: $e');
      return [];
    }
  }

  /// Get clinic's appointments
  static Future<List<AppointmentBooking>> getClinicAppointments(String clinicId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('clinicId', isEqualTo: clinicId)
          .orderBy('appointmentDate', descending: false)
          .get();

      return querySnapshot.docs
          .map((doc) => AppointmentBooking.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting clinic appointments: $e');
      return [];
    }
  }

  /// Update appointment status
  static Future<bool> updateAppointmentStatus(
    String appointmentId,
    AppointmentStatus newStatus, {
    String? reason,
  }) async {
    try {
      // First get the appointment details for notification
      AppointmentBooking? appointment;
      try {
        final doc = await _firestore.collection(_collection).doc(appointmentId).get();
        if (doc.exists) {
          appointment = AppointmentBooking.fromMap(doc.data()!, doc.id);
        }
      } catch (e) {
        print('Warning: Could not fetch appointment details for notifications: $e');
      }

      final updateData = <String, dynamic>{
        'status': newStatus.name,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (newStatus == AppointmentStatus.cancelled) {
        updateData['cancelReason'] = reason;
        updateData['cancelledAt'] = Timestamp.fromDate(DateTime.now());
      } else if (newStatus == AppointmentStatus.rescheduled) {
        updateData['rescheduleReason'] = reason;
        updateData['rescheduledAt'] = Timestamp.fromDate(DateTime.now());
      }

      await _firestore
          .collection(_collection)
          .doc(appointmentId)
          .update(updateData);

      // Create notification for status change (if we have appointment details)
      if (appointment != null) {
        try {
          // Get additional details for notification
          String petName = 'Your pet';
          String clinicName = 'the clinic';
          
          // Try to fetch pet and clinic names
          try {
            final petDoc = await _firestore.collection('pets').doc(appointment.petId).get();
            if (petDoc.exists) {
              petName = petDoc.data()?['petName'] ?? petName;
            }
            
            final clinicDoc = await _firestore.collection('clinics').doc(appointment.clinicId).get();
            if (clinicDoc.exists) {
              clinicName = clinicDoc.data()?['name'] ?? clinicName;
            }
          } catch (e) {
            print('Warning: Could not fetch pet/clinic names for notification: $e');
          }

          await AppointmentBookingIntegration.onAppointmentStatusChanged(
            userId: appointment.userId,
            appointmentId: appointmentId,
            petName: petName,
            clinicName: clinicName,
            oldStatus: appointment.status.name,
            newStatus: newStatus.name,
            appointmentDate: appointment.appointmentDate,
            appointmentTime: appointment.appointmentTime,
            reason: reason,
          );
        } catch (notificationError) {
          print('⚠️ Failed to create status change notification: $notificationError');
          // Don't fail the status update if notification fails
        }
      }

      return true;
    } catch (e) {
      print('Error updating appointment status: $e');
      return false;
    }
  }

  /// Cancel appointment
  static Future<bool> cancelAppointment(String appointmentId, String reason) async {
    return await updateAppointmentStatus(
      appointmentId,
      AppointmentStatus.cancelled,
      reason: reason,
    );
  }

  /// Confirm appointment (for clinic use)
  static Future<bool> confirmAppointment(String appointmentId) async {
    return await updateAppointmentStatus(appointmentId, AppointmentStatus.confirmed);
  }

  /// Complete appointment (for clinic use)
  static Future<bool> completeAppointment(String appointmentId) async {
    return await updateAppointmentStatus(appointmentId, AppointmentStatus.completed);
  }

  /// Reschedule appointment
  static Future<bool> rescheduleAppointment(
    String appointmentId,
    DateTime newDate,
    String newTime,
    String reason,
  ) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(appointmentId)
          .update({
        'appointmentDate': Timestamp.fromDate(newDate),
        'appointmentTime': newTime,
        'status': AppointmentStatus.rescheduled.name,
        'rescheduleReason': reason,
        'rescheduledAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      return true;
    } catch (e) {
      print('Error rescheduling appointment: $e');
      return false;
    }
  }

  /// Get appointment by ID
  static Future<AppointmentBooking?> getAppointmentById(String appointmentId) async {
    try {
      final doc = await _firestore
          .collection(_collection)
          .doc(appointmentId)
          .get();

      if (doc.exists && doc.data() != null) {
        return AppointmentBooking.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting appointment by ID: $e');
      return null;
    }
  }

  /// Delete appointment (admin only)
  static Future<bool> deleteAppointment(String appointmentId) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(appointmentId)
          .delete();

      return true;
    } catch (e) {
      print('Error deleting appointment: $e');
      return false;
    }
  }

  /// Get appointments by date range
  static Future<List<AppointmentBooking>> getAppointmentsByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('appointmentDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('appointmentDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('appointmentDate', descending: false)
          .get();

      return querySnapshot.docs
          .map((doc) => AppointmentBooking.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting appointments by date range: $e');
      return [];
    }
  }

  /// Get appointment statistics for user
  static Future<Map<String, int>> getAppointmentStats(String userId) async {
    try {
      final appointments = await getUserAppointments(userId);
      
      final stats = <String, int>{
        'total': appointments.length,
        'pending': 0,
        'confirmed': 0,
        'completed': 0,
        'cancelled': 0,
        'upcoming': 0,
      };

      for (final appointment in appointments) {
        stats[appointment.status.name] = (stats[appointment.status.name] ?? 0) + 1;
        if (appointment.isUpcoming) {
          stats['upcoming'] = (stats['upcoming'] ?? 0) + 1;
        }
      }

      return stats;
    } catch (e) {
      print('Error getting appointment stats: $e');
      return {};
    }
  }
}