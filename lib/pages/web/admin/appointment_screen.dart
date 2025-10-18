// screens/optimized_appointment_management_screen.dart
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pawsense/core/utils/file_downloader.dart' as file_downloader;
import '../../../core/utils/app_colors.dart';
import '../../../core/utils/sort_order.dart';
import '../../../core/models/clinic/appointment_models.dart' as AppointmentModels;
import '../../../core/models/clinic/appointment_booking_model.dart';
import '../../../core/services/clinic/appointment_service.dart';
import '../../../core/services/clinic/paginated_appointment_service.dart';
import '../../../core/services/clinic/realtime_appointment_listener.dart';
import '../../../core/services/clinic/appointment_cache_service.dart';
import '../../../core/services/clinic/appointment_pdf_service.dart';
import '../../../core/services/clinic/clinic_details_service.dart';
import '../../../core/services/super_admin/screen_state_service.dart';
import '../../../core/widgets/admin/appointments/appointment_header.dart';
import '../../../core/widgets/admin/appointments/appointment_filters.dart';
import '../../../core/widgets/admin/appointments/appointment_summary.dart';
import '../../../core/widgets/admin/appointments/appointment_edit_modal.dart';
import '../../../core/widgets/admin/appointments/appointment_completion_modal.dart';
import '../../../core/widgets/admin/clinic_schedule/appointment_details_modal.dart';
import '../../../core/widgets/admin/appointments/appointment_table_row.dart';
import '../../../core/widgets/admin/appointments/appointment_table_header.dart';
import '../../../core/widgets/shared/pagination_widget.dart';
import 'package:http/http.dart' as http;

// Global key for accessing appointment screen methods from anywhere
final GlobalKey<_OptimizedAppointmentManagementScreenState> appointmentScreenKey = 
    GlobalKey<_OptimizedAppointmentManagementScreenState>();

class OptimizedAppointmentManagementScreen extends StatefulWidget {
  final String? highlightAppointmentId; // Appointment ID to auto-open
  
  OptimizedAppointmentManagementScreen({
    Key? key,
    this.highlightAppointmentId,
  }) : super(key: key ?? appointmentScreenKey) {
    // Debug log in constructor
    if (highlightAppointmentId != null) {
      print('🎯 CONSTRUCTOR DEBUG: OptimizedAppointmentManagementScreen created with highlightAppointmentId: $highlightAppointmentId');
    }
  }

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
  DateTime? startDate;
  DateTime? endDate;
  String? selectedPetType;
  String? selectedBreed;
  SortOrder bookedAtSortOrder = SortOrder.descending; // Default to newest first
  
  // Appointment data
  List<AppointmentModels.Appointment> appointments = [];
  List<AppointmentModels.Appointment> filteredAppointments = [];
  
  // Status counts (for summary badges - fetched separately from all appointments)
  AppointmentStatusCounts? statusCounts;
  bool isLoadingStatusCounts = true;
  
  // Loading state
  bool isInitialLoading = true;
  bool _isLoading = false; // General loading state (replaces isInitialLoading after first load)
  bool _isPaginationLoading = false; // Separate loading state for pagination
  String? error;
  
  // Pagination
  int currentPage = 1;
  int totalPages = 1;
  int totalAppointments = 0;
  
  // Page cursors for navigation
  Map<int, DocumentSnapshot?> _pageCursors = {}; // Store last document for each page
  
  // Clinic data
  String? _cachedClinicId;
  String? _cachedClinicName;
  
  // Services
  final _stateService = ScreenStateService();
  final _realtimeListener = RealTimeAppointmentListener();
  final _cacheService = AppointmentCacheService();
  
  // Real-time updates state
  bool _isRefreshing = false; // Prevent concurrent refreshes
  
  // Debounce timer for search
  Timer? _searchDebounce;

