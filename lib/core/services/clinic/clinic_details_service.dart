import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawsense/core/guards/auth_guard.dart';
import 'package:pawsense/core/models/clinic/clinic_details_model.dart';

/// Service for managing clinic details and settings
class ClinicDetailsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Stream clinic details by clinic ID for real-time updates
  static Stream<ClinicDetails?> streamClinicDetails(String clinicId) {
    return _firestore
        .collection('clinicDetails')
        .where('clinicId', isEqualTo: clinicId)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        try {
          final rawData = snapshot.docs.first.data();
          return ClinicDetails.fromMap(rawData);
        } catch (e) {
          print('Error parsing clinic details stream: $e');
          return null;
        }
      }
      return null;
    });
  }
  
  /// Get clinic details by user ID (clinic ID)
  static Future<ClinicDetails?> getClinicDetails(String clinicId) async {
    try {
      final query = await _firestore
          .collection('clinicDetails')
          .where('clinicId', isEqualTo: clinicId)
          .limit(1)
          .get();
          
      if (query.docs.isNotEmpty) {
        final rawData = query.docs.first.data();
        print('DEBUG: Raw clinic details data type: ${rawData.runtimeType}');
        print('DEBUG: Raw clinic details keys: ${rawData.keys}');
        
        // Print each field individually to find the problematic one
        rawData.forEach((key, value) {
          print('DEBUG: Field "$key": ${value.runtimeType} = $value');
        });
        
        return ClinicDetails.fromMap(rawData);
      }
      return null;
    } catch (e, stackTrace) {
      print('Error getting clinic details: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }
  
  /// Create clinic details document if it doesn't exist
  static Future<bool> createClinicDetailsDocument(String clinicId) async {
    try {
      // Get clinic data first
      final clinicDoc = await _firestore.collection('clinics').doc(clinicId).get();
      if (!clinicDoc.exists) {
        print('DEBUG: Clinic document not found');
        return false;
      }
      
      final clinicData = clinicDoc.data()!;
      
      // Create clinic details document
      final clinicDetailsId = 'clinic_details_$clinicId';
      await _firestore.collection('clinicDetails').doc(clinicDetailsId).set({
        'id': clinicDetailsId,
        'clinicId': clinicId,
        'clinicName': clinicData['clinicName'] ?? 'Unknown Clinic',
        'description': 'Veterinary clinic providing quality care',
        'address': clinicData['address'] ?? '',
        'phone': clinicData['phone'] ?? '',
        'email': clinicData['email'] ?? '',
        'operatingHours': 'Mon-Fri: 8AM-6PM',
        'specializations': [],
        'services': [],
        'certifications': [],
        'isVerified': false,
        'isActive': true,
        'createdAt': DateTime.now().toIso8601String(),
      });
      
      print('DEBUG: Created clinic details document: $clinicDetailsId');
      return true;
    } catch (e) {
      print('DEBUG: Error creating clinic details document: $e');
      return false;
    }
  }
  
  /// Update clinic details settings
  static Future<bool> updateClinicDetails({
    String? operatingHours,
    String? description,
    bool? autoApproveAppointments,
    String? defaultDuration,
    String? bufferTime,
    String? advanceBooking,
    bool? isVerified,
    bool? isActive,
  }) async {
    try {
      final currentUser = await AuthGuard.getCurrentUser();
      if (currentUser == null) return false;
      
      final query = await _firestore
          .collection('clinicDetails')
          .where('clinicId', isEqualTo: currentUser.uid)
          .limit(1)
          .get();
      
      if (query.docs.isNotEmpty) {
        final updateData = <String, dynamic>{
          'updatedAt': DateTime.now().toIso8601String(),
        };
        
        if (operatingHours != null) updateData['operatingHours'] = operatingHours;
        if (description != null) updateData['description'] = description;
        if (autoApproveAppointments != null) updateData['autoApproveAppointments'] = autoApproveAppointments;
        if (defaultDuration != null) updateData['defaultDuration'] = defaultDuration;
        if (bufferTime != null) updateData['bufferTime'] = bufferTime;
        if (advanceBooking != null) updateData['advanceBooking'] = advanceBooking;
        if (isVerified != null) updateData['isVerified'] = isVerified;
        if (isActive != null) updateData['isActive'] = isActive;
        
        await query.docs.first.reference.update(updateData);
        return true;
      } else {
        // Create clinic details document if it doesn't exist
        final success = await createClinicDetailsDocument(currentUser.uid);
        if (success) {
          // Retry the update
          return await updateClinicDetails(
            operatingHours: operatingHours,
            description: description,
            autoApproveAppointments: autoApproveAppointments,
            defaultDuration: defaultDuration,
            bufferTime: bufferTime,
            advanceBooking: advanceBooking,
            isVerified: isVerified,
            isActive: isActive,
          );
        }
      }
      
      return false;
    } catch (e) {
      print('Error updating clinic details: $e');
      return false;
    }
  }
  
  /// Get clinic details for current user
  static Future<ClinicDetails?> getCurrentUserClinicDetails() async {
    try {
      final currentUser = await AuthGuard.getCurrentUser();
      if (currentUser == null) return null;
      
      return await getClinicDetails(currentUser.uid);
    } catch (e) {
      print('Error getting current user clinic details: $e');
      return null;
    }
  }
  
  /// Check if clinic details document exists
  static Future<bool> clinicDetailsExists(String clinicId) async {
    try {
      final query = await _firestore
          .collection('clinicDetails')
          .where('clinicId', isEqualTo: clinicId)
          .limit(1)
          .get();
      
      return query.docs.isNotEmpty;
    } catch (e) {
      print('Error checking if clinic details exists: $e');
      return false;
    }
  }
}
