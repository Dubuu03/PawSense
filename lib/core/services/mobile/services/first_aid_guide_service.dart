import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawsense/core/models/services/first_aid_guide_model.dart';

class FirstAidGuideService {
  static const String _collection = 'first_aid_guides';
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get all active first aid guides ordered by priority
  static Future<List<FirstAidGuideModel>> getActiveGuides() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .orderBy('priority', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => FirstAidGuideModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting active guides: $e');
      return [];
    }
  }

  /// Get all first aid guides (for admin management)
  static Future<List<FirstAidGuideModel>> getAllGuides() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .orderBy('priority', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => FirstAidGuideModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting all guides: $e');
      return [];
    }
  }

  /// Get guides by category
  static Future<List<FirstAidGuideModel>> getGuidesByCategory(String category) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('category', isEqualTo: category)
          .where('isActive', isEqualTo: true)
          .orderBy('priority', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => FirstAidGuideModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting guides by category: $e');
      return [];
    }
  }

  /// Get guides by urgency level
  static Future<List<FirstAidGuideModel>> getGuidesByUrgency(String urgencyLevel) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('urgencyLevel', isEqualTo: urgencyLevel)
          .where('isActive', isEqualTo: true)
          .orderBy('priority', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => FirstAidGuideModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting guides by urgency: $e');
      return [];
    }
  }

  /// Search guides by title or tags
  static Future<List<FirstAidGuideModel>> searchGuides(String searchTerm) async {
    try {
      final allGuides = await getActiveGuides();
      final searchLower = searchTerm.toLowerCase();
      
      return allGuides.where((guide) =>
          guide.title.toLowerCase().contains(searchLower) ||
          guide.description.toLowerCase().contains(searchLower) ||
          guide.category.toLowerCase().contains(searchLower) ||
          guide.tags.any((tag) => tag.toLowerCase().contains(searchLower))
      ).toList();
    } catch (e) {
      print('Error searching guides: $e');
      return [];
    }
  }

  /// Get a specific guide by ID
  static Future<FirstAidGuideModel?> getGuideById(String guideId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(guideId).get();
      
      if (doc.exists && doc.data() != null) {
        return FirstAidGuideModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting guide by ID: $e');
      return null;
    }
  }

  /// Add a new first aid guide
  static Future<String?> addGuide(FirstAidGuideModel guide) async {
    try {
      final docRef = await _firestore.collection(_collection).add(guide.toMap());
      return docRef.id;
    } catch (e) {
      print('Error adding guide: $e');
      return null;
    }
  }

  /// Update an existing guide
  static Future<bool> updateGuide(FirstAidGuideModel guide) async {
    try {
      if (guide.id == null) return false;
      
      final updatedGuide = guide.copyWith(updatedAt: DateTime.now());
      await _firestore
          .collection(_collection)
          .doc(guide.id)
          .update(updatedGuide.toMap());
      
      return true;
    } catch (e) {
      print('Error updating guide: $e');
      return false;
    }
  }

  /// Delete a guide
  static Future<bool> deleteGuide(String guideId) async {
    try {
      await _firestore.collection(_collection).doc(guideId).delete();
      return true;
    } catch (e) {
      print('Error deleting guide: $e');
      return false;
    }
  }

  /// Toggle guide active status
  static Future<bool> toggleGuideStatus(String guideId, bool isActive) async {
    try {
      await _firestore.collection(_collection).doc(guideId).update({
        'isActive': isActive,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      return true;
    } catch (e) {
      print('Error toggling guide status: $e');
      return false;
    }
  }

  /// Get available categories
  static Future<List<String>> getCategories() async {
    try {
      final guides = await getActiveGuides();
      final categories = guides.map((guide) => guide.category).toSet().toList();
      categories.sort();
      return categories;
    } catch (e) {
      print('Error getting categories: $e');
      return [];
    }
  }

  /// Initialize default first aid guides if none exist
  static Future<void> initializeDefaultGuides() async {
    try {
      final existingGuides = await getAllGuides();
      if (existingGuides.isNotEmpty) return;

      final defaultGuides = [
        FirstAidGuideModel(
          title: 'Pet Choking Emergency',
          category: 'Breathing',
          description: 'What to do when your pet is choking',
          urgencyLevel: 'Critical',
          steps: [
            FirstAidStep(
              stepNumber: '1',
              title: 'Stay Calm',
              description: 'Keep yourself calm to think clearly and act quickly.',
              isImportant: true,
            ),
            FirstAidStep(
              stepNumber: '2',
              title: 'Open the Mouth',
              description: 'Gently open your pet\'s mouth and look for visible objects.',
            ),
            FirstAidStep(
              stepNumber: '3',
              title: 'Remove Object',
              description: 'If you can see the object, try to remove it with tweezers or pliers.',
            ),
            FirstAidStep(
              stepNumber: '4',
              title: 'Heimlich Maneuver',
              description: 'For larger dogs, perform the Heimlich maneuver by lifting the hind legs.',
              isImportant: true,
            ),
          ],
          warnings: [
            'Never reach into the mouth blindly',
            'Don\'t use your fingers to remove objects',
            'Be careful not to push the object further down',
          ],
          whenToCallVet: [
            'If you cannot remove the object',
            'After successfully removing the object (for check-up)',
            'If your pet loses consciousness',
          ],
          tags: ['choking', 'emergency', 'breathing', 'airway'],
          priority: 10,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        FirstAidGuideModel(
          title: 'Wound Care Basics',
          category: 'Injury',
          description: 'How to treat minor cuts and wounds',
          urgencyLevel: 'Medium',
          steps: [
            FirstAidStep(
              stepNumber: '1',
              title: 'Clean Your Hands',
              description: 'Wash your hands thoroughly before treating the wound.',
            ),
            FirstAidStep(
              stepNumber: '2',
              title: 'Stop the Bleeding',
              description: 'Apply gentle pressure with a clean cloth or gauze.',
            ),
            FirstAidStep(
              stepNumber: '3',
              title: 'Clean the Wound',
              description: 'Rinse with clean water or saline solution.',
            ),
            FirstAidStep(
              stepNumber: '4',
              title: 'Apply Bandage',
              description: 'Cover with a sterile bandage, not too tight.',
            ),
          ],
          warnings: [
            'Don\'t use hydrogen peroxide on deep wounds',
            'Avoid tight bandaging that cuts off circulation',
          ],
          whenToCallVet: [
            'If the wound is deep or gaping',
            'If bleeding doesn\'t stop after 10 minutes',
            'Signs of infection appear',
          ],
          tags: ['wound', 'bleeding', 'injury', 'bandage'],
          priority: 8,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      for (final guide in defaultGuides) {
        await addGuide(guide);
      }
    } catch (e) {
      print('Error initializing default guides: $e');
    }
  }
}