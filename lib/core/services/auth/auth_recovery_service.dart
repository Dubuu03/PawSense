import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../models/user/user_model.dart';
import 'auth_service_mobile.dart';
import '../../guards/auth_guard.dart';

/// Service to handle authentication recovery scenarios
/// This helps recover user sessions when the app is restarted during email verification
class AuthRecoveryService {
  static final AuthRecoveryService _instance = AuthRecoveryService._internal();
  factory AuthRecoveryService() => _instance;
  AuthRecoveryService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthService _authService = AuthService();

  /// Check for authentication recovery on app startup
  /// This should be called early in the app initialization
  Future<AuthRecoveryResult> checkForRecovery() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return AuthRecoveryResult(
          needsRecovery: false,
          isComplete: false,
          message: 'No user session found',
        );
      }

      // Reload user to get latest verification status
      await user.reload();
      final updatedUser = _auth.currentUser;

      if (updatedUser == null) {
        return AuthRecoveryResult(
          needsRecovery: false,
          isComplete: false,
          message: 'User session expired',
        );
      }

      // Check if email is verified but no Firestore data exists
      if (updatedUser.emailVerified) {
        final userData = await _authService.getUserData(updatedUser.uid);
        
        if (userData != null) {
          // User has verified email and Firestore data - recovery complete
          debugPrint('✅ AuthRecovery: User session is complete');
          return AuthRecoveryResult(
            needsRecovery: false,
            isComplete: true,
            userData: userData,
            message: 'User session is valid',
          );
        } else {
          // User has verified email but no Firestore data - needs recovery
          debugPrint('⚠️ AuthRecovery: User needs data recovery (verified but no Firestore data)');
          return AuthRecoveryResult(
            needsRecovery: true,
            isComplete: false,
            firebaseUser: updatedUser,
            message: 'Email verified but user data missing',
          );
        }
      } else {
        // User exists but email not verified - normal verification flow
        debugPrint('ℹ️ AuthRecovery: User exists but email not verified');
        return AuthRecoveryResult(
          needsRecovery: false,
          isComplete: false,
          firebaseUser: updatedUser,
          message: 'Email verification pending',
        );
      }
    } catch (e) {
      debugPrint('❌ AuthRecovery: Error during recovery check: $e');
      return AuthRecoveryResult(
        needsRecovery: false,
        isComplete: false,
        message: 'Recovery check failed: $e',
      );
    }
  }

  /// Attempt to recover user data from incomplete session
  /// This is used when Firebase user exists and is verified but Firestore data is missing
  Future<bool> attemptDataRecovery(User firebaseUser, {
    String? firstName,
    String? lastName,
    String? contactNumber,
    String? address,
  }) async {
    try {
      debugPrint('🔄 AuthRecovery: Attempting data recovery for user ${firebaseUser.uid}');

      // Try to extract name from display name if available
      String? recoveredFirstName = firstName;
      String? recoveredLastName = lastName;
      
      if (recoveredFirstName == null && firebaseUser.displayName != null) {
        final nameParts = firebaseUser.displayName!.trim().split(' ');
        if (nameParts.isNotEmpty) {
          recoveredFirstName = nameParts.first;
          if (nameParts.length > 1) {
            recoveredLastName = nameParts.sublist(1).join(' ');
          }
        }
      }

      // Create user data with available information
      final userModel = UserModel(
        uid: firebaseUser.uid,
        username: recoveredFirstName != null && recoveredLastName != null 
          ? '$recoveredFirstName $recoveredLastName'
          : firebaseUser.email ?? firebaseUser.uid,
        email: firebaseUser.email ?? '',
        contactNumber: contactNumber ?? '',
        agreedToTerms: true, // Assume true since they went through signup
        createdAt: DateTime.now(),
        address: address ?? '',
        firstName: recoveredFirstName ?? '',
        lastName: recoveredLastName ?? '',
        role: 'user',
      );

      // Save to Firestore
      await _authService.saveUser(userModel);
      
      // Clear any stale cache
      AuthGuard.clearUserCache();
      
      debugPrint('✅ AuthRecovery: Data recovery successful for user ${firebaseUser.uid}');
      return true;
    } catch (e) {
      debugPrint('❌ AuthRecovery: Data recovery failed: $e');
      return false;
    }
  }

  /// Show recovery dialog to user for missing information
  /// Returns user data if provided, null if cancelled
  Future<Map<String, String>?> showRecoveryDialog() async {
    // This would show a dialog asking user to re-enter their information
    // For now, we'll return empty data and let them complete profile later
    return <String, String>{};
  }
}

/// Result of authentication recovery check
class AuthRecoveryResult {
  final bool needsRecovery;
  final bool isComplete;
  final UserModel? userData;
  final User? firebaseUser;
  final String message;

  AuthRecoveryResult({
    required this.needsRecovery,
    required this.isComplete,
    this.userData,
    this.firebaseUser,
    required this.message,
  });
}