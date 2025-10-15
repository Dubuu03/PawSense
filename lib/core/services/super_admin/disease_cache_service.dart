import 'package:pawsense/core/models/skin_disease/skin_disease_model.dart';

/// Cache key for storing page data
class _CacheKey {
  final String? detectionFilter;
  final List<String> speciesFilter;
  final String? severityFilter;
  final List<String> categoriesFilter;
  final bool? contagiousFilter;
  final String searchQuery;
  final String sortBy;
  final int page;

  _CacheKey({
    required this.detectionFilter,
    required this.speciesFilter,
    required this.severityFilter,
    required this.categoriesFilter,
    required this.contagiousFilter,
    required this.searchQuery,
    required this.sortBy,
    required this.page,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _CacheKey &&
          runtimeType == other.runtimeType &&
          detectionFilter == other.detectionFilter &&
          _listEquals(speciesFilter, other.speciesFilter) &&
          severityFilter == other.severityFilter &&
          _listEquals(categoriesFilter, other.categoriesFilter) &&
          contagiousFilter == other.contagiousFilter &&
          searchQuery == other.searchQuery &&
          sortBy == other.sortBy &&
          page == other.page;

  @override
  int get hashCode =>
      detectionFilter.hashCode ^
      speciesFilter.hashCode ^
      severityFilter.hashCode ^
      categoriesFilter.hashCode ^
      contagiousFilter.hashCode ^
      searchQuery.hashCode ^
      sortBy.hashCode ^
      page.hashCode;

  @override
  String toString() =>
      'CacheKey(detection: $detectionFilter, species: $speciesFilter, severity: $severityFilter, categories: $categoriesFilter, contagious: $contagiousFilter, search: $searchQuery, sort: $sortBy, page: $page)';

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Cached page data
class _CachedPageData {
  final List<SkinDiseaseModel> diseases;
  final int totalDiseases;
  final int totalPages;
  final DateTime fetchTime;

  _CachedPageData({
    required this.diseases,
    required this.totalDiseases,
    required this.totalPages,
    required this.fetchTime,
  });

  bool isValid(Duration cacheDuration) {
    final now = DateTime.now();
    final difference = now.difference(fetchTime);
    return difference < cacheDuration;
  }
}

/// Service to cache disease data and manage refresh logic
/// Optimized for multi-page caching - remembers all visited pages
class DiseaseCacheService {
  static final DiseaseCacheService _instance = DiseaseCacheService._internal();
  factory DiseaseCacheService() => _instance;
  DiseaseCacheService._internal();

  // Multi-page cache storage - stores all visited pages
  final Map<_CacheKey, _CachedPageData> _pageCache = {};
  Map<String, int>? _cachedStats;
  DateTime? _statsLastFetchTime;

  // Cache configuration
  final Duration _cacheDuration = Duration(minutes: 5);
  final int _maxCachedPages = 20; // Limit cache size to prevent memory issues

  // Current filters context
  String? _lastDetectionFilter;
  List<String>? _lastSpeciesFilter;
  String? _lastSeverityFilter;
  List<String>? _lastCategoriesFilter;
  bool? _lastContagiousFilter;
  String? _lastSearchQuery;
  String? _lastSortBy;

  /// Get cached page data if available and valid
  _CachedPageData? getCachedPage({
    required String? detectionFilter,
    required List<String> speciesFilter,
    required String? severityFilter,
    required List<String> categoriesFilter,
    required bool? contagiousFilter,
    required String searchQuery,
    required String sortBy,
    required int page,
  }) {
    final key = _CacheKey(
      detectionFilter: detectionFilter,
      speciesFilter: speciesFilter,
      severityFilter: severityFilter,
      categoriesFilter: categoriesFilter,
      contagiousFilter: contagiousFilter,
      searchQuery: searchQuery,
      sortBy: sortBy,
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
  bool hasFiltersChanged(
    String? detectionFilter,
    List<String> speciesFilter,
    String? severityFilter,
    List<String> categoriesFilter,
    bool? contagiousFilter,
    String searchQuery,
    String sortBy,
  ) {
    return _lastDetectionFilter != detectionFilter ||
        !_listEquals(_lastSpeciesFilter ?? [], speciesFilter) ||
        _lastSeverityFilter != severityFilter ||
        !_listEquals(_lastCategoriesFilter ?? [], categoriesFilter) ||
        _lastContagiousFilter != contagiousFilter ||
        _lastSearchQuery != searchQuery ||
        _lastSortBy != sortBy;
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
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
    required List<SkinDiseaseModel> diseases,
    required int totalDiseases,
    required int totalPages,
    required Map<String, int> stats,
    required String? detectionFilter,
    required List<String> speciesFilter,
    required String? severityFilter,
    required List<String> categoriesFilter,
    required bool? contagiousFilter,
    required String searchQuery,
    required String sortBy,
    required int page,
  }) {
    // Create cache key
    final key = _CacheKey(
      detectionFilter: detectionFilter,
      speciesFilter: speciesFilter,
      severityFilter: severityFilter,
      categoriesFilter: categoriesFilter,
      contagiousFilter: contagiousFilter,
      searchQuery: searchQuery,
      sortBy: sortBy,
      page: page,
    );

    // Store page data
    _pageCache[key] = _CachedPageData(
      diseases: diseases,
      totalDiseases: totalDiseases,
      totalPages: totalPages,
      fetchTime: DateTime.now(),
    );

    // Update stats
    _cachedStats = stats;
    _statsLastFetchTime = DateTime.now();

    // Update filter context
    _lastDetectionFilter = detectionFilter;
    _lastSpeciesFilter = List.from(speciesFilter);
    _lastSeverityFilter = severityFilter;
    _lastCategoriesFilter = List.from(categoriesFilter);
    _lastContagiousFilter = contagiousFilter;
    _lastSearchQuery = searchQuery;
    _lastSortBy = sortBy;

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
    _lastDetectionFilter = null;
    _lastSpeciesFilter = null;
    _lastSeverityFilter = null;
    _lastCategoriesFilter = null;
    _lastContagiousFilter = null;
    _lastSearchQuery = null;
    _lastSortBy = null;
    print('🗑️ All caches cleared');
  }

  /// Update a single disease in ALL cached pages that contain it
  void updateDiseaseInCache(SkinDiseaseModel updatedDisease) {
    int updatedCount = 0;

    // Update disease in all cached pages
    for (var entry in _pageCache.entries) {
      final diseases = entry.value.diseases;
      final index = diseases.indexWhere((d) => d.id == updatedDisease.id);
      if (index != -1) {
        diseases[index] = updatedDisease;
        updatedCount++;
      }
    }

    if (updatedCount > 0) {
      print('✅ Updated disease in $updatedCount cached page(s)');
    }
  }

  /// Remove a disease from ALL cached pages after deletion
  void removeDiseaseFromCache(String diseaseId) {
    int removedCount = 0;

    // Remove disease from all cached pages
    for (var entry in _pageCache.entries) {
      final diseases = entry.value.diseases;
      final initialLength = diseases.length;
      diseases.removeWhere((d) => d.id == diseaseId);
      if (diseases.length < initialLength) {
        removedCount++;
      }
    }

    if (removedCount > 0) {
      print('✅ Removed disease from $removedCount cached page(s)');
    }
  }
}