  // ValueNotifier for table updates only (prevents full screen rebuild)
  final ValueNotifier<bool> _tableUpdateNotifier = ValueNotifier<bool>(false);

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _restoreState();
    _initializeData();
  }

  @override
  void dispose() {
    _saveState();
    // Unregister from real-time listener
    _realtimeListener.unregisterStatusCountCallback(_updateStatusCountsRealTime);
    _realtimeListener.unregisterAppointmentListCallback(_refreshDataSilently);
    _searchDebounce?.cancel();
    _tableUpdateNotifier.dispose();
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
      
      // Auto-open appointment details modal if appointmentId is provided
      if (widget.highlightAppointmentId != null) {
        print('🎯 DEBUG: highlightAppointmentId detected: ${widget.highlightAppointmentId}');
        // Schedule the modal opening (no await to avoid blocking)
        _openAppointmentDetailsById(widget.highlightAppointmentId!);
      }
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

  /// Load appointments starting from current page (restored from state)
  Future<void> _loadFirstPage() async {
    setState(() {
      _isLoading = true;
      error = null;
      appointments.clear();
      filteredAppointments.clear();
      _pageCursors.clear(); // Clear cursors on fresh load
      currentPage = 1; // Always start from page 1 on fresh load
    });

    await _loadPage(1);
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
          followUpCount: 0,
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

  /// Load specific page of appointments
  Future<void> _loadPage(int page, {bool isPagination = false, bool forceRefresh = false, bool isSilentRefresh = false}) async {
    if (_cachedClinicId == null) return;

    // Check if filters changed (clear cache if so)
    final filtersChanged = _cacheService.hasFiltersChanged(
      selectedStatus,
      searchQuery,
      startDate?.toIso8601String(),
      endDate?.toIso8601String(),
      null, // No separate follow-up filter, it's now part of selectedStatus
    );
    if (filtersChanged && !isInitialLoading) {
      _cacheService.invalidateCacheForFilterChange();
      _pageCursors.clear(); // Clear page cursors when filters change
    }

    // Try to load from multi-page cache first
    if (!forceRefresh && !isInitialLoading && !isSilentRefresh) {
      final cachedPage = _cacheService.getCachedPage(
        statusFilter: selectedStatus,
        searchQuery: searchQuery,
        startDate: startDate?.toIso8601String(),
        endDate: endDate?.toIso8601String(),
        followUpFilter: null, // No separate follow-up filter
        page: page,
      );

      if (cachedPage != null) {
        print('[CACHE] Using cached page data - no network call needed');
        setState(() {
          appointments.clear();
          appointments.addAll(cachedPage.appointments);
          totalAppointments = cachedPage.totalAppointments;
          totalPages = cachedPage.totalPages;
          currentPage = page;
          _isPaginationLoading = false;
          _isLoading = false;
          
          // Apply filters and sorting to the loaded appointments
          _applyFilters();
        });
        return;
      }
    }

    // Don't show loading state for silent background refreshes
    if (!isSilentRefresh) {
      setState(() {
        if (isInitialLoading) {
          // Keep isInitialLoading true for first load
          _isLoading = true;
        } else if (isPagination) {
          _isPaginationLoading = true;
        } else {
          _isLoading = true;
        }
      });
    }

    try {
      print('📥 Loading page $page of appointments with filter: $selectedStatus...');
      
      // Get the cursor for the previous page to support pagination
      DocumentSnapshot? lastDoc;
      if (page > 1) {
        lastDoc = _pageCursors[page - 1];
      }
      
      final result = await PaginatedAppointmentService.getClinicAppointmentsPaginated(
        clinicId: _cachedClinicId!,
        page: page,
        itemsPerPage: 10, // Show 10 appointments per page
        lastDocument: lastDoc, // Use cursor for pagination
        status: _getStatusFilterForService(), // Apply server-side status filtering
        startDate: startDate, // Apply date range filter
        endDate: endDate, // Apply date range filter
      );

      // Update cache with current page data
      _cacheService.updateCache(
        appointments: result.appointments,
        totalAppointments: result.totalCount ?? result.appointments.length,
        totalPages: result.totalPages ?? 1,
        statusFilter: selectedStatus,
        searchQuery: searchQuery,
        startDate: startDate?.toIso8601String(),
        endDate: endDate?.toIso8601String(),
        followUpFilter: null, // No separate follow-up filter
        page: page,
      );

      if (isSilentRefresh) {
        // For silent refresh, just update data without changing loading states
        appointments.clear();
        appointments.addAll(result.appointments);
        currentPage = result.currentPage ?? page;
        
        // Store the last document for this page (for next page navigation)
        if (result.lastDocument != null && result.appointments.isNotEmpty) {
          _pageCursors[page] = result.lastDocument;
        }
        
        // Use actual counts from service
        totalPages = result.totalPages ?? 1;
        totalAppointments = result.totalCount ?? result.appointments.length;
        
        print('✅ Silently loaded page $page: ${result.appointments.length} appointments. Total: $totalAppointments, Pages: $totalPages');
        print('📋 Appointment IDs on this page: ${result.appointments.map((a) => a.id).take(3).join(", ")}${result.appointments.length > 3 ? "..." : ""}');
        
        // Apply filters and sorting to the loaded appointments (this will trigger table update)
        _applyFilters();
      } else {
        setState(() {
          appointments.clear();
          appointments.addAll(result.appointments);
          currentPage = result.currentPage ?? page;
          
          // Store the last document for this page (for next page navigation)
          if (result.lastDocument != null && result.appointments.isNotEmpty) {
            _pageCursors[page] = result.lastDocument;
          }
          
          // Use actual counts from service
          totalPages = result.totalPages ?? 1;
          totalAppointments = result.totalCount ?? result.appointments.length;
          
          isInitialLoading = false;
          _isLoading = false;
          _isPaginationLoading = false;
          
          print('✅ Loaded page $page: ${result.appointments.length} appointments. Total: $totalAppointments, Pages: $totalPages');
          print('📋 Appointment IDs on this page: ${result.appointments.map((a) => a.id).take(3).join(", ")}${result.appointments.length > 3 ? "..." : ""}');
          
          // Apply filters and sorting to the loaded appointments
          _applyFilters();
        });
      }
    } catch (e) {
      print('❌ Error loading appointments page $page: $e');
      // Don't show error UI for silent refresh failures
      if (!isSilentRefresh) {
        setState(() {
          error = 'Failed to load appointments';
          isInitialLoading = false;
          _isLoading = false;
          _isPaginationLoading = false;
        });
      }
    }
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
          label: 'Go to Page 1',
          textColor: Colors.white,
          onPressed: () {
            _onPageChanged(1);
          },
        ),
      ),
    );
  }





  /// Apply filters and sorting to appointments
  void _applyFilters() {
    // First, filter all appointments
    List<AppointmentModels.Appointment> allFiltered = appointments.where((appointment) {
      // Status filter - handle both appointment status and follow-up status
      bool statusMatch = selectedStatus == 'All Status' ||
          appointment.status.name.toLowerCase() == selectedStatus.toLowerCase() ||
          (selectedStatus == 'Follow-up' && appointment.isFollowUp == true);

      // Search filter
      bool searchMatch = searchQuery.isEmpty ||
          appointment.pet.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          appointment.owner.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          appointment.diseaseReason.toLowerCase().contains(searchQuery.toLowerCase());

      // Pet type filter
      bool petTypeMatch = selectedPetType == null ||
          appointment.pet.type.toLowerCase() == selectedPetType!.toLowerCase();

      // Breed filter
      bool breedMatch = selectedBreed == null ||
          (appointment.pet.breed != null &&
              appointment.pet.breed!.toLowerCase() == selectedBreed!.toLowerCase());

      return statusMatch && searchMatch && petTypeMatch && breedMatch;
    }).toList();
    
    // Apply sorting by date to all filtered results
    allFiltered.sort((a, b) {
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
        return 0;
      }
    });
    
    // For search mode, Follow-up filter, or pet type/breed filters, show only the current page of filtered results
    if (searchQuery.isNotEmpty || selectedStatus == 'Follow-up' || selectedPetType != null || selectedBreed != null) {
      final itemsPerPage = 10;
      final startIndex = (currentPage - 1) * itemsPerPage;
      final endIndex = (startIndex + itemsPerPage).clamp(0, allFiltered.length);
      
      filteredAppointments = allFiltered.sublist(startIndex, endIndex);
      
      // Update pagination for filtered results
      totalAppointments = allFiltered.length;
      totalPages = (totalAppointments / itemsPerPage).ceil();
      if (totalPages == 0) totalPages = 1;
      
      print('🔍 Filtered results: ${allFiltered.length} total matches, showing page $currentPage (${filteredAppointments.length} appointments)');
      print('📄 Pagination: Page $currentPage of $totalPages');
    } else {
      // For no search or client-side filtering, show all results from current page load
      filteredAppointments = allFiltered;
      print('🔍 Filtered: ${filteredAppointments.length} of ${appointments.length} appointments');
    }
    
    // Notify table to update without rebuilding entire screen
    _tableUpdateNotifier.value = !_tableUpdateNotifier.value;
  }



  /// Toggle booked at sort order
  void _onBookedAtSortChanged() {
    // Update state without rebuilding entire screen
    bookedAtSortOrder = bookedAtSortOrder == SortOrder.ascending 
        ? SortOrder.descending 
        : SortOrder.ascending;
    _saveState();
    _applyFilters(); // This will trigger table update via ValueNotifier
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
      
      print('🔄 Silently refreshing current page and status counts in background...');
      
      // Store current filtered count to detect changes
      final currentFilteredCount = filteredAppointments.length;
      
      // Refresh status counts and current page in parallel (with silent refresh flag)
      await Future.wait([
        _loadPage(currentPage, isSilentRefresh: true),
        _loadStatusCounts(),
      ]);
      
      // Check if there are new appointments and show notification
      final newFilteredCount = filteredAppointments.length;
      if (newFilteredCount > currentFilteredCount) {
        final newAppointments = newFilteredCount - currentFilteredCount;
        _showNewAppointmentsSnackbar(newAppointments);
      }
      
      print('✅ Silent refresh complete: ${appointments.length} appointments on page $currentPage');
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

  /// Refresh after status changes - reload current page and status counts
  Future<void> _refreshAfterStatusChange() async {
    if (_cachedClinicId == null || !mounted) return;

    try {
      print('🔄 Refreshing after status change - reloading current page...');
      
      // Refresh both current page and status counts
      await Future.wait([
        _loadPage(currentPage),
        _loadStatusCounts(),
      ]);
      
      print('✅ Refresh after status change complete');
    } catch (e) {
      print('❌ Error during refresh after status change: $e');
      // Fallback to regular refresh if refresh fails
      await _refreshData();
    }
  }

  /// Handle page change (matches user management style)
  void _onPageChanged(int page) {
    print('🔄 Page change requested: $currentPage -> $page');
    if (page != currentPage) {
      // Update page without rebuilding entire screen
      currentPage = page;
      _saveState(); // Save state when page changes
      
      // For search mode, Follow-up filter, or pet type/breed filters, just re-apply filters with new page
      if (searchQuery.isNotEmpty || selectedStatus == 'Follow-up' || selectedPetType != null || selectedBreed != null) {
        _applyFilters(); // This will paginate the filtered results and trigger table update
      } else {
        _loadPage(page, isPagination: true); // Load new page data with pagination flag
      }
    } else {
      print('⚠️ Same page requested, ignoring');
    }
  }

  /// Restore state from ScreenStateService
  void _restoreState() {
    currentPage = _stateService.appointmentCurrentPage;
    searchQuery = _stateService.appointmentSearchQuery;
    selectedStatus = _stateService.appointmentSelectedStatus;
    startDate = _stateService.appointmentStartDate;
    endDate = _stateService.appointmentEndDate;
    selectedPetType = _stateService.appointmentSelectedPetType;
    selectedBreed = _stateService.appointmentSelectedBreed;
    bookedAtSortOrder = SortOrder.fromString(_stateService.appointmentDateSortOrder);
  }

  /// Save current state to ScreenStateService
  void _saveState() {
    _stateService.saveAppointmentState(
      currentPage: currentPage,
      searchQuery: searchQuery,
      selectedStatus: selectedStatus,
      dateSortOrder: bookedAtSortOrder.value,
      startDate: startDate,
      endDate: endDate,
      followUpFilter: null, // No longer using separate follow-up filter
      selectedPetType: selectedPetType,
      selectedBreed: selectedBreed,
    );
  }

  /// Handle search with debouncing
  void _onSearchChanged(String query) {
    // Cancel previous timer
    _searchDebounce?.cancel();

    // Debounce both data loading to prevent excessive queries
    _searchDebounce = Timer(const Duration(milliseconds: 600), () {
      if (mounted && query != searchQuery) {
        // Update state without rebuilding entire screen
        searchQuery = query;
        currentPage = 1; // Reset to first page
        _saveState();
        _loadDataWithNewFilter();
      }
    });
  }

  /// Handle status filter change
  void _onStatusChanged(String status) {
    // Update state without rebuilding entire screen
    selectedStatus = status;
    currentPage = 1; // Reset to first page
    _saveState();
    
    // Reload data with new filter instead of just applying client-side filter
    _loadDataWithNewFilter();
  }

  /// Handle start date change
  void _onStartDateChanged(DateTime? date) {
    // Update state without rebuilding entire screen
    startDate = date;
    // If endDate is null, set it to today
    if (date != null && endDate == null) {
      endDate = DateTime.now();
    }
    currentPage = 1; // Reset to first page
    _saveState();
    // Reload data with new date filter
    _loadDataWithNewFilter();
  }

  /// Handle end date change
  void _onEndDateChanged(DateTime? date) {
    // Update state without rebuilding entire screen
    endDate = date;
    currentPage = 1; // Reset to first page
    _saveState();
    
    // Reload data with new date filter
    _loadDataWithNewFilter();
  }

  /// Handle pet type change
  void _onPetTypeChanged(String? petType) {
    // Update state without rebuilding entire screen
    selectedPetType = petType;
    // Reset breed when pet type changes
    selectedBreed = null;
    currentPage = 1; // Reset to first page
    _saveState();
    
    // Reload data with new filter
    _loadDataWithNewFilter();
  }

  /// Handle breed change
  void _onBreedChanged(String? breed) {
    // Update state without rebuilding entire screen
    selectedBreed = breed;
    currentPage = 1; // Reset to first page
    _saveState();
    
    // Reload data with new filter
    _loadDataWithNewFilter();
  }

  /// Handle export data - exports ALL filtered appointments to PDF
  Future<void> _onExportData() async {
    if (_cachedClinicId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to export: Clinic information not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show loading indicator
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 16),
              Text('Generating PDF report...'),
            ],
          ),
          duration: Duration(seconds: 30),
          backgroundColor: Colors.blue,
        ),
      );
    }

    try {
      print('📊 Generating PDF report with filters...');
      
      // Fetch ALL filtered appointments (not just current page)
      final result = await PaginatedAppointmentService.getClinicAppointmentsPaginated(
        clinicId: _cachedClinicId!,
        page: 1,
        itemsPerPage: 999999, // Get all matching records
        status: _getStatusFilterForService(),
        startDate: startDate,
        endDate: endDate,
      );

      List<AppointmentModels.Appointment> allAppointments = result.appointments;

      // Apply search filter if present (client-side)
      if (searchQuery.isNotEmpty) {
        allAppointments = allAppointments.where((appointment) {
          return appointment.pet.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
              appointment.owner.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
              appointment.diseaseReason.toLowerCase().contains(searchQuery.toLowerCase());
        }).toList();
      }

      // Apply pet type filter if present (client-side)
      if (selectedPetType != null) {
        allAppointments = allAppointments.where((appointment) {
          return appointment.pet.type.toLowerCase() == selectedPetType!.toLowerCase();
        }).toList();
      }

      // Apply breed filter if present (client-side)
      if (selectedBreed != null) {
        allAppointments = allAppointments.where((appointment) {
          return appointment.pet.breed != null &&
              appointment.pet.breed!.toLowerCase() == selectedBreed!.toLowerCase();
        }).toList();
      }

      // Apply sorting
      allAppointments.sort((a, b) {
        try {
          final dateA = a.createdAt;
          final dateB = b.createdAt;
          
          if (bookedAtSortOrder == SortOrder.ascending) {
            return dateA.compareTo(dateB);
          } else {
            return dateB.compareTo(dateA);
          }
        } catch (e) {
          return 0;
        }
      });

      if (allAppointments.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No appointments to export'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Get clinic details for logo and address
      String clinicAddress = '';
      Uint8List? clinicLogo;
      
      try {
        final clinicDetails = await ClinicDetailsService.getClinicDetails(_cachedClinicId!);
        if (clinicDetails != null) {
          clinicAddress = clinicDetails.address;
          
          // Try to fetch clinic logo if available
          if (clinicDetails.logoUrl != null && clinicDetails.logoUrl!.isNotEmpty) {
            try {
              final response = await http.get(Uri.parse(clinicDetails.logoUrl!));
              if (response.statusCode == 200) {
                clinicLogo = response.bodyBytes;
              }
            } catch (e) {
              print('⚠️ Could not fetch clinic logo: $e');
            }
          }
        }
      } catch (e) {
        print('⚠️ Could not fetch clinic details: $e');
      }

      // Get current user for "generated by"
      String? generatedBy;
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
          if (userDoc.exists) {
            generatedBy = userDoc.data()?['name'] as String?;
          }
        }
      } catch (e) {
        print('⚠️ Could not fetch user name: $e');
      }

      // Generate PDF
      final pdfBytes = await AppointmentPdfService.generateAppointmentReport(
        appointments: allAppointments,
        clinicName: _cachedClinicName ?? 'Veterinary Clinic',
        clinicAddress: clinicAddress.isNotEmpty ? clinicAddress : 'Address not available',
        clinicLogo: clinicLogo,
        statusFilter: selectedStatus != 'All Status' ? selectedStatus : null,
        searchQuery: searchQuery.isNotEmpty ? searchQuery : null,
        startDate: startDate,
        endDate: endDate,
        petTypeFilter: selectedPetType,
        breedFilter: selectedBreed,
        generatedBy: generatedBy,
      );

      // Create filename with clinic name and timestamp
      final clinicNameSafe = _cachedClinicName?.replaceAll(RegExp(r'[^\w\s-]'), '') ?? 'clinic';
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filename = 'appointment_report_${clinicNameSafe}_$timestamp.pdf';
      
      file_downloader.downloadFile(filename, pdfBytes);

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Generated PDF report with ${allAppointments.length} appointments'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      print('📊 Generated PDF report with ${allAppointments.length} appointments');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      print('❌ Error generating PDF report: $e');
    }
  }

  /// Load fresh data when filter changes to ensure all matching appointments are shown
  Future<void> _loadDataWithNewFilter() async {
    // Show loading state while fetching (not initial loading)
    setState(() {
      _isLoading = true;
      error = null;
    });
    
    appointments.clear();
    filteredAppointments.clear();
    currentPage = 1;
    _pageCursors.clear(); // Clear page cursors when filters change

    // If there's a search query, Follow-up filter, or pet type/breed filters, load ALL appointments for comprehensive filtering
    if (searchQuery.isNotEmpty || selectedStatus == 'Follow-up' || selectedPetType != null || selectedBreed != null) {
      await _loadAllAppointmentsForSearch();
    } else {
      // For no search or client-side filtering, use normal pagination
      await _loadPage(1);
    }
  }

  /// Load all appointments when searching or using client-side filters (like Follow-up, pet type, breed)
  Future<void> _loadAllAppointmentsForSearch() async {
    if (_cachedClinicId == null) return;

    try {
      String filterType = 'filter';
      if (searchQuery.isNotEmpty) filterType = 'search';
      else if (selectedStatus == 'Follow-up') filterType = 'Follow-up filter';
      else if (selectedPetType != null || selectedBreed != null) filterType = 'pet type/breed filter';
      
      print('🔍 Loading ALL appointments for $filterType...');
      
      // Load all appointments with status filter but no pagination
      final result = await PaginatedAppointmentService.getClinicAppointmentsPaginated(
        clinicId: _cachedClinicId!,
        page: 1,
        itemsPerPage: 1000, // Large number to get all appointments
        status: _getStatusFilterForService(),
        startDate: startDate,
        endDate: endDate,
      );

      setState(() {
        appointments.clear();
        appointments.addAll(result.appointments);
        totalAppointments = result.totalCount ?? result.appointments.length;
        
        // Apply search and other filters to the complete dataset
        _applyFilters();
        
        isInitialLoading = false;
        _isLoading = false;
        
        print('✅ Loaded ${appointments.length} appointments for $filterType');
        print('🔍 Filtered results: ${filteredAppointments.length} appointments match criteria');
      });
    } catch (e) {
      print('❌ Error loading all appointments for search: $e');
      setState(() {
        error = 'Failed to load appointments for search';
        isInitialLoading = false;
        _isLoading = false;
      });
    }
  }



  /// Convert filter status string to AppointmentStatus enum for server-side filtering
  AppointmentStatus? _getStatusFilterForService() {
    if (selectedStatus == 'All Status') return null;
    
    // Follow-up filter doesn't map to appointment status enum
    // It will be filtered client-side in _applyFilters()
    if (selectedStatus == 'Follow-up') {
      return null; // Return null to get all appointments, then filter client-side
    }
    
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
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const AppointmentHeader(),
              const SizedBox(height: 24),

              // Summary - always visible (loads immediately like clinic management)
              AppointmentSummary(
                statusCounts: statusCounts ?? AppointmentStatusCounts(
                  pendingCount: 0,
                  confirmedCount: 0,
                  completedCount: 0,
                  cancelledCount: 0,
                  followUpCount: 0,
                ),
                isLoading: false, // No loading spinner, just show 0 counts initially
              ),
              const SizedBox(height: 24),
              
              // Filters - always visible (loads immediately like clinic management)
              AppointmentFilters(
                searchQuery: searchQuery,
                selectedStatus: selectedStatus,
                startDate: startDate,
                endDate: endDate,
                selectedPetType: selectedPetType,
                selectedBreed: selectedBreed,
                onSearchChanged: _onSearchChanged,
                onStatusChanged: _onStatusChanged,
                onStartDateChanged: _onStartDateChanged,
                onEndDateChanged: _onEndDateChanged,
                onPetTypeChanged: _onPetTypeChanged,
                onBreedChanged: _onBreedChanged,
                onExportData: _onExportData,
              ),
              const SizedBox(height: 16),

              // Appointment list with loading overlay (matches breed/disease management pattern)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Stack(
                  children: [
                    // Table content - wrapped in ValueListenableBuilder
                    ValueListenableBuilder<bool>(
                      valueListenable: _tableUpdateNotifier,
                      builder: (context, _, __) {
                        return (isInitialLoading || _isLoading) 
                            ? _buildLoadingState() 
                            : _buildAppointmentTable();
                      },
                    ),
                    
                    // Show loading overlay during pagination only
                    if (_isPaginationLoading)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.white.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 40,
                                    height: 40,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Loading page $currentPage...',
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Error state (shown below table area if needed)
              if (error != null && !isInitialLoading)
                Container(
                  margin: const EdgeInsets.all(24),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: AppColors.error),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          error!,
                          style: TextStyle(color: AppColors.error),
                        ),
                      ),
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

              // Bottom spacing
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  /// Build loading state (matches breed/disease management style)
  Widget _buildLoadingState() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(80.0),
              child: Column(
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading appointments...',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Build empty state (matches breed/disease management style)
  Widget _buildEmptyState() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(80.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.calendar_today,
                size: 80,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 24),
              Text(
                'No appointments found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Try adjusting your filters',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build appointment table (separated for efficient updates)
  Widget _buildAppointmentTable() {
    if (filteredAppointments.isEmpty) {
      return Column(
        children: [
          _buildEmptyState(),
        ],
      );
    }

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            children: [
              // Table header
              AppointmentTableHeader(
                bookedAtSortOrder: bookedAtSortOrder,
                onBookedAtSortChanged: _onBookedAtSortChanged,
              ),
              
              // Divider
              Divider(height: 1, thickness: 1, color: AppColors.border),
              
              // Appointment rows
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
                    onMarkNoShow: appointment.status == AppointmentModels.AppointmentStatus.confirmed
                        ? () => _onMarkNoShow(appointment)
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

        // Pagination Controls
        if (totalPages > 1) ...[
          const SizedBox(height: 24),
          PaginationWidget(
            currentPage: currentPage,
            totalPages: totalPages,
            totalItems: totalAppointments,
            onPageChanged: _onPageChanged,
            isLoading: _isPaginationLoading,
          ),
        ],
      ],
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

  Future<void> _onMarkNoShow(AppointmentModels.Appointment appointment) async {
    // Confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.person_off_outlined, color: AppColors.warning),
            SizedBox(width: 8),
            Text('Mark as No Show'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to mark this appointment as a no-show?',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('Pet:', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      Text(appointment.pet.name),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Text('Owner:', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      Text(appointment.owner.name),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Text('Date:', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      Text('${appointment.date} at ${appointment.time}'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppColors.warning),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Both you and the pet owner will be notified.',
                      style: TextStyle(fontSize: 12, color: AppColors.warning),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            child: const Text('Mark as No Show', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await AppointmentService.markAsNoShow(appointment.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Marked appointment for ${appointment.pet.name} as no-show'
                  : 'Failed to mark appointment as no-show',
            ),
            backgroundColor: success ? AppColors.warning : AppColors.error,
          ),
        );
        
        if (success) {
          try {
            await _refreshAfterStatusChange();
          } catch (e) {
            print('⚠️ Error refreshing data after marking as no-show: $e');
          }
        }
      }
    }
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
              maxLines: 5,
              maxLength: 300,
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

  /// Public method to open appointment modal by ID (can be called from anywhere using the global key)
  void openAppointmentById(String appointmentId) {
    print('📞 PUBLIC METHOD: openAppointmentById called with ID: $appointmentId');
    _openAppointmentDetailsById(appointmentId);
  }

  /// Open appointment details modal by ID (for navigation from notifications)
  Future<void> _openAppointmentDetailsById(String appointmentId) async {
    print('🔍 DEBUG: _openAppointmentDetailsById called with ID: $appointmentId');
    
    try {
      // Wait a bit to ensure the UI is ready and data is loaded
      await Future.delayed(const Duration(milliseconds: 1200));
      
      if (!mounted) {
        print('⚠️ DEBUG: Widget not mounted, aborting');
        return;
      }
      
      print('🔍 DEBUG: Searching for appointment in ${appointments.length} loaded appointments');
      print('🔍 DEBUG: Loaded appointment IDs: ${appointments.map((a) => a.id).take(5).toList()}...');
      
      // First, try to find the appointment in the current loaded list
      AppointmentModels.Appointment? foundAppointment;
      try {
        foundAppointment = appointments.firstWhere(
          (apt) => apt.id == appointmentId,
        );
        print('✅ DEBUG: Found appointment in loaded list!');
      } catch (e) {
        print('⚠️ DEBUG: Appointment not found in loaded list, will fetch from Firestore');
        foundAppointment = null;
      }
      
      if (foundAppointment != null) {
        // Found in current page, open the modal
        print('📱 DEBUG: Opening modal for appointment: ${foundAppointment.pet.name}');
        AppointmentDetailsModal.show(
          context,
          foundAppointment,
          showAcceptButton: false,
        );
        return;
      }
      
      // Appointment not in current page, fetch it directly from Firestore
      print('🔍 DEBUG: Fetching appointment from Firestore...');
      
      final doc = await FirebaseFirestore.instance
          .collection('appointments')
          .doc(appointmentId)
          .get();
      
      if (doc.exists && mounted) {
        print('✅ DEBUG: Fetched appointment from Firestore');
        final appointmentData = doc.data()!;
        final appointment = AppointmentModels.Appointment.fromFirestore(
          appointmentData,
          doc.id,
        );
        
        print('📱 DEBUG: Opening modal for fetched appointment: ${appointment.pet.name}');
        print('   Widget mounted: $mounted');
        print('   Context mounted: ${context.mounted}');
        
        // Ensure we're using a valid context
        if (!context.mounted) {
          print('❌ Context is not mounted!');
          return;
        }
        
        // Open the modal with the fetched appointment
        AppointmentDetailsModal.show(
          context,
          appointment,
          showAcceptButton: false,
        );
      } else if (mounted) {
        print('❌ DEBUG: Appointment not found in Firestore');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment not found'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      print('❌ ERROR in _openAppointmentDetailsById: $e');
      print('Stack trace: ${StackTrace.current}');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load appointment details: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
