import 'package:pawsense/core/services/notifications/notification_service.dart';
import 'package:pawsense/core/models/notifications/notification_model.dart';

/// Integration utilities for appointment booking notifications
/// This class provides helper methods that are automatically called
/// by the appointment booking and management services.
class AppointmentBookingIntegration {
  
  /// Creates a pending notification when user submits an appointment booking
  /// This is automatically called by AppointmentBookingService.bookAppointment()
  static Future<void> onAppointmentBooked({
    required String userId,
    required String petName,
    required String clinicName,
    required DateTime requestedDate,
    required String requestedTime,
    String? appointmentId,
    bool isEmergency = false,
    String? symptoms,
  }) async {
    try {
      await NotificationService.createPendingAppointmentNotification(
        userId: userId,
        petName: petName,
        clinicName: clinicName,
        requestedDate: requestedDate,
        requestedTime: requestedTime,
        appointmentId: appointmentId,
        isEmergency: isEmergency,
      );
      
      print('✅ Pending appointment notification created for user $userId');
    } catch (e) {
      print('❌ Failed to create pending notification: $e');
    }
  }
  
  /// Creates status change notification when appointment status is updated
  /// This is automatically called by both:
  /// - AppointmentBookingService.updateAppointmentStatus() (mobile)
  /// - AppointmentService.updateAppointmentStatus() (admin/clinic)
  static Future<void> onAppointmentStatusChanged({
    required String userId,
    required String appointmentId,
    required String petName,
    required String clinicName,
    required String oldStatus,
    required String newStatus,
    DateTime? appointmentDate,
    String? appointmentTime,
    String? reason,
  }) async {
    try {
      await NotificationService.updateAppointmentStatusNotification(
        userId: userId,
        appointmentId: appointmentId,
        petName: petName,
        clinicName: clinicName,
        oldStatus: oldStatus,
        newStatus: newStatus,
        appointmentDate: appointmentDate,
        appointmentTime: appointmentTime,
        reason: reason,
      );
      
      print('✅ Status change notification updated: $oldStatus → $newStatus');
    } catch (e) {
      print('❌ Failed to update status change notification: $e');
    }
  }

  /// Creates notification when appointment is automatically cancelled due to expiration
  /// This is automatically called by AppointmentAutoCancellationService
  static Future<void> onAppointmentCancelled({
    required String userId,
    required String petName,
    required String clinicName,
    required DateTime appointmentDate,
    required String appointmentTime,
    String? appointmentId,
    String? cancelReason,
    bool cancelledByClinic = false,
    bool isAutoCancelled = false,
    bool isNoShow = false,
  }) async {
    try {
      // Skip notification if this is a no-show (has its own specific notification)
      if (isNoShow) {
        print('⏭️ Skipping generic cancellation notification for no-show appointment');
        return;
      }
      
      String title;
      String message;
      
      if (isAutoCancelled) {
        // NO EMOJI for auto-cancelled
        title = 'Appointment Automatically Cancelled';
        message = 'Your appointment for $petName at $clinicName on ${_formatDate(appointmentDate)} at $appointmentTime was automatically cancelled because the scheduled time has passed without clinic confirmation.';
      } else if (cancelledByClinic) {
        title = 'Appointment Cancelled';
        message = 'Your appointment for $petName at $clinicName on ${_formatDate(appointmentDate)} at $appointmentTime has been cancelled. Reason: ${cancelReason ?? "Not specified"}';
      } else {
        title = 'Appointment Cancelled';
        message = 'Your appointment for $petName at $clinicName on ${_formatDate(appointmentDate)} at $appointmentTime has been cancelled.';
      }
      
      await NotificationService.createNotification(
        userId: userId,
        title: title,
        message: message,
        category: NotificationCategory.appointment,
        priority: isAutoCancelled ? NotificationPriority.medium : NotificationPriority.high,
        actionUrl: appointmentId != null ? '/appointments/$appointmentId' : null,
        metadata: {
          'appointmentId': appointmentId,
          'petName': petName,
          'clinicName': clinicName,
          'appointmentDate': appointmentDate.toIso8601String(),
          'appointmentTime': appointmentTime,
          'cancelReason': cancelReason ?? (isAutoCancelled ? 'Auto-cancelled due to expiration' : 'Cancelled'),
          'isAutoCancelled': isAutoCancelled,
          'cancelledByClinic': cancelledByClinic,
          'notificationSource': 'onAppointmentCancelled',  // DEBUG: Track source
        },
      );
      
      print('✅ Cancellation notification created for user $userId (auto: $isAutoCancelled)');
      print('   📋 Title: "$title"');
      print('   📝 Message: "${message.substring(0, message.length > 50 ? 50 : message.length)}..."');
    } catch (e) {
      print('❌ Failed to create cancellation notification: $e');
    }
  }

  /// Creates notification when appointment is marked as No Show
  /// This is called by AppointmentService.markAsNoShow()
  static Future<void> onAppointmentNoShow({
    required String userId,
    required String petName,
    required DateTime appointmentDate,
    required String appointmentTime,
    String? appointmentId,
  }) async {
    try {
      final title = 'Appointment Marked as No Show';
      final message = 'Your appointment for $petName on ${_formatDate(appointmentDate)} at $appointmentTime has been marked as a no-show because you did not arrive for your scheduled appointment.';
      
      print('🔔 Creating NO SHOW notification for user: $userId');
      print('   Pet: $petName');
      print('   Date/Time: ${_formatDate(appointmentDate)} at $appointmentTime');
      
      await NotificationService.createNotification(
        userId: userId,
        title: title,
        message: message,
        category: NotificationCategory.appointment,
        priority: NotificationPriority.high,
        actionUrl: appointmentId != null ? '/appointments/$appointmentId' : null,
        metadata: {
          'appointmentId': appointmentId,
          'petName': petName,
          'appointmentDate': appointmentDate.toIso8601String(),
          'appointmentTime': appointmentTime,
          'status': 'cancelled',  // Add status for proper alert type mapping
          'isNoShow': true,
          'notificationSource': 'onAppointmentNoShow',  // DEBUG: Track source
        },
      );
      
      print('✅ No-show notification created for user $userId');
      print('   📋 Title: "$title"');
      print('   📝 Message: "${message.substring(0, message.length > 50 ? 50 : message.length)}..."');
    } catch (e) {
      print('❌ Failed to create no-show notification: $e');
    }
  }
  
  static String _formatDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}