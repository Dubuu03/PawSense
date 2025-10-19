import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawsense/core/models/clinic/appointment_booking_model.dart';
import 'package:pawsense/core/services/notifications/appointment_booking_integration.dart';
import 'package:pawsense/core/services/admin/admin_appointment_notification_integrator.dart';

/// Service for automatically cancelling pending appointments that have expired
/// 
/// Best Practice Implementation:
/// - Only auto-cancels PENDING appointments (not confirmed ones)
/// - Auto-cancels the day AFTER scheduled date (gives clinic full day to confirm)
/// - Example: Appointment on Oct 24 → Auto-cancel on Oct 25 if still pending
/// - Sends notifications to both user and admin
/// - Provides clear cancellation reason
class AppointmentAutoCancellationService {
  static const String _collection = 'appointments';
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Grace period after appointment DATE before auto-cancellation
  /// Auto-cancels on the next day (midnight) if appointment is still pending
  /// Example: Appointment on Oct 24 → Auto-cancel on Oct 25 00:00 if not confirmed
  static const Duration _gracePeriod = Duration(days: 1);
  
  /// How far back to check for expired appointments
  static const Duration _lookbackWindow = Duration(days: 7);
  
  /// Auto-cancel reason text
  static const String _autoCancelReason = 
    'Appointment automatically cancelled - scheduled date has passed without clinic confirmation';

  /// Process all expired pending appointments
  /// This should be called periodically (e.g., every hour via Cloud Functions or app startup)
  /// 
  /// Returns: Map with counts of processed appointments
  static Future<Map<String, int>> processExpiredAppointments() async {
    final stats = {
      'checked': 0,
      'cancelled': 0,
      'failed': 0,
    };

    try {
      print('🔍 Checking for expired pending appointments...');
      
      // Calculate cutoff time (appointments before this are expired)
      final cutoffTime = DateTime.now().subtract(_gracePeriod);
      final lookbackTime = DateTime.now().subtract(_lookbackWindow);
      
      // Query pending appointments that are past their scheduled time
      final query = await _firestore
          .collection(_collection)
          .where('status', isEqualTo: AppointmentStatus.pending.name)
          .where('appointmentDate', 
              isGreaterThanOrEqualTo: Timestamp.fromDate(lookbackTime))
          .where('appointmentDate', 
              isLessThan: Timestamp.fromDate(cutoffTime))
          .get();
      
      stats['checked'] = query.docs.length;
      
      if (query.docs.isEmpty) {
        print('✅ No expired pending appointments found');
        return stats;
      }
      
      print('⏰ Found ${query.docs.length} potentially expired appointments');
      
      // Process each expired appointment
      for (final doc in query.docs) {
        try {
          final appointment = AppointmentBooking.fromMap(doc.data(), doc.id);
          
          // Double-check if appointment is truly expired
          if (_isAppointmentExpired(appointment)) {
            await _cancelExpiredAppointment(appointment);
            stats['cancelled'] = (stats['cancelled'] ?? 0) + 1;
            print('❌ Auto-cancelled appointment ${appointment.id}');
          }
        } catch (e) {
          print('⚠️ Failed to cancel appointment ${doc.id}: $e');
          stats['failed'] = (stats['failed'] ?? 0) + 1;
        }
      }
      
      print('✅ Auto-cancellation complete: ${stats['cancelled']} cancelled, ${stats['failed']} failed');
      
    } catch (e) {
      print('❌ Error processing expired appointments: $e');
    }
    
    return stats;
  }

  /// Check if a specific appointment should be auto-cancelled
  static bool _isAppointmentExpired(AppointmentBooking appointment) {
    // Only cancel pending appointments
    if (appointment.status != AppointmentStatus.pending) {
      return false;
    }
    
    try {
      // Get the appointment date (ignore time - we care about the day)
      final appointmentDate = DateTime(
        appointment.appointmentDate.year,
        appointment.appointmentDate.month,
        appointment.appointmentDate.day,
      );
      
      // Get today's date (midnight)
      final today = DateTime.now();
      final todayMidnight = DateTime(today.year, today.month, today.day);
      
      // Auto-cancel if we're past the appointment date
      // Example: Appointment on Oct 24 → Cancel on Oct 25 (next day)
      final isExpired = todayMidnight.isAfter(appointmentDate);
      
      if (isExpired) {
        print('📅 Appointment ${appointment.id} scheduled for ${appointmentDate.toIso8601String().split('T')[0]} - Now is ${todayMidnight.toIso8601String().split('T')[0]} - EXPIRED');
      }
      
      return isExpired;
      
    } catch (e) {
      print('⚠️ Error checking appointment expiry: $e');
      return false;
    }
  }

