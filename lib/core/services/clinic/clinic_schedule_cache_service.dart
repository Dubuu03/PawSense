/// Cache entry for clinic schedule data with metadata
class _ScheduleCacheEntry {
  final Map<String, Map<String, dynamic>> weekData;
  final DateTime weekStartDate; // Monday of the week
  final DateTime timestamp;

  _ScheduleCacheEntry({
    required this.weekData,
    required this.weekStartDate,
    required this.timestamp,
  });

  bool isExpired(Duration ttl) {
    return DateTime.now().difference(timestamp) > ttl;
  }

  bool matchesWeek(DateTime date) {
    // Get Monday of the provided date
    final weekday = date.weekday;
    final monday = date.subtract(Duration(days: weekday - 1));
    
    // Compare dates (ignore time)
    return weekStartDate.year == monday.year &&
           weekStartDate.month == monday.month &&
           weekStartDate.day == monday.day;
  }
}

/// Service to cache clinic schedule data and reduce Firestore calls
/// Implements cache with TTL (Time To Live) for weekly schedule data
class ClinicScheduleCacheService {
  static final ClinicScheduleCacheService _instance = ClinicScheduleCacheService._internal();
  factory ClinicScheduleCacheService() => _instance;
  ClinicScheduleCacheService._internal();

  _ScheduleCacheEntry? _cachedData;
  final Duration _ttl = Duration(minutes: 5); // 5-minute cache

  /// Get cached schedule data if available and not expired
  Map<String, Map<String, dynamic>>? getCachedWeekData({
    required DateTime selectedDate,
  }) {
    if (_cachedData == null) {
      print('💾 Schedule Cache MISS: No cached data');
      return null;
    }

    if (_cachedData!.isExpired(_ttl)) {
      print('⏰ Schedule Cache EXPIRED: Data is older than ${_ttl.inMinutes} minutes');
      _cachedData = null;
      return null;
    }

    if (!_cachedData!.matchesWeek(selectedDate)) {
      print('📅 Schedule Cache MISS: Different week requested');
      return null;
    }

    final age = DateTime.now().difference(_cachedData!.timestamp);
    print('📦 Schedule Cache HIT: Returning week data (age: ${age.inSeconds}s)');
    return _cachedData!.weekData;
  }

  /// Update cache with new schedule data
  void updateCache({
    required Map<String, Map<String, dynamic>> weekData,
    required DateTime selectedDate,
  }) {
    // Get Monday of the week
    final weekday = selectedDate.weekday;
    final monday = selectedDate.subtract(Duration(days: weekday - 1));

    _cachedData = _ScheduleCacheEntry(
      weekData: weekData,
      weekStartDate: monday,
      timestamp: DateTime.now(),
    );

    print('💾 Schedule Cache UPDATED: Stored week data for ${monday.toString().split(' ')[0]}');
  }

  /// Invalidate cache (force refresh)
  void invalidateCache() {
    _cachedData = null;
    print('🗑️  Schedule Cache INVALIDATED: Forced refresh');
  }

  /// Get cache statistics for debugging
  Map<String, dynamic> getCacheStats() {
    if (_cachedData == null) {
      return {
        'cached': false,
        'age': 0,
      };
    }

    final age = DateTime.now().difference(_cachedData!.timestamp);
    return {
      'cached': true,
      'weekStartDate': _cachedData!.weekStartDate.toString().split(' ')[0],
      'age': age.inSeconds,
      'expired': _cachedData!.isExpired(_ttl),
    };
  }
}
