import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// License status enum
enum LicenseStatus {
  pending,
  approved,
  rejected,
  expired,
  suspended,
}

/// Model representing a clinic license
class ClinicLicense {
  final String id;
  final String clinicId;
  final String licenseId; // Changed from licenseDescription
  final String licensePictureUrl; // Made required
  final String licensePictureFileId; // Made required - Google Drive file ID
  final Timestamp issueDate;
  final Timestamp expiryDate;
  final LicenseStatus status;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? verificationNotes;

  const ClinicLicense({
    required this.id,
    required this.clinicId,
    required this.licenseId, // Changed from licenseDescription
    required this.licensePictureUrl, // Made required
    required this.licensePictureFileId, // Made required
    required this.issueDate,
    required this.expiryDate,
    this.status = LicenseStatus.pending,
    this.rejectionReason,
    required this.createdAt,
    this.updatedAt,
    this.verificationNotes,
  });

  /// Convert to Map for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clinicId': clinicId,
      'licenseId': licenseId, // Changed from licenseDescription
      'licensePictureUrl': licensePictureUrl,
      'licensePictureFileId': licensePictureFileId,
      'issueDate': issueDate,
      'expiryDate': expiryDate,
      'status': status.name,
      'rejectionReason': rejectionReason,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'verificationNotes': verificationNotes,
    };
  }

  /// Create from Firestore Map
  factory ClinicLicense.fromMap(Map<String, dynamic> map) {
    return ClinicLicense(
      id: map['id'] ?? '',
      clinicId: map['clinicId'] ?? '',
      licenseId: map['licenseId'] ?? '', // Changed from licenseDescription
      licensePictureUrl: map['licensePictureUrl'] ?? '',
      licensePictureFileId: map['licensePictureFileId'] ?? '',
      issueDate: map['issueDate'] as Timestamp,
      expiryDate: map['expiryDate'] as Timestamp,
      status: LicenseStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => LicenseStatus.pending,
      ),
      rejectionReason: map['rejectionReason'],
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: map['updatedAt'] != null 
          ? DateTime.tryParse(map['updatedAt']) 
          : null,
      verificationNotes: map['verificationNotes'],
    );
  }

  /// Create a copy with updated fields
  ClinicLicense copyWith({
    String? id,
    String? clinicId,
    String? licenseId, // Changed from licenseDescription
    String? licensePictureUrl,
    String? licensePictureFileId,
    Timestamp? issueDate,
    Timestamp? expiryDate,
    LicenseStatus? status,
    String? rejectionReason,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? verificationNotes,
  }) {
    return ClinicLicense(
      id: id ?? this.id,
      clinicId: clinicId ?? this.clinicId,
      licenseId: licenseId ?? this.licenseId, // Changed from licenseDescription
      licensePictureUrl: licensePictureUrl ?? this.licensePictureUrl,
      licensePictureFileId: licensePictureFileId ?? this.licensePictureFileId,
      issueDate: issueDate ?? this.issueDate,
      expiryDate: expiryDate ?? this.expiryDate,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      verificationNotes: verificationNotes ?? this.verificationNotes,
    );
  }

  /// Check if license is expired
  bool get isExpired {
    return expiryDate.toDate().isBefore(DateTime.now());
  }

  /// Check if license is active (approved and not expired)
  bool get isActive {
    return status == LicenseStatus.approved && !isExpired;
  }

  /// Get days until expiry
  int get daysUntilExpiry {
    final now = DateTime.now();
    final expiry = expiryDate.toDate();
    return expiry.difference(now).inDays;
  }

  /// Get status display text
  String get statusDisplayText {
    switch (status) {
      case LicenseStatus.pending:
        return 'Pending Review';
      case LicenseStatus.approved:
        return isExpired ? 'Expired' : 'Active';
      case LicenseStatus.rejected:
        return 'Rejected';
      case LicenseStatus.expired:
        return 'Expired';
      case LicenseStatus.suspended:
        return 'Suspended';
    }
  }

  /// Get status color
  Color get statusColor {
    switch (status) {
      case LicenseStatus.pending:
        return Colors.orange;
      case LicenseStatus.approved:
        return isExpired ? Colors.red : Colors.green;
      case LicenseStatus.rejected:
        return Colors.red;
      case LicenseStatus.expired:
        return Colors.red;
      case LicenseStatus.suspended:
        return Colors.red;
    }
  }

  /// Check if license needs renewal (expires in 30 days or less)
  bool get needsRenewal {
    return daysUntilExpiry <= 30 && daysUntilExpiry > 0;
  }

  @override
  String toString() {
    return 'ClinicLicense(id: $id, clinicId: $clinicId, licenseId: $licenseId, status: $status, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClinicLicense &&
        other.id == id &&
        other.clinicId == clinicId &&
        other.licenseId == licenseId &&
        other.status == status;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        clinicId.hashCode ^
        licenseId.hashCode ^
        status.hashCode;
  }
}
