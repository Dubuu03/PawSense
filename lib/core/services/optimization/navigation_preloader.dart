import 'package:flutter/foundation.dart';
import 'optimized_data_service.dart';
import 'cache_manager.dart';

/// Navigation preloader that anticipates user navigation patterns
/// and preloads data to minimize loading times
class NavigationPreloader {
  static final NavigationPreloader _instance = NavigationPreloader._internal();
  factory NavigationPreloader() => _instance;
  NavigationPreloader._internal();

  final OptimizedDataService _dataService = OptimizedDataService();
  final CacheManager _cache = CacheManager();
  
  // Track navigation patterns
  final List<String> _navigationHistory = [];
  final Map<String, int> _screenVisitCount = {};
  final Map<String, List<String>> _navigationPatterns = {};

  /// Record navigation to a screen
  void recordNavigation(String screenName) {
    final now = DateTime.now();
    final timeStamp = now.millisecondsSinceEpoch;
    
    _navigationHistory.add('$screenName:$timeStamp');
    _screenVisitCount[screenName] = (_screenVisitCount[screenName] ?? 0) + 1;
    
    // Keep only recent history (last 20 navigations)
    if (_navigationHistory.length > 20) {
      _navigationHistory.removeAt(0);
    }
    
    _updateNavigationPatterns(screenName);
    _preloadForScreen(screenName);
  }

  /// Preload data based on current screen and predicted next screens
  Future<void> _preloadForScreen(String currentScreen) async {
    // Immediate preload for current screen
    await _dataService.preloadForScreen(currentScreen);
    
    // Predictive preload for likely next screens
    final predictedScreens = _getPredictedNextScreens(currentScreen);
    for (final screen in predictedScreens.take(2)) { // Limit to top 2 predictions
      _preloadInBackground(screen);
    }
  }

  /// Preload data in background without blocking UI
  void _preloadInBackground(String screenName) {
    Future.microtask(() async {
      try {
        await _dataService.preloadForScreen(screenName);
        if (kDebugMode) {
          print('NavigationPreloader: Preloaded data for $screenName');
        }
      } catch (e) {
        if (kDebugMode) {
          print('NavigationPreloader: Error preloading $screenName: $e');
        }
      }
    });
  }

  /// Update navigation patterns based on history
  void _updateNavigationPatterns(String currentScreen) {
    if (_navigationHistory.length < 2) return;
    
    // Get previous screen
    final previousEntry = _navigationHistory[_navigationHistory.length - 2];
    final previousScreen = previousEntry.split(':')[0];
    
    // Update pattern
    if (!_navigationPatterns.containsKey(previousScreen)) {
      _navigationPatterns[previousScreen] = [];
    }
    
    _navigationPatterns[previousScreen]!.add(currentScreen);
    
    // Keep pattern history reasonable
    if (_navigationPatterns[previousScreen]!.length > 10) {
      _navigationPatterns[previousScreen]!.removeAt(0);
    }
  }

  /// Get predicted next screens based on patterns
  List<String> _getPredictedNextScreens(String currentScreen) {
    final patterns = _navigationPatterns[currentScreen];
    if (patterns == null || patterns.isEmpty) {
      return _getDefaultNextScreens(currentScreen);
    }
    
    // Count frequency of next screens
    final frequency = <String, int>{};
    for (final screen in patterns) {
      frequency[screen] = (frequency[screen] ?? 0) + 1;
    }
    
    // Sort by frequency
    final sortedScreens = frequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedScreens.map((e) => e.key).toList();
  }

  /// Get default next screens for common navigation patterns
  List<String> _getDefaultNextScreens(String currentScreen) {
    switch (currentScreen.toLowerCase()) {
      case 'dashboard':
        return ['appointments', 'patients', 'notifications'];
      case 'appointments':
        return ['dashboard', 'patients', 'appointment_detail'];
      case 'patients':
        return ['patient_detail', 'appointments', 'dashboard'];
      case 'patient_detail':
        return ['appointments', 'patients'];
      case 'settings':
        return ['dashboard', 'profile'];
      default:
        return ['dashboard'];
    }
  }

