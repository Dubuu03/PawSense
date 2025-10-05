import 'package:pawsense/core/models/clinic/clinic_registration_model.dart';

/// Cache key for storing page data
class _CacheKey {
  final String statusFilter;
  final String searchQuery;
  final int page;

  _CacheKey({
    required this.statusFilter,
    required this.searchQuery,
    required this.page,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _CacheKey &&
          runtimeType == other.runtimeType &&
          statusFilter == other.statusFilter &&
          searchQuery == other.searchQuery &&
          page == other.page;

  @override
  int get hashCode => statusFilter.hashCode ^ searchQuery.hashCode ^ page.hashCode;

  @override
  String toString() => 'CacheKey(status: $statusFilter, search: $searchQuery, page: $page)';
}

/// Cached page data
class _CachedPageData {
  final List<ClinicRegistration> clinics;
  final int totalClinics;
  final int totalPages;
  final DateTime fetchTime;

  _CachedPageData({
    required this.clinics,
    required this.totalClinics,
    required this.totalPages,
    required this.fetchTime,
  });

  bool isValid(Duration cacheDuration) {
    final now = DateTime.now();
    final difference = now.difference(fetchTime);
    return difference < cacheDuration;
  }
}

/// Service to cache clinic data and manage refresh logic
/// Optimized for multi-page caching - remembers all visited pages
class ClinicCacheService {
  static final ClinicCacheService _instance = ClinicCacheService._internal();
  factory ClinicCacheService() => _instance;
  ClinicCacheService._internal();

  // Multi-page cache storage - stores all visited pages
  final Map<_CacheKey, _CachedPageData> _pageCache = {};
  Map<String, int>? _cachedStats;
  DateTime? _statsLastFetchTime;
  
  // Cache configuration
  final Duration _cacheDuration = Duration(minutes: 5);
  final int _maxCachedPages = 20; // Limit cache size to prevent memory issues
  
  // Current filters context
  String? _lastStatusFilter;
  String? _lastSearchQuery;
  
  /// Get cached page data if available and valid
  _CachedPageData? getCachedPage({
    required String statusFilter,
    required String searchQuery,
    required int page,
  }) {
    final key = _CacheKey(
      statusFilter: statusFilter,
      searchQuery: searchQuery,
      page: page,
    );
    
    final cachedData = _pageCache[key];
    if (cachedData == null) {
      print('📭 No cache for $key');
      return null;
    }
    
    if (!cachedData.isValid(_cacheDuration)) {
      print('⏰ Cache expired for $key');
      _pageCache.remove(key);
      return null;
    }
    
    print('✅ Cache HIT for $key');
    return cachedData;
  }
  
  /// Check if filters have changed (not including page)
  bool hasFiltersChanged(String? statusFilter, String? searchQuery) {
    return _lastStatusFilter != statusFilter || _lastSearchQuery != searchQuery;
  }
  
  /// Get cached stats
  Map<String, int>? get cachedStats {
    if (_cachedStats == null || _statsLastFetchTime == null) {
      return null;
    }
    
    final now = DateTime.now();
    final difference = now.difference(_statsLastFetchTime!);
    if (difference >= _cacheDuration) {
      return null; // Stats expired
    }
    
    return _cachedStats;
  }
  
  /// Update cache with page data
  void updateCache({
    required List<ClinicRegistration> clinics,
    required int totalClinics,
    required int totalPages,
    required Map<String, int> stats,
    required String statusFilter,
    required String searchQuery,
    required int page,
  }) {
    // Create cache key
    final key = _CacheKey(
      statusFilter: statusFilter,
      searchQuery: searchQuery,
      page: page,
    );
    
    // Store page data
    _pageCache[key] = _CachedPageData(
      clinics: clinics,
      totalClinics: totalClinics,
      totalPages: totalPages,
      fetchTime: DateTime.now(),
    );
    
    // Update stats
    _cachedStats = stats;
    _statsLastFetchTime = DateTime.now();
    
    // Update filter context
    _lastStatusFilter = statusFilter;
    _lastSearchQuery = searchQuery;
    
    // Enforce cache size limit (LRU-style: remove oldest entries)
    if (_pageCache.length > _maxCachedPages) {
      _evictOldestCacheEntries();
    }
    
    print('💾 Cached page data for $key (${_pageCache.length} pages in cache)');
  }
  
  /// Remove oldest cache entries when limit is reached
  void _evictOldestCacheEntries() {
    final entries = _pageCache.entries.toList()
      ..sort((a, b) => a.value.fetchTime.compareTo(b.value.fetchTime));
    
    // Remove oldest 25% of entries
    final removeCount = (_maxCachedPages * 0.25).ceil();
    for (var i = 0; i < removeCount && entries.isNotEmpty; i++) {
      _pageCache.remove(entries[i].key);
      print('🗑️ Evicted old cache entry: ${entries[i].key}');
    }
  }
  
  /// Invalidate all caches when filters change
  void invalidateCacheForFilterChange() {
    print('🔄 Filters changed - clearing all page caches');
    _pageCache.clear();
    // Keep stats as they're independent of filters
  }
  
  /// Invalidate cache (force refresh on next load)
  void invalidateCache() {
    _pageCache.clear();
    _cachedStats = null;
    _statsLastFetchTime = null;
    _lastStatusFilter = null;
    _lastSearchQuery = null;
    print('🗑️ All caches cleared');
  }
  
  /// Update a single clinic in ALL cached pages that contain it
  void updateClinicInCache(ClinicRegistration updatedClinic) {
    int updatedCount = 0;
    
    // Update clinic in all cached pages
    for (var entry in _pageCache.entries) {
      final clinics = entry.value.clinics;
      final index = clinics.indexWhere((c) => c.id == updatedClinic.id);
      if (index != -1) {
        clinics[index] = updatedClinic;
        updatedCount++;
      }
    }
    
    if (updatedCount > 0) {
      print('✏️ Updated clinic in $updatedCount cached pages');
    }
    
    // Note: Stats will be refreshed from server on next navigation
  }
  
  /// Get cache statistics for debugging
  Map<String, dynamic> getCacheStats() {
    return {
      'totalCachedPages': _pageCache.length,
      'maxCachedPages': _maxCachedPages,
      'cacheDuration': _cacheDuration.inMinutes,
      'hasStats': _cachedStats != null,
      'cachedPageKeys': _pageCache.keys.map((k) => k.toString()).toList(),
    };
  }
  
  /// Clear cache on logout or when needed
  void clearCache() {
    invalidateCache();
  }
}
