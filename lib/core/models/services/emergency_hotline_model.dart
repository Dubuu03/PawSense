import 'package:cloud_firestore/cloud_firestore.dart';

class EmergencyHotlineModel {
  final String? id;
  final String title;
  final String description;
  final String phoneNumber;
  final String emergencyType;
  final bool isAvailable24_7;
  final List<String> operatingHours;
  final String? website;
  final String? email;
  final bool isActive;
  final int priority;
  final DateTime createdAt;
  final DateTime updatedAt;

  EmergencyHotlineModel({
    this.id,
    required this.title,
    required this.description,
    required this.phoneNumber,
    required this.emergencyType,
    this.isAvailable24_7 = true,
    this.operatingHours = const [],
    this.website,
    this.email,
    this.isActive = true,
    this.priority = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'phoneNumber': phoneNumber,
      'emergencyType': emergencyType,
      'isAvailable24_7': isAvailable24_7,
      'operatingHours': operatingHours,
      'website': website,
      'email': email,
      'isActive': isActive,
      'priority': priority,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  static EmergencyHotlineModel fromMap(Map<String, dynamic> map, String id) {
    return EmergencyHotlineModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      emergencyType: map['emergencyType'] ?? 'General',
      isAvailable24_7: map['isAvailable24_7'] ?? true,
      operatingHours: List<String>.from(map['operatingHours'] ?? []),
      website: map['website'],
      email: map['email'],
      isActive: map['isActive'] ?? true,
      priority: map['priority'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  EmergencyHotlineModel copyWith({
    String? id,
    String? title,
    String? description,
    String? phoneNumber,
    String? emergencyType,
    bool? isAvailable24_7,
    List<String>? operatingHours,
    String? website,
    String? email,
    bool? isActive,
    int? priority,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EmergencyHotlineModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      emergencyType: emergencyType ?? this.emergencyType,
      isAvailable24_7: isAvailable24_7 ?? this.isAvailable24_7,
      operatingHours: operatingHours ?? this.operatingHours,
      website: website ?? this.website,
      email: email ?? this.email,
      isActive: isActive ?? this.isActive,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}