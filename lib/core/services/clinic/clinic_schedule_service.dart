import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/clinic/clinic_schedule_model.dart';

class ClinicScheduleService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'clinicSchedules';

  // Create or update weekly schedule for a clinic (nested structure)
  static Future<bool> saveWeeklySchedule(String clinicId, List<ClinicScheduleModel> schedules) async {
    try {
      if (clinicId.isEmpty) {
        print('Error: clinicId cannot be empty');
        return false;
      }

      // Create nested structure: one document per clinic with days as nested fields
      final Map<String, dynamic> weeklyScheduleData = {
        'clinicId': clinicId,
        'lastUpdated': Timestamp.fromDate(DateTime.now()),
        'days': {},
      };

      // Add each day's schedule as nested data
      for (final schedule in schedules) {
        weeklyScheduleData['days'][schedule.dayOfWeek.toLowerCase()] = {
          'dayOfWeek': schedule.dayOfWeek,
          'openTime': schedule.openTime,
          'closeTime': schedule.closeTime,
          'isOpen': schedule.isOpen,
          'breakTimes': schedule.breakTimes.map((bt) => bt.toMap()).toList(),
          'notes': schedule.notes,
          'slotsPerHour': schedule.slotsPerHour,
          'slotDurationMinutes': schedule.slotDurationMinutes,
          'isActive': schedule.isActive,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        };
      }

      // Save as single document with clinic ID as document ID
      await _firestore.collection(_collection).doc(clinicId).set(weeklyScheduleData);
      
      print('Successfully saved weekly schedule for clinic: $clinicId');
      return true;
    } catch (e) {
      print('Error saving weekly schedule: $e');
      return false;
    }
  }

  // Get weekly schedule for a clinic
  static Future<WeeklySchedule> getWeeklySchedule(String clinicId) async {
    try {
      if (clinicId.isEmpty) {
        print('Error: clinicId cannot be empty');
        return WeeklySchedule(schedules: {});
      }

      final doc = await _firestore.collection(_collection).doc(clinicId).get();
      
      if (!doc.exists) {
        print('No schedule found for clinic: $clinicId');
        return WeeklySchedule(schedules: {});
      }

      final data = doc.data() as Map<String, dynamic>;
      final daysData = data['days'] as Map<String, dynamic>? ?? {};
      
      final Map<String, ClinicScheduleModel> schedules = {};
      
      for (final dayName in WeeklySchedule.daysOfWeek) {
        final dayKey = dayName.toLowerCase();
        if (daysData.containsKey(dayKey)) {
          final dayData = daysData[dayKey] as Map<String, dynamic>;
          schedules[dayName] = ClinicScheduleModel(
            id: '${clinicId}_${dayKey}',
            clinicId: clinicId,
            dayOfWeek: dayData['dayOfWeek'] ?? dayName,
            openTime: dayData['openTime'],
            closeTime: dayData['closeTime'],
            isOpen: dayData['isOpen'] ?? false,
            breakTimes: (dayData['breakTimes'] as List<dynamic>?)
                ?.map((bt) => BreakTime.fromMap(bt))
                .toList() ?? [],
            notes: dayData['notes'],
            slotsPerHour: dayData['slotsPerHour'] ?? 3,
            slotDurationMinutes: dayData['slotDurationMinutes'] ?? 20,
            createdAt: (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
            updatedAt: (dayData['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            isActive: dayData['isActive'] ?? true,
          );
        } else {
          // Create default closed schedule for missing days
          schedules[dayName] = ClinicScheduleModel(
            id: '${clinicId}_${dayKey}',
            clinicId: clinicId,
            dayOfWeek: dayName,
            openTime: null,
            closeTime: null,
            isOpen: false,
            breakTimes: [],
            notes: null,
            slotsPerHour: 3,
            slotDurationMinutes: 20,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            isActive: true,
          );
        }
      }

      print('Successfully loaded weekly schedule for clinic: $clinicId');
      return WeeklySchedule(schedules: schedules);
    } catch (e) {
      print('Error getting weekly schedule: $e');
      return WeeklySchedule(schedules: {});
    }
  }

  // Get schedule for a specific clinic and day
  static Future<ClinicScheduleModel?> getScheduleForDay(String clinicId, String dayOfWeek) async {
    try {
      if (clinicId.isEmpty) {
        print('Error: clinicId cannot be empty');
        return null;
      }

      final doc = await _firestore.collection(_collection).doc(clinicId).get();
      
      if (!doc.exists) {
        print('No schedule found for clinic: $clinicId');
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      final daysData = data['days'] as Map<String, dynamic>? ?? {};
      final dayKey = dayOfWeek.toLowerCase();
      
      if (daysData.containsKey(dayKey)) {
        final dayData = daysData[dayKey] as Map<String, dynamic>;
        return ClinicScheduleModel(
          id: '${clinicId}_${dayKey}',
          clinicId: clinicId,
          dayOfWeek: dayData['dayOfWeek'] ?? dayOfWeek,
          openTime: dayData['openTime'],
          closeTime: dayData['closeTime'],
          isOpen: dayData['isOpen'] ?? false,
          breakTimes: (dayData['breakTimes'] as List<dynamic>?)
              ?.map((bt) => BreakTime.fromMap(bt))
              .toList() ?? [],
          notes: dayData['notes'],
          slotsPerHour: dayData['slotsPerHour'] ?? 3,
          slotDurationMinutes: dayData['slotDurationMinutes'] ?? 20,
          createdAt: (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
          updatedAt: (dayData['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          isActive: dayData['isActive'] ?? true,
        );
      }
      
      return null;
    } catch (e) {
      print('Error getting schedule for day: $e');
      return null;
    }
  }

  // Initialize default schedule for a new clinic
  static Future<bool> initializeDefaultSchedule(String clinicId) async {
    try {
      if (clinicId.isEmpty) {
        print('Error: clinicId cannot be empty');
        return false;
      }

      final defaultSchedules = <ClinicScheduleModel>[];
      
      for (final day in WeeklySchedule.daysOfWeek) {
        final isWeekend = day == 'Saturday' || day == 'Sunday';
        
        final schedule = ClinicScheduleModel(
          id: '${clinicId}_${day.toLowerCase()}',
          clinicId: clinicId,
          dayOfWeek: day,
          openTime: isWeekend ? null : '09:00',
          closeTime: isWeekend ? null : '17:00',
          isOpen: !isWeekend,
          breakTimes: isWeekend ? [] : [
            BreakTime(
              startTime: '12:00',
              endTime: '13:00',
              label: 'Lunch Break',
            ),
          ],
          notes: isWeekend ? 'Closed on weekends' : null,
          slotsPerHour: 3,
          slotDurationMinutes: 20,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isActive: true,
        );
        
        defaultSchedules.add(schedule);
      }
      
      return await saveWeeklySchedule(clinicId, defaultSchedules);
    } catch (e) {
      print('Error initializing default schedule: $e');
      return false;
    }
  }

  // Check if clinic is open at specific date and time
  static Future<bool> isClinicOpen(String clinicId, DateTime dateTime) async {
    try {
      final dayOfWeek = _getDayOfWeek(dateTime.weekday);
      final schedule = await getScheduleForDay(clinicId, dayOfWeek);
      
      return schedule?.isOpenAt(dateTime) ?? false;
    } catch (e) {
      print('Error checking if clinic is open: $e');
      return false;
    }
  }

  // Get available time slots for a specific date
  static Future<List<String>> getAvailableTimeSlots(
    String clinicId, 
    DateTime date, {
    int intervalMinutes = 30,
  }) async {
    try {
      final dayOfWeek = _getDayOfWeek(date.weekday);
      final schedule = await getScheduleForDay(clinicId, dayOfWeek);
      
      return schedule?.getAvailableTimeSlots() ?? [];
    } catch (e) {
      print('Error getting available time slots: $e');
      return [];
    }
  }

  // Update specific day schedule
  static Future<bool> updateDaySchedule(
    String clinicId,
    String dayOfWeek, {
    String? openTime,
    String? closeTime,
    bool? isOpen,
    List<BreakTime>? breakTimes,
    String? notes,
    int? slotsPerHour,
    int? slotDurationMinutes,
  }) async {
    try {
      if (clinicId.isEmpty) {
        print('Error: clinicId cannot be empty');
        return false;
      }

      // Get current weekly schedule
      final weeklySchedule = await getWeeklySchedule(clinicId);
      final existingSchedule = weeklySchedule.getScheduleForDay(dayOfWeek);
      
      // Create updated schedule
      final updatedSchedule = existingSchedule?.copyWith(
        openTime: openTime,
        closeTime: closeTime,
        isOpen: isOpen,
        breakTimes: breakTimes,
        notes: notes,
        slotsPerHour: slotsPerHour,
        slotDurationMinutes: slotDurationMinutes,
        updatedAt: DateTime.now(),
      ) ?? ClinicScheduleModel(
        id: '${clinicId}_${dayOfWeek.toLowerCase()}',
        clinicId: clinicId,
        dayOfWeek: dayOfWeek,
        openTime: openTime,
        closeTime: closeTime,
        isOpen: isOpen ?? false,
        breakTimes: breakTimes ?? [],
        notes: notes,
        slotsPerHour: slotsPerHour ?? 3,
        slotDurationMinutes: slotDurationMinutes ?? 20,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
      );

      // Update the schedule in the weekly collection
      final schedules = List<ClinicScheduleModel>.from(weeklySchedule.schedules.values);
      final existingIndex = schedules.indexWhere((s) => s.dayOfWeek == dayOfWeek);
      
      if (existingIndex >= 0) {
        schedules[existingIndex] = updatedSchedule;
      } else {
        schedules.add(updatedSchedule);
      }

      return await saveWeeklySchedule(clinicId, schedules);
    } catch (e) {
      print('Error updating day schedule: $e');
      return false;
    }
  }

  // Delete schedule (set as inactive)
  static Future<bool> deleteSchedule(String clinicId) async {
    try {
      if (clinicId.isEmpty) {
        print('Error: clinicId cannot be empty');
        return false;
      }

      await _firestore.collection(_collection).doc(clinicId).delete();
      print('Successfully deleted schedule for clinic: $clinicId');
      return true;
    } catch (e) {
      print('Error deleting schedule: $e');
      return false;
    }
  }

  // Stream of weekly schedule changes
  static Stream<WeeklySchedule> streamWeeklySchedule(String clinicId) {
    if (clinicId.isEmpty) {
      return Stream.value(WeeklySchedule(schedules: {}));
    }

    return _firestore
        .collection(_collection)
        .doc(clinicId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) {
        return WeeklySchedule(schedules: {});
      }

      final data = snapshot.data() as Map<String, dynamic>;
      final daysData = data['days'] as Map<String, dynamic>? ?? {};
      final Map<String, ClinicScheduleModel> schedules = {};
      
      for (final dayName in WeeklySchedule.daysOfWeek) {
        final dayKey = dayName.toLowerCase();
        if (daysData.containsKey(dayKey)) {
          final dayData = daysData[dayKey] as Map<String, dynamic>;
          schedules[dayName] = ClinicScheduleModel(
            id: '${clinicId}_${dayKey}',
            clinicId: clinicId,
            dayOfWeek: dayData['dayOfWeek'] ?? dayName,
            openTime: dayData['openTime'],
            closeTime: dayData['closeTime'],
            isOpen: dayData['isOpen'] ?? false,
            breakTimes: (dayData['breakTimes'] as List<dynamic>?)
                ?.map((bt) => BreakTime.fromMap(bt))
                .toList() ?? [],
            notes: dayData['notes'],
            slotsPerHour: dayData['slotsPerHour'] ?? 3,
            slotDurationMinutes: dayData['slotDurationMinutes'] ?? 20,
            createdAt: (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
            updatedAt: (dayData['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            isActive: dayData['isActive'] ?? true,
          );
        }
      }

      return WeeklySchedule(schedules: schedules);
    });
  }

  // Bulk update break times for all days
  static Future<bool> updateAllBreakTimes(String clinicId, List<BreakTime> breakTimes) async {
    try {
      if (clinicId.isEmpty) {
        print('Error: clinicId cannot be empty');
        return false;
      }

      final weeklySchedule = await getWeeklySchedule(clinicId);
      final updatedSchedules = <ClinicScheduleModel>[];
      
      for (final schedule in weeklySchedule.schedules.values) {
        if (schedule.isOpen) {
          updatedSchedules.add(schedule.copyWith(
            breakTimes: breakTimes,
            updatedAt: DateTime.now(),
          ));
        } else {
          updatedSchedules.add(schedule);
        }
      }
      
      return await saveWeeklySchedule(clinicId, updatedSchedules);
    } catch (e) {
      print('Error updating all break times: $e');
      return false;
    }
  }

  // Helper method to convert weekday number to day name
  static String _getDayOfWeek(int weekday) {
    const days = [
      'Monday',    // 1
      'Tuesday',   // 2
      'Wednesday', // 3
      'Thursday',  // 4
      'Friday',    // 5
      'Saturday',  // 6
      'Sunday',    // 7
    ];
    return days[weekday - 1];
  }

  // Get schedule summary for display
  static Future<Map<String, String>> getScheduleSummary(String clinicId) async {
    try {
      final weeklySchedule = await getWeeklySchedule(clinicId);
      final summary = <String, String>{};
      
      for (final day in WeeklySchedule.daysOfWeek) {
        final schedule = weeklySchedule.getScheduleForDay(day);
        if (schedule != null && schedule.isOpen && 
            schedule.openTime != null && schedule.closeTime != null) {
          summary[day] = '${schedule.openTime} - ${schedule.closeTime}';
        } else {
          summary[day] = 'Closed';
        }
      }
      
      return summary;
    } catch (e) {
      print('Error getting schedule summary: $e');
      return {};
    }
  }

  // Check if clinic has any configured schedules
  static Future<bool> hasConfiguredSchedules(String clinicId) async {
    try {
      if (clinicId.isEmpty) return false;
      
      final weeklySchedule = await getWeeklySchedule(clinicId);
      return weeklySchedule.schedules.values.any((schedule) => schedule.isOpen);
    } catch (e) {
      print('Error checking configured schedules: $e');
      return false;
    }
  }

  // Get clinic's operating days
  static Future<List<String>> getOperatingDays(String clinicId) async {
    try {
      final weeklySchedule = await getWeeklySchedule(clinicId);
      return weeklySchedule.schedules.values
          .where((schedule) => schedule.isOpen)
          .map((schedule) => schedule.dayOfWeek)
          .toList();
    } catch (e) {
      print('Error getting operating days: $e');
      return [];
    }
  }

  // Get appointments for a specific clinic and date
  static Future<List<Map<String, dynamic>>> getAppointmentsForDate(String clinicId, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final query = await _firestore
          .collection('appointments')
          .where('clinicId', isEqualTo: clinicId)
          .where('appointmentDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('appointmentDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();

      final appointments = query.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'time': data['appointmentTime'], // Use appointmentTime field
          'status': data['status'],
          'serviceName': data['serviceName'],
          'petId': data['petId'],
          'userId': data['userId'],
        };
      }).toList();

      // Filter for active appointments only (exclude cancelled, rejected, etc.)
      final activeAppointments = appointments.where((apt) => 
        ['pending', 'confirmed', 'completed'].contains(apt['status']) && 
        apt['status'] != 'cancelled' && 
        apt['status'] != 'rejected'
      ).toList();
      
      return activeAppointments;
    } catch (e) {
      print('Error getting appointments for date: $e');
      return [];
    }
  }

  // Get day schedule with real-time appointment availability
  static Future<Map<String, dynamic>> getDayScheduleWithAvailability(String clinicId, String dayOfWeek, DateTime date) async {
    try {
      final schedule = await getScheduleForDay(clinicId, dayOfWeek);
      if (schedule == null || !schedule.isOpen) {
        print('$dayOfWeek is closed or no schedule found');
        return {
          'schedule': null,
          'totalSlots': 0,
          'bookedSlots': 0,
          'availableSlots': 0,
          'appointments': [],
          'utilization': 0,
        };
      }

      final appointments = await getAppointmentsForDate(clinicId, date);
      
      // Count only confirmed appointments for utilization calculation (to match appointment display)
      final confirmedAppointments = appointments.where((apt) => apt['status'] == 'confirmed').toList();
      
      final totalSlots = schedule.getTotalCapacity();
      final bookedSlots = confirmedAppointments.length; // Only confirmed appointments
      final availableSlots = totalSlots - bookedSlots;
      final utilization = totalSlots > 0 ? (bookedSlots / totalSlots * 100).round() : 0;

      return {
        'schedule': schedule,
        'totalSlots': totalSlots,
        'bookedSlots': bookedSlots,
        'availableSlots': availableSlots.clamp(0, totalSlots),
        'appointments': appointments, // Return all active appointments
        'utilization': utilization,
      };
    } catch (e) {
      print('Error getting day schedule with availability: $e');
      return {
        'schedule': null,
        'totalSlots': 0,
        'bookedSlots': 0,
        'availableSlots': 0,
        'appointments': [],
        'utilization': 0,
      };
    }
  }

  // Get weekly schedule with appointment availability
  static Future<Map<String, Map<String, dynamic>>> getWeeklyScheduleWithAvailability(String clinicId, DateTime weekDate) async {
    try {
      final weeklyData = <String, Map<String, dynamic>>{};
      
      // Get Monday of the week
      final weekday = weekDate.weekday;
      final monday = weekDate.subtract(Duration(days: weekday - 1));
      
      for (int i = 0; i < 7; i++) {
        final currentDate = monday.add(Duration(days: i));
        final dayName = _getDayOfWeek(currentDate.weekday);
        
        final dayData = await getDayScheduleWithAvailability(clinicId, dayName, currentDate);
        weeklyData[dayName] = dayData;
      }
      
      return weeklyData;
    } catch (e) {
      print('Error getting weekly schedule with availability: $e');
      return {};
    }
  }
}