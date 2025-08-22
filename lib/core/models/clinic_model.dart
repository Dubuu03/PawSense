// core/models/clinic_model.dart
class Clinic {
  final String id;
  final String userId; // Reference to user UID
  final String clinicName;
  final String address;
  final String phone;
  final String email;
  final String? website;
  final DateTime createdAt;

  Clinic({
    required this.id,
    required this.userId,
    required this.clinicName,
    required this.address,
    required this.phone,
    required this.email,
    this.website,
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
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  Clinic copyWith({
    String? id,
    String? userId,
    String? clinicName,
    String? address,
    String? phone,
    String? email,
    String? website,
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
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Clinic(id: $id, userId: $userId, clinicName: $clinicName, address: $address, phone: $phone, email: $email, website: $website, createdAt: $createdAt)';
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
        createdAt.hashCode;
  }
}
