import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// Script to clean up analysis complete notifications
/// Run this once to remove all existing "Analysis Complete" notifications
Future<void> main() async {
  try {
    // Initialize Firebase
    await Firebase.initializeApp();
    
    final firestore = FirebaseFirestore.instance;
    
    print('🧹 Starting cleanup of Analysis Complete notifications...');
    
    // Query for notifications with title "Analysis Complete"
    final querySnapshot = await firestore
        .collection('notifications')
        .where('title', isEqualTo: 'Analysis Complete')
        .get();
    
    print('📊 Found ${querySnapshot.docs.length} Analysis Complete notifications to delete');
    
    // Delete in batches
    final batch = firestore.batch();
    int count = 0;
    
    for (final doc in querySnapshot.docs) {
      batch.delete(doc.reference);
      count++;
      
      // Commit batch every 500 operations (Firestore limit)
      if (count % 500 == 0) {
        await batch.commit();
        print('✅ Deleted $count notifications...');
      }
    }
    
    // Commit remaining operations
    if (count % 500 != 0) {
      await batch.commit();
    }
    
    print('🎉 Successfully deleted $count Analysis Complete notifications');
    
    // Also clean up any assessment category notifications
    final assessmentQuery = await firestore
        .collection('notifications')
        .where('category', isEqualTo: 'assessment')
        .get();
    
    if (assessmentQuery.docs.isNotEmpty) {
      print('📊 Found ${assessmentQuery.docs.length} assessment category notifications to delete');
      
      final assessmentBatch = firestore.batch();
      for (final doc in assessmentQuery.docs) {
        assessmentBatch.delete(doc.reference);
      }
      
      await assessmentBatch.commit();
      print('🎉 Successfully deleted ${assessmentQuery.docs.length} assessment category notifications');
    }
    
    print('✅ Cleanup completed successfully!');
    
  } catch (e) {
    print('❌ Error during cleanup: $e');
  }
}