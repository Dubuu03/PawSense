import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawsense/core/models/clinic/appointment_booking_model.dart';
import 'package:pawsense/core/guards/auth_guard.dart';
import 'package:pawsense/core/services/notifications/appointment_booking_integration.dart';
import 'package:pawsense/core/services/clinic/appointment_auto_cancellation_service.dart';

class AppointmentBookingService {
  static const String _collection = 'appointments';
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Rate limiting: Track recent booking attempts per user
  static final Map<String, List<DateTime>> _userBookingAttempts = {};
  static const int _maxBookingsPerWindow = 3; // Max 3 bookings
  static const Duration _rateLimitWindow = Duration(minutes: 5); // Within 5 minutes

  /// Check for duplicate booking (same user, pet, clinic, date, time)
  static Future<bool> checkForDuplicateBooking({
    required String userId,
    required String petId,
    required String clinicId,
    required DateTime appointmentDate,
    required String appointmentTime,
  }) async {
    try {
      // Normalize date to start of day for comparison
      final startOfDay = DateTime(appointmentDate.year, appointmentDate.month, appointmentDate.day);
      final endOfDay = DateTime(appointmentDate.year, appointmentDate.month, appointmentDate.day, 23, 59, 59);
      
      final duplicateCheck = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('petId', isEqualTo: petId)
          .where('clinicId', isEqualTo: clinicId)
          .where('appointmentDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('appointmentDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();
      
      // Check if any existing appointment matches the exact time and is not cancelled
      for (final doc in duplicateCheck.docs) {
        final data = doc.data();
        final existingTime = data['appointmentTime'] as String;
        final status = data['status'] as String;
        
        // Only consider pending or confirmed appointments as duplicates
        if (existingTime == appointmentTime && 
            (status == 'pending' || status == 'confirmed')) {
          print('🚫 Duplicate booking detected for user $userId at $appointmentTime');
          return true; // Duplicate found
        }
      }
      
      return false; // No duplicate
    } catch (e) {
      print('Error checking for duplicate booking: $e');
      return false; // On error, allow booking (fail open)
    }
  }

  /// Check if user has exceeded rate limit
  static bool checkRateLimit(String userId) {
    final now = DateTime.now();
    
    // Get user's recent booking attempts
    final attempts = _userBookingAttempts[userId] ?? [];
    
    // Remove attempts outside the rate limit window
    attempts.removeWhere((attemptTime) => 
      now.difference(attemptTime) > _rateLimitWindow
    );
    
    // Update the list
    _userBookingAttempts[userId] = attempts;
    
    // Check if limit exceeded
    if (attempts.length >= _maxBookingsPerWindow) {
      print('🚫 Rate limit exceeded for user $userId (${attempts.length} bookings in last ${_rateLimitWindow.inMinutes} minutes)');
      return false; // Rate limit exceeded
    }
    
    return true; // Within rate limit
  }

  /// Record a booking attempt for rate limiting
  static void recordBookingAttempt(String userId) {
    final attempts = _userBookingAttempts[userId] ?? [];
    attempts.add(DateTime.now());
    _userBookingAttempts[userId] = attempts;
  }

  /// Check if a specific time slot is at full capacity
  static Future<bool> isTimeSlotFull({
    required String clinicId,
    required DateTime appointmentDate,
    required String appointmentTime,
  }) async {
    try {
      final startOfDay = DateTime(appointmentDate.year, appointmentDate.month, appointmentDate.day);
      final endOfDay = DateTime(appointmentDate.year, appointmentDate.month, appointmentDate.day, 23, 59, 59);
      
      final existingAppointments = await _firestore
          .collection(_collection)
          .where('clinicId', isEqualTo: clinicId)
          .where('appointmentDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('appointmentDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .where('appointmentTime', isEqualTo: appointmentTime)
          .get();
      
      // Count confirmed or pending appointments (not cancelled)
      final activeAppointments = existingAppointments.docs.where((doc) {
        final status = doc.data()['status'] as String;
        return status == 'pending' || status == 'confirmed';
      }).length;
      
      // Assuming 1 appointment per time slot (can be configured)
      const maxAppointmentsPerSlot = 1;
      
      return activeAppointments >= maxAppointmentsPerSlot;
    } catch (e) {
      print('Error checking time slot capacity: $e');
      return false; // On error, assume slot is available
    }
  }

  /// Book a new appointment with duplicate prevention and rate limiting
  static Future<Map<String, dynamic>> bookAppointment({
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
        return {
          'success': false,
          'message': 'User not authenticated',
          'appointmentId': null,
        };
      }

      // 1. Check rate limit
      if (!checkRateLimit(currentUser.uid)) {
        return {
          'success': false,
          'message': 'Too many booking attempts. Please wait a few minutes and try again.',
          'appointmentId': null,
          'rateLimitExceeded': true,
        };
      }

      // 2. Check for duplicate booking
      final isDuplicate = await checkForDuplicateBooking(
        userId: currentUser.uid,
        petId: petId,
        clinicId: clinicId,
        appointmentDate: appointmentDate,
        appointmentTime: appointmentTime,
      );

      if (isDuplicate) {
        return {
          'success': false,
          'message': 'You already have an appointment for this pet at this clinic on this date and time.',
          'appointmentId': null,
          'isDuplicate': true,
        };
      }

      // 3. Use Firestore transaction to ensure atomic slot check and booking
      final result = await _firestore.runTransaction<Map<String, dynamic>>((transaction) async {
        // Check if slot is still available within transaction
        final startOfDay = DateTime(appointmentDate.year, appointmentDate.month, appointmentDate.day);
        final endOfDay = DateTime(appointmentDate.year, appointmentDate.month, appointmentDate.day, 23, 59, 59);
        
        final existingAppointmentsQuery = await _firestore
            .collection(_collection)
            .where('clinicId', isEqualTo: clinicId)
            .where('appointmentDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
            .where('appointmentDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
            .where('appointmentTime', isEqualTo: appointmentTime)
            .get();
        
        // Count active appointments in this slot
        final activeCount = existingAppointmentsQuery.docs.where((doc) {
          final status = doc.data()['status'] as String;
          return status == 'pending' || status == 'confirmed';
        }).length;
        
        const maxAppointmentsPerSlot = 1;
        
        if (activeCount >= maxAppointmentsPerSlot) {
          return {
            'success': false,
            'message': 'This time slot was just booked by another user. Please select a different time.',
            'appointmentId': null,
            'slotFull': true,
          };
        }

        // Slot is available, create the appointment
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

        final docRef = _firestore.collection(_collection).doc();
        transaction.set(docRef, appointment.toMap());

        return {
          'success': true,
          'message': 'Appointment booked successfully',
          'appointmentId': docRef.id,
        };
      });

      // Record the booking attempt for rate limiting (only if successful)
      if (result['success'] == true) {
        recordBookingAttempt(currentUser.uid);
        
        print('📋 MOBILE DEBUG: Appointment booked successfully with ID: ${result['appointmentId']}');
        print('🏥 MOBILE DEBUG: Saved with clinicId: $clinicId');
        print('👤 MOBILE DEBUG: Saved with userId: ${currentUser.uid}');
        print('🐾 MOBILE DEBUG: Saved with petId: $petId');
        print('📅 MOBILE DEBUG: Saved for date: $appointmentDate at $appointmentTime');
        print('🔧 MOBILE DEBUG: Service: $serviceName (ID: $serviceId)');
      }
      
      return result;
    } catch (e) {
      print('Error booking appointment: $e');
      return {
        'success': false,
        'message': 'Failed to book appointment: ${e.toString()}',
        'appointmentId': null,
      };
    }
  }

  /// Get user's appointments
  static Future<List<AppointmentBooking>> getUserAppointments(String userId) async {
    try {
      // Auto-cancel expired appointments before fetching
      await AppointmentAutoCancellationService.checkUserExpiredAppointments(userId);
      
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .get();

      final appointments = querySnapshot.docs
          .map((doc) => AppointmentBooking.fromMap(doc.data(), doc.id))
          .toList();
      
      // Sort by creation date in descending order (most recently booked first)
      appointments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return appointments;
    } catch (e) {
      print('Error getting user appointments: $e');
      return [];
    }
  }

  /// Stream user's appointments in real-time
  static Stream<List<AppointmentBooking>> getUserAppointmentsStream(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final appointments = snapshot.docs
          .map((doc) => AppointmentBooking.fromMap(doc.data(), doc.id))
          .toList();
      
      // Sort by creation date in descending order (most recently booked first)
      appointments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return appointments;
    });
  }

  /// Stream a single appointment by ID in real-time
  static Stream<AppointmentBooking?> getAppointmentStream(String appointmentId) {
    return _firestore
        .collection(_collection)
        .doc(appointmentId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return null;
      return AppointmentBooking.fromMap(snapshot.data()!, snapshot.id);
    });
  }

