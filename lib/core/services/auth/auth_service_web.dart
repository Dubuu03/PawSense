import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';

class AuthResult {
  final bool success;
  final String? role;
  final UserModel? user;
  final String? error;

  AuthResult({required this.success, this.role, this.user, this.error});
}

class AuthServiceWeb {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign in with email and password
  Future<AuthResult> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        // Fetch user data from Firestore to get role
        final userData = await _getUserData(result.user!.uid);

        if (userData != null) {
          // Check if user has admin or super_admin role
          if (userData.role == 'admin' || userData.role == 'super_admin') {
            return AuthResult(
              success: true,
              role: userData.role,
              user: userData,
            );
          } else {
            // Sign out user if they don't have proper permissions
            await signOut();
            return AuthResult(
              success: false,
              error:
                  'Access denied. You do not have administrative privileges.',
            );
          }
        } else {
          await signOut();
          return AuthResult(
            success: false,
            error: 'User data not found. Please contact your administrator.',
          );
        }
      } else {
        return AuthResult(success: false, error: 'Authentication failed.');
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found with this email address.';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password.';
          break;
        case 'user-disabled':
          errorMessage = 'This account has been disabled.';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many failed attempts. Please try again later.';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address.';
          break;
        default:
          errorMessage = 'Login failed. Please try again.';
      }

      return AuthResult(success: false, error: errorMessage);
    } catch (e) {
      return AuthResult(
        success: false,
        error: 'An unexpected error occurred. Please try again.',
      );
    }
  }

  // Get user data from Firestore
  Future<UserModel?> _getUserData(String uid) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .get();

      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error fetching user data: $e');
      return null;
    }
  }

  // Get current user data with role
  Future<UserModel?> getCurrentUserData() async {
    final user = currentUser;
    if (user != null) {
      return await _getUserData(user.uid);
    }
    return null;
  }

  // Check if current user is admin
  Future<bool> isAdmin() async {
    final userData = await getCurrentUserData();
    return userData?.role == 'admin';
  }

  // Check if current user is super admin
  Future<bool> isSuperAdmin() async {
    final userData = await getCurrentUserData();
    return userData?.role == 'super_admin';
  }

  // Check if current user has admin privileges (admin or super_admin)
  Future<bool> hasAdminPrivileges() async {
    final userData = await getCurrentUserData();
    return userData?.role == 'admin' || userData?.role == 'super_admin';
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
      throw e;
    }
  }

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Check if user is signed in
  bool get isSignedIn => currentUser != null;
}
