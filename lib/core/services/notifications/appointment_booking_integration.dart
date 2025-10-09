import 'package:pawsense/core/services/notifications/notification_service.dart';

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
}