  /// Cancel an expired appointment and send notifications
  static Future<void> _cancelExpiredAppointment(AppointmentBooking appointment) async {
    try {
      // Update appointment status to cancelled
      // Note: We set autoCancelled BEFORE status to prevent double notifications
      await _firestore.collection(_collection).doc(appointment.id).update({
        'autoCancelled': true, // Flag FIRST to prevent duplicate notifications
        'status': AppointmentStatus.cancelled.name,
        'cancelReason': _autoCancelReason,
        'cancelledAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      // Send notification to user
      await _notifyUserOfAutoCancellation(appointment);
      
      // Send notification to admin
      await _notifyAdminOfAutoCancellation(appointment);
      
    } catch (e) {
      print('❌ Error cancelling expired appointment ${appointment.id}: $e');
      rethrow;
    }
  }

  /// Notify user that their appointment was auto-cancelled
  static Future<void> _notifyUserOfAutoCancellation(AppointmentBooking appointment) async {
    try {
      // Get clinic name for notification
      String clinicName = 'the clinic';
      try {
        final clinicDoc = await _firestore
            .collection('clinics')
            .doc(appointment.clinicId)
            .get();
        if (clinicDoc.exists) {
          clinicName = clinicDoc.data()?['clinicName'] ?? clinicName;
        }
      } catch (e) {
        print('⚠️ Could not fetch clinic name: $e');
      }
      
      // Get pet name for notification
      String petName = 'your pet';
      try {
        final petDoc = await _firestore
            .collection('pets')
            .doc(appointment.petId)
            .get();
        if (petDoc.exists) {
          petName = petDoc.data()?['name'] ?? petName;
        }
      } catch (e) {
        print('⚠️ Could not fetch pet name: $e');
      }
      
      // Create user notification using existing notification service
      await AppointmentBookingIntegration.onAppointmentCancelled(
        userId: appointment.userId,
        petName: petName,
        clinicName: clinicName,
        appointmentDate: appointment.appointmentDate,
        appointmentTime: appointment.appointmentTime,
        appointmentId: appointment.id,
        cancelReason: _autoCancelReason,
        cancelledByClinic: false,
        isAutoCancelled: true,
      );
      
    } catch (e) {
      print('⚠️ Failed to notify user of auto-cancellation: $e');
      // Don't rethrow - notification failure shouldn't prevent cancellation
    }
  }

  /// Notify admin that an appointment was auto-cancelled
  static Future<void> _notifyAdminOfAutoCancellation(AppointmentBooking appointment) async {
    try {
      // Get details for admin notification
      String petName = 'Unknown Pet';
      String ownerName = 'Unknown Owner';
      
      try {
        final petDoc = await _firestore
            .collection('pets')
            .doc(appointment.petId)
            .get();
        if (petDoc.exists) {
          petName = petDoc.data()?['name'] ?? petName;
        }
        
        final userDoc = await _firestore
            .collection('users')
            .doc(appointment.userId)
            .get();
        if (userDoc.exists) {
          ownerName = userDoc.data()?['name'] ?? ownerName;
        }
      } catch (e) {
        print('⚠️ Could not fetch pet/owner details: $e');
      }
      
      // Create admin notification
      await AdminAppointmentNotificationIntegrator.notifyAppointmentAutoCancelled(
        appointmentId: appointment.id ?? '',
        petName: petName,
        ownerName: ownerName,
        appointmentDate: appointment.appointmentDate,
        appointmentTime: appointment.appointmentTime,
        serviceName: appointment.serviceName,
      );
      
    } catch (e) {
      print('⚠️ Failed to notify admin of auto-cancellation: $e');
      // Don't rethrow - notification failure shouldn't prevent cancellation
    }
  }

  /// Check and process expired appointments for a specific user
  /// Useful for user-facing checks when they view their appointments
  static Future<List<String>> checkUserExpiredAppointments(String userId) async {
    final cancelledIds = <String>[];
    
    try {
      final cutoffTime = DateTime.now().subtract(_gracePeriod);
      
      final query = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: AppointmentStatus.pending.name)
          .where('appointmentDate', isLessThan: Timestamp.fromDate(cutoffTime))
          .get();
      
      for (final doc in query.docs) {
        try {
          final appointment = AppointmentBooking.fromMap(doc.data(), doc.id);
          if (_isAppointmentExpired(appointment)) {
            await _cancelExpiredAppointment(appointment);
            cancelledIds.add(appointment.id ?? '');
          }
        } catch (e) {
          print('⚠️ Failed to cancel user appointment ${doc.id}: $e');
        }
      }
      
    } catch (e) {
      print('❌ Error checking user expired appointments: $e');
    }
    
    return cancelledIds;
  }

  /// Check and process expired appointments for a specific clinic
  /// Useful for admin dashboard checks
  static Future<List<String>> checkClinicExpiredAppointments(String clinicId) async {
    final cancelledIds = <String>[];
    
    try {
      final cutoffTime = DateTime.now().subtract(_gracePeriod);
      
      final query = await _firestore
          .collection(_collection)
          .where('clinicId', isEqualTo: clinicId)
          .where('status', isEqualTo: AppointmentStatus.pending.name)
          .where('appointmentDate', isLessThan: Timestamp.fromDate(cutoffTime))
          .get();
      
      for (final doc in query.docs) {
        try {
          final appointment = AppointmentBooking.fromMap(doc.data(), doc.id);
          if (_isAppointmentExpired(appointment)) {
            await _cancelExpiredAppointment(appointment);
            cancelledIds.add(appointment.id ?? '');
          }
        } catch (e) {
          print('⚠️ Failed to cancel clinic appointment ${doc.id}: $e');
        }
      }
      
    } catch (e) {
      print('❌ Error checking clinic expired appointments: $e');
    }
    
    return cancelledIds;
  }

  /// Get grace period in hours (for display purposes)
  static int getGracePeriodHours() {
    return _gracePeriod.inHours;
  }
  
  /// Format the auto-cancel reason with specific time information
  static String getAutoCancelReasonWithTime(DateTime appointmentDate, String appointmentTime) {
    return 'Appointment automatically cancelled - scheduled for ${_formatDate(appointmentDate)} at $appointmentTime has passed without clinic confirmation (${_gracePeriod.inHours}hr grace period)';
  }
  
  static String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
