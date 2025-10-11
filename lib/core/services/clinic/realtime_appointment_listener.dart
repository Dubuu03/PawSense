// services/realtime_appointment_listener.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'paginated_appointment_service.dart';

/// Singleton service that manages real-time appointment listeners for a clinic.
/// Provides callbacks for status count updates and appointment changes.
/// Ensures optimal Firebase listener management with automatic cleanup.
class RealTimeAppointmentListener {
  static final RealTimeAppointmentListener _instance = RealTimeAppointmentListener._internal();
  factory RealTimeAppointmentListener() => _instance;
  RealTimeAppointmentListener._internal();

  // Firebase listener
  StreamSubscription<QuerySnapshot>? _appointmentsListener;
  String? _currentClinicId;
  bool _isFirstEvent = true;

  // Callbacks for different components
  final List<VoidCallback> _statusCountCallbacks = [];
  final List<VoidCallback> _appointmentListCallbacks = [];
  final List<VoidCallback> _dashboardCallbacks = [];

  /// Setup real-time listener for a specific clinic
  /// Will cancel any existing listener and create a new one
  void setupListener(String clinicId) {
    // Don't setup duplicate listeners
    if (_currentClinicId == clinicId && _appointmentsListener != null) {
      print('🔔 Real-time listener already active for clinic: $clinicId');
      return;
    }

    // Cleanup existing listener
    cleanup();

    _currentClinicId = clinicId;
    _isFirstEvent = true;

    print('🔔 Setting up real-time appointment listener for clinic: $clinicId');

    _appointmentsListener = FirebaseFirestore.instance
        .collection('appointments')
        .where('clinicId', isEqualTo: clinicId)
        .snapshots()
        .listen(
      (snapshot) {
        // Skip the first event (initial snapshot with all "added" changes)
        if (_isFirstEvent) {
          _isFirstEvent = false;
          print('🔔 Real-time listener initialized (skipping initial snapshot)');
          return;
        }

        // Only process if there are actual changes
        if (snapshot.docChanges.isEmpty) return;

        print('🔔 ${snapshot.docChanges.length} appointment(s) changed - notifying listeners');

        // Notify all registered callbacks with appropriate delays
        _notifyStatusCountCallbacks();
        _notifyAppointmentListCallbacks();
        _notifyDashboardCallbacks();
      },
      onError: (error) {
        print('❌ Real-time listener error: $error');
      },
    );
  }

  /// Register callback for status count updates (e.g., AppointmentSummary badges)
  /// These get immediate updates (50ms delay) for instant UI feedback
  void registerStatusCountCallback(VoidCallback callback) {
    if (!_statusCountCallbacks.contains(callback)) {
      _statusCountCallbacks.add(callback);
      print('📊 Registered status count callback (${_statusCountCallbacks.length} total)');
    }
  }

  /// Register callback for appointment list updates (e.g., appointment table)
  /// These get slightly delayed updates (100ms) to allow for UI consistency
  void registerAppointmentListCallback(VoidCallback callback) {
    if (!_appointmentListCallbacks.contains(callback)) {
      _appointmentListCallbacks.add(callback);
      print('📋 Registered appointment list callback (${_appointmentListCallbacks.length} total)');
    }
  }

  /// Register callback for dashboard updates (e.g., dashboard stats)
  /// These get delayed updates (200ms) as they're less critical for immediate feedback
  void registerDashboardCallback(VoidCallback callback) {
    if (!_dashboardCallbacks.contains(callback)) {
      _dashboardCallbacks.add(callback);
      print('📈 Registered dashboard callback (${_dashboardCallbacks.length} total)');
    }
  }

  /// Unregister callbacks to prevent memory leaks
  void unregisterStatusCountCallback(VoidCallback callback) {
    _statusCountCallbacks.remove(callback);
    print('📊 Unregistered status count callback (${_statusCountCallbacks.length} remaining)');
  }

  void unregisterAppointmentListCallback(VoidCallback callback) {
    _appointmentListCallbacks.remove(callback);
    print('📋 Unregistered appointment list callback (${_appointmentListCallbacks.length} remaining)');
  }

  void unregisterDashboardCallback(VoidCallback callback) {
    _dashboardCallbacks.remove(callback);
    print('📈 Unregistered dashboard callback (${_dashboardCallbacks.length} remaining)');
  }

  /// Notify status count callbacks with immediate update (50ms delay)
  void _notifyStatusCountCallbacks() {
    if (_statusCountCallbacks.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 50), () {
        print('🔄 Notifying ${_statusCountCallbacks.length} status count listeners');
        for (final callback in List.from(_statusCountCallbacks)) {
          try {
            callback();
          } catch (e) {
            print('❌ Error in status count callback: $e');
          }
        }
      });
    }
  }

  /// Notify appointment list callbacks with slight delay (100ms)
  void _notifyAppointmentListCallbacks() {
    if (_appointmentListCallbacks.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 100), () {
        print('🔄 Notifying ${_appointmentListCallbacks.length} appointment list listeners');
        for (final callback in List.from(_appointmentListCallbacks)) {
          try {
            callback();
          } catch (e) {
            print('❌ Error in appointment list callback: $e');
          }
        }
      });
    }
  }

  /// Notify dashboard callbacks with longer delay (200ms) for less critical updates
  void _notifyDashboardCallbacks() {
    if (_dashboardCallbacks.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 200), () {
        print('🔄 Notifying ${_dashboardCallbacks.length} dashboard listeners');
        for (final callback in List.from(_dashboardCallbacks)) {
          try {
            callback();
          } catch (e) {
            print('❌ Error in dashboard callback: $e');
          }
        }
      });
    }
  }

  /// Get current clinic ID being monitored
  String? get currentClinicId => _currentClinicId;

  /// Check if listener is active
  bool get isListening => _appointmentsListener != null && _currentClinicId != null;

  /// Get count of registered callbacks
  int get totalCallbacks => _statusCountCallbacks.length + 
                            _appointmentListCallbacks.length + 
                            _dashboardCallbacks.length;

  /// Cleanup listener and callbacks
  void cleanup() {
    print('🧹 Cleaning up real-time appointment listener');
    
    _appointmentsListener?.cancel();
    _appointmentsListener = null;
    _currentClinicId = null;
    _isFirstEvent = true;
    
    // Clear all callbacks to prevent memory leaks
    _statusCountCallbacks.clear();
    _appointmentListCallbacks.clear();
    _dashboardCallbacks.clear();
    
    print('✅ Real-time listener cleanup complete');
  }

  /// Utility method to get fresh status counts for a clinic
  /// Can be used by callback implementations
  static Future<AppointmentStatusCounts> getStatusCounts(String clinicId) {
    return PaginatedAppointmentService.getAppointmentStatusCounts(clinicId: clinicId);
  }

  /// Debug info for troubleshooting
  Map<String, dynamic> getDebugInfo() {
    return {
      'isListening': isListening,
      'currentClinicId': _currentClinicId,
      'totalCallbacks': totalCallbacks,
      'statusCountCallbacks': _statusCountCallbacks.length,
      'appointmentListCallbacks': _appointmentListCallbacks.length,
      'dashboardCallbacks': _dashboardCallbacks.length,
    };
  }
}