import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/clinic/clinic_schedule_model.dart';

/// Centralized manager for real-time clinic schedule updates
/// This service can be used across the app to manage schedule listeners and caching
class RealtimeScheduleManager {
  static final Map<String, StreamSubscription<DocumentSnapshot>> _listeners = {};
  static final Map<String, WeeklySchedule> _cache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static final Map<String, DateTime?> _lastModified = {};
  
  /// Duration after which cache expires
  static const Duration cacheExpiry = Duration(minutes: 30);
  
  /// Setup real-time listener for a clinic
  static StreamSubscription<DocumentSnapshot>? setupListener(
    String clinicId, {
    required Function(WeeklySchedule schedule) onUpdate,
    Function(String error)? onError,
  }) {
    // Cancel existing listener
    _listeners[clinicId]?.cancel();
    
    // Setup new listener
    final listener = FirebaseFirestore.instance
        .collection('clinicSchedules')
        .doc(clinicId)
        .snapshots()
        .listen(
      (DocumentSnapshot snapshot) {
        if (snapshot.exists) {
          _handleScheduleUpdate(clinicId, snapshot, onUpdate);
        }
      },
      onError: (error) {
        print('❌ RealtimeScheduleManager error for $clinicId: $error');
        onError?.call(error.toString());
      },
    );
    
    _listeners[clinicId] = listener;
    print('🎧 RealtimeScheduleManager: Setup listener for clinic $clinicId');
    return listener;
  }
  
  /// Handle real-time schedule updates
  static void _handleScheduleUpdate(
    String clinicId, 
    DocumentSnapshot snapshot, 
    Function(WeeklySchedule schedule) onUpdate,
  ) {
    try {
      final data = snapshot.data() as Map<String, dynamic>?;
      if (data == null) return;
      
      final documentLastModified = (data['updatedAt'] as Timestamp?)?.toDate() ?? 
                                  (data['lastModified'] as Timestamp?)?.toDate() ??
                                  (data['lastUpdated'] as Timestamp?)?.toDate();
      
      // Check if we need to update the cache
      final cachedLastModified = _lastModified[clinicId];
      if (cachedLastModified != null && 
          documentLastModified != null &&
          !documentLastModified.isAfter(cachedLastModified)) {
        return; // Cache is already up to date
      }
      
      // Parse the schedule
      final schedule = _parseScheduleFromDocument(clinicId, data);
      
      // Update cache
      _cache[clinicId] = schedule;
      _cacheTimestamps[clinicId] = DateTime.now();
      _lastModified[clinicId] = documentLastModified;
      
      // Notify listener
      onUpdate(schedule);
      
      print('✅ RealtimeScheduleManager: Updated cache for clinic $clinicId');
    } catch (e) {
      print('❌ RealtimeScheduleManager: Error handling update for $clinicId: $e');
    }
  }
  
  /// Parse WeeklySchedule from Firestore document data
  static WeeklySchedule _parseScheduleFromDocument(String clinicId, Map<String, dynamic> data) {
    final daysData = data['days'] as Map<String, dynamic>? ?? {};
    final Map<String, ClinicScheduleModel> schedules = {};
    
    for (final dayName in WeeklySchedule.daysOfWeek) {
      final dayKey = dayName.toLowerCase();
      if (daysData.containsKey(dayKey)) {
        final dayData = daysData[dayKey] as Map<String, dynamic>;
        schedules[dayName] = ClinicScheduleModel(
          id: '${clinicId}_$dayKey',
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
          id: '${clinicId}_$dayKey',
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
    
    return WeeklySchedule(schedules: schedules);
  }
  
  /// Get cached schedule if available and not expired
  static WeeklySchedule? getCachedSchedule(String clinicId) {
    final timestamp = _cacheTimestamps[clinicId];
    if (timestamp == null) return null;
    
    final now = DateTime.now();
    if (now.difference(timestamp) > cacheExpiry) {
      // Cache expired, remove it
      _cache.remove(clinicId);
      _cacheTimestamps.remove(clinicId);
      _lastModified.remove(clinicId);
      return null;
    }
    
    return _cache[clinicId];
  }
  
  /// Cleanup listener for a specific clinic
  static void cleanupListener(String clinicId) {
    _listeners[clinicId]?.cancel();
    _listeners.remove(clinicId);
    print('🧹 RealtimeScheduleManager: Cleaned up listener for clinic $clinicId');
  }
  
  /// Cleanup all listeners and cache
  static void cleanupAll() {
    for (final listener in _listeners.values) {
      listener.cancel();
    }
    _listeners.clear();
    _cache.clear();
    _cacheTimestamps.clear();
    _lastModified.clear();
    print('🧹 RealtimeScheduleManager: Cleaned up all listeners and cache');
  }
  
  /// Force invalidate cache for a clinic
  static void invalidateCache(String clinicId) {
    _cache.remove(clinicId);
    _cacheTimestamps.remove(clinicId);
    _lastModified.remove(clinicId);
    print('🗑️ RealtimeScheduleManager: Invalidated cache for clinic $clinicId');
  }
  
  /// Get statistics about the cache and listeners
  static Map<String, dynamic> getStats() {
    return {
      'activeListeners': _listeners.length,
      'cachedSchedules': _cache.length,
      'clinicsWithListeners': _listeners.keys.toList(),
      'clinicsWithCache': _cache.keys.toList(),
    };
  }
}