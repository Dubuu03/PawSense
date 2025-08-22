/// Universal cache manager for optimizing data fetching and navigation
class CacheManager {
  static final CacheManager _instance = CacheManager._internal();
  factory CacheManager() => _instance;
  CacheManager._internal();

  // Cache storage
  final Map<String, CachedData> _cache = {};
  final Map<String, List<CachedData>> _categoryCache = {};
  
  /// Cache data with expiration
  void cache<T>(String key, T data, {Duration? expiry}) {
    final expiresAt = expiry != null 
        ? DateTime.now().add(expiry) 
        : DateTime.now().add(const Duration(hours: 1)); // Default 1 hour
    
    _cache[key] = CachedData(
      data: data,
      expiresAt: expiresAt,
      createdAt: DateTime.now(),
    );
  }
  
  /// Cache data by category (for bulk operations)
  void cacheByCategory<T>(String category, String key, T data, {Duration? expiry}) {
    cache(key, data, expiry: expiry);
    
    final cachedData = _cache[key]!;
    if (!_categoryCache.containsKey(category)) {
      _categoryCache[category] = [];
    }
    
    // Remove existing entry if exists
    _categoryCache[category]!.removeWhere((item) => 
        _getCacheKey(item.data) == key);
    
    _categoryCache[category]!.add(cachedData);
  }
  
  /// Get cached data
  T? get<T>(String key) {
    final cached = _cache[key];
    if (cached == null) return null;
    
    if (cached.isExpired) {
      _cache.remove(key);
      return null;
    }
    
    return cached.data as T;
  }
  
  /// Get all cached data by category
  List<T> getByCategory<T>(String category) {
    final categoryData = _categoryCache[category];
    if (categoryData == null) return [];
    
    final validData = <T>[];
    final expiredKeys = <String>[];
    
    for (final cached in categoryData) {
      if (cached.isExpired) {
        expiredKeys.add(_getCacheKey(cached.data));
      } else {
        validData.add(cached.data as T);
      }
    }
    
    // Clean up expired entries
    for (final key in expiredKeys) {
      _cache.remove(key);
    }
    
    _categoryCache[category]?.removeWhere((item) => item.isExpired);
    
    return validData;
  }
  
  /// Check if data is cached and valid
  bool has(String key) {
    final cached = _cache[key];
    if (cached == null) return false;
    
    if (cached.isExpired) {
      _cache.remove(key);
      return false;
    }
    
    return true;
  }
  
  /// Invalidate cache for a key
  void invalidate(String key) {
    _cache.remove(key);
    
    // Remove from category caches
    _categoryCache.forEach((category, items) {
      items.removeWhere((item) => _getCacheKey(item.data) == key);
    });
  }
  
  /// Invalidate all cache for a category
  void invalidateCategory(String category) {
    final categoryData = _categoryCache[category];
    if (categoryData != null) {
      for (final cached in categoryData) {
        _cache.remove(_getCacheKey(cached.data));
      }
      _categoryCache.remove(category);
    }
  }
  
  /// Clear all cache
  void clearAll() {
    _cache.clear();
    _categoryCache.clear();
  }
  
  /// Preload data (fire-and-forget caching)
  Future<void> preload<T>(String key, Future<T> Function() fetcher, {Duration? expiry}) async {
    if (has(key)) return; // Already cached
    
    try {
      final data = await fetcher();
      cache(key, data, expiry: expiry);
    } catch (e) {
      // Ignore preload errors
    }
  }
  
  /// Get with fallback to fetcher
  Future<T> getOrFetch<T>(String key, Future<T> Function() fetcher, {Duration? expiry}) async {
    // Try cache first
    final cached = get<T>(key);
    if (cached != null) return cached;
    
    // Fetch and cache
    final data = await fetcher();
    cache(key, data, expiry: expiry);
    return data;
  }
  
  /// Get with fallback to fetcher (nullable version)
  Future<T?> getOrFetchNullable<T>(String key, Future<T?> Function() fetcher, {Duration? expiry}) async {
    // Try cache first
    final cached = get<T>(key);
    if (cached != null) return cached;
    
    try {
      // Fetch and cache
      final data = await fetcher();
      if (data != null) {
        cache(key, data, expiry: expiry);
      }
      return data;
    } catch (e) {
      return null;
    }
  }
  
  /// Batch fetch with caching
  Future<Map<String, T?>> batchGetOrFetch<T>(
    Map<String, Future<T> Function()> fetchers, 
    {Duration? expiry}
  ) async {
    final results = <String, T?>{};
    final fetchTasks = <String, Future<T>>{};
    
    // Check cache first
    for (final entry in fetchers.entries) {
      final cached = get<T>(entry.key);
      if (cached != null) {
        results[entry.key] = cached;
      } else {
        fetchTasks[entry.key] = entry.value();
      }
    }
    
    // Fetch missing data in parallel
    if (fetchTasks.isNotEmpty) {
      final fetchResults = <T?>[];
      
      for (final entry in fetchTasks.entries) {
        try {
          final result = await entry.value;
          fetchResults.add(result);
        } catch (e) {
          fetchResults.add(null);
        }
      }
      
      int index = 0;
      for (final entry in fetchTasks.entries) {
        final data = fetchResults[index++];
        if (data != null) {
          cache(entry.key, data, expiry: expiry);
        }
        results[entry.key] = data;
      }
    }
    
    return results;
  }
  
  /// Get cache statistics
  CacheStats getStats() {
    int totalEntries = _cache.length;
    int expiredEntries = 0;
    int categoryCount = _categoryCache.length;
    
    for (final cached in _cache.values) {
      if (cached.isExpired) expiredEntries++;
    }
    
    return CacheStats(
      totalEntries: totalEntries,
      expiredEntries: expiredEntries,
      categoryCount: categoryCount,
      hitRate: 0.0, // Would need to track hits/misses for accurate rate
    );
  }
  
  String _getCacheKey(dynamic data) {
    // Generate cache key from data
    if (data is Map && data.containsKey('id')) {
      return data['id'].toString();
    }
    return data.hashCode.toString();
  }
}

/// Cached data wrapper
class CachedData {
  final dynamic data;
  final DateTime expiresAt;
  final DateTime createdAt;
  
  CachedData({
    required this.data,
    required this.expiresAt,
    required this.createdAt,
  });
  
  bool get isExpired => DateTime.now().isAfter(expiresAt);
  Duration get age => DateTime.now().difference(createdAt);
}

/// Cache statistics
class CacheStats {
  final int totalEntries;
  final int expiredEntries;
  final int categoryCount;
  final double hitRate;
  
  CacheStats({
    required this.totalEntries,
    required this.expiredEntries,
    required this.categoryCount,
    required this.hitRate,
  });
  
  @override
  String toString() {
    return 'CacheStats(total: $totalEntries, expired: $expiredEntries, categories: $categoryCount, hitRate: ${(hitRate * 100).toStringAsFixed(1)}%)';
  }
}
