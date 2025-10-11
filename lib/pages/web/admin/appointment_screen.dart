// screens/optimized_appointment_management_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/utils/app_colors.dart';
import '../../../core/utils/sort_order.dart';
import '../../../core/models/clinic/appointment_models.dart' as AppointmentModels;
import '../../../core/models/clinic/appointment_booking_model.dart';
import '../../../core/services/clinic/appointment_service.dart';
import '../../../core/services/clinic/paginated_appointment_service.dart';
import '../../../core/services/clinic/realtime_appointment_listener.dart';
import '../../../core/services/super_admin/screen_state_service.dart';
import '../../../core/widgets/admin/appointments/appointment_header.dart';
import '../../../core/widgets/admin/appointments/appointment_filters.dart';
import '../../../core/widgets/admin/appointments/appointment_summary.dart';
import '../../../core/widgets/admin/appointments/appointment_edit_modal.dart';
import '../../../core/widgets/admin/appointments/appointment_completion_modal.dart';
import '../../../core/widgets/admin/clinic_schedule/appointment_details_modal.dart';
import '../../../core/widgets/admin/appointments/appointment_table_row.dart';
import '../../../core/widgets/admin/appointments/appointment_table_header.dart';

class OptimizedAppointmentManagementScreen extends StatefulWidget {
  const OptimizedAppointmentManagementScreen({Key? key}) 
      : super(key: key ?? const PageStorageKey('appointment_management'));

  @override
  State<OptimizedAppointmentManagementScreen> createState() => 
      _OptimizedAppointmentManagementScreenState();
}

