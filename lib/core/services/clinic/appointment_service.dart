import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pawsense/core/models/clinic/appointment_booking_model.dart';
import 'package:pawsense/core/models/clinic/appointment_models.dart' as AppointmentModels;
import 'package:pawsense/core/models/user/pet_model.dart' as UserModels;
import 'package:pawsense/core/services/clinic/clinic_schedule_service.dart';
import 'package:pawsense/core/services/notifications/appointment_booking_integration.dart';

class AppointmentService {
  static const String _collection = 'appointments';
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get appointments for admin dashboard (specific clinic)
  static Future<List<AppointmentModels.Appointment>> getClinicAppointments(String clinicId, {
    DateTime? startDate,
    DateTime? endDate,
    AppointmentStatus? status,
  }) async {
    try {
      Query query = _firestore
          .collection(_collection)
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

      // Order by appointment date (now that we have the Firestore index)
      query = query.orderBy('appointmentDate', descending: false);

      final querySnapshot = await query.get();
      
      final appointments = <AppointmentModels.Appointment>[];

      for (final doc in querySnapshot.docs) {
        final appointmentBooking = AppointmentBooking.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        final appointment = await _convertBookingToAppointment(appointmentBooking);
        if (appointment != null) {
          appointments.add(appointment);
        }
      }

      return appointments;
    } catch (e) {
      print('Error getting clinic appointments: $e');
      return [];
    }
  }

