import 'package:pawsense/core/models/user/user_model.dart';

/// Cache key for storing page data
class _UserCacheKey {
  final String roleFilter;
  final String statusFilter;
  final String searchQuery;
  final int page;

  _UserCacheKey({
    required this.roleFilter,
    required this.statusFilter,
    required this.searchQuery,
    required this.page,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _UserCacheKey &&
          runtimeType == other.runtimeType &&
          roleFilter == other.roleFilter &&
          statusFilter == other.statusFilter &&
          searchQuery == other.searchQuery &&
          page == other.page;

  @override
  int get hashCode =>
      roleFilter.hashCode ^
      statusFilter.hashCode ^
      searchQuery.hashCode ^
      page.hashCode;

  @override
  String toString() =>
      'UserCacheKey(role: $roleFilter, status: $statusFilter, search: $searchQuery, page: $page)';
}

/// Cached page data
class _CachedUserPageData {
  final List<Map<String, dynamic>> usersWithStatus;
  final int totalUsers;
  final int totalPages;
  final DateTime fetchTime;

  _CachedUserPageData({
    required this.usersWithStatus,
    required this.totalUsers,
    required this.totalPages,
    required this.fetchTime,
  });

  bool isValid(Duration cacheDuration) {
    final now = DateTime.now();
    final difference = now.difference(fetchTime);
    return difference < cacheDuration;
  }
}

/// Service to cache user data and manage refresh logic
/// Optimized for multi-page caching - remembers all visited pages
class UserCacheService {
  static final UserCacheService _instance = UserCacheService._internal();
  factory UserCacheService() => _instance;
  UserCacheService._internal();

  // Multi-page cache storage - stores all visited pages
  final Map<_UserCacheKey, _CachedUserPageData> _pageCache = {};
  Map<String, int>? _cachedStats;
  DateTime? _statsLastFetchTime;

  // Cache configuration
  final Duration _cacheDuration = Duration(minutes: 5);
  final int _maxCachedPages = 20; // Limit cache size to prevent memory issues

  // Current filters context
  String? _lastRoleFilter;
  String? _lastStatusFilter;
  String? _lastSearchQuery;

  /// Get cached page data if available and valid
  _CachedUserPageData? getCachedPage({
    required String roleFilter,
    required String statusFilter,
    required String searchQuery,
    required int page,
  }) {
    final key = _UserCacheKey(
      roleFilter: roleFilter,
      statusFilter: statusFilter,
      searchQuery: searchQuery,
      page: page,
    );

    final cachedData = _pageCache[key];
    if (cachedData == null) {
      print('📭 No user cache for $key');
      return null;
    }

    if (!cachedData.isValid(_cacheDuration)) {
      print('⏰ User cache expired for $key');
      _pageCache.remove(key);
      return null;
    }

    print('✅ User cache HIT for $key');
    return cachedData;
  }

  /// Check if filters have changed (not including page)
  bool hasFiltersChanged(
      String? roleFilter, String? statusFilter, String? searchQuery) {
    return _lastRoleFilter != roleFilter ||
        _lastStatusFilter != statusFilter ||
        _lastSearchQuery != searchQuery;
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
    required List<Map<String, dynamic>> usersWithStatus,
    required int totalUsers,
    required int totalPages,
    required Map<String, int> stats,
    required String roleFilter,
    required String statusFilter,
    required String searchQuery,
    required int page,
  }) {
    // Create cache key
    final key = _UserCacheKey(
      roleFilter: roleFilter,
      statusFilter: statusFilter,
      searchQuery: searchQuery,
      page: page,
    );

    // Store page data
    _pageCache[key] = _CachedUserPageData(
      usersWithStatus: usersWithStatus,
      totalUsers: totalUsers,
      totalPages: totalPages,
      fetchTime: DateTime.now(),
    );

    // Update stats
    _cachedStats = stats;
    _statsLastFetchTime = DateTime.now();

    // Update filter context
    _lastRoleFilter = roleFilter;
    _lastStatusFilter = statusFilter;
    _lastSearchQuery = searchQuery;

    // Enforce cache size limit (LRU-style: remove oldest entries)
    if (_pageCache.length > _maxCachedPages) {
      _evictOldestCacheEntries();
    }

    print(
        '💾 Cached user page data for $key (${_pageCache.length} pages in cache)');
  }

  /// Remove oldest cache entries when limit is reached
  void _evictOldestCacheEntries() {
    final entries = _pageCache.entries.toList()
      ..sort((a, b) => a.value.fetchTime.compareTo(b.value.fetchTime));

    // Remove oldest 25% of entries
    final removeCount = (_maxCachedPages * 0.25).ceil();
    for (var i = 0; i < removeCount && entries.isNotEmpty; i++) {
      _pageCache.remove(entries[i].key);
      print('🗑️ Evicted old user cache entry: ${entries[i].key}');
    }
  }

  /// Invalidate all caches when filters change
  void invalidateCacheForFilterChange() {
    print('🔄 User filters changed - clearing all page caches');
    _pageCache.clear();
    // Keep stats as they're independent of filters
  }

  /// Invalidate cache (force refresh on next load)
  void invalidateCache() {
    _pageCache.clear();
    _cachedStats = null;
    _statsLastFetchTime = null;
    _lastRoleFilter = null;
    _lastStatusFilter = null;
    _lastSearchQuery = null;
    print('🗑️ All user caches cleared');
  }

  /// Update a single user in ALL cached pages that contain it
  void updateUserInCache(UserModel updatedUser) {
    int updatedCount = 0;

    // Update user in all cached pages
    for (var entry in _pageCache.entries) {
      final usersWithStatus = entry.value.usersWithStatus;
      final index = usersWithStatus.indexWhere(
          (u) => (u['user'] as UserModel).uid == updatedUser.uid);
      if (index != -1) {
        usersWithStatus[index]['user'] = updatedUser;
        updatedCount++;
      }
    }

    if (updatedCount > 0) {
      print('✏️ Updated user in $updatedCount cached pages');
    }
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
