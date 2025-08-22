// lib/core/models/certificate_model.dart
class CertificateModel {
  final String name;
  final String issuer;
  final DateTime dateIssued;
  final DateTime? dateExpiry; // Nullable for lifetime certificates

  CertificateModel({
    required this.name,
    required this.issuer,
    required this.dateIssued,
    this.dateExpiry,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'issuer': issuer,
    'dateIssued': dateIssued.toIso8601String(),
    'dateExpiry': dateExpiry?.toIso8601String(),
  };

  factory CertificateModel.fromMap(Map<String, dynamic> map) {
    return CertificateModel(
      name: map['name'] ?? '',
      issuer: map['issuer'] ?? '',
      dateIssued: DateTime.tryParse(map['dateIssued'] ?? '') ?? DateTime.now(),
      dateExpiry: map['dateExpiry'] != null
          ? DateTime.tryParse(map['dateExpiry'])
          : null,
    );
  }

  CertificateModel copyWith({
    String? name,
    String? issuer,
    DateTime? dateIssued,
    DateTime? dateExpiry,
  }) {
    return CertificateModel(
      name: name ?? this.name,
      issuer: issuer ?? this.issuer,
      dateIssued: dateIssued ?? this.dateIssued,
      dateExpiry: dateExpiry ?? this.dateExpiry,
    );
  }

  bool get isLifetime => dateExpiry == null;
  bool get isExpired =>
      dateExpiry != null && dateExpiry!.isBefore(DateTime.now());
  bool get isExpiringSoon {
    if (dateExpiry == null) return false;
    final now = DateTime.now();
    final warningDate = dateExpiry!.subtract(const Duration(days: 30));
    return now.isAfter(warningDate) && now.isBefore(dateExpiry!);
  }
}
