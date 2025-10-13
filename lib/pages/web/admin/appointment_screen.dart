// screens/optimized_appointment_management_screen.dart
import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
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
import '../../../core/widgets/shared/pagination_widget.dart';

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
  DateTime? startDate;
  DateTime? endDate;
  SortOrder bookedAtSortOrder = SortOrder.descending; // Default to newest first
  
  // Appointment data
  List<AppointmentModels.Appointment> appointments = [];
  List<AppointmentModels.Appointment> filteredAppointments = [];
  
  // Status counts (for summary badges - fetched separately from all appointments)
  AppointmentStatusCounts? statusCounts;
  bool isLoadingStatusCounts = true;
  
  // Loading state
  bool isInitialLoading = true;
  String? error;
  
  // Pagination
  int currentPage = 1;
  int totalPages = 1;
  int totalAppointments = 0;
  bool _isPaginationLoading = false; // Separate loading state for pagination
  
  // Page cursors for navigation
  Map<int, DocumentSnapshot?> _pageCursors = {}; // Store last document for each page
  
  // Clinic data
  String? _cachedClinicId;
  String? _cachedClinicName;
  
  // Services
  final _stateService = ScreenStateService();
  final _realtimeListener = RealTimeAppointmentListener();
  
  // Real-time updates state
  bool _isRefreshing = false; // Prevent concurrent refreshes
  
  // Debounce timer for search
  Timer? _searchDebounce;

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

  /// Load appointments starting from current page (restored from state)
  Future<void> _loadFirstPage() async {
    setState(() {
      isInitialLoading = true;
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
  Future<void> _loadPage(int page, {bool isPagination = false}) async {
    if (_cachedClinicId == null) return;

    setState(() {
      if (page == 1 && !isPagination) {
        isInitialLoading = true;
      } else if (isPagination) {
        _isPaginationLoading = true;
      }
    });

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
        _isPaginationLoading = false;
        
        print('✅ Loaded page $page: ${result.appointments.length} appointments. Total: $totalAppointments, Pages: $totalPages');
        print('📋 Appointment IDs on this page: ${result.appointments.map((a) => a.id).take(3).join(", ")}${result.appointments.length > 3 ? "..." : ""}');
        
        // Apply filters and sorting to the loaded appointments
        _applyFilters();
      });
    } catch (e) {
      print('❌ Error loading appointments page $page: $e');
      setState(() {
        error = 'Failed to load appointments';
        isInitialLoading = false;
        _isPaginationLoading = false;
      });
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
    
    // For search mode, show only the current page of filtered results
    if (searchQuery.isNotEmpty) {
      final itemsPerPage = 10;
      final startIndex = (currentPage - 1) * itemsPerPage;
      final endIndex = (startIndex + itemsPerPage).clamp(0, allFiltered.length);
      
      filteredAppointments = allFiltered.sublist(startIndex, endIndex);
      
      // Update pagination for search results
      totalAppointments = allFiltered.length;
      totalPages = (totalAppointments / itemsPerPage).ceil();
      if (totalPages == 0) totalPages = 1;
      
      print('🔍 Search results: ${allFiltered.length} total matches, showing page $currentPage (${filteredAppointments.length} appointments)');
      print('📄 Pagination: Page $currentPage of $totalPages');
    } else {
      // For no search, show all results from current page load
      filteredAppointments = allFiltered;
      print('🔍 Filtered: ${filteredAppointments.length} of ${appointments.length} appointments');
    }
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
      
      print('🔄 Silently refreshing current page and status counts in background...');
      
      // Store current filtered count to detect changes
      final currentFilteredCount = filteredAppointments.length;
      
      // Refresh status counts and current page in parallel
      await Future.wait([
        _loadPage(currentPage),
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
      setState(() {
        currentPage = page;
      });
      _saveState(); // Save state when page changes
      
      // For search mode, just re-apply filters with new page
      if (searchQuery.isNotEmpty) {
        _applyFilters(); // This will paginate the filtered results
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
    );
  }

  /// Handle search with debouncing
  void _onSearchChanged(String query) {
    // Cancel previous timer
    _searchDebounce?.cancel();

    // Debounce both setState and data loading to prevent UI jumps
    _searchDebounce = Timer(const Duration(milliseconds: 600), () {
      if (mounted && query != searchQuery) {
        setState(() {
          searchQuery = query;
          currentPage = 1; // Reset to first page
        });
        _saveState();
        _loadDataWithNewFilter();
      }
    });
  }

  /// Handle status filter change
  void _onStatusChanged(String status) {
    setState(() {
      selectedStatus = status;
      currentPage = 1; // Reset to first page
    });
    _saveState();
    
    // Reload data with new filter instead of just applying client-side filter
    _loadDataWithNewFilter();
  }

  /// Handle start date change
  void _onStartDateChanged(DateTime? date) {
    setState(() {
      startDate = date;
      // If endDate is null, set it to today
      if (date != null && endDate == null) {
        endDate = DateTime.now();
      }
      currentPage = 1; // Reset to first page
    });
    _saveState();
    // Reload data with new date filter
    _loadDataWithNewFilter();
  }

  /// Handle end date change
  void _onEndDateChanged(DateTime? date) {
    setState(() {
      endDate = date;
      currentPage = 1; // Reset to first page
    });
    _saveState();
    
    // Reload data with new date filter
    _loadDataWithNewFilter();
  }

  /// Handle export data - exports ALL filtered appointments to CSV
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
              Text('Preparing export...'),
            ],
          ),
          duration: Duration(seconds: 30),
          backgroundColor: Colors.blue,
        ),
      );
    }

    try {
      print('📊 Exporting appointments with filters...');
      
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

      // Generate CSV content (with AI diagnosis data)
      final csvContent = await _generateCSV(allAppointments);

      // Create blob and download
      final bytes = utf8.encode(csvContent);
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      
      // Create filename with clinic name and timestamp
      final clinicNameSafe = _cachedClinicName?.replaceAll(RegExp(r'[^\w\s-]'), '') ?? 'clinic';
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filename = 'appointments_${clinicNameSafe}_$timestamp.csv';
      
      final anchor = html.document.createElement('a') as html.AnchorElement
        ..href = url
        ..style.display = 'none'
        ..download = filename;

      html.document.body?.children.add(anchor);
      anchor.click();

      html.document.body?.children.remove(anchor);
      html.Url.revokeObjectUrl(url);

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Exported ${allAppointments.length} appointments to CSV'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      print('📊 Exported ${allAppointments.length} appointments to $filename');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting CSV: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      print('❌ Error exporting CSV: $e');
    }
  }

  Future<String> _generateCSV(List<AppointmentModels.Appointment> appointments) async {
    final buffer = StringBuffer();
    
    // CSV Headers
    buffer.writeln(
      'Appointment ID,Pet Name,Pet Type,Pet Breed,Pet Age,Owner Name,Owner Email,Owner Phone,'
      'Disease/Reason,Appointment Date,Appointment Time,Time Slot,Status,Booked At,'
      'Veterinarian ID,AI Diagnosis Results,Diagnosis,Treatment,Prescription,'
      'Clinic Notes,Needs Follow-up,Follow-up Date,Follow-up Time,Cancel Reason,Cancelled At,Completed At'
    );

    // CSV Rows
    for (final appointment in appointments) {
      // Format dates
      final bookedAt = DateFormat('yyyy-MM-dd HH:mm:ss').format(appointment.createdAt);
      final completedAt = appointment.completedAt != null 
          ? DateFormat('yyyy-MM-dd HH:mm:ss').format(appointment.completedAt!) 
          : '';
      final cancelledAt = appointment.cancelledAt != null
          ? DateFormat('yyyy-MM-dd HH:mm:ss').format(appointment.cancelledAt!)
          : '';
      
      // Get status display name
      final status = _formatStatus(appointment.status);
      
      // Get AI diagnosis results if available
      String aiDiagnosisResults = '';
      if (appointment.assessmentResultId != null && appointment.assessmentResultId!.isNotEmpty) {
        try {
          final assessmentDoc = await FirebaseFirestore.instance
              .collection('assessment_results')
              .doc(appointment.assessmentResultId)
              .get();
          
          if (assessmentDoc.exists) {
            final data = assessmentDoc.data();
            final analysisResults = data?['analysisResults'] as List?;
            
            if (analysisResults != null && analysisResults.isNotEmpty) {
              final results = List<Map<String, dynamic>>.from(
                analysisResults.where((r) => r is Map<String, dynamic>).cast<Map<String, dynamic>>(),
              )..sort((a, b) {
                  final percentA = a['percentage'] as num? ?? 0;
                  final percentB = b['percentage'] as num? ?? 0;
                  return percentB.compareTo(percentA);
                });
              
              aiDiagnosisResults = results.map((r) {
                final condition = r['condition'] as String? ?? 'Unknown';
                final percentage = r['percentage'] as num? ?? 0;
                return '$condition (${percentage.toStringAsFixed(1)}%)';
              }).join('; ');
            }
          }
        } catch (e) {
          aiDiagnosisResults = 'Error loading';
        }
      }
      
      buffer.writeln(
        '${_escapeCsv(appointment.id)},'
        '${_escapeCsv(appointment.pet.name)},'
        '${_escapeCsv(appointment.pet.type)},'
        '${_escapeCsv(appointment.pet.breed ?? '')},'
        '${appointment.pet.age ?? ''},'
        '${_escapeCsv(appointment.owner.name)},'
        '${_escapeCsv(appointment.owner.email ?? '')},'
        '${_escapeCsv(appointment.owner.phone)},'
        '${_escapeCsv(appointment.diseaseReason)},'
        '${_escapeCsv(appointment.date)},'
        '${_escapeCsv(appointment.time)},'
        '${_escapeCsv(appointment.timeSlot)},'
        '$status,'
        '$bookedAt,'
        '${_escapeCsv(appointment.veterinarianId ?? '')},'
        '${_escapeCsv(aiDiagnosisResults)},'
        '${_escapeCsv(appointment.diagnosis ?? '')},'
        '${_escapeCsv(appointment.treatment ?? '')},'
        '${_escapeCsv(appointment.prescription ?? '')},'
        '${_escapeCsv(appointment.clinicNotes ?? '')},'
        '${appointment.needsFollowUp == true ? 'Yes' : 'No'},'
        '${_escapeCsv(appointment.followUpDate ?? '')},'
        '${_escapeCsv(appointment.followUpTime ?? '')},'
        '${_escapeCsv(appointment.cancelReason ?? '')},'
        '$cancelledAt,'
        '$completedAt'
      );
    }

    return buffer.toString();
  }

  String _formatStatus(AppointmentModels.AppointmentStatus status) {
    return status.name.toUpperCase();
  }

  String _escapeCsv(String value) {
    // Escape double quotes and wrap in quotes if contains comma, newline, or quotes
    if (value.contains(',') || value.contains('\n') || value.contains('"')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  /// Load fresh data when filter changes to ensure all matching appointments are shown
  Future<void> _loadDataWithNewFilter() async {
    setState(() {
      isInitialLoading = true;
      appointments.clear();
      filteredAppointments.clear();
      currentPage = 1;
      _pageCursors.clear(); // Clear page cursors when filters change
    });

    // If there's a search query, load ALL appointments for comprehensive search
    if (searchQuery.isNotEmpty) {
      await _loadAllAppointmentsForSearch();
    } else {
      // For no search, use normal pagination
      await _loadPage(1);
    }
  }

  /// Load all appointments when searching to ensure comprehensive results
  Future<void> _loadAllAppointmentsForSearch() async {
    if (_cachedClinicId == null) return;

    try {
      print('🔍 Loading ALL appointments for search: "$searchQuery"...');
      
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
        
        print('✅ Loaded ${appointments.length} appointments for search');
        print('🔍 Search results: ${filteredAppointments.length} appointments match "$searchQuery"');
      });
    } catch (e) {
      print('❌ Error loading all appointments for search: $e');
      setState(() {
        error = 'Failed to load appointments for search';
        isInitialLoading = false;
      });
    }
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
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const AppointmentHeader(),
              const SizedBox(height: 24),

              // Loading state (initial)
              if (isInitialLoading)
                Container(
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: const Center(
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
                Container(
                  height: MediaQuery.of(context).size.height * 0.5,
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
                  startDate: startDate,
                  endDate: endDate,
                  onSearchChanged: _onSearchChanged,
                  onStatusChanged: _onStatusChanged,
                  onStartDateChanged: _onStartDateChanged,
                  onEndDateChanged: _onEndDateChanged,
                  onExportData: _onExportData,
                ),
                const SizedBox(height: 16),

                // Appointment list
                if (filteredAppointments.isEmpty)
                  Container(
                    height: 300,
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
                else ...[
                  // Appointment list with pagination loading overlay
                  Stack(
                    children: [
                      Container(
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
                      
                      // Show loading overlay during pagination
                      if (_isPaginationLoading)
                        Positioned.fill(
                          child: Container(
                            margin: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppColors.white.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Container(
                                padding: EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: Offset(0, 4),
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
                                    SizedBox(height: 16),
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
              ],

              // Bottom spacing
              const SizedBox(height: 24),
            ],
          ),
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
