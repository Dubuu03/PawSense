import 'package:cloud_firestore/cloud_firestore.dart';
import '../../guards/auth_guard.dart';
import '../clinic/clinic_details_service.dart';

/// Service for managing vet specializations
class SpecializationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Get raw specializations data with full details from Firestore
  static Future<List<dynamic>> getRawSpecializationsData(String clinicId) async {
    print('DEBUG SpecializationService: getRawSpecializationsData called for clinicId: $clinicId');
    try {
      final query = await _firestore
          .collection('clinicDetails')
          .where('clinicId', isEqualTo: clinicId)
          .limit(1)
          .get();

      print('DEBUG SpecializationService: Found ${query.docs.length} documents for raw specializations');

      if (query.docs.isNotEmpty) {
        final data = query.docs.first.data();
        print('DEBUG SpecializationService: Raw document data keys: ${data.keys}');
        final dynamic specializationsData = data['specializations'] ?? data['specialties'] ?? [];
        print('DEBUG SpecializationService: Raw specializations data: $specializationsData');
        
        if (specializationsData is List<String>) {
          // Old format: convert to new format
          return specializationsData.map((spec) => {
            'title': spec,
            'level': 'Expert',
            'hasCertification': true,
          }).toList();
        } else {
          // New format: return as is
          final result = List<Map<String, dynamic>>.from(specializationsData);
          print('DEBUG SpecializationService: Returning ${result.length} specializations in new format');
          return result;
        }
      } else {
        print('DEBUG SpecializationService: No documents found for raw specializations');
      }
      return [];
    } catch (e) {
      print('DEBUG SpecializationService: Error getting raw specializations data: $e');
      return [];
    }
  }

  /// Add specialization to current user's clinic details
  static Future<bool> addSpecialization(
    String specialization, {
    String? level,
    bool? hasCertification,
  }) async {
    return await addSpecializationWithCertificate(
      specialization,
      level: level,
      hasCertification: hasCertification,
      certificateUrl: null,
    );
  }

  /// Add specialization with certificate to current user's clinic details
  static Future<bool> addSpecializationWithCertificate(
    String specialization, {
    String? level,
    bool? hasCertification,
    String? certificateUrl,
  }) async {
    try {
      print('DEBUG: Adding specialization: $specialization');
      
      final currentUser = await AuthGuard.getCurrentUser();
      if (currentUser == null) {
        print('DEBUG: No current user found');
        return false;
      }
      
      print('DEBUG: Current user UID: ${currentUser.uid}');

      // Find clinic details document
      final query = await _firestore
          .collection('clinicDetails')
          .where('clinicId', isEqualTo: currentUser.uid)
          .limit(1)
          .get();
      
      print('DEBUG: Found ${query.docs.length} clinic details documents');

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        final data = doc.data();
        print('DEBUG: Current clinic details data: ${data.keys}');
        
        // Get current specializations (handle both old and new formats)
        final dynamic existingData = data['specializations'] ?? data['specialties'] ?? [];
        List<Map<String, dynamic>> currentSpecializations = [];
        
        if (existingData is List<String>) {
          // Convert old format to new format
          currentSpecializations = existingData.map((spec) => {
            'title': spec,
            'level': 'Expert',
            'hasCertification': true,
            'addedAt': DateTime.now().toIso8601String(),
          }).toList().cast<Map<String, dynamic>>();
        } else {
          // Already new format
          currentSpecializations = List<Map<String, dynamic>>.from(existingData);
        }
        
        print('DEBUG: Current specializations: $currentSpecializations');

        // Check if specialization already exists (by title)
        final bool alreadyExists = currentSpecializations
            .any((spec) => spec['title'] == specialization);

        if (!alreadyExists) {
          // Add new specialization with full details
          final newSpecialization = {
            'title': specialization,
            'level': level ?? 'Expert',
            'hasCertification': hasCertification ?? true,
            'addedAt': DateTime.now().toIso8601String(),
            if (certificateUrl != null) 'certificateUrl': certificateUrl,
          };
          
          currentSpecializations.add(newSpecialization);
          print('DEBUG: Updated specializations: $currentSpecializations');

          await doc.reference.update({
            'specializations': currentSpecializations,
            'updatedAt': DateTime.now().toIso8601String(),
          });
          
          print('DEBUG: Specialization added successfully');

          return true;
        } else {
          print('DEBUG: Specialization already exists');
          return false;
        }
      } else {
        print('DEBUG: No clinic details document found. Creating one...');
        
        // Create clinic details document if it doesn't exist
        final success = await ClinicDetailsService.createClinicDetailsDocument(currentUser.uid);
        if (success) {
          print('DEBUG: Created clinic details document. Retrying...');
          return await addSpecializationWithCertificate(
            specialization,
            level: level,
            hasCertification: hasCertification,
            certificateUrl: certificateUrl,
          );
        } else {
          print('DEBUG: Failed to create clinic details document');
          return false;
        }
      }
    } catch (e, stackTrace) {
      print('Error adding specialization: $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Delete specialization from current user's clinic details
  static Future<bool> deleteSpecialization(String specialization) async {
    try {
      final currentUser = await AuthGuard.getCurrentUser();
      if (currentUser == null) return false;

      // Find clinic details document
      final query = await _firestore
          .collection('clinicDetails')
          .where('clinicId', isEqualTo: currentUser.uid)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        final data = doc.data();
        // Handle both old format (list of strings) and new format (list of maps)
        final dynamic specializationsData = data['specializations'] ?? data['specialties'] ?? [];
        
        if (specializationsData is List<String>) {
          // Old format: convert to new format while removing
          final List<String> currentSpecialties = List<String>.from(specializationsData);
          print('DEBUG: Current specialties (old format): $currentSpecialties');
          
          if (currentSpecialties.remove(specialization)) {
            // Convert remaining to new format
            final updatedSpecializations = currentSpecialties.map((s) => {
              'title': s,
              'level': 'Expert',
              'hasCertification': true,
              'addedAt': DateTime.now().toIso8601String(),
            }).toList();
            
            await doc.reference.update({
              'specializations': updatedSpecializations,
              'updatedAt': DateTime.now().toIso8601String(),
            });

            return true;
          }
        } else {
          // New format: list of maps
          final List<Map<String, dynamic>> currentSpecializations = 
              List<Map<String, dynamic>>.from(specializationsData);
          print('DEBUG: Current specializations (new format): $currentSpecializations');
          
          final int originalLength = currentSpecializations.length;
          currentSpecializations.removeWhere((spec) => spec['title'] == specialization);
          
          if (currentSpecializations.length < originalLength) {
            await doc.reference.update({
              'specializations': currentSpecializations,
              'updatedAt': DateTime.now().toIso8601String(),
            });
            return true;
          }
        }
        
        print('DEBUG: Specialization not found');
      } else {
        print('DEBUG: No clinic details document found');
      }
      return false;
    } catch (e) {
      print('Error deleting specialization: $e');
      return false;
    }
  }

  /// Update specialization details
  static Future<bool> updateSpecialization(
    String oldTitle,
    String newTitle, {
    String? level,
    bool? hasCertification,
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
        final doc = query.docs.first;
        final data = doc.data();
        final dynamic specializationsData = data['specializations'] ?? data['specialties'] ?? [];
        
        List<Map<String, dynamic>> currentSpecializations;
        
        if (specializationsData is List<String>) {
          // Convert old format to new format
          currentSpecializations = specializationsData.map((spec) => {
            'title': spec,
            'level': 'Expert',
            'hasCertification': true,
            'addedAt': DateTime.now().toIso8601String(),
          }).toList().cast<Map<String, dynamic>>();
        } else {
          currentSpecializations = List<Map<String, dynamic>>.from(specializationsData);
        }
        
        // Find and update the specialization
        final specIndex = currentSpecializations.indexWhere((spec) => spec['title'] == oldTitle);
        if (specIndex != -1) {
          currentSpecializations[specIndex] = {
            ...currentSpecializations[specIndex],
            'title': newTitle,
            if (level != null) 'level': level,
            if (hasCertification != null) 'hasCertification': hasCertification,
            'updatedAt': DateTime.now().toIso8601String(),
          };
          
          await doc.reference.update({
            'specializations': currentSpecializations,
            'updatedAt': DateTime.now().toIso8601String(),
          });
          
          return true;
        }
      }
      
      return false;
    } catch (e) {
      print('Error updating specialization: $e');
      return false;
    }
  }

  /// Get all specializations for current user
  static Future<List<Map<String, dynamic>>> getSpecializations() async {
    try {
      final currentUser = await AuthGuard.getCurrentUser();
      if (currentUser == null) return [];
      
      final rawData = await getRawSpecializationsData(currentUser.uid);
      return List<Map<String, dynamic>>.from(rawData);
    } catch (e) {
      print('Error getting specializations: $e');
      return [];
    }
  }
  
  /// Check if specialization exists
  static Future<bool> hasSpecialization(String specialization) async {
    try {
      final specializations = await getSpecializations();
      return specializations.any((spec) => spec['title'] == specialization);
    } catch (e) {
      print('Error checking specialization: $e');
      return false;
    }
  }
  
  /// Get specializations by level
  static Future<List<Map<String, dynamic>>> getSpecializationsByLevel(String level) async {
    try {
      final specializations = await getSpecializations();
      return specializations.where((spec) => spec['level'] == level).toList();
    } catch (e) {
      print('Error getting specializations by level: $e');
      return [];
    }
  }
  
  /// Get certified specializations only
  static Future<List<Map<String, dynamic>>> getCertifiedSpecializations() async {
    try {
      final specializations = await getSpecializations();
      return specializations.where((spec) => spec['hasCertification'] == true).toList();
    } catch (e) {
      print('Error getting certified specializations: $e');
      return [];
    }
  }
}
