// lib/core/models/service_model.dart
enum ServiceCategory {
  consultation,
  diagnostic,
  preventive,
  surgery,
  emergency,
  telemedicine;

  String get displayName {
    switch (this) {
      case ServiceCategory.consultation:
        return 'Consultation';
      case ServiceCategory.diagnostic:
        return 'Diagnostic';
      case ServiceCategory.preventive:
        return 'Preventive';
      case ServiceCategory.surgery:
        return 'Surgery';
      case ServiceCategory.emergency:
        return 'Emergency';
      case ServiceCategory.telemedicine:
        return 'Telemedicine';
    }
  }
}

class ServiceModel {
  final String serviceName;
  final String serviceDescription;
  final String estimatedPrice; // Using String to handle flexible pricing
  final String duration;
  final ServiceCategory category;

  ServiceModel({
    required this.serviceName,
    required this.serviceDescription,
    required this.estimatedPrice,
    required this.duration,
    required this.category,
  });

  Map<String, dynamic> toMap() => {
    'serviceName': serviceName,
    'serviceDescription': serviceDescription,
    'estimatedPrice': estimatedPrice,
    'duration': duration,
    'category': category.name,
  };

  factory ServiceModel.fromMap(Map<String, dynamic> map) {
    return ServiceModel(
      serviceName: map['serviceName'] ?? '',
      serviceDescription: map['serviceDescription'] ?? '',
      estimatedPrice: map['estimatedPrice'] ?? '',
      duration: map['duration'] ?? '',
      category: ServiceCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => ServiceCategory.consultation,
      ),
    );
  }

  ServiceModel copyWith({
    String? serviceName,
    String? serviceDescription,
    String? estimatedPrice,
    String? duration,
    ServiceCategory? category,
  }) {
    return ServiceModel(
      serviceName: serviceName ?? this.serviceName,
      serviceDescription: serviceDescription ?? this.serviceDescription,
      estimatedPrice: estimatedPrice ?? this.estimatedPrice,
      duration: duration ?? this.duration,
      category: category ?? this.category,
    );
  }
}
