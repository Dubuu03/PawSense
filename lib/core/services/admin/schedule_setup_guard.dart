import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/clinic/clinic_model.dart';

class ScheduleSetupGuard {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Check if the current admin needs to set up their clinic schedule
  static Future<ScheduleSetupStatus> checkScheduleSetupStatus([String? clinicId]) async {
    try {
      print('🔍 ScheduleSetupGuard: Checking setup status for clinic: ${clinicId ?? 'current user'}');
      
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ ScheduleSetupGuard: No authenticated user found');
        return ScheduleSetupStatus(
          needsSetup: false,
          inProgress: false,
          clinic: null,
          message: 'User not authenticated',
        );
      }

      DocumentSnapshot clinicDoc;
      
      if (clinicId != null) {
        // Get specific clinic by ID
        print('🔍 ScheduleSetupGuard: Fetching clinic by ID: $clinicId');
        clinicDoc = await _firestore.collection('clinics').doc(clinicId).get();
        if (!clinicDoc.exists) {
          print('❌ ScheduleSetupGuard: Clinic not found with ID: $clinicId');
          return ScheduleSetupStatus(
            needsSetup: false,
            inProgress: false,
            clinic: null,
            message: 'Clinic not found',
          );
        }
      } else {
        // Get clinic data for current user
        print('🔍 ScheduleSetupGuard: Fetching clinic for user: ${user.uid}');
        final clinicQuery = await _firestore
            .collection('clinics')
            .where('userId', isEqualTo: user.uid)
            .limit(1)
            .get();

        if (clinicQuery.docs.isEmpty) {
          print('❌ ScheduleSetupGuard: No clinic found for user: ${user.uid}');
          return ScheduleSetupStatus(
            needsSetup: false,
            inProgress: false,
            clinic: null,
            message: 'No clinic found for user',
          );
        }
        clinicDoc = clinicQuery.docs.first;
      }

      final clinicData = clinicDoc.data() as Map<String, dynamic>;
      final clinic = Clinic.fromMap({
        'id': clinicDoc.id,
        ...clinicData,
      });

      // Check clinic approval status first
      final approvalStatus = clinic.status;
      if (approvalStatus != 'approved') {
        print('❌ ScheduleSetupGuard: Clinic not approved yet (status: $approvalStatus)');
        return ScheduleSetupStatus(
          needsSetup: false,
          inProgress: false,
          clinic: clinic,
          message: 'Clinic not yet approved by admin',
        );
      }

      // Check schedule status
      final scheduleStatus = clinic.scheduleStatus;
      final isInProgress = scheduleStatus == 'in_progress';
      final needsSetup = scheduleStatus == 'pending' || isInProgress;
      
      print('📊 ScheduleSetupGuard: Status analysis:');
      print('   - Approval Status: $approvalStatus');
      print('   - Schedule Status: $scheduleStatus');
      print('   - Needs Setup: $needsSetup');
      print('   - In Progress: $isInProgress');
      print('   - Is Visible: ${clinic.isVisible}');

      if (needsSetup) {
        return ScheduleSetupStatus(
          needsSetup: true,
          inProgress: isInProgress,
          clinic: clinic,
          message: isInProgress 
              ? 'Schedule setup is in progress'
              : 'Schedule setup required before clinic can be visible to users',
        );
      }

      print('✅ ScheduleSetupGuard: Setup completed, clinic is ready');
      return ScheduleSetupStatus(
        needsSetup: false,
        inProgress: false,
        clinic: clinic,
        message: 'Schedule setup completed',
      );
    } catch (e) {
      print('❌ ScheduleSetupGuard: Error checking setup status: $e');
      // Return a safe default that won't break the flow
      return ScheduleSetupStatus(
        needsSetup: true, // Default to requiring setup on error to be safe
        inProgress: false,
        clinic: null,
        message: 'Error checking setup status: $e',
      );
    }
  }

  /// Mark schedule setup as in progress
  static Future<bool> markScheduleSetupInProgress(String clinicId) async {
    try {
      print('🔄 ScheduleSetupGuard: Marking schedule setup as in progress for clinic: $clinicId');
      
      await _firestore.collection('clinics').doc(clinicId).update({
        'scheduleStatus': 'in_progress',
        'updatedAt': Timestamp.now(),
      });
      
      print('✅ ScheduleSetupGuard: Setup marked as in progress');
      return true;
    } catch (e) {
      print('❌ ScheduleSetupGuard: Error marking schedule setup in progress: $e');
      return false;
    }
  }

  /// Complete schedule setup process
  static Future<bool> completeScheduleSetup(String clinicId) async {
    try {
      print('✅ ScheduleSetupGuard: Completing schedule setup for clinic: $clinicId');
      
      // Verify clinic exists and is in the right state
      final clinicDoc = await _firestore.collection('clinics').doc(clinicId).get();
      if (!clinicDoc.exists) {
        print('❌ ScheduleSetupGuard: Clinic not found: $clinicId');
        return false;
      }
      
      final clinicData = clinicDoc.data() as Map<String, dynamic>;
      final currentStatus = clinicData['status'] as String?;
      final currentScheduleStatus = clinicData['scheduleStatus'] as String?;
      
      // Only allow completion if clinic is approved
      if (currentStatus != 'approved') {
        print('❌ ScheduleSetupGuard: Cannot complete setup - clinic not approved (status: $currentStatus)');
        return false;
      }
      
      // Update schedule completion
      await _firestore.collection('clinics').doc(clinicId).update({
        'scheduleStatus': 'completed',
        'isVisible': true,
        'scheduleCompletedAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
      
      print('✅ ScheduleSetupGuard: Schedule setup completed successfully');
      print('   - Previous schedule status: $currentScheduleStatus');
      print('   - New schedule status: completed');
      print('   - Clinic is now visible to users');
      
      return true;
    } catch (e) {
      print('❌ ScheduleSetupGuard: Error completing schedule setup: $e');
      return false;
    }
  }

  /// Reset schedule setup (for testing or admin purposes)
  static Future<bool> resetScheduleSetup(String clinicId) async {
    try {
      await _firestore.collection('clinics').doc(clinicId).update({
        'scheduleStatus': 'pending',
        'isVisible': false,
        'scheduleCompletedAt': null,
      });
      return true;
    } catch (e) {
      print('Error resetting schedule setup: $e');
      return false;
    }
  }
}

class ScheduleSetupStatus {
  final bool needsSetup;
  final bool inProgress;
  final Clinic? clinic;
  final String message;

  ScheduleSetupStatus({
    required this.needsSetup,
    this.inProgress = false,
    required this.clinic,
    required this.message,
  });

  @override
  String toString() {
    return 'ScheduleSetupStatus(needsSetup: $needsSetup, inProgress: $inProgress, clinic: ${clinic?.clinicName}, message: $message)';
  }
}