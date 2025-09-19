import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawsense/core/models/services/emergency_hotline_model.dart';

class EmergencyHotlineService {
  static const String _collection = 'emergency_hotlines';
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get all active emergency hotlines ordered by priority
  static Future<List<EmergencyHotlineModel>> getActiveHotlines() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .orderBy('priority', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => EmergencyHotlineModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting active hotlines: $e');
      return [];
    }
  }

  /// Get all emergency hotlines (for admin management)
  static Future<List<EmergencyHotlineModel>> getAllHotlines() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .orderBy('priority', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => EmergencyHotlineModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting all hotlines: $e');
      return [];
    }
  }

  /// Get hotlines by emergency type
  static Future<List<EmergencyHotlineModel>> getHotlinesByType(String emergencyType) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('emergencyType', isEqualTo: emergencyType)
          .where('isActive', isEqualTo: true)
          .orderBy('priority', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => EmergencyHotlineModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting hotlines by type: $e');
      return [];
    }
  }

  /// Get a specific hotline by ID
  static Future<EmergencyHotlineModel?> getHotlineById(String hotlineId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(hotlineId).get();
      
      if (doc.exists && doc.data() != null) {
        return EmergencyHotlineModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting hotline by ID: $e');
      return null;
    }
  }

  /// Add a new emergency hotline
  static Future<String?> addHotline(EmergencyHotlineModel hotline) async {
    try {
      final docRef = await _firestore.collection(_collection).add(hotline.toMap());
      return docRef.id;
    } catch (e) {
      print('Error adding hotline: $e');
      return null;
    }
  }

  /// Update an existing hotline
  static Future<bool> updateHotline(EmergencyHotlineModel hotline) async {
    try {
      if (hotline.id == null) return false;
      
      final updatedHotline = hotline.copyWith(updatedAt: DateTime.now());
      await _firestore
          .collection(_collection)
          .doc(hotline.id)
          .update(updatedHotline.toMap());
      
      return true;
    } catch (e) {
      print('Error updating hotline: $e');
      return false;
    }
  }

  /// Delete a hotline
  static Future<bool> deleteHotline(String hotlineId) async {
    try {
      await _firestore.collection(_collection).doc(hotlineId).delete();
      return true;
    } catch (e) {
      print('Error deleting hotline: $e');
      return false;
    }
  }

  /// Toggle hotline active status
  static Future<bool> toggleHotlineStatus(String hotlineId, bool isActive) async {
    try {
      await _firestore.collection(_collection).doc(hotlineId).update({
        'isActive': isActive,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      return true;
    } catch (e) {
      print('Error toggling hotline status: $e');
      return false;
    }
  }

  /// Initialize default emergency hotlines if none exist
  static Future<void> initializeDefaultHotlines() async {
    try {
      final existingHotlines = await getAllHotlines();
      if (existingHotlines.isNotEmpty) return;

      final defaultHotlines = [
        EmergencyHotlineModel(
          title: 'Pet Emergency Hotline',
          description: '24/7 emergency veterinary assistance and guidance',
          phoneNumber: '+1-800-PET-HELP',
          emergencyType: 'General',
          isAvailable24_7: true,
          operatingHours: ['24/7'],
          website: 'https://petemergency.com',
          email: 'emergency@petemergency.com',
          priority: 10,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        EmergencyHotlineModel(
          title: 'Animal Poison Control',
          description: 'Immediate assistance for pet poisoning cases',
          phoneNumber: '+1-800-POISON-1',
          emergencyType: 'Poisoning',
          isAvailable24_7: true,
          operatingHours: ['24/7'],
          priority: 9,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        EmergencyHotlineModel(
          title: 'Local Emergency Vet',
          description: 'Your nearest emergency veterinary clinic',
          phoneNumber: '+1-555-VET-911',
          emergencyType: 'Medical',
          isAvailable24_7: false,
          operatingHours: ['Mon-Fri: 6PM-8AM', 'Weekends: 24/7'],
          priority: 8,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      for (final hotline in defaultHotlines) {
        await addHotline(hotline);
      }
    } catch (e) {
      print('Error initializing default hotlines: $e');
    }
  }
}