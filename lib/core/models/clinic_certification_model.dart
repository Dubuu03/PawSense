import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Certification status enum
enum CertificationStatus {
  pending,
  approved,
  rejected,
  expired,
  suspended,
}

/// Model representing a clinic certification
class ClinicCertification {
  final String id;
  final String clinicId;
  final String name;
  final String issuer;
  final Timestamp dateIssued;
  final Timestamp? dateExpiry;
  final CertificationStatus status;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? documentUrl;
  final String? documentFileId; // Google Drive file ID
  final String? verificationNotes;

  const ClinicCertification({
    required this.id,
    required this.clinicId,
    required this.name,
    required this.issuer,
    required this.dateIssued,
    this.dateExpiry,
    this.status = CertificationStatus.pending,
    this.rejectionReason,
    required this.createdAt,
    this.updatedAt,
    this.documentUrl,
    this.documentFileId,
    this.verificationNotes,
  });

  /// Convert to Map for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clinicId': clinicId,
      'name': name,
      'issuer': issuer,
      'dateIssued': dateIssued,
      'dateExpiry': dateExpiry,
      'status': status.name,
      'rejectionReason': rejectionReason,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'documentUrl': documentUrl,
      'documentFileId': documentFileId,
      'verificationNotes': verificationNotes,
    };
  }

  /// Create from Firestore Map
  factory ClinicCertification.fromMap(Map<String, dynamic> map) {
    return ClinicCertification(
      id: map['id'] ?? '',
      clinicId: map['clinicId'] ?? '',
      name: map['name'] ?? '',
      issuer: map['issuer'] ?? '',
      dateIssued: map['dateIssued'] as Timestamp,
      dateExpiry: map['dateExpiry'] as Timestamp?,
      status: CertificationStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => CertificationStatus.pending,
      ),
      rejectionReason: map['rejectionReason'],
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: map['updatedAt'] != null 
          ? DateTime.tryParse(map['updatedAt']) 
          : null,
      documentUrl: map['documentUrl'],
      documentFileId: map['documentFileId'],
      verificationNotes: map['verificationNotes'],
    );
  }

  /// Create a copy with updated fields
  ClinicCertification copyWith({
    String? id,
    String? clinicId,
    String? name,
    String? issuer,
    Timestamp? dateIssued,
    Timestamp? dateExpiry,
    CertificationStatus? status,
    String? rejectionReason,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? documentUrl,
    String? documentFileId,
    String? verificationNotes,
  }) {
    return ClinicCertification(
      id: id ?? this.id,
      clinicId: clinicId ?? this.clinicId,
      name: name ?? this.name,
      issuer: issuer ?? this.issuer,
      dateIssued: dateIssued ?? this.dateIssued,
      dateExpiry: dateExpiry ?? this.dateExpiry,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      documentUrl: documentUrl ?? this.documentUrl,
      documentFileId: documentFileId ?? this.documentFileId,
      verificationNotes: verificationNotes ?? this.verificationNotes,
    );
  }

  /// Check if certification is expired
  bool get isExpired {
    if (dateExpiry == null) return false;
    return dateExpiry!.toDate().isBefore(DateTime.now());
  }

  /// Check if certification is active (approved and not expired)
  bool get isActive {
    return status == CertificationStatus.approved && !isExpired;
  }

  /// Get days until expiry
  int? get daysUntilExpiry {
    if (dateExpiry == null) return null;
    final now = DateTime.now();
    final expiry = dateExpiry!.toDate();
    return expiry.difference(now).inDays;
  }

  /// Get status display text
  String get statusDisplayText {
    switch (status) {
      case CertificationStatus.pending:
        return 'Pending Review';
      case CertificationStatus.approved:
        return isExpired ? 'Expired' : 'Active';
      case CertificationStatus.rejected:
        return 'Rejected';
      case CertificationStatus.expired:
        return 'Expired';
      case CertificationStatus.suspended:
        return 'Suspended';
    }
  }

  /// Get status color
  Color get statusColor {
    switch (status) {
      case CertificationStatus.pending:
        return Colors.orange;
      case CertificationStatus.approved:
        return isExpired ? Colors.red : Colors.green;
      case CertificationStatus.rejected:
        return Colors.red;
      case CertificationStatus.expired:
        return Colors.red;
      case CertificationStatus.suspended:
        return Colors.red;
    }
  }

  @override
  String toString() {
    return 'ClinicCertification(id: $id, clinicId: $clinicId, name: $name, status: $status, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClinicCertification &&
        other.id == id &&
        other.clinicId == clinicId &&
        other.name == name &&
        other.status == status;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        clinicId.hashCode ^
        name.hashCode ^
        status.hashCode;
  }
}
