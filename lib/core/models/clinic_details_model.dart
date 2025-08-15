// core/models/clinic_details_model.dart
class ClinicDetails {
  final String id;
  final String clinicId;
  final String certificationName;
  final String licenseNumber;
  final DateTime issuedDate;
  final DateTime expiryDate;
  final String documentImage;
  final DateTime createdAt;

  ClinicDetails({
    required this.id,
    required this.clinicId,
    required this.certificationName,
    required this.licenseNumber,
    required this.issuedDate,
    required this.expiryDate,
    required this.documentImage,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'clinicId': clinicId,
    'certificationName': certificationName,
    'licenseNumber': licenseNumber,
    'issuedDate': issuedDate.toIso8601String(),
    'expiryDate': expiryDate.toIso8601String(),
    'documentImage': documentImage,
    'createdAt': createdAt.toIso8601String(),
  };

  factory ClinicDetails.fromMap(Map<String, dynamic> map) {
    return ClinicDetails(
      id: map['id'] ?? '',
      clinicId: map['clinicId'] ?? '',
      certificationName: map['certificationName'] ?? '',
      licenseNumber: map['licenseNumber'] ?? '',
      issuedDate: DateTime.parse(map['issuedDate']),
      expiryDate: DateTime.parse(map['expiryDate']),
      documentImage: map['documentImage'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  ClinicDetails copyWith({
    String? id,
    String? clinicId,
    String? certificationName,
    String? licenseNumber,
    DateTime? issuedDate,
    DateTime? expiryDate,
    String? documentImage,
    DateTime? createdAt,
  }) {
    return ClinicDetails(
      id: id ?? this.id,
      clinicId: clinicId ?? this.clinicId,
      certificationName: certificationName ?? this.certificationName,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      issuedDate: issuedDate ?? this.issuedDate,
      expiryDate: expiryDate ?? this.expiryDate,
      documentImage: documentImage ?? this.documentImage,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'ClinicDetails(id: $id, clinicId: $clinicId, certificationName: $certificationName, licenseNumber: $licenseNumber, issuedDate: $issuedDate, expiryDate: $expiryDate, documentImage: $documentImage, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClinicDetails &&
        other.id == id &&
        other.clinicId == clinicId &&
        other.certificationName == certificationName &&
        other.licenseNumber == licenseNumber &&
        other.issuedDate == issuedDate &&
        other.expiryDate == expiryDate &&
        other.documentImage == documentImage &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        clinicId.hashCode ^
        certificationName.hashCode ^
        licenseNumber.hashCode ^
        issuedDate.hashCode ^
        expiryDate.hashCode ^
        documentImage.hashCode ^
        createdAt.hashCode;
  }

  // Helper methods
  bool get isExpired => expiryDate.isBefore(DateTime.now());

  bool get isExpiringSoon {
    final now = DateTime.now();
    final warningDate = expiryDate.subtract(const Duration(days: 30));
    return now.isAfter(warningDate) && now.isBefore(expiryDate);
  }

  int get daysUntilExpiry {
    final now = DateTime.now();
    return expiryDate.difference(now).inDays;
  }
}
