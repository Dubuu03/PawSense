import 'package:flutter/foundation.dart';
import '../../models/user/user_model.dart';
import '../../models/clinic/appointment_models.dart';
import '../../models/user/patient_data.dart';
import '../../models/support/support_ticket.dart';
import '../../models/support/faq_item_model.dart';
import '../../models/support/ticket_status.dart';
import 'cache_manager.dart';

/// Optimized data service with comprehensive caching for fast navigation
class OptimizedDataService {
  static final OptimizedDataService _instance = OptimizedDataService._internal();
  factory OptimizedDataService() => _instance;
  OptimizedDataService._internal();

  final CacheManager _cache = CacheManager();
  bool _useFirebase = false;

  // Cache durations for different data types
  static const Duration _userCacheDuration = Duration(minutes: 10);
  static const Duration _appointmentCacheDuration = Duration(minutes: 5);
  static const Duration _patientCacheDuration = Duration(minutes: 15);
  static const Duration _staticDataCacheDuration = Duration(hours: 1);

  /// Toggle between Firebase and mock data
  void enableFirebase(bool enabled) {
    _useFirebase = enabled;
    if (kDebugMode) {
      print('OptimizedDataService: Firebase ${enabled ? 'enabled' : 'disabled'}');
    }
  }

  // ========== USER MANAGEMENT ==========
  
  /// Get current user with caching
  Future<UserModel?> getCurrentUser() async {
    return await _cache.getOrFetchNullable(
      'current_user',
      () => _fetchCurrentUser(),
      expiry: _userCacheDuration,
    );
  }

  /// Get all users with caching
  Future<List<UserModel>> getAllUsers() async {
    final users = _cache.getByCategory<UserModel>('users');
    if (users.isNotEmpty) return users;

    final fetchedUsers = await _fetchAllUsers();
    for (final user in fetchedUsers) {
      _cache.cacheByCategory('users', 'user_${user.uid}', user, expiry: _userCacheDuration);
    }
    return fetchedUsers;
  }

  /// Get user by ID with caching
  Future<UserModel?> getUserById(String userId) async {
    return await _cache.getOrFetchNullable(
      'user_$userId',
      () => _fetchUserById(userId),
      expiry: _userCacheDuration,
    );
  }

  // ========== APPOINTMENT MANAGEMENT ==========
  
  /// Get appointments with caching and pagination support
  Future<List<Appointment>> getAppointments({
    String? status,
    DateTime? date,
    int page = 1,
    int limit = 20,
  }) async {
    final cacheKey = 'appointments_${status ?? 'all'}_${date?.toIso8601String() ?? 'all'}_${page}_$limit';
    
    final result = await _cache.getOrFetch(
      cacheKey,
      () => _fetchAppointments(status: status, date: date, page: page, limit: limit),
      expiry: _appointmentCacheDuration,
    );
    return result;
  }

  /// Get appointment by ID with caching
  Future<Appointment?> getAppointmentById(String appointmentId) async {
    return await _cache.getOrFetchNullable(
      'appointment_$appointmentId',
      () => _fetchAppointmentById(appointmentId),
      expiry: _appointmentCacheDuration,
    );
  }

  /// Get today's appointments (heavily cached for dashboard)
  Future<List<Appointment>> getTodayAppointments() async {
    final today = DateTime.now();
    final dateKey = '${today.year}-${today.month}-${today.day}';
    
    final result = await _cache.getOrFetch(
      'today_appointments_$dateKey',
      () => _fetchAppointments(date: today),
      expiry: const Duration(minutes: 2), // Very short cache for real-time data
    );
    return result;
  }

  // ========== PATIENT MANAGEMENT ==========
  
  /// Get patients with caching
  Future<List<PatientData>> getPatients({int page = 1, int limit = 50}) async {
    final cacheKey = 'patients_${page}_$limit';
    
    final result = await _cache.getOrFetch(
      cacheKey,
      () => _fetchPatients(page: page, limit: limit),
      expiry: _patientCacheDuration,
    );
    return result;
  }

