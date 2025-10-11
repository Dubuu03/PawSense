import 'package:flutter/foundation.dart';
import '../../models/user/user_model.dart';
import '../../models/clinic/appointment_models.dart';
import '../../models/user/patient_data.dart';
import '../../models/support/support_ticket.dart';
import '../../models/support/faq_item_model.dart';
import '../../models/support/ticket_status.dart';
import '../../widgets/admin/patient_records/patient_status.dart';
import '../../utils/app_colors.dart';

/// Cache wrapper class
class _CachedData<T> {
  final T data;
  final DateTime expiry;
  
  _CachedData(this.data, this.expiry);
  
  bool get isExpired => DateTime.now().isAfter(expiry);
}

/// Data service abstraction layer for Firebase integration
/// This service provides a unified interface for data operations
/// Making it easy to switch between mock data and Firebase
class DataService {
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();

  // TODO: Replace with Firebase service when ready
  bool _useFirebase = false;
  
  // In-memory cache for performance optimization
  final Map<String, _CachedData> _cache = {};
  
  /// Cache helper methods
  void _cacheSet<T>(String key, T data, {Duration expiry = const Duration(minutes: 5)}) {
    _cache[key] = _CachedData(data, DateTime.now().add(expiry));
  }
  
  T? _cacheGet<T>(String key) {
    final cached = _cache[key];
    if (cached != null && !cached.isExpired) {
      return cached.data as T;
    }
    if (cached != null && cached.isExpired) {
      _cache.remove(key); // Clean expired cache
    }
    return null;
  }
  
  /// Clear specific cache or all cache
  void clearCache([String? key]) {
    if (key != null) {
      _cache.remove(key);
    } else {
      _cache.clear();
    }
  }
  
  /// Toggle between Firebase and mock data
  void enableFirebase(bool enabled) {
    _useFirebase = enabled;
    if (kDebugMode) {
      print('DataService: Firebase ${enabled ? 'enabled' : 'disabled'}');
    }
  }

  // User Management
  Future<UserModel?> getCurrentUser() async {
    // Check cache first
    final cached = _cacheGet<UserModel>('current_user');
    if (cached != null) return cached;
    
    UserModel? user;
    if (_useFirebase) {
      // TODO: Implement Firebase user retrieval
      throw UnimplementedError('Firebase integration pending');
    }
    
    // Mock data for development
    user = UserModel(
      uid: 'mock_user_123',
      username: 'Dr. Sarah Johnson',
      email: 'sarah.johnson@pawsense.com',
      contactNumber: '+1234567890',
      address: '123 Veterinary Street, Pet City',
      role: 'admin',
      createdAt: DateTime.now().subtract(Duration(days: 30)),
    );
    
    // Cache for 10 minutes
    _cacheSet('current_user', user, expiry: Duration(minutes: 10));
    
    return user;
  }

  Future<List<UserModel>> getAllUsers() async {
    // Check cache first
    final cached = _cacheGet<List<UserModel>>('all_users');
    if (cached != null) return cached;
    
    List<UserModel> users;
    if (_useFirebase) {
      // TODO: Implement Firebase user list retrieval
      throw UnimplementedError('Firebase integration pending');
    }

    // Mock data
    users = [
      UserModel(
        uid: 'user_1',
        username: 'John Pet Owner',
        email: 'john@example.com',
        role: 'user',
        createdAt: DateTime.now().subtract(Duration(days: 10)),
      ),
      UserModel(
        uid: 'admin_1',
        username: 'Dr. Smith',
        email: 'dr.smith@pawsense.com',
        role: 'admin',
        createdAt: DateTime.now().subtract(Duration(days: 60)),
      ),
    ];
    
    // Cache for 5 minutes - users change less frequently
    _cacheSet('all_users', users, expiry: Duration(minutes: 5));
    
    return users;
  }