  /// Preload essential data when app starts
  Future<void> preloadAppStartup() async {
    final startupTasks = [
      _dataService.preloadEssentialData(),
      _cache.preload('current_user', () => _dataService.getCurrentUser()),
    ];
    
    await Future.wait(startupTasks);
    
    if (kDebugMode) {
      print('NavigationPreloader: App startup preload complete');
    }
  }

  /// Preload data for likely user workflows
  Future<void> preloadCommonWorkflows() async {
    final workflows = [
      _preloadDashboardWorkflow(),
      _preloadAppointmentWorkflow(),
      _preloadPatientWorkflow(),
    ];
    
    // Execute workflows in background
    for (final workflow in workflows) {
      _executeInBackground(workflow);
    }
  }

  /// Preload dashboard workflow data
  Future<void> _preloadDashboardWorkflow() async {
    await Future.wait([
      _dataService.getTodayAppointments(),
      _dataService.getPatients(limit: 10),
      _dataService.getSupportTickets(),
    ]);
  }

  /// Preload appointment workflow data
  Future<void> _preloadAppointmentWorkflow() async {
    await Future.wait([
      _dataService.getAppointments(limit: 20),
      _dataService.getAppointments(status: 'pending'),
      _dataService.getAppointments(status: 'confirmed'),
    ]);
  }

  /// Preload patient workflow data
  Future<void> _preloadPatientWorkflow() async {
    await _dataService.getPatients(limit: 50);
  }

  /// Execute task in background
  void _executeInBackground(Future<void> task) {
    Future.microtask(() async {
      try {
        await task;
      } catch (e) {
        if (kDebugMode) {
          print('NavigationPreloader: Background task error: $e');
        }
      }
    });
  }

  /// Get navigation statistics
  Map<String, dynamic> getNavigationStats() {
    return {
      'total_navigations': _navigationHistory.length,
      'screen_visit_counts': Map.from(_screenVisitCount),
      'navigation_patterns': Map.from(_navigationPatterns),
      'cache_stats': _cache.getStats().toString(),
    };
  }

  /// Clear navigation history and patterns
  void clearNavigationHistory() {
    _navigationHistory.clear();
    _screenVisitCount.clear();
    _navigationPatterns.clear();
  }

  /// Preload data for specific user action
  Future<void> preloadForAction(String action, [Map<String, dynamic>? context]) async {
    switch (action.toLowerCase()) {
      case 'view_appointment_details':
        if (context?['appointmentId'] != null) {
          await _dataService.getAppointmentById(context!['appointmentId']);
        }
        break;
        
      case 'view_patient_details':
        if (context?['patientId'] != null) {
          await _dataService.getPatientById(context!['patientId']);
        }
        break;
        
      case 'search_patients':
        if (context?['query'] != null) {
          await _dataService.searchPatients(context!['query']);
        }
        break;
    }
  }

  /// Smart preload based on time patterns
  void scheduleTimeBasedPreloading() {
    final now = DateTime.now();
    final hour = now.hour;
    
    // Morning preload (7-10 AM) - focus on today's schedule
    if (hour >= 7 && hour <= 10) {
      _executeInBackground(_preloadDashboardWorkflow());
    }
    
    // Afternoon preload (12-2 PM) - focus on appointments
    else if (hour >= 12 && hour <= 14) {
      _executeInBackground(_preloadAppointmentWorkflow());
    }
    
    // Evening preload (5-7 PM) - focus on next day preparation
    else if (hour >= 17 && hour <= 19) {
      _executeInBackground(_preloadTomorrowData());
    }
  }

  /// Preload tomorrow's data
  Future<void> _preloadTomorrowData() async {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    await _dataService.getAppointments(date: tomorrow);
  }
}
