import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawsense/core/widgets/admin/dashboard/recent_activity_list.dart';
import '../../../core/widgets/admin/dashboard/stats_cards_list.dart';
import '../../../core/widgets/admin/dashboard/dashboard_header.dart';
import '../../../core/widgets/admin/dashboard/common_diseases_chart.dart';
import '../../../core/utils/app_colors.dart';
import '../../../core/services/admin/dashboard_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key ?? const PageStorageKey('admin_dashboard'));

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with AutomaticKeepAliveClientMixin {
  String selectedPeriod = 'Daily';
  String? _clinicId;
  bool _isLoading = true;
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

  @override
  bool get wantKeepAlive => true; // Keep state alive when navigating away

  @override
  void initState() {
    super.initState();
    _restoreState();
    // Only load data if not already cached
    if (_statsCache.isEmpty || _cachedActivities == null || _cachedDiseases == null) {
      _loadDashboardData();
    } else {
      // Data already cached, just restore it
      print('📦 Dashboard data already cached - skipping load');
      setState(() {
        _isLoading = false;
        _currentStats = _statsCache[selectedPeriod.toLowerCase()];
        _recentActivities = _cachedActivities ?? [];
        _diseaseData = _cachedDiseases ?? [];
      });
      // Still set up listener for updates
      _setupAppointmentsListenerIfNeeded();
    }
  }
  
  @override
  void dispose() {
    _saveState();
    // Cancel listener when widget is disposed
    _appointmentsListener?.cancel();
    super.dispose();
  }
  
  /// Restore state from PageStorage
  void _restoreState() {
    final storage = PageStorage.of(context);
    final savedPeriod = storage.readState(context, identifier: 'selectedPeriod');
    if (savedPeriod != null && savedPeriod is String) {
      setState(() {
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

  /// Load dashboard data from Firebase
  Future<void> _loadDashboardData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Get the current user's clinic ID
      final clinicId = await DashboardService.getCurrentUserClinicId();
      
      if (clinicId == null) {
        print('Error: No clinic ID found for current user');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      _clinicId = clinicId;

      // Set up real-time listener for appointments
      _setupAppointmentsListener();

      // Fetch all dashboard data
      await Future.wait([
        _loadStats(),
        _loadRecentActivities(),
        _loadDiseaseData(),
      ]);
    } catch (e) {
      print('Error loading dashboard data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  /// Set up Firebase listener for appointments changes
  void _setupAppointmentsListener() {
    if (_clinicId == null) return;
    
    // Don't set up multiple listeners
    if (_appointmentsListener != null) {
      print('Firebase listener already active');
      return;
    }
    
    print('Setting up Firebase listener for clinic: $_clinicId');
    
    // Listen to appointments collection for changes
    _appointmentsListener = FirebaseFirestore.instance
        .collection('appointments')
        .where('clinicId', isEqualTo: _clinicId)
        .snapshots()
        .listen((snapshot) {
      // When appointments change, clear cache and reload data
      print('Appointments changed - ${snapshot.docChanges.length} changes detected');
      
      // Clear all cached data (stats, activities, diseases)
      _statsCache.clear();
      _cachedActivities = null;
      _cachedDiseases = null;
      
      // Reload current view data without showing loading state
      _refreshDataSilently();
    });
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
  
  /// Refresh data without showing loading indicators
  Future<void> _refreshDataSilently() async {
    if (_clinicId == null || !mounted) return;
    
    try {
      // Reload stats for current period
      final stats = await DashboardService.getClinicDashboardStats(
        _clinicId!,
        period: selectedPeriod.toLowerCase(),
      );
      
      // Update cache
      _statsCache[selectedPeriod.toLowerCase()] = stats;
      
      // Reload activities and diseases
      final activities = await DashboardService.getRecentActivities(
        _clinicId!,
        limit: 10,
      );
      
      final diseases = await DashboardService.getCommonDiseases(
        _clinicId!,
        limit: 5,
      );
      
      // Update caches
      _cachedActivities = activities;
      _cachedDiseases = diseases;
      
      // Only update UI if widget is still mounted
      if (mounted) {
        setState(() {
          _currentStats = stats;
          _recentActivities = activities;
          _diseaseData = diseases;
        });
        print('Dashboard data refreshed silently');
      }
    } catch (e) {
      print('Error refreshing data: $e');
    }
  }

  /// Load statistics based on selected period (with caching)
  Future<void> _loadStats() async {
    if (_clinicId == null || !mounted) return;

    final periodKey = selectedPeriod.toLowerCase();
    
    // Check cache first
    if (_statsCache.containsKey(periodKey)) {
      print('Using cached stats for $periodKey');
      if (mounted) {
        setState(() {
          _currentStats = _statsCache[periodKey];
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoadingStats = true;
      });
    }

    try {
      final stats = await DashboardService.getClinicDashboardStats(
        _clinicId!,
        period: periodKey,
      );

      // Store in cache
      _statsCache[periodKey] = stats;
      
      if (mounted) {
        setState(() {
          _currentStats = stats;
          _isLoadingStats = false;
        });
      }
      
      print('Stats loaded and cached for $periodKey');
    } catch (e) {
      print('Error loading stats: $e');
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
        });
      }
    }
  }

  /// Load recent activities (with caching)
  Future<void> _loadRecentActivities() async {
    if (_clinicId == null || !mounted) return;

    // Check cache first
    if (_cachedActivities != null) {
      print('Using cached activities');
      if (mounted) {
        setState(() {
          _recentActivities = _cachedActivities!;
        });
      }
      return;
    }

    try {
      final activities = await DashboardService.getRecentActivities(
        _clinicId!,
        limit: 10,
      );

      _cachedActivities = activities;
      
      if (mounted) {
        setState(() {
          _recentActivities = activities;
        });
      }
      
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
      if (mounted) {
        setState(() {
          _diseaseData = _cachedDiseases!;
        });
      }
      return;
    }

    try {
      final diseases = await DashboardService.getCommonDiseases(
        _clinicId!,
        limit: 5,
      );

      _cachedDiseases = diseases;
      
      if (mounted) {
        setState(() {
          _diseaseData = diseases;
        });
      }
      
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
    
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }

    final statsCards = _getStatsCards();

    return Padding(
      padding: EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DashboardHeader(
            selectedPeriod: selectedPeriod,
            onPeriodChanged: (period) {
              setState(() {
                selectedPeriod = period;
              });
              _loadStats(); // Reload stats when period changes
            },
          ),
          SizedBox(height: 24),
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
