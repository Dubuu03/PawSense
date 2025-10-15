import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:pawsense/core/models/user/user_model.dart';
import 'package:pawsense/core/guards/auth_guard.dart';
import 'package:pawsense/core/services/messaging/mobile_messaging_preferences_service.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';
import 'package:pawsense/core/widgets/user/shared/navigation/user_app_bar.dart';
import 'package:pawsense/core/widgets/user/shared/navigation/user_bottom_nav_bar.dart';
import 'package:pawsense/core/widgets/user/shared/tab_toggle.dart';
import 'package:pawsense/core/widgets/user/home/profile_header.dart';
import 'package:pawsense/core/widgets/user/home/pet_info_card.dart';
import 'package:pawsense/core/widgets/user/home/health_snapshot.dart';
import 'package:pawsense/core/widgets/user/home/nearby_clinics.dart';
import 'package:pawsense/core/widgets/user/home/services_grid.dart';
import 'package:pawsense/core/widgets/user/home/history_section.dart';
import 'package:pawsense/core/widgets/user/home/ai_history_list.dart';
import 'package:pawsense/core/widgets/user/home/appointment_history_list.dart';
import 'package:pawsense/core/widgets/user/shared/modals/pet_assessment_modal.dart';
import 'package:pawsense/core/widgets/shared/ui/scroll_to_top_fab.dart';
import 'package:pawsense/core/services/user/assessment_result_service.dart';
import 'package:pawsense/core/models/user/assessment_result_model.dart';
import 'package:pawsense/core/models/clinic/appointment_booking_model.dart' as booking;
import 'package:pawsense/core/services/mobile/appointment_booking_service.dart';
import 'package:pawsense/core/utils/data_cache.dart';
import 'package:pawsense/core/services/notifications/notification_service.dart';
import 'package:pawsense/core/services/notifications/global_notification_manager.dart';
import 'dart:async';

