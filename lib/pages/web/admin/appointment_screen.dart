// screens/appointment_management_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/utils/app_colors.dart';
import '../../../core/models/clinic/appointment_models.dart' as AppointmentModels;
import '../../../core/services/clinic/appointment_service.dart';
import '../../../core/services/clinic/appointment_cache_service.dart';
import '../../../core/services/super_admin/screen_state_service.dart';
import '../../../core/widgets/admin/appointments/appointment_header.dart';
import '../../../core/widgets/admin/appointments/appointment_filters.dart';
import '../../../core/widgets/admin/appointments/appointment_table.dart';
import '../../../core/widgets/admin/appointments/appointment_summary.dart';
import '../../../core/widgets/admin/appointments/appointment_edit_modal.dart';
import '../../../core/widgets/admin/appointments/appointment_completion_modal.dart';
import '../../../core/widgets/admin/clinic_schedule/appointment_details_modal.dart';

class AppointmentManagementScreen extends StatefulWidget {
  const AppointmentManagementScreen({Key? key}) : super(key: key ?? const PageStorageKey('appointment_management'));

  @override
  State<AppointmentManagementScreen> createState() => _AppointmentManagementScreenState();
}

class _AppointmentManagementScreenState extends State<AppointmentManagementScreen> with AutomaticKeepAliveClientMixin {
  String searchQuery = '';
  String selectedStatus = 'All Status';
  List<AppointmentModels.Appointment> appointments = [];
  bool isLoading = true;
  String? error;
  String? _cachedClinicId; // Cache clinic ID to avoid repeated lookups

  // Services
  final _cacheService = AppointmentCacheService();
  final _stateService = ScreenStateService();
  
  // Firebase listener subscription
  StreamSubscription<QuerySnapshot>? _appointmentsListener;

  @override
  bool get wantKeepAlive => true; // Keep state alive when navigating away

  @override
  void initState() {
    super.initState();
    _restoreState();
    // Clear cache to ensure fresh data with assessmentResultId
    _cacheService.invalidateCache();
    _initializeClinicListener();
    _loadAppointments();
  }
  
