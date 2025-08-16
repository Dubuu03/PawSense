/// Model class representing a user in the app.
class UserModel {
  final String uid;
  final String username;
  final String email;
  final String? profileImageUrl;
  final bool darkTheme;
  final String role; // user | admin | super_admin
  final DateTime createdAt;
  final DateTime? dateOfBirth;
  final String? contactNumber;
  final bool? agreedToTerms;
  final String? address;
  // New admin fields - nullable for mobile compatibility
  final String? firstName;
  final String? lastName;

  /// Creates a new UserModel instance.
  const UserModel({
    required this.uid,
    required this.username,
    required this.email,
    this.profileImageUrl,
    this.darkTheme = false,
    this.role = 'user',
    required this.createdAt,
    this.dateOfBirth,
    this.contactNumber,
    this.agreedToTerms = true,
    this.address,
    // New admin fields - nullable for mobile compatibility
    this.firstName,
    this.lastName,
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
    'dateOfBirth': dateOfBirth?.toIso8601String(),
    'contactNumber': contactNumber,
    'agreedToTerms': agreedToTerms,
    'address': address,
    'firstName': firstName,
    'lastName': lastName,
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
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      // After
      dateOfBirth: map['dateOfBirth'] != null
          ? DateTime.tryParse(map['dateOfBirth'])
          : null,
      contactNumber: map['contactNumber'],
      agreedToTerms: map['agreedToTerms'] ?? true,
      address: map['address'],
      firstName: map['firstName'],
      lastName: map['lastName'],
    );
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
    DateTime? dateOfBirth,
    String? contactNumber,
    bool? agreedToTerms,
    String? address,
    String? firstName,
    String? lastName,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      username: username ?? this.username,
      email: email ?? this.email,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      darkTheme: darkTheme ?? this.darkTheme,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      contactNumber: contactNumber ?? this.contactNumber,
      agreedToTerms: agreedToTerms ?? this.agreedToTerms,
      address: address ?? this.address,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
    );
  }
}
