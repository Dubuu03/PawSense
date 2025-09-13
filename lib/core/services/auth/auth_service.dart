import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:typed_data';
import '../../models/user/user_model.dart';
import '../../models/clinic/clinic_model.dart';
import '../../guards/auth_guard.dart';
import 'token_manager.dart';
import '../cloudinary/cloudinary_service.dart';

/// Comprehensive authentication service that integrates with all models
class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final TokenManager _tokenManager = TokenManager();
  static final CloudinaryService _cloudinaryService = CloudinaryService();

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
        // Get user data from Firestore first to determine role
        final userDoc = await _firestore.collection('users').doc(result.user!.uid).get();
        if (!userDoc.exists) {
          await _auth.signOut();
          return AuthResult(
            success: false, 
            error: 'Account data not found. Please contact support.',
          );
        }
        
        final userData = UserModel.fromMap(userDoc.data()!);
        
        if (userData.role == 'admin') {
          await _validateClinicApprovalStatus(result.user!.uid);
        }
        
        return AuthResult(
          success: true, 
          role: userData.role,
          user: userData,
        );
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
      final errorString = e.toString();
      if (errorString.contains('account-pending-approval')) {
        return AuthResult(success: false, error: 'Your registration has been submitted. Please wait for admin approval before logging in.');
      } else if (errorString.contains('account-suspended')) {
        return AuthResult(success: false, error: 'Your clinic has been suspended. Please contact support for assistance.');
      } else if (errorString.contains('account-rejected')) {
        return AuthResult(success: false, error: 'Your clinic registration has been rejected. Please contact support for more information.');
      } else if (errorString.contains('account-not-verified')) {
        return AuthResult(success: false, error: 'Your account is not yet verified. Please wait for admin approval.');
      }
      return AuthResult(success: false, error: 'An unexpected error occurred. Please try again.');
    }
  }

  Future<void> _validateClinicApprovalStatus(String userId) async {
    try {
      final clinicQuery = await _firestore
          .collection('clinics')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (clinicQuery.docs.isEmpty) {
        throw Exception('account-not-verified');
      }

      final clinicData = clinicQuery.docs.first.data();
      final String status = clinicData['status'] ?? 'pending';

      switch (status) {
        case 'pending':
          throw Exception('account-pending-approval');
        case 'suspended':
          throw Exception('account-suspended');
        case 'rejected':
          throw Exception('account-rejected');
        case 'approved':
          print('✅ Clinic account verified: $userId (status: approved)');
          break;
        default:
          throw Exception('account-pending-approval');
      }
    } catch (e) {
      if (e.toString().contains('account-')) {
        rethrow;
      }
      throw Exception('account-not-verified');
    }
  }

  Future<AuthResult> signUpClinicAdmin({
    required String email,
    required String password,
    required String username,
    required String? firstName,
    required String? lastName,
    required String? contactNumber,
    required Clinic clinic,
    required Map<String, dynamic> clinicDetailsData,
    // Add image data parameters
    Map<int, Uint8List>? certificationImages,
    Map<int, String>? certificationImageNames,
    Map<int, Uint8List>? licenseImages,
    Map<int, String>? licenseImageNames,
  }) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        final uid = result.user!.uid;

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

        await _createUserProfile(uid, userModel);

        final createdClinic = await _createClinic(uid, clinic);
        if (!createdClinic) {
          throw Exception('Failed to create clinic data');
        }

        final createdClinicDetails = await _createClinicDetails(
          uid, 
          clinicDetailsData,
          certificationImages: certificationImages,
          certificationImageNames: certificationImageNames,
          licenseImages: licenseImages,
          licenseImageNames: licenseImageNames,
        );
        if (!createdClinicDetails) {
          throw Exception('Failed to create clinic details');
        }

        if (userModel.role == 'admin') {
          await _auth.signOut();
          _tokenManager.clearToken();
        }

        return AuthResult(success: true, role: userModel.role, user: userModel);
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
      try {
        await _auth.currentUser?.delete();
      } catch (cleanupError) {
        print('Failed to cleanup auth user: $cleanupError');
      }
      return AuthResult(success: false, error: e.toString());
    }
  }

  Future<void> _createUserProfile(String uid, UserModel userModel) async {
    try {
      await _firestore.collection('users').doc(uid).set(userModel.toMap());
      print('✅ User profile created successfully for: $uid');
    } catch (e) {
      print('❌ Failed to create user profile: $e');
      throw Exception('Failed to create user profile: $e');
    }
  }

  Future<bool> _createClinic(String uid, Clinic clinic) async {
    try {
      final clinicWithId = clinic.copyWith(
        id: uid,
        userId: uid,
        status: 'pending',
      );

      await _firestore.collection('clinics').doc(uid).set(clinicWithId.toMap());
      print('✅ Clinic created successfully for: $uid');
      print('   Clinic Name: ${clinic.clinicName}');
      print('   Clinic ID: $uid');
      print('   Status: pending (awaiting admin approval)');
      
      return true;
    } catch (e) {
      print('❌ Failed to create clinic: $e');
      return false;
    }
  }

  Future<bool> _createClinicDetails(
    String uid, 
    Map<String, dynamic> clinicDetailsData, {
    Map<int, Uint8List>? certificationImages,
    Map<int, String>? certificationImageNames,
    Map<int, Uint8List>? licenseImages,
    Map<int, String>? licenseImageNames,
  }) async {
    try {
  print('DEBUG: _createClinicDetails called for uid=$uid');
  print('  certifications present: ${clinicDetailsData['certifications'] != null}');
  print('  licenses present: ${clinicDetailsData['licenses'] != null}');
  print('  certificationImages keys: ${certificationImages?.keys.toList()}');
  print('  certificationImageNames keys: ${certificationImageNames?.keys.toList()}');
  print('  licenseImages keys: ${licenseImages?.keys.toList()}');
  print('  licenseImageNames keys: ${licenseImageNames?.keys.toList()}');

      final clinicDetailsId = _firestore.collection('clinicDetails').doc().id;

      // Upload certification images to Cloudinary
      if (clinicDetailsData['certifications'] != null && certificationImages != null) {
        final certifications = List<Map<String, dynamic>>.from(clinicDetailsData['certifications']);
        
        for (int i = 0; i < certifications.length; i++) {
          final imageBytes = certificationImages[i];
          final imageName = certificationImageNames?[i];
          
          if (imageBytes != null && imageName != null) {
            try {
              print('📤 Uploading certification image ${i + 1}/${ certifications.length}...');
              final uploadedUrl = await _cloudinaryService.uploadImageFromBytes(
                imageBytes,
                'cert_${uid}_${i}_$imageName',
                folder: 'certifications',
              );
              
              // Save URL into the field expected by ClinicCertification model
              certifications[i]['documentUrl'] = uploadedUrl;
              certifications[i]['documentFileId'] = null;
              certifications[i]['fileName'] = imageName; // keep original name if needed
              print('✅ Certification image uploaded: ${uploadedUrl}');
            } catch (e) {
              print('❌ Failed to upload certification image $i: $e');
              // Continue without the image - will be marked as needing upload later
            }
          }
          
          certifications[i]['clinicId'] = uid;
        }
        
        clinicDetailsData['certifications'] = certifications;
      }

      // Upload license images to Cloudinary
      if (clinicDetailsData['licenses'] != null && licenseImages != null) {
        final licenses = List<Map<String, dynamic>>.from(clinicDetailsData['licenses']);
        
        for (int i = 0; i < licenses.length; i++) {
          final imageBytes = licenseImages[i];
          final imageName = licenseImageNames?[i];
          
          if (imageBytes != null && imageName != null) {
            try {
              print('📤 Uploading license image ${i + 1}/${licenses.length}...');
              final uploadedUrl = await _cloudinaryService.uploadImageFromBytes(
                imageBytes,
                'license_${uid}_${i}_$imageName',
                folder: 'licenses',
              );
              
              // Save URL into the field expected by ClinicLicense model
              licenses[i]['licensePictureUrl'] = uploadedUrl;
              licenses[i]['licensePictureFileId'] = null;
              licenses[i]['fileName'] = imageName; // keep original name if needed
              print('✅ License image uploaded: ${uploadedUrl}');
            } catch (e) {
              print('❌ Failed to upload license image $i: $e');
              // Continue without the image - will be marked as needing upload later
            }
          }
          
          licenses[i]['clinicId'] = uid;
        }
        
        clinicDetailsData['licenses'] = licenses;
      }

      final clinicDetailsWithIds = {
        ...clinicDetailsData,
        'id': clinicDetailsId,
        'clinicId': uid,
        'isVerified': false,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      await _firestore.collection('clinicDetails').doc(clinicDetailsId).set(clinicDetailsWithIds);
      
      print('✅ Clinic details created successfully');
      return true;
    } catch (e) {
      print('❌ Failed to create clinic details: $e');
      return false;
    }
  }

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

  Future<bool> updateClinicData(Clinic clinic) async {
    try {
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

  Future<bool> updateClinicDetails(String clinicId, Map<String, dynamic> data) async {
    try {
      if (!await canAccessClinic(clinicId)) {
        return false;
      }

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

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  bool get isSignedIn => currentUser != null;

  Future<String?> getAuthToken({bool forceRefresh = false}) async {
    return await _tokenManager.getToken(forceRefresh: forceRefresh);
  }

  Future<T?> authenticatedApiCall<T>({required Future<T> Function(String) apiCall}) async {
    return await _tokenManager.authenticatedApiCall(apiCall: apiCall);
  }
}

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