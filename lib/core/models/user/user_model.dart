import 'package:cloud_firestore/cloud_firestore.dart';

/// Model class representing a user in the app.
class UserModel {
  final String uid;
  final String username;
  final String email;
  final String? profileImageUrl;
  final bool darkTheme;
  final String role; // user | admin | super_admin
  final DateTime createdAt;
  final String? contactNumber;
  final bool? agreedToTerms;
  final String? address;
  // New admin fields - nullable for mobile compatibility
  final String? firstName;
  final String? lastName;
  // Suspension fields
  final bool isActive;
  final String? suspensionReason;
  final DateTime? suspendedAt;
  final DateTime? updatedAt;

  /// Creates a new UserModel instance.
  const UserModel({
    required this.uid,
    required this.username,
    required this.email,
    this.profileImageUrl,
    this.darkTheme = false,
    this.role = 'user',
    required this.createdAt,
    this.contactNumber,
    this.agreedToTerms = true,
    this.address,
    // New admin fields - nullable for mobile compatibility
    this.firstName,
    this.lastName,
    // Suspension fields with defaults
    this.isActive = true,
    this.suspensionReason,
    this.suspendedAt,
    this.updatedAt,
  });

  /// Converts the UserModel to a map for Firestore storage.
  Map<String, dynamic> toMap() => {
    'uid': uid,
    'username': username,
    'email': email,
    'profileImageUrl': profileImageUrl,
    'darkTheme': darkTheme,
    'role': role,
    'createdAt': createdAt.toIso8601String(),
    'contactNumber': contactNumber,
    'agreedToTerms': agreedToTerms,
    'address': address,
    'firstName': firstName,
    'lastName': lastName,
    // Suspension fields
    'isActive': isActive,
    'suspensionReason': suspensionReason,
    'suspendedAt': suspendedAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };

  /// Creates a UserModel from a Firestore map.
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      profileImageUrl: map['profileImageUrl'],
      darkTheme: map['darkTheme'] ?? false,
      role: map['role'] ?? 'user',
      createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
      contactNumber: map['contactNumber'],
      agreedToTerms: map['agreedToTerms'] ?? true,
      address: map['address'],
      firstName: map['firstName'],
      lastName: map['lastName'],
      // Suspension fields
      isActive: map['isActive'] ?? true,
      suspensionReason: map['suspensionReason'],
      suspendedAt: _parseDateTime(map['suspendedAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
    );
  }

  /// Helper method to parse DateTime from Firestore data (handles both Timestamp and String)
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    
    // Handle Firestore Timestamp
    if (value is Timestamp) {
      return value.toDate();
    }
    
    // Handle String
    if (value is String) {
      return DateTime.tryParse(value);
    }
    
    return null;
  }

  /// Returns a copy of this UserModel with updated fields.
  UserModel copyWith({
    String? uid,
    String? username,
    String? email,
    String? profileImageUrl,
    bool? darkTheme,
    String? role,
    DateTime? createdAt,
    String? contactNumber,
    bool? agreedToTerms,
    String? address,
    String? firstName,
    String? lastName,
    bool? isActive,
    String? suspensionReason,
    DateTime? suspendedAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      username: username ?? this.username,
      email: email ?? this.email,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      darkTheme: darkTheme ?? this.darkTheme,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      contactNumber: contactNumber ?? this.contactNumber,
      agreedToTerms: agreedToTerms ?? this.agreedToTerms,
      address: address ?? this.address,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      isActive: isActive ?? this.isActive,
      suspensionReason: suspensionReason ?? this.suspensionReason,
      suspendedAt: suspendedAt ?? this.suspendedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
