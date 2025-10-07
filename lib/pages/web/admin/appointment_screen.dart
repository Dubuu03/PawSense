// screens/optimized_appointment_management_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/utils/app_colors.dart';
import '../../../core/models/clinic/appointment_models.dart' as AppointmentModels;
import '../../../core/services/clinic/appointment_service.dart';
import '../../../core/services/clinic/paginated_appointment_service.dart';
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
  
  // Appointment data
  List<AppointmentModels.Appointment> appointments = [];
  List<AppointmentModels.Appointment> filteredAppointments = [];
  
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
  
  // Firebase listener
  StreamSubscription<QuerySnapshot>? _appointmentsListener;
  bool _listenerSetup = false;
  bool _isFirstListenerEvent = true; // Skip first event (initial snapshot)
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
    _appointmentsListener?.cancel();
    _scrollController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  /// Initialize clinic data and load first page
  Future<void> _initializeData() async {
    await _getClinicId();
    if (_cachedClinicId != null) {
      await _loadFirstPage();
      // Setup listener after a delay to avoid build conflicts
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
      print('📥 Loading ${appointments.isEmpty ? 'first' : 'next'} page of appointments...');
      
      final result = await PaginatedAppointmentService.getClinicAppointmentsPaginated(
        clinicId: _cachedClinicId!,
        lastDocument: _lastDocument,
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

  /// Apply filters to appointments
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
    
    print('🔍 Filtered: ${filteredAppointments.length} of ${appointments.length} appointments');
  }

  /// Setup real-time listener for appointment changes
  void _setupRealtimeListener() {
    if (_listenerSetup || _cachedClinicId == null || !mounted) return;
    _listenerSetup = true;

    print('🔔 Setting up real-time listener for clinic: $_cachedClinicId');

    _appointmentsListener = FirebaseFirestore.instance
        .collection('appointments')
        .where('clinicId', isEqualTo: _cachedClinicId)
        .snapshots()
        .listen(
      (snapshot) {
        // Skip the first event (initial snapshot with all "added" changes)
        if (_isFirstListenerEvent) {
          _isFirstListenerEvent = false;
          print('🔔 Listener initialized (skipping initial snapshot)');
          return;
        }
        
        // Only refresh if there are actual changes and widget is still mounted
        if (!mounted || snapshot.docChanges.isEmpty) return;
        
        print('🔔 ${snapshot.docChanges.length} appointment(s) changed - scheduling background refresh');
        
        // Use a longer delay to ensure we're completely out of any build cycle
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && !_isRefreshing) {
            _refreshDataSilently();
          }
        });
      },
      onError: (error) {
        print('❌ Listener error: $error');
      },
    );
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
      
      print('🔄 Silently refreshing appointments in background...');
      
      // Load fresh data from first page
      final result = await PaginatedAppointmentService.getClinicAppointmentsPaginated(
        clinicId: _cachedClinicId!,
        lastDocument: null, // Start from beginning
      );

      if (mounted) {
        setState(() {
          appointments.clear();
          appointments.addAll(result.appointments);
          _lastDocument = result.lastDocument;
          _hasMore = result.hasMore;
          
          // Apply filters
          _applyFilters();
          
          print('✅ Silent refresh complete: ${appointments.length} appointments');
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
    await _loadFirstPage();
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
  }

  /// Save current state to ScreenStateService
  void _saveState() {
    _stateService.saveAppointmentState(
      searchQuery: searchQuery,
      selectedStatus: selectedStatus,
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
    _applyFilters();
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
                    AppointmentSummary(appointments: appointments),
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
                        const AppointmentTableHeader(),
                        
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
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.red,
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
        onCompleted: _refreshData,
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
          ),
        );
      }
    }
  }

  void _onEdit(AppointmentModels.Appointment appointment) {
    showDialog(
      context: context,
      builder: (context) => AppointmentEditModal(
        appointment: appointment,
        onUpdate: _refreshData,
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
          ),
        );
      }
    }
  }
}
