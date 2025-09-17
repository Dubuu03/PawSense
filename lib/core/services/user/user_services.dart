import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:pawsense/core/models/user/user_model.dart';
import 'package:pawsense/core/guards/auth_guard.dart';

class UserServices {
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  // Get user by uid
  Future<UserModel?> getUserByUid(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data()!);
    }
    return null;
  }

  // Get user by email
  Future<UserModel?> getUserByEmail(String email) async {
    final query = await _firestore.collection('users').where('email', isEqualTo: email.trim().toLowerCase()).limit(1).get();
    if (query.docs.isNotEmpty) {
      return UserModel.fromMap(query.docs.first.data());
    }
    return null;
  }

  // Update user
  Future<void> updateUser(UserModel user) async {
    await _firestore.collection('users').doc(user.uid).update(user.toMap());
    // Clear AuthGuard cache to ensure fresh data is loaded
    AuthGuard.clearUserCache();
  }

  // Delete user
  Future<void> deleteUser(String uid) async {
    await _firestore.collection('users').doc(uid).delete();
  }

  // Stream user document
  Stream<UserModel?> userStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    });
  }

  // List all users (use with caution for large collections)
  Future<List<UserModel>> getAllUsers() async {
    final query = await _firestore.collection('users').get();
    return query.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
  }

  // Get profile image URL for a user
  Future<String?> getProfileImageUrl(String uid) async {
    try {
      final user = await getUserByUid(uid);
      return user?.profileImageUrl;
    } catch (e) {
      print('Error getting profile image URL: $e');
      return null;
    }
  }

  // Update profile image URL
  Future<void> updateProfileImageUrl(String uid, String imageUrl) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'profileImageUrl': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      // Clear AuthGuard cache to ensure fresh data is loaded
      AuthGuard.clearUserCache();
    } catch (e) {
      print('Error updating profile image URL: $e');
      throw e;
    }
  }

  // Remove profile image
  Future<void> removeProfileImage(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'profileImageUrl': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      // Clear AuthGuard cache to ensure fresh data is loaded
      AuthGuard.clearUserCache();
    } catch (e) {
      print('Error removing profile image: $e');
      throw e;
    }
  }

  // Upload profile image to Firebase Storage
  Future<String?> uploadProfileImage(String uid, File imageFile) async {
    try {
      final ref = _storage.ref().child('profile_images').child('$uid.jpg');
      final uploadTask = await ref.putFile(imageFile);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      
      // Update user document with new image URL
      await updateProfileImageUrl(uid, downloadUrl);
      
      return downloadUrl;
    } catch (e) {
      print('Error uploading profile image: $e');
      return null;
    }
  }

  // Delete profile image from Firebase Storage
  Future<void> deleteProfileImageFromStorage(String uid) async {
    try {
      final ref = _storage.ref().child('profile_images').child('$uid.jpg');
      await ref.delete();
      await removeProfileImage(uid);
    } catch (e) {
      print('Error deleting profile image from storage: $e');
      // Don't throw error if image doesn't exist in storage
    }
  }
}
