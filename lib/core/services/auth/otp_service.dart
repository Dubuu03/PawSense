import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Service class for OTP generation, storage, and validation
/// Stores OTPs in Firestore with expiration times
class OTPService {
  final _firestore = FirebaseFirestore.instance;
  static const String _otpCollection = 'otp_codes';
  static const int _otpLength = 6;
  static const int _expirationMinutes = 10; // OTP expires in 10 minutes
  static const int _maxAttempts = 5; // Maximum validation attempts

  /// Generates a 6-digit OTP code
  String _generateOTP() {
    final random = Random();
    String otp = '';
    for (int i = 0; i < _otpLength; i++) {
      otp += random.nextInt(10).toString();
    }
    return otp;
  }

  /// Creates and stores an OTP for the given email and purpose
  /// Returns the generated OTP code
  Future<String> createOTP({
    required String email,
    required OTPPurpose purpose,
  }) async {
    try {
      final otp = _generateOTP();
      final normalizedEmail = email.trim().toLowerCase();
      final docId = '${normalizedEmail}_${purpose.name}';
      
      // Delete any existing OTP for this email and purpose
      await deleteOTP(email: normalizedEmail, purpose: purpose);
      
      final otpData = {
        'email': normalizedEmail,
        'purpose': purpose.name,
        'code': otp,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': DateTime.now().add(const Duration(minutes: _expirationMinutes)),
        'attempts': 0,
        'maxAttempts': _maxAttempts,
        'isUsed': false,
      };

      await _firestore
          .collection(_otpCollection)
          .doc(docId)
          .set(otpData);

      debugPrint('🔑 OTP created for $normalizedEmail (${purpose.name}): $otp');
      return otp;
    } catch (e) {
      debugPrint('❌ Error creating OTP: $e');
      rethrow;
    }
  }

  /// Validates an OTP code for the given email and purpose
  /// Returns OTPValidationResult with success status and message
  Future<OTPValidationResult> validateOTP({
    required String email,
    required String code,
    required OTPPurpose purpose,
  }) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();
      final docId = '${normalizedEmail}_${purpose.name}';
      
      final doc = await _firestore
          .collection(_otpCollection)
          .doc(docId)
          .get();

      if (!doc.exists) {
        return OTPValidationResult(
          isValid: false,
          message: 'No OTP found. Please request a new code.',
          shouldDeleteOTP: false,
        );
      }

      final data = doc.data() as Map<String, dynamic>;
      final storedCode = data['code'] as String;
      final expiresAt = (data['expiresAt'] as Timestamp).toDate();
      final attempts = (data['attempts'] as int? ?? 0);
      final maxAttempts = (data['maxAttempts'] as int? ?? _maxAttempts);
      final isUsed = data['isUsed'] as bool? ?? false;

      // Check if OTP is already used
      if (isUsed) {
        return OTPValidationResult(
          isValid: false,
          message: 'This OTP has already been used. Please request a new code.',
          shouldDeleteOTP: true,
        );
      }

      // Check if OTP has expired
      if (DateTime.now().isAfter(expiresAt)) {
        await deleteOTP(email: normalizedEmail, purpose: purpose);
        return OTPValidationResult(
          isValid: false,
          message: 'OTP has expired. Please request a new code.',
          shouldDeleteOTP: true,
        );
      }

      // Check if max attempts exceeded
      if (attempts >= maxAttempts) {
        await deleteOTP(email: normalizedEmail, purpose: purpose);
        return OTPValidationResult(
          isValid: false,
          message: 'Too many incorrect attempts. Please request a new code.',
          shouldDeleteOTP: true,
        );
      }

