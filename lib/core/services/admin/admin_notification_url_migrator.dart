import 'package:cloud_firestore/cloud_firestore.dart';

/// Migration service to update old appointment notifications with proper action URLs
class AdminNotificationUrlMigrator {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Migrate all appointment notifications to include appointmentId in actionUrl
  static Future<void> migrateAppointmentNotifications(String clinicId) async {
    print('🔄 Starting migration of appointment notification URLs for clinic: $clinicId');
    
    try {
      // Find all appointment notifications with old URL format
      final query = await _firestore
          .collection('admin_notifications')
          .where('clinicId', isEqualTo: clinicId)
          .where('type', isEqualTo: 'appointment')
          .get();
      
      print('📊 Found ${query.docs.length} appointment notifications');
      
      final batch = _firestore.batch();
      int updateCount = 0;
      int skippedCount = 0;
      
      for (final doc in query.docs) {
        final data = doc.data();
        final currentActionUrl = data['actionUrl'] as String?;
        final relatedId = data['relatedId'] as String?; // This is the appointmentId
        
        // Check if URL needs updating
        if (relatedId != null && currentActionUrl != null) {
          // If URL doesn't contain appointmentId parameter, update it
          if (!currentActionUrl.contains('appointmentId=')) {
            final newActionUrl = '/admin/appointments?appointmentId=$relatedId';
            
            batch.update(doc.reference, {
              'actionUrl': newActionUrl,
              'migratedAt': FieldValue.serverTimestamp(),
            });
            
            updateCount++;
            print('✅ Updated: ${doc.id} → $newActionUrl');
          } else {
            skippedCount++;
          }
        }
      }
      
      if (updateCount > 0) {
        await batch.commit();
        print('✅ Migration complete: Updated $updateCount notifications, skipped $skippedCount');
      } else {
        print('✅ No notifications needed updating (skipped $skippedCount)');
      }
      
    } catch (e) {
      print('❌ Error during migration: $e');
      rethrow;
    }
  }
  
  /// Migrate a single notification
  static Future<void> migrateSingleNotification(String notificationId) async {
    try {
      final doc = await _firestore
          .collection('admin_notifications')
          .doc(notificationId)
          .get();
      
      if (!doc.exists) {
        print('❌ Notification not found: $notificationId');
        return;
      }
      
      final data = doc.data()!;
      final currentActionUrl = data['actionUrl'] as String?;
      final relatedId = data['relatedId'] as String?;
      
      if (relatedId != null && currentActionUrl != null && !currentActionUrl.contains('appointmentId=')) {
        final newActionUrl = '/admin/appointments?appointmentId=$relatedId';
        
        await doc.reference.update({
          'actionUrl': newActionUrl,
          'migratedAt': FieldValue.serverTimestamp(),
        });
        
        print('✅ Updated notification: $notificationId → $newActionUrl');
      } else {
        print('⏭️ Notification already has correct URL or missing data');
      }
      
    } catch (e) {
      print('❌ Error migrating notification: $e');
      rethrow;
    }
  }
}
