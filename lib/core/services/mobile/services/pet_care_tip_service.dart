import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawsense/core/models/services/pet_care_tip_model.dart';

class PetCareTipService {
  static const String _collection = 'pet_care_tips';
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get all active pet care tips ordered by featured status and creation date
  static Future<List<PetCareTipModel>> getActiveTips() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .orderBy('isFeatured', descending: true)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => PetCareTipModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting active tips: $e');
      return [];
    }
  }

  /// Get all pet care tips (for admin management)
  static Future<List<PetCareTipModel>> getAllTips() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => PetCareTipModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting all tips: $e');
      return [];
    }
  }

  /// Get featured tips
  static Future<List<PetCareTipModel>> getFeaturedTips() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('isFeatured', isEqualTo: true)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => PetCareTipModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting featured tips: $e');
      return [];
    }
  }

  /// Get tips by category
  static Future<List<PetCareTipModel>> getTipsByCategory(String category) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('category', isEqualTo: category)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => PetCareTipModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting tips by category: $e');
      return [];
    }
  }

  /// Get tips by pet type
  static Future<List<PetCareTipModel>> getTipsByPetType(String petType) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('petType', whereIn: [petType, 'All'])
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => PetCareTipModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting tips by pet type: $e');
      return [];
    }
  }

  /// Get tips by age group
  static Future<List<PetCareTipModel>> getTipsByAgeGroup(String ageGroup) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('ageGroup', whereIn: [ageGroup, 'All'])
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => PetCareTipModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting tips by age group: $e');
      return [];
    }
  }

  /// Search tips by title, description, or tags
  static Future<List<PetCareTipModel>> searchTips(String searchTerm) async {
    try {
      final allTips = await getActiveTips();
      final searchLower = searchTerm.toLowerCase();
      
      return allTips.where((tip) =>
          tip.title.toLowerCase().contains(searchLower) ||
          tip.description.toLowerCase().contains(searchLower) ||
          tip.content.toLowerCase().contains(searchLower) ||
          tip.category.toLowerCase().contains(searchLower) ||
          tip.tags.any((tag) => tag.toLowerCase().contains(searchLower))
      ).toList();
    } catch (e) {
      print('Error searching tips: $e');
      return [];
    }
  }

  /// Get a specific tip by ID
  static Future<PetCareTipModel?> getTipById(String tipId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(tipId).get();
      
      if (doc.exists && doc.data() != null) {
        return PetCareTipModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting tip by ID: $e');
      return null;
    }
  }

  /// Add a new pet care tip
  static Future<String?> addTip(PetCareTipModel tip) async {
    try {
      final docRef = await _firestore.collection(_collection).add(tip.toMap());
      return docRef.id;
    } catch (e) {
      print('Error adding tip: $e');
      return null;
    }
  }

  /// Update an existing tip
  static Future<bool> updateTip(PetCareTipModel tip) async {
    try {
      if (tip.id == null) return false;
      
      final updatedTip = tip.copyWith(updatedAt: DateTime.now());
      await _firestore
          .collection(_collection)
          .doc(tip.id)
          .update(updatedTip.toMap());
      
      return true;
    } catch (e) {
      print('Error updating tip: $e');
      return false;
    }
  }

  /// Delete a tip
  static Future<bool> deleteTip(String tipId) async {
    try {
      await _firestore.collection(_collection).doc(tipId).delete();
      return true;
    } catch (e) {
      print('Error deleting tip: $e');
      return false;
    }
  }

  /// Toggle tip active status
  static Future<bool> toggleTipStatus(String tipId, bool isActive) async {
    try {
      await _firestore.collection(_collection).doc(tipId).update({
        'isActive': isActive,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      return true;
    } catch (e) {
      print('Error toggling tip status: $e');
      return false;
    }
  }

  /// Toggle tip featured status
  static Future<bool> toggleFeaturedStatus(String tipId, bool isFeatured) async {
    try {
      await _firestore.collection(_collection).doc(tipId).update({
        'isFeatured': isFeatured,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      return true;
    } catch (e) {
      print('Error toggling featured status: $e');
      return false;
    }
  }

  /// Increment tip views
  static Future<bool> incrementViews(String tipId) async {
    try {
      await _firestore.collection(_collection).doc(tipId).update({
        'views': FieldValue.increment(1),
      });
      return true;
    } catch (e) {
      print('Error incrementing views: $e');
      return false;
    }
  }

  /// Increment tip likes
  static Future<bool> incrementLikes(String tipId) async {
    try {
      await _firestore.collection(_collection).doc(tipId).update({
        'likes': FieldValue.increment(1),
      });
      return true;
    } catch (e) {
      print('Error incrementing likes: $e');
      return false;
    }
  }

  /// Get available categories
  static Future<List<String>> getCategories() async {
    try {
      final tips = await getActiveTips();
      final categories = tips.map((tip) => tip.category).toSet().toList();
      categories.sort();
      return categories;
    } catch (e) {
      print('Error getting categories: $e');
      return [];
    }
  }

  /// Initialize default pet care tips if none exist
  static Future<void> initializeDefaultTips() async {
    try {
      final existingTips = await getAllTips();
      if (existingTips.isNotEmpty) return;

      final defaultTips = [
        PetCareTipModel(
          title: 'Daily Grooming Routine',
          category: 'Grooming',
          description: 'Essential daily grooming practices for a healthy pet',
          content: '''
# Daily Grooming Routine

Maintaining a daily grooming routine is essential for your pet's health and wellbeing.

## For Dogs:
- **Brushing**: Brush daily to prevent matting and reduce shedding
- **Teeth**: Clean teeth or provide dental chews
- **Ears**: Check for dirt, wax, or signs of infection
- **Eyes**: Wipe away any discharge with a damp cloth

## For Cats:
- **Brushing**: Long-haired cats need daily brushing, short-haired weekly
- **Nail trimming**: Trim nails every 2-3 weeks
- **Dental care**: Provide dental treats or toys

## Benefits:
- Reduces shedding and hairballs
- Prevents skin issues
- Strengthens bond with your pet
- Early detection of health problems
          ''',
          petType: 'All',
          ageGroup: 'All',
          difficulty: 'Beginner',
          tags: ['grooming', 'daily care', 'health', 'hygiene'],
          estimatedReadTime: 3,
          isFeatured: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        PetCareTipModel(
          title: 'Puppy Training Basics',
          category: 'Training',
          description: 'Fundamental training techniques for new puppies',
          content: '''
# Puppy Training Basics

Starting training early is key to raising a well-behaved dog.

## House Training:
- Take puppy outside frequently (every 2-3 hours)
- Reward immediately after successful potty breaks
- Watch for signs like sniffing or circling
- Be patient and consistent

## Basic Commands:
1. **Sit**: Hold treat above head, say "sit", reward when they sit
2. **Stay**: Start with short durations, gradually increase
3. **Come**: Practice in safe, enclosed areas first
4. **Down**: Lower treat to ground, say "down"

## Socialization:
- Expose to different people, animals, and environments
- Keep experiences positive
- Start early (8-16 weeks is critical period)

## Remember:
- Keep training sessions short (5-10 minutes)
- Always end on a positive note
- Consistency is key
          ''',
          petType: 'Dog',
          ageGroup: 'Puppy',
          difficulty: 'Beginner',
          tags: ['training', 'puppy', 'behavior', 'socialization'],
          estimatedReadTime: 5,
          isFeatured: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        PetCareTipModel(
          title: 'Healthy Pet Nutrition',
          category: 'Nutrition',
          description: 'Guidelines for feeding your pet a balanced diet',
          content: '''
# Healthy Pet Nutrition

Proper nutrition is the foundation of your pet's health.

## Choosing the Right Food:
- Look for AAFCO (Association of American Feed Control Officials) certification
- Consider your pet's age, size, and activity level
- Choose high-quality protein as the first ingredient
- Avoid foods with excessive fillers

## Feeding Guidelines:
- **Puppies/Kittens**: 3-4 meals per day
- **Adult pets**: 2 meals per day
- **Senior pets**: May need special diets, consult vet

## Foods to Avoid:
- Chocolate, grapes, onions, garlic
- Xylitol (artificial sweetener)
- Cooked bones
- High-fat foods

## Hydration:
- Always provide fresh, clean water
- Monitor water intake changes
- Consider wet food for additional hydration

## Treats:
- Should not exceed 10% of daily calories
- Use for training and bonding
- Choose healthy, species-appropriate options
          ''',
          petType: 'All',
          ageGroup: 'All',
          difficulty: 'Beginner',
          tags: ['nutrition', 'diet', 'feeding', 'health'],
          estimatedReadTime: 4,
          isFeatured: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      for (final tip in defaultTips) {
        await addTip(tip);
      }
    } catch (e) {
      print('Error initializing default tips: $e');
    }
  }
}