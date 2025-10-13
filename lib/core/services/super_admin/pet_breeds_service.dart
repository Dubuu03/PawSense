import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/breeds/pet_breed_model.dart';

/// Service for managing pet breeds in Firestore
class PetBreedsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'petBreeds';

  /// Get all breeds with optional filtering and sorting
  static Future<List<PetBreed>> fetchAllBreeds({
    String? speciesFilter,
    String? statusFilter,
    String? searchQuery,
    String sortBy = 'name_asc',
  }) async {
    try {
      print('🔍 Fetching breeds: species=$speciesFilter, status=$statusFilter, search=$searchQuery, sort=$sortBy');

      Query query = _firestore.collection(_collection);

      // Apply species filter
      if (speciesFilter != null && speciesFilter != 'all' && speciesFilter.isNotEmpty) {
        query = query.where('species', isEqualTo: speciesFilter);
      }

      // Apply status filter
      if (statusFilter != null && statusFilter != 'all' && statusFilter.isNotEmpty) {
        query = query.where('status', isEqualTo: statusFilter);
      }

      // Get all matching documents
      final snapshot = await query.get();
      print('📦 Retrieved ${snapshot.docs.length} breeds from Firestore');

      // Convert to breed objects
      List<PetBreed> breeds = snapshot.docs
          .map((doc) => PetBreed.fromFirestore(doc))
          .toList();

      // Apply search filter (client-side)
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        breeds = breeds.where((breed) {
          return breed.name.toLowerCase().contains(query);
        }).toList();
        print('🔍 After search filtering: ${breeds.length} breeds');
      }

      // Apply sorting
      breeds = _sortBreeds(breeds, sortBy);

      print('✅ Returning ${breeds.length} breeds');
      return breeds;
    } catch (e) {
      print('❌ Error fetching breeds: $e');
      return [];
    }
  }

  /// Get paginated breeds with optional filtering and sorting
  static Future<Map<String, dynamic>> getPaginatedBreeds({
    int page = 1,
    int itemsPerPage = 10,
    String? speciesFilter,
    String? statusFilter,
    String? searchQuery,
    String sortBy = 'name_asc',
  }) async {
    try {
      // Fetch all matching breeds first
      final allBreeds = await fetchAllBreeds(
        speciesFilter: speciesFilter,
        statusFilter: statusFilter,
        searchQuery: searchQuery,
        sortBy: sortBy,
      );

      // Calculate pagination
      final totalBreeds = allBreeds.length;
      final totalPages = (totalBreeds / itemsPerPage).ceil();
      final validPage = page.clamp(1, totalPages > 0 ? totalPages : 1);

      // Get paginated subset
      final startIndex = (validPage - 1) * itemsPerPage;
      final endIndex = (startIndex + itemsPerPage).clamp(0, totalBreeds);
      final paginatedBreeds = allBreeds.sublist(
        startIndex.clamp(0, totalBreeds),
        endIndex,
      );

      print('📄 Breeds Pagination: page $validPage/$totalPages, showing ${paginatedBreeds.length}/$totalBreeds breeds');

      return {
        'breeds': paginatedBreeds,
        'totalBreeds': totalBreeds,
        'totalPages': totalPages,
        'currentPage': validPage,
      };
    } catch (e) {
      print('❌ Error fetching paginated breeds: $e');
      return {
        'breeds': <PetBreed>[],
        'totalBreeds': 0,
        'totalPages': 0,
        'currentPage': 1,
      };
    }
  }

  /// Sort breeds based on sort option
  static List<PetBreed> _sortBreeds(List<PetBreed> breeds, String sortBy) {
    switch (sortBy) {
      case 'name_asc':
        breeds.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case 'name_desc':
        breeds.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
      case 'species':
        breeds.sort((a, b) {
          final speciesCompare = a.species.compareTo(b.species);
          if (speciesCompare != 0) return speciesCompare;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
        break;
      case 'date_added':
        breeds.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      default:
        breeds.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }
    return breeds;
  }

  /// Get a single breed by ID
  static Future<PetBreed?> fetchBreedById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists) {
        return PetBreed.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('❌ Error fetching breed by ID: $e');
      return null;
    }
  }

  /// Create a new breed
  static Future<String?> createBreed(PetBreed breed) async {
    try {
      print('➕ Creating new breed: ${breed.name}');

      // Check for duplicate name
      final isDuplicate = await _checkDuplicateName(breed.name);
      if (isDuplicate) {
        throw Exception('A breed with this name already exists');
      }

      // Create document
      final docRef = await _firestore.collection(_collection).add(breed.toJson());
      print('✅ Breed created with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Error creating breed: $e');
      rethrow;
    }
  }

  /// Update an existing breed
  static Future<bool> updateBreed(String id, PetBreed breed) async {
    try {
      print('🔄 Updating breed: $id');

      // Check for duplicate name (exclude current breed)
      final isDuplicate = await _checkDuplicateName(breed.name, excludeId: id);
      if (isDuplicate) {
        throw Exception('A breed with this name already exists');
      }

      // Update document
      final updateData = breed.toJson();
      updateData['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore.collection(_collection).doc(id).update(updateData);
      print('✅ Breed updated successfully');
      return true;
    } catch (e) {
      print('❌ Error updating breed: $e');
      rethrow;
    }
  }

  /// Delete a breed
  static Future<bool> deleteBreed(String id) async {
    try {
      print('🗑️ Deleting breed: $id');
      await _firestore.collection(_collection).doc(id).delete();
      print('✅ Breed deleted successfully');
      return true;
    } catch (e) {
      print('❌ Error deleting breed: $e');
      return false;
    }
  }

  /// Toggle breed status (active/inactive)
  static Future<bool> toggleBreedStatus(String id, bool isActive) async {
    try {
      print('🔄 Toggling breed status: $id to ${isActive ? 'active' : 'inactive'}');
      await _firestore.collection(_collection).doc(id).update({
        'status': isActive ? 'active' : 'inactive',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ Breed status updated');
      return true;
    } catch (e) {
      print('❌ Error toggling breed status: $e');
      return false;
    }
  }

  /// Check if a breed name already exists
  static Future<bool> _checkDuplicateName(String name, {String? excludeId}) async {
    try {
      Query query = _firestore.collection(_collection);
      
      // Case-insensitive search
      final snapshot = await query.get();
      final nameLower = name.toLowerCase().trim();
      
      for (var doc in snapshot.docs) {
        if (doc.id == excludeId) continue; // Skip current breed when updating
        
        final data = doc.data() as Map<String, dynamic>;
        final existingName = (data['name'] as String? ?? '').toLowerCase().trim();
        
        if (existingName == nameLower) {
          return true;
        }
      }
      
      return false;
    } catch (e) {
      print('❌ Error checking duplicate name: $e');
      return false;
    }
  }

  /// Get breed statistics for dashboard cards
  static Future<Map<String, int>> getBreedStatistics() async {
    try {
      print('📊 Fetching breed statistics...');
      
      final snapshot = await _firestore.collection(_collection).get();
      
      int total = snapshot.docs.length;
      int catBreeds = 0;
      int dogBreeds = 0;
      int recentlyAdded = 0;
      
      final thirtyDaysAgo = DateTime.now().subtract(Duration(days: 30));
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final species = data['species'] as String?;
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
        
        if (species == 'cat') {
          catBreeds++;
        } else if (species == 'dog') {
          dogBreeds++;
        }
        
        if (createdAt != null && createdAt.isAfter(thirtyDaysAgo)) {
          recentlyAdded++;
        }
      }
      
      print('📊 Statistics: total=$total, cats=$catBreeds, dogs=$dogBreeds, recent=$recentlyAdded');
      
      return {
        'total': total,
        'catBreeds': catBreeds,
        'dogBreeds': dogBreeds,
        'recentlyAdded': recentlyAdded,
      };
    } catch (e) {
      print('❌ Error fetching statistics: $e');
      return {
        'total': 0,
        'catBreeds': 0,
        'dogBreeds': 0,
        'recentlyAdded': 0,
      };
    }
  }

  /// Search breeds by name or description
  static Future<List<PetBreed>> searchBreeds(String query) async {
    try {
      if (query.isEmpty) {
        return await fetchAllBreeds();
      }

      print('🔍 Searching breeds: $query');
      final snapshot = await _firestore.collection(_collection).get();
      
      final queryLower = query.toLowerCase();
      final results = snapshot.docs
          .map((doc) => PetBreed.fromFirestore(doc))
          .where((breed) {
            return breed.name.toLowerCase().contains(queryLower);
          })
          .toList();
      
      print('✅ Found ${results.length} matching breeds');
      return results;
    } catch (e) {
      print('❌ Error searching breeds: $e');
      return [];
    }
  }

  /// Validate breed data before save
  static String? validateBreed(PetBreed breed) {
    if (breed.name.isEmpty || breed.name.length < 2) {
      return 'Breed name must be at least 2 characters';
    }

    if (breed.name.length > 50) {
      return 'Breed name must be less than 50 characters';
    }

    if (breed.species.isEmpty) {
      return 'Species is required';
    }

    if (breed.species != 'cat' && breed.species != 'dog') {
      return 'Species must be either cat or dog';
    }

    return null; // No errors
  }

  /// Get real-time stream of breeds
  static Stream<List<PetBreed>> getBreedsStream() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PetBreed.fromFirestore(doc))
            .toList());
  }

  /// Batch delete multiple breeds
  static Future<bool> batchDeleteBreeds(List<String> ids) async {
    try {
      print('🗑️ Batch deleting ${ids.length} breeds');
      
      final batch = _firestore.batch();
      for (final id in ids) {
        batch.delete(_firestore.collection(_collection).doc(id));
      }
      
      await batch.commit();
      print('✅ Batch delete completed');
      return true;
    } catch (e) {
      print('❌ Error batch deleting breeds: $e');
      return false;
    }
  }
}
