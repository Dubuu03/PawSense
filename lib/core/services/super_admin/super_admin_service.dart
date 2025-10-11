import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user/user_model.dart';
import '../../models/clinic/clinic_registration_model.dart';

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

      // Get all matching documents first
      final allSnapshot = await query.get();
      final allDocs = allSnapshot.docs;

      print('SuperAdminService: Retrieved ${allDocs.length} users from Firestore');

      // Convert all documents to user objects with status
      final allUsers = allDocs.map((doc) {
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

      // Apply search filter FIRST (before pagination)
      List<Map<String, dynamic>> filteredUsers = allUsers;
      if (searchQuery != null && searchQuery.isNotEmpty) {
        print('SuperAdminService: Applying search filter: "$searchQuery" on ${allUsers.length} users');
        filteredUsers = allUsers.where((userMap) {
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

      // NOW apply pagination to the filtered results
      final totalFilteredUsers = filteredUsers.length;
      final offset = (page - 1) * itemsPerPage;
      final paginatedUsers = filteredUsers.skip(offset).take(itemsPerPage).toList();

      print('SuperAdminService: Pagination applied - filtered total: $totalFilteredUsers, page: $page, offset: $offset, returned: ${paginatedUsers.length}');

      return {
        'users': paginatedUsers,
        'totalUsers': totalFilteredUsers, // Use filtered count, not original count
        'currentPage': page,
        'totalPages': (totalFilteredUsers / itemsPerPage).ceil(),
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
  
  /// Update user profile data
  static Future<bool> updateUser(UserModel user) async {
    try {
      final updateData = <String, dynamic>{
        'username': user.username,
        'email': user.email,
        'role': user.role,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      // Add optional fields if they exist
      if (user.firstName != null) {
        updateData['firstName'] = user.firstName;
      }
      if (user.lastName != null) {
        updateData['lastName'] = user.lastName;
      }
      if (user.contactNumber != null) {
        updateData['contactNumber'] = user.contactNumber;
      }
      if (user.address != null) {
        updateData['address'] = user.address;
      }
      if (user.profileImageUrl != null) {
        updateData['profileImageUrl'] = user.profileImageUrl;
      }
      
      // Add status-related fields
      updateData['isActive'] = user.isActive;
      if (user.suspensionReason != null) {
        updateData['suspensionReason'] = user.suspensionReason;
      }
      if (user.suspendedAt != null) {
        updateData['suspendedAt'] = Timestamp.fromDate(user.suspendedAt!);
      }
      
      await _firestore.collection('users').doc(user.uid).update(updateData);
      return true;
    } catch (e) {
      print('Error updating user: $e');
      return false;
    }
  }
  
  /// Update clinic basic information
  static Future<bool> updateClinic(ClinicRegistration clinic) async {
    try {
      final clinicUpdateData = <String, dynamic>{
        'clinicName': clinic.clinicName,
        'email': clinic.email,
        'phone': clinic.phone,
        'address': clinic.address,
        'licenseNumber': clinic.licenseNumber,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      final userUpdateData = <String, dynamic>{
        'username': clinic.adminName,
        'email': clinic.email,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      // Update clinic document
      await _firestore.collection('clinics').doc(clinic.id).update(clinicUpdateData);
      
      // Update admin user document
      await _firestore.collection('users').doc(clinic.adminId).update(userUpdateData);
      
      // Update clinic details if exists
      final clinicDetailsQuery = await _firestore
          .collection('clinicDetails')
          .where('clinicId', isEqualTo: clinic.id)
          .limit(1)
          .get();
      
      if (clinicDetailsQuery.docs.isNotEmpty) {
        await clinicDetailsQuery.docs.first.reference.update({
          'clinicName': clinic.clinicName,
          'address': clinic.address,
          'phone': clinic.phone,
          'email': clinic.email,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }
      
      return true;
    } catch (e) {
      print('Error updating clinic: $e');
      return false;
    }
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
  /// Optimized to fetch only the needed page and batch-fetch user data
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

      // Get all matching documents (needed for search filtering)
      final allSnapshot = await query.get();
      final allDocs = allSnapshot.docs;

      print('SuperAdminService: Retrieved ${allDocs.length} clinics from Firestore');

      // Batch fetch all user data in one query to avoid N+1 problem
      final clinicIds = allDocs.map((doc) => doc.id).toList();
      Map<String, Map<String, dynamic>> userDataMap = {};
      
      if (clinicIds.isNotEmpty) {
        // Firestore 'in' queries are limited to 10 items, so batch them
        for (int i = 0; i < clinicIds.length; i += 10) {
          final batchIds = clinicIds.skip(i).take(10).toList();
          final userSnapshots = await _firestore
              .collection('users')
              .where(FieldPath.documentId, whereIn: batchIds)
              .get();
          
          for (var userDoc in userSnapshots.docs) {
            userDataMap[userDoc.id] = userDoc.data();
          }
        }
      }

      // Convert all documents to clinic registration objects (now with batched user data)
      List<ClinicRegistration> allClinics = [];
      for (var clinicDoc in allDocs) {
        final registration = _buildClinicRegistrationFromData(
          clinicDoc.id,
          clinicDoc.data() as Map<String, dynamic>,
          userDataMap[clinicDoc.id] ?? {},
        );
        allClinics.add(registration);
      }

      // Apply search filter FIRST (before pagination)
      List<ClinicRegistration> filteredClinics = allClinics;
      if (searchQuery != null && searchQuery.isNotEmpty) {
        print('SuperAdminService: Applying clinic search filter: "$searchQuery" on ${allClinics.length} clinics');
        filteredClinics = allClinics.where((clinic) {
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

      // NOW apply pagination to the filtered results
      final totalFilteredClinics = filteredClinics.length;
      final offset = (page - 1) * itemsPerPage;
      final paginatedClinics = filteredClinics.skip(offset).take(itemsPerPage).toList();

      print('SuperAdminService: Pagination applied - filtered total: $totalFilteredClinics, page: $page, offset: $offset, returned: ${paginatedClinics.length}');
      
      return {
        'clinics': paginatedClinics,
        'totalClinics': totalFilteredClinics, // Use filtered count, not original count
        'currentPage': page,
        'totalPages': (totalFilteredClinics / itemsPerPage).ceil(),
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
  
  /// Helper method to build ClinicRegistration from document (DEPRECATED - kept for compatibility)
  static Future<ClinicRegistration> _buildClinicRegistration(QueryDocumentSnapshot clinicDoc) async {
    final clinicData = clinicDoc.data() as Map<String, dynamic>;
    final clinicId = clinicDoc.id;
    
    // Get user data for admin info
    final userDoc = await _firestore.collection('users').doc(clinicId).get();
    final userData = userDoc.exists 
        ? Map<String, dynamic>.from(userDoc.data()!) 
        : <String, dynamic>{};
    
    return _buildClinicRegistrationFromData(clinicId, clinicData, userData);
  }
  
  /// Build ClinicRegistration from pre-fetched data (optimized)
  static ClinicRegistration _buildClinicRegistrationFromData(
    String clinicId,
    Map<String, dynamic> clinicData,
    Map<String, dynamic> userData,
  ) {
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
  
  /// Update clinic status and verification status
  static Future<bool> updateClinicStatus(
    String clinicId, 
    ClinicStatus status, {
    String? reason,
  }) async {
    try {
      // Prepare clinic collection update
      final clinicUpdateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      switch (status) {
        case ClinicStatus.approved:
          // Clinic approved - set status to 'approved'
          clinicUpdateData['status'] = 'approved'; // Use 'approved' to match auth validation
          clinicUpdateData['approvedAt'] = FieldValue.serverTimestamp();
          clinicUpdateData['rejectionReason'] = null;
          clinicUpdateData['suspensionReason'] = null;
          break;
          
        case ClinicStatus.rejected:
          clinicUpdateData['status'] = 'rejected';
          clinicUpdateData['rejectionReason'] = reason ?? 'Rejected by admin';
          clinicUpdateData['approvedAt'] = null;
          break;
          
        case ClinicStatus.suspended:
          clinicUpdateData['status'] = 'suspended';
          clinicUpdateData['suspensionReason'] = reason ?? 'Suspended by admin';
          break;
          
        case ClinicStatus.pending:
          clinicUpdateData['status'] = 'pending';
          clinicUpdateData['rejectionReason'] = null;
          clinicUpdateData['suspensionReason'] = null;
          clinicUpdateData['approvedAt'] = null;
          break;
      }
      
      // Update clinic collection only (no longer updating clinicDetails.isVerified)
      await _firestore.collection('clinics').doc(clinicId).update(clinicUpdateData);
      
      print('✅ Clinic status updated successfully: $clinicId -> ${clinicUpdateData['status']}');
      
      // Send notification to clinic admin about status change
      await _sendClinicStatusNotification(clinicId, status, reason);
      
      return true;
    } catch (e) {
      print('❌ Error updating clinic status: $e');
      return false;
    }
  }

  /// Send notification to clinic admin about status change
  static Future<void> _sendClinicStatusNotification(
    String clinicId, 
    ClinicStatus status, 
    String? reason,
  ) async {
    try {
      // Get clinic details
      final clinicDoc = await _firestore.collection('clinics').doc(clinicId).get();
      
      if (!clinicDoc.exists) return;
      
      final clinicData = clinicDoc.data()!;
      
      String title;
      String message;
      String type = 'system';
      
      switch (status) {
        case ClinicStatus.approved:
          title = 'Clinic Application Approved!';
          message = 'Congratulations! Your clinic "${clinicData['clinicName']}" has been approved. You can now access all features.';
          type = 'approval';
          break;
          
        case ClinicStatus.rejected:
          title = 'Clinic Application Rejected';
          message = 'Your clinic application has been rejected. ${reason != null ? 'Reason: $reason' : 'Please contact support for more information.'}';
          type = 'rejection';
          break;
          
        case ClinicStatus.suspended:
          title = 'Clinic Account Suspended';
          message = 'Your clinic account has been suspended. ${reason != null ? 'Reason: $reason' : 'Please contact support for assistance.'}';
          type = 'suspension';
          break;
          
        case ClinicStatus.pending:
          title = 'Clinic Status Updated';
          message = 'Your clinic application is now under review.';
          break;
      }
      
      // Create notification document
      await _firestore.collection('notifications').add({
        'recipientId': clinicId,
        'recipientType': 'admin',
        'title': title,
        'message': message,
        'type': type,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'data': {
          'clinicId': clinicId,
          'clinicName': clinicData['clinicName'],
          'status': status.toString().split('.').last,
          'reason': reason,
        },
      });
      
      print('✅ Notification sent to clinic admin: $clinicId');
    } catch (e) {
      print('⚠️ Failed to send notification: $e');
      // Don't throw error as this is not critical for the approval process
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
        final data = doc.data();
        final status = (data['status'] ?? 'pending').toString().trim().toLowerCase();
        
        switch (status) {
          case 'pending':
            pending++;
            break;
          case 'approved':
            approved++;
            break;
          case 'rejected':
            rejected++;
            break;
          case 'suspended':
            suspended++;
            break;
          default:
            // Unknown status defaults to pending
            pending++;
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
      case 'approved':
        return ClinicStatus.approved;
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