  /// Convert AppointmentBooking to Appointment for display
  static Future<AppointmentModels.Appointment?> _convertBookingToAppointment(AppointmentBooking booking) async {
    try {
      // Get pet details with profile picture
      UserModels.Pet? pet;
      try {
        final petDoc = await _firestore.collection('pets').doc(booking.petId).get();
        if (petDoc.exists) {
          pet = UserModels.Pet.fromMap(petDoc.data()!, petDoc.id);
        }
      } catch (e) {
        print('Error fetching pet ${booking.petId}: $e');
      }

      // Get owner details with full name and contact info
      AppointmentModels.Owner? owner;
      try {
        final userDoc = await _firestore.collection('users').doc(booking.userId).get();
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
          
          owner = AppointmentModels.Owner(
            id: booking.userId,
            name: fullName,
            phone: phone,
            email: email,
          );
        }
      } catch (e) {
        print('Error fetching user ${booking.userId}: $e');
      }

      // Set default values if data is missing
      pet ??= UserModels.Pet(
        id: booking.petId,
        userId: booking.userId,
        petName: 'Unknown Pet',
        petType: 'Unknown',
        age: 0,
        weight: 0.0,
        breed: 'Unknown',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      owner ??= AppointmentModels.Owner(
        id: booking.userId,
        name: 'Unknown Owner',
        phone: 'N/A',
        email: 'N/A',
      );

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
          imageUrl: pet.imageUrl, // Include pet profile picture
        ),
        diseaseReason: booking.serviceName.isNotEmpty ? booking.serviceName : 'N/A',
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
      print('Error converting booking to appointment: $e');
      return null;
    }
  }

  /// Create time slot from appointment time (e.g., "09:00" -> "09:00-09:20")
  static String _createTimeSlot(String appointmentTime) {
    try {
      final parts = appointmentTime.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      
      // Assume 20-minute slots for now
      final endMinute = minute + 20;
      final endHour = hour + (endMinute >= 60 ? 1 : 0);
      final finalEndMinute = endMinute % 60;
      
      final endTime = '${endHour.toString().padLeft(2, '0')}:${finalEndMinute.toString().padLeft(2, '0')}';
      return '$appointmentTime-$endTime';
    } catch (e) {
      return '$appointmentTime-$appointmentTime'; // Fallback
    }
  }

  /// Format DateTime to string
  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Convert booking status to appointment status
  static AppointmentModels.AppointmentStatus _convertBookingStatus(AppointmentStatus bookingStatus) {
    // Map from booking status enum to appointment status enum
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
        return AppointmentModels.AppointmentStatus.pending; // Map rescheduled to pending
    }
  }

  /// Get emoji for pet type
  static String _getPetEmoji(String petType) {
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
      case 'fish':
        return '🐠';
      default:
        return '🐾';
    }
  }

  /// Validate if appointment can be booked at given time
  static Future<bool> canBookAtTime(String clinicId, DateTime date, String time) async {
    try {
      // Get clinic schedule for the day
      final dayOfWeek = _getDayOfWeek(date.weekday);
      final scheduleData = await ClinicScheduleService.getDayScheduleWithAvailability(
        clinicId, 
        dayOfWeek, 
        date
      );

      final schedule = scheduleData['schedule'];
      if (schedule == null || !(schedule.isOpen)) {
        return false; // Clinic is closed
      }

      // Check if time is within operating hours
      final appointmentTime = TimeOfDay(
        hour: int.parse(time.split(':')[0]),
        minute: int.parse(time.split(':')[1]),
      );

      final openTime = _parseTimeString(schedule.openTime);
      final closeTime = _parseTimeString(schedule.closeTime);

      if (openTime == null || closeTime == null) {
        return false;
      }

      // Check if appointment time is within operating hours
      if (!_isTimeWithinRange(appointmentTime, openTime, closeTime)) {
        return false;
      }

      // Check if appointment time conflicts with break times
      for (final breakTime in schedule.breakTimes) {
        final breakStart = _parseTimeString(breakTime.startTime);
        final breakEnd = _parseTimeString(breakTime.endTime);
        if (breakStart != null && breakEnd != null) {
          if (_isTimeWithinRange(appointmentTime, breakStart, breakEnd)) {
            return false; // Time is during break
          }
        }
      }

      // Check if there are available slots
      final availableSlots = scheduleData['availableSlots'] ?? 0;
      return availableSlots > 0;

    } catch (e) {
      print('Error validating appointment time: $e');
      return false;
    }
  }

  /// Get available time slots for a clinic on a specific date
  static Future<List<String>> getAvailableTimeSlots(String clinicId, DateTime date) async {
    try {
      final dayOfWeek = _getDayOfWeek(date.weekday);
      final scheduleData = await ClinicScheduleService.getDayScheduleWithAvailability(
        clinicId, 
        dayOfWeek, 
        date
      );

      final schedule = scheduleData['schedule'];
      if (schedule == null || !(schedule.isOpen)) {
        return []; // Clinic is closed
      }

      final openTime = _parseTimeString(schedule.openTime);
      final closeTime = _parseTimeString(schedule.closeTime);
      
      if (openTime == null || closeTime == null) {
        return [];
      }

      // Generate time slots based on slots per hour
      final slotsPerHour = schedule.slotsPerHour;
      final slotDurationMinutes = 60 ~/ slotsPerHour;
      
      final timeSlots = <String>[];
      final appointments = scheduleData['appointments'] as List<Map<String, dynamic>>? ?? [];
      final bookedTimes = appointments.map((apt) => apt['appointmentTime'] as String).toSet();

      // Generate slots from open to close time
      var currentTime = openTime;
      while (_isTimeBefore(currentTime, closeTime)) {
        final timeString = '${currentTime.hour.toString().padLeft(2, '0')}:${currentTime.minute.toString().padLeft(2, '0')}';
        
        // Check if time is not during break and not already booked
        bool isAvailable = true;
        
        // Check break times
        for (final breakTime in schedule.breakTimes) {
          final breakStart = _parseTimeString(breakTime.startTime);
          final breakEnd = _parseTimeString(breakTime.endTime);
          if (breakStart != null && breakEnd != null) {
            if (_isTimeWithinRange(currentTime, breakStart, breakEnd)) {
              isAvailable = false;
              break;
            }
          }
        }
        
        // Check if already booked
        if (bookedTimes.contains(timeString)) {
          isAvailable = false;
        }

        if (isAvailable) {
          timeSlots.add(timeString);
        }

        // Move to next slot
        final newMinute = currentTime.minute + slotDurationMinutes;
        currentTime = TimeOfDay(
          hour: currentTime.hour + (newMinute >= 60 ? 1 : 0),
          minute: newMinute % 60,
        );
      }

      return timeSlots;
    } catch (e) {
      print('Error getting available time slots: $e');
      return [];
    }
  }

  /// Update appointment status
  static Future<bool> updateAppointmentStatus(String appointmentId, AppointmentModels.AppointmentStatus status) async {
    try {
      // First get the appointment details for notification
      AppointmentModels.Appointment? appointment;
      try {
        final doc = await _firestore.collection(_collection).doc(appointmentId).get();
        if (doc.exists) {
          final data = doc.data()!;
          appointment = AppointmentModels.Appointment.fromFirestore(data, doc.id);
        }
      } catch (e) {
        print('Warning: Could not fetch appointment details for notifications: $e');
      }

      await _firestore.collection(_collection).doc(appointmentId).update({
        'status': status.toString().split('.').last,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Create notification for status change (if we have appointment details)
      if (appointment != null) {
        try {
          await AppointmentBookingIntegration.onAppointmentStatusChanged(
            userId: appointment.owner.id,
            appointmentId: appointmentId,
            petName: appointment.pet.name,
            clinicName: 'Clinic', // Will be updated in the integration method
            oldStatus: appointment.status.toString().split('.').last,
            newStatus: status.toString().split('.').last,
            appointmentDate: DateTime.tryParse(appointment.date.replaceAll('-', '')),
            appointmentTime: appointment.time,
            reason: status == AppointmentModels.AppointmentStatus.cancelled ? 
              'Cancelled by clinic administration' : null,
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

  /// Public method to check slot availability for a specific time
  /// Useful for UI to show available slots or warn about conflicts
  static Future<bool> isTimeSlotAvailable(String clinicId, DateTime date, String time) async {
    try {
      // Get the day of week for the date
      final dayOfWeek = _getDayOfWeek(date.weekday);

      // Get clinic schedule for this day
      final schedule = await ClinicScheduleService.getScheduleForDay(clinicId, dayOfWeek);
      if (schedule == null || !schedule.isOpen) {
        return false; // Clinic is closed on this day
      }

      // Parse time to determine the time slot
      final timeParts = time.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      // Calculate the slot based on slotDurationMinutes
      final slotDuration = schedule.slotDurationMinutes;
      final slotIndex = minute ~/ slotDuration;

      // Get all confirmed appointments for this clinic on this date
      // Split the query to avoid composite index requirement
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final existingAppointments = await _firestore
          .collection(_collection)
          .where('clinicId', isEqualTo: clinicId)
          .where('appointmentDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('appointmentDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();

      // Filter for confirmed appointments in code to avoid composite index
      final confirmedAppointments = existingAppointments.docs.where((doc) {
        final data = doc.data();
        return data['status'] == 'confirmed';
      }).toList();

      // Count appointments in the same time slot
      int sameSlotCount = 0;
      for (final doc in confirmedAppointments) {
        final data = doc.data();
        final existingTime = data['appointmentTime'] as String;
        final existingTimeParts = existingTime.split(':');
        final existingHour = int.parse(existingTimeParts[0]);
        final existingMinute = int.parse(existingTimeParts[1]);

        // Check if it's in the same hour and same time slot
        if (existingHour == hour) {
          final existingSlotIndex = existingMinute ~/ slotDuration;
          if (existingSlotIndex == slotIndex) {
            sameSlotCount++;
          }
        }
      }

      return sameSlotCount < 1; // Only allow 1 appointment per time slot
    } catch (e) {
      print('Error checking time slot availability: $e');
      return false;
    }
  }

  /// Check if accepting an appointment would exceed slot capacity
  static Future<bool> _canAcceptAppointment(String appointmentId) async {
    try {
      // Get the appointment details
      final appointmentDoc = await _firestore.collection(_collection).doc(appointmentId).get();
      if (!appointmentDoc.exists) {
        return false;
      }

      final appointmentData = appointmentDoc.data()!;
      final clinicId = appointmentData['clinicId'] as String;
      final appointmentDate = (appointmentData['appointmentDate'] as Timestamp).toDate();
      final appointmentTime = appointmentData['appointmentTime'] as String;

      // Get the day of week for the appointment
      final dayOfWeek = _getDayOfWeek(appointmentDate.weekday);

      // Get clinic schedule for this day
      final schedule = await ClinicScheduleService.getScheduleForDay(clinicId, dayOfWeek);
      if (schedule == null || !schedule.isOpen) {
        return false; // Clinic is closed on this day
      }

      // Parse appointment time to determine the time slot
      final timeParts = appointmentTime.split(':');
      final appointmentHour = int.parse(timeParts[0]);
      final appointmentMinute = int.parse(timeParts[1]);

      // Calculate the slot based on slotDurationMinutes
      final slotDuration = schedule.slotDurationMinutes;
      
      // Determine which slot within the hour this appointment belongs to
      final slotIndex = appointmentMinute ~/ slotDuration;

      // Get all appointments for this clinic on this date
      // Split the query to avoid composite index requirement
      final startOfDay = DateTime(appointmentDate.year, appointmentDate.month, appointmentDate.day);
      final endOfDay = DateTime(appointmentDate.year, appointmentDate.month, appointmentDate.day, 23, 59, 59);

      final existingAppointments = await _firestore
          .collection(_collection)
          .where('clinicId', isEqualTo: clinicId)
          .where('appointmentDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('appointmentDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();

      // Filter for confirmed appointments in code to avoid composite index
      final confirmedAppointments = existingAppointments.docs.where((doc) {
        final data = doc.data();
        return data['status'] == 'confirmed';
      }).toList();

      // Count appointments in the same time slot
      int sameSlotCount = 0;
      print('Checking slot availability for $appointmentTime on ${appointmentDate.day}/${appointmentDate.month}');
      print('Slot index: $slotIndex (duration: ${slotDuration}min)');
      print('Found ${confirmedAppointments.length} confirmed appointments on this day');
      
      for (final doc in confirmedAppointments) {
        final data = doc.data();
        final existingTime = data['appointmentTime'] as String;
        final existingTimeParts = existingTime.split(':');
        final existingHour = int.parse(existingTimeParts[0]);
        final existingMinute = int.parse(existingTimeParts[1]);

        // Check if it's in the same hour and same time slot
        if (existingHour == appointmentHour) {
          final existingSlotIndex = existingMinute ~/ slotDuration;
          print('Existing appointment at $existingTime (slot index: $existingSlotIndex)');
          if (existingSlotIndex == slotIndex) {
            sameSlotCount++;
            print('CONFLICT: Same slot index $slotIndex');
          }
        }
      }

      print('Same slot count: $sameSlotCount');
      
      // Check if we have capacity
      // Each time slot should allow only 1 appointment (unless configured otherwise)
      if (sameSlotCount >= 1) {
        print('Slot is occupied, cannot accept');
        return false; // Time slot is already occupied
      }
      
      print('Slot is available');
      return true; // Slot is available
    } catch (e) {
      print('Error checking appointment slot availability: $e');
      return false;
    }
  }

  /// Helper method to get day of week string
  static String _getDayOfWeek(int weekday) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[weekday - 1];
  }

  /// Accept an appointment (change status to confirmed) with slot validation
  /// Returns a map with 'success' boolean and 'message' string
  static Future<Map<String, dynamic>> acceptAppointment(String appointmentId) async {
    try {
      // Get appointment details for better error messages
      final appointmentDoc = await _firestore.collection(_collection).doc(appointmentId).get();
      if (!appointmentDoc.exists) {
        return {
          'success': false,
          'message': 'Appointment not found'
        };
      }

      final appointmentData = appointmentDoc.data()!;
      final appointmentTime = appointmentData['appointmentTime'] as String;
      final appointmentDate = (appointmentData['appointmentDate'] as Timestamp).toDate();
      
      // Check if the appointment can be accepted without exceeding slot capacity
      final canAccept = await _canAcceptAppointment(appointmentId);
      if (!canAccept) {
        return {
          'success': false,
          'message': 'Cannot accept appointment: Time slot $appointmentTime on ${appointmentDate.day}/${appointmentDate.month}/${appointmentDate.year} is already occupied'
        };
      }

      await _firestore.collection(_collection).doc(appointmentId).update({
        'status': AppointmentModels.AppointmentStatus.confirmed.toString().split('.').last,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      return {
        'success': true,
        'message': 'Appointment accepted successfully'
      };
    } catch (e) {
      print('Error accepting appointment: $e');
      return {
        'success': false,
        'message': 'Failed to accept appointment: ${e.toString()}'
      };
    }
  }

  /// Reject an appointment (change status to cancelled with reason)
  static Future<bool> rejectAppointment(String appointmentId, String cancelReason) async {
    try {
      await _firestore.collection(_collection).doc(appointmentId).update({
        'status': AppointmentModels.AppointmentStatus.cancelled.toString().split('.').last,
        'cancelReason': cancelReason,
        'cancelledAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      return true;
    } catch (e) {
      print('Error rejecting appointment: $e');
      return false;
    }
  }

  /// Mark an appointment as completed
  static Future<bool> markAppointmentCompleted(String appointmentId) async {
    try {
      await _firestore.collection(_collection).doc(appointmentId).update({
        'status': AppointmentModels.AppointmentStatus.completed.toString().split('.').last,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      return true;
    } catch (e) {
      print('Error marking appointment as completed: $e');
      return false;
    }
  }

  /// Re-accept a cancelled appointment (change status back to confirmed and clear cancel data)
  static Future<bool> reAcceptAppointment(String appointmentId) async {
    try {
      await _firestore.collection(_collection).doc(appointmentId).update({
        'status': AppointmentModels.AppointmentStatus.confirmed.toString().split('.').last,
        'cancelReason': FieldValue.delete(),
        'cancelledAt': FieldValue.delete(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      return true;
    } catch (e) {
      print('Error re-accepting appointment: $e');
      return false;
    }
  }

  // Helper methods
  static TimeOfDay? _parseTimeString(String? timeString) {
    if (timeString == null) return null;
    try {
      final parts = timeString.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (e) {
      return null;
    }
  }

  static bool _isTimeWithinRange(TimeOfDay time, TimeOfDay start, TimeOfDay end) {
    final timeInMinutes = time.hour * 60 + time.minute;
    final startInMinutes = start.hour * 60 + start.minute;
    final endInMinutes = end.hour * 60 + end.minute;
    
    return timeInMinutes >= startInMinutes && timeInMinutes < endInMinutes;
  }

  static bool _isTimeBefore(TimeOfDay time1, TimeOfDay time2) {
    final time1InMinutes = time1.hour * 60 + time1.minute;
    final time2InMinutes = time2.hour * 60 + time2.minute;
    return time1InMinutes < time2InMinutes;
  }
}