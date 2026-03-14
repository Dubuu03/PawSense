import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawsense/core/widgets/admin/dashboard/recent_activity_list.dart';
import '../../../core/widgets/admin/dashboard/stats_cards_list.dart';
import '../../../core/widgets/admin/dashboard/loading_stats_card.dart';
import '../../../core/widgets/admin/dashboard/dashboard_header.dart';
import '../../../core/widgets/admin/dashboard/common_diseases_chart.dart';
import '../../../core/widgets/admin/dashboard/appointment_status_pie_chart.dart';
import '../../../core/widgets/admin/dashboard/common_diseases_pie_chart.dart';
import '../../../core/widgets/admin/dashboard/pet_type_pie_chart.dart';
import '../../../core/widgets/admin/dashboard/appointment_trends_chart.dart';
import '../../../core/widgets/admin/dashboard/monthly_comparison_chart.dart';
import '../../../core/widgets/admin/dashboard/response_time_card.dart';
import '../../../core/utils/app_colors.dart';
import '../../../core/services/admin/dashboard_service.dart';
import '../../../core/services/admin/admin_appointment_notification_integrator.dart';
import '../../../core/services/admin/admin_message_notification_integrator.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/guards/auth_guard.dart';
import '../../../core/widgets/admin/setup/admin_dashboard_setup_wrapper.dart';
import '../../../core/services/auth/auth_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key ?? const PageStorageKey('admin_dashboard'));

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with AutomaticKeepAliveClientMixin {
  String selectedPeriod = 'Daily';
  String? _clinicId;
  String? _userName; // User's display name
  bool _isLoadingStats = false; // Loading state for stats only
  DashboardStats? _currentStats;
  List<RecentActivity> _recentActivities = [];
  List<DiseaseData> _diseaseData = [];
  AppointmentStatusData? _appointmentStatusData;
  DiseaseEvaluationData? _commonDiseaseData;
  bool _isLoadingCharts = false;
  
  // New chart data
  Map<String, int> _petTypeDistribution = {};
  List<TrendDataPoint> _appointmentTrends = [];
  MonthlyComparison? _monthlyComparison;
  ResponseTimeData? _responseTimeData;
  bool _isLoadingNewCharts = false;
  
  // Cache for stats by period
  final Map<String, DashboardStats> _statsCache = {};
  
  // Cache for activities and diseases
  List<RecentActivity>? _cachedActivities;
  List<DiseaseData>? _cachedDiseases;
  AppointmentStatusData? _cachedAppointmentStatus;
  DiseaseEvaluationData? _cachedCommonDiseases;
  
  // Cache for new charts
  Map<String, int>? _cachedPetTypeDistribution;
  List<TrendDataPoint>? _cachedAppointmentTrends;
  MonthlyComparison? _cachedMonthlyComparison;
  ResponseTimeData? _cachedResponseTimeData;
  
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
    if (_statsCache.isEmpty || _cachedActivities == null || _cachedDiseases == null || 
        _cachedAppointmentStatus == null || _cachedCommonDiseases == null) {
      _loadDashboardData();
    } else {
      // Data already cached, just restore it
      print('📦 Dashboard data already cached - skipping load');
      _safeSetState(() {
        _currentStats = _statsCache[selectedPeriod.toLowerCase()];
        _recentActivities = _cachedActivities ?? [];
        _diseaseData = _cachedDiseases ?? [];
        _appointmentStatusData = _cachedAppointmentStatus;
        _commonDiseaseData = _cachedCommonDiseases;
      });
      // Still set up listener for updates and initialize notifications
      _setupAppointmentsListenerIfNeeded();
      // Initialize notifications after getting clinic ID
      _ensureNotificationIntegratorsInitialized();
    }
  }
  
  @override
  void dispose() {
    // Try to save state, but don't fail if context is already deactivated
    try {
      if (mounted) {
        _saveState();
      }
    } catch (e) {
      // Context might be deactivated during sign out - safe to ignore
      AppLogger.debug('Could not save state on dispose (widget deactivated): $e');
    }
    
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
    if (!mounted) return;
    
    try {
      final storage = PageStorage.maybeOf(context);
      if (storage == null) {
        AppLogger.debug('PageStorage not available - skipping state restore');
        return;
      }
      
      final savedPeriod = storage.readState(context, identifier: 'selectedPeriod');
      if (savedPeriod != null && savedPeriod is String) {
        _safeSetState(() {
          selectedPeriod = savedPeriod;
        });
        print('🔄 Restored dashboard state: period="$selectedPeriod"');
      }
    } catch (e) {
      AppLogger.debug('Error restoring state: $e');
    }
  }
  
  /// Save current state to PageStorage
  void _saveState() {
    // Guard against accessing deactivated context (e.g., during sign out)
    if (!mounted) {
      AppLogger.debug('Cannot save state - widget not mounted');
      return;
    }
    
    try {
      final storage = PageStorage.maybeOf(context);
      if (storage != null) {
        storage.writeState(context, selectedPeriod, identifier: 'selectedPeriod');
        print('💾 Saved dashboard state: period="$selectedPeriod"');
      } else {
        AppLogger.debug('PageStorage not available - skipping state save');
      }
    } catch (e) {
      AppLogger.debug('Error saving state: $e');
    }
  }

  /// Safe setState that prevents lifecycle crashes
  void _safeSetState(VoidCallback callback) {
    // If the widget is already disposed, skip immediately.
    if (!mounted) {
      AppLogger.debug('Skipping setState - widget not mounted');
      return;
    }

    // Schedule setState in a post-frame callback to avoid lifecycle races where
    // the element becomes defunct between the `mounted` check and the actual
    // setState call (this can happen during rapid navigator/pop sequences).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        AppLogger.debug('Skipping scheduled setState - widget disposed before frame');
        return;
      }

      try {
        setState(callback);
      } catch (e, st) {
        AppLogger.error('Error in setState: $e\n$st', tag: 'DashboardScreen');
        // Swallow the error to avoid crashing the app UI thread.
      }
    });
  }

  /// Get current user's display name
  Future<String?> _getCurrentUserName() async {
    try {
      final user = await AuthGuard.getCurrentUser();
      if (user == null) return null;

      // Build display name from firstName and lastName
      if (user.firstName != null && user.lastName != null) {
        return '${user.firstName} ${user.lastName}';
      } else if (user.firstName != null) {
        return user.firstName;
      } else if (user.lastName != null) {
        return user.lastName;
      } else {
        return user.username;
      }
    } catch (e) {
      AppLogger.error('Error getting current user name', error: e, tag: 'DashboardScreen');
      return null;
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
      // Get the current user's clinic ID and name
      final clinicId = await DashboardService.getCurrentUserClinicId();
      final userName = await _getCurrentUserName();
      
      print('🔍 Attempting to load dashboard data...');
      print('   User name: $userName');
      print('   Clinic ID: $clinicId');
      
      if (clinicId == null) {
        print('❌ ERROR: No clinic ID found for current user');
        AppLogger.error('No clinic ID found for current user', tag: 'DashboardScreen');
        _safeSetState(() {
          _isLoadingStats = false;
        });
        
        // Show error message to user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Unable to load clinic data. Please try logging in again.'),
              backgroundColor: AppColors.error,
              duration: Duration(seconds: 5),
            ),
          );
        }
        return;
      }

      _clinicId = clinicId;
      _userName = userName;
      print('✅ Dashboard initialized - Clinic ID: $_clinicId, User: $_userName');
      AppLogger.info('Clinic ID obtained: $_clinicId, User: $_userName');

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
        _loadAppointmentStatusData(),
        _loadCommonDiseaseData(),
        _loadNewAnalyticsData(),
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
    
    // Clear chart data cache when period changes or when appointments change
    _cachedAppointmentStatus = null;
    _cachedCommonDiseases = null;
    
    // Refresh chart data
    _loadAppointmentStatusData();
    _loadCommonDiseaseData();
    
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
      AppLogger.debug('Skipping _loadStats - widget disposed or invalid state (clinicId: $_clinicId, mounted: $mounted)');
      return;
    }

    final periodKey = selectedPeriod.toLowerCase();
    
    print('📊 Loading stats for clinic: $_clinicId, period: $periodKey');
    
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
      print('📡 Fetching dashboard stats from Firebase...');
      final stats = await DashboardService.getClinicDashboardStats(
        _clinicId!,
        period: periodKey,
      );

      print('📊 Stats received: appointments=${stats.totalAppointments}, completed=${stats.completedConsultations}, patients=${stats.activePatients}');

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
      print('❌ Error loading stats: $e');
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

  /// Load appointment status data for pie chart (with caching)
  Future<void> _loadAppointmentStatusData() async {
    if (_clinicId == null || !mounted) return;

    final periodKey = selectedPeriod.toLowerCase();

    // Check cache first
    if (_cachedAppointmentStatus?.period == periodKey) {
      print('Using cached appointment status data');
      _safeSetState(() {
        _appointmentStatusData = _cachedAppointmentStatus;
      });
      return;
    }

    try {
      final statusCounts = await DashboardService.getAppointmentStatusCounts(
        _clinicId!,
        period: periodKey,
      );

      final statusData = AppointmentStatusData(
        statusCounts: statusCounts,
        period: periodKey,
      );

      _cachedAppointmentStatus = statusData;
      
      _safeSetState(() {
        _appointmentStatusData = statusData;
      });
      
      print('Appointment status data loaded and cached');
    } catch (e) {
      print('Error loading appointment status data: $e');
    }
  }

  /// Load common disease data for pie chart (with caching)
  Future<void> _loadCommonDiseaseData() async {
    if (_clinicId == null || !mounted) return;

    final periodKey = selectedPeriod.toLowerCase();

    // Check cache first
    if (_cachedCommonDiseases?.period == periodKey) {
      print('Using cached common disease data');
      _safeSetState(() {
        _commonDiseaseData = _cachedCommonDiseases;
      });
      return;
    }

    try {
      final diseases = await DashboardService.getCommonDiseases(
        _clinicId!,
        limit: 8, // Get more diseases for pie chart
      );

      // Convert to DiseaseEvaluationData format for pie chart
      final diseaseMap = <String, int>{};
      for (final disease in diseases) {
        diseaseMap[disease.name] = disease.count;
      }

      final commonDiseaseData = DiseaseEvaluationData(
        diseaseCounts: diseaseMap,
        period: periodKey,
      );

      _cachedCommonDiseases = commonDiseaseData;
      
      _safeSetState(() {
        _commonDiseaseData = commonDiseaseData;
      });
      
      print('Common disease data loaded and cached');
    } catch (e) {
      print('Error loading common disease data: $e');
    }
  }

  /// Load new analytics data
  Future<void> _loadNewAnalyticsData() async {
    if (_clinicId == null || !mounted) return;

    // Check cache first
    if (_cachedPetTypeDistribution != null &&
        _cachedAppointmentTrends != null &&
        _cachedMonthlyComparison != null &&
        _cachedResponseTimeData != null) {
      print('Using cached new analytics data');
      _safeSetState(() {
        _petTypeDistribution = _cachedPetTypeDistribution!;
        _appointmentTrends = _cachedAppointmentTrends!;
        _monthlyComparison = _cachedMonthlyComparison;
        _responseTimeData = _cachedResponseTimeData;
      });
      return;
    }

    _safeSetState(() {
      _isLoadingNewCharts = true;
    });

    try {
      // Load all new analytics data in parallel
      final results = await Future.wait([
        DashboardService.getPetTypeDistribution(_clinicId!),
        DashboardService.getAppointmentTrends(_clinicId!),
        DashboardService.getMonthlyComparison(_clinicId!),
        DashboardService.getResponseTimeData(_clinicId!),
      ]);

      // Cache results
      _cachedPetTypeDistribution = results[0] as Map<String, int>;
      _cachedAppointmentTrends = results[1] as List<TrendDataPoint>;
      _cachedMonthlyComparison = results[2] as MonthlyComparison;
      _cachedResponseTimeData = results[3] as ResponseTimeData;

      _safeSetState(() {
        _petTypeDistribution = _cachedPetTypeDistribution!;
        _appointmentTrends = _cachedAppointmentTrends!;
        _monthlyComparison = _cachedMonthlyComparison;
        _responseTimeData = _cachedResponseTimeData;
        _isLoadingNewCharts = false;
      });

      print('New analytics data loaded and cached');
    } catch (e) {
      print('Error loading new analytics data: $e');
      _safeSetState(() {
        _isLoadingNewCharts = false;
      });
    }
  }

  /// Build loading skeleton for stats cards with static UI (title & icons)
  Widget _buildLoadingStatsCards() {
    // Static card configurations with titles and icons
    final loadingCards = [
      {
        'title': 'Total Appointments',
        'icon': Icons.calendar_today,
        'iconColor': AppColors.primary,
      },
      {
        'title': 'Consultations Completed',
        'icon': Icons.check_circle_outline,
        'iconColor': AppColors.success,
      },
      {
        'title': 'Active Patients',
        'icon': Icons.favorite_outline,
        'iconColor': AppColors.info,
      },
    ];

    return Row(
      children: List.generate(loadingCards.length, (index) {
        final card = loadingCards[index];
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index < loadingCards.length - 1 ? 16 : 0),
            child: LoadingStatsCard(
              title: card['title'] as String,
              icon: card['icon'] as IconData,
              iconColor: card['iconColor'] as Color,
            ),
          ),
        );
      }),
    );
  }

  /// Build empty state when no data is available
  Widget _buildEmptyStatsState() {
    return Container(
      height: 120,
      padding: EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline,
              size: 32,
              color: AppColors.info,
            ),
            SizedBox(width: 16),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No Dashboard Data Available',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Statistics will appear once you start receiving appointments.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build section header with icon
  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: AppColors.primary,
          ),
        ),
        SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: 0.3,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.border,
                  AppColors.border.withOpacity(0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Build a responsive two-card row that stacks on smaller widths.
  Widget _buildResponsiveDashboardRow({
    required Widget firstChild,
    required Widget secondChild,
    double spacing = 20,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const minTwoColumnWidth = 1280.0;
        final shouldStack = constraints.maxWidth < minTwoColumnWidth;
        final cardWidth = shouldStack
            ? constraints.maxWidth
            : (constraints.maxWidth - spacing) / 2;

        return SizedBox(
          width: double.infinity,
          child: Wrap(
            alignment: WrapAlignment.start,
            runAlignment: WrapAlignment.start,
            crossAxisAlignment: WrapCrossAlignment.start,
            spacing: spacing,
            runSpacing: spacing,
            children: [
              SizedBox(width: cardWidth, child: firstChild),
              SizedBox(width: cardWidth, child: secondChild),
            ],
          ),
        );
      },
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

    // Helper to format change text
    String formatChange(double change, int currentValue, String period) {
      if (currentValue == 0 && change == 0.0) {
        return 'No appointments yet';
      }
      if (change == 0.0) {
        return 'No change from last $period';
      }
      return '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}% from last $period';
    }

    // Helper to determine change color
    Color getChangeColor(double change, int currentValue) {
      if (currentValue == 0 && change == 0.0) {
        return AppColors.textSecondary;
      }
      return change >= 0 ? AppColors.success : AppColors.error;
    }

    return [
      {
        'title': 'Total Appointments',
        'value': '${stats.totalAppointments}',
        'change': formatChange(stats.appointmentsChange, stats.totalAppointments, periodText),
        'changeColor': getChangeColor(stats.appointmentsChange, stats.totalAppointments),
        'icon': Icons.calendar_today,
        'iconColor': AppColors.primary,
      },
      {
        'title': 'Consultations Completed',
        'value': '${stats.completedConsultations}',
        'change': formatChange(stats.consultationsChange, stats.completedConsultations, periodText),
        'changeColor': getChangeColor(stats.consultationsChange, stats.completedConsultations),
        'icon': Icons.check_circle_outline,
        'iconColor': AppColors.success,
      },
      {
        'title': 'Active Patients',
        'value': '${stats.activePatients}',
        'change': formatChange(stats.patientsChange, stats.activePatients, periodText),
        'changeColor': getChangeColor(stats.patientsChange, stats.activePatients),
        'icon': Icons.favorite_outline,
        'iconColor': AppColors.info,
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required by AutomaticKeepAliveClientMixin
    
    final statsCards = _getStatsCards();

    // Wrap dashboard with schedule setup check
    return FutureBuilder(
      future: AuthService().getUserClinic(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        return AdminDashboardWithSetupCheck(
          clinic: snapshot.data,
          onSetupCompleted: () {
            print('🎉 Dashboard: Setup completed callback received');
            // Clear all cached data and refresh everything
            _statsCache.clear();
            _cachedActivities = null;
            _cachedDiseases = null;
            _cachedAppointmentStatus = null;
            _cachedCommonDiseases = null;
            _clinicId = null;
            
            // Refresh clinic data and dashboard after setup completion
            _safeSetState(() {
              _isLoadingStats = true;
            });
            
            // Reload all data with a delay to ensure database updates are reflected
            Future.delayed(const Duration(milliseconds: 1000), () {
              _loadDashboardData();
            });
          },
          dashboardContent: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.background,
                  AppColors.background.withOpacity(0.8),
                ],
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.all(24.0),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                // ✅ Header appears immediately (no data dependency)
                DashboardHeader(
                  selectedPeriod: selectedPeriod,
                  userName: _userName,
                  onPeriodChanged: (period) {
                    _safeSetState(() {
                      selectedPeriod = period;
                    });
                    _loadStats(); // Reload stats when period changes
                    
                    // Clear cached chart data and reload for new period
                    _cachedAppointmentStatus = null;
                    _cachedCommonDiseases = null;
                    _loadAppointmentStatusData();
                    _loadCommonDiseaseData();
                  },
                ),
                SizedBox(height: 24),
                
                // Stats section with loading state
                _isLoadingStats
                    ? _buildLoadingStatsCards()
                    : _currentStats != null
                        ? StatsCards(statsList: statsCards)
                        : _buildEmptyStatsState(),
                SizedBox(height: 40),
                
                // Analytics Overview Section
                _buildSectionHeader('Analytics Overview', Icons.analytics),
                SizedBox(height: 20),
                
                // First row: Appointment Status and Common Diseases pie charts
                _buildResponsiveDashboardRow(
                  firstChild: AppointmentStatusPieChart(
                    statusData: _appointmentStatusData,
                    isLoading: _isLoadingCharts,
                  ),
                  secondChild: CommonDiseasesPieChart(
                    diseaseData: _commonDiseaseData,
                    isLoading: _isLoadingCharts,
                  ),
                ),
                
                SizedBox(height: 32),
                
                // Patient & Appointment Insights Section
                _buildSectionHeader('Patient & Appointment Insights', Icons.pets),
                SizedBox(height: 20),
                
                // Second row: Pet Type Distribution and Appointment Trends
                _buildResponsiveDashboardRow(
                  firstChild: PetTypePieChart(
                    petTypeDistribution: _petTypeDistribution,
                    isLoading: _isLoadingNewCharts,
                  ),
                  secondChild: AppointmentTrendsChart(
                    trendData: _appointmentTrends,
                    isLoading: _isLoadingNewCharts,
                  ),
                ),
                
                SizedBox(height: 32),
                
                // Performance Metrics Section
                _buildSectionHeader('Performance Metrics', Icons.speed),
                SizedBox(height: 20),
                
                // Third row: Monthly Comparison and Response Time
                _buildResponsiveDashboardRow(
                  firstChild: MonthlyComparisonChart(
                    comparisonData: _monthlyComparison ?? MonthlyComparison.empty(),
                    isLoading: _isLoadingNewCharts,
                  ),
                  secondChild: ResponseTimeCard(
                    responseData: _responseTimeData ?? ResponseTimeData.empty(),
                    isLoading: _isLoadingNewCharts,
                  ),
                ),
                
                SizedBox(height: 32),
                
                // Activity & Health Trends Section
                _buildSectionHeader('Activity & Health Trends', Icons.show_chart),
                SizedBox(height: 20),
                
                // Fourth row: Common diseases (bar chart view) and recent activities
                _buildResponsiveDashboardRow(
                  firstChild: CommonDiseasesChart(
                    diseaseData: _diseaseData,
                  ),
                  secondChild: RecentActivityList(
                    activities: _recentActivities,
                  ),
                ),
                
                SizedBox(height: 40), // Bottom padding
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