  // Appointment Management
  Future<List<Appointment>> getAppointments({
    DateTime? startDate,
    DateTime? endDate,
    String? status,
  }) async {
    // Create cache key based on parameters
    final cacheKey = 'appointments_${startDate?.toIso8601String() ?? 'null'}_${endDate?.toIso8601String() ?? 'null'}_${status ?? 'all'}';
    
    // Check cache first
    final cached = _cacheGet<List<Appointment>>(cacheKey);
    if (cached != null) return cached;
    
    List<Appointment> appointments;
    if (_useFirebase) {
      // TODO: Implement Firebase appointments retrieval with filters
      throw UnimplementedError('Firebase integration pending');
    }

    // Mock data
    appointments = [
      Appointment(
        id: 'apt_mock_001',
        clinicId: 'clinic_mock_001',
        date: DateTime.now().add(Duration(days: 1)).toIso8601String().split('T')[0],
        time: '10:00',
        timeSlot: '10:00-10:20',
        pet: Pet(
          id: 'pet_mock_001',
          name: 'Fluffy',
          type: 'Dog',
          emoji: '🐕',
          breed: 'Golden Retriever',
          age: 3,
        ),
        diseaseReason: 'Regular health checkup',
        owner: Owner(
          id: 'owner_mock_001',
          name: 'John Doe',
          phone: '+1234567890',
          email: 'john.doe@email.com',
        ),
        status: AppointmentStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Appointment(
        id: 'apt_mock_002',
        clinicId: 'clinic_mock_001',
        date: DateTime.now().add(Duration(days: 2)).toIso8601String().split('T')[0],
        time: '14:00',
        timeSlot: '14:00-14:20',
        pet: Pet(
          id: 'pet_mock_002',
          name: 'Max',
          type: 'Dog',
          emoji: '🐕',
          breed: 'Labrador',
          age: 2,
        ),
        diseaseReason: 'Annual vaccination due',
        owner: Owner(
          id: 'owner_mock_002',
          name: 'Jane Smith',
          phone: '+1234567891',
          email: 'jane.smith@email.com',
        ),
        status: AppointmentStatus.confirmed,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
    
    // Apply filters to mock data if needed
    if (status != null) {
      final statusEnum = AppointmentStatus.values.firstWhere(
        (s) => s.toString().split('.').last == status.toLowerCase(),
        orElse: () => AppointmentStatus.pending,
      );
      appointments = appointments.where((a) => a.status == statusEnum).toList();
    }
    
    // Cache for 3 minutes - appointments change more frequently
    _cacheSet(cacheKey, appointments, expiry: Duration(minutes: 3));
    
    return appointments;
  }

  Future<bool> updateAppointmentStatus(String appointmentId, AppointmentStatus status) async {
    if (_useFirebase) {
      // TODO: Implement Firebase appointment status update
      throw UnimplementedError('Firebase integration pending');
    }

    // Mock success response
    await Future.delayed(Duration(seconds: 1));
    
    // Clear appointments cache since data has changed
    final keysToRemove = _cache.keys.where((key) => key.startsWith('appointments_')).toList();
    for (final key in keysToRemove) {
      _cache.remove(key);
    }
    
    return true;
  }

  // Patient Management
  Future<List<PatientData>> getPatients({int? limit}) async {
    // Check cache first
    final cacheKey = 'patients${limit != null ? '_limit_$limit' : ''}';
    final cached = _cacheGet<List<PatientData>>(cacheKey);
    if (cached != null) return cached;
    
    List<PatientData> patients;
    if (_useFirebase) {
      // TODO: Implement Firebase patient retrieval
      throw UnimplementedError('Firebase integration pending');
    }

    // Mock data
    patients = [
      PatientData(
        name: 'Buddy',
        breed: 'Golden Retriever',
        age: '3 years',
        weight: '30 kg',
        lastVisit: '2024-01-15',
        status: PatientStatus.healthy,
        confidencePercentage: 92,
        petIcon: '🐕',
        diseaseDetection: 'Healthy',
        cardColor: AppColors.success,
        type: 'Dog',
      ),
      PatientData(
        name: 'Whiskers',
        breed: 'Persian Cat',
        age: '5 years',
        weight: '4 kg',
        lastVisit: '2024-01-10',
        status: PatientStatus.treatment,
        confidencePercentage: 78,
        petIcon: '🐱',
        diseaseDetection: 'Under treatment',
        cardColor: AppColors.warning,
        type: 'Cat',
      ),
      // Add more mock patients for testing pagination
      PatientData(
        name: 'Charlie',
        breed: 'Labrador',
        age: '2 years',
        weight: '25 kg',
        lastVisit: '2024-01-12',
        status: PatientStatus.healthy,
        confidencePercentage: 95,
        petIcon: '🐕',
        diseaseDetection: 'Healthy',
        cardColor: AppColors.success,
        type: 'Dog',
      ),
    ];
    
    // Apply limit if specified
    if (limit != null && limit > 0) {
      patients = patients.take(limit).toList();
    }
    
    // Cache for 8 minutes - patient data doesn't change very frequently
    _cacheSet(cacheKey, patients, expiry: Duration(minutes: 8));
    
    return patients;
  }

  /// Get today's appointments - used by dashboard and navigation preloader
  Future<List<Appointment>> getTodayAppointments() async {
    final today = DateTime.now();
    final todayStr = today.toIso8601String().split('T')[0];
    
    // Check cache first - shorter cache for real-time data
    final cached = _cacheGet<List<Appointment>>('today_appointments_$todayStr');
    if (cached != null) return cached;
    
    // Get appointments for today
    final allAppointments = await getAppointments();
    final todayAppointments = allAppointments.where((appointment) => 
      appointment.date == todayStr
    ).toList();
    
    // Cache for 2 minutes - very short for real-time dashboard data
    _cacheSet('today_appointments_$todayStr', todayAppointments, expiry: Duration(minutes: 2));
    
    return todayAppointments;
  }

  // Support Management
  Future<List<SupportTicket>> getSupportTickets() async {
    if (_useFirebase) {
      // TODO: Implement Firebase support ticket retrieval
      throw UnimplementedError('Firebase integration pending');
    }

    // Mock data
    final now = DateTime.now();
    return [
      SupportTicket(
        id: 'ticket_1',
        title: 'Login Issues',
        description: 'Unable to log into the mobile app',
        category: 'Technical',
        status: TicketStatus.open,
        submitterName: 'John Doe',
        submitterEmail: 'john@example.com',
        createdAt: now.subtract(Duration(hours: 2)),
        lastReply: now.subtract(Duration(hours: 1)),
      ),
      SupportTicket(
        id: 'ticket_2',
        title: 'Appointment Booking',
        description: 'Cannot book appointments for next week',
        category: 'Booking',
        status: TicketStatus.inProgress,
        submitterName: 'Jane Smith',
        submitterEmail: 'jane@example.com',
        createdAt: now.subtract(Duration(days: 1)),
        lastReply: now.subtract(Duration(hours: 6)),
      ),
    ];
  }

  // FAQ Management
  Future<List<FAQItemModel>> getFAQs() async {
    if (_useFirebase) {
      // TODO: Implement Firebase FAQ retrieval
      throw UnimplementedError('Firebase integration pending');
    }

    // Mock data
    return [
      FAQItemModel(
        id: 'faq_1',
        question: 'How do I book an appointment?',
        answer: 'You can book an appointment through our mobile app or by calling our clinic directly.',
        category: 'Booking',
        views: 150,
        helpfulVotes: 42,
        isExpanded: false,
        createdAt: DateTime.now(),
        createdBy: 'system',
      ),
      FAQItemModel(
        id: 'faq_2',
        question: 'What should I bring to my pet\'s appointment?',
        answer: 'Please bring your pet\'s vaccination records, any medications they\'re currently taking, and a list of any concerns you have.',
        category: 'Appointments',
        views: 98,
        helpfulVotes: 35,
        isExpanded: false,
        createdAt: DateTime.now(),
        createdBy: 'system',
      ),
    ];
  }

  // Statistics and Analytics
  Future<Map<String, dynamic>> getDashboardStats(String period) async {
    if (_useFirebase) {
      // TODO: Implement Firebase stats retrieval
      throw UnimplementedError('Firebase integration pending');
    }

    // Mock data based on period
    final baseStats = {
      'totalAppointments': 85,
      'consultationsCompleted': 60,
      'activePatients': 500,
    };

    switch (period.toLowerCase()) {
      case 'daily':
        return {
          'totalAppointments': 12,
          'consultationsCompleted': 8,
          'activePatients': 142,
        };
      case 'weekly':
        return baseStats;
      case 'monthly':
        return {
          'totalAppointments': 320,
          'consultationsCompleted': 250,
          'activePatients': 1200,
        };
      default:
        return baseStats;
    }
  }

  // Search functionality
  Future<List<dynamic>> searchData(String query, {String? type}) async {
    if (_useFirebase) {
      // TODO: Implement Firebase search
      throw UnimplementedError('Firebase integration pending');
    }

    // Mock search functionality
    final results = <dynamic>[];
    
    if (type == null || type == 'patients') {
      final patients = await getPatients();
      results.addAll(patients.where((patient) => 
        patient.name.toLowerCase().contains(query.toLowerCase()) ||
        patient.breed.toLowerCase().contains(query.toLowerCase())
      ));
    }
    
    if (type == null || type == 'appointments') {
      final appointments = await getAppointments();
      results.addAll(appointments.where((appointment) => 
        appointment.pet.name.toLowerCase().contains(query.toLowerCase()) ||
        appointment.owner.name.toLowerCase().contains(query.toLowerCase())
      ));
    }
    
    return results;
  }

  // Preloading and Performance Optimization
  
  /// Preload data for specific screens to improve navigation performance
  Future<void> preloadForScreen(String screenName) async {
    final futures = <Future<void>>[];
    
    switch (screenName.toLowerCase()) {
      case 'dashboard':
        // Preload dashboard essentials
        futures.add(getCurrentUser().then((_) {}));
        futures.add(getTodayAppointments().then((_) {}));
        futures.add(getPatients(limit: 10).then((_) {}));
        futures.add(getSupportTickets().then((_) {}));
        break;
        
      case 'appointments':
        // Preload appointments data
        futures.add(getAppointments().then((_) {}));
        futures.add(getAppointments(status: 'pending').then((_) {}));
        futures.add(getAppointments(status: 'confirmed').then((_) {}));
        futures.add(getTodayAppointments().then((_) {}));
        break;
        
      case 'patients':
        futures.add(getPatients().then((_) {}));
        break;
        
      case 'support':
        futures.add(getSupportTickets().then((_) {}));
        futures.add(getFAQs().then((_) {}));
        break;
        
      case 'notifications':
        futures.add(getNotifications().then((_) {}));
        break;
        
      default:
        // Generic preload
        futures.add(getCurrentUser().then((_) {}));
    }
    
    // Execute all preloads in parallel but handle errors gracefully
    await Future.wait(futures.map((future) async {
      try {
        return await future;
      } catch (e) {
        if (kDebugMode) {
          print('DataService: Preload error for $screenName: $e');
        }
      }
    }));
  }

  /// Cache statistics for monitoring
  Map<String, dynamic> getCacheStats() {
    int activeEntries = 0;
    int expiredEntries = 0;
    
    for (final entry in _cache.values) {
      if (entry.isExpired) {
        expiredEntries++;
      } else {
        activeEntries++;
      }
    }
    
    return {
      'total_entries': _cache.length,
      'active_entries': activeEntries,
      'expired_entries': expiredEntries,
      'cache_hit_potential': _cache.isNotEmpty ? activeEntries / _cache.length : 0.0,
    };
  }

  // Notification Management
  Future<List<Map<String, dynamic>>> getNotifications() async {
    // Check cache first
    final cached = _cacheGet<List<Map<String, dynamic>>>('notifications');
    if (cached != null) return cached;
    
    List<Map<String, dynamic>> notifications;
    if (_useFirebase) {
      // TODO: Implement Firebase notification retrieval
      throw UnimplementedError('Firebase integration pending');
    }

    // Mock notifications
    notifications = [
      {
        'id': 'notif_1',
        'title': 'New Appointment Request',
        'description': 'John Doe has requested an appointment for Buddy',
        'timestamp': DateTime.now().subtract(Duration(minutes: 30)),
        'isUnread': true,
        'requiresAction': true,
        'type': 'appointment',
      },
      {
        'id': 'notif_2',
        'title': 'System Update',
        'description': 'PawSense system will be updated tonight at 2:00 AM',
        'timestamp': DateTime.now().subtract(Duration(hours: 2)),
        'isUnread': false,
        'requiresAction': false,
        'type': 'system',
      },
    ];
    
    // Cache for 2 minutes - notifications need to be fresh
    _cacheSet('notifications', notifications, expiry: Duration(minutes: 2));
    
    return notifications;
  }

  // Error Handling
  void handleError(String operation, dynamic error) {
    if (kDebugMode) {
      print('DataService Error in $operation: $error');
    }
    // TODO: Implement proper error logging with Firebase Crashlytics
  }
}

/// Service locator for easy access throughout the app
class ServiceLocator {
  static final DataService dataService = DataService();
}
