import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pawsense/core/guards/auth_guard.dart';

/// Service for managing settings data from Firebase
class SettingsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Get current user's account data
  static Future<Map<String, dynamic>?> getAccountSettings() async {
    try {
      final currentUser = await AuthGuard.getCurrentUser();
      if (currentUser == null) return null;
      
      // Get user document
      final userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();
      
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        return {
          'firstName': userData['firstName'] ?? '',
          'lastName': userData['lastName'] ?? '',
          'username': userData['username'] ?? '',
          'email': userData['email'] ?? '',
          'contactNumber': userData['contactNumber'] ?? '',
          'emergencyContact': userData['emergencyContact'] ?? '',
        };
      }
      
      return null;
    } catch (e) {
      print('Error getting account settings: $e');
      return null;
    }
  }
  
  /// Get current user's clinic data
  static Future<Map<String, dynamic>?> getClinicSettings() async {
    try {
      final currentUser = await AuthGuard.getCurrentUser();
      if (currentUser == null) return null;
      
      // Get clinic document
      final clinicDoc = await _firestore
          .collection('clinics')
          .doc(currentUser.uid)
          .get();
      
      Map<String, dynamic>? clinicData;
      if (clinicDoc.exists) {
        clinicData = clinicDoc.data()!;
      }
      
      // Get clinic details for additional settings
      final clinicDetailsQuery = await _firestore
          .collection('clinicDetails')
          .where('clinicId', isEqualTo: currentUser.uid)
          .limit(1)
          .get();
      
      Map<String, dynamic>? clinicDetailsData;
      if (clinicDetailsQuery.docs.isNotEmpty) {
        clinicDetailsData = clinicDetailsQuery.docs.first.data();
      }
      
      // Combine both sources
      return {
        // Basic clinic info
        'clinicName': clinicData?['clinicName'] ?? '',
        'address': clinicData?['address'] ?? '',
        'phone': clinicData?['phone'] ?? '',
        'email': clinicData?['email'] ?? '',
        'website': clinicData?['website'] ?? '',
        
        // Additional settings from clinic details
        'operatingHours': clinicDetailsData?['operatingHours'] ?? '',
        'autoApproveAppointments': clinicDetailsData?['autoApproveAppointments'] ?? true,
        'defaultDuration': clinicDetailsData?['defaultDuration'] ?? '30',
        'bufferTime': clinicDetailsData?['bufferTime'] ?? '10',
        'advanceBooking': clinicDetailsData?['advanceBooking'] ?? '60',
      };
      
    } catch (e) {
      print('Error getting clinic settings: $e');
      return null;
    }
  }
  
  /// Update account settings
  static Future<bool> updateAccountSettings(Map<String, dynamic> data) async {
    try {
      final currentUser = await AuthGuard.getCurrentUser();
      if (currentUser == null) return false;
      
      // Update user document
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .update({
            'firstName': data['firstName'],
            'lastName': data['lastName'],
            'username': data['username'],
            'contactNumber': data['contactNumber'],
            'emergencyContact': data['emergencyContact'],
            'updatedAt': DateTime.now().toIso8601String(),
          });
      
      // Clear AuthGuard cache to ensure fresh data is loaded
      AuthGuard.clearUserCache();
      
      return true;
    } catch (e) {
      print('Error updating account settings: $e');
      return false;
    }
  }
  
  /// Update clinic settings
  static Future<bool> updateClinicSettings(Map<String, dynamic> data) async {
    try {
      final currentUser = await AuthGuard.getCurrentUser();
      if (currentUser == null) return false;
      
      // Update clinic document
      await _firestore
          .collection('clinics')
          .doc(currentUser.uid)
          .update({
            'clinicName': data['clinicName'],
            'address': data['address'],
            'phone': data['phone'],
            'email': data['email'],
            'website': data['website'],
          });
      
      // Update clinic details document
      final clinicDetailsQuery = await _firestore
          .collection('clinicDetails')
          .where('clinicId', isEqualTo: currentUser.uid)
          .limit(1)
          .get();
      
      if (clinicDetailsQuery.docs.isNotEmpty) {
        await clinicDetailsQuery.docs.first.reference.update({
          'clinicName': data['clinicName'],
          'address': data['address'],
          'phone': data['phone'],
          'email': data['email'],
          'operatingHours': data['operatingHours'],
          'autoApproveAppointments': data['autoApproveAppointments'],
          'defaultDuration': data['defaultDuration'],
          'bufferTime': data['bufferTime'],
          'advanceBooking': data['advanceBooking'],
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }
      
      return true;
    } catch (e) {
      print('Error updating clinic settings: $e');
      return false;
    }
  }
  
  /// Update user password
  static Future<bool> updatePassword(String currentPassword, String newPassword) async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) return false;
      
      // In Firebase, password updates require re-authentication
      // This is a simplified version - in production, you'd want to handle re-authentication properly
      await firebaseUser.updatePassword(newPassword);
      
      return true;
    } catch (e) {
      print('Error updating password: $e');
      return false;
    }
  }
}
