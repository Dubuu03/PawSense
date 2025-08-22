import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/clinic_model.dart';
import '../models/clinic_details_model.dart';
import '../guards/auth_guard.dart';

/// Service for managing vet profile data
class VetProfileService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Cache for profile data
  static Map<String, dynamic>? _cachedProfile;
  static DateTime? _profileCacheTime;
  
  /// Get current vet's profile data
  static Future<Map<String, dynamic>?> getVetProfile() async {
    try {
      final currentUser = await AuthGuard.getCurrentUser();
      if (currentUser == null) return null;
      
      // Check cache (5 minutes)
      final now = DateTime.now();
      if (_cachedProfile != null && 
          _profileCacheTime != null && 
          now.difference(_profileCacheTime!).inMinutes < 5) {
        return _cachedProfile;
      }
      
      // Get clinic data
      final clinic = await _getClinicData(currentUser.uid);
      if (clinic == null) return null;
      
      // Get clinic details
      final clinicDetails = await _getClinicDetails(currentUser.uid);
      
      // Combine all data
      final profile = {
        'user': currentUser.toMap(),
        'clinic': clinic.toMap(),
        'clinicDetails': clinicDetails?.toMap(),
        'services': clinicDetails?.services.map((s) => s.toMap()).toList() ?? [], // Show ALL services, not just active ones
        'certifications': clinicDetails?.certifications.map((c) => c.toMap()).toList() ?? [], // Show ALL certifications (including pending ones)
        'specializations': clinicDetails?.specialties ?? [],
      };
      
      print('DEBUG VetProfileService: Services from clinicDetails: ${clinicDetails?.services.length ?? 0}');
      print('DEBUG VetProfileService: Active services: ${clinicDetails?.activeServices.length ?? 0}');
      print('DEBUG VetProfileService: ALL services being returned: ${profile['services']}');
      
      // Cache the result
      _cachedProfile = profile;
      _profileCacheTime = now;
      
      return profile;
    } catch (e) {
      print('Error getting vet profile: $e');
      return null;
    }
  }
  
  /// Get clinic data by user ID
  static Future<Clinic?> _getClinicData(String userId) async {
    try {
      final doc = await _firestore.collection('clinics').doc(userId).get();
      if (doc.exists) {
        return Clinic.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting clinic data: $e');
      return null;
    }
  }
  
  /// Get clinic details by user ID (clinic ID)
  static Future<ClinicDetails?> _getClinicDetails(String clinicId) async {
    try {
      final query = await _firestore
          .collection('clinicDetails')
          .where('clinicId', isEqualTo: clinicId)
          .limit(1)
          .get();
          
      if (query.docs.isNotEmpty) {
        return ClinicDetails.fromMap(query.docs.first.data());
      }
      return null;
    } catch (e) {
      print('Error getting clinic details: $e');
      return null;
    }
  }
  
  /// Update clinic basic information
  static Future<bool> updateClinicBasicInfo({
    required String clinicName,
    required String address,
    required String phone,
    required String email,
    String? website,
  }) async {
    try {
      final currentUser = await AuthGuard.getCurrentUser();
      if (currentUser == null) return false;
      
      // Update clinic document
      await _firestore.collection('clinics').doc(currentUser.uid).update({
        'clinicName': clinicName,
        'address': address,
        'phone': phone,
        'email': email,
        'website': website,
      });
      
      // Update clinic details if exists
      final query = await _firestore
          .collection('clinicDetails')
          .where('clinicId', isEqualTo: currentUser.uid)
          .limit(1)
          .get();
          
      if (query.docs.isNotEmpty) {
        await query.docs.first.reference.update({
          'clinicName': clinicName,
          'address': address,
          'phone': phone,
          'email': email,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }
      
      // Clear cache
      _clearCache();
      
      return true;
    } catch (e) {
      print('Error updating clinic basic info: $e');
      return false;
    }
  }
  
  /// Toggle service status
  static Future<bool> toggleServiceStatus(String serviceId, bool isActive) async {
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
        final services = List<Map<String, dynamic>>.from(data['services'] ?? []);
        
        // Find and update the specific service
        final serviceIndex = services.indexWhere((s) => s['id'] == serviceId);
        if (serviceIndex != -1) {
          services[serviceIndex]['isActive'] = isActive;
          services[serviceIndex]['updatedAt'] = DateTime.now().toIso8601String();
          
          await doc.reference.update({
            'services': services,
            'updatedAt': DateTime.now().toIso8601String(),
          });
          
          // Clear cache
          _clearCache();
          
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Error toggling service status: $e');
      return false;
    }
  }
  
  /// Delete service
  static Future<bool> deleteService(String serviceId) async {
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
        final services = List<Map<String, dynamic>>.from(data['services'] ?? []);
        
        // Remove the service
        services.removeWhere((s) => s['id'] == serviceId);
        
        await doc.reference.update({
          'services': services,
          'updatedAt': DateTime.now().toIso8601String(),
        });
        
        // Clear cache
        _clearCache();
        
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting service: $e');
      return false;
    }
  }

  /// Add new service with dynamic field handling
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
        final services = List<Map<String, dynamic>>.from(data['services'] ?? []);

        // Generate service name if empty
        String finalServiceName = serviceName.trim().isEmpty 
            ? _generateServiceNameFromDescription(serviceDescription, category)
            : serviceName;

        // Create new service with all required fields and additional fields
        final newService = {
          'id': 'service-${DateTime.now().millisecondsSinceEpoch}',
          'clinicId': currentUser.uid,
          'serviceName': finalServiceName,
          'serviceDescription': serviceDescription.trim().isEmpty 
              ? 'Professional veterinary service' 
              : serviceDescription,
          'estimatedPrice': estimatedPrice.trim().isEmpty 
              ? '0.00' 
              : estimatedPrice,
          'duration': duration.trim().isEmpty 
              ? '30 mins' 
              : duration,
          'category': category,
          'isActive': isActive ?? true,
          'isVerified': isVerified ?? false,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': null,
          // Add any additional fields dynamically
          ...?additionalFields,
        };

        // Add the new service
        services.add(newService);

        await doc.reference.update({
          'services': services,
          'updatedAt': DateTime.now().toIso8601String(),
        });

        // Clear cache
        _clearCache();

        return true;
      }
      return false;
    } catch (e) {
      print('Error adding service: $e');
      return false;
    }
  }

  /// Update existing service with dynamic field handling
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
        final services = List<Map<String, dynamic>>.from(data['services'] ?? []);

        // Find and update the service
        final serviceIndex = services.indexWhere((s) => s['id'] == serviceId);
        if (serviceIndex != -1) {
          final existingService = services[serviceIndex];
          
          // Generate service name if provided name is empty
          String? finalServiceName = serviceName;
          if (serviceName != null && serviceName.trim().isEmpty && serviceDescription != null) {
            finalServiceName = _generateServiceNameFromDescription(
              serviceDescription,
              category ?? existingService['category'] ?? 'general'
            );
          }

          // Update service with provided fields
          services[serviceIndex] = {
            ...existingService, // Keep existing fields like id, clinicId, etc.
            if (finalServiceName != null) 'serviceName': finalServiceName,
            if (serviceDescription != null) 'serviceDescription': serviceDescription,
            if (estimatedPrice != null) 'estimatedPrice': estimatedPrice,
            if (duration != null) 'duration': duration,
            if (category != null) 'category': category,
            if (isActive != null) 'isActive': isActive,
            if (isVerified != null) 'isVerified': isVerified,
            'updatedAt': DateTime.now().toIso8601String(),
            // Add any additional fields dynamically
            ...?additionalFields,
          };

          await doc.reference.update({
            'services': services,
            'updatedAt': DateTime.now().toIso8601String(),
          });

          // Clear cache
          _clearCache();

          return true;
        }
      }
      return false;
    } catch (e) {
      print('Error updating service: $e');
      return false;
    }
  }
  
  /// Fix existing services with missing required fields
  static Future<bool> fixExistingServices() async {
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
        final services = List<Map<String, dynamic>>.from(data['services'] ?? []);

        // Fix each service with missing fields
        for (int i = 0; i < services.length; i++) {
          final service = services[i];
          
          // Add missing required fields and fix empty serviceName
          services[i] = {
            'id': service['id'] ?? 'service-${DateTime.now().millisecondsSinceEpoch}-$i',
            'clinicId': service['clinicId'] ?? currentUser.uid,
            'serviceName': service['serviceName']?.isEmpty == true || service['serviceName'] == null 
                ? _generateServiceNameFromDescription(service['serviceDescription'] ?? 'Unknown Service', service['category'] ?? 'other')
                : service['serviceName'],
            'serviceDescription': service['serviceDescription'] ?? 'No description',
            'estimatedPrice': service['estimatedPrice'] ?? '0.00',
            'duration': service['duration'] ?? '30 minutes',
            'category': service['category'] ?? 'other',
            'isActive': service['isActive'] ?? true, // Default to active
            'createdAt': service['createdAt'] ?? DateTime.now().toIso8601String(),
            'updatedAt': service['updatedAt'] ?? DateTime.now().toIso8601String(),
          };
        }

        await doc.reference.update({
          'services': services,
          'updatedAt': DateTime.now().toIso8601String(),
        });

        // Clear cache
        _clearCache();

        return true;
      }
      return false;
    } catch (e) {
      print('Error fixing existing services: $e');
      return false;
    }
  }

  /// Generate service name from description and category
  static String _generateServiceNameFromDescription(String description, String category) {
    // Create a service name based on description and category
    if (description.toLowerCase().contains('skin scraping') || description.toLowerCase().contains('microscopic examination')) {
      return 'Skin Scraping & Analysis';
    } else if (description.toLowerCase().contains('vaccination')) {
      return 'Vaccination Package';
    } else if (description.toLowerCase().contains('dental')) {
      return 'Dental Cleaning';
    } else if (description.toLowerCase().contains('emergency') || description.toLowerCase().contains('surgery')) {
      return 'Emergency Surgery';
    } else if (description.toLowerCase().contains('consultation')) {
      return 'General Consultation';
    } else if (description.toLowerCase().contains('grooming')) {
      return 'Pet Grooming Service';
    } else {
      // Fallback: Use category + "Service"
      final categoryName = category[0].toUpperCase() + category.substring(1);
      return '$categoryName Service';
    }
  }

  /// Clear cached data
  static void _clearCache() {
    _cachedProfile = null;
    _profileCacheTime = null;
  }
}
