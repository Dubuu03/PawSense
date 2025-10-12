import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawsense/core/models/skin_disease/skin_disease_model.dart';

/// Service for managing skin diseases in super admin panel
class SkinDiseasesService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'skinDiseases';

  /// Fetch all diseases with optional filters and sorting
  static Future<List<SkinDiseaseModel>> fetchAllDiseases({
    String? detectionFilter, // 'ai' or 'info'
    List<String>? speciesFilter, // ['cats'], ['dogs'], or both
    String? severityFilter, // 'mild', 'moderate', 'severe', 'varies'
    List<String>? categoriesFilter,
    bool? contagiousFilter,
    String? searchQuery,
    String sortBy = 'name_asc',
  }) async {
    try {
      Query query = _firestore.collection(_collection);

      // Apply Firestore filters
      if (detectionFilter != null) {
        query = query.where('detectionMethod', isEqualTo: detectionFilter);
      }

      if (severityFilter != null && severityFilter != 'all') {
        query = query.where('severity', isEqualTo: severityFilter);
      }

      if (contagiousFilter != null) {
        query = query.where('isContagious', isEqualTo: contagiousFilter);
      }

      // Fetch documents
      final snapshot = await query.get();
      List<SkinDiseaseModel> diseases = snapshot.docs
          .map((doc) => SkinDiseaseModel.fromFirestore(doc))
          .toList();

      // Apply client-side filters
      if (speciesFilter != null && speciesFilter.isNotEmpty) {
        diseases = diseases.where((disease) {
          final diseaseLower = disease.species.map((s) => s.toLowerCase()).toList();
          return speciesFilter.any((filter) => 
            diseaseLower.any((s) => s.contains(filter.toLowerCase()))
          );
        }).toList();
      }

      if (categoriesFilter != null && categoriesFilter.isNotEmpty) {
        diseases = diseases.where((disease) {
          return categoriesFilter.any((filter) => 
            disease.categories.any((c) => c.toLowerCase() == filter.toLowerCase())
          );
        }).toList();
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        diseases = diseases.where((disease) {
          return disease.name.toLowerCase().contains(query) ||
                 disease.description.toLowerCase().contains(query) ||
                 disease.symptoms.any((s) => s.toLowerCase().contains(query)) ||
                 disease.causes.any((c) => c.toLowerCase().contains(query));
        }).toList();
      }

      // Apply sorting
      diseases = _sortDiseases(diseases, sortBy);

      return diseases;
    } catch (e) {
      print('Error fetching diseases: $e');
      rethrow;
    }
  }

  /// Fetch single disease by ID
  static Future<SkinDiseaseModel?> fetchDiseaseById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists) {
        return SkinDiseaseModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error fetching disease by ID: $e');
      rethrow;
    }
  }

  /// Create new disease
  static Future<String> createDisease(SkinDiseaseModel disease) async {
    try {
      // Check for duplicate name
      final isDuplicate = await _checkDuplicateName(disease.name);
      if (isDuplicate) {
        throw Exception('A disease with this name already exists');
      }

      // Validate disease
      _validateDisease(disease);

      // Create document
      final docRef = await _firestore.collection(_collection).add(
        disease.copyWith(
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          viewCount: 0,
        ).toFirestore(),
      );

      return docRef.id;
    } catch (e) {
      print('Error creating disease: $e');
      rethrow;
    }
  }

  /// Update existing disease
  static Future<void> updateDisease(String id, SkinDiseaseModel disease) async {
    try {
      // Check for duplicate name (excluding current disease)
      final isDuplicate = await _checkDuplicateName(disease.name, excludeId: id);
      if (isDuplicate) {
        throw Exception('A disease with this name already exists');
      }

      // Validate disease
      _validateDisease(disease);

      // Update document
      await _firestore.collection(_collection).doc(id).update(
        disease.copyWith(updatedAt: DateTime.now()).toFirestore(),
      );
    } catch (e) {
      print('Error updating disease: $e');
      rethrow;
    }
  }

  /// Delete disease
  static Future<void> deleteDisease(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      print('Error deleting disease: $e');
      rethrow;
    }
  }

  /// Duplicate disease (create copy)
  static Future<String> duplicateDisease(String id) async {
    try {
      final disease = await fetchDiseaseById(id);
      if (disease == null) {
        throw Exception('Disease not found');
      }

      // Create copy with modified name
      final copy = disease.copyWith(
        id: '', // Will be auto-generated
        name: '${disease.name} (Copy)',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        viewCount: 0,
      );

      return await createDisease(copy);
    } catch (e) {
      print('Error duplicating disease: $e');
      rethrow;
    }
  }

  /// Increment view count
  static Future<void> incrementViewCount(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).update({
        'viewCount': FieldValue.increment(1),
      });
    } catch (e) {
      print('Error incrementing view count: $e');
      // Don't rethrow - this is not critical
    }
  }

  /// Get disease statistics for dashboard
  static Future<Map<String, int>> getDiseaseStatistics() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();
      final diseases = snapshot.docs
          .map((doc) => SkinDiseaseModel.fromFirestore(doc))
          .toList();

      int aiCount = 0;
      int infoCount = 0;
      Set<String> categories = {};

      for (final disease in diseases) {
        if (disease.detectionMethod == 'ai' || disease.detectionMethod == 'both') {
          aiCount++;
        } else {
          infoCount++;
        }
        categories.addAll(disease.categories);
      }

      return {
        'total': diseases.length,
        'ai': aiCount,
        'info': infoCount,
        'categories': categories.length,
      };
    } catch (e) {
      print('Error getting statistics: $e');
      return {
        'total': 0,
        'ai': 0,
        'info': 0,
        'categories': 0,
      };
    }
  }

  /// Check if disease name already exists
  static Future<bool> _checkDuplicateName(String name, {String? excludeId}) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('name', isEqualTo: name.trim())
          .get();

      // If excluding an ID, filter it out
      if (excludeId != null) {
        return snapshot.docs.any((doc) => doc.id != excludeId);
      }

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking duplicate name: $e');
      return false;
    }
  }

  /// Validate disease before save
  static void _validateDisease(SkinDiseaseModel disease) {
    if (disease.name.trim().length < 5 || disease.name.trim().length > 100) {
      throw Exception('Disease name must be 5-100 characters');
    }

    if (disease.description.trim().length < 20 || disease.description.trim().length > 500) {
      throw Exception('Description must be 20-500 characters');
    }

    if (disease.species.isEmpty) {
      throw Exception('At least one species must be selected');
    }

    if (disease.categories.isEmpty) {
      throw Exception('At least one category must be selected');
    }

    if (disease.symptoms.length < 3) {
      throw Exception('At least 3 symptoms are required');
    }

    if (disease.causes.length < 2) {
      throw Exception('At least 2 causes are required');
    }

    if (disease.treatments.length < 3) {
      throw Exception('At least 3 treatments are required');
    }

    if (disease.imageUrl.isNotEmpty && !_isValidUrl(disease.imageUrl)) {
      throw Exception('Invalid image URL format');
    }
  }

  /// Validate URL format
  static bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  /// Sort diseases
  static List<SkinDiseaseModel> _sortDiseases(List<SkinDiseaseModel> diseases, String sortBy) {
    switch (sortBy) {
      case 'name_asc':
        diseases.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'name_desc':
        diseases.sort((a, b) => b.name.compareTo(a.name));
        break;
      case 'date_added':
        diseases.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'date_updated':
        diseases.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
      case 'most_viewed':
        diseases.sort((a, b) => b.viewCount.compareTo(a.viewCount));
        break;
      case 'severity':
        diseases.sort((a, b) {
          final severityOrder = {'severe': 3, 'moderate': 2, 'mild': 1, 'varies': 0};
          return (severityOrder[b.severity] ?? 0).compareTo(severityOrder[a.severity] ?? 0);
        });
        break;
      default:
        diseases.sort((a, b) => a.name.compareTo(b.name));
    }
    return diseases;
  }
}
