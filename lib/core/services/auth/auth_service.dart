import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../models/clinic_model.dart';
import '../../guards/auth_guard.dart';
import 'token_manager.dart';

/// Comprehensive authentication service that integrates with all models
class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final TokenManager _tokenManager = TokenManager();

  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  /// Get current Firebase user
  User? get currentUser => _auth.currentUser;

  /// Get current authenticated user with full profile
  Future<UserModel?> getCurrentUser() async {
    return await AuthGuard.getCurrentUser();
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    return await AuthGuard.isAuthenticated();
  }

  /// Check if user has specific role
  Future<bool> hasRole(String role) async {
    return await AuthGuard.hasRole(role);
  }

  /// Check if user has admin privileges
  Future<bool> hasAdminPrivileges() async {
    return await AuthGuard.hasAdminPrivileges();
  }

  /// Check if user is super admin
  Future<bool> isSuperAdmin() async {
    return await AuthGuard.isSuperAdmin();
  }

  /// Check if user has specific permission
  Future<bool> hasPermission(String permission) async {
    return await AuthGuard.hasPermission(permission);
  }

  /// Get user's clinic data
  Future<Clinic?> getUserClinic() async {
    final user = await getCurrentUser();
    if (user == null) return null;
    
    return await AuthGuard.getUserClinic(user.uid);
  }

  /// Check if user can access specific clinic
  Future<bool> canAccessClinic(String clinicId) async {
    return await AuthGuard.canAccessClinic(clinicId);
  }

  /// Check if user can manage clinic services
  Future<bool> canManageClinicServices(String clinicId) async {
    return await AuthGuard.canManageClinicServices(clinicId);
  }

  /// Check if user can manage certifications
  Future<bool> canManageCertifications() async {
    return await AuthGuard.canManageCertifications();
  }

  /// Sign out current user
  Future<void> signOut() async {
    _tokenManager.clearToken();
    await _auth.signOut();
  }

  /// Sign in with email and password
  Future<AuthResult> signInWithEmailPassword(String email, String password) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        // Get user data from Firestore
        final userData = await AuthGuard.getCurrentUser();
        if (userData != null) {
          return AuthResult(
            success: true, 
            role: userData.role,
            user: userData,
          );
        } else {
          // User exists in Auth but not in Firestore
          await _auth.signOut();
          return AuthResult(
            success: false, 
            error: 'Account data not found. Please contact support.',
          );
        }
      } else {
        return AuthResult(success: false, error: 'Sign in failed. Please try again.');
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No account found with this email address.';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password. Please try again.';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address format.';
          break;
        case 'user-disabled':
          errorMessage = 'This account has been disabled.';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many failed attempts. Please try again later.';
          break;
        case 'invalid-credential':
          errorMessage = 'Invalid email or password. Please check your credentials.';
          break;
        default:
          errorMessage = 'Sign in failed: ${e.message}';
          break;
      }
      return AuthResult(success: false, error: errorMessage);
    } catch (e) {
      return AuthResult(success: false, error: 'An unexpected error occurred. Please try again.');
    }
  }

  /// Sign up clinic admin with separated clinic and clinic details creation
  Future<AuthResult> signUpClinicAdmin({
    required String email,
    required String password,
    required String username,
    required String? firstName,
    required String? lastName,
    required String? contactNumber,
    required Clinic clinic,
    required Map<String, dynamic> clinicDetailsData,
  }) async {
    try {
      // Step 1: Create Firebase Auth user
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        final uid = result.user!.uid;

        // Step 2: Create user document with admin role
        final userModel = UserModel(
          uid: uid,
          username: username,
          email: email,
          role: 'admin',
          createdAt: DateTime.now(),
          darkTheme: false,
          agreedToTerms: true,
          contactNumber: contactNumber,
          firstName: firstName,
          lastName: lastName,
        );

        // Step 3: Create basic user profile first
        await _createUserProfile(uid, userModel);

        // Step 4: Create clinic with proper clinic ID assignment
        final createdClinic = await _createClinic(uid, clinic);
        if (!createdClinic) {
          throw Exception('Failed to create clinic data');
        }

        // Step 5: Create clinic details with proper ID assignment and services
        final createdClinicDetails = await _createClinicDetails(uid, clinicDetailsData);
        if (!createdClinicDetails) {
          throw Exception('Failed to create clinic details');
        }

        return AuthResult(success: true, role: 'admin', user: userModel);
      } else {
        return AuthResult(success: false, error: 'Failed to create account.');
      }
    } on FirebaseAuthException catch (e) {
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
          break;
      }
      return AuthResult(success: false, error: errorMessage);
    } catch (e) {
      // Cleanup: Delete auth user if Firestore operations failed
      try {
        await _auth.currentUser?.delete();
      } catch (cleanupError) {
        print('Failed to cleanup auth user: $cleanupError');
      }
      return AuthResult(success: false, error: e.toString());
    }
  }

  /// Create user profile document
  Future<void> _createUserProfile(String uid, UserModel userModel) async {
    try {
      await _firestore.collection('users').doc(uid).set(userModel.toMap());
      print('✅ User profile created successfully for: $uid');
    } catch (e) {
      print('❌ Failed to create user profile: $e');
      throw Exception('Failed to create user profile: $e');
    }
  }

  /// Create clinic document with proper ID assignment
  Future<bool> _createClinic(String uid, Clinic clinic) async {
    try {
      // Create clinic with uid as both id and userId
      final clinicWithId = clinic.copyWith(
        id: uid,
        userId: uid,
      );

      await _firestore.collection('clinics').doc(uid).set(clinicWithId.toMap());
      print('✅ Clinic created successfully for: $uid');
      print('   Clinic Name: ${clinic.clinicName}');
      print('   Clinic ID: $uid');
      
      return true;
    } catch (e) {
      print('❌ Failed to create clinic: $e');
      return false;
    }
  }

  /// Create clinic details with proper ID assignment and services
  Future<bool> _createClinicDetails(String uid, Map<String, dynamic> clinicDetailsData) async {
    try {
      // Generate unique clinic details document ID
      final clinicDetailsId = _firestore.collection('clinicDetails').doc().id;
      
      // Prepare clinic details with proper IDs
      final clinicDetailsWithIds = {
        ...clinicDetailsData,
        'id': clinicDetailsId,
        'clinicId': uid, // Set proper clinic ID
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      // Update services and certifications with proper clinic ID
      if (clinicDetailsWithIds['services'] != null) {
        final services = List<Map<String, dynamic>>.from(clinicDetailsWithIds['services']);
        for (int i = 0; i < services.length; i++) {
          services[i]['clinicId'] = uid; // Set proper clinic ID for each service
          print('   Service ${i + 1}: ${services[i]['serviceName']} (ID: ${services[i]['id']})');
        }
        clinicDetailsWithIds['services'] = services;
      }

      if (clinicDetailsWithIds['certifications'] != null) {
        final certifications = List<Map<String, dynamic>>.from(clinicDetailsWithIds['certifications']);
        for (int i = 0; i < certifications.length; i++) {
          certifications[i]['clinicId'] = uid; // Set proper clinic ID for each certification
          print('   Certification ${i + 1}: ${certifications[i]['name']} (ID: ${certifications[i]['id']})');
        }
        clinicDetailsWithIds['certifications'] = certifications;
      }

      await _firestore.collection('clinicDetails').doc(clinicDetailsId).set(clinicDetailsWithIds);
      
      print('✅ Clinic details created successfully');
      print('   Clinic Details ID: $clinicDetailsId');
      print('   Linked to Clinic ID: $uid');
      print('   Services count: ${(clinicDetailsWithIds['services'] as List?)?.length ?? 0}');
      print('   Certifications count: ${(clinicDetailsWithIds['certifications'] as List?)?.length ?? 0}');
      
      return true;
    } catch (e) {
      print('❌ Failed to create clinic details: $e');
      return false;
    }
  }

  /// Get user data by ID
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
      return null;
    }
  }

  /// Get clinic data by clinic ID
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
      return null;
    }
  }

  /// Get clinic details by clinic ID
  Future<Map<String, dynamic>?> getClinicDetails(String clinicId) async {
    try {
      final QuerySnapshot query = await _firestore
          .collection('clinicDetails')
          .where('clinicId', isEqualTo: clinicId)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return query.docs.first.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Update clinic data
  Future<bool> updateClinicData(Clinic clinic) async {
    try {
      // Check if user has permission to update this clinic
      if (!await canAccessClinic(clinic.id)) {
        return false;
      }

      await _firestore
          .collection('clinics')
          .doc(clinic.id)
          .update(clinic.toMap());
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Update clinic details
  Future<bool> updateClinicDetails(String clinicId, Map<String, dynamic> data) async {
    try {
      // Check if user has permission to update this clinic
      if (!await canAccessClinic(clinicId)) {
        return false;
      }

      // Find the clinic details document
      final query = await _firestore
          .collection('clinicDetails')
          .where('clinicId', isEqualTo: clinicId)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        await query.docs.first.reference.update(data);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Get auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Check if user is signed in
  bool get isSignedIn => currentUser != null;

  /// Get authentication token
  Future<String?> getAuthToken({bool forceRefresh = false}) async {
    return await _tokenManager.getToken(forceRefresh: forceRefresh);
  }

  /// Make authenticated API call
  Future<T?> authenticatedApiCall<T>({required Future<T> Function(String) apiCall}) async {
    return await _tokenManager.authenticatedApiCall(apiCall: apiCall);
  }
}

/// Authentication result class
class AuthResult {
  final bool success;
  final String? error;
  final String? role;
  final UserModel? user;

  const AuthResult({
    required this.success,
    this.error,
    this.role,
    this.user,
  });

  @override
  String toString() {
    return 'AuthResult(success: $success, error: $error, role: $role, user: ${user?.uid})';
  }
}
