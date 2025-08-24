import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../google_drive/google_drive_service.dart';
import '../../models/clinic_certification_model.dart';
import '../../models/clinic_license_model.dart';
import '../../models/clinic_details_model.dart';

/// Service for managing clinic documents (certifications and licenses)
class DocumentManagementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleDriveService _googleDriveService = GoogleDriveService();

  // Collection references
  static const String _clinicDetailsCollection = 'clinicDetails';

  /// Add license to clinic details with required image
  Future<ClinicLicense> addLicenseWithImage({
    required String clinicId,
    required String licenseId,
    required DateTime issueDate,
    required DateTime expiryDate,
    required Uint8List imageBytes,
    required String fileName,
    String? verificationNotes,
  }) async {
    try {
      print('Adding license with image for clinic: $clinicId');
      
      // Upload image to Google Drive first (required)
      final String actualFileName = 'license_${licenseId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      final uploadResult = await _googleDriveService.uploadImageFromBytes(
        fileBytes: imageBytes,
        fileName: actualFileName,
        description: 'License document for license ID: $licenseId',
        properties: {
          'clinic_id': clinicId,
          'license_id': licenseId,
          'document_type': 'license',
        },
      );

      // Create license object with required image data
      final String licenseDocId = _firestore.collection(_clinicDetailsCollection).doc().id;
      final license = ClinicLicense(
        id: licenseDocId,
        clinicId: clinicId,
        licenseId: licenseId,
        licensePictureUrl: uploadResult.webViewLink,
        licensePictureFileId: uploadResult.fileId,
        issueDate: Timestamp.fromDate(issueDate),
        expiryDate: Timestamp.fromDate(expiryDate),
        status: LicenseStatus.pending,
        createdAt: DateTime.now(),
        verificationNotes: verificationNotes,
      );

      // Add license to clinic details
      await _addLicenseToClinicDetails(clinicId, license);

      print('License added successfully: ${license.id}');
      return license;
    } catch (e) {
      print('Error adding license: $e');
      throw Exception('Failed to add license: $e');
    }
  }

  /// Add license without image to clinic details (for backend flexibility)
  Future<ClinicLicense> addLicense({
    required String clinicId,
    required String licenseId,
    required DateTime issueDate,
    required DateTime expiryDate,
    String? verificationNotes,
  }) async {
    try {
      print('Adding license without image for clinic: $clinicId');

      // Create license object without image
      final String licenseDocId = _firestore.collection(_clinicDetailsCollection).doc().id;
      final license = ClinicLicense(
        id: licenseDocId,
        clinicId: clinicId,
        licenseId: licenseId,
        licensePictureUrl: '', // Empty since no image
        licensePictureFileId: '', // Empty since no image
        issueDate: Timestamp.fromDate(issueDate),
        expiryDate: Timestamp.fromDate(expiryDate),
        status: LicenseStatus.pending,
        createdAt: DateTime.now(),
        verificationNotes: verificationNotes,
      );

      // Add license to clinic details
      await _addLicenseToClinicDetails(clinicId, license);

      print('License added successfully (no image): ${license.id}');
      return license;
    } catch (e) {
      print('Error adding license: $e');
      throw Exception('Failed to add license: $e');
    }
  }

  /// Add certification with required image to clinic details
  Future<ClinicCertification> addCertificationWithImage({
    required String clinicId,
    required String name,
    required String issuer,
    required DateTime issueDate,
    DateTime? expiryDate,
    required Uint8List imageBytes,
    required String fileName,
    String? verificationNotes,
  }) async {
    try {
      print('Adding certification with image for clinic: $clinicId');
      
      // Upload image to Google Drive first (required)
      final String actualFileName = 'cert_${name.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      final uploadResult = await _googleDriveService.uploadImageFromBytes(
        fileBytes: imageBytes,
        fileName: actualFileName,
        description: 'Certification document for: $name',
        properties: {
          'clinic_id': clinicId,
          'certification_name': name,
          'document_type': 'certification',
        },
      );

      // Create certification object
      final String certDocId = _firestore.collection(_clinicDetailsCollection).doc().id;
      final certification = ClinicCertification(
        id: certDocId,
        clinicId: clinicId,
        name: name,
        issuer: issuer,
        dateIssued: Timestamp.fromDate(issueDate),
        dateExpiry: expiryDate != null ? Timestamp.fromDate(expiryDate) : null,
        status: CertificationStatus.pending,
        documentFileId: uploadResult.fileId,
        createdAt: DateTime.now(),
        verificationNotes: verificationNotes,
      );

      // Add certification to clinic details
      await _addCertificationToClinicDetails(clinicId, certification);

      print('Certification added successfully: ${certification.id}');
      return certification;
    } catch (e) {
      print('Error adding certification: $e');
      throw Exception('Failed to add certification: $e');
    }
  }

  /// Add certification without image to clinic details (for backend flexibility)
  Future<ClinicCertification> addCertification({
    required String clinicId,
    required String name,
    required String issuer,
    required DateTime issueDate,
    DateTime? expiryDate,
    String? verificationNotes,
  }) async {
    try {
      print('Adding certification without image for clinic: $clinicId');

      // Create certification object without image
      final String certDocId = _firestore.collection(_clinicDetailsCollection).doc().id;
      final certification = ClinicCertification(
        id: certDocId,
        clinicId: clinicId,
        name: name,
        issuer: issuer,
        dateIssued: Timestamp.fromDate(issueDate),
        dateExpiry: expiryDate != null ? Timestamp.fromDate(expiryDate) : null,
        status: CertificationStatus.pending,
        createdAt: DateTime.now(),
        verificationNotes: verificationNotes,
        // documentUrl and documentFileId will be null
      );

      // Add certification to clinic details
      await _addCertificationToClinicDetails(clinicId, certification);

      print('Certification added successfully (no image): ${certification.id}');
      return certification;
    } catch (e) {
      print('Error adding certification: $e');
      throw Exception('Failed to add certification: $e');
    }
  }

  /// Internal method to add license to clinic details document
  Future<void> _addLicenseToClinicDetails(String clinicId, ClinicLicense license) async {
    try {
      final docRef = _firestore.collection(_clinicDetailsCollection).doc(clinicId);
      
      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        
        if (doc.exists) {
          // Get existing clinic details
          final clinicDetails = ClinicDetails.fromMap(doc.data()!);
          
          // Add new license
          final updatedLicenses = List<ClinicLicense>.from(clinicDetails.licenses)..add(license);
          
          // Update clinic details with new license
          final updatedClinicDetails = clinicDetails.copyWith(
            licenses: updatedLicenses,
            updatedAt: DateTime.now(),
          );
          
          transaction.update(docRef, updatedClinicDetails.toMap());
        } else {
          throw Exception('Clinic details document not found');
        }
      });
    } catch (e) {
      print('Error adding license to clinic details: $e');
      throw Exception('Failed to add license to clinic details: $e');
    }
  }

  /// Internal method to add certification to clinic details document
  Future<void> _addCertificationToClinicDetails(String clinicId, ClinicCertification certification) async {
    try {
      final docRef = _firestore.collection(_clinicDetailsCollection).doc(clinicId);
      
      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        
        if (doc.exists) {
          // Get existing clinic details
          final clinicDetails = ClinicDetails.fromMap(doc.data()!);
          
          // Add new certification
          final updatedCertifications = List<ClinicCertification>.from(clinicDetails.certifications)..add(certification);
          
          // Update clinic details with new certification
          final updatedClinicDetails = clinicDetails.copyWith(
            certifications: updatedCertifications,
            updatedAt: DateTime.now(),
          );
          
          transaction.update(docRef, updatedClinicDetails.toMap());
        } else {
          throw Exception('Clinic details document not found');
        }
      });
    } catch (e) {
      print('Error adding certification to clinic details: $e');
      throw Exception('Failed to add certification to clinic details: $e');
    }
  }

  /// Get clinic details with licenses and certifications
  Future<ClinicDetails?> getClinicDetails(String clinicId) async {
    try {
      final doc = await _firestore
          .collection(_clinicDetailsCollection)
          .doc(clinicId)
          .get();

      if (doc.exists) {
        return ClinicDetails.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting clinic details: $e');
      return null;
    }
  }

  /// Update license status
  Future<void> updateLicenseStatus({
    required String clinicId,
    required String licenseId,
    required LicenseStatus status,
    String? rejectionReason,
    String? verificationNotes,
  }) async {
    try {
      final docRef = _firestore.collection(_clinicDetailsCollection).doc(clinicId);
      
      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        
        if (doc.exists) {
          final clinicDetails = ClinicDetails.fromMap(doc.data()!);
          
          // Find and update the license
          final updatedLicenses = clinicDetails.licenses.map((license) {
            if (license.id == licenseId) {
              return license.copyWith(
                status: status,
                rejectionReason: rejectionReason,
                verificationNotes: verificationNotes,
                updatedAt: DateTime.now(),
              );
            }
            return license;
          }).toList();
          
          // Update clinic details
          final updatedClinicDetails = clinicDetails.copyWith(
            licenses: updatedLicenses,
            updatedAt: DateTime.now(),
          );
          
          transaction.update(docRef, updatedClinicDetails.toMap());
        }
      });
    } catch (e) {
      print('Error updating license status: $e');
      throw Exception('Failed to update license status: $e');
    }
  }

  /// Update certification status
  Future<void> updateCertificationStatus({
    required String clinicId,
    required String certificationId,
    required CertificationStatus status,
    String? rejectionReason,
    String? verificationNotes,
  }) async {
    try {
      final docRef = _firestore.collection(_clinicDetailsCollection).doc(clinicId);
      
      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        
        if (doc.exists) {
          final clinicDetails = ClinicDetails.fromMap(doc.data()!);
          
          // Find and update the certification
          final updatedCertifications = clinicDetails.certifications.map((cert) {
            if (cert.id == certificationId) {
              return cert.copyWith(
                status: status,
                rejectionReason: rejectionReason,
                verificationNotes: verificationNotes,
                updatedAt: DateTime.now(),
              );
            }
            return cert;
          }).toList();
          
          // Update clinic details
          final updatedClinicDetails = clinicDetails.copyWith(
            certifications: updatedCertifications,
            updatedAt: DateTime.now(),
          );
          
          transaction.update(docRef, updatedClinicDetails.toMap());
        }
      });
    } catch (e) {
      print('Error updating certification status: $e');
      throw Exception('Failed to update certification status: $e');
    }
  }

  /// Delete license and its image
  Future<void> deleteLicense({
    required String clinicId,
    required String licenseId,
  }) async {
    try {
      final docRef = _firestore.collection(_clinicDetailsCollection).doc(clinicId);
      
      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        
        if (doc.exists) {
          final clinicDetails = ClinicDetails.fromMap(doc.data()!);
          
          // Find the license to delete
          final licenseToDelete = clinicDetails.licenses.firstWhere(
            (license) => license.id == licenseId,
            orElse: () => throw Exception('License not found'),
          );
          
          // Delete image from Google Drive
          await _googleDriveService.deleteFile(licenseToDelete.licensePictureFileId);
          
          // Remove license from list
          final updatedLicenses = clinicDetails.licenses
              .where((license) => license.id != licenseId)
              .toList();
          
          // Update clinic details
          final updatedClinicDetails = clinicDetails.copyWith(
            licenses: updatedLicenses,
            updatedAt: DateTime.now(),
          );
          
          transaction.update(docRef, updatedClinicDetails.toMap());
        }
      });
    } catch (e) {
      print('Error deleting license: $e');
      throw Exception('Failed to delete license: $e');
    }
  }

  /// Delete certification and its image
  Future<void> deleteCertification({
    required String clinicId,
    required String certificationId,
  }) async {
    try {
      final docRef = _firestore.collection(_clinicDetailsCollection).doc(clinicId);
      
      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        
        if (doc.exists) {
          final clinicDetails = ClinicDetails.fromMap(doc.data()!);
          
          // Find the certification to delete
          final certificationToDelete = clinicDetails.certifications.firstWhere(
            (cert) => cert.id == certificationId,
            orElse: () => throw Exception('Certification not found'),
          );
          
          // Delete image from Google Drive if it exists
          if (certificationToDelete.documentFileId != null) {
            await _googleDriveService.deleteFile(certificationToDelete.documentFileId!);
          }
          
          // Remove certification from list
          final updatedCertifications = clinicDetails.certifications
              .where((cert) => cert.id != certificationId)
              .toList();
          
          // Update clinic details
          final updatedClinicDetails = clinicDetails.copyWith(
            certifications: updatedCertifications,
            updatedAt: DateTime.now(),
          );
          
          transaction.update(docRef, updatedClinicDetails.toMap());
        }
      });
    } catch (e) {
      print('Error deleting certification: $e');
      throw Exception('Failed to delete certification: $e');
    }
  }
}