  /// Get patient by ID with caching
  Future<PatientData?> getPatientById(String patientId) async {
    return await _cache.getOrFetchNullable(
      'patient_$patientId',
      () => _fetchPatientById(patientId),
      expiry: _patientCacheDuration,
    );
  }

  /// Search patients with temporary caching
  Future<List<PatientData>> searchPatients(String query) async {
    if (query.trim().isEmpty) return [];
    
    final cacheKey = 'search_patients_${query.toLowerCase().trim()}';
    
    final result = await _cache.getOrFetch(
      cacheKey,
      () => _fetchSearchPatients(query),
      expiry: const Duration(minutes: 5), // Shorter cache for search results
    );
    return result;
  }

  // ========== SUPPORT & TICKETS ==========
  
  /// Get support tickets with caching
  Future<List<SupportTicket>> getSupportTickets({TicketStatus? status}) async {
    final cacheKey = 'support_tickets_${status?.name ?? 'all'}';
    
    final result = await _cache.getOrFetch(
      cacheKey,
      () => _fetchSupportTickets(status: status),
      expiry: const Duration(minutes: 3),
    );
    return result;
  }

  /// Get FAQ items with long caching (static content)
  Future<List<FAQItemModel>> getFAQItems() async {
    final result = await _cache.getOrFetch(
      'faq_items',
      () => _fetchFAQItems(),
      expiry: _staticDataCacheDuration,
    );
    return result;
  }

  // ========== PRELOADING & OPTIMIZATION ==========
  
  /// Preload essential data for faster navigation
  Future<void> preloadEssentialData() async {
    final preloadTasks = [
      _cache.preload('current_user', () => _fetchCurrentUser(), expiry: _userCacheDuration),
      _cache.preload('today_appointments_${_getTodayKey()}', () => _fetchAppointments(date: DateTime.now())),
      _cache.preload('faq_items', () => _fetchFAQItems(), expiry: _staticDataCacheDuration),
    ];

    await Future.wait(preloadTasks);
  }

  /// Preload data for specific screen
  Future<void> preloadForScreen(String screenName) async {
    switch (screenName.toLowerCase()) {
      case 'dashboard':
        await Future.wait([
          _cache.preload('today_appointments_${_getTodayKey()}', () => _fetchAppointments(date: DateTime.now())),
          _cache.preload('patients_1_10', () => _fetchPatients(limit: 10)), // Recent patients
        ]);
        break;
        
      case 'appointments':
        await Future.wait([
          _cache.preload('appointments_all_all_1_20', () => _fetchAppointments()),
          _cache.preload('appointments_pending_all_1_20', () => _fetchAppointments(status: 'pending')),
        ]);
        break;
        
      case 'patients':
        await _cache.preload('patients_1_50', () => _fetchPatients());
        break;
        
      case 'support':
        await Future.wait([
          _cache.preload('support_tickets_all', () => _fetchSupportTickets()),
          _cache.preload('faq_items', () => _fetchFAQItems(), expiry: _staticDataCacheDuration),
        ]);
        break;
    }
  }

  /// Batch preload for multiple screens
  Future<void> batchPreload(List<String> screens) async {
    final preloadTasks = screens.map((screen) => preloadForScreen(screen));
    await Future.wait(preloadTasks);
  }

  // ========== CACHE MANAGEMENT ==========
  
  /// Invalidate cache for specific data type
  void invalidateCache(String type, [String? id]) {
    switch (type.toLowerCase()) {
      case 'user':
        if (id != null) {
          _cache.invalidate('user_$id');
        } else {
          _cache.invalidateCategory('users');
          _cache.invalidate('current_user');
        }
        break;
        
      case 'appointment':
        if (id != null) {
          _cache.invalidate('appointment_$id');
        } else {
          _cache.invalidateCategory('appointments');
          // Clear all appointment-related cache
          final keys = ['today_appointments', 'appointments_'];
          for (final key in keys) {
            _invalidateKeysContaining(key);
          }
        }
        break;
        
      case 'patient':
        if (id != null) {
          _cache.invalidate('patient_$id');
        } else {
          _cache.invalidateCategory('patients');
          _invalidateKeysContaining('patients_');
          _invalidateKeysContaining('search_patients_');
        }
        break;
    }
  }

