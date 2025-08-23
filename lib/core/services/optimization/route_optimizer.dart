import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'navigation_preloader.dart';
import 'optimized_data_service.dart';

/// Route optimization service for fast page transitions and data loading
class RouteOptimizer {
  static final RouteOptimizer _instance = RouteOptimizer._internal();
  factory RouteOptimizer() => _instance;
  RouteOptimizer._internal();

  final NavigationPreloader _preloader = NavigationPreloader();
  final OptimizedDataService _dataService = OptimizedDataService();
  
  // Cache for page widgets to avoid rebuilding
  final Map<String, Widget> _pageCache = {};
  
  // Preloading states
  final Map<String, bool> _preloadingStates = {};
  final Map<String, DateTime> _lastPreloadTimes = {};

  /// Navigate to route with optimization
  Future<T?> navigateToOptimized<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
    bool replace = false,
    bool clearStack = false,
  }) async {
    // Record navigation for learning
    _preloader.recordNavigation(routeName);
    
    // Start preloading if not already done
    await _preloadForRoute(routeName, arguments);
    
    // Perform navigation using GoRouter
    if (clearStack) {
      // For clearing the stack, we'll use go which replaces the entire stack
      context.go(routeName);
      return null; // GoRouter go() doesn't return a value
    } else if (replace) {
      // Use pushReplacement equivalent in GoRouter
      context.pushReplacement(routeName);
      return null; // GoRouter pushReplacement() doesn't return a value
    } else {
      // Use regular push navigation
      return context.push(routeName);
    }
  }

  /// Preload data for a specific route
  Future<void> _preloadForRoute(String routeName, Object? arguments) async {
    final now = DateTime.now();
    final lastPreload = _lastPreloadTimes[routeName];
    
    // Skip if recently preloaded (within 30 seconds)
    if (lastPreload != null && 
        now.difference(lastPreload).inSeconds < 30) {
      return;
    }
    
    // Skip if already preloading
    if (_preloadingStates[routeName] == true) {
      return;
    }
    
    _preloadingStates[routeName] = true;
    _lastPreloadTimes[routeName] = now;
    
    try {
      await _executeRoutePreload(routeName, arguments);
    } finally {
      _preloadingStates[routeName] = false;
    }
  }

  /// Execute preload based on route
  Future<void> _executeRoutePreload(String routeName, Object? arguments) async {
    final screenName = _getScreenNameFromRoute(routeName);
    
    switch (screenName.toLowerCase()) {
      case 'dashboard':
        await _preloadDashboard();
        break;
        
      case 'appointment_screen':
      case 'appointments':
        await _preloadAppointments();
        break;
        
      case 'patient_record_screen':
      case 'patients':
        await _preloadPatients();
        break;
        
      case 'settings_screen':
      case 'settings':
        await _preloadSettings();
        break;
        
      case 'support_screen':
      case 'support':
        await _preloadSupport();
        break;
        
      case 'notifications_screen':
      case 'notifications':
        await _preloadNotifications();
        break;
        
      default:
        // Generic preload
        await _dataService.preloadForScreen(screenName);
    }
  }

  /// Preload dashboard data
  Future<void> _preloadDashboard() async {
    final tasks = [
      _dataService.getCurrentUser(),
      _dataService.getTodayAppointments(),
      _dataService.getPatients(limit: 10),
      _dataService.getSupportTickets(),
    ];
    
    await Future.wait(tasks.map((task) async {
      try {
        return await task;
      } catch (e) {
        return null;
      }
    }));
  }

  /// Preload appointments data
  Future<void> _preloadAppointments() async {
    final tasks = [
      _dataService.getAppointments(limit: 20),
      _dataService.getAppointments(status: 'pending'),
      _dataService.getAppointments(status: 'confirmed'),
      _dataService.getTodayAppointments(),
    ];
    
    await Future.wait(tasks.map((task) async {
      try {
        return await task;
      } catch (e) {
        return <dynamic>[];
      }
    }));
  }

  /// Preload patients data
  Future<void> _preloadPatients() async {
    final tasks = [
      _dataService.getPatients(limit: 50),
      _dataService.getPatients(page: 1, limit: 20), // First page for quick display
    ];
    
    await Future.wait(tasks.map((task) async {
      try {
        return await task;
      } catch (e) {
        return <dynamic>[];
      }
    }));
  }

  /// Preload settings data
  Future<void> _preloadSettings() async {
    final tasks = [
      _dataService.getCurrentUser(),
      // Add clinic settings, preferences, etc. when available
    ];
    
    await Future.wait(tasks.map((task) async {
      try {
        return await task;
      } catch (e) {
        return null;
      }
    }));
  }

  /// Preload support data
  Future<void> _preloadSupport() async {
    final tasks = [
      _dataService.getSupportTickets(),
      _dataService.getFAQItems(),
    ];
    
    await Future.wait(tasks.map((task) async {
      try {
        return await task;
      } catch (e) {
        return <dynamic>[];
      }
    }));
  }

  /// Preload notifications data
  Future<void> _preloadNotifications() async {
    // When notification service is implemented
    // await notificationService.getNotifications();
  }

  /// Create optimized page route with preloading
  PageRoute<T> createOptimizedRoute<T>(
    Widget page,
    String routeName, {
    RouteSettings? settings,
    bool maintainState = true,
    bool fullscreenDialog = false,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) {
        // Record navigation
        _preloader.recordNavigation(routeName);
        
        // Start background preloading for predicted next routes
        _startPredictivePreloading(routeName);
        
        return page;
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Optimized transition with fade for better performance
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 200), // Fast transition
      maintainState: maintainState,
      fullscreenDialog: fullscreenDialog,
    );
  }

  /// Start preloading for predicted next routes
  void _startPredictivePreloading(String currentRoute) {
    Future.microtask(() async {
      // Get predicted routes based on navigation patterns
      final predictedRoutes = _getPredictedRoutes(currentRoute);
      
      for (final route in predictedRoutes.take(2)) { // Limit to top 2 predictions
        try {
          await _preloadForRoute(route, null);
        } catch (e) {
          if (kDebugMode) {
            print('RouteOptimizer: Error preloading $route: $e');
          }
        }
      }
    });
  }

  /// Get predicted routes based on current route
  List<String> _getPredictedRoutes(String currentRoute) {
    final screenName = _getScreenNameFromRoute(currentRoute);
    
    switch (screenName.toLowerCase()) {
      case 'dashboard':
        return ['/admin/appointment', '/admin/patient-record', '/admin/notifications'];
      case 'appointment_screen':
        return ['/admin/dashboard', '/admin/patient-record'];
      case 'patient_record_screen':
        return ['/admin/appointment', '/admin/dashboard'];
      case 'settings_screen':
        return ['/admin/dashboard', '/admin/vet-profile'];
      default:
        return ['/admin/dashboard'];
    }
  }

  /// Extract screen name from route
  String _getScreenNameFromRoute(String routeName) {
    return routeName.split('/').last.replaceAll('-', '_');
  }

  /// Cache page widget for reuse
  void cachePage(String routeName, Widget page) {
    _pageCache[routeName] = page;
  }

  /// Get cached page widget
  Widget? getCachedPage(String routeName) {
    return _pageCache[routeName];
  }

  /// Clear page cache
  void clearPageCache() {
    _pageCache.clear();
  }

  /// Batch preload for multiple routes
  Future<void> batchPreload(List<String> routes) async {
    final preloadTasks = routes.map((route) => 
      _preloadForRoute(route, null).catchError((_) {}));
    
    await Future.wait(preloadTasks);
  }

  /// Initialize route optimizer
  Future<void> initialize() async {
    // Preload essential data
    await _preloader.preloadAppStartup();
    
    // Start predictive preloading
    _preloader.preloadCommonWorkflows();
    
    // Schedule time-based preloading
    _preloader.scheduleTimeBasedPreloading();
    
    if (kDebugMode) {
      print('RouteOptimizer: Initialized with preloading');
    }
  }

  /// Get optimization statistics
  Map<String, dynamic> getStats() {
    return {
      'cached_pages': _pageCache.length,
      'preloading_states': Map.from(_preloadingStates),
      'last_preload_times': _lastPreloadTimes.length,
      'navigation_stats': _preloader.getNavigationStats(),
    };
  }

  /// Create loading placeholder with shimmer effect
  Widget createLoadingPlaceholder({
    double height = 100,
    double width = double.infinity,
    Color baseColor = const Color(0xFFE0E0E0),
    Color highlightColor = const Color(0xFFF5F5F5),
  }) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [baseColor, highlightColor, baseColor],
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  /// Create optimized list view with lazy loading
  Widget createOptimizedListView<T>({
    required List<T> items,
    required Widget Function(BuildContext, T) itemBuilder,
    ScrollController? controller,
    EdgeInsets padding = EdgeInsets.zero,
    bool shrinkWrap = false,
  }) {
    return ListView.builder(
      controller: controller,
      padding: padding,
      shrinkWrap: shrinkWrap,
      itemCount: items.length,
      cacheExtent: 500, // Cache more items for smoother scrolling
      itemBuilder: (context, index) => itemBuilder(context, items[index]),
    );
  }
}
