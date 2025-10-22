// core/models/clinic_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Clinic {
  final String id;
  final String userId; // Reference to user UID
  final String clinicName;
  final String address;
  final String phone;
  final String email;
  final String? website;
  final String? logoUrl; // Cloudinary URL for clinic logo
  final String status; // pending, approved, suspended, rejected
  final String scheduleStatus; // pending, in_progress, completed
  final bool isVisible; // Only true when schedule is completed
  final DateTime? scheduleCompletedAt;
  final DateTime createdAt;

  Clinic({
    required this.id,
    required this.userId,
    required this.clinicName,
    required this.address,
    required this.phone,
    required this.email,
    this.website,
    this.logoUrl,
    this.status = 'pending',
    this.scheduleStatus = 'pending',
    this.isVisible = false,
    this.scheduleCompletedAt,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'clinicName': clinicName,
    'address': address,
    'phone': phone,
    'email': email,
    'website': website,
    'logoUrl': logoUrl,
    'status': status,
    'scheduleStatus': scheduleStatus,
    'isVisible': isVisible,
    'scheduleCompletedAt': scheduleCompletedAt?.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
  };

  factory Clinic.fromMap(Map<String, dynamic> map) {
    return Clinic(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      clinicName: map['clinicName'] ?? '',
      address: map['address'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      website: map['website'],
      logoUrl: map['logoUrl'],
      status: map['status'] ?? 'pending',
      scheduleStatus: map['scheduleStatus'] ?? 'pending',
      isVisible: map['isVisible'] ?? false,
      scheduleCompletedAt: _parseDateTime(map['scheduleCompletedAt']),
      createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
    );
  }

  /// Helper method to parse DateTime from various Firestore formats
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    
    // Handle Firestore Timestamp
    if (value is Timestamp) {
      return value.toDate();
    }
    
    // Handle string format
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        print('Warning: Failed to parse date string: $value');
        return null;
      }
    }
    
    // Handle DateTime (already parsed)
    if (value is DateTime) {
      return value;
    }
    
    print('Warning: Unexpected date format: $value (${value.runtimeType})');
    return null;
  }

  Clinic copyWith({
    String? id,
    String? userId,
    String? clinicName,
    String? address,
    String? phone,
    String? email,
    String? website,
    String? logoUrl,
    String? status,
    String? scheduleStatus,
    bool? isVisible,
    DateTime? scheduleCompletedAt,
    DateTime? createdAt,
  }) {
    return Clinic(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      clinicName: clinicName ?? this.clinicName,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website ?? this.website,
      logoUrl: logoUrl ?? this.logoUrl,
      status: status ?? this.status,
      scheduleStatus: scheduleStatus ?? this.scheduleStatus,
      isVisible: isVisible ?? this.isVisible,
      scheduleCompletedAt: scheduleCompletedAt ?? this.scheduleCompletedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Clinic(id: $id, userId: $userId, clinicName: $clinicName, address: $address, phone: $phone, email: $email, website: $website, status: $status, scheduleStatus: $scheduleStatus, isVisible: $isVisible, scheduleCompletedAt: $scheduleCompletedAt, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Clinic &&
        other.id == id &&
        other.userId == userId &&
        other.clinicName == clinicName &&
        other.address == address &&
        other.phone == phone &&
        other.email == email &&
        other.website == website &&
        other.logoUrl == logoUrl &&
        other.status == status &&
        other.scheduleStatus == scheduleStatus &&
        other.isVisible == isVisible &&
        other.scheduleCompletedAt == scheduleCompletedAt &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        clinicName.hashCode ^
        address.hashCode ^
        phone.hashCode ^
        email.hashCode ^
        website.hashCode ^
        logoUrl.hashCode ^
        status.hashCode ^
        scheduleStatus.hashCode ^
        isVisible.hashCode ^
        scheduleCompletedAt.hashCode ^
        createdAt.hashCode;
  }

  // Helper methods for schedule status
  bool get needsScheduleSetup => status == 'approved' && scheduleStatus != 'completed';
  bool get canAcceptAppointments => status == 'approved' && scheduleStatus == 'completed' && isVisible;
}
