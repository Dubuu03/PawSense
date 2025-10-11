import 'package:flutter/foundation.dart';

/// Centralized logging configuration for the PawSense app
/// Controls debug output to prevent log spam and reduce performance impact
class AppLogger {
  // Configure logging levels
  static const bool _enableDebugLogs = kDebugMode; // Only in debug mode
  static const bool _enableInfoLogs = true; // Always enabled
  static const bool _enableWarningLogs = true; // Always enabled  
  static const bool _enableErrorLogs = true; // Always enabled
  
  // Specific feature logging controls (can be turned off for production)
  static const bool _enableDashboardLogs = false; // Disable dashboard spam
  static const bool _enableNotificationLogs = false; // Disable notification spam
  static const bool _enableAppointmentLogs = false; // Disable appointment spam
  static const bool _enableFirebaseLogs = false; // Disable Firebase query spam
  
  /// Log debug messages (development only)
  static void debug(String message, {String? tag}) {
    if (_enableDebugLogs) {
      final prefix = tag != null ? '[$tag] ' : '';
      print('🐛 $prefix$message');
    }
  }
  
  /// Log info messages
  static void info(String message, {String? tag}) {
    if (_enableInfoLogs) {
      final prefix = tag != null ? '[$tag] ' : '';
      print('ℹ️ $prefix$message');
    }
  }
  
  /// Log warning messages
  static void warning(String message, {String? tag}) {
    if (_enableWarningLogs) {
      final prefix = tag != null ? '[$tag] ' : '';
      print('⚠️ $prefix$message');
    }
  }
  
  /// Log error messages (always shown)
  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    if (_enableErrorLogs) {
      final prefix = tag != null ? '[$tag] ' : '';
      print('❌ $prefix$message');
      if (error != null) print('   Error: $error');
      if (stackTrace != null && kDebugMode) print('   Stack: $stackTrace');
    }
  }
  
  // Feature-specific logging methods
  
  /// Dashboard-specific logging (disabled by default to prevent spam)
  static void dashboard(String message) {
    if (_enableDashboardLogs && _enableDebugLogs) {
      print('📊 [Dashboard] $message');
    }
  }
  
  /// Notification-specific logging (disabled by default to prevent spam)
  static void notification(String message) {
    if (_enableNotificationLogs && _enableDebugLogs) {
      print('🔔 [Notification] $message');
    }
  }
  
  /// Appointment-specific logging (disabled by default to prevent spam)
  static void appointment(String message) {
    if (_enableAppointmentLogs && _enableDebugLogs) {
      print('📅 [Appointment] $message');
    }
  }
  
  /// Firebase query logging (disabled by default to prevent spam)
  static void firebase(String message) {
    if (_enableFirebaseLogs && _enableDebugLogs) {
      print('🔥 [Firebase] $message');
    }
  }
  
  /// Success messages (always shown but not verbose)
  static void success(String message, {String? tag}) {
    final prefix = tag != null ? '[$tag] ' : '';
    print('✅ $prefix$message');
  }
  
  /// Performance timing (only in debug mode)
  static void performance(String operation, Duration duration) {
    if (_enableDebugLogs) {
      print('⏱️ [Performance] $operation took ${duration.inMilliseconds}ms');
    }
  }
}