class _OptimizedAppointmentManagementScreenState 
    extends State<OptimizedAppointmentManagementScreen> 
    with AutomaticKeepAliveClientMixin {
  
  // Filter state
  String searchQuery = '';
  String selectedStatus = 'All Status';
  SortOrder bookedAtSortOrder = SortOrder.descending; // Default to newest first
  
  // Appointment data
  List<AppointmentModels.Appointment> appointments = [];
  List<AppointmentModels.Appointment> filteredAppointments = [];
  
  // Status counts (for summary badges - fetched separately from all appointments)
  AppointmentStatusCounts? statusCounts;
  bool isLoadingStatusCounts = true;
  
  // Loading state
  bool isInitialLoading = true;
  bool isLoadingMore = false;
  String? error;
  
  // Pagination
  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;
  
  // Clinic data
  String? _cachedClinicId;
  String? _cachedClinicName;
  
  // Services
  final _stateService = ScreenStateService();
  final _realtimeListener = RealTimeAppointmentListener();
  
  // Real-time updates state
  bool _isRefreshing = false; // Prevent concurrent refreshes
  
  // Scroll controller for infinite scroll
  final ScrollController _scrollController = ScrollController();
  
  // Debounce timer for search
  Timer? _searchDebounce;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _restoreState();
    _initializeData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _saveState();
    // Unregister from real-time listener
    _realtimeListener.unregisterStatusCountCallback(_updateStatusCountsRealTime);
    _realtimeListener.unregisterAppointmentListCallback(_refreshDataSilently);
    _scrollController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  /// Initialize clinic data and load first page
  Future<void> _initializeData() async {
    await _getClinicId();
    if (_cachedClinicId != null) {
      // Load appointments and status counts in parallel for better performance
      await Future.wait([
        _loadFirstPage(),
        _loadStatusCounts(),
      ]);
      
      // Setup centralized real-time listener after a delay to avoid build conflicts
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _setupRealtimeListener();
        }
      });
    }
  }

  /// Get and cache clinic ID
  Future<void> _getClinicId() async {
    if (_cachedClinicId != null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        error = 'User not authenticated';
        isInitialLoading = false;
      });
      return;
    }

    try {
      final clinicQuery = await FirebaseFirestore.instance
          .collection('clinics')
          .where('userId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'approved')
          .limit(1)
          .get();

      if (clinicQuery.docs.isNotEmpty) {
        final clinicDoc = clinicQuery.docs.first;
        _cachedClinicId = clinicDoc.id;
        _cachedClinicName = clinicDoc.data()['clinicName'] as String?;
        print('✅ Clinic ID cached: $_cachedClinicId ($_cachedClinicName)');
      } else {
        setState(() {
          error = 'No approved clinic found';
          isInitialLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error getting clinic ID: $e');
      setState(() {
        error = 'Failed to get clinic information';
        isInitialLoading = false;
      });
    }
  }

  /// Load first page of appointments
  Future<void> _loadFirstPage() async {
    setState(() {
      isInitialLoading = true;
      error = null;
      appointments.clear();
      filteredAppointments.clear();
      _lastDocument = null;
      _hasMore = true;
    });

    await _loadMoreAppointments();
  }

  /// Load status counts for summary badges (fetches total counts, not just paginated)
  Future<void> _loadStatusCounts() async {
    if (_cachedClinicId == null) return;

    setState(() {
      isLoadingStatusCounts = true;
    });

    try {
      print('📊 Loading appointment status counts...');
      
      final counts = await PaginatedAppointmentService.getAppointmentStatusCounts(
        clinicId: _cachedClinicId!,
      );

      setState(() {
        statusCounts = counts;
        isLoadingStatusCounts = false;
        
        print('✅ Loaded status counts: ${counts.toString()}');
      });
    } catch (e) {
      print('❌ Error loading status counts: $e');
      setState(() {
        isLoadingStatusCounts = false;
        // Set default counts on error
        statusCounts = AppointmentStatusCounts(
          pendingCount: 0,
          confirmedCount: 0,
          completedCount: 0,
          cancelledCount: 0,
        );
      });
    }
  }

  /// Update status counts in real-time (optimized for background updates)
  Future<void> _updateStatusCountsRealTime() async {
    if (_cachedClinicId == null || !mounted) return;

    try {
      print('🔄 Updating status counts in real-time...');
      
      final counts = await PaginatedAppointmentService.getAppointmentStatusCounts(
        clinicId: _cachedClinicId!,
      );

      if (mounted) {
        setState(() {
          statusCounts = counts;
          print('✅ Real-time status counts updated: ${counts.toString()}');
        });
      }
    } catch (e) {
      print('❌ Error updating status counts in real-time: $e');
      // Don't show error to user for background updates
    }
  }

  /// Load more appointments (pagination)
  Future<void> _loadMoreAppointments() async {
    if (!_hasMore || _cachedClinicId == null) return;
    
    // Prevent multiple simultaneous loads
    if (isLoadingMore) return;

    setState(() {
      if (appointments.isEmpty) {
        isInitialLoading = true;
      } else {
        isLoadingMore = true;
      }
    });

    try {
      print('📥 Loading ${appointments.isEmpty ? 'first' : 'next'} page of appointments with filter: $selectedStatus...');
      
      final result = await PaginatedAppointmentService.getClinicAppointmentsPaginated(
        clinicId: _cachedClinicId!,
        lastDocument: _lastDocument,
        status: _getStatusFilterForService(), // Apply server-side status filtering
      );

      setState(() {
        appointments.addAll(result.appointments);
        _lastDocument = result.lastDocument;
        _hasMore = result.hasMore;
        isInitialLoading = false;
        isLoadingMore = false;
        
        print('✅ Loaded ${result.appointments.length} appointments. Total: ${appointments.length}, Has more: $_hasMore');
        
        // Apply filters
        _applyFilters();
      });
    } catch (e) {
      print('❌ Error loading appointments: $e');
      setState(() {
        error = 'Failed to load appointments';
        isInitialLoading = false;
        isLoadingMore = false;
      });
    }
  }

  /// Load appointments until we reach a target count (for maintaining scroll position)
  Future<PaginatedAppointmentResult> _loadAppointmentsUntilCount({
    required int targetCount,
  }) async {
    List<AppointmentModels.Appointment> allAppointments = [];
    DocumentSnapshot? lastDoc;
    bool hasMore = true;
    
    while (allAppointments.length < targetCount && hasMore) {
      final result = await PaginatedAppointmentService.getClinicAppointmentsPaginated(
        clinicId: _cachedClinicId!,
        lastDocument: lastDoc,
        status: _getStatusFilterForService(), // Apply same filter as regular loading
      );
      
      allAppointments.addAll(result.appointments);
      lastDoc = result.lastDocument;
      hasMore = result.hasMore;
      
      // Safety break to avoid infinite loops
      if (result.appointments.isEmpty) break;
    }
    
    return PaginatedAppointmentResult(
      appointments: allAppointments,
      lastDocument: lastDoc,
      hasMore: hasMore,
    );
  }

  /// Show a subtle notification when new appointments are detected
  void _showNewAppointmentsSnackbar(int count) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.refresh, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text(
              '$count new appointment${count > 1 ? 's' : ''} ${selectedStatus != 'All Status' ? 'in ${selectedStatus.toLowerCase()}' : 'added'}',
            ),
          ],
        ),
        backgroundColor: AppColors.info,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        action: SnackBarAction(
          label: 'Scroll to Top',
          textColor: Colors.white,
          onPressed: () {
            _scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
            );
          },
        ),
      ),
    );
  }

  /// Show notification that new appointments are available but not loaded
  void _showRefreshAvailableSnackbar() {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.new_releases, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text(
              'New appointments available ${selectedStatus != 'All Status' ? 'in ${selectedStatus.toLowerCase()}' : ''}',
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        action: SnackBarAction(
          label: 'Refresh',
          textColor: Colors.white,
          onPressed: () {
            _refreshData(); // Full refresh
          },
        ),
      ),
    );
  }

  /// Get expected count based on current filter and status counts
  int _getExpectedFilteredCount() {
    if (statusCounts == null) return 0;
    
    switch (selectedStatus) {
      case 'Pending':
        return statusCounts!.pendingCount;
      case 'Confirmed':
        return statusCounts!.confirmedCount;
      case 'Completed':
        return statusCounts!.completedCount;
      case 'Cancelled':
        return statusCounts!.cancelledCount;
      case 'All Status':
      default:
        return statusCounts!.totalCount;
    }
  }

  /// Apply filters and sorting to appointments
  void _applyFilters() {
    filteredAppointments = appointments.where((appointment) {
      // Status filter
      bool statusMatch = selectedStatus == 'All Status' ||
          appointment.status.name.toLowerCase() == selectedStatus.toLowerCase();

      // Search filter
      bool searchMatch = searchQuery.isEmpty ||
          appointment.pet.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          appointment.owner.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          appointment.diseaseReason.toLowerCase().contains(searchQuery.toLowerCase());

      return statusMatch && searchMatch;
    }).toList();
    
    // Apply sorting by date
    _sortAppointments();
    
    print('🔍 Filtered: ${filteredAppointments.length} of ${appointments.length} appointments');
  }

  /// Sort appointments by booked at date based on current sort order
  void _sortAppointments() {
    filteredAppointments.sort((a, b) {
      try {
        final dateA = a.createdAt;
        final dateB = b.createdAt;
        
        if (bookedAtSortOrder == SortOrder.ascending) {
          return dateA.compareTo(dateB); // Oldest first
        } else {
          return dateB.compareTo(dateA); // Newest first
        }
      } catch (e) {
        print('Error comparing booked at dates for sorting: $e');
        // Fallback to timestamp comparison
        if (bookedAtSortOrder == SortOrder.ascending) {
          return a.createdAt.compareTo(b.createdAt);
        } else {
          return b.createdAt.compareTo(a.createdAt);
        }
      }
    });
  }

  /// Toggle booked at sort order
  void _onBookedAtSortChanged() {
    setState(() {
      bookedAtSortOrder = bookedAtSortOrder == SortOrder.ascending 
          ? SortOrder.descending 
          : SortOrder.ascending;
    });
    _saveState();
    _applyFilters();
    print('📅 Booked At sort changed to: ${bookedAtSortOrder.displayName}');
  }

  /// Setup real-time listener for appointment changes using centralized service
  void _setupRealtimeListener() {
    if (_cachedClinicId == null || !mounted) return;

    print('🔔 Setting up centralized real-time listener for clinic: $_cachedClinicId');

    // Setup the shared listener for this clinic
    _realtimeListener.setupListener(_cachedClinicId!);
    
    // Register callbacks for different update types
    _realtimeListener.registerStatusCountCallback(_updateStatusCountsRealTime);
    _realtimeListener.registerAppointmentListCallback(_refreshDataSilently);
    
    print('✅ Real-time listener callbacks registered');
  }

  /// Refresh data silently (for real-time updates)
  Future<void> _refreshDataSilently() async {
    if (!mounted || _cachedClinicId == null || _isRefreshing) return;
    
    _isRefreshing = true;
    
    try {
      // Add a tiny delay to ensure we're completely out of any build cycle
      await Future.delayed(const Duration(milliseconds: 50));
      
      if (!mounted) {
        _isRefreshing = false;
        return;
      }
      
      print('🔄 Silently refreshing appointments and status counts in background...');
      
      // Store current number of appointments to know how many pages we had loaded
      final currentAppointmentCount = appointments.length;
      final currentFilteredCount = filteredAppointments.length;
      
      // Load fresh status counts and appointments in parallel for better performance
      final Future<AppointmentStatusCounts> statusCountsFuture = PaginatedAppointmentService.getAppointmentStatusCounts(
        clinicId: _cachedClinicId!,
      );
      
      // For better performance, just load the first page and detect if there are changes
      // If user has scrolled down significantly, we'll show a notification instead of reloading everything
      final shouldLoadAll = currentAppointmentCount <= 20; // Only reload all if few appointments loaded
      
      // Load appointments and status counts in parallel
      late Future<PaginatedAppointmentResult> appointmentsFuture;
      
      if (shouldLoadAll) {
        // Load enough appointments to cover what was previously loaded + buffer
        appointmentsFuture = _loadAppointmentsUntilCount(
          targetCount: currentAppointmentCount + 10,
        );
      } else {
        // Just load first page and show notification if changes detected
        appointmentsFuture = PaginatedAppointmentService.getClinicAppointmentsPaginated(
          clinicId: _cachedClinicId!,
          lastDocument: null,
          status: _getStatusFilterForService(), // Apply same filter
        );
      }

      // Wait for both operations to complete
      final results = await Future.wait([
        appointmentsFuture,
        statusCountsFuture,
      ]);

      final appointmentsToLoad = results[0] as PaginatedAppointmentResult;
      final statusCountsResult = results[1] as AppointmentStatusCounts;

      if (mounted) {
        setState(() {
          appointments.clear();
          appointments.addAll(appointmentsToLoad.appointments);
          _lastDocument = appointmentsToLoad.lastDocument;
          _hasMore = appointmentsToLoad.hasMore;
          
          // Update status counts - This triggers real-time badge updates!
          statusCounts = statusCountsResult;
          
          // Apply filters
          _applyFilters();
          
          // Handle notifications based on whether we did a full reload or partial
          final newFilteredCount = filteredAppointments.length;
          
          if (shouldLoadAll) {
            // Full reload - show notification if new appointments were added
            if (newFilteredCount > currentFilteredCount) {
              final newAppointments = newFilteredCount - currentFilteredCount;
              _showNewAppointmentsSnackbar(newAppointments);
            }
          } else {
            // Partial reload - check if there are likely new appointments not loaded
            if (statusCounts != null) {
              final expectedCount = _getExpectedFilteredCount();
              // Only show notification if there's a significant difference (more than 2 appointments)
              if (expectedCount > currentFilteredCount + 2) {
                _showRefreshAvailableSnackbar();
              }
            }
          }
          
          print('✅ Silent refresh complete: ${appointments.length} appointments, status counts: ${statusCountsResult.toString()}');
        });
      }
    } catch (e) {
      print('❌ Error during silent refresh: $e');
      // Don't show error to user for background refresh
    } finally {
      _isRefreshing = false;
    }
  }

  /// Refresh all data (reload from first page) - for pull-to-refresh
  Future<void> _refreshData() async {
    // Refresh both appointments and status counts
    await Future.wait([
      _loadFirstPage(),
      _loadStatusCounts(),
    ]);
  }

  /// Smart refresh that preserves infinite scroll state after status changes
  Future<void> _refreshAfterStatusChange() async {
    if (_cachedClinicId == null || !mounted) return;

    try {
      print('🔄 Smart refresh after status change - preserving scroll state...');
      
      // Store current scroll state
      final currentAppointmentCount = appointments.length;
      final currentScrollPosition = _scrollController.hasClients 
          ? _scrollController.position.pixels 
          : 0.0;
      
      // Refresh status counts immediately for instant badge updates
      final statusCountsFuture = _loadStatusCounts();
      
      // Reload appointments to match current loaded count (preserve infinite scroll)
      final appointmentsFuture = _loadAppointmentsUntilCount(
        targetCount: currentAppointmentCount,
      );

      // Wait for both operations
      final results = await Future.wait([
        appointmentsFuture,
        statusCountsFuture,
      ]);

      final appointmentsResult = results[0] as PaginatedAppointmentResult;

      if (mounted) {
        setState(() {
          // Update appointments while preserving count
          appointments.clear();
          appointments.addAll(appointmentsResult.appointments);
          _lastDocument = appointmentsResult.lastDocument;
          _hasMore = appointmentsResult.hasMore;
          
          // Apply filters to update the displayed list
          _applyFilters();
          
          print('✅ Smart refresh complete: preserved ${appointments.length} appointments');
        });

        // Restore scroll position after a brief delay
        if (_scrollController.hasClients && currentScrollPosition > 0) {
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted && _scrollController.hasClients) {
              _scrollController.animateTo(
                currentScrollPosition,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
              );
            }
          });
        }
      }
    } catch (e) {
      print('❌ Error during smart refresh: $e');
      // Fallback to regular refresh if smart refresh fails
      await _refreshData();
    }
  }

  /// Handle scroll events for infinite scrolling
  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      // User is near bottom, load more
      if (_hasMore && !isLoadingMore && !isInitialLoading) {
        _loadMoreAppointments();
      }
    }
  }

  /// Restore state from ScreenStateService
  void _restoreState() {
    searchQuery = _stateService.appointmentSearchQuery;
    selectedStatus = _stateService.appointmentSelectedStatus;
    bookedAtSortOrder = SortOrder.fromString(_stateService.appointmentDateSortOrder);
  }

  /// Save current state to ScreenStateService
  void _saveState() {
    _stateService.saveAppointmentState(
      searchQuery: searchQuery,
      selectedStatus: selectedStatus,
      dateSortOrder: bookedAtSortOrder.value,
    );
  }

  /// Handle search with debouncing
  void _onSearchChanged(String query) {
    setState(() {
      searchQuery = query;
    });
    _saveState();

    // Cancel previous timer
    _searchDebounce?.cancel();

    // Debounce search to avoid excessive filtering
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      _applyFilters();
      setState(() {});
    });
  }

  /// Handle status filter change
  void _onStatusChanged(String status) {
    setState(() {
      selectedStatus = status;
    });
    _saveState();
    
    // Reload data with new filter instead of just applying client-side filter
    _loadDataWithNewFilter();
  }

  /// Load fresh data when filter changes to ensure all matching appointments are shown
  Future<void> _loadDataWithNewFilter() async {
    setState(() {
      isInitialLoading = true;
      appointments.clear();
      filteredAppointments.clear();
      _lastDocument = null;
      _hasMore = true;
    });

    // Load appointments with the new status filter
    await _loadMoreAppointments();
  }

  /// Convert filter status string to AppointmentStatus enum for server-side filtering
  AppointmentStatus? _getStatusFilterForService() {
    if (selectedStatus == 'All Status') return null;
    
    switch (selectedStatus.toLowerCase()) {
      case 'pending':
        return AppointmentStatus.pending;
      case 'confirmed':
        return AppointmentStatus.confirmed;
      case 'completed':
        return AppointmentStatus.completed;
      case 'cancelled':
        return AppointmentStatus.cancelled;
      default:
        return null;
    }
  }

  /// Refresh appointments (pull to refresh)
  Future<void> _onRefresh() async {
    await _refreshData();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppointmentHeader(),
                  const SizedBox(height: 24),
                ],
              ),
            ),

            // Loading state (initial)
            if (isInitialLoading)
              const SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: AppColors.primary),
                      SizedBox(height: 16),
                      Text(
                        'Loading appointments...',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              )
            
            // Error state
            else if (error != null)
              SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            size: 48, color: AppColors.error),
                        const SizedBox(height: 16),
                        Text(error!,
                            style: TextStyle(color: AppColors.error)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => _refreshData(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            
            // Content
            else ...[
              // Summary
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    AppointmentSummary(
                      statusCounts: statusCounts ?? AppointmentStatusCounts(
                        pendingCount: 0,
                        confirmedCount: 0,
                        completedCount: 0,
                        cancelledCount: 0,
                      ),
                      isLoading: isLoadingStatusCounts,
                    ),
                    const SizedBox(height: 24),
                    
                    // Filters
                    AppointmentFilters(
                      searchQuery: searchQuery,
                      selectedStatus: selectedStatus,
                      onSearchChanged: _onSearchChanged,
                      onStatusChanged: _onStatusChanged,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),

              // Appointment list
              if (filteredAppointments.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_today,
                              size: 48, color: AppColors.textSecondary),
                          const SizedBox(height: 16),
                          const Text(
                            'No appointments found',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Try adjusting your filters',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        AppointmentTableHeader(
                          bookedAtSortOrder: bookedAtSortOrder,
                          onBookedAtSortChanged: _onBookedAtSortChanged,
                        ),
                        
                        // Lazy-loaded appointment rows
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredAppointments.length,
                          itemBuilder: (context, index) {
                            final appointment = filteredAppointments[index];
                            return AppointmentTableRow(
                              appointment: appointment,
                              onView: () => _onView(appointment),
                              onAccept: appointment.status == AppointmentModels.AppointmentStatus.pending
                                  ? () => _onAccept(appointment)
                                  : null,
                              onMarkDone: appointment.status == AppointmentModels.AppointmentStatus.confirmed
                                  ? () => _onMarkDone(appointment)
                                  : null,
                              onReject: appointment.status == AppointmentModels.AppointmentStatus.pending
                                  ? () => _onReject(appointment)
                                  : null,
                              onEdit: () => _onEdit(appointment),
                              onDelete: () => _onDelete(appointment),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

              // Loading more indicator
              if (isLoadingMore)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),

              // End of list indicator
              if (!_hasMore && filteredAppointments.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: Text(
                        'No more appointments',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
            ],

            // Bottom spacing
            const SliverToBoxAdapter(
              child: SizedBox(height: 24),
            ),
          ],
        ),
      ),
    );
  }

  // Action handlers
  void _onView(AppointmentModels.Appointment appointment) {
    AppointmentDetailsModal.show(
      context,
      appointment,
      showAcceptButton: false,
    );
  }

  void _onAccept(AppointmentModels.Appointment appointment) {
    AppointmentDetailsModal.show(
      context,
      appointment,
      showAcceptButton: true,
      onAcceptAppointment: () async {
        final result = await AppointmentService.acceptAppointment(appointment.id);

        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Accepted appointment for ${appointment.pet.name}'),
              backgroundColor: AppColors.success,
            ),
          );
          
          // Smart refresh to preserve infinite scroll state
          try {
            await _refreshAfterStatusChange();
          } catch (e) {
            print('⚠️ Error refreshing data after accepting appointment: $e');
            // Don't show error to user as the appointment was successfully accepted
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      },
    );
  }

  void _onMarkDone(AppointmentModels.Appointment appointment) {
    showDialog(
      context: context,
      builder: (context) => AppointmentCompletionModal(
        appointment: appointment,
        onCompleted: _refreshAfterStatusChange,
      ),
    );
  }

  Future<void> _onReject(AppointmentModels.Appointment appointment) async {
    final TextEditingController reasonController = TextEditingController();

    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Appointment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rejecting appointment for ${appointment.pet.name}'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for rejection',
                hintText: 'Please provide a reason',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isNotEmpty) {
                Navigator.of(context).pop(reasonController.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (reason != null && reason.isNotEmpty) {
      final success = await AppointmentService.rejectAppointment(
        appointment.id,
        reason,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Rejected appointment for ${appointment.pet.name}'
                  : 'Failed to reject appointment',
            ),
            backgroundColor: success ? AppColors.warning : AppColors.error,
          ),
        );
        
        // Smart refresh to preserve infinite scroll state
        if (success) {
          try {
            await _refreshAfterStatusChange();
          } catch (e) {
            print('⚠️ Error refreshing data after rejecting appointment: $e');
            // Don't show error to user as the appointment was successfully rejected
          }
        }
      }
    }
  }

  void _onEdit(AppointmentModels.Appointment appointment) {
    showDialog(
      context: context,
      builder: (context) => AppointmentEditModal(
        appointment: appointment,
        onUpdate: _refreshAfterStatusChange,
      ),
    );
  }

  Future<void> _onDelete(AppointmentModels.Appointment appointment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Appointment'),
        content: Text(
          'Are you sure you want to delete the appointment for ${appointment.pet.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await AppointmentService.updateAppointmentStatus(
        appointment.id,
        AppointmentModels.AppointmentStatus.cancelled,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Cancelled appointment for ${appointment.pet.name}'
                  : 'Failed to cancel appointment',
            ),
            backgroundColor: success ? AppColors.warning : AppColors.error,
          ),
        );
        
        // Smart refresh to preserve infinite scroll state
        if (success) {
          try {
            await _refreshAfterStatusChange();
          } catch (e) {
            print('⚠️ Error refreshing data after cancelling appointment: $e');
            // Don't show error to user as the appointment was successfully cancelled
          }
        }
      }
    }
  }
}
