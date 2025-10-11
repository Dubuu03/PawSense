import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/clinic/clinic_model.dart';

class ScheduleSetupGuard {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Check if the current admin needs to set up their clinic schedule
  static Future<ScheduleSetupStatus> checkScheduleSetupStatus([String? clinicId]) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
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
        clinicDoc = await _firestore.collection('clinics').doc(clinicId).get();
        if (!clinicDoc.exists) {
          return ScheduleSetupStatus(
            needsSetup: false,
            inProgress: false,
            clinic: null,
            message: 'Clinic not found',
          );
        }
      } else {
        // Get clinic data for current user
        final clinicQuery = await _firestore
            .collection('clinics')
            .where('userId', isEqualTo: user.uid)
            .limit(1)
            .get();

        if (clinicQuery.docs.isEmpty) {
          return ScheduleSetupStatus(
            needsSetup: false,
            inProgress: false,
            clinic: null,
            message: 'No clinic found for user',
          );
        }
        clinicDoc = clinicQuery.docs.first;
      }

      final clinic = Clinic.fromMap({
        'id': clinicDoc.id,
        ...clinicDoc.data() as Map<String, dynamic>,
      });

      // Check schedule status
      final scheduleStatus = clinic.scheduleStatus;
      final isInProgress = scheduleStatus == 'in_progress';
      final needsSetup = scheduleStatus == 'pending' || isInProgress;

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

      return ScheduleSetupStatus(
        needsSetup: false,
        inProgress: false,
        clinic: clinic,
        message: 'Schedule setup completed',
      );
    } catch (e) {
      print('Error checking schedule setup status: $e');
      return ScheduleSetupStatus(
        needsSetup: false,
        inProgress: false,
        clinic: null,
        message: 'Error checking setup status: $e',
      );
    }
  }

  /// Mark schedule setup as in progress
  static Future<bool> markScheduleSetupInProgress(String clinicId) async {
    try {
      await _firestore.collection('clinics').doc(clinicId).update({
        'scheduleStatus': 'in_progress',
      });
      return true;
    } catch (e) {
      print('Error marking schedule setup in progress: $e');
      return false;
    }
  }

  /// Complete schedule setup process
  static Future<bool> completeScheduleSetup(String clinicId) async {
    try {
      await _firestore.collection('clinics').doc(clinicId).update({
        'scheduleStatus': 'completed',
        'isVisible': true,
        'scheduleCompletedAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      print('Error completing schedule setup: $e');
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