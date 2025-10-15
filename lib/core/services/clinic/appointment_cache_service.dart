import 'package:pawsense/core/models/clinic/appointment_models.dart';

/// Cache key for storing page data
class _CacheKey {
  final String statusFilter;
  final String searchQuery;
  final String? startDate;
  final String? endDate;
  final String? followUpFilter; // Store as string: null = 'all', 'true' = needs follow-up, 'false' = no follow-up
  final int page;

  _CacheKey({
    required this.statusFilter,
    required this.searchQuery,
    this.startDate,
    this.endDate,
    this.followUpFilter,
    required this.page,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _CacheKey &&
          runtimeType == other.runtimeType &&
          statusFilter == other.statusFilter &&
          searchQuery == other.searchQuery &&
          startDate == other.startDate &&
          endDate == other.endDate &&
          followUpFilter == other.followUpFilter &&
          page == other.page;

  @override
  int get hashCode =>
      statusFilter.hashCode ^
      searchQuery.hashCode ^
      (startDate?.hashCode ?? 0) ^
      (endDate?.hashCode ?? 0) ^
      (followUpFilter?.hashCode ?? 0) ^
      page.hashCode;

  @override
  String toString() => 'CacheKey(status: $statusFilter, search: $searchQuery, start: $startDate, end: $endDate, followUp: $followUpFilter, page: $page)';
}

/// Cached page data
class _CachedPageData {
  final List<Appointment> appointments;
  final int totalAppointments;
  final int totalPages;
  final DateTime fetchTime;

  _CachedPageData({
    required this.appointments,
    required this.totalAppointments,
    required this.totalPages,
    required this.fetchTime,
  });

  bool isValid(Duration cacheDuration) {
    final now = DateTime.now();
    final difference = now.difference(fetchTime);
    return difference < cacheDuration;
  }
}

/// Service to cache appointment data and manage refresh logic
/// Optimized for multi-page caching - remembers all visited pages
class AppointmentCacheService {
  static final AppointmentCacheService _instance = AppointmentCacheService._internal();
  factory AppointmentCacheService() => _instance;
  AppointmentCacheService._internal();

  // Multi-page cache storage - stores all visited pages
  final Map<_CacheKey, _CachedPageData> _pageCache = {};
  
  // Cache configuration
  final Duration _cacheDuration = Duration(minutes: 5);
  final int _maxCachedPages = 20; // Limit cache size to prevent memory issues
  
  // Current filters context
  String? _lastStatusFilter;
  String? _lastSearchQuery;
  String? _lastStartDate;
  String? _lastEndDate;
  String? _lastFollowUpFilter;
  
  /// Get cached page data if available and valid
  _CachedPageData? getCachedPage({
    required String statusFilter,
    required String searchQuery,
    String? startDate,
    String? endDate,
    bool? followUpFilter,
    required int page,
  }) {
    final key = _CacheKey(
      statusFilter: statusFilter,
      searchQuery: searchQuery,
      startDate: startDate,
      endDate: endDate,
      followUpFilter: followUpFilter?.toString(),
      page: page,
    );
    
    final cachedData = _pageCache[key];
    if (cachedData == null) {
      print('[CACHE] No cache for $key');
      return null;
    }
    
    if (!cachedData.isValid(_cacheDuration)) {
      print('[CACHE] Cache expired for $key');
      _pageCache.remove(key);
      return null;
    }
    
    print('[CACHE] Cache HIT for $key');
    return cachedData;
  }
  
  /// Check if filters have changed (not including page)
  bool hasFiltersChanged(String? statusFilter, String? searchQuery, String? startDate, String? endDate, bool? followUpFilter) {
    return _lastStatusFilter != statusFilter || 
           _lastSearchQuery != searchQuery ||
           _lastStartDate != startDate ||
           _lastEndDate != endDate ||
           _lastFollowUpFilter != followUpFilter?.toString();
  }
  
  /// Update cache with page data
  void updateCache({
    required List<Appointment> appointments,
    required int totalAppointments,
    required int totalPages,
    required String statusFilter,
    required String searchQuery,
    String? startDate,
    String? endDate,
    bool? followUpFilter,
    required int page,
  }) {
    // Create cache key
    final key = _CacheKey(
      statusFilter: statusFilter,
      searchQuery: searchQuery,
      startDate: startDate,
      endDate: endDate,
      followUpFilter: followUpFilter?.toString(),
      page: page,
    );
    
    // Store page data
    _pageCache[key] = _CachedPageData(
      appointments: appointments,
      totalAppointments: totalAppointments,
      totalPages: totalPages,
      fetchTime: DateTime.now(),
    );
    
    // Update filter context
    _lastStatusFilter = statusFilter;
    _lastSearchQuery = searchQuery;
    _lastStartDate = startDate;
    _lastEndDate = endDate;
    _lastFollowUpFilter = followUpFilter?.toString();
    
    // Enforce cache size limit (LRU-style: remove oldest entries)
    if (_pageCache.length > _maxCachedPages) {
      _evictOldestCacheEntries();
    }
    
    print('[CACHE] Cached page data for $key (${_pageCache.length} pages in cache)');
  }
  
  /// Remove oldest cache entries when limit is reached
  void _evictOldestCacheEntries() {
    final entries = _pageCache.entries.toList()
      ..sort((a, b) => a.value.fetchTime.compareTo(b.value.fetchTime));
    
    // Remove oldest 25% of entries
    final removeCount = (_maxCachedPages * 0.25).ceil();
    for (var i = 0; i < removeCount && entries.isNotEmpty; i++) {
      _pageCache.remove(entries[i].key);
      print('[CACHE] Evicted old cache entry: ${entries[i].key}');
    }
  }
  
  /// Invalidate all caches when filters change
  void invalidateCacheForFilterChange() {
    print('[CACHE] Filters changed - clearing all page caches');
    _pageCache.clear();
  }
  
  /// Invalidate cache (force refresh on next load)
  void invalidateCache() {
    _pageCache.clear();
    _lastStatusFilter = null;
    _lastSearchQuery = null;
    _lastStartDate = null;
    _lastEndDate = null;
    print('[CACHE] All caches cleared');
  }
  
  /// Update a single appointment in ALL cached pages that contain it
  void updateAppointmentInCache(Appointment updatedAppointment) {
    int updatedCount = 0;
    
    // Update appointment in all cached pages
    for (var entry in _pageCache.entries) {
      final appointments = entry.value.appointments;
      final index = appointments.indexWhere((a) => a.id == updatedAppointment.id);
      if (index != -1) {
        appointments[index] = updatedAppointment;
        updatedCount++;
      }
    }
    
    if (updatedCount > 0) {
      print('[CACHE] Updated appointment in $updatedCount cached pages');
    }
  }
  
  /// Remove an appointment from ALL cached pages
  void removeAppointmentFromCache(String appointmentId) {
    int removedCount = 0;
    
    // Remove appointment from all cached pages
    for (var entry in _pageCache.entries) {
      final appointments = entry.value.appointments;
      final index = appointments.indexWhere((a) => a.id == appointmentId);
      if (index != -1) {
        appointments.removeAt(index);
        removedCount++;
      }
    }
    
    if (removedCount > 0) {
      print('[CACHE] Removed appointment from $removedCount cached pages');
    }
  }
  
  /// Get cache statistics for debugging
  Map<String, dynamic> getCacheStats() {
    return {
      'totalCachedPages': _pageCache.length,
      'maxCachedPages': _maxCachedPages,
      'cacheDuration': _cacheDuration.inMinutes,
      'cachedPageKeys': _pageCache.keys.map((k) => k.toString()).toList(),
    };
  }
  
  /// Clear cache on logout or when needed
  void clearCache() {
    invalidateCache();
  }
}
