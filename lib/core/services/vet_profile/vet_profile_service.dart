import 'profile_management_service.dart';
import '../clinic/clinic_service.dart';
import '../clinic/clinic_details_service.dart';
import '../clinic/clinic_services_management_service.dart';
import 'specialization_service.dart';

/// Main VetProfileService that delegates to specialized services
/// This maintains backward compatibility while using the new modular architecture
class VetProfileService {
  /// Stream current vet's profile data for real-time updates (delegates to ProfileManagementService)
  static Stream<Map<String, dynamic>?> streamVetProfile() {
    return ProfileManagementService.streamVetProfile();
  }
  
  /// Get current vet's profile data (delegates to ProfileManagementService)
  static Future<Map<String, dynamic>?> getVetProfile({bool forceRefresh = false}) async {
    return await ProfileManagementService.getVetProfile(forceRefresh: forceRefresh);
  }
  
  /// Update clinic basic information (delegates to ClinicService)
  static Future<bool> updateClinicBasicInfo({
    required String clinicName,
    required String address,
    required String phone,
    required String email,
    String? website,
  }) async {
    return await ClinicService.updateClinicBasicInfo(
      clinicName: clinicName,
      address: address,
      phone: phone,
      email: email,
      website: website,
    );
  }
  
  /// Toggle service status (delegates to ClinicServicesManagementService)
  static Future<bool> toggleServiceStatus(String serviceId, bool isActive) async {
    return await ClinicServicesManagementService.toggleServiceStatus(serviceId, isActive);
  }
  
  /// Delete service (delegates to ClinicServicesManagementService)
  static Future<bool> deleteService(String serviceId) async {
    return await ClinicServicesManagementService.deleteService(serviceId);
  }

  /// Add new service (delegates to ClinicServicesManagementService)
  static Future<bool> addService({
    required String serviceName,
    required String serviceDescription,
    required String estimatedPrice,
    required String duration,
    required String category,
    bool? isActive,
    bool? isVerified,
    Map<String, dynamic>? additionalFields,
  }) async {
    return await ClinicServicesManagementService.addService(
      serviceName: serviceName,
      serviceDescription: serviceDescription,
      estimatedPrice: estimatedPrice,
      duration: duration,
      category: category,
      isActive: isActive,
      isVerified: isVerified,
      additionalFields: additionalFields,
    );
  }

  /// Update existing service (delegates to ClinicServicesManagementService)
  static Future<bool> updateService({
    required String serviceId,
    String? serviceName,
    String? serviceDescription,
    String? estimatedPrice,
    String? duration,
    String? category,
    bool? isActive,
    bool? isVerified,
    Map<String, dynamic>? additionalFields,
  }) async {
    return await ClinicServicesManagementService.updateService(
      serviceId: serviceId,
      serviceName: serviceName,
      serviceDescription: serviceDescription,
      estimatedPrice: estimatedPrice,
      duration: duration,
      category: category,
      isActive: isActive,
      isVerified: isVerified,
      additionalFields: additionalFields,
    );
  }
  
  /// Fix existing services (delegates to ClinicServicesManagementService)
  static Future<bool> fixExistingServices() async {
    return await ClinicServicesManagementService.fixExistingServices();
  }

  /// Clear cached data (delegates to ProfileManagementService)
  static void clearCache() {
    ProfileManagementService.clearCache();
  }

  /// Add specialization (delegates to SpecializationService)
  static Future<bool> addSpecialization(
    String specialization, {
    String? level,
    bool? hasCertification,
  }) async {
    return await SpecializationService.addSpecialization(
      specialization,
      level: level,
      hasCertification: hasCertification,
    );
  }

  /// Delete specialization (delegates to SpecializationService)
  static Future<bool> deleteSpecialization(String specialization) async {
    return await SpecializationService.deleteSpecialization(specialization);
  }

  /// Get raw specializations data (delegates to SpecializationService)
  static Future<List<dynamic>> getRawSpecializationsData(String clinicId) async {
    return await SpecializationService.getRawSpecializationsData(clinicId);
  }

  // DEPRECATED METHODS - Use the new specialized services instead

  /// @deprecated Use ClinicService.getClinicData() instead
  static Future<dynamic> getClinicData(String userId) async {
    return await ClinicService.getClinicData(userId);
  }

  /// @deprecated Use ClinicDetailsService.getClinicDetails() instead
  static Future<dynamic> getClinicDetails(String clinicId) async {
    return await ClinicDetailsService.getClinicDetails(clinicId);
  }

  /// @deprecated Use ClinicDetailsService.createClinicDetailsDocument() instead
  static Future<bool> createClinicDetailsDocument(String clinicId) async {
    return await ClinicDetailsService.createClinicDetailsDocument(clinicId);
  }
}
