import 'clinic_service_model.dart';
import 'clinic_certification_model.dart';

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
    return ClinicDetails(
      id: map['id'] ?? '',
      clinicId: map['clinicId'] ?? '',
      clinicName: map['clinicName'] ?? '',
      description: map['description'] ?? '',
      address: map['address'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      operatingHours: map['operatingHours'],
      specialties: List<String>.from(map['specialties'] ?? []),
      services: (map['services'] as List<dynamic>? ?? [])
          .map((serviceMap) => ClinicService.fromMap(serviceMap as Map<String, dynamic>))
          .toList(),
      certifications: (map['certifications'] as List<dynamic>? ?? [])
          .map((certMap) => ClinicCertification.fromMap(certMap as Map<String, dynamic>))
          .toList(),
      isVerified: map['isVerified'] ?? false,
      isActive: map['isActive'] ?? true,
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: map['updatedAt'] != null 
          ? DateTime.tryParse(map['updatedAt']) 
          : null,
      updatedBy: map['updatedBy'],
      socialMedia: map['socialMedia'],
    );
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
