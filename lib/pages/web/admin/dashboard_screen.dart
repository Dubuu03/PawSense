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
  String? _userName;
  bool _isLoadingStats = false;
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
  static const Duration _minRefreshInterval = Duration(seconds: 30);
  static const Duration _debounceDelay = Duration(seconds: 2);

  // Layout breakpoints
  static const double _twoColumnBreakpoint = 900.0;
  static const double _compactBreakpoint = 600.0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _restoreState();
    
    if (_statsCache.isEmpty || _cachedActivities == null || _cachedDiseases == null || 
        _cachedAppointmentStatus == null || _cachedCommonDiseases == null) {
      _loadDashboardData();
    } else {
      AppLogger.debug('Dashboard data already cached - skipping load');
      _safeSetState(() {
        _currentStats = _statsCache[selectedPeriod.toLowerCase()];
        _recentActivities = _cachedActivities ?? [];
        _diseaseData = _cachedDiseases ?? [];
        _appointmentStatusData = _cachedAppointmentStatus;
        _commonDiseaseData = _cachedCommonDiseases;
      });
      _setupAppointmentsListenerIfNeeded();
      _ensureNotificationIntegratorsInitialized();
    }
  }
  
  @override
  void dispose() {
    try {
      if (mounted) {
        _saveState();
      }
    } catch (e) {
      AppLogger.debug('Could not save state on dispose (widget deactivated): $e');
    }
    
    _appointmentsListener?.cancel();
    _refreshDebounceTimer?.cancel();
    super.dispose();
  }
  
  /// Initialize notification integrators for real-time notifications
  void _initializeNotificationIntegrators() {
    if (_clinicId == null || _notificationIntegratorsInitialized) return;
    
    AppLogger.info('Initializing notification integrators for clinic: $_clinicId');
    
    Future.delayed(const Duration(milliseconds: 500), () {
      AdminAppointmentNotificationIntegrator.initializeAppointmentListeners();
      AdminMessageNotificationIntegrator.initializeMessageListeners();
      AppLogger.info('Notification integrators initialized successfully');
    });
    
    _notificationIntegratorsInitialized = true;
  }
  
  /// Ensure notification integrators are initialized
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
        AppLogger.debug('Restored dashboard state: period="$selectedPeriod"');
      }
    } catch (e) {
      AppLogger.debug('Error restoring state: $e');
    }
  }
  
  /// Save current state to PageStorage
  void _saveState() {
    if (!mounted) {
      AppLogger.debug('Cannot save state - widget not mounted');
      return;
    }
    
    try {
      final storage = PageStorage.maybeOf(context);
      if (storage != null) {
        storage.writeState(context, selectedPeriod, identifier: 'selectedPeriod');
        AppLogger.debug('Saved dashboard state: period="$selectedPeriod"');
      } else {
        AppLogger.debug('PageStorage not available - skipping state save');
      }
    } catch (e) {
      AppLogger.debug('Error saving state: $e');
    }
  }

  /// Safe setState that prevents lifecycle crashes
  void _safeSetState(VoidCallback callback) {
    if (!mounted) {
      AppLogger.debug('Skipping setState - widget not mounted');
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        AppLogger.debug('Skipping scheduled setState - widget disposed before frame');
        return;
      }

      try {
        setState(callback);
      } catch (e, st) {
        AppLogger.error('Error in setState: $e\n$st', tag: 'DashboardScreen');
      }
    });
  }

  /// Get current user's display name
  Future<String?> _getCurrentUserName() async {
    try {
      final user = await AuthGuard.getCurrentUser();
      if (user == null) return null;

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

  /// Load dashboard data from Firebase
  Future<void> _loadDashboardData() async {
    if (!mounted) return;
    
    _safeSetState(() {
      _isLoadingStats = true;
    });

    try {
      final clinicId = await DashboardService.getCurrentUserClinicId();
      final userName = await _getCurrentUserName();
      
      AppLogger.info('Loading dashboard data - User: $userName, Clinic: $clinicId');
      
      if (clinicId == null) {
        AppLogger.error('No clinic ID found for current user', tag: 'DashboardScreen');
        _safeSetState(() {
          _isLoadingStats = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Unable to load clinic data. Please try logging in again.'),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 5),
            ),
          );
        }
        return;
      }

      _clinicId = clinicId;
      _userName = userName;
      AppLogger.info('Dashboard initialized - Clinic ID: $_clinicId, User: $_userName');

      _initializeNotificationIntegrators();

      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _setupAppointmentsListener();
        }
      });

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
    
    if (_appointmentsListener != null) {
      AppLogger.info('Firebase listener already active');
      return;
    }
    
    AppLogger.info('Setting up Firebase listener for clinic: $_clinicId');
    
    _appointmentsListener = FirebaseFirestore.instance
        .collection('appointments')
        .where('clinicId', isEqualTo: _clinicId)
        .snapshots()
        .listen((snapshot) {
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
      
      final now = DateTime.now();
      if (_lastRefreshTime != null && 
          now.difference(_lastRefreshTime!) < _minRefreshInterval) {
        AppLogger.debug('Refresh rate limited - ignoring change');
        return;
      }
      
      _refreshDebounceTimer?.cancel();
      
      _refreshDebounceTimer = Timer(_debounceDelay, () {
        if (mounted) {
          _lastRefreshTime = DateTime.now();
          _statsCache.clear();
          _debouncedDataRefresh();
        }
      });
    });
  }
  
  /// Debounced data refresh
  void _debouncedDataRefresh() {
    if (!mounted) {
      AppLogger.debug('Widget disposed, skipping refresh');
      return;
    }
    
    _loadStats();
    
    _cachedAppointmentStatus = null;
    _cachedCommonDiseases = null;
    
    _loadAppointmentStatusData();
    _loadCommonDiseaseData();
    
    if (_recentActivities.isEmpty || DateTime.now().millisecondsSinceEpoch % 2 == 0) {
      _cachedActivities = null;
      _loadRecentActivities();
    }
  }
  
  /// Set up listener only if clinic ID is available
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
    if (_clinicId == null || !mounted) {
      AppLogger.debug('Skipping _loadStats - clinicId: $_clinicId, mounted: $mounted');
      return;
    }

    final periodKey = selectedPeriod.toLowerCase();
    
    if (_statsCache.containsKey(periodKey)) {
      AppLogger.debug('Using cached stats for $periodKey');
      _safeSetState(() {
        _currentStats = _statsCache[periodKey];
      });
      return;
    }

    _safeSetState(() {
      _isLoadingStats = true;
    });

    try {
      final stats = await DashboardService.getClinicDashboardStats(
        _clinicId!,
        period: periodKey,
      );

      if (!mounted) {
        AppLogger.debug('Widget disposed during stats loading');
        return;
      }

      _statsCache[periodKey] = stats;
      
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

    if (_cachedActivities != null) {
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
    } catch (e) {
      AppLogger.error('Error loading recent activities', error: e, tag: 'DashboardScreen');
    }
  }

  /// Load disease data for chart (with caching)
  Future<void> _loadDiseaseData() async {
    if (_clinicId == null || !mounted) return;

    if (_cachedDiseases != null) {
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
    } catch (e) {
      AppLogger.error('Error loading disease data', error: e, tag: 'DashboardScreen');
    }
  }

  /// Load appointment status data (with caching)
  Future<void> _loadAppointmentStatusData() async {
    if (_clinicId == null || !mounted) return;

    final periodKey = selectedPeriod.toLowerCase();

    if (_cachedAppointmentStatus?.period == periodKey) {
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
    } catch (e) {
      AppLogger.error('Error loading appointment status data', error: e, tag: 'DashboardScreen');
    }
  }

  /// Load common disease data for pie chart (with caching)
  Future<void> _loadCommonDiseaseData() async {
    if (_clinicId == null || !mounted) return;

    final periodKey = selectedPeriod.toLowerCase();

    if (_cachedCommonDiseases?.period == periodKey) {
      _safeSetState(() {
        _commonDiseaseData = _cachedCommonDiseases;
      });
      return;
    }

    try {
      final diseases = await DashboardService.getCommonDiseases(
        _clinicId!,
        limit: 8,
      );

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
    } catch (e) {
      AppLogger.error('Error loading common disease data', error: e, tag: 'DashboardScreen');
    }
  }

  /// Load new analytics data
  Future<void> _loadNewAnalyticsData() async {
    if (_clinicId == null || !mounted) return;

    if (_cachedPetTypeDistribution != null &&
        _cachedAppointmentTrends != null &&
        _cachedMonthlyComparison != null &&
        _cachedResponseTimeData != null) {
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
      final results = await Future.wait([
        DashboardService.getPetTypeDistribution(_clinicId!),
        DashboardService.getAppointmentTrends(_clinicId!),
        DashboardService.getMonthlyComparison(_clinicId!),
        DashboardService.getResponseTimeData(_clinicId!),
      ]);

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
    } catch (e) {
      AppLogger.error('Error loading new analytics data', error: e, tag: 'DashboardScreen');
      _safeSetState(() {
        _isLoadingNewCharts = false;
      });
    }
  }

  /// Build loading skeleton for stats cards
  Widget _buildLoadingStatsCards(bool isCompact) {
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

    if (isCompact) {
      return Column(
        children: loadingCards.map((card) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: LoadingStatsCard(
              title: card['title'] as String,
              icon: card['icon'] as IconData,
              iconColor: card['iconColor'] as Color,
            ),
          );
        }).toList(),
      );
    }

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
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.info_outline,
            size: 32,
            color: AppColors.info,
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
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
          ),
        ],
      ),
    );
  }

  /// Build section header with icon
  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.border,
                  AppColors.border.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Build a responsive two-card row using IntrinsicHeight for equal heights.
  /// Falls back to a stacked column layout on narrow screens.
  Widget _buildResponsiveDashboardRow({
    required Widget firstChild,
    required Widget secondChild,
    double spacing = 20,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final shouldStack = constraints.maxWidth < _twoColumnBreakpoint;

        if (shouldStack) {
          return Column(
            children: [
              firstChild,
              SizedBox(height: spacing),
              secondChild,
            ],
          );
        }

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: firstChild),
              SizedBox(width: spacing),
              Expanded(child: secondChild),
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

    String formatChange(double change, int currentValue, String period) {
      if (currentValue == 0 && change == 0.0) {
        return 'No appointments yet';
      }
      if (change == 0.0) {
        return 'No change from last $period';
      }
      return '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}% from last $period';
    }

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
    super.build(context);
    
    final statsCards = _getStatsCards();

    return FutureBuilder(
      future: AuthService().getUserClinic(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        return AdminDashboardWithSetupCheck(
          clinic: snapshot.data,
          onSetupCompleted: () {
            AppLogger.info('Dashboard: Setup completed callback received');
            _statsCache.clear();
            _cachedActivities = null;
            _cachedDiseases = null;
            _cachedAppointmentStatus = null;
            _cachedCommonDiseases = null;
            _cachedPetTypeDistribution = null;
            _cachedAppointmentTrends = null;
            _cachedMonthlyComparison = null;
            _cachedResponseTimeData = null;
            _clinicId = null;
            
            _safeSetState(() {
              _isLoadingStats = true;
            });
            
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
                  AppColors.background.withValues(alpha: 0.8),
                ],
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < _compactBreakpoint;

                return SingleChildScrollView(
                  padding: EdgeInsets.all(isCompact ? 16.0 : 24.0),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        DashboardHeader(
                          selectedPeriod: selectedPeriod,
                          userName: _userName,
                          onPeriodChanged: (period) {
                            _safeSetState(() {
                              selectedPeriod = period;
                            });
                            _loadStats();
                            _cachedAppointmentStatus = null;
                            _cachedCommonDiseases = null;
                            _loadAppointmentStatusData();
                            _loadCommonDiseaseData();
                          },
                        ),
                        const SizedBox(height: 24),
                        
                        // Stats Cards — responsive row vs column
                        _isLoadingStats
                            ? _buildLoadingStatsCards(isCompact)
                            : _currentStats != null
                                ? _buildResponsiveStatsCards(statsCards, isCompact)
                                : _buildEmptyStatsState(),
                        const SizedBox(height: 40),
                        
                        // Analytics Overview Section
                        _buildSectionHeader('Analytics Overview', Icons.analytics),
                        const SizedBox(height: 20),
                        
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
                        
                        const SizedBox(height: 32),
                        
                        // Patient & Appointment Insights Section
                        _buildSectionHeader('Patient & Appointment Insights', Icons.pets),
                        const SizedBox(height: 20),
                        
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
                        
                        const SizedBox(height: 32),
                        
                        // Performance Metrics Section
                        _buildSectionHeader('Performance Metrics', Icons.speed),
                        const SizedBox(height: 20),
                        
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
                        
                        const SizedBox(height: 32),
                        
                        // Activity & Health Trends Section
                        _buildSectionHeader('Activity & Health Trends', Icons.show_chart),
                        const SizedBox(height: 20),
                        
                        _buildResponsiveDashboardRow(
                          firstChild: CommonDiseasesChart(
                            diseaseData: _diseaseData,
                          ),
                          secondChild: RecentActivityList(
                            activities: _recentActivities,
                          ),
                        ),
                        
                        const SizedBox(height: 40),
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

  /// Responsive stats cards — stacks vertically on compact screens
  Widget _buildResponsiveStatsCards(List<Map<String, dynamic>> statsCards, bool isCompact) {
    if (isCompact) {
      return Column(
        children: statsCards.map((stat) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: StatsCards(statsList: [stat]),
          );
        }).toList(),
      );
    }

    return StatsCards(statsList: statsCards);
  }
}
