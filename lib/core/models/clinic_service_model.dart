/// Service categories for clinic services
enum ServiceCategory {
  consultation,
  diagnostic,
  preventive,
  surgery,
  emergency,
  telemedicine,
  grooming,
  boarding,
  training,
  other,
}

/// Model representing a clinic service
class ClinicService {
  final String id;
  final String clinicId;
  final String serviceName;
  final String serviceDescription;
  final String estimatedPrice;
  final String duration;
  final ServiceCategory category;
  final bool isActive;
  final bool isVerified; // Added verification field
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? createdBy;
  final String? updatedBy;

  const ClinicService({
    required this.id,
    required this.clinicId,
    required this.serviceName,
    required this.serviceDescription,
    required this.estimatedPrice,
    required this.duration,
    required this.category,
    this.isActive = true,
    this.isVerified = false, // Default to false - needs admin verification
    required this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.updatedBy,
  });

  /// Convert to Map for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clinicId': clinicId,
      'serviceName': serviceName,
      'serviceDescription': serviceDescription,
      'estimatedPrice': estimatedPrice,
      'duration': duration,
      'category': category.name,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'createdBy': createdBy,
      'updatedBy': updatedBy,
    };
  }

  /// Create from Firestore Map
  factory ClinicService.fromMap(Map<String, dynamic> map) {
    return ClinicService(
      id: map['id'] ?? '',
      clinicId: map['clinicId'] ?? '',
      serviceName: map['serviceName'] ?? '',
      serviceDescription: map['serviceDescription'] ?? '',
      estimatedPrice: map['estimatedPrice'] ?? '',
      duration: map['duration'] ?? '',
      category: ServiceCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => ServiceCategory.consultation,
      ),
      isActive: map['isActive'] ?? true,
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: map['updatedAt'] != null 
          ? DateTime.tryParse(map['updatedAt']) 
          : null,
      createdBy: map['createdBy'],
      updatedBy: map['updatedBy'],
    );
  }

  /// Create a copy with updated fields
  ClinicService copyWith({
    String? id,
    String? clinicId,
    String? serviceName,
    String? serviceDescription,
    String? estimatedPrice,
    String? duration,
    ServiceCategory? category,
    bool? isActive,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
  }) {
    return ClinicService(
      id: id ?? this.id,
      clinicId: clinicId ?? this.clinicId,
      serviceName: serviceName ?? this.serviceName,
      serviceDescription: serviceDescription ?? this.serviceDescription,
      estimatedPrice: estimatedPrice ?? this.estimatedPrice,
      duration: duration ?? this.duration,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }

  @override
  String toString() {
    return 'ClinicService(id: $id, clinicId: $clinicId, serviceName: $serviceName, category: $category, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClinicService &&
        other.id == id &&
        other.clinicId == clinicId &&
        other.serviceName == serviceName &&
        other.category == category;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        clinicId.hashCode ^
        serviceName.hashCode ^
        category.hashCode;
  }
}

