import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../models/user_model.dart';
class AuthService {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  Future<String?> signUpWithEmail({
    required String email,
    required String password,
    required String username,
    required String contactNumber,
    required DateTime dateOfBirth,
    required bool agreedToTerms,
    required String address,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await cred.user?.sendEmailVerification();
    return cred.user?.uid;
  }

  Future<bool> isEmailVerified() async {
    final user = _auth.currentUser;
    await user?.reload();
    return user?.emailVerified ?? false;
  }

  Future<void> resendVerificationEmail() async =>
      await _auth.currentUser?.sendEmailVerification();

  Future<void> saveUser(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.uid).set(user.toMap());
      debugPrint('User saved: ${user.uid}');
    } catch (e, stack) {
      debugPrint('Error saving user: $e\n$stack');
      rethrow;
    }
  }

  Future<void> signOut() async => _auth.signOut();

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

  User? get currentUser => _auth.currentUser;

  Future<User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return cred.user;
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<List<String>> fetchSignInMethodsForEmail(String email) async {
    return await _auth.fetchSignInMethodsForEmail(email);
  }
}
