import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import '../../models/user_model.dart';
import '../../models/clinic_model.dart';
import '../../models/clinic_details_model.dart';

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

  // NEW: Sign up clinic admin with all required data
  Future<AuthResult> signUpClinicAdmin({
    required String email,
    required String password,
    required String username,
    required Clinic clinic,
    required ClinicDetails clinicDetails,
    Uint8List? documentBytes,
    String? documentName,
  }) async {
    try {
      print('Starting clinic admin signup for email: $email'); // Debug print

      // Create Firebase Auth user
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        final uid = result.user!.uid;
        print('Firebase Auth user created with UID: $uid'); // Debug print

        // Upload document if provided (skip for testing)
        String? documentUrl;
        if (documentBytes != null && documentName != null) {
          print('Uploading document...'); // Debug print
          documentUrl = await _uploadDocument(uid, documentBytes, documentName);
          print('Document uploaded: $documentUrl'); // Debug print
        } else {
          print('Skipping document upload (testing mode)'); // Debug print
        }

        // Create user document with admin role
        final userModel = UserModel(
          uid: uid,
          username: username,
          email: email,
          role: 'admin',
          createdAt: DateTime.now(),
          darkTheme: false,
          agreedToTerms: true,
        );

        // Create clinic document with uid as clinic id
        final clinicWithId = clinic.copyWith(id: uid);

        // Create clinic details document with generated id and clinic id
        final clinicDetailsId = _firestore
            .collection('clinic_details')
            .doc()
            .id;
        final clinicDetailsWithIds = clinicDetails.copyWith(
          id: clinicDetailsId,
          clinicId: uid,
          documentImage: documentUrl ?? '', // Empty string if no upload
        );

        print('Preparing Firestore batch write...'); // Debug print

        // Batch write all documents
        final batch = _firestore.batch();

        // Add user document
        batch.set(_firestore.collection('users').doc(uid), userModel.toMap());

        // Add clinic document
        batch.set(
          _firestore.collection('clinics').doc(uid),
          clinicWithId.toMap(),
        );

        // Add clinic details document
        batch.set(
          _firestore.collection('clinic_details').doc(clinicDetailsId),
          clinicDetailsWithIds.toMap(),
        );

        // Commit batch
        print('Committing Firestore batch...'); // Debug print
        await batch.commit();
        print('Firestore batch committed successfully!'); // Debug print

        return AuthResult(success: true, role: 'admin', user: userModel);
      } else {
        print('Failed to create Firebase Auth user'); // Debug print
        return AuthResult(success: false, error: 'Failed to create account.');
      }
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException: ${e.code} - ${e.message}'); // Debug print
      String errorMessage;
      switch (e.code) {
        case 'weak-password':
          errorMessage = 'The password provided is too weak.';
          break;
        case 'email-already-in-use':
          errorMessage = 'An account already exists with this email address.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is not valid.';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Email/password accounts are not enabled.';
          break;
        default:
          errorMessage = 'Account creation failed. Please try again.';
      }

      return AuthResult(success: false, error: errorMessage);
    } catch (e) {
      print('General error creating clinic admin account: $e'); // Debug print

      // Cleanup: Delete auth user if Firestore operations failed
      try {
        await _auth.currentUser?.delete();
        print('Cleaned up auth user after error'); // Debug print
      } catch (cleanupError) {
        print('Error during cleanup: $cleanupError'); // Debug print
      }

      return AuthResult(
        success: false,
        error: 'Account creation failed. Please try again.',
      );
    }
  }

  // Helper method to upload document to Firebase Storage
  Future<String?> _uploadDocument(
    String uid,
    Uint8List documentBytes,
    String fileName,
  ) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final cleanFileName =
          '${timestamp}_${fileName.replaceAll(RegExp(r'[^\w\-.]'), '_')}';

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('clinic_documents')
          .child(uid)
          .child(cleanFileName);

      // Determine content type based on file extension
      String contentType = 'application/octet-stream';
      final extension = fileName.toLowerCase().split('.').last;
      switch (extension) {
        case 'jpg':
        case 'jpeg':
          contentType = 'image/jpeg';
          break;
        case 'png':
          contentType = 'image/png';
          break;
        case 'pdf':
          contentType = 'application/pdf';
          break;
      }

      final metadata = SettableMetadata(
        contentType: contentType,
        customMetadata: {
          'uploadedBy': uid,
          'uploadedAt': DateTime.now().toIso8601String(),
          'originalName': fileName,
        },
      );

      final uploadTask = await storageRef.putData(documentBytes, metadata);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading document: $e');
      return null;
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

  // Get clinic data for current admin user
  Future<Clinic?> getCurrentUserClinic() async {
    final user = currentUser;
    if (user != null) {
      return await getClinicData(user.uid);
    }
    return null;
  }

  // Get clinic data by clinic ID (uid)
  Future<Clinic?> getClinicData(String clinicId) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection('clinics')
          .doc(clinicId)
          .get();

      if (doc.exists) {
        return Clinic.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error fetching clinic data: $e');
      return null;
    }
  }

  // Get clinic details for current admin user
  Future<ClinicDetails?> getCurrentUserClinicDetails() async {
    final user = currentUser;
    if (user != null) {
      return await getClinicDetails(user.uid);
    }
    return null;
  }

  // Get clinic details by clinic ID (uid)
  Future<ClinicDetails?> getClinicDetails(String clinicId) async {
    try {
      final QuerySnapshot query = await _firestore
          .collection('clinic_details')
          .where('clinicId', isEqualTo: clinicId)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return ClinicDetails.fromMap(
          query.docs.first.data() as Map<String, dynamic>,
        );
      }
      return null;
    } catch (e) {
      print('Error fetching clinic details: $e');
      return null;
    }
  }

  // Update clinic data
  Future<bool> updateClinicData(Clinic clinic) async {
    try {
      await _firestore
          .collection('clinics')
          .doc(clinic.id)
          .update(clinic.toMap());
      return true;
    } catch (e) {
      print('Error updating clinic data: $e');
      return false;
    }
  }

  // Update clinic details
  Future<bool> updateClinicDetails(ClinicDetails clinicDetails) async {
    try {
      await _firestore
          .collection('clinic_details')
          .doc(clinicDetails.id)
          .update(clinicDetails.toMap());
      return true;
    } catch (e) {
      print('Error updating clinic details: $e');
      return false;
    }
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