  /// Initialize clinic ID and set up listener early
  Future<void> _initializeClinicListener() async {
    if (_cachedClinicId != null) {
      // Already have clinic ID, just set up listener
      _setupAppointmentsListener();
      return;
    }
    
    // Get clinic ID first
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    try {
      final clinicQuery = await FirebaseFirestore.instance
          .collection('clinics')
          .where('userId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'approved')
          .limit(1)
          .get();
      
      if (clinicQuery.docs.isNotEmpty) {
        _cachedClinicId = clinicQuery.docs.first.id;
        print('🔔 Clinic ID obtained early: $_cachedClinicId');
        _setupAppointmentsListener();
      }
    } catch (e) {
      print('❌ Error getting clinic ID for listener: $e');
    }
  }

  @override
  void dispose() {
    _saveState();
    // Cancel listener when widget is disposed
    _appointmentsListener?.cancel();
    super.dispose();
  }

  /// Restore state from ScreenStateService
  void _restoreState() {
    searchQuery = _stateService.appointmentSearchQuery;
    selectedStatus = _stateService.appointmentSelectedStatus;
    print('🔄 Restored appointment management state: status="$selectedStatus", search="$searchQuery"');
  }

  /// Save current state to ScreenStateService
  void _saveState() {
    _stateService.saveAppointmentState(
      searchQuery: searchQuery,
      selectedStatus: selectedStatus,
    );
  }

  Future<void> _loadAppointments({bool forceRefresh = false}) async {
    // Check if filters changed (clear cache if so)
    final filtersChanged = _cacheService.hasFiltersChanged(searchQuery, selectedStatus);
    if (filtersChanged) {
      _cacheService.invalidateCache();
      print('🔄 Filters changed - cache invalidated');
    }

    // Try to load from cache first (always check cache unless force refresh)
    if (!forceRefresh) {
      final cachedAppointments = _cacheService.getCachedAppointments(
        searchQuery: searchQuery,
        selectedStatus: selectedStatus,
      );

      if (cachedAppointments != null) {
        print('📦 Using cached appointment data - no network call needed');
        setState(() {
          appointments = cachedAppointments;
          isLoading = false;
        });
        
        // Ensure listener is set up even when using cached data
        if (_cachedClinicId != null) {
          _setupAppointmentsListener();
        }
        
        return;
      }
    }

    // Show loading only if no data cached
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          error = 'User not authenticated';
          isLoading = false;
        });
        return;
      }

      // Use cached clinic ID if available
      String? clinicId = _cachedClinicId;

      if (clinicId == null) {
        // First, find the clinic document for this user
        print('👤 Looking up clinic for admin user UID: ${user.uid}');
        
        final clinicQuery = await FirebaseFirestore.instance
            .collection('clinics')
            .where('userId', isEqualTo: user.uid)
            .where('status', isEqualTo: 'approved')
            .limit(1)
            .get();

        print('🏥 Found ${clinicQuery.docs.length} approved clinics for user ${user.uid}');

        if (clinicQuery.docs.isEmpty) {
          print('❌ No approved clinic found for user ${user.uid}');
          
          setState(() {
            error = 'No approved clinic found for this user';
            isLoading = false;
          });
          return;
        }

        clinicId = clinicQuery.docs.first.id;
        _cachedClinicId = clinicId; // Cache for future calls
        
        final clinicData = clinicQuery.docs.first.data();
        print('🎯 Using clinic ID: $clinicId (${clinicData['clinicName']})');
        
        // Set up real-time listener for this clinic
        _setupAppointmentsListener();
      } else {
        print('📦 Using cached clinic ID: $clinicId');
      }

      // Load appointments for this clinic using the clinic document ID
      print('🔄 Fetching appointments from Firestore...');
      final loadedAppointments = await AppointmentService.getClinicAppointments(clinicId);

      // Update cache with new data
      _cacheService.updateCache(
        appointments: loadedAppointments,
        searchQuery: searchQuery,
        selectedStatus: selectedStatus,
      );

      setState(() {
        appointments = loadedAppointments;
        isLoading = false;
      });

      print('✅ Loaded ${loadedAppointments.length} appointments');
    } catch (e) {
      print('❌ Error loading appointments: $e');
      setState(() {
        error = 'Failed to load appointments: $e';
        isLoading = false;
      });
    }
  }

  /// Set up Firebase listener for real-time appointment updates
  void _setupAppointmentsListener() {
    if (_cachedClinicId == null) return;
    
    // Don't set up multiple listeners
    if (_appointmentsListener != null) {
      print('🔔 Firebase listener already active');
      return;
    }
    
    print('🔔 Setting up Firebase listener for appointments - clinic: $_cachedClinicId');
    
    // Listen to appointments collection for changes
    _appointmentsListener = FirebaseFirestore.instance
        .collection('appointments')
        .where('clinicId', isEqualTo: _cachedClinicId)
        .snapshots()
        .listen((snapshot) {
      // When appointments change, invalidate cache and reload
      print('🔔 Appointments changed - ${snapshot.docChanges.length} changes detected');
      
      for (var change in snapshot.docChanges) {
        final data = change.doc.data();
        final petName = data?['petName'] ?? 'Unknown';
        print('   - ${change.type.name}: $petName');
      }
      
      // Clear cache to force reload
      _cacheService.invalidateCache();
      
      // Reload data silently (without showing loading spinner)
      _refreshAppointmentsSilently();
    }, onError: (error) {
      print('❌ Error in appointments listener: $error');
    });
  }
  
  /// Refresh appointments without showing loading indicator
  Future<void> _refreshAppointmentsSilently() async {
    if (_cachedClinicId == null || !mounted) return;
    
    try {
      print('🔄 Silently refreshing appointments...');
      final loadedAppointments = await AppointmentService.getClinicAppointments(_cachedClinicId!);
      
      // Update cache
      _cacheService.updateCache(
        appointments: loadedAppointments,
        searchQuery: searchQuery,
        selectedStatus: selectedStatus,
      );
      
      if (mounted) {
        setState(() {
          appointments = loadedAppointments;
          error = null;
        });
        print('✅ Appointments refreshed silently - ${loadedAppointments.length} total');
      }
    } catch (e) {
      print('❌ Error refreshing appointments silently: $e');
      // Don't update error state for silent refresh failures
    }
  }

  Future<void> _refreshAppointments() async {
    await _loadAppointments(forceRefresh: true);
  }

  void _onSearchChanged(String query) {
    setState(() {
      searchQuery = query;
    });
    _saveState();
    // Debounced search could be added here if needed
    _loadAppointments();
  }

  void _onStatusChanged(String status) {
    setState(() {
      selectedStatus = status;
    });
    _saveState();
    _loadAppointments();
  }
  
  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _refreshAppointments,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const AppointmentHeader(),
              const SizedBox(height: 24),

              // Loading state
              if (isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        CircularProgressIndicator(color: AppColors.primary),
                        SizedBox(height: 16),
                        Text('Loading appointments...', style: TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                )
              // Error state
              else if (error != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        Icon(Icons.error_outline, size: 48, color: AppColors.error),
                        const SizedBox(height: 16),
                        Text(error!, style: TextStyle(color: AppColors.error)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _refreshAppointments,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              // Content
              else ...[
                // Summary
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

                // Table
                Builder(
                  builder: (context) {
                    // Filter appointments for the table
                    List<AppointmentModels.Appointment> filteredAppointments = appointments.where((appointment) {
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

                    if (filteredAppointments.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Column(
                            children: [
                              Icon(Icons.calendar_today, size: 48, color: AppColors.textSecondary),
                              SizedBox(height: 16),
                              Text(
                                'No appointments found',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Try adjusting your filters or create a new appointment',
                                style: TextStyle(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return AppointmentTable(
                      appointments: filteredAppointments,
                      onAccept: (appointment) {
                        // Show appointment details modal with accept button
                        AppointmentDetailsModal.show(
                          context,
                          appointment,
                          showAcceptButton: true,
                          onAcceptAppointment: () async {
                            final result = await AppointmentService.acceptAppointment(appointment.id);
                            
                            if (result['success']) {
                              _refreshAppointments();
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
                                  duration: Duration(seconds: 4), // Longer duration for error messages
                                ),
                              );
                            }
                          },
                        );
                      },
                      onMarkDone: (appointment) {
                        showDialog(
                          context: context,
                          builder: (context) => AppointmentCompletionModal(
                            appointment: appointment,
                            onCompleted: _refreshAppointments,
                          ),
                        );
                      },
                      onReject: (appointment) async {
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
                                    hintText: 'Please provide a reason for rejecting this appointment',
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
                          final success = await AppointmentService.rejectAppointment(appointment.id, reason);
                          
                          if (success) {
                            _refreshAppointments();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Rejected appointment for ${appointment.pet.name}')),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Failed to reject appointment')),
                            );
                          }
                        }
                      },
                      onEdit: (appointment) {
                        showDialog(
                          context: context,
                          builder: (context) => AppointmentEditModal(
                            appointment: appointment,
                            onUpdate: _refreshAppointments,
                          ),
                        );
                      },
                      onDelete: (appointment) async {
                        // Show confirmation dialog
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Appointment'),
                            content: Text('Are you sure you want to delete the appointment for ${appointment.pet.name}?'),
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
                          // Update status to cancelled instead of deleting
                          final success = await AppointmentService.updateAppointmentStatus(
                            appointment.id,
                            AppointmentModels.AppointmentStatus.cancelled,
                          );
                          
                          if (success) {
                            _refreshAppointments();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Cancelled appointment for ${appointment.pet.name}')),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Failed to cancel appointment')),
                            );
                          }
                        }
                      },
                      onView: (appointment) {
                        // Use the AppointmentDetailsModal without accept button
                        AppointmentDetailsModal.show(
                          context,
                          appointment,
                          showAcceptButton: false,
                        );
                      },
                    );
                  },
                ),
              ],
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}