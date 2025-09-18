import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawsense/core/models/user/pet_model.dart';

class PetService {
  static const String _collection = 'pets';
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Add a new pet to Firestore
  static Future<String?> addPet(Pet pet) async {
    try {
      final docRef = await _firestore.collection(_collection).add(pet.toMap());
      return docRef.id;
    } catch (e) {
      print('Error adding pet: $e');
      return null;
    }
  }

  /// Get all pets for a specific user
  static Future<List<Pet>> getUserPets(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .get();

      final pets = querySnapshot.docs
          .map((doc) => Pet.fromMap(doc.data(), doc.id))
          .toList();

      // Sort by createdAt in descending order (most recent first)
      pets.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return pets;
    } catch (e) {
      print('Error getting user pets: $e');
      return [];
    }
  }

  /// Get a specific pet by ID
  static Future<Pet?> getPetById(String petId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(petId).get();
      
      if (doc.exists && doc.data() != null) {
        return Pet.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting pet by ID: $e');
      return null;
    }
  }

  /// Update an existing pet
  static Future<bool> updatePet(Pet pet) async {
    try {
      if (pet.id == null) return false;
      
      final updatedPet = pet.copyWith(updatedAt: DateTime.now());
      await _firestore
          .collection(_collection)
          .doc(pet.id)
          .update(updatedPet.toMap());
      
      return true;
    } catch (e) {
      print('Error updating pet: $e');
      return false;
    }
  }

  /// Delete a pet
  static Future<bool> deletePet(String petId) async {
    try {
      await _firestore.collection(_collection).doc(petId).delete();
      return true;
    } catch (e) {
      print('Error deleting pet: $e');
      return false;
    }
  }

  /// Stream of user's pets for real-time updates
  static Stream<List<Pet>> getUserPetsStream(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final pets = snapshot.docs
              .map((doc) => Pet.fromMap(doc.data(), doc.id))
              .toList();
          
          // Sort by createdAt in descending order (most recent first)
          pets.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          
          return pets;
        });
  }

  /// Get pets count for a user
  static Future<int> getUserPetsCount(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .get();
      
      return querySnapshot.docs.length;
    } catch (e) {
      print('Error getting pets count: $e');
      return 0;
    }
  }

  /// Search pets by name or breed
  static Future<List<Pet>> searchUserPets(String userId, String searchTerm) async {
    try {
      final pets = await getUserPets(userId);
      final searchLower = searchTerm.toLowerCase();
      
      return pets.where((pet) =>
          pet.petName.toLowerCase().contains(searchLower) ||
          pet.breed.toLowerCase().contains(searchLower) ||
          pet.petType.toLowerCase().contains(searchLower)
      ).toList();
    } catch (e) {
      print('Error searching pets: $e');
      return [];
    }
  }

  /// Get pets by type for a user
  static Future<List<Pet>> getUserPetsByType(String userId, String petType) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('petType', isEqualTo: petType)
          .get();

      final pets = querySnapshot.docs
          .map((doc) => Pet.fromMap(doc.data(), doc.id))
          .toList();

      // Sort by createdAt in descending order (most recent first)
      pets.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return pets;
    } catch (e) {
      print('Error getting pets by type: $e');
      return [];
    }
  }
}
