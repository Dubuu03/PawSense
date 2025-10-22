import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for managing predefined specializations
/// These are the specializations that admins can choose from when adding their own
class PredefinedSpecializationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'predefinedSpecializations';

  /// Get all predefined specializations
  static Future<List<Map<String, dynamic>>> getAllSpecializations() async {
    try {
      final query = await _firestore
          .collection(_collection)
          .orderBy('name')
          .get();

      return query.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      print('Error getting predefined specializations: $e');
      return [];
    }
  }

  /// Get active predefined specializations only
  static Future<List<Map<String, dynamic>>> getActiveSpecializations() async {
    try {
      final query = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();

      return query.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      print('Error getting active predefined specializations: $e');
      return [];
    }
  }

  /// Stream all predefined specializations
  static Stream<List<Map<String, dynamic>>> streamSpecializations() {
    return _firestore
        .collection(_collection)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {
          'id': doc.id,
          ...doc.data(),
        }).toList());
  }

  /// Add a new predefined specialization
  static Future<bool> addSpecialization({
    required String name,
    String? description,
    bool isActive = true,
  }) async {
    try {
      // Check if specialization already exists
      final existing = await _firestore
          .collection(_collection)
          .where('name', isEqualTo: name)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        print('Specialization already exists: $name');
        return false;
      }

      await _firestore.collection(_collection).add({
        'name': name,
        'description': description,
        'isActive': isActive,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error adding predefined specialization: $e');
      return false;
    }
  }

  /// Update a predefined specialization
  static Future<bool> updateSpecialization({
    required String id,
    String? name,
    String? description,
    bool? isActive,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) updates['name'] = name;
      if (description != null) updates['description'] = description;
      if (isActive != null) updates['isActive'] = isActive;

      await _firestore.collection(_collection).doc(id).update(updates);
      return true;
    } catch (e) {
      print('Error updating predefined specialization: $e');
      return false;
    }
  }

  /// Delete a predefined specialization
  static Future<bool> deleteSpecialization(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
      return true;
    } catch (e) {
      print('Error deleting predefined specialization: $e');
      return false;
    }
  }

  /// Toggle active status of a specialization
  static Future<bool> toggleActive(String id, bool isActive) async {
    try {
      await _firestore.collection(_collection).doc(id).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error toggling specialization status: $e');
      return false;
    }
  }

  /// Seed default specializations (call this once during setup)
  static Future<void> seedDefaultSpecializations() async {
    final defaultSpecializations = [
      {
        'name': 'Small Animal Medicine',
        'description': 'Specialized in treating small animals like cats, dogs, and pocket pets',
        'isActive': true,
      },
      {
        'name': 'Large Animal Medicine',
        'description': 'Specialized in treating large animals like horses, cattle, and livestock',
        'isActive': true,
      },
      {
        'name': 'Emergency and Critical Care',
        'description': 'Specialized in emergency medical care and critical patient management',
        'isActive': true,
      },
      {
        'name': 'Surgery',
        'description': 'Specialized in veterinary surgical procedures',
        'isActive': true,
      },
      {
        'name': 'Dermatology',
        'description': 'Specialized in skin diseases and disorders in animals',
        'isActive': true,
      },
      {
        'name': 'Cardiology',
        'description': 'Specialized in heart and cardiovascular diseases',
        'isActive': true,
      },
      {
        'name': 'Neurology',
        'description': 'Specialized in nervous system diseases and disorders',
        'isActive': true,
      },
      {
        'name': 'Oncology',
        'description': 'Specialized in cancer diagnosis and treatment',
        'isActive': true,
      },
      {
        'name': 'Ophthalmology',
        'description': 'Specialized in eye diseases and vision care',
        'isActive': true,
      },
      {
        'name': 'Dentistry',
        'description': 'Specialized in dental care and oral health',
        'isActive': true,
      },
      {
        'name': 'Internal Medicine',
        'description': 'Specialized in complex internal medical conditions',
        'isActive': true,
      },
      {
        'name': 'Anesthesiology',
        'description': 'Specialized in anesthesia and pain management',
        'isActive': true,
      },
      {
        'name': 'Radiology',
        'description': 'Specialized in diagnostic imaging and radiological procedures',
        'isActive': true,
      },
      {
        'name': 'Pathology',
        'description': 'Specialized in laboratory diagnosis and disease investigation',
        'isActive': true,
      },
      {
        'name': 'Exotic Animal Medicine',
        'description': 'Specialized in treating exotic and non-traditional pets',
        'isActive': true,
      },
    ];

    for (final spec in defaultSpecializations) {
      await addSpecialization(
        name: spec['name'] as String,
        description: spec['description'] as String?,
        isActive: spec['isActive'] as bool,
      );
    }

    print('✅ Successfully seeded ${defaultSpecializations.length} default specializations');
  }
}
