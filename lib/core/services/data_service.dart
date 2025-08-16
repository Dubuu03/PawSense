import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/appointment_models.dart';
import '../models/patient_data.dart';
import '../models/support_ticket.dart';
import '../models/faq_item_model.dart';
import '../models/ticket_status.dart';
import '../widgets/admin/patient_records/patient_status.dart';
import '../utils/app_colors.dart';

/// Data service abstraction layer for Firebase integration
/// This service provides a unified interface for data operations
/// Making it easy to switch between mock data and Firebase
class DataService {
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();

  // TODO: Replace with Firebase service when ready
  bool _useFirebase = false;
  
  /// Toggle between Firebase and mock data
  void enableFirebase(bool enabled) {
    _useFirebase = enabled;
    if (kDebugMode) {
      print('DataService: Firebase ${enabled ? 'enabled' : 'disabled'}');
    }
  }

  // User Management
  Future<UserModel?> getCurrentUser() async {
    if (_useFirebase) {
      // TODO: Implement Firebase user retrieval
      throw UnimplementedError('Firebase integration pending');
    }
    
    // Mock data for development
    return UserModel(
      uid: 'mock_user_123',
      username: 'Dr. Sarah Johnson',
      email: 'sarah.johnson@pawsense.com',
      contactNumber: '+1234567890',
      address: '123 Veterinary Street, Pet City',
      dateOfBirth: DateTime(1985, 5, 15),
      role: 'admin',
      createdAt: DateTime.now().subtract(Duration(days: 30)),
    );
  }

  Future<List<UserModel>> getAllUsers() async {
    if (_useFirebase) {
      // TODO: Implement Firebase user list retrieval
      throw UnimplementedError('Firebase integration pending');
    }

    // Mock data
    return [
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
  }

  // Appointment Management
  Future<List<Appointment>> getAppointments({
    DateTime? startDate,
    DateTime? endDate,
    String? status,
  }) async {
    if (_useFirebase) {
      // TODO: Implement Firebase appointments retrieval with filters
      throw UnimplementedError('Firebase integration pending');
    }

    // Mock data
    return [
      Appointment(
        date: DateTime.now().add(Duration(days: 1)).toIso8601String().split('T')[0],
        time: '10:00 AM',
        pet: Pet(name: 'Fluffy', type: 'Dog', emoji: '🐕'),
        diseaseReason: 'Regular health checkup',
        owner: Owner(name: 'John Doe', phone: '+1234567890'),
        status: AppointmentStatus.pending,
      ),
      Appointment(
        date: DateTime.now().add(Duration(days: 2)).toIso8601String().split('T')[0],
        time: '2:00 PM',
        pet: Pet(name: 'Max', type: 'Dog', emoji: '🐕'),
        diseaseReason: 'Annual vaccination due',
        owner: Owner(name: 'Jane Smith', phone: '+1234567891'),
        status: AppointmentStatus.confirmed,
      ),
    ];
  }

  Future<bool> updateAppointmentStatus(String appointmentId, AppointmentStatus status) async {
    if (_useFirebase) {
      // TODO: Implement Firebase appointment status update
      throw UnimplementedError('Firebase integration pending');
    }

    // Mock success response
    await Future.delayed(Duration(seconds: 1));
    return true;
  }

  // Patient Management
  Future<List<PatientData>> getPatients() async {
    if (_useFirebase) {
      // TODO: Implement Firebase patient retrieval
      throw UnimplementedError('Firebase integration pending');
    }

    // Mock data
    return [
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
    ];
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
      ),
      FAQItemModel(
        id: 'faq_2',
        question: 'What should I bring to my pet\'s appointment?',
        answer: 'Please bring your pet\'s vaccination records, any medications they\'re currently taking, and a list of any concerns you have.',
        category: 'Appointments',
        views: 98,
        helpfulVotes: 35,
        isExpanded: false,
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

  // Notification Management
  Future<List<Map<String, dynamic>>> getNotifications() async {
    if (_useFirebase) {
      // TODO: Implement Firebase notification retrieval
      throw UnimplementedError('Firebase integration pending');
    }

    // Mock notifications
    return [
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
