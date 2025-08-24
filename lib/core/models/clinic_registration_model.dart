/// Enum representing the possible statuses of a clinic registration
enum ClinicStatus {
  pending('Pending', 'Application is under review'),
  approved('Approved', 'Clinic is approved and active'),
  rejected('Rejected', 'Application was rejected'),
  suspended('Suspended', 'Clinic access is temporarily suspended');

  const ClinicStatus(this.displayName, this.description);

  final String displayName;
  final String description;

  /// Convert from string to enum
  static ClinicStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return ClinicStatus.pending;
      case 'approved':
        return ClinicStatus.approved;
      case 'rejected':
        return ClinicStatus.rejected;
      case 'suspended':
        return ClinicStatus.suspended;
      default:
        return ClinicStatus.pending;
    }
  }
}

/// Model class for clinic registration with status
class ClinicRegistration {
  final String id;
  final String clinicName;
  final String adminName;
  final String adminId; // Reference to admin user
  final String email;
  final String phone;
  final String address;
  final String licenseNumber;
  final ClinicStatus status;
  final DateTime applicationDate;
  final DateTime? approvedDate;
  final String? rejectionReason;
  final String? suspensionReason;

  const ClinicRegistration({
    required this.id,
    required this.clinicName,
    required this.adminName,
    required this.adminId,
    required this.email,
    required this.phone,
    required this.address,
    required this.licenseNumber,
    required this.status,
    required this.applicationDate,
    this.approvedDate,
    this.rejectionReason,
    this.suspensionReason,
  });

  /// Convert to map for Firestore storage
  Map<String, dynamic> toMap() => {
    'id': id,
    'clinicName': clinicName,
    'adminName': adminName,
    'adminId': adminId,
    'email': email,
    'phone': phone,
    'address': address,
    'licenseNumber': licenseNumber,
    'status': status.name,
    'applicationDate': applicationDate.toIso8601String(),
    'approvedDate': approvedDate?.toIso8601String(),
    'rejectionReason': rejectionReason,
    'suspensionReason': suspensionReason,
  };

  /// Create from Firestore map
  factory ClinicRegistration.fromMap(Map<String, dynamic> map) {
    return ClinicRegistration(
      id: map['id'] ?? '',
      clinicName: map['clinicName'] ?? '',
      adminName: map['adminName'] ?? '',
      adminId: map['adminId'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      licenseNumber: map['licenseNumber'] ?? '',
      status: ClinicStatus.fromString(map['status'] ?? 'pending'),
      applicationDate: DateTime.tryParse(map['applicationDate'] ?? '') ?? DateTime.now(),
      approvedDate: map['approvedDate'] != null ? DateTime.tryParse(map['approvedDate']) : null,
      rejectionReason: map['rejectionReason'],
      suspensionReason: map['suspensionReason'],
    );
  }

  /// Create a copy with updated fields
  ClinicRegistration copyWith({
    String? id,
    String? clinicName,
    String? adminName,
    String? adminId,
    String? email,
    String? phone,
    String? address,
    String? licenseNumber,
    ClinicStatus? status,
    DateTime? applicationDate,
    DateTime? approvedDate,
    String? rejectionReason,
    String? suspensionReason,
  }) {
    return ClinicRegistration(
      id: id ?? this.id,
      clinicName: clinicName ?? this.clinicName,
      adminName: adminName ?? this.adminName,
      adminId: adminId ?? this.adminId,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      status: status ?? this.status,
      applicationDate: applicationDate ?? this.applicationDate,
      approvedDate: approvedDate ?? this.approvedDate,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      suspensionReason: suspensionReason ?? this.suspensionReason,
    );
  }
}