      // Validate the code
      if (code.trim() == storedCode) {
        // Mark as used
        await _firestore
            .collection(_otpCollection)
            .doc(docId)
            .update({'isUsed': true});

        debugPrint('✅ OTP validated successfully for $normalizedEmail');
        return OTPValidationResult(
          isValid: true,
          message: 'OTP verified successfully.',
          shouldDeleteOTP: false,
        );
      } else {
        // Increment attempt count
        await _firestore
            .collection(_otpCollection)
            .doc(docId)
            .update({'attempts': attempts + 1});

        final remainingAttempts = maxAttempts - (attempts + 1);
        return OTPValidationResult(
          isValid: false,
          message: remainingAttempts > 0 
              ? 'Invalid OTP. $remainingAttempts attempts remaining.'
              : 'Invalid OTP. Maximum attempts exceeded.',
          shouldDeleteOTP: remainingAttempts <= 0,
        );
      }
    } catch (e) {
      debugPrint('❌ Error validating OTP: $e');
      return OTPValidationResult(
        isValid: false,
        message: 'Error validating OTP. Please try again.',
        shouldDeleteOTP: false,
      );
    }
  }

  /// Deletes an OTP for the given email and purpose
  Future<void> deleteOTP({
    required String email,
    required OTPPurpose purpose,
  }) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();
      final docId = '${normalizedEmail}_${purpose.name}';
      
      await _firestore
          .collection(_otpCollection)
          .doc(docId)
          .delete();

      debugPrint('🗑️ OTP deleted for $normalizedEmail (${purpose.name})');
    } catch (e) {
      debugPrint('❌ Error deleting OTP: $e');
    }
  }

  /// Checks if an OTP exists and is still valid for the given email and purpose
  Future<bool> hasValidOTP({
    required String email,
    required OTPPurpose purpose,
  }) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();
      final docId = '${normalizedEmail}_${purpose.name}';
      
      final doc = await _firestore
          .collection(_otpCollection)
          .doc(docId)
          .get();

      if (!doc.exists) return false;

      final data = doc.data() as Map<String, dynamic>;
      final expiresAt = (data['expiresAt'] as Timestamp).toDate();
      final isUsed = data['isUsed'] as bool? ?? false;

      return !isUsed && DateTime.now().isBefore(expiresAt);
    } catch (e) {
      debugPrint('❌ Error checking OTP validity: $e');
      return false;
    }
  }

  /// Gets the remaining time in seconds for an OTP
  Future<int> getRemainingTime({
    required String email,
    required OTPPurpose purpose,
  }) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();
      final docId = '${normalizedEmail}_${purpose.name}';
      
      final doc = await _firestore
          .collection(_otpCollection)
          .doc(docId)
          .get();

      if (!doc.exists) return 0;

      final data = doc.data() as Map<String, dynamic>;
      final expiresAt = (data['expiresAt'] as Timestamp).toDate();
      final isUsed = data['isUsed'] as bool? ?? false;

      if (isUsed) return 0;

      final remaining = expiresAt.difference(DateTime.now()).inSeconds;
      return remaining > 0 ? remaining : 0;
    } catch (e) {
      debugPrint('❌ Error getting remaining time: $e');
      return 0;
    }
  }

  /// Cleans up expired OTPs (should be called periodically)
  Future<void> cleanupExpiredOTPs() async {
    try {
      final now = DateTime.now();
      final query = await _firestore
          .collection(_otpCollection)
          .where('expiresAt', isLessThan: now)
          .get();

      final batch = _firestore.batch();
      for (final doc in query.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      debugPrint('🧹 Cleaned up ${query.docs.length} expired OTPs');
    } catch (e) {
      debugPrint('❌ Error cleaning up expired OTPs: $e');
    }
  }
}

/// Enum for different OTP purposes
enum OTPPurpose {
  passwordReset,
  emailVerification,
  accountVerification,
}

/// Result class for OTP validation
class OTPValidationResult {
  final bool isValid;
  final String message;
  final bool shouldDeleteOTP;

  const OTPValidationResult({
    required this.isValid,
    required this.message,
    required this.shouldDeleteOTP,
  });
}