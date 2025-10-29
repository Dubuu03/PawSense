import 'package:cloud_firestore/cloud_firestore.dart';

/// Script to seed predefined specializations to Firestore
/// Run this once to populate the predefinedSpecializations collection
Future<void> seedPredefinedSpecializations() async {
  final firestore = FirebaseFirestore.instance;
  final collection = firestore.collection('predefinedSpecializations');

  print('🌱 Starting to seed predefined specializations...');

  final specializations = [
    {
      'name': 'Small Animal Medicine',
      'description': 'Specialized in treating small animals like cats, dogs, and pocket pets',
      'isActive': true,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    },
    {
      'name': 'Large Animal Medicine',
      'description': 'Specialized in treating large animals like horses, cattle, and livestock',
      'isActive': true,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    },
    {
      'name': 'Emergency and Critical Care',
      'description': 'Specialized in emergency medical care and critical patient management',
      'isActive': true,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    },
    {
      'name': 'Surgery',
      'description': 'Specialized in veterinary surgical procedures',
      'isActive': true,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    },
    {
      'name': 'Dermatology',
      'description': 'Specialized in skin diseases and disorders in animals',
      'isActive': true,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    },
    {
      'name': 'Cardiology',
      'description': 'Specialized in heart and cardiovascular diseases',
      'isActive': true,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    },
    {
      'name': 'Neurology',
      'description': 'Specialized in nervous system diseases and disorders',
      'isActive': true,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    },
    {
      'name': 'Oncology',
      'description': 'Specialized in cancer diagnosis and treatment',
      'isActive': true,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    },
    {
      'name': 'Ophthalmology',
      'description': 'Specialized in eye diseases and vision care',
      'isActive': true,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    },
    {
      'name': 'Dentistry',
      'description': 'Specialized in dental care and oral health',
      'isActive': true,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    },
    {
      'name': 'Internal Medicine',
      'description': 'Specialized in complex internal medical conditions',
      'isActive': true,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    },
    {
      'name': 'Anesthesiology',
      'description': 'Specialized in anesthesia and pain management',
      'isActive': true,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    },
    {
      'name': 'Radiology',
      'description': 'Specialized in diagnostic imaging and radiological procedures',
      'isActive': true,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    },
    {
      'name': 'Pathology',
      'description': 'Specialized in laboratory diagnosis and disease investigation',
      'isActive': true,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    },
    {
      'name': 'Exotic Animal Medicine',
      'description': 'Specialized in treating exotic and non-traditional pets',
      'isActive': true,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    },
  ];

  int successCount = 0;
  int skipCount = 0;

  for (final spec in specializations) {
    try {
      // Check if already exists
      final existing = await collection
          .where('name', isEqualTo: spec['name'])
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        print('⏭️  Skipping "${spec['name']}" - already exists');
        skipCount++;
        continue;
      }

      // Add new specialization
      await collection.add(spec);
      print('✅ Added "${spec['name']}"');
      successCount++;
    } catch (e) {
      print('❌ Error adding "${spec['name']}": $e');
    }
  }

  print('\n✨ Seeding complete!');
  print('   Added: $successCount');
  print('   Skipped: $skipCount');
  print('   Total: ${specializations.length}');
}

// Run this function manually or call it from your app's initialization
void main() async {
  // Note: You need to initialize Firebase before running this
  // This is typically done in your app's main() function
  await seedPredefinedSpecializations();
}