class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key});

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  UserModel? _userModel;
  bool _loading = true;
  int _currentNavIndex = 0;
  int _currentTabIndex = 0;
  int _currentHistorySubtabIndex = 0; // For history subtabs: 0=Assessment History, 1=Appointment History
  final GlobalKey<PetInfoCardState> _petCardKey = GlobalKey<PetInfoCardState>();
  bool _hasInitiallyLoaded = false; // Track if initial load is complete
  bool _isInternalTabSwitch = false; // Track if this is just a tab switch
  final ScrollController _historyScrollController = ScrollController(); // Scroll controller for history tab

  // Dynamic health data generated from AI history
  List<HealthData> _healthData = [];

  // Dynamic AI history data from database
  List<AIHistoryData> _aiHistory = [];
  bool _historyLoading = false;
  final AssessmentResultService _assessmentService = AssessmentResultService();
  
  // Dynamic appointment history data from database
  List<AppointmentHistoryData> _appointmentHistory = [];
  bool _appointmentHistoryLoading = false;
  StreamSubscription<List<booking.AppointmentBooking>>? _appointmentStreamSubscription;
  
  // Closest upcoming appointment data
  String? _nextAppointmentDate;
  String? _nextAppointmentTime;
  
  final DataCache _cache = DataCache();
  
  // Notification system
  int _notificationCount = 0;
  late Stream<int> _notificationStream;

  @override
  void initState() {
    super.initState();
    _fetchUser();
  }

  @override
  void dispose() {
    // Global notification manager handles cleanup automatically
    _appointmentStreamSubscription?.cancel();
    _historyScrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Check for query parameters to set initial tab
    final uri = GoRouterState.of(context).uri;
    final tabParam = uri.queryParameters['tab'];
    final subtabParam = uri.queryParameters['subtab'];
    final refreshParam = uri.queryParameters['refresh'];
    
    if (tabParam == 'history') {
      if (mounted) {
        setState(() {
          _currentTabIndex = 1; // History tab index
          
          // Set history subtab based on parameter
          if (subtabParam == 'assessment') {
            _currentHistorySubtabIndex = 0; // Assessment History
          } else if (subtabParam == 'appointments') {
            _currentHistorySubtabIndex = 1; // Appointment History
          }
        });
      }
    }
    
    // Only refresh pet card on initial load or when explicitly requested via refresh param
    // Don't refresh on internal tab switches
    final shouldRefresh = (!_hasInitiallyLoaded || refreshParam == 'pets') && !_isInternalTabSwitch;
    
    if (shouldRefresh) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _refreshPetCard();
          if (!_hasInitiallyLoaded) {
            if (mounted) {
              setState(() {
                _hasInitiallyLoaded = true;
              });
            }
          }
        }
      });
    }
    
    // Reset the internal tab switch flag
    _isInternalTabSwitch = false;
    
    // Also refresh assessment history when tab is history
    if (tabParam == 'history') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _userModel != null) {
          // Force refresh if coming from assessment completion
          final forceRefreshAssessment = refreshParam == 'assessment';
          // Force refresh if coming from appointment booking
          final forceRefreshAppointment = uri.queryParameters['refresh_appointments'] != null;
          
          print('DEBUG: Navigation to history tab detected, forceRefreshAssessment: $forceRefreshAssessment, forceRefreshAppointment: $forceRefreshAppointment, refreshParam: $refreshParam');
          
          if (forceRefreshAssessment && _userModel != null) {
            // Invalidate cache when new assessment is completed
            final cacheKey = CacheKeys.userAssessments(_userModel!.uid);
            _cache.invalidate(cacheKey);
            print('DEBUG: Assessment cache invalidated for key: $cacheKey');
          }
          
          if (forceRefreshAppointment && _userModel != null) {
            // Invalidate cache when new appointment is booked
            final cacheKey = 'user_appointments_${_userModel!.uid}';
            _cache.invalidate(cacheKey);
            print('DEBUG: Appointment cache invalidated for key: $cacheKey');
          }
          
          _fetchAssessmentHistory(forceRefresh: forceRefreshAssessment);
          _fetchAppointmentHistory(forceRefresh: forceRefreshAppointment);
          
          // Add a secondary refresh after 2 seconds for assessment completions
          // This helps ensure we get the data even if there are propagation delays
          if (forceRefreshAssessment) {
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted && _userModel != null) {
                print('DEBUG: Performing secondary refresh after assessment completion');
                _fetchAssessmentHistory(forceRefresh: true);
              }
            });
          }
          
          // Add a secondary refresh after 2 seconds for appointment bookings
          if (forceRefreshAppointment) {
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted && _userModel != null) {
                print('DEBUG: Performing secondary refresh after appointment booking');
                _fetchAppointmentHistory(forceRefresh: true);
              }
            });
          }
        }
      });
    }
  }

  void _refreshPetCard() {
    print('DEBUG: _refreshPetCard called');
    if (mounted && _petCardKey.currentState != null) {
      print('DEBUG: Calling refreshPets with forceRefresh=false (using cache)');
      _petCardKey.currentState!.refreshPets(forceRefresh: false);
    } else {
      print('DEBUG: Pet card widget not available for refresh');
    }
  }

  // Public method to refresh pets (can be called when returning from pets page)
  void refreshPets() {
    _refreshPetCard();
  }

  // Public method to refresh assessment history (can be called after completing assessment)
  void refreshAssessmentHistory({bool forceRefresh = true}) {
    // When called externally (like after assessment), usually want fresh data
    if (_userModel != null) {
      // Invalidate cache when new assessment is added
      final cacheKey = CacheKeys.userAssessments(_userModel!.uid);
      _cache.invalidate(cacheKey);
    }
    _fetchAssessmentHistory(forceRefresh: forceRefresh);
  }

  // Public method to refresh appointment history (can be called after booking appointment)
  void refreshAppointmentHistory({bool forceRefresh = true}) {
    // With streams, the data will automatically update, but we can restart the stream if needed
    if (_userModel != null) {
      print('DEBUG: Refreshing appointment history stream');
      _fetchAppointmentHistory(forceRefresh: forceRefresh);
    }
  }

  Future<void> _fetchUser() async {
    try {
      // Clear any stale authentication cache first
      AuthGuard.clearUserCache();
      
      final userModel = await AuthGuard.getCurrentUser();
      if (userModel != null) {
        print('DEBUG: Fetched user - UID: ${userModel.uid}, Email: ${userModel.email}, Role: ${userModel.role}');
        
        // Verify this is actually the current Firebase Auth user
        final firebaseUser = FirebaseAuth.instance.currentUser;
        if (firebaseUser != null && firebaseUser.uid != userModel.uid) {
          print('WARNING: User ID mismatch! Firebase: ${firebaseUser.uid}, AuthGuard: ${userModel.uid}');
          // Force re-authentication
          AuthGuard.clearUserCache();
          return;
        }
        
        // Initialize mobile messaging preferences for the user
        try {
          final preferencesService = MobileMessagingPreferencesService.instance;
          if (!preferencesService.isInitialized) {
            await preferencesService.initializeForUser(userModel.uid);
          }
        } catch (e) {
          print('Error initializing mobile messaging preferences: $e');
          // Don't block the UI for preferences initialization error
        }
        
        if (mounted) {
          setState(() {
            _userModel = userModel;
            _loading = false;
          });
        }
        
        // Fetch assessment history after user is loaded
        _fetchAssessmentHistory();
        
        // Fetch appointment history after user is loaded
        _fetchAppointmentHistory();
        
        // Initialize notification stream
        _initializeNotificationStream();
      } else {
        if (mounted) {
          setState(() {
            _loading = false;
          });
        }
      }
    } catch (e) {
      print('ERROR in _fetchUser: $e');
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _initializeNotificationStream() async {
    if (_userModel == null) {
      debugPrint('⚠️ Cannot initialize notifications: _userModel is null');
      return;
    }
    
    try {
      // Use global notification manager
      final globalManager = GlobalNotificationManager();
      
      // Listen to unread count changes
      globalManager.unreadCountStream.listen((count) {
        debugPrint('� Global unread count updated to: $count');
        if (mounted) {
          setState(() {
            _notificationCount = count;
          });
        }
      });
      
      // Get initial count
      final initialCount = globalManager.unreadCount;
      setState(() {
        _notificationCount = initialCount;
      });
      
      debugPrint('✅ Home page connected to global notification manager');
      debugPrint('📊 Initial unread count: $initialCount');
      
    } catch (e) {
      debugPrint('❌ Failed to connect to global notifications: $e');
      debugPrint('🔄 Falling back to old notification system');
      // Fallback to old system if needed
      _initializeFallbackNotifications();
    }
  }

  // Fallback method in case of initialization failure
  void _initializeFallbackNotifications() {
    if (_userModel == null) return;
    
    _notificationStream = NotificationService.getUnreadNotificationsCount(_userModel!.uid);
    _notificationStream.listen((count) {
      if (mounted) {
        setState(() {
          _notificationCount = count;
        });
      }
    });
  }

  // Debug method to test popup notifications (can be called manually for testing)
  void debugTestPopupNotification() {
    try {
      final globalManager = GlobalNotificationManager();
      globalManager.showTestPopup(context);
      debugPrint('🧪 Debug: Test popup notification triggered via global manager');
    } catch (e) {
      debugPrint('❌ Error in debug popup test: $e');
    }
  }

  Future<void> _fetchAssessmentHistory({bool forceRefresh = false}) async {
    if (_userModel == null) {
      print('DEBUG: User model is null, cannot fetch assessment history');
      return;
    }
    
    // Double-check user authentication before fetching
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null || firebaseUser.uid != _userModel!.uid) {
      print('WARNING: User authentication mismatch in _fetchAssessmentHistory');
      print('Firebase User: ${firebaseUser?.uid}, UserModel: ${_userModel!.uid}');
      AuthGuard.clearUserCache();
      return;
    }
    
    print('DEBUG: Fetching assessment history for user: ${_userModel!.uid}, forceRefresh: $forceRefresh');
    
    final cacheKey = CacheKeys.userAssessments(_userModel!.uid);
    
    // Try to get cached data first (unless forcing refresh)
    if (!forceRefresh) {
      final cachedAssessments = _cache.get<List<AssessmentResult>>(cacheKey);
      if (cachedAssessments != null) {
        print('DEBUG: Using cached assessments (${cachedAssessments.length} assessments)');
        
        final aiHistoryData = _convertAssessmentResultsToAIHistory(cachedAssessments);
        final healthData = _generateHealthDataFromAssessments(cachedAssessments);
        
        if (mounted) {
          setState(() {
            _aiHistory = aiHistoryData;
            _healthData = healthData;
            _historyLoading = false;
          });
        }
        return;
      }
    }
    
    // Show loading only if we don't have data yet
    final showLoading = _aiHistory.isEmpty;
    
    if (mounted && showLoading) {
      setState(() {
        _historyLoading = true;
      });
    }

    try {
      print('DEBUG: Fetching assessments from API for user: ${_userModel!.uid}');
      final assessmentResults = await _assessmentService.getAssessmentResultsByUserId(_userModel!.uid);
      print('DEBUG: Fetched ${assessmentResults.length} assessment results from API');
      
      // Verify all assessment results belong to the current user
      final invalidResults = assessmentResults.where((result) => result.userId != _userModel!.uid).toList();
      if (invalidResults.isNotEmpty) {
        print('ERROR: Found ${invalidResults.length} assessment results that do not belong to current user!');
        print('Current user: ${_userModel!.uid}');
        for (var result in invalidResults) {
          print('Invalid result: ${result.id} belongs to user: ${result.userId}');
        }
      }
      
      // Filter to only include results for current user (safety check)
      final validResults = assessmentResults.where((result) => result.userId == _userModel!.uid).toList();
      print('DEBUG: After filtering, ${validResults.length} valid assessment results for current user');
      
      // Cache the fresh data (3 minutes TTL)
      _cache.put(cacheKey, validResults, ttl: const Duration(minutes: 3));
      
      final aiHistoryData = _convertAssessmentResultsToAIHistory(validResults);
      print('DEBUG: Converted to ${aiHistoryData.length} AI history items');
      
      // Generate health data from assessment results
      final healthData = _generateHealthDataFromAssessments(validResults);
      print('DEBUG: Generated ${healthData.length} health data items');
      
      if (mounted) {
        setState(() {
          _aiHistory = aiHistoryData;
          _healthData = healthData;
          _historyLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching assessment history: $e');
      if (mounted) {
        setState(() {
          _historyLoading = false;
        });
      }
    }
  }

  Future<void> _fetchAppointmentHistory({bool forceRefresh = false}) async {
    if (_userModel == null) {
      print('DEBUG: User model is null, cannot fetch appointment history');
      return;
    }
    
    // Double-check user authentication before fetching
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null || firebaseUser.uid != _userModel!.uid) {
      print('WARNING: User authentication mismatch in _fetchAppointmentHistory');
      print('Firebase User: ${firebaseUser?.uid}, UserModel: ${_userModel!.uid}');
      AuthGuard.clearUserCache();
      return;
    }
    
    print('DEBUG: Fetching appointment history for user: ${_userModel!.uid}, forceRefresh: $forceRefresh');
    
    // Cancel existing subscription if any
    await _appointmentStreamSubscription?.cancel();
    
    // Show loading only if we don't have data yet
    final showLoading = _appointmentHistory.isEmpty;
    
    if (mounted && showLoading) {
      setState(() {
        _appointmentHistoryLoading = true;
      });
    }

    try {
      print('DEBUG: Setting up real-time appointment stream');
      
      // Subscribe to real-time updates
      _appointmentStreamSubscription = AppointmentBookingService
          .getUserAppointmentsStream(_userModel!.uid)
          .listen(
        (appointments) {
          print('DEBUG: Received ${appointments.length} appointments from stream');
          
          // Verify all appointments belong to the current user
          final invalidAppointments = appointments.where((appointment) => appointment.userId != _userModel!.uid).toList();
          if (invalidAppointments.isNotEmpty) {
            print('ERROR: Found ${invalidAppointments.length} appointments that do not belong to current user!');
            print('Current user: ${_userModel!.uid}');
            for (var appointment in invalidAppointments) {
              print('Invalid appointment: ${appointment.id} belongs to user: ${appointment.userId}');
            }
          }
          
          // Filter to only include appointments for current user (safety check)
          final validAppointments = appointments.where((appointment) => appointment.userId == _userModel!.uid).toList();
          print('DEBUG: After filtering, ${validAppointments.length} valid appointments for current user');
          
          final appointmentHistoryData = _convertAppointmentsToHistoryData(validAppointments);
          print('DEBUG: Converted to ${appointmentHistoryData.length} appointment history items');
          
          // Calculate closest upcoming appointment from real-time data
          _calculateClosestUpcomingAppointment(validAppointments);
          
          if (mounted) {
            setState(() {
              _appointmentHistory = appointmentHistoryData;
              _appointmentHistoryLoading = false;
            });
          }
        },
        onError: (error) {
          print('Error in appointment stream: $error');
          if (mounted) {
            setState(() {
              _appointmentHistoryLoading = false;
            });
          }
        },
      );
      
      print('DEBUG: Successfully subscribed to appointment stream');
    } catch (e) {
      print('Error setting up appointment stream: $e');
      if (mounted) {
        setState(() {
          _appointmentHistoryLoading = false;
        });
      }
    }
  }

  List<AppointmentHistoryData> _convertAppointmentsToHistoryData(List<booking.AppointmentBooking> appointments) {
    print('DEBUG: Converting ${appointments.length} appointments to history data');
    
    // Create a map to track unique appointments (ignoring status changes)
    // Key insight: Same appointment with different statuses = ONE appointment entry
    final Map<String, booking.AppointmentBooking> uniqueAppointments = {};
    
    for (final appointment in appointments) {
      // Create a unique key based ONLY on service, date, and time (NOT status)
      // This ensures that "Consultation Service 31/10 09:00" appears only ONCE
      // regardless of whether it was Pending → Confirmed → Cancelled
      final uniqueKey = '${appointment.serviceName}_${appointment.appointmentDate.toIso8601String().split('T')[0]}_${appointment.appointmentTime}';
      
      // Keep the appointment with the most recent update time (latest status)
      if (!uniqueAppointments.containsKey(uniqueKey)) {
        uniqueAppointments[uniqueKey] = appointment;
        print('DEBUG: Added new appointment: ${appointment.serviceName} on ${appointment.appointmentDate.toIso8601String().split('T')[0]} at ${appointment.appointmentTime} - Status: ${appointment.status}');
      } else {
        // Compare update times to keep the most recent version
        final existingAppointment = uniqueAppointments[uniqueKey]!;
        
        if (appointment.updatedAt.isAfter(existingAppointment.updatedAt)) {
          print('DEBUG: Updating appointment status: ${appointment.serviceName} from ${existingAppointment.status} to ${appointment.status}');
          uniqueAppointments[uniqueKey] = appointment;
        } else {
          print('DEBUG: Keeping existing appointment status: ${appointment.serviceName} - ${existingAppointment.status}');
        }
      }
    }
    
    print('DEBUG: After deduplication: ${uniqueAppointments.length} unique appointments');
    
    // Convert the unique appointments to history data
    return uniqueAppointments.values.map((appointment) {
      // Convert booking AppointmentStatus to history AppointmentStatus
      AppointmentStatus historyStatus;
      switch (appointment.status) {
        case booking.AppointmentStatus.pending:
          historyStatus = AppointmentStatus.pending;
          break;
        case booking.AppointmentStatus.confirmed:
          historyStatus = AppointmentStatus.confirmed;
          break;
        case booking.AppointmentStatus.completed:
          historyStatus = AppointmentStatus.completed;
          break;
        case booking.AppointmentStatus.cancelled:
        case booking.AppointmentStatus.rescheduled:
          historyStatus = AppointmentStatus.cancelled;
          break;
      }
      
      // Format the subtitle with date, time, and status
      final dateStr = '${appointment.appointmentDate.day}/${appointment.appointmentDate.month}';
      final statusStr = _getStatusDisplayName(appointment.status);
      final subtitle = '$dateStr • ${appointment.appointmentTime} • $statusStr';
      
      return AppointmentHistoryData(
        id: appointment.id ?? '',
        title: _getStatusTitle(appointment),
        subtitle: subtitle,
        status: historyStatus,
        timestamp: appointment.appointmentDate,
        clinicName: appointment.serviceName, // Store service name for reference
      );
    }).toList();
  }
  
  String _getStatusTitle(booking.AppointmentBooking appointment) {
    // Use service name as the primary title instead of just status
    return appointment.serviceName.isNotEmpty 
        ? appointment.serviceName 
        : 'Veterinary Appointment';
  }

  String _getStatusDisplayName(booking.AppointmentStatus status) {
    switch (status) {
      case booking.AppointmentStatus.pending:
        return 'Pending';
      case booking.AppointmentStatus.confirmed:
        return 'Confirmed';
      case booking.AppointmentStatus.completed:
        return 'Completed';
      case booking.AppointmentStatus.cancelled:
        return 'Cancelled';
      case booking.AppointmentStatus.rescheduled:
        return 'Rescheduled';
    }
  }

  void _calculateClosestUpcomingAppointment(List<booking.AppointmentBooking> appointments) {
    String? nextDate;
    String? nextTime;
    
    if (appointments.isNotEmpty) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day); // Start of today
      
      // Filter to only include confirmed appointments that are today or in the future
      final upcomingAppointments = appointments.where((appointment) {
        return appointment.status == booking.AppointmentStatus.confirmed &&
               (appointment.appointmentDate.isAtSameMomentAs(today) ||
                appointment.appointmentDate.isAfter(today));
      }).toList();
      
      // Sort by date and time to find the closest one
      if (upcomingAppointments.isNotEmpty) {
        upcomingAppointments.sort((a, b) {
          final dateComparison = a.appointmentDate.compareTo(b.appointmentDate);
          if (dateComparison != 0) return dateComparison;
          
          // If same date, sort by time
          return a.appointmentTime.compareTo(b.appointmentTime);
        });
        
        final closestAppointment = upcomingAppointments.first;
        // Format date as "Oct 9" or similar
        final appointmentDate = closestAppointment.appointmentDate;
        final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                       'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        nextDate = '${months[appointmentDate.month - 1]} ${appointmentDate.day}';
        nextTime = closestAppointment.appointmentTime;
        
        print('DEBUG: Found closest upcoming appointment: $nextDate at $nextTime');
      } else {
        print('DEBUG: No upcoming appointments found');
      }
    }
    
    // Update the state variables
    _nextAppointmentDate = nextDate;
    _nextAppointmentTime = nextTime;
  }

  List<AIHistoryData> _convertAssessmentResultsToAIHistory(List<AssessmentResult> assessmentResults) {
    List<AIHistoryData> aiHistoryList = [];
    
    print('DEBUG: Converting ${assessmentResults.length} assessment results');
    
    for (final result in assessmentResults) {
      print('DEBUG: Processing assessment ${result.id} with ${result.detectionResults.length} detection results');
      
      if (result.detectionResults.isEmpty) {
        // If no detection results at all, still show the assessment
        final aiHistoryItem = AIHistoryData(
          id: result.id ?? '${result.createdAt.millisecondsSinceEpoch}',
          title: 'Assessment completed',
          subtitle: _formatTimestamp(result.createdAt),
          type: AIDetectionType.mange, // Default type
          timestamp: result.createdAt,
          confidence: 0.0,
          imageUrl: result.imageUrls.isNotEmpty ? result.imageUrls.first : null,
        );
        aiHistoryList.add(aiHistoryItem);
        print('DEBUG: Added assessment with no detection results');
        continue;
      }
      
      // Find the highest confidence detection across ALL images in this assessment
      double highestConfidence = 0.0;
      String bestDetectionLabel = '';
      String? firstImageUrl;
      
      for (final detectionResult in result.detectionResults) {
        // Use the first available image URL
        if (firstImageUrl == null && detectionResult.imageUrl.isNotEmpty) {
          firstImageUrl = detectionResult.imageUrl;
        }
        
        for (final detection in detectionResult.detections) {
          if (detection.confidence > highestConfidence) {
            highestConfidence = detection.confidence;
            bestDetectionLabel = detection.label;
          }
        }
      }
      
      // Create a single history item for the entire assessment
      final String title;
      if (bestDetectionLabel.isNotEmpty) {
        title = _formatDetectionTitle(bestDetectionLabel, highestConfidence);
        print('DEBUG: Best detection across all images: $bestDetectionLabel with confidence $highestConfidence');
      } else {
        title = 'No conditions detected';
        print('DEBUG: No detections found across all images');
      }
      
      final aiHistoryItem = AIHistoryData(
        id: result.id ?? '${result.createdAt.millisecondsSinceEpoch}',
        title: title,
        subtitle: _formatTimestamp(result.createdAt),
        type: bestDetectionLabel.isNotEmpty ? _getAIDetectionType(bestDetectionLabel) : AIDetectionType.mange,
        timestamp: result.createdAt,
        confidence: highestConfidence,
        imageUrl: firstImageUrl,
      );
      
      aiHistoryList.add(aiHistoryItem);
      print('DEBUG: Added single AI history item for assessment: ${aiHistoryItem.title}');
    }
    
    // Sort by timestamp (newest first)
    aiHistoryList.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    print('DEBUG: Final AI history list has ${aiHistoryList.length} items');
    return aiHistoryList;
  }

  String _formatDetectionTitle(String label, double confidence) {
    final formattedLabel = label.replaceAll('_', ' ').split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
    
    if (confidence > 0.8) {
      return '$formattedLabel detected';
    } else if (confidence > 0.6) {
      return 'Possible $formattedLabel';
    } else {
      return 'Potential $formattedLabel signs';
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 60) {
      return 'Today • ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (difference.inHours < 24) {
      return 'Today • ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday • ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return '${weekdays[timestamp.weekday - 1]} • ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else {
      return '${timestamp.day}/${timestamp.month} • ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }

  AIDetectionType _getAIDetectionType(String label) {
    switch (label.toLowerCase()) {
      case 'mange':
        return AIDetectionType.mange;
      case 'ringworm':
        return AIDetectionType.ringworm;
      case 'pyoderma':
        return AIDetectionType.pyoderma;
      case 'hotspot':
      case 'hot_spot':
        return AIDetectionType.hotSpot;
      case 'fleas':
      case 'flea_allergy':
        return AIDetectionType.fleaAllergy;
      default:
        return AIDetectionType.mange; // Default fallback
    }
  }

  List<HealthData> _generateHealthDataFromAssessments(List<AssessmentResult> assessmentResults) {
    if (assessmentResults.isEmpty) return [];
    
    // Filter assessments from the last week
    final oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));
    final recentAssessments = assessmentResults
        .where((assessment) => assessment.createdAt.isAfter(oneWeekAgo))
        .toList();
    
    if (recentAssessments.isEmpty) return [];
    
    // Count detections by condition from recent assessments
    final Map<String, int> conditionCounts = {};
    
    for (final assessment in recentAssessments) {
      for (final detectionResult in assessment.detectionResults) {
        if (detectionResult.detections.isNotEmpty) {
          // Get only the highest confidence detection per image (matching our display logic)
          final sortedDetections = List<Detection>.from(detectionResult.detections);
          sortedDetections.sort((a, b) => b.confidence.compareTo(a.confidence));
          final highestDetection = sortedDetections.first;
          
          final condition = _formatConditionForSnapshot(highestDetection.label);
          conditionCounts[condition] = (conditionCounts[condition] ?? 0) + 1;
        }
      }
    }
    
    // Convert to HealthData objects with colors
    final colors = [
      const Color(0xFFFF9500), // Orange
      const Color(0xFF007AFF), // Blue
      const Color(0xFF8E44AD), // Purple
      const Color(0xFFE74C3C), // Red
      const Color(0xFF2ECC71), // Green
      const Color(0xFFF39C12), // Orange variant
      const Color(0xFF9B59B6), // Purple variant
      const Color(0xFF1ABC9C), // Teal
    ];
    
    final healthDataList = <HealthData>[];
    int colorIndex = 0;
    
    // Sort by count (highest first) and take top conditions
    final sortedConditions = conditionCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    for (final entry in sortedConditions.take(6)) {
      healthDataList.add(HealthData(
        condition: entry.key,
        count: entry.value,
        color: colors[colorIndex % colors.length],
      ));
      colorIndex++;
    }
    
    return healthDataList;
  }
  
  String _formatConditionForSnapshot(String condition) {
    // Format condition names for display
    return condition
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: UserAppBar(
        user: _userModel,
        onUserUpdated: (updatedUser) {
          setState(() {
            _userModel = updatedUser;
          });
        },
      ),
      body: _loading 
          ? _buildLoadingState()
          : _userModel != null 
              ? _currentTabIndex == 1 
                  ? _buildHistoryWithScrollToTop()
                  : _buildHomeContent()
              : _buildErrorState(),
      bottomNavigationBar: UserBottomNavBar(
        currentIndex: _currentNavIndex,
        notificationCount: _notificationCount, // Add notification count
        onIndexChanged: (index) {
          if (index == 2) {
            // Navigate to alerts page
            context.push('/alerts');
          } else {
            if (mounted) {
              setState(() {
                _currentNavIndex = index;
              });
            }
            // Only refresh pet card when home tab is selected AND we're coming from a different nav index
            // This prevents unnecessary refreshes when already on home tab
            if (index == 0 && _currentNavIndex != 0) {
              _refreshPetCard();
            }
          }
        },
        onCameraPressed: _showCameraDialog,
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
      ),
    );
  }

  Widget _buildErrorState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: 16),
          Text(
            'Unable to load user data',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    return RefreshIndicator(
      onRefresh: _fetchUser,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Tab Toggle
            Container(
              margin: const EdgeInsets.symmetric(horizontal: kMobileMarginHorizontal, vertical: kMobileSizedBoxXLarge),
              child: TabToggle(
                selectedIndex: _currentTabIndex,
                onTabChanged: (index) {
                  if (mounted) {
                    // Set flag to indicate this is an internal tab switch
                    _isInternalTabSwitch = true;
                    setState(() {
                      _currentTabIndex = index;
                    });
                  }
                },
                tabs: const ['Dashboard', 'History'],
              ),
            ),
            
            // Content based on selected tab
            if (_currentTabIndex == 0) ...[
              // Dashboard Tab
                Transform.translate(
                  offset: Offset(0, -kMobileSizedBoxXLarge),
                  child: Column(
                    children: [
                      ProfileHeader(
                        user: _userModel!,
                        onManagePressed: () async {
                          // Navigate to edit profile page
                          final updatedUser = await context.push('/edit-profile', extra: {
                            'user': _userModel!,
                          });
                          
                          // If user data was updated, refresh the page
                          if (updatedUser != null && updatedUser is UserModel) {
                            if (mounted) {
                              setState(() {
                                _userModel = updatedUser;
                              });
                            }
                          } else {
                            // Fallback: refresh user data from server
                            _fetchUser();
                          }
                        },
                      ),

                      PetInfoCard(
                        key: _petCardKey,
                        nextAppointmentDate: _nextAppointmentDate,
                        nextAppointmentTime: _nextAppointmentTime,
                      ),

                      // Add space between pets and health snapshot
                      const SizedBox(height: kMobileSizedBoxHuge),

                      HealthSnapshot(
                        healthData: _healthData,
                      ),

                      NearbyClinicsWidget(
                        onViewAllPressed: () {
                          // Handle view all clinics
                          print('View all clinics pressed');
                        },
                        onMessageClinic: (clinic) {
                          // Handle message clinic
                          print('Message clinic: ${clinic.name}');
                          // TODO: Navigate to messaging or contact page
                        },
                      ),

                      // Services moved below nearby clinics
                      ServicesGrid(
                        services: _getServices(),
                      ),
                    ],
                  ),
                ),
            ] else ...[
              // History Tab
              _buildHistoryContent(),
            ],
            
            const SizedBox(height: 32), // Bottom padding
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryContent() {
    return HistorySection(
      aiHistory: _aiHistory,
      appointmentHistory: _appointmentHistory,
      isHistoryLoading: _historyLoading,
      isAppointmentHistoryLoading: _appointmentHistoryLoading,
      initialSubtabIndex: _currentHistorySubtabIndex,
      onViewAllPressed: () {
        // Handle view all history
      },
      onAppointmentUpdated: () {
        // Refresh appointment history when an appointment is updated (e.g., cancelled)
        refreshAppointmentHistory(forceRefresh: true);
      },
    );
  }

  Widget _buildHistoryWithScrollToTop() {
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () async {
            await _fetchAssessmentHistory(forceRefresh: true);
            await _fetchAppointmentHistory(forceRefresh: true);
          },
          color: AppColors.primary,
          child: SingleChildScrollView(
            controller: _historyScrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                // Tab Toggle
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: kMobileMarginHorizontal, vertical: kMobileSizedBoxXLarge),
                  child: TabToggle(
                    selectedIndex: _currentTabIndex,
                    onTabChanged: (index) {
                      if (mounted) {
                        setState(() {
                          _currentTabIndex = index;
                          _isInternalTabSwitch = true;
                        });
                      }
                    },
                    tabs: const ['Dashboard', 'History'],
                  ),
                ),
                
                // History Content
                _buildHistoryContent(),
                
                const SizedBox(height: 32), // Bottom padding
              ],
            ),
          ),
        ),
        
        // Scroll to Top FAB
        Positioned(
          right: 16,
          bottom: 16,
          child: ScrollToTopFab(
            scrollController: _historyScrollController,
            showThreshold: 200.0,
            tooltip: 'Scroll to top',
          ),
        ),
      ],
    );
  }

  List<ServiceItem> _getServices() {
    return [
      ServiceItem(
        title: 'Book Appointment',
        subtitle: 'Schedule visit',
        icon: Icons.calendar_today,
        backgroundColor: const Color(0xFF8E44AD).withValues(alpha: 0.1),
        onTap: () {
          context.push('/book-appointment');
        },
      ),
      ServiceItem(
        title: 'Messages',
        subtitle: 'Chat with vets',
        icon: Icons.message,
        backgroundColor: const Color(0xFF007AFF).withValues(alpha: 0.1),
        onTap: () {
          context.push('/messaging?source=services');
        },
      ),
      ServiceItem(
        title: 'FAQs',
        subtitle: 'Common questions',
        icon: Icons.help_outline,
        backgroundColor: const Color(0xFFFF9500).withValues(alpha: 0.1),
        onTap: () {
          context.push('/faqs');
        },
      ),
      ServiceItem(
        title: 'Skin Disease Info',
        subtitle: 'Learn about conditions',
        icon: Icons.medical_information_outlined,
        backgroundColor: const Color(0xFF34C759).withValues(alpha: 0.1),
        onTap: () {
          context.push('/skin-disease-library?source=services');
        },
      ),
    ];
  }

  void _showCameraDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const PetAssessmentModal(),
    );
  }
}
