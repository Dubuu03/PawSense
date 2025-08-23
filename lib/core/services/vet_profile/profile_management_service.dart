
import 'package:pawsense/core/guards/auth_guard.dart';
import 'package:pawsense/core/services/clinic/clinic_details_service.dart';
import 'package:pawsense/core/services/clinic/clinic_service.dart';
import 'package:pawsense/core/services/vet_profile/specialization_service.dart';

/// Service for managing vet profile data with caching
class ProfileManagementService {
  
  /// Cache for profile data
  static Map<String, dynamic>? _cachedProfile;
  static DateTime? _profileCacheTime;
  
  /// Get current vet's complete profile data
  static Future<Map<String, dynamic>?> getVetProfile({bool forceRefresh = false}) async {
    try {
      final currentUser = await AuthGuard.getCurrentUser();
      if (currentUser == null) return null;
      
      // Check cache (5 minutes) unless force refresh is requested
      final now = DateTime.now();
      if (!forceRefresh &&
          _cachedProfile != null && 
          _profileCacheTime != null && 
          now.difference(_profileCacheTime!).inMinutes < 5) {
        print('DEBUG: Returning cached profile data (cache age: ${now.difference(_profileCacheTime!).inMinutes} minutes)');
        return _cachedProfile;
      }
      
      if (forceRefresh) {
        print('DEBUG ProfileManagementService: Force refresh requested, clearing cache and fetching fresh data...');
        clearCache();
      } else {
        print('DEBUG ProfileManagementService: Cache expired or not found, fetching fresh data...');
      }
      
      // Get clinic data using ClinicService
      final clinic = await ClinicService.getClinicData(currentUser.uid);
      if (clinic == null) return null;
      
      // Get clinic details and specializations using respective services
      final clinicDetails = await ClinicDetailsService.getClinicDetails(currentUser.uid);
      final rawSpecializationsData = await SpecializationService.getRawSpecializationsData(currentUser.uid);
      
      print('DEBUG: clinicDetails result: $clinicDetails');
      print('DEBUG: clinicDetails is null: ${clinicDetails == null}');
      
      if (clinicDetails != null) {
        print('DEBUG: clinicDetails.services length: ${clinicDetails.services.length}');
        print('DEBUG: clinicDetails.certifications length: ${clinicDetails.certifications.length}');
        print('DEBUG: clinicDetails.specialties length: ${clinicDetails.specialties.length}');
        print('DEBUG: clinicDetails.services: ${clinicDetails.services}');
        print('DEBUG: clinicDetails.certifications: ${clinicDetails.certifications}');
        print('DEBUG: clinicDetails.specialties: ${clinicDetails.specialties}');
      }
      
      // Combine all data
      final profile = {
        'user': currentUser.toMap(),
        'clinic': clinic.toMap(),
        'clinicDetails': clinicDetails?.toMap(),
        'services': clinicDetails?.services.map((s) => s.toMap()).toList() ?? [], // Show ALL services, not just active ones
        'certifications': clinicDetails?.certifications.map((c) => c.toMap()).toList() ?? [], // Show ALL certifications (including pending ones)
        'specializations': rawSpecializationsData,
      };
      
      print('DEBUG ProfileManagementService: Services from clinicDetails: ${clinicDetails?.services.length ?? 0}');
      print('DEBUG ProfileManagementService: Active services: ${clinicDetails?.activeServices.length ?? 0}');
      print('DEBUG ProfileManagementService: ALL services being returned: ${profile['services']}');
      
      // Cache the result
      _cachedProfile = profile;
      _profileCacheTime = now;
      
      return profile;
    } catch (e) {
      print('Error getting vet profile: $e');
      return null;
    }
  }
  
  /// Clear cached profile data
  static void clearCache() {
    print('DEBUG: Clearing ProfileManagementService cache...');
    _cachedProfile = null;
    _profileCacheTime = null;
  }
  
  /// Get cache info for debugging
  static Map<String, dynamic> getCacheInfo() {
    return {
      'hasCachedData': _cachedProfile != null,
      'cacheTime': _profileCacheTime?.toIso8601String(),
      'cacheAge': _profileCacheTime != null 
          ? DateTime.now().difference(_profileCacheTime!).inMinutes 
          : null,
    };
  }
}
