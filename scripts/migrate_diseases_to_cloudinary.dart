// Migration Script for Existing Disease Images to Cloudinary
// Run this script to migrate all existing local asset images to Cloudinary

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawsense/core/services/cloudinary/cloudinary_service.dart';

/// This script migrates existing disease images from local assets to Cloudinary
/// 
/// Prerequisites:
/// 1. Ensure CLOUDINARY_CLOUD_NAME and CLOUDINARY_UPLOAD_PRESET are set in .env
/// 2. Ensure all image files exist in assets/img/skin_diseases/ directory
/// 3. Backup Firestore database before running
/// 
/// Usage:
/// Run this from a terminal or as a one-time migration function
class DiseaseMigrationScript {
  final CloudinaryService _cloudinary = CloudinaryService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Main migration function
  Future<void> migrateAllDiseasesToCloudinary() async {
    print('🚀 Starting disease image migration to Cloudinary...\n');
    
    try {
      // Fetch all diseases
      final snapshot = await _firestore.collection('skinDiseases').get();
      print('📋 Found ${snapshot.docs.length} diseases to process\n');
      
      int successCount = 0;
      int skipCount = 0;
      int errorCount = 0;
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final diseaseId = doc.id;
        final diseaseName = data['name'] ?? 'Unknown';
        final imageUrl = data['imageUrl'] ?? '';
        
        print('Processing: $diseaseName (ID: $diseaseId)');
        
        // Skip if already a network URL
        if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
          print('  ⏭️  Already using network URL, skipping...\n');
          skipCount++;
          continue;
        }
        
        // Skip if no image
        if (imageUrl.isEmpty) {
          print('  ⏭️  No image set, skipping...\n');
          skipCount++;
          continue;
        }
        
        try {
          // Construct local file path
          final localPath = 'assets/img/skin_diseases/$imageUrl';
          final file = File(localPath);
          
          if (!await file.exists()) {
            print('  ⚠️  File not found: $localPath\n');
            errorCount++;
            continue;
          }
          
          // Upload to Cloudinary
          print('  ⬆️  Uploading to Cloudinary...');
          final cloudinaryUrl = await _cloudinary.uploadImageFromFile(
            localPath,
            folder: 'skin_diseases',
          );
          
          // Update Firestore
          await _firestore.collection('skinDiseases').doc(diseaseId).update({
            'imageUrl': cloudinaryUrl,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          
          print('  ✅ Successfully migrated!');
          print('  📸 New URL: $cloudinaryUrl\n');
          successCount++;
          
          // Add delay to avoid rate limiting
          await Future.delayed(Duration(seconds: 1));
          
        } catch (e) {
          print('  ❌ Error: $e\n');
          errorCount++;
        }
      }
      
      // Print summary
      print('═' * 60);
      print('Migration Complete!');
      print('═' * 60);
      print('✅ Success: $successCount');
      print('⏭️  Skipped: $skipCount');
      print('❌ Errors: $errorCount');
      print('📊 Total: ${snapshot.docs.length}');
      print('═' * 60);
      
    } catch (e) {
      print('❌ Fatal error during migration: $e');
      rethrow;
    }
  }
  
  /// Migrate a single disease by ID (for testing)
  Future<void> migrateSingleDisease(String diseaseId) async {
    print('🚀 Migrating single disease: $diseaseId\n');
    
    try {
      final doc = await _firestore.collection('skinDiseases').doc(diseaseId).get();
      
      if (!doc.exists) {
        print('❌ Disease not found!');
        return;
      }
      
      final data = doc.data()!;
      final diseaseName = data['name'] ?? 'Unknown';
      final imageUrl = data['imageUrl'] ?? '';
      
      print('Disease: $diseaseName');
      print('Current imageUrl: $imageUrl\n');
      
      if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
        print('⏭️  Already using network URL!');
        return;
      }
      
      if (imageUrl.isEmpty) {
        print('⏭️  No image set!');
        return;
      }
      
      final localPath = 'assets/img/skin_diseases/$imageUrl';
      final file = File(localPath);
      
      if (!await file.exists()) {
        print('❌ File not found: $localPath');
        return;
      }
      
      print('⬆️  Uploading to Cloudinary...');
      final cloudinaryUrl = await _cloudinary.uploadImageFromFile(
        localPath,
        folder: 'skin_diseases',
      );
      
      await _firestore.collection('skinDiseases').doc(diseaseId).update({
        'imageUrl': cloudinaryUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ Successfully migrated!');
      print('📸 New URL: $cloudinaryUrl');
      
    } catch (e) {
      print('❌ Error: $e');
      rethrow;
    }
  }
  
  /// Verify migration - check all diseases have Cloudinary URLs
  Future<void> verifyMigration() async {
    print('🔍 Verifying migration...\n');
    
    final snapshot = await _firestore.collection('skinDiseases').get();
    
    int cloudinaryCount = 0;
    int localCount = 0;
    int emptyCount = 0;
    
    List<String> needsMigration = [];
    
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final imageUrl = data['imageUrl'] ?? '';
      final diseaseName = data['name'] ?? 'Unknown';
      
      if (imageUrl.isEmpty) {
        emptyCount++;
      } else if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
        cloudinaryCount++;
      } else {
        localCount++;
        needsMigration.add('$diseaseName (ID: ${doc.id})');
      }
    }
    
    print('═' * 60);
    print('Migration Status');
    print('═' * 60);
    print('☁️  Cloudinary URLs: $cloudinaryCount');
    print('📁 Local assets: $localCount');
    print('🔳 No image: $emptyCount');
    print('📊 Total: ${snapshot.docs.length}');
    print('═' * 60);
    
    if (needsMigration.isNotEmpty) {
      print('\n⚠️  Diseases still using local assets:');
      for (final disease in needsMigration) {
        print('  • $disease');
      }
    } else {
      print('\n✅ All diseases have been migrated to Cloudinary!');
    }
  }
  
  /// Rollback migration - restore local asset references
  /// WARNING: Only use if Cloudinary migration failed
  Future<void> rollbackMigration(Map<String, String> backup) async {
    print('⚠️  Rolling back migration...\n');
    
    for (final entry in backup.entries) {
      try {
        await _firestore.collection('skinDiseases').doc(entry.key).update({
          'imageUrl': entry.value,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print('✅ Rolled back: ${entry.key}');
      } catch (e) {
        print('❌ Failed to rollback ${entry.key}: $e');
      }
    }
    
    print('\n✅ Rollback complete!');
  }
  
  /// Create backup of current imageUrls before migration
  Future<Map<String, String>> createBackup() async {
    print('💾 Creating backup of current imageUrls...\n');
    
    final snapshot = await _firestore.collection('skinDiseases').get();
    final backup = <String, String>{};
    
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final imageUrl = data['imageUrl'] ?? '';
      backup[doc.id] = imageUrl;
    }
    
    print('✅ Backup created for ${backup.length} diseases\n');
    return backup;
  }
}

/// Example usage:
/// 
/// ```dart
/// void main() async {
///   // Initialize Firebase
///   await Firebase.initializeApp();
///   
///   final migration = DiseaseMigrationScript();
///   
///   // Create backup first
///   final backup = await migration.createBackup();
///   
///   // Run migration
///   await migration.migrateAllDiseasesToCloudinary();
///   
///   // Verify results
///   await migration.verifyMigration();
/// }
/// ```
