import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawsense/core/models/breeds/pet_breed_model.dart';

/// Script to prepopulate the database with common cat and dog breeds
/// Run this once during initial setup or when you need to reset breed data
class BreedSeeder {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'petBreeds';

  /// List of common dog breeds
  static final List<Map<String, String>> _dogBreeds = [
    {'name': 'Labrador Retriever'},
    {'name': 'Golden Retriever'},
    {'name': 'German Shepherd'},
    {'name': 'French Bulldog'},
    {'name': 'Bulldog'},
    {'name': 'Poodle'},
    {'name': 'Beagle'},
    {'name': 'Rottweiler'},
    {'name': 'Yorkshire Terrier'},
    {'name': 'Dachshund'},
    {'name': 'Siberian Husky'},
    {'name': 'Boxer'},
    {'name': 'Border Collie'},
    {'name': 'Australian Shepherd'},
    {'name': 'Shih Tzu'},
    {'name': 'Boston Terrier'},
    {'name': 'Pomeranian'},
    {'name': 'Chihuahua'},
    {'name': 'Maltese'},
    {'name': 'Havanese'},
    {'name': 'Cavalier King Charles Spaniel'},
    {'name': 'Bernese Mountain Dog'},
    {'name': 'Weimaraner'},
    {'name': 'Collie'},
    {'name': 'Basset Hound'},
    {'name': 'Newfoundland'},
    {'name': 'Saint Bernard'},
    {'name': 'Bloodhound'},
    {'name': 'Vizsla'},
    {'name': 'Whippet'},
    {'name': 'Greyhound'},
    {'name': 'Dalmatian'},
    {'name': 'Great Dane'},
    {'name': 'Doberman Pinscher'},
    {'name': 'Cocker Spaniel'},
    {'name': 'Mastiff'},
    {'name': 'Cane Corso'},
    {'name': 'Akita'},
    {'name': 'Shiba Inu'},
    {'name': 'Chow Chow'},
    {'name': 'Great Pyrenees'},
    {'name': 'Miniature Schnauzer'},
    {'name': 'Jack Russell Terrier'},
    {'name': 'Scottish Terrier'},
    {'name': 'West Highland White Terrier'},
    {'name': 'Bull Terrier'},
    {'name': 'American Staffordshire Terrier'},
    {'name': 'Australian Cattle Dog'},
    {'name': 'Brittany'},
    {'name': 'Irish Setter'},
    {'name': 'Mixed Breed'},
    {'name': 'Unknown'},
  ];

  /// List of common cat breeds
  static final List<Map<String, String>> _catBreeds = [
    {'name': 'Persian'},
    {'name': 'Maine Coon'},
    {'name': 'Ragdoll'},
    {'name': 'British Shorthair'},
    {'name': 'Siamese'},
    {'name': 'Abyssinian'},
    {'name': 'Birman'},
    {'name': 'Oriental Shorthair'},
    {'name': 'Sphynx'},
    {'name': 'Devon Rex'},
    {'name': 'Cornish Rex'},
    {'name': 'Scottish Fold'},
    {'name': 'American Shorthair'},
    {'name': 'Russian Blue'},
    {'name': 'Manx'},
    {'name': 'Norwegian Forest Cat'},
    {'name': 'Siberian'},
    {'name': 'Turkish Angora'},
    {'name': 'Burmese'},
    {'name': 'Tonkinese'},
    {'name': 'Balinese'},
    {'name': 'Javanese'},
    {'name': 'Himalayan'},
    {'name': 'Exotic Shorthair'},
    {'name': 'Bombay'},
    {'name': 'Chartreux'},
    {'name': 'Egyptian Mau'},
    {'name': 'Ocicat'},
    {'name': 'Bengal'},
    {'name': 'Savannah'},
    {'name': 'Munchkin'},
    {'name': 'Singapura'},
    {'name': 'Somali'},
    {'name': 'Turkish Van'},
    {'name': 'Ragamuffin'},
    {'name': 'Nebelung'},
    {'name': 'American Bobtail'},
    {'name': 'Japanese Bobtail'},
    {'name': 'American Curl'},
    {'name': 'Selkirk Rex'},
    {'name': 'LaPerm'},
    {'name': 'Korat'},
    {'name': 'Pixie-Bob'},
    {'name': 'Highlander'},
    {'name': 'Chausie'},
    {'name': 'Toyger'},
    {'name': 'Domestic Shorthair'},
    {'name': 'Domestic Longhair'},
    {'name': 'Mixed Breed'},
    {'name': 'Unknown'},
  ];