  /// Get cache statistics
  CacheStats getCacheStats() => _cache.getStats();

  /// Clear all cache
  void clearAllCache() => _cache.clearAll();

  // ========== PRIVATE FETCH METHODS ==========
  
  Future<UserModel?> _fetchCurrentUser() async {
    if (_useFirebase) {
      // TODO: Implement Firebase user retrieval
      throw UnimplementedError('Firebase integration pending');
    }
    
    // Simulate network delay for mock data
    await Future.delayed(const Duration(milliseconds: 200));
    
    return UserModel(
      uid: 'mock_user_123',
      username: 'Dr. Sarah Johnson',
      email: 'sarah.johnson@pawsense.com',
      contactNumber: '+1234567890',
      address: '123 Veterinary Street, Pet City',
      role: 'admin',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    );
  }

  Future<List<UserModel>> _fetchAllUsers() async {
    if (_useFirebase) {
      throw UnimplementedError('Firebase integration pending');
    }
    
    await Future.delayed(const Duration(milliseconds: 300));
    
    return [
      UserModel(uid: 'user_1', username: 'John Pet Owner', email: 'john@example.com', role: 'user', createdAt: DateTime.now().subtract(const Duration(days: 10))),
      UserModel(uid: 'user_2', username: 'Jane Doe', email: 'jane@example.com', role: 'user', createdAt: DateTime.now().subtract(const Duration(days: 5))),
    ];
  }

  Future<UserModel?> _fetchUserById(String userId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    // Mock implementation
    return UserModel(uid: userId, username: 'User $userId', email: '$userId@example.com', role: 'user', createdAt: DateTime.now());
  }

  Future<List<Appointment>> _fetchAppointments({String? status, DateTime? date, int page = 1, int limit = 20}) async {
    await Future.delayed(const Duration(milliseconds: 250));
    // Mock implementation - return empty list for now
    return [];
  }

  Future<Appointment?> _fetchAppointmentById(String appointmentId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    // Mock implementation
    return null;
  }

  Future<List<PatientData>> _fetchPatients({int page = 1, int limit = 50}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // Mock implementation
    return [];
  }

  Future<PatientData?> _fetchPatientById(String patientId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    // Mock implementation
    return null;
  }

  Future<List<PatientData>> _fetchSearchPatients(String query) async {
    await Future.delayed(const Duration(milliseconds: 200));
    // Mock implementation
    return [];
  }

  Future<List<SupportTicket>> _fetchSupportTickets({TicketStatus? status}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    // Mock implementation
    return [];
  }

  Future<List<FAQItemModel>> _fetchFAQItems() async {
    await Future.delayed(const Duration(milliseconds: 100));
    
    return [
      FAQItemModel(
        id: 'faq_1',
        question: 'How do I book an appointment?',
        answer: 'You can book an appointment through our mobile app or website.',
        category: 'General',
        views: 0,
        helpfulVotes: 0,
        isExpanded: false,
        createdAt: DateTime.now(),
        createdBy: 'system',
      ),
      FAQItemModel(
        id: 'faq_2',
        question: 'What are your operating hours?',
        answer: 'We are open Monday to Friday, 8 AM to 6 PM, and Saturday 9 AM to 4 PM.',
        category: 'General',
        views: 0,
        helpfulVotes: 0,
        isExpanded: false,
        createdAt: DateTime.now(),
        createdBy: 'system',
      ),
    ];
  }

  // ========== HELPER METHODS ==========
  
  String _getTodayKey() {
    final today = DateTime.now();
    return '${today.year}-${today.month}-${today.day}';
  }

  void _invalidateKeysContaining(String pattern) {
    // This would need to be implemented in CacheManager
    // For now, we'll use a simple approach
    _cache.clearAll(); // Temporary solution
  }
}
