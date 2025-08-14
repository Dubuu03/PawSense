import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../models/user_model.dart';

/// Service class for all authentication and user account related operations.
class AuthService {
  // Firebase Auth instance
  final _auth = FirebaseAuth.instance;
  // Firestore instance
  final _firestore = FirebaseFirestore.instance;

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
  /// Also sends an email verification to the new user.
  Future<String?> signUpWithEmail({
    required String email,
    required String password,
    required String username,
    required String contactNumber,
    required DateTime dateOfBirth,
    required bool agreedToTerms,
    required String address,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final cred = await _auth.createUserWithEmailAndPassword(
      email: normalizedEmail,
      password: password,
    );
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

  /// Saves or updates a user document in Firestore.
  /// Always stores the email in lowercase.
  Future<void> saveUser(UserModel user) async {
    try {
      final updatedUser = user.copyWith(email: user.email.trim().toLowerCase());
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(updatedUser.toMap());
      debugPrint('User saved: {user.uid}');
    } catch (e, stack) {
      debugPrint('Error saving user: $e\n$stack');
      rethrow;
    }
  }

  /// Signs out the current user.
  Future<void> signOut() async => _auth.signOut();

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
  Future<User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final cred = await _auth.signInWithEmailAndPassword(
      email: normalizedEmail,
      password: password,
    );
    return cred.user;
  }

  /// Sends a password reset email to the given email address.
  Future<void> sendPasswordResetEmail(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    await _auth.sendPasswordResetEmail(email: normalizedEmail);
  }

  /// Fetches the list of sign-in methods for the given email (e.g., ['password', 'google.com']).
  Future<List<String>> fetchSignInMethodsForEmail(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    return await _auth.fetchSignInMethodsForEmail(normalizedEmail);
  }
}