  /// Get upcoming appointments for user
  static Future<List<AppointmentBooking>> getUpcomingAppointments(String userId) async {
    try {
      // Auto-cancel expired appointments before fetching
      await AppointmentAutoCancellationService.checkUserExpiredAppointments(userId);
      
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
      // BUT skip if this is an auto-cancelled or no-show appointment (those have their own specific notifications)
      if (appointment != null) {
        try {
          // Check if this is an auto-cancelled or no-show appointment by reading the updated document
          final updatedDoc = await _firestore.collection(_collection).doc(appointmentId).get();
          final isAutoCancelled = updatedDoc.data()?['autoCancelled'] == true;
          final isNoShow = updatedDoc.data()?['isNoShow'] == true;
          
          if (isAutoCancelled) {
            print('⏰ Skipping onAppointmentStatusChanged for auto-cancelled appointment: $appointmentId');
          } else if (isNoShow) {
            print('🚫 Skipping onAppointmentStatusChanged for no-show appointment: $appointmentId');
          } else {
            // Get additional details for notification
            String petName = 'Your pet';
            String clinicName = 'the clinic';
            
            // Try to fetch pet and clinic names
            try {
              final petDoc = await _firestore.collection('pets').doc(appointment.petId).get();
              if (petDoc.exists) {
                final petData = petDoc.data();
                petName = petData?['name'] ?? petData?['petName'] ?? 'Your pet';
              }
              
              final clinicDoc = await _firestore.collection('clinics').doc(appointment.clinicId).get();
              if (clinicDoc.exists) {
                final clinicData = clinicDoc.data();
                clinicName = clinicData?['clinicName'] ?? clinicData?['name'] ?? 'the clinic';
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
          }
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