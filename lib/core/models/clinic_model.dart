// core/models/clinic_model.dart
class Clinic {
  final String id;
  final String name;
  final String address;
  final String phone;
  final String email;
  final String services;
  final DateTime createdAt;

  Clinic({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.email,
    required this.services,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'address': address,
    'phone': phone,
    'email': email,
    'services': services,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Clinic.fromMap(Map<String, dynamic> map) {
    return Clinic(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      services: map['services'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  Clinic copyWith({
    String? id,
    String? name,
    String? address,
    String? phone,
    String? email,
    String? services,
    DateTime? createdAt,
  }) {
    return Clinic(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      services: services ?? this.services,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Clinic(id: $id, name: $name, address: $address, phone: $phone, email: $email, services: $services, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Clinic &&
        other.id == id &&
        other.name == name &&
        other.address == address &&
        other.phone == phone &&
        other.email == email &&
        other.services == services &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        address.hashCode ^
        phone.hashCode ^
        email.hashCode ^
        services.hashCode ^
        createdAt.hashCode;
  }
}
