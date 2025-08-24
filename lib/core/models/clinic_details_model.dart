import 'clinic_service_model.dart';
import 'clinic_certification_model.dart';
import 'clinic_license_model.dart';

/// Model representing detailed clinic information
class ClinicDetails {
  final String id;
  final String clinicId;
  final String clinicName;
  final String description;
  final String address;
  final String phone;
  final String email;
  final String? operatingHours;
  final List<String> specialties;
  final List<ClinicService> services;
  final List<ClinicCertification> certifications;
  final List<ClinicLicense> licenses;
  final bool isVerified;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? updatedBy;
  final Map<String, dynamic>? socialMedia;

  const ClinicDetails({
    required this.id,
    required this.clinicId,
    required this.clinicName,
    required this.description,
    required this.address,
    required this.phone,
    required this.email,
    this.operatingHours,
    this.specialties = const [],
    this.services = const [],
    this.certifications = const [],
    this.licenses = const [],
    this.isVerified = false,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
    this.updatedBy,
    this.socialMedia,

  });

  /// Convert to Map for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clinicId': clinicId,
      'clinicName': clinicName,
      'description': description,
      'address': address,
      'phone': phone,
      'email': email,
      'operatingHours': operatingHours,
      'specialties': specialties,
      'services': services.map((service) => service.toMap()).toList(),
      'certifications': certifications.map((cert) => cert.toMap()).toList(),
      'licenses': licenses.map((license) => license.toMap()).toList(),
      'isVerified': isVerified,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'updatedBy': updatedBy,
      'socialMedia': socialMedia,
    };
  }

  /// Create from Firestore Map
  factory ClinicDetails.fromMap(Map<String, dynamic> map) {
    try {
      print('DEBUG: Starting ClinicDetails.fromMap...');
      print('DEBUG: Map keys: ${map.keys}');
      
      // Parse each field individually with error handling
      final id = map['id'] ?? '';
      print('DEBUG: id: $id');
      
      final clinicId = map['clinicId'] ?? '';
      print('DEBUG: clinicId: $clinicId');
      
      final clinicName = map['clinicName'] ?? '';
      print('DEBUG: clinicName: $clinicName');
      
      final description = map['description'] ?? '';
      print('DEBUG: description: $description');
      
      final address = map['address'] ?? '';
      print('DEBUG: address: $address');
      
      final phone = map['phone'] ?? '';
      print('DEBUG: phone: $phone');
      
      final email = map['email'] ?? '';
      print('DEBUG: email: $email');
      
      final operatingHours = map['operatingHours'];
      print('DEBUG: operatingHours: $operatingHours (${operatingHours.runtimeType})');
      
      // Handle specialties - can be either strings or objects (check both 'specialties' and 'specializations')
      final specialtiesRaw = map['specializations'] ?? map['specialties'] ?? [];
      final List<String> specialties;
      
      if (specialtiesRaw is List) {
        if (specialtiesRaw.isNotEmpty && specialtiesRaw.first is Map) {
          // If specialties are stored as objects, extract the title
          specialties = specialtiesRaw.map((spec) {
            if (spec is Map<String, dynamic>) {
              return spec['title']?.toString() ?? '';
            }
            return spec.toString();
          }).where((title) => title.isNotEmpty).cast<String>().toList();
        } else {
          // If specialties are stored as simple strings
          specialties = List<String>.from(specialtiesRaw);
        }
      } else {
        specialties = [];
      }
      
      print('DEBUG: specialties: $specialties');
      
      print('DEBUG: About to parse services...');
      final services = (map['services'] as List<dynamic>? ?? [])
          .map((serviceMap) => ClinicService.fromMap(serviceMap as Map<String, dynamic>))
          .toList();
      print('DEBUG: services: ${services.length} items');
      
      print('DEBUG: About to parse certifications...');
      final certifications = (map['certifications'] as List<dynamic>? ?? [])
          .map((certMap) => ClinicCertification.fromMap(certMap as Map<String, dynamic>))
          .toList();
      print('DEBUG: certifications: ${certifications.length} items');
      
      print('DEBUG: About to parse licenses...');
      final licenses = (map['licenses'] as List<dynamic>? ?? [])
          .map((licenseMap) => ClinicLicense.fromMap(licenseMap as Map<String, dynamic>))
          .toList();
      print('DEBUG: licenses: ${licenses.length} items');
      
      final isVerified = map['isVerified'] ?? false;
      print('DEBUG: isVerified: $isVerified');
      
      final isActive = map['isActive'] ?? true;
      print('DEBUG: isActive: $isActive');
      
      final createdAt = DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now();
      print('DEBUG: createdAt: $createdAt');
      
      final updatedAt = map['updatedAt'] != null 
          ? DateTime.tryParse(map['updatedAt']) 
          : null;
      print('DEBUG: updatedAt: $updatedAt');
      
      final updatedBy = map['updatedBy'];
      print('DEBUG: updatedBy: $updatedBy');
      
      final socialMedia = map['socialMedia'];
      print('DEBUG: socialMedia: $socialMedia');

      return ClinicDetails(
        id: id,
        clinicId: clinicId,
        clinicName: clinicName,
        description: description,
        address: address,
        phone: phone,
        email: email,
        operatingHours: operatingHours,
        specialties: specialties,
        services: services,
        certifications: certifications,
        licenses: licenses,
        isVerified: isVerified,
        isActive: isActive,
        createdAt: createdAt,
        updatedAt: updatedAt,
        updatedBy: updatedBy,
        socialMedia: socialMedia,
      );
    } catch (e, stackTrace) {
      print('ERROR in ClinicDetails.fromMap: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Create a copy with updated fields
  ClinicDetails copyWith({
    String? id,
    String? clinicId,
    String? clinicName,
    String? description,
    String? address,
    String? phone,
    String? email,
    String? operatingHours,
    List<String>? specialties,
    List<ClinicService>? services,
    List<ClinicCertification>? certifications,
    List<ClinicLicense>? licenses,
    bool? isVerified,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? updatedBy,
    String? logoUrl,
    String? bannerUrl,
    List<String>? galleryImages,
    Map<String, dynamic>? socialMedia,
    Map<String, dynamic>? location,
    String? timezone,
  }) {
    return ClinicDetails(
      id: id ?? this.id,
      clinicId: clinicId ?? this.clinicId,
      clinicName: clinicName ?? this.clinicName,
      description: description ?? this.description,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      operatingHours: operatingHours ?? this.operatingHours,
      specialties: specialties ?? this.specialties,
      services: services ?? this.services,
      certifications: certifications ?? this.certifications,
      licenses: licenses ?? this.licenses,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      socialMedia: socialMedia ?? this.socialMedia,

    );
  }

  /// Get active services
  List<ClinicService> get activeServices {
    return services.where((service) => service.isActive).toList();
  }

  /// Get active certifications
  List<ClinicCertification> get activeCertifications {
    return certifications.where((cert) => cert.isActive).toList();
  }

  /// Get pending certifications
  List<ClinicCertification> get pendingCertifications {
    return certifications.where((cert) => cert.status == CertificationStatus.pending).toList();
  }

  /// Get expired certifications
  List<ClinicCertification> get expiredCertifications {
    return certifications.where((cert) => cert.isExpired).toList();
  }

  /// Get active licenses
  List<ClinicLicense> get activeLicenses {
    return licenses.where((license) => license.isActive).toList();
  }

  /// Get pending licenses
  List<ClinicLicense> get pendingLicenses {
    return licenses.where((license) => license.status == LicenseStatus.pending).toList();
  }

  /// Get expired licenses
  List<ClinicLicense> get expiredLicenses {
    return licenses.where((license) => license.isExpired).toList();
  }

  /// Check if clinic has specific specialty
  bool hasSpecialty(String specialty) {
    return specialties.contains(specialty);
  }

  /// Get service by category
  List<ClinicService> getServicesByCategory(ServiceCategory category) {
    return services.where((service) => service.category == category).toList();
  }

  /// Get service by name
  ClinicService? getServiceByName(String serviceName) {
    try {
      return services.firstWhere((service) => service.serviceName == serviceName);
    } catch (e) {
      return null;
    }
  }

  @override
  String toString() {
    return 'ClinicDetails(id: $id, clinicId: $clinicId, clinicName: $clinicName, isVerified: $isVerified, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClinicDetails &&
        other.id == id &&
        other.clinicId == clinicId &&
        other.clinicName == clinicName;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        clinicId.hashCode ^
        clinicName.hashCode;
  }
}

