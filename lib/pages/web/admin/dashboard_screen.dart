import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawsense/core/widgets/admin/dashboard/recent_activity_list.dart';
import '../../../core/widgets/admin/dashboard/stats_cards_list.dart';
import '../../../core/widgets/admin/dashboard/dashboard_header.dart';
import '../../../core/widgets/admin/dashboard/common_diseases_chart.dart';
import '../../../core/utils/app_colors.dart';
import '../../../core/services/admin/dashboard_service.dart';
import '../../../core/services/admin/admin_appointment_notification_integrator.dart';
import '../../../core/services/admin/admin_message_notification_integrator.dart';
import '../../../core/utils/app_logger.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key ?? const PageStorageKey('admin_dashboard'));

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with AutomaticKeepAliveClientMixin {
  String selectedPeriod = 'Daily';
  String? _clinicId;
  bool _isLoadingStats = false; // Loading state for stats only
  DashboardStats? _currentStats;
  List<RecentActivity> _recentActivities = [];
  List<DiseaseData> _diseaseData = [];
  
  // Cache for stats by period
  final Map<String, DashboardStats> _statsCache = {};
  
  // Cache for activities and diseases
  List<RecentActivity>? _cachedActivities;
  List<DiseaseData>? _cachedDiseases;
  
  // Firebase listener subscription
  StreamSubscription? _appointmentsListener;
  
  // Notification integrators initialized flag
  bool _notificationIntegratorsInitialized = false;
  
  // Debouncing for appointment changes
  Timer? _refreshDebounceTimer;
  DateTime? _lastRefreshTime;
  static const Duration _minRefreshInterval = Duration(seconds: 30); // Minimum 30s between refreshes
  static const Duration _debounceDelay = Duration(seconds: 2); // 2s debounce delay

  @override
  bool get wantKeepAlive => true; // Keep state alive when navigating away

  @override
  void initState() {
    super.initState();
    _restoreState();
    
    // Header appears immediately (no data needed)
    // Only load data if not already cached
    if (_statsCache.isEmpty || _cachedActivities == null || _cachedDiseases == null) {
      _loadDashboardData();
    } else {
      // Data already cached, just restore it
      print('📦 Dashboard data already cached - skipping load');
      _safeSetState(() {
        _currentStats = _statsCache[selectedPeriod.toLowerCase()];
        _recentActivities = _cachedActivities ?? [];
        _diseaseData = _cachedDiseases ?? [];
      });
      // Still set up listener for updates and initialize notifications
      _setupAppointmentsListenerIfNeeded();
      // Initialize notifications after getting clinic ID
      _ensureNotificationIntegratorsInitialized();
    }
  }
  
  @override
  void dispose() {
    _saveState();
    // Cancel listener and debounce timer when widget is disposed
    _appointmentsListener?.cancel();
    _refreshDebounceTimer?.cancel();
    super.dispose();
  }
  
  /// Initialize notification integrators for real-time notifications
  void _initializeNotificationIntegrators() {
    if (_clinicId == null || _notificationIntegratorsInitialized) return;
    
    print('🔔 Initializing notification integrators for clinic: $_clinicId');
    
    // Initialize notification service first with a small delay to ensure it's ready
    Future.delayed(const Duration(milliseconds: 500), () {
      // Initialize appointment notification integrator (static method)
      AdminAppointmentNotificationIntegrator.initializeAppointmentListeners();
      
      // Initialize message notification integrator (static method)
      AdminMessageNotificationIntegrator.initializeMessageListeners();
      
      print('✅ Notification integrators initialized successfully');
    });
    
    _notificationIntegratorsInitialized = true;
  }
  
  /// Ensure notification integrators are initialized (get clinic ID if needed)
  Future<void> _ensureNotificationIntegratorsInitialized() async {
    if (_notificationIntegratorsInitialized) return;
    
    if (_clinicId == null) {
      final clinicId = await DashboardService.getCurrentUserClinicId();
      if (clinicId != null) {
        _clinicId = clinicId;
      }
    }
    
    _initializeNotificationIntegrators();
  }
  
  /// Restore state from PageStorage
  void _restoreState() {
    final storage = PageStorage.of(context);
    final savedPeriod = storage.readState(context, identifier: 'selectedPeriod');
    if (savedPeriod != null && savedPeriod is String) {
      _safeSetState(() {
        selectedPeriod = savedPeriod;
      });
      print('🔄 Restored dashboard state: period="$selectedPeriod"');
    }
  }
  
  /// Save current state to PageStorage
  void _saveState() {
    final storage = PageStorage.of(context);
    storage.writeState(context, selectedPeriod, identifier: 'selectedPeriod');
    print('💾 Saved dashboard state: period="$selectedPeriod"');
  }

  /// Safe setState that prevents lifecycle crashes
  void _safeSetState(VoidCallback callback) {
    if (!mounted) {
      AppLogger.debug('Skipping setState - widget not mounted');
      return;
    }
    
    try {
      setState(callback);
    } catch (e) {
      AppLogger.error('Error in setState: $e', tag: 'DashboardScreen');
      // Don't rethrow - just log and continue
    }
  }

  /// Load dashboard data from Firebase (header already visible)
  Future<void> _loadDashboardData() async {
    if (!mounted) return;
    
    // Don't show full loading state - header is already visible
    _safeSetState(() {
      _isLoadingStats = true; // Only show loading for stats section
    });

    try {
      // Get the current user's clinic ID
      final clinicId = await DashboardService.getCurrentUserClinicId();
      
      if (clinicId == null) {
        AppLogger.error('No clinic ID found for current user', tag: 'DashboardScreen');
        _safeSetState(() {
          _isLoadingStats = false;
        });
        return;
      }

      _clinicId = clinicId;
      AppLogger.info('Clinic ID obtained: $_clinicId');

      // Initialize notification integrators for real-time notifications
      _initializeNotificationIntegrators();

      // Set up real-time listener for appointments (delayed to avoid build conflicts)
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _setupAppointmentsListener();
        }
      });

      // Fetch all dashboard data in parallel
      AppLogger.info('Loading dashboard data...');
      await Future.wait([
        _loadStats(),
        _loadRecentActivities(),
        _loadDiseaseData(),
      ]);
      
      AppLogger.success('Dashboard data loaded successfully');
    } catch (e) {
      AppLogger.error('Error loading dashboard data', error: e, tag: 'DashboardScreen');
    }
  }
  
  /// Set up Firebase listener for appointments changes with debouncing
  void _setupAppointmentsListener() {
    if (_clinicId == null) return;
    
    // Don't set up multiple listeners
    if (_appointmentsListener != null) {
      AppLogger.info('Firebase listener already active');
      return;
    }
    
    AppLogger.info('Setting up Firebase listener for clinic: $_clinicId');
    
    // Listen to appointments collection for changes with debouncing
    _appointmentsListener = FirebaseFirestore.instance
        .collection('appointments')
        .where('clinicId', isEqualTo: _clinicId)
        .snapshots()
        .listen((snapshot) {
      // Only process significant changes (not just read operations)
      final hasSignificantChanges = snapshot.docChanges.any((change) => 
        change.type == DocumentChangeType.added || 
        change.type == DocumentChangeType.modified ||
        change.type == DocumentChangeType.removed
      );
      
      if (!hasSignificantChanges) {
        AppLogger.debug('Ignoring snapshot with no significant changes');
        return;
      }
      
      AppLogger.info('${snapshot.docChanges.length} appointment changes detected');
      
      // Implement rate limiting - don't refresh more than once every 30 seconds
      final now = DateTime.now();
      if (_lastRefreshTime != null && 
          now.difference(_lastRefreshTime!) < _minRefreshInterval) {
        AppLogger.debug('Refresh rate limited - ignoring change');
        return;
      }
      
      // Cancel previous debounce timer
      _refreshDebounceTimer?.cancel();
      
      // Set up debounced refresh
      _refreshDebounceTimer = Timer(_debounceDelay, () {
        if (mounted) {
          _lastRefreshTime = DateTime.now();
          
          // Clear only stats cache, keep activities and diseases longer
          _statsCache.clear();
          
          // Only refresh data if user is likely still viewing
          _debouncedDataRefresh();
        }
      });
    });
  }
  
  /// Debounced data refresh that's less aggressive
  void _debouncedDataRefresh() {
    // Only refresh if widget is still mounted
    if (!mounted) {
      AppLogger.debug('Widget disposed, skipping refresh');
      return;
    }
    
    // Only refresh stats which change most frequently
    _loadStats();
    
    // Refresh activities less frequently (every other refresh)
    if (_recentActivities.isEmpty || DateTime.now().millisecondsSinceEpoch % 2 == 0) {
      _cachedActivities = null;
      _loadRecentActivities();
    }
  }
  
  /// Set up listener only if clinic ID is available and listener doesn't exist
  Future<void> _setupAppointmentsListenerIfNeeded() async {
    if (_clinicId == null) {
      final clinicId = await DashboardService.getCurrentUserClinicId();
      if (clinicId != null) {
        _clinicId = clinicId;
      }
    }
    _setupAppointmentsListener();
  }
  


  /// Load statistics based on selected period (with caching)
  Future<void> _loadStats() async {
    // Critical widget lifecycle protection
    if (_clinicId == null || !mounted) {
      AppLogger.debug('Skipping _loadStats - widget disposed or invalid state');
      return;
    }

    final periodKey = selectedPeriod.toLowerCase();
    
    // Check cache first
    if (_statsCache.containsKey(periodKey)) {
      AppLogger.debug('Using cached stats for $periodKey');
      _safeSetState(() {
        _currentStats = _statsCache[periodKey];
      });
      return;
    }

    // Only show loading if widget is still active
    _safeSetState(() {
      _isLoadingStats = true;
    });

    try {
      final stats = await DashboardService.getClinicDashboardStats(
        _clinicId!,
        period: periodKey,
      );

      // Check again after async operation - critical!
      if (!mounted) {
        AppLogger.debug('Widget disposed during stats loading - skipping setState');
        return;
      }

      // Store in cache
      _statsCache[periodKey] = stats;
      
      // Final check before setState
      _safeSetState(() {
        _currentStats = stats;
        _isLoadingStats = false;
      });
      
      AppLogger.dashboard('Stats loaded and cached for $periodKey');
    } catch (e) {
      AppLogger.error('Error loading stats', error: e, tag: 'DashboardScreen');
      _safeSetState(() {
        _isLoadingStats = false;
      });
    }
  }

  /// Load recent activities (with caching)
  Future<void> _loadRecentActivities() async {
    if (_clinicId == null || !mounted) return;

    // Check cache first
    if (_cachedActivities != null) {
      print('Using cached activities');
      _safeSetState(() {
        _recentActivities = _cachedActivities!;
      });
      return;
    }

    try {
      final activities = await DashboardService.getRecentActivities(
        _clinicId!,
        limit: 10,
      );

      _cachedActivities = activities;
      
      _safeSetState(() {
        _recentActivities = activities;
      });
      
      print('Activities loaded and cached');
    } catch (e) {
      print('Error loading recent activities: $e');
    }
  }

  /// Load disease data for chart (with caching)
  Future<void> _loadDiseaseData() async {
    if (_clinicId == null || !mounted) return;

    // Check cache first
    if (_cachedDiseases != null) {
      print('Using cached diseases');
      _safeSetState(() {
        _diseaseData = _cachedDiseases!;
      });
      return;
    }

    try {
      final diseases = await DashboardService.getCommonDiseases(
        _clinicId!,
        limit: 5,
      );

      _cachedDiseases = diseases;
      
      _safeSetState(() {
        _diseaseData = diseases;
      });
      
      print('Diseases loaded and cached');
    } catch (e) {
      print('Error loading disease data: $e');
    }
  }

  /// Build loading skeleton for stats cards
  Widget _buildLoadingStatsCards() {
    return Row(
      children: List.generate(3, (index) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index < 2 ? 16 : 0),
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 2,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  /// Convert dashboard stats to stats card format
  List<Map<String, dynamic>> _getStatsCards() {
    if (_currentStats == null) {
      return [];
    }

    final stats = _currentStats!;
    final periodText = selectedPeriod == 'Daily' 
        ? 'day' 
        : selectedPeriod == 'Weekly' 
            ? 'week' 
            : 'month';

    return [
      {
        'title': 'Total Appointments',
        'value': '${stats.totalAppointments}',
        'change': '${stats.appointmentsChange >= 0 ? '+' : ''}${stats.appointmentsChange.toStringAsFixed(1)}% from last $periodText',
        'changeColor': stats.appointmentsChange >= 0 ? AppColors.success : AppColors.error,
        'icon': Icons.calendar_today,
        'iconColor': AppColors.primary,
      },
      {
        'title': 'Consultations Completed',
        'value': '${stats.completedConsultations}',
        'change': '${stats.consultationsChange >= 0 ? '+' : ''}${stats.consultationsChange.toStringAsFixed(1)}% from last $periodText',
        'changeColor': stats.consultationsChange >= 0 ? AppColors.success : AppColors.error,
        'icon': Icons.check_circle_outline,
        'iconColor': AppColors.success,
      },
      {
        'title': 'Active Patients',
        'value': '${stats.activePatients}',
        'change': '${stats.patientsChange >= 0 ? '+' : ''}${stats.patientsChange.toStringAsFixed(1)}% from last $periodText',
        'changeColor': stats.patientsChange >= 0 ? AppColors.success : AppColors.info,
        'icon': Icons.favorite_outline,
        'iconColor': AppColors.info,
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required by AutomaticKeepAliveClientMixin
    
    final statsCards = _getStatsCards();

    return Padding(
      padding: EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ Header appears immediately (no data dependency)
          DashboardHeader(
            selectedPeriod: selectedPeriod,
            onPeriodChanged: (period) {
              _safeSetState(() {
                selectedPeriod = period;
              });
              _loadStats(); // Reload stats when period changes
            },
          ),
          SizedBox(height: 24),
          
          // Stats section with loading state
          _isLoadingStats
              ? _buildLoadingStatsCards()
              : statsCards.isNotEmpty
                  ? StatsCards(statsList: statsCards)
                  : Center(
                      child: Container(
                        height: 120,
                        child: Center(
                          child: Text(
                            'No data available',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      ),
                    ),
          SizedBox(height: 32),
          
          // Charts and activities section
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 1,
                  child: CommonDiseasesChart(
                    diseaseData: _diseaseData,
                  ),
                ),
                SizedBox(width: 24),
                Expanded(
                  flex: 1,
                  child: RecentActivityList(
                    activities: _recentActivities,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
