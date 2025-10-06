import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawsense/core/models/skin_disease/skin_disease_model.dart';
import 'package:pawsense/core/utils/data_cache.dart';

/// Service for managing skin disease information
/// 
/// Provides CRUD operations for skin diseases in Firestore
/// Uses DataCache for performance optimization (24-hour TTL)
class SkinDiseaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DataCache _cache = DataCache();
  
  static const String _collectionName = 'skinDiseases';
  static const Duration _cacheDuration = Duration(hours: 24);
  
  // Cache keys
  static const String _allDiseasesKey = 'all_skin_diseases';
  static const String _categoriesKey = 'skin_disease_categories';
  static const String _recentViewsKey = 'recent_skin_diseases';

  /// Get all skin diseases with optional filtering
  /// 
  /// [species] - Filter by species: 'cats', 'dogs', or null for all
  /// [category] - Filter by category (e.g., 'parasitic', 'allergic')
  /// [detectionMethod] - Filter by detection method: 'ai', 'vet_guided', 'both'
  /// [useCache] - Whether to use cached data (default: true)
  Future<List<SkinDiseaseModel>> getAllDiseases({
    String? species,
    String? category,
    String? detectionMethod,
    bool useCache = true,
  }) async {
    try {
      // Create cache key based on filters
      final cacheKey = '${_allDiseasesKey}_${species ?? 'all'}_${category ?? 'all'}_${detectionMethod ?? 'all'}';
      
      // Try to get from cache
      if (useCache) {
        final cached = _cache.get<List<SkinDiseaseModel>>(cacheKey);
        if (cached != null) {
          print('SkinDiseaseService: Returning cached diseases (${cached.length} items)');
          return cached;
        }
      }

      // Query Firestore
      print('SkinDiseaseService: Querying collection: $_collectionName');
      Query query = _firestore.collection(_collectionName);

      // Build query based on filters
      // Note: Firestore queries are limited - complex filtering done in code
      
      final snapshot = await query.get();
      print('SkinDiseaseService: Raw documents fetched: ${snapshot.docs.length}');
      
      // Debug: Print first document if exists
      if (snapshot.docs.isNotEmpty) {
        print('SkinDiseaseService: First document data: ${snapshot.docs.first.data()}');
      }
      
      // Parse and filter results
      List<SkinDiseaseModel> diseases = [];
      for (var doc in snapshot.docs) {
        try {
          final disease = SkinDiseaseModel.fromFirestore(doc);
          diseases.add(disease);
          print('SkinDiseaseService: Successfully parsed disease: ${disease.name}');
        } catch (e) {
          print('SkinDiseaseService: Error parsing document ${doc.id}: $e');
        }
      }

      // Apply client-side filters
      if (species != null && species.isNotEmpty) {
        diseases = diseases.where((disease) {
          return disease.species.contains(species) || disease.species.contains('both');
        }).toList();
      }

      if (category != null && category.isNotEmpty) {
        diseases = diseases.where((disease) {
          return disease.categories.contains(category);
        }).toList();
      }

      if (detectionMethod != null && detectionMethod.isNotEmpty) {
        diseases = diseases.where((disease) {
          return disease.detectionMethod == detectionMethod || disease.detectionMethod == 'both';
        }).toList();
      }

      // Sort by view count (most popular first)
      diseases.sort((a, b) => b.viewCount.compareTo(a.viewCount));

      // Cache results
      _cache.put(cacheKey, diseases, ttl: _cacheDuration);
      
      print('SkinDiseaseService: Fetched ${diseases.length} diseases from Firestore');
      return diseases;
    } catch (e) {
      print('SkinDiseaseService: Error fetching diseases: $e');
      rethrow;
    }
  }

  /// Get a single disease by ID and increment view count
  Future<SkinDiseaseModel?> getDiseaseById(String id) async {
    try {
      final cacheKey = 'disease_$id';
      
      // Try cache first
      final cached = _cache.get<SkinDiseaseModel>(cacheKey);
      if (cached != null) {
        // Increment view count asynchronously
        _incrementViewCount(id);
        return cached;
      }

      // Fetch from Firestore
      final doc = await _firestore.collection(_collectionName).doc(id).get();
      
      if (!doc.exists) {
        print('SkinDiseaseService: Disease not found with id: $id');
        return null;
      }

      final disease = SkinDiseaseModel.fromFirestore(doc);
      
      // Cache the result
      _cache.put(cacheKey, disease, ttl: _cacheDuration);
      
      // Increment view count
      _incrementViewCount(id);
      
      return disease;
    } catch (e) {
      print('SkinDiseaseService: Error fetching disease by ID: $e');
      rethrow;
    }
  }

  /// Get recently viewed diseases (top 10 by view count)
  Future<List<SkinDiseaseModel>> getRecentlyViewed({bool useCache = true}) async {
    try {
      if (useCache) {
        final cached = _cache.get<List<SkinDiseaseModel>>(_recentViewsKey);
        if (cached != null) {
          return cached;
        }
      }

      final snapshot = await _firestore
          .collection(_collectionName)
          .orderBy('viewCount', descending: true)
          .limit(10)
          .get();

      final diseases = snapshot.docs
          .map((doc) => SkinDiseaseModel.fromFirestore(doc))
          .toList();

      _cache.put(_recentViewsKey, diseases, ttl: _cacheDuration);
      
      return diseases;
    } catch (e) {
      print('SkinDiseaseService: Error fetching recently viewed: $e');
      return [];
    }
  }

  /// Search diseases by name or description
  Future<List<SkinDiseaseModel>> searchDiseases(String query) async {
    try {
      if (query.isEmpty) {
        return getAllDiseases();
      }

      // Get all diseases and filter client-side
      // (Firestore doesn't support full-text search natively)
      final allDiseases = await getAllDiseases();
      
      final searchLower = query.toLowerCase();
      
      return allDiseases.where((disease) {
        return disease.name.toLowerCase().contains(searchLower) ||
            disease.description.toLowerCase().contains(searchLower) ||
            disease.symptoms.any((symptom) => symptom.toLowerCase().contains(searchLower));
      }).toList();
    } catch (e) {
      print('SkinDiseaseService: Error searching diseases: $e');
      rethrow;
    }
  }

  /// Get unique categories from all diseases
  Future<List<String>> getCategories({bool useCache = true}) async {
    try {
      if (useCache) {
        final cached = _cache.get<List<String>>(_categoriesKey);
        if (cached != null) {
          return cached;
        }
      }

      final diseases = await getAllDiseases();
      final categories = <String>{};
      
      for (var disease in diseases) {
        categories.addAll(disease.categories);
      }
      
      final categoryList = categories.toList()..sort();
      
      _cache.put(_categoriesKey, categoryList, ttl: _cacheDuration);
      
      return categoryList;
    } catch (e) {
      print('SkinDiseaseService: Error fetching categories: $e');
      return [];
    }
  }

  /// Increment view count for a disease (async, non-blocking)
  Future<void> _incrementViewCount(String diseaseId) async {
    try {
      await _firestore.collection(_collectionName).doc(diseaseId).update({
        'viewCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Invalidate cache
      _cache.invalidate('disease_$diseaseId');
      _cache.invalidate(_recentViewsKey);
      
      print('SkinDiseaseService: Incremented view count for $diseaseId');
    } catch (e) {
      print('SkinDiseaseService: Error incrementing view count: $e');
      // Non-critical error, don't rethrow
    }
  }

  /// Clear all cached data
  void clearCache() {
    _cache.clear();
    print('SkinDiseaseService: Cache cleared');
  }

  /// Admin: Create a new disease (for admin panel - future use)
  Future<String> createDisease(SkinDiseaseModel disease) async {
    try {
      final docRef = await _firestore.collection(_collectionName).add(
        disease.copyWith(
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ).toFirestore(),
      );
      
      clearCache();
      
      return docRef.id;
    } catch (e) {
      print('SkinDiseaseService: Error creating disease: $e');
      rethrow;
    }
  }

  /// Admin: Update an existing disease
  Future<void> updateDisease(String id, SkinDiseaseModel disease) async {
    try {
      await _firestore.collection(_collectionName).doc(id).update(
        disease.copyWith(updatedAt: DateTime.now()).toFirestore(),
      );
      
      clearCache();
    } catch (e) {
      print('SkinDiseaseService: Error updating disease: $e');
      rethrow;
    }
  }

  /// Admin: Delete a disease
  Future<void> deleteDisease(String id) async {
    try {
      await _firestore.collection(_collectionName).doc(id).delete();
      
      clearCache();
    } catch (e) {
      print('SkinDiseaseService: Error deleting disease: $e');
      rethrow;
    }
  }
}
