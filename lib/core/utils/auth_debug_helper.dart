import 'package:firebase_auth/firebase_auth.dart';
import 'package:pawsense/core/guards/auth_guard.dart';
import 'package:pawsense/core/services/auth/auth_service.dart';

class AuthDebugHelper {
  static Future<void> debugCurrentUser() async {
    print('=== AUTH DEBUG ===');
    
    // Check Firebase Auth current user
    final firebaseUser = FirebaseAuth.instance.currentUser;
    print('Firebase Auth User: ${firebaseUser?.uid} | Email: ${firebaseUser?.email}');
    
    // Check AuthGuard cached user
    final authGuardUser = await AuthGuard.getCurrentUser();
    print('AuthGuard User: ${authGuardUser?.uid} | Email: ${authGuardUser?.email} | Role: ${authGuardUser?.role}');
    
    // Check AuthService current user
    final authServiceUser = await AuthService().getCurrentUser();
    print('AuthService User: ${authServiceUser?.uid} | Email: ${authServiceUser?.email} | Role: ${authServiceUser?.role}');
    
    print('==================');
  }
  
  static Future<void> clearAllAuthCache() async {
    print('Clearing all authentication cache...');
    AuthGuard.clearUserCache();
    print('Authentication cache cleared.');
  }
}