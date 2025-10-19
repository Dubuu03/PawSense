import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/clinic/clinic_model.dart';
import '../../models/clinic/clinic_details_model.dart';

/// Service for fetching lists of clinics for public display
class ClinicListService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Get all approved and active clinics for public display
  static Future<List<Map<String, dynamic>>> getAllActiveClinics() async {
    try {
      // Get all approved clinics that are visible (completed schedule setup)
      final clinicsSnapshot = await _firestore
          .collection('clinics')
          .where('status', isEqualTo: 'approved')
          .where('isVisible', isEqualTo: true) // Only show clinics that completed setup
          .get();
      
      List<Map<String, dynamic>> clinicList = [];
      
      for (var clinicDoc in clinicsSnapshot.docs) {
        final clinicData = clinicDoc.data();
        final clinic = Clinic.fromMap(clinicData);
        
        // Double-check that schedule is completed (belt and suspenders approach)
        if (clinic.scheduleStatus != 'completed') {
          print('⚠️ Clinic ${clinic.clinicName} has isVisible=true but scheduleStatus=${clinic.scheduleStatus}');
          continue; // Skip this clinic as it shouldn't be visible yet
        }
        
        // Try to get clinic details for additional information
        final clinicDetailsQuery = await _firestore
            .collection('clinicDetails')
            .where('clinicId', isEqualTo: clinic.id)
            .where('isActive', isEqualTo: true)
            .limit(1)
            .get();
        
        ClinicDetails? clinicDetails;
        if (clinicDetailsQuery.docs.isNotEmpty) {
          try {
            clinicDetails = ClinicDetails.fromMap(clinicDetailsQuery.docs.first.data());
          } catch (e) {
            // Continue without detailed info
          }
        }
        
        // Create consolidated clinic info
        final clinicInfo = {
          'id': clinic.id,
          'name': clinic.clinicName,
          'address': clinic.address,
          'phone': clinic.phone,
          'email': clinic.email,
          'website': clinic.website,
          'logoUrl': clinic.logoUrl,
          'operatingHours': clinicDetails?.operatingHours ?? 'Mon-Fri: 8AM-6PM',
          'specialties': clinicDetails?.specialties ?? [],
          'isVerified': clinicDetails?.isVerified ?? false,
          'rating': 4.5, // Default rating - can be calculated from reviews in future
          'createdAt': clinic.createdAt,
        };
        
        clinicList.add(clinicInfo);
      }
      
      // Sort by name for consistent ordering
      clinicList.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
      
      return clinicList;
      
    } catch (e) {
      return [];
    }
  }
  
  /// Get clinics with search and filter options
  static Future<List<Map<String, dynamic>>> searchClinics({
    String? searchQuery,
    List<String>? specialties,
    bool verifiedOnly = false,
    int? limit,
  }) async {
    try {
      List<Map<String, dynamic>> allClinics = await getAllActiveClinics();
      
      // Apply filters
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        allClinics = allClinics.where((clinic) {
          final name = (clinic['name'] as String).toLowerCase();
          final address = (clinic['address'] as String).toLowerCase();
          return name.contains(query) || address.contains(query);
        }).toList();
      }
      
      if (specialties != null && specialties.isNotEmpty) {
        allClinics = allClinics.where((clinic) {
          final clinicSpecialties = List<String>.from(clinic['specialties'] ?? []);
          return specialties.any((specialty) => 
            clinicSpecialties.any((cs) => cs.toLowerCase().contains(specialty.toLowerCase()))
          );
        }).toList();
      }
      
      if (verifiedOnly) {
        allClinics = allClinics.where((clinic) => clinic['isVerified'] == true).toList();
      }
      
      // Apply limit if specified
      if (limit != null && limit > 0) {
        allClinics = allClinics.take(limit).toList();
      }
      
      return allClinics;
      
    } catch (e) {
      return [];
    }
  }
  
  /// Get clinics near a specific location (simplified version without geolocation)
  static Future<List<Map<String, dynamic>>> getClinicsNearby({
    String? cityFilter,
    int limit = 10,
  }) async {
    try {
      List<Map<String, dynamic>> allClinics = await getAllActiveClinics();
      
      if (cityFilter != null && cityFilter.isNotEmpty) {
        final city = cityFilter.toLowerCase();
        allClinics = allClinics.where((clinic) {
          final address = (clinic['address'] as String).toLowerCase();
          return address.contains(city);
        }).toList();
      }
      
      // Sort by verification status and rating
      allClinics.sort((a, b) {
        // Verified clinics first
        if (a['isVerified'] != b['isVerified']) {
          return b['isVerified'] ? 1 : -1;
        }
        // Then by rating
        final ratingA = a['rating'] as double;
        final ratingB = b['rating'] as double;
        return ratingB.compareTo(ratingA);
      });
      
      return allClinics.take(limit).toList();
      
    } catch (e) {
      return [];
    }
  }
  
  /// Get clinic statistics for display
  static Future<Map<String, int>> getClinicStatistics() async {
    try {
      final allClinics = await getAllActiveClinics();
      final verifiedCount = allClinics.where((clinic) => clinic['isVerified'] == true).length;
      
      return {
        'total': allClinics.length,
        'verified': verifiedCount,
        'unverified': allClinics.length - verifiedCount,
      };
      
    } catch (e) {
      print('Error getting clinic statistics: $e');
      return {'total': 0, 'verified': 0, 'unverified': 0};
    }
  }
}
