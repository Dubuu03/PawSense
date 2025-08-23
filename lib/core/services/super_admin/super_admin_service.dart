import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../models/clinic_registration_model.dart';

/// Service for Super Admin operations
class SuperAdminService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // =================== USER MANAGEMENT ===================
  
  /// Get paginated users from Firestore with suspension status
  static Future<Map<String, dynamic>> getPaginatedUsersWithStatus({
    int page = 1,
    int itemsPerPage = 5,
    String? roleFilter,
    String? statusFilter,
    String? searchQuery,
  }) async {
    try {
      // Build the base query
      Query query = _firestore.collection('users');
      
      // Apply role filter
      if (roleFilter != null && roleFilter != 'all' && roleFilter.isNotEmpty) {
        query = query.where('role', isEqualTo: roleFilter);
      }
      
      // Apply status filter
      if (statusFilter != null && statusFilter != 'all' && statusFilter.isNotEmpty) {
        bool isActive = statusFilter == 'active';
        query = query.where('isActive', isEqualTo: isActive);
      }
      
      // Get total count first (for pagination info)
      final totalCountSnapshot = await query.get();
      final totalUsers = totalCountSnapshot.docs.length;
      
      // Apply pagination
      final offset = (page - 1) * itemsPerPage;

      // Get all matching documents for pagination
      final allSnapshot = await query.get();
      final allDocs = allSnapshot.docs;

      // Apply pagination in memory
      final limitedDocs = allDocs.skip(offset).take(itemsPerPage).toList();

      print('SuperAdminService: Pagination debug - total docs: ${allDocs.length}, offset: $offset, taking: $itemsPerPage, limitedDocs count: ${limitedDocs.length}');

      final users = limitedDocs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final user = UserModel.fromMap({
          'uid': doc.id,
          ...data,
        });

        return {
          'user': user,
          'isActive': user.isActive,
          'suspensionReason': user.suspensionReason,
          'suspendedAt': user.suspendedAt,
        };
      }).toList();

      // Apply search filter in memory (for simplicity)
      List<Map<String, dynamic>> filteredUsers = users;
      if (searchQuery != null && searchQuery.isNotEmpty) {
        print('SuperAdminService: Applying search filter: "$searchQuery" on ${users.length} users');
        filteredUsers = users.where((userMap) {
          final user = userMap['user'] as UserModel;
          final searchLower = searchQuery.toLowerCase();
          final matches = user.username.toLowerCase().contains(searchLower) ||
                 user.email.toLowerCase().contains(searchLower) ||
                 (user.firstName?.toLowerCase().contains(searchLower) ?? false) ||
                 (user.lastName?.toLowerCase().contains(searchLower) ?? false);
          if (matches) {
            print('SuperAdminService: User "${user.username}" matches search');
          }
          return matches;
        }).toList();
        print('SuperAdminService: After search filtering: ${filteredUsers.length} users');
      }

      print('SuperAdminService: Found ${filteredUsers.length} users for page $page (offset: $offset, total docs: ${allDocs.length})');

      return {
        'users': filteredUsers,
        'totalUsers': totalUsers,
        'currentPage': page,
        'totalPages': (totalUsers / itemsPerPage).ceil(),
        'itemsPerPage': itemsPerPage,
      };
    } catch (e) {
      print('Error fetching paginated users with status: $e');
      return {
        'users': <Map<String, dynamic>>[],
        'totalUsers': 0,
        'currentPage': 1,
        'totalPages': 0,
        'itemsPerPage': itemsPerPage,
      };
    }
  }

  /// Get all users from Firestore with suspension status (kept for backward compatibility)
  static Future<List<Map<String, dynamic>>> getAllUsersWithStatus() async {
    final result = await getPaginatedUsersWithStatus(itemsPerPage: 1000); // Large number to get all
    return result['users'] as List<Map<String, dynamic>>;
  }
  
  /// Get users with pagination
  static Future<List<UserModel>> getUsersPaginated({
    int limit = 20,
    DocumentSnapshot? lastDocument,
    String? role,
    String? searchQuery,
  }) async {
    try {
      Query query = _firestore.collection('users');
      
      // Apply role filter
      if (role != null && role != 'All Roles') {
        query = query.where('role', isEqualTo: role.toLowerCase());
      }
      
      // Apply pagination
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }
      
      query = query.limit(limit);
      
      final querySnapshot = await query.get();
      List<UserModel> users = querySnapshot.docs.map((doc) {
        return UserModel.fromMap({
          'uid': doc.id,
          ...doc.data() as Map<String, dynamic>,
        });
      }).toList();
      
      // Apply search filter (client-side for now)
      if (searchQuery != null && searchQuery.isNotEmpty) {
        users = users.where((user) {
          final query = searchQuery.toLowerCase();
          return user.username.toLowerCase().contains(query) ||
                 user.email.toLowerCase().contains(query) ||
                 (user.firstName?.toLowerCase().contains(query) ?? false) ||
                 (user.lastName?.toLowerCase().contains(query) ?? false);
        }).toList();
      }
      
      return users;
    } catch (e) {
      print('Error fetching paginated users: $e');
      return [];
    }
  }
  
  /// Update user status (suspend/activate)
  static Future<bool> updateUserStatus(String uid, bool isActive, {String? reason}) async {
    try {
      final updateData = <String, dynamic>{
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      if (!isActive && reason != null) {
        updateData['suspensionReason'] = reason;
        updateData['suspendedAt'] = FieldValue.serverTimestamp();
      } else if (isActive) {
        updateData['suspensionReason'] = null;
        updateData['suspendedAt'] = null;
      }
      
      await _firestore.collection('users').doc(uid).update(updateData);
      return true;
    } catch (e) {
      print('Error updating user status: $e');
      return false;
    }
  }
  
  /// Suspend user with reason
  static Future<bool> suspendUser(String uid, String reason) async {
    return await updateUserStatus(uid, false, reason: reason);
  }
  
  /// Activate user
  static Future<bool> activateUser(String uid) async {
    return await updateUserStatus(uid, true);
  }
  
  /// Delete user
  static Future<bool> deleteUser(String uid) async {
    try {
      // Delete user document
      await _firestore.collection('users').doc(uid).delete();
      
      // Also delete related clinic data if exists
      final clinicDoc = await _firestore.collection('clinics').doc(uid).get();
      if (clinicDoc.exists) {
        await _firestore.collection('clinics').doc(uid).delete();
      }
      
      // Delete clinic details if exists
      final clinicDetailsQuery = await _firestore
          .collection('clinicDetails')
          .where('clinicId', isEqualTo: uid)
          .get();
      
      for (var doc in clinicDetailsQuery.docs) {
        await doc.reference.delete();
      }
      
      return true;
    } catch (e) {
      print('Error deleting user: $e');
      return false;
    }
  }
  
  // =================== CLINIC MANAGEMENT ===================
  
  /// Get all clinic registrations
  static Future<List<ClinicRegistration>> getAllClinicRegistrations() async {
    try {
      print('SuperAdminService: Fetching all clinic registrations...');
      
      // Get all clinics
      final clinicsSnapshot = await _firestore.collection('clinics').get();
      List<ClinicRegistration> clinicRegistrations = [];
      
      for (var clinicDoc in clinicsSnapshot.docs) {
        final registration = await _buildClinicRegistration(clinicDoc);
        clinicRegistrations.add(registration);
      }
      
      print('SuperAdminService: Found ${clinicRegistrations.length} clinic registrations');
      return clinicRegistrations;
    } catch (e) {
      print('Error fetching clinic registrations: $e');
      return [];
    }
  }
  
  /// Get paginated clinic registrations with filtering
  static Future<Map<String, dynamic>> getPaginatedClinicRegistrations({
    int page = 1,
    int itemsPerPage = 5,
    String? statusFilter,
    String? searchQuery,
  }) async {
    try {
      print('SuperAdminService: Fetching paginated clinics (page: $page, itemsPerPage: $itemsPerPage)...');
      print('SuperAdminService: Filters - statusFilter: "$statusFilter", searchQuery: "$searchQuery"');
      
      // Build the base query
      Query query = _firestore.collection('clinics');
      
      // Apply status filter
      if (statusFilter != null && statusFilter.isNotEmpty && statusFilter != 'all') {
        query = query.where('status', isEqualTo: statusFilter);
      }
      
      // Get total count first (for pagination info)
      final totalCountSnapshot = await query.get();
      final totalClinics = totalCountSnapshot.docs.length;
      
      // Apply pagination
      final offset = (page - 1) * itemsPerPage;

      // Get all matching documents for pagination
      final allSnapshot = await query.get();
      final allDocs = allSnapshot.docs;

      // Apply pagination in memory
      final limitedDocs = allDocs.skip(offset).take(itemsPerPage).toList();

      print('SuperAdminService: Pagination debug - total docs: ${allDocs.length}, offset: $offset, taking: $itemsPerPage, limitedDocs count: ${limitedDocs.length}');

      List<ClinicRegistration> clinicRegistrations = [];
      for (var clinicDoc in limitedDocs) {
        final registration = await _buildClinicRegistration(clinicDoc);
        clinicRegistrations.add(registration);
      }
      
      // Apply search filter in memory (for simplicity)
      List<ClinicRegistration> filteredClinics = clinicRegistrations;
      if (searchQuery != null && searchQuery.isNotEmpty) {
        print('SuperAdminService: Applying clinic search filter: "$searchQuery" on ${clinicRegistrations.length} clinics');
        filteredClinics = clinicRegistrations.where((clinic) {
          final searchLower = searchQuery.toLowerCase();
          final matches = clinic.clinicName.toLowerCase().contains(searchLower) ||
                 clinic.email.toLowerCase().contains(searchLower) ||
                 clinic.licenseNumber.toLowerCase().contains(searchLower) ||
                 clinic.adminName.toLowerCase().contains(searchLower);
          if (matches) {
            print('SuperAdminService: Clinic "${clinic.clinicName}" matches search');
          }
          return matches;
        }).toList();
        print('SuperAdminService: After clinic search filtering: ${filteredClinics.length} clinics');
      }
      
      print('SuperAdminService: Found ${filteredClinics.length} clinics for page $page (offset: $offset, total docs: ${allDocs.length})');
      
      return {
        'clinics': filteredClinics,
        'totalClinics': totalClinics,
        'currentPage': page,
        'totalPages': (totalClinics / itemsPerPage).ceil(),
        'itemsPerPage': itemsPerPage,
      };
    } catch (e) {
      print('Error fetching paginated clinics: $e');
      return {
        'clinics': <ClinicRegistration>[],
        'totalClinics': 0,
        'currentPage': 1,
        'totalPages': 0,
        'itemsPerPage': itemsPerPage,
      };
    }
  }
  
  /// Helper method to build ClinicRegistration from document
  static Future<ClinicRegistration> _buildClinicRegistration(QueryDocumentSnapshot clinicDoc) async {
    final clinicData = clinicDoc.data() as Map<String, dynamic>;
    final clinicId = clinicDoc.id;
    
    // Get user data for admin info
    final userDoc = await _firestore.collection('users').doc(clinicId).get();
    final userData = userDoc.exists ? userDoc.data()! : {};
    
    return ClinicRegistration(
      id: clinicId,
      clinicName: clinicData['clinicName'] ?? 'Unknown Clinic',
      adminName: userData['username'] ?? userData['firstName'] ?? 'Unknown Admin',
      adminId: clinicId,
      email: clinicData['email'] ?? userData['email'] ?? '',
      phone: clinicData['phone'] ?? userData['contactNumber'] ?? '',
      address: clinicData['address'] ?? '',
      licenseNumber: clinicData['licenseNumber'] ?? 'Not provided',
      status: _parseClinicStatus(clinicData['status']),
      applicationDate: _parseDateTime(clinicData['createdAt']) ?? DateTime.now(),
      approvedDate: _parseDateTime(clinicData['approvedAt']),
      rejectionReason: clinicData['rejectionReason'],
      suspensionReason: clinicData['suspensionReason'],
    );
  }
  
  /// Update clinic status
  static Future<bool> updateClinicStatus(
    String clinicId, 
    ClinicStatus status, {
    String? reason,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': status.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      switch (status) {
        case ClinicStatus.verified:
          updateData['approvedAt'] = FieldValue.serverTimestamp();
          updateData['rejectionReason'] = null;
          updateData['suspensionReason'] = null;
          break;
        case ClinicStatus.rejected:
          updateData['rejectionReason'] = reason ?? 'Rejected by admin';
          updateData['approvedAt'] = null;
          break;
        case ClinicStatus.suspended:
          updateData['suspensionReason'] = reason ?? 'Suspended by admin';
          break;
        case ClinicStatus.pending:
          updateData['rejectionReason'] = null;
          updateData['suspensionReason'] = null;
          updateData['approvedAt'] = null;
          break;
      }
      
      await _firestore.collection('clinics').doc(clinicId).update(updateData);
      return true;
    } catch (e) {
      print('Error updating clinic status: $e');
      return false;
    }
  }
  
  /// Get clinic statistics
  static Future<Map<String, int>> getClinicStatistics() async {
    try {
      final snapshot = await _firestore.collection('clinics').get();
      
      int total = snapshot.docs.length;
      int pending = 0;
      int approved = 0;
      int rejected = 0;
      int suspended = 0;
      
      for (var doc in snapshot.docs) {
        final status = doc.data()['status'] ?? 'pending';
        switch (status) {
          case 'pending':
            pending++;
            break;
          case 'verified':
            approved++;
            break;
          case 'rejected':
            rejected++;
            break;
          case 'suspended':
            suspended++;
            break;
        }
      }
      
      return {
        'total': total,
        'pending': pending,
        'approved': approved,
        'rejected': rejected,
        'suspended': suspended,
      };
    } catch (e) {
      print('Error getting clinic statistics: $e');
      return {
        'total': 0,
        'pending': 0,
        'approved': 0,
        'rejected': 0,
        'suspended': 0,
      };
    }
  }
  
  /// Get user statistics
  static Future<Map<String, int>> getUserStatistics() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      
      int total = snapshot.docs.length;
      int active = 0;
      int suspended = 0;
      int admins = 0;
      int users = 0;
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final isActive = data['isActive'] ?? true;
        final role = data['role'] ?? 'user';
        
        if (isActive) {
          active++;
        } else {
          suspended++;
        }
        
        if (role == 'admin' || role == 'super_admin') {
          admins++;
        } else {
          users++;
        }
      }
      
      return {
        'total': total,
        'active': active,
        'suspended': suspended,
        'admins': admins,
        'users': users,
      };
    } catch (e) {
      print('Error getting user statistics: $e');
      return {
        'total': 0,
        'active': 0,
        'suspended': 0,
        'admins': 0,
        'users': 0,
      };
    }
  }
  
  // =================== HELPER METHODS ===================
  
  /// Parse clinic status from string
  static ClinicStatus _parseClinicStatus(dynamic status) {
    if (status == null) return ClinicStatus.pending;
    
    final statusString = status.toString().toLowerCase();
    switch (statusString) {
      case 'verified':
        return ClinicStatus.verified;
      case 'rejected':
        return ClinicStatus.rejected;
      case 'suspended':
        return ClinicStatus.suspended;
      default:
        return ClinicStatus.pending;
    }
  }
  
  /// Parse DateTime from Firestore Timestamp
  static DateTime? _parseDateTime(dynamic timestamp) {
    if (timestamp == null) return null;
    
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    }
    
    if (timestamp is DateTime) {
      return timestamp;
    }
    
    return null;
  }
}
