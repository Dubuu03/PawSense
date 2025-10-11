import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'realtime_notification_service.dart';
import 'transaction_notification_service.dart';

/// Global notification manager that handles all notification services
/// and provides app-wide popup notifications
class GlobalNotificationManager {
  static final GlobalNotificationManager _instance = GlobalNotificationManager._internal();
  factory GlobalNotificationManager() => _instance;
  GlobalNotificationManager._internal();

  // Core services
  final RealTimeNotificationService _realtimeService = RealTimeNotificationService();
  final TransactionNotificationService _transactionService = TransactionNotificationService();
  
  // Auth state listener
  StreamSubscription<User?>? _authSubscription;
  String? _currentUserId;
  bool _isInitialized = false;

  /// Initialize global notification system
  /// Call this in main.dart after Firebase initialization
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Listen to auth state changes
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen(
      (user) async {
        if (user != null && user.uid != _currentUserId) {
          await _initializeForUser(user.uid);
        } else if (user == null) {
          await _dispose();
        }
      },
    );
    
    _isInitialized = true;
    debugPrint('🌍 Global notification manager initialized');
  }

  /// Initialize all notification services for a specific user
  Future<void> _initializeForUser(String userId) async {
    try {
      debugPrint('🔔 Initializing global notifications for user: $userId');
      
      // Dispose previous user's services
      if (_currentUserId != null && _currentUserId != userId) {
        await _disposeUserServices();
      }
      
      _currentUserId = userId;
      
      // Initialize real-time notification service
      await _realtimeService.initializeForUser(userId);
      debugPrint('✅ Real-time notification service initialized');
      
      // Initialize transaction monitoring
      await _transactionService.initializeForUser(userId);
      debugPrint('✅ Transaction notification service initialized');
      
      debugPrint('🎉 All notification services initialized for user: $userId');
      
    } catch (e) {
      debugPrint('❌ Error initializing global notifications: $e');
    }
  }

  /// Initialize overlay for a specific context (call from main app widget) - DISABLED
  void initializeOverlay(BuildContext context) {
    // Overlay functionality removed
    debugPrint('� Overlay functionality disabled');
  }

  /// Get unread notification count stream
  Stream<int> get unreadCountStream => _realtimeService.unreadCountStream;

  /// Get current unread count
  int get unreadCount => _realtimeService.unreadCount;

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    if (_currentUserId != null) {
      await _realtimeService.markAsRead(notificationId, _currentUserId!);
    }
  }

  /// Get cached notifications
  List<dynamic> get cachedNotifications => _realtimeService.cachedNotifications;

  /// Force refresh notifications
  Future<void> refresh() async {
    await _realtimeService.refresh();
  }

  /// Show a manual popup notification (for testing) - DISABLED
  void showTestPopup(BuildContext context) {
    debugPrint('🚫 Popup functionality disabled');
  }

  /// Dispose user-specific services
  Future<void> _disposeUserServices() async {
    await _realtimeService.dispose();
    await _transactionService.dispose();
    _currentUserId = null;
  }

  /// Dispose all services
  Future<void> _dispose() async {
    await _disposeUserServices();
    await _authSubscription?.cancel();
    _authSubscription = null;
  }

  /// Complete dispose (call on app termination)
  Future<void> dispose() async {
    await _dispose();
    _isInitialized = false;
    debugPrint('🧹 Global notification manager disposed');
  }

  /// Check if services are initialized
  bool get isInitialized => _isInitialized;
  String? get currentUserId => _currentUserId;
}