  /// Seed all breeds into the database
  /// Set [clearExisting] to true to delete all existing breeds first
  static Future<Map<String, dynamic>> seedBreeds({
    bool clearExisting = false,
    String createdBy = 'system',
  }) async {
    print('🌱 Starting breed seeding process...');
    
    try {
      int dogsAdded = 0;
      int catsAdded = 0;
      int dogsSkipped = 0;
      int catsSkipped = 0;
      
      // Clear existing breeds if requested
      if (clearExisting) {
        print('🗑️ Clearing existing breeds...');
        final snapshot = await _firestore.collection(_collection).get();
        final batch = _firestore.batch();
        for (var doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
        print('✅ Cleared ${snapshot.docs.length} existing breeds');
      }

      // Seed dog breeds
      print('🐶 Adding dog breeds...');
      for (final breedData in _dogBreeds) {
        final result = await _addBreedIfNotExists(
          name: breedData['name']!,
          species: 'dog',
          createdBy: createdBy,
        );
        
        if (result) {
          dogsAdded++;
        } else {
          dogsSkipped++;
        }
      }

      // Seed cat breeds
      print('🐱 Adding cat breeds...');
      for (final breedData in _catBreeds) {
        final result = await _addBreedIfNotExists(
          name: breedData['name']!,
          species: 'cat',
          createdBy: createdBy,
        );
        
        if (result) {
          catsAdded++;
        } else {
          catsSkipped++;
        }
      }

      print('✅ Breed seeding complete!');
      print('   Dogs added: $dogsAdded');
      print('   Dogs skipped (already exist): $dogsSkipped');
      print('   Cats added: $catsAdded');
      print('   Cats skipped (already exist): $catsSkipped');
      print('   Total breeds: ${dogsAdded + catsAdded}');

      return {
        'success': true,
        'dogsAdded': dogsAdded,
        'catsAdded': catsAdded,
        'dogsSkipped': dogsSkipped,
        'catsSkipped': catsSkipped,
        'totalAdded': dogsAdded + catsAdded,
      };
    } catch (e) {
      print('❌ Error seeding breeds: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Add a breed only if it doesn't already exist
  static Future<bool> _addBreedIfNotExists({
    required String name,
    required String species,
    required String createdBy,
  }) async {
    try {
      // Check if breed already exists
      final snapshot = await _firestore
          .collection(_collection)
          .where('name', isEqualTo: name)
          .where('species', isEqualTo: species)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        print('   ⏭️  Skipping $name ($species) - already exists');
        return false;
      }

      // Create the breed
      final now = DateTime.now();
      final breed = PetBreed(
        id: '', // Firestore will generate
        name: name,
        species: species,
        status: 'active',
        createdAt: now,
        updatedAt: now,
        createdBy: createdBy,
      );

      await _firestore.collection(_collection).add(breed.toJson());
      print('   ✅ Added $name ($species)');
      return true;
    } catch (e) {
      print('   ❌ Failed to add $name ($species): $e');
      return false;
    }
  }

  /// Seed only dog breeds
  static Future<Map<String, dynamic>> seedDogBreeds({
    bool clearExisting = false,
    String createdBy = 'system',
  }) async {
    print('🌱 Starting dog breed seeding...');
    
    try {
      int added = 0;
      int skipped = 0;

      if (clearExisting) {
        print('🗑️ Clearing existing dog breeds...');
        final snapshot = await _firestore
            .collection(_collection)
            .where('species', isEqualTo: 'dog')
            .get();
        final batch = _firestore.batch();
        for (var doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
        print('✅ Cleared ${snapshot.docs.length} existing dog breeds');
      }

      for (final breedData in _dogBreeds) {
        final result = await _addBreedIfNotExists(
          name: breedData['name']!,
          species: 'dog',
          createdBy: createdBy,
        );
        
        if (result) {
          added++;
        } else {
          skipped++;
        }
      }

      print('✅ Dog breed seeding complete!');
      print('   Added: $added');
      print('   Skipped: $skipped');

      return {
        'success': true,
        'added': added,
        'skipped': skipped,
      };
    } catch (e) {
      print('❌ Error seeding dog breeds: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Seed only cat breeds
  static Future<Map<String, dynamic>> seedCatBreeds({
    bool clearExisting = false,
    String createdBy = 'system',
  }) async {
    print('🌱 Starting cat breed seeding...');
    
    try {
      int added = 0;
      int skipped = 0;

      if (clearExisting) {
        print('🗑️ Clearing existing cat breeds...');
        final snapshot = await _firestore
            .collection(_collection)
            .where('species', isEqualTo: 'cat')
            .get();
        final batch = _firestore.batch();
        for (var doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
        print('✅ Cleared ${snapshot.docs.length} existing cat breeds');
      }

      for (final breedData in _catBreeds) {
        final result = await _addBreedIfNotExists(
          name: breedData['name']!,
          species: 'cat',
          createdBy: createdBy,
        );
        
        if (result) {
          added++;
        } else {
          skipped++;
        }
      }

      print('✅ Cat breed seeding complete!');
      print('   Added: $added');
      print('   Skipped: $skipped');

      return {
        'success': true,
        'added': added,
        'skipped': skipped,
      };
    } catch (e) {
      print('❌ Error seeding cat breeds: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Get count of existing breeds
  static Future<Map<String, int>> getBreedCounts() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();
      
      int totalBreeds = snapshot.docs.length;
      int dogBreeds = 0;
      int catBreeds = 0;
      int activeBreeds = 0;
      int inactiveBreeds = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final species = data['species'] as String?;
        final status = data['status'] as String?;

        if (species == 'dog') dogBreeds++;
        if (species == 'cat') catBreeds++;
        if (status == 'active') activeBreeds++;
        if (status == 'inactive') inactiveBreeds++;
      }

      return {
        'total': totalBreeds,
        'dogs': dogBreeds,
        'cats': catBreeds,
        'active': activeBreeds,
        'inactive': inactiveBreeds,
      };
    } catch (e) {
      print('❌ Error getting breed counts: $e');
      return {};
    }
  }
}
