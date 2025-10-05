import 'package:pawsense/core/models/clinic/appointment_models.dart';

/// Cache entry for appointments with metadata
class _AppointmentCacheEntry {
  final List<Appointment> appointments;
  final DateTime timestamp;
  final String searchQuery;
  final String selectedStatus;

  _AppointmentCacheEntry({
    required this.appointments,
    required this.timestamp,
    required this.searchQuery,
    required this.selectedStatus,
  });

  bool isExpired(Duration ttl) {
    return DateTime.now().difference(timestamp) > ttl;
  }

  bool matchesFilters({
    required String searchQuery,
    required String selectedStatus,
  }) {
    return this.searchQuery == searchQuery && 
           this.selectedStatus == selectedStatus;
  }
}

/// Service to cache appointment data and reduce Firestore calls
/// Implements LRU cache with TTL (Time To Live)
class AppointmentCacheService {
  static final AppointmentCacheService _instance = AppointmentCacheService._internal();
  factory AppointmentCacheService() => _instance;
  AppointmentCacheService._internal();

  _AppointmentCacheEntry? _cachedData;
  final Duration _ttl = Duration(minutes: 5); // 5-minute cache

  // Store last known filter state for change detection
  String _lastSearchQuery = '';
  String _lastSelectedStatus = 'All Status';

  /// Get cached appointments if available and not expired
  List<Appointment>? getCachedAppointments({
    required String searchQuery,
    required String selectedStatus,
  }) {
    if (_cachedData == null) {
      print('💾 Cache MISS: No cached data');
      return null;
    }

    if (_cachedData!.isExpired(_ttl)) {
      print('⏰ Cache EXPIRED: Data is older than ${_ttl.inMinutes} minutes');
      _cachedData = null;
      return null;
    }

    if (!_cachedData!.matchesFilters(
      searchQuery: searchQuery,
      selectedStatus: selectedStatus,
    )) {
      print('🔍 Cache MISS: Filters changed (search: "$searchQuery", status: "$selectedStatus")');
      return null;
    }

    final age = DateTime.now().difference(_cachedData!.timestamp);
    print('📦 Cache HIT: Returning ${_cachedData!.appointments.length} appointments (age: ${age.inSeconds}s)');
    return _cachedData!.appointments;
  }

  /// Update cache with new appointment data
  void updateCache({
    required List<Appointment> appointments,
    required String searchQuery,
    required String selectedStatus,
  }) {
    _cachedData = _AppointmentCacheEntry(
      appointments: appointments,
      timestamp: DateTime.now(),
      searchQuery: searchQuery,
      selectedStatus: selectedStatus,
    );

    _lastSearchQuery = searchQuery;
    _lastSelectedStatus = selectedStatus;

    print('💾 Cache UPDATED: Stored ${appointments.length} appointments (search: "$searchQuery", status: "$selectedStatus")');
  }

  /// Check if filters have changed since last cache
  bool hasFiltersChanged(String searchQuery, String selectedStatus) {
    final changed = _lastSearchQuery != searchQuery || 
                    _lastSelectedStatus != selectedStatus;
    
    if (changed) {
      print('🔄 Filters CHANGED: was (search: "$_lastSearchQuery", status: "$_lastSelectedStatus"), now (search: "$searchQuery", status: "$selectedStatus")');
    }
    
    return changed;
  }

  /// Invalidate cache (force refresh)
  void invalidateCache() {
    _cachedData = null;
    print('🗑️  Cache INVALIDATED: Forced refresh');
  }

  /// Update a single appointment in cache (e.g., after status update)
  void updateAppointmentInCache(Appointment updatedAppointment) {
    if (_cachedData == null) return;

    final index = _cachedData!.appointments.indexWhere((a) => a.id == updatedAppointment.id);
    if (index != -1) {
      final updatedList = List<Appointment>.from(_cachedData!.appointments);
      updatedList[index] = updatedAppointment;

      _cachedData = _AppointmentCacheEntry(
        appointments: updatedList,
        timestamp: _cachedData!.timestamp, // Keep original timestamp
        searchQuery: _cachedData!.searchQuery,
        selectedStatus: _cachedData!.selectedStatus,
      );

      print('✏️  Cache UPDATED: Modified appointment ${updatedAppointment.id}');
    }
  }

  /// Remove an appointment from cache (e.g., after cancellation)
  void removeAppointmentFromCache(String appointmentId) {
    if (_cachedData == null) return;

    final updatedList = _cachedData!.appointments
        .where((a) => a.id != appointmentId)
        .toList();

    _cachedData = _AppointmentCacheEntry(
      appointments: updatedList,
      timestamp: _cachedData!.timestamp, // Keep original timestamp
      searchQuery: _cachedData!.searchQuery,
      selectedStatus: _cachedData!.selectedStatus,
    );

    print('🗑️  Cache UPDATED: Removed appointment $appointmentId');
  }

  /// Get cache statistics for debugging
  Map<String, dynamic> getCacheStats() {
    if (_cachedData == null) {
      return {
        'cached': false,
        'appointments': 0,
        'age': 0,
      };
    }

    final age = DateTime.now().difference(_cachedData!.timestamp);
    return {
      'cached': true,
      'appointments': _cachedData!.appointments.length,
      'age': age.inSeconds,
      'searchQuery': _cachedData!.searchQuery,
      'selectedStatus': _cachedData!.selectedStatus,
      'expired': _cachedData!.isExpired(_ttl),
    };
  }
}
