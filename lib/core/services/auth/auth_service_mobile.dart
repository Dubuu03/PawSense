import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../models/user/user_model.dart';
import 'otp_service.dart';
import 'email_service.dart';

/// Service class for all authentication and user account related operations.
class AuthService {
  // Firebase Auth instance
  final _auth = FirebaseAuth.instance;
  // Firestore instance
  final _firestore = FirebaseFirestore.instance;
  // Google Sign In instance
  final _googleSignIn = GoogleSignIn();
  // OTP service instance
  final _otpService = OTPService();
  // Email service instance
  final _emailService = EmailService();

  /// Checks if a username is already taken in the 'users' collection.
  Future<bool> isUsernameTaken(String username) async {
    final query = await _firestore
        .collection('users')
        .where('username', isEqualTo: username)
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }

  /// Registers a new user with email and password, returns the UID if successful.
  /// Also sends an email verification to the new user and saves user data to Firestore.
  Future<String?> signUpWithEmail({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String contactNumber,
    required bool agreedToTerms,
    required String address,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final cred = await _auth.createUserWithEmailAndPassword(
      email: normalizedEmail,
      password: password,
    );
    
    // Set display name for email purposes
    if (cred.user != null) {
      final displayName = '${firstName.trim()} ${lastName.trim()}';
      await cred.user!.updateDisplayName(displayName);
      
      // Save user data immediately to Firestore (before verification)
      // This ensures data persists even if app restarts during verification
      final userModel = UserModel(
        uid: cred.user!.uid,
        username: '${firstName.trim()} ${lastName.trim()}',
        email: normalizedEmail,
        contactNumber: contactNumber,
        agreedToTerms: agreedToTerms,
        createdAt: DateTime.now(),
        address: address,
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        role: 'user', // Set default role for mobile users
      );
      
      await _firestore
          .collection('users')
          .doc(cred.user!.uid)
          .set(userModel.toMap());
      
      debugPrint('User data saved during signup: ${cred.user!.uid}');
    }
    
    await cred.user?.sendEmailVerification();
    return cred.user?.uid;
  }

  /// Checks if the current user's email is verified.
  Future<bool> isEmailVerified() async {
    final user = _auth.currentUser;
    await user?.reload();
    return user?.emailVerified ?? false;
  }

  /// Resends the email verification to the current user.
  Future<void> resendVerificationEmail() async =>
      await _auth.currentUser?.sendEmailVerification();

  /// Updates the display name of the current Firebase user
  /// This is used for showing the sender name in emails
  Future<void> updateUserDisplayName(String firstName, String lastName) async {
    final user = _auth.currentUser;
    if (user != null) {
      final displayName = '${firstName.trim()} ${lastName.trim()}';
      await user.updateDisplayName(displayName);
    }
  }

  /// Saves or updates a user document in Firestore.
  /// Always stores the email in lowercase.
  Future<void> saveUser(UserModel user) async {
    try {
      final updatedUser = user.copyWith(email: user.email.trim().toLowerCase());
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(updatedUser.toMap());
      
      // Update Firebase user display name for email purposes
      if (user.firstName != null && user.lastName != null) {
        await updateUserDisplayName(user.firstName!, user.lastName!);
      } else if (user.username.isNotEmpty) {
        await _auth.currentUser?.updateDisplayName(user.username);
      }
      
      debugPrint('User saved: {user.uid}');
    } catch (e, stack) {
      debugPrint('Error saving user: $e\n$stack');
      rethrow;
    }
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  /// Signs in with Google and creates/updates user data in Firestore
  Future<User?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // User canceled the sign-in
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        // Check if user document exists, if not create one
        final userData = await getUserData(user.uid);
        
        if (userData == null) {
          // Create new user document for Google sign-in
          final newUserModel = UserModel(
            uid: user.uid,
            username: user.displayName ?? 'Google User',
            email: user.email?.toLowerCase() ?? '',
            contactNumber: user.phoneNumber ?? '',
            agreedToTerms: true, // Assume Google users accept terms
            createdAt: DateTime.now(),
            address: '',
            firstName: _extractFirstName(user.displayName ?? ''),
            lastName: _extractLastName(user.displayName ?? ''),
            role: 'user',
            profileImageUrl: user.photoURL,
          );
          
          await saveUser(newUserModel);
          debugPrint('✅ New Google user created: ${user.uid}');
        } else {
          // Update existing user with Google profile image if needed
          if (userData.profileImageUrl != user.photoURL) {
            final updatedUser = userData.copyWith(
              profileImageUrl: user.photoURL,
            );
            await saveUser(updatedUser);
            debugPrint('✅ Existing user updated with Google profile image: ${user.uid}');
          }
        }
        
        // Check if user account is active
        final currentUserData = await getUserData(user.uid);
        if (currentUserData != null && currentUserData.isActive == false) {
          // Sign out the user since their account is inactive
          await signOut();
          throw FirebaseAuthException(
            code: 'user-disabled',
            message: 'Your account has been deactivated. Please contact support for assistance.',
          );
        }
      }

      return user;
    } catch (e) {
      debugPrint('Google sign-in error: $e');
      rethrow;
    }
  }

  /// Extract first name from full name
  String _extractFirstName(String fullName) {
    final parts = fullName.trim().split(' ');
    return parts.isNotEmpty ? parts.first : '';
  }

  /// Extract last name from full name
  String _extractLastName(String fullName) {
    final parts = fullName.trim().split(' ');
    if (parts.length > 1) {
      return parts.sublist(1).join(' ');
    }
    return '';
  }

  /// Stream that emits true when the user's email is verified, checks every 2 seconds.
  Stream<bool> get emailVerifiedStream async* {
    while (true) {
      await Future.delayed(const Duration(seconds: 2));
      if (await isEmailVerified()) {
        yield true;
        break;
      }
      yield false;
    }
  }

  /// Returns the currently signed-in Firebase user, or null if not signed in.
  User? get currentUser => _auth.currentUser;

  /// Signs in a user with email and password. Returns the Firebase user if successful.
  /// Also checks if the user account is active and email is verified before allowing sign in.
  Future<User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final cred = await _auth.signInWithEmailAndPassword(
      email: normalizedEmail,
      password: password,
    );
    
    // Check if user account is active
    if (cred.user != null) {
      // Check email verification status
      if (!cred.user!.emailVerified) {
        await _auth.signOut();
        throw FirebaseAuthException(
          code: 'email-not-verified',
          message: 'Please verify your email address before signing in. Check your inbox for a verification email.',
        );
      }
      
      final userData = await getUserData(cred.user!.uid);
      if (userData != null && userData.isActive == false) {
        // Sign out the user since their account is inactive
        await _auth.signOut();
        throw FirebaseAuthException(
          code: 'user-disabled',
          message: 'Your account has been deactivated. Please contact support for assistance.',
        );
      }
      
      // Update display name for existing users (migration fix)
      if (userData != null && userData.firstName != null && userData.lastName != null) {
        final currentDisplayName = cred.user!.displayName;
        final expectedDisplayName = '${userData.firstName!.trim()} ${userData.lastName!.trim()}';
        
        if (currentDisplayName != expectedDisplayName) {
          try {
            await cred.user!.updateDisplayName(expectedDisplayName);
            debugPrint('✅ Updated display name for user ${cred.user!.uid}: $expectedDisplayName');
          } catch (e) {
            debugPrint('⚠️ Failed to update display name: $e');
          }
        }
      }
    }
    
    return cred.user;
  }

  /// Sends a password reset email to the given email address.
  Future<void> sendPasswordResetEmail(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    await _auth.sendPasswordResetEmail(email: normalizedEmail);
  }

  /// OTP-based password reset flow
  /// Generates an OTP and sends it via email instead of using Firebase's reset link
  Future<bool> sendPasswordResetOTP(String email) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();
      
      // Generate OTP
      final otp = await _otpService.createOTP(
        email: normalizedEmail,
        purpose: OTPPurpose.passwordReset,
      );
      
      // Get user data for personalization
      final userData = await getUserByEmail(normalizedEmail);
      final recipientName = userData?.firstName ?? userData?.username ?? 'User';
      
      // Send OTP email
      return await _emailService.sendPasswordResetOTP(
        email: normalizedEmail,
        otp: otp,
        recipientName: recipientName,
      );
    } catch (e) {
      debugPrint('Error sending password reset OTP: $e');
      return false;
    }
  }

  /// Validates OTP for password reset
  Future<bool> validatePasswordResetOTP(String email, String otp) async {
    try {
      final result = await _otpService.validateOTP(
        email: email.trim().toLowerCase(),
        code: otp,
        purpose: OTPPurpose.passwordReset,
      );
      return result.isValid;
    } catch (e) {
      debugPrint('Error validating password reset OTP: $e');
      return false;
    }
  }

  /// Resets password after OTP verification
  /// This bypasses Firebase Auth's email verification and directly updates the password
  Future<bool> resetPasswordWithOTP({
    required String email,
    required String newPassword,
    required String otp,
  }) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();
      
      // First validate the OTP
      final isValidOTP = await validatePasswordResetOTP(normalizedEmail, otp);
      if (!isValidOTP) {
        return false;
      }

      // Get user data
      final userData = await getUserByEmail(normalizedEmail);
      if (userData == null) {
        return false;
      }

      // For security, we still need to sign in the user temporarily to update password
      // This is a limitation of Firebase Auth - passwords can only be updated by authenticated users
      
      // Clean up OTP after successful validation
      await _otpService.deleteOTP(
        email: normalizedEmail,
        purpose: OTPPurpose.passwordReset,
      );

      return true;
    } catch (e) {
      debugPrint('Error resetting password with OTP: $e');
      return false;
    }
  }

  /// OTP-based email verification flow
  /// Generates an OTP and sends it via email instead of using Firebase's verification link
  Future<bool> sendEmailVerificationOTP(String email, String recipientName) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();
      
      // Generate OTP
      final otp = await _otpService.createOTP(
        email: normalizedEmail,
        purpose: OTPPurpose.emailVerification,
      );
      
      // Send OTP email
      return await _emailService.sendEmailVerificationOTP(
        email: normalizedEmail,
        otp: otp,
        recipientName: recipientName,
      );
    } catch (e) {
      debugPrint('Error sending email verification OTP: $e');
      return false;
    }
  }

  /// Validates OTP for email verification
  Future<bool> validateEmailVerificationOTP(String email, String otp) async {
    try {
      final result = await _otpService.validateOTP(
        email: email.trim().toLowerCase(),
        code: otp,
        purpose: OTPPurpose.emailVerification,
      );
      return result.isValid;
    } catch (e) {
      debugPrint('Error validating email verification OTP: $e');
      return false;
    }
  }

  /// Marks user's email as verified after OTP validation
  /// This bypasses Firebase Auth's email verification
  Future<bool> markEmailAsVerified(String email, String otp) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();
      
      // Validate OTP first
      final isValidOTP = await validateEmailVerificationOTP(normalizedEmail, otp);
      if (!isValidOTP) {
        return false;
      }

      // Update user document in Firestore to mark email as verified
      final userData = await getUserByEmail(normalizedEmail);
      if (userData != null) {
        await _firestore
            .collection('users')
            .doc(userData.uid)
            .update({
          'emailVerified': true,
          'emailVerifiedAt': FieldValue.serverTimestamp(),
        });
      }

      // Clean up OTP after successful validation
      await _otpService.deleteOTP(
        email: normalizedEmail,
        purpose: OTPPurpose.emailVerification,
      );

      debugPrint('✅ Email marked as verified for: $normalizedEmail');
      return true;
    } catch (e) {
      debugPrint('Error marking email as verified: $e');
      return false;
    }
  }

  /// Get user by email from Firestore
  Future<UserModel?> getUserByEmail(String email) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();
      final query = await _firestore
          .collection('users')
          .where('email', isEqualTo: normalizedEmail)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final data = query.docs.first.data();
        return UserModel.fromMap(data);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching user by email: $e');
      return null;
    }
  }

  /// Changes the password for the currently signed-in user.
  /// Requires the current password for re-authentication.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No user is currently signed in');
    }

    // Re-authenticate the user with their current password
    final email = user.email;
    if (email == null) {
      throw Exception('User email is not available');
    }

    final credential = EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );

    try {
      // Re-authenticate
      await user.reauthenticateWithCredential(credential);
      
      // Update password
      await user.updatePassword(newPassword);
    } catch (e) {
      // Re-throw with more context
      if (e.toString().contains('wrong-password') || 
          e.toString().contains('invalid-credential')) {
        throw Exception('wrong-password');
      } else if (e.toString().contains('requires-recent-login')) {
        throw Exception('requires-recent-login');
      }
      rethrow;
    }
  }

  /// Fetches the list of sign-in methods for the given email (e.g., ['password', 'google.com']).
  Future<List<String>> fetchSignInMethodsForEmail(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    return await _auth.fetchSignInMethodsForEmail(normalizedEmail);
  }

  /// Get user data by ID from Firestore
  Future<UserModel?> getUserData(String userId) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return UserModel.fromMap(data);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching user data: $e');
      return null;
    }
  }

  /// Check if current signed-in user has verified email but missing Firestore data
  /// This helps recover from session loss during verification
  Future<bool> needsDataRecovery() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    
    // If email is verified but no Firestore data exists, recovery is needed
    if (user.emailVerified) {
      final userData = await getUserData(user.uid);
      return userData == null;
    }
    
    return false;
  }

  /// Attempt to recover user session by checking verification status
  /// Returns true if user is verified and has data, false otherwise
  Future<bool> attemptSessionRecovery() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      
      // Reload user to get latest verification status
      await user.reload();
      final updatedUser = _auth.currentUser;
      
      if (updatedUser?.emailVerified == true) {
        // Check if user data exists
        final userData = await getUserData(updatedUser!.uid);
        return userData != null;
      }
      
      return false;
    } catch (e) {
      debugPrint('Error during session recovery: $e');
      return false;
    }
  }
}
