import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pawsense/core/models/clinic/clinic_registration_model.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';
import 'package:pawsense/core/widgets/shared/page_header.dart';
import '../../../core/widgets/super_admin/clinic_management/clinic_summary_cards.dart';
import '../../../core/widgets/super_admin/clinic_management/clinic_search_and_filter.dart';
import '../../../core/widgets/super_admin/clinic_management/clinics_list.dart';
import '../../../core/widgets/shared/pagination_widget.dart';
import '../../../core/services/super_admin/super_admin_service.dart';
import '../../../core/services/super_admin/clinic_cache_service.dart';
import '../../../core/services/super_admin/screen_state_service.dart';

class ClinicManagementScreen extends StatefulWidget {
  const ClinicManagementScreen({Key? key}) : super(key: key ?? const PageStorageKey('clinic_management'));

  @override
  State<ClinicManagementScreen> createState() => _ClinicManagementScreenState();
}

class _ClinicManagementScreenState extends State<ClinicManagementScreen> with AutomaticKeepAliveClientMixin {
  List<ClinicRegistration> _clinics = [];
  bool _isLoading = true;
  bool _isInitialLoad = true;
  bool _isPaginationLoading = false; // Separate loading state for pagination
  Map<String, int> _clinicStats = {};
  
  // Pagination - fixed at 5 items per page
  int _currentPage = 1;
  int _totalClinics = 0;
  int _totalPages = 0;
  final int _itemsPerPage = 5; // Fixed at 5 items per page
  
  // Filters
  String _searchQuery = '';
  String _selectedStatus = ''; // Start with empty string to match "All Status" behavior
  
  // Services
  final _cacheService = ClinicCacheService();
  final _stateService = ScreenStateService();
  
  // Debouncing for search
  Timer? _debounceTimer;
  final Duration _debounceDuration = Duration(milliseconds: 500);

  @override
  bool get wantKeepAlive => true; // Keep state alive when navigating away

  @override
  void initState() {
    super.initState();
    _restoreState();
    _loadClinics();
  }
  
  @override
  void dispose() {
    _saveState();
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// Restore state from ScreenStateService
  void _restoreState() {
    _currentPage = _stateService.clinicCurrentPage;
    _searchQuery = _stateService.clinicSearchQuery;
    _selectedStatus = _stateService.clinicSelectedStatus;
    print('🔄 Restored clinic management state: page=$_currentPage, status="$_selectedStatus", search="$_searchQuery"');
  }

  /// Save current state to ScreenStateService
  void _saveState() {
    _stateService.saveClinicState(
      currentPage: _currentPage,
      searchQuery: _searchQuery,
      selectedStatus: _selectedStatus,
    );
  }

  Future<void> _loadClinics({bool forceRefresh = false, bool isPagination = false}) async {
    // Check if filters changed (clear cache if so)
    final filtersChanged = _cacheService.hasFiltersChanged(_selectedStatus, _searchQuery);
    if (filtersChanged && !_isInitialLoad) {
      _cacheService.invalidateCacheForFilterChange();
    }
    
    // Try to load from multi-page cache first
    if (!forceRefresh && !_isInitialLoad) {
      final cachedPage = _cacheService.getCachedPage(
        statusFilter: _selectedStatus,
        searchQuery: _searchQuery,
        page: _currentPage,
      );
      
      if (cachedPage != null) {
        print('📦 Using cached page data - no network call needed');
        setState(() {
          _clinics = cachedPage.clinics;
          _totalClinics = cachedPage.totalClinics;
          _totalPages = cachedPage.totalPages;
          _isPaginationLoading = false;
        });
        
        // Load stats from cache if available
        final cachedStats = _cacheService.cachedStats;
        if (cachedStats != null) {
          setState(() {
            _clinicStats = cachedStats;
          });
        }
        return;
      }
    }
    
    // Set appropriate loading state
    setState(() {
      if (_isInitialLoad) {
        _isLoading = true;
      } else if (isPagination) {
        _isPaginationLoading = true;
      }
    });
    
    try {
      print('🔄 Loading clinics from Firestore...');
      print('Selected Status: "$_selectedStatus"');
      
      // Convert filter strings to API format
      String? statusFilter;
      if (_selectedStatus.isNotEmpty && _selectedStatus != 'All Status') {
        statusFilter = _selectedStatus.toLowerCase();
      }
      
      print('Filters - Status: $statusFilter, Search: $_searchQuery');
      
      // Fetch statistics and paginated clinics in parallel for better performance
      final results = await Future.wait([
        SuperAdminService.getClinicStatistics(),
        SuperAdminService.getPaginatedClinicRegistrations(
          page: _currentPage,
          itemsPerPage: _itemsPerPage,
          statusFilter: statusFilter,
          searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
        ),
      ]);
      
      final stats = results[0] as Map<String, int>;
      final paginatedResult = results[1];
      
      final clinics = paginatedResult['clinics'] as List<ClinicRegistration>;
      final totalClinics = paginatedResult['totalClinics'] as int;
      final totalPages = paginatedResult['totalPages'] as int;
      
      // Fallback: if statistics are all 0 but we have clinics, compute manually
      final hasEmptyStats = stats.values.every((count) => count == 0);
      Map<String, int> finalStats = stats;
      
      if (hasEmptyStats && clinics.isNotEmpty) {
        finalStats = {
          'total': totalClinics,
          'pending': clinics.where((c) => c.status == ClinicStatus.pending).length,
          'approved': clinics.where((c) => c.status == ClinicStatus.approved).length,
          'rejected': clinics.where((c) => c.status == ClinicStatus.rejected).length,
          'suspended': clinics.where((c) => c.status == ClinicStatus.suspended).length,
        };
      }
      
      // Update cache with current page data
      _cacheService.updateCache(
        clinics: clinics,
        totalClinics: totalClinics,
        totalPages: totalPages,
        stats: finalStats,
        statusFilter: _selectedStatus,
        searchQuery: _searchQuery,
        page: _currentPage,
      );
      
      setState(() {
        _clinics = clinics;
        _totalClinics = totalClinics;
        _totalPages = totalPages;
        _clinicStats = finalStats;
        _isLoading = false;
        _isInitialLoad = false;
        _isPaginationLoading = false; // Clear pagination loading
      });
      
      print('✅ Loaded ${clinics.length} clinics on page $_currentPage of $_totalPages (total: $totalClinics)');
    } catch (e) {
      print('❌ Error loading clinics: $e');
      
      // Fallback to mock data if Firebase fails
      final mockClinics = _getMockClinics();
      setState(() {
        _clinics = mockClinics.take(_itemsPerPage).toList();
        _totalClinics = mockClinics.length;
        _totalPages = (mockClinics.length / _itemsPerPage).ceil();
        _clinicStats = {
          'total': mockClinics.length,
          'pending': mockClinics.where((c) => c.status == ClinicStatus.pending).length,
          'approved': mockClinics.where((c) => c.status == ClinicStatus.approved).length,
          'rejected': mockClinics.where((c) => c.status == ClinicStatus.rejected).length,
          'suspended': mockClinics.where((c) => c.status == ClinicStatus.suspended).length,
        };
        _isLoading = false;
        _isInitialLoad = false;
        _isPaginationLoading = false; // Clear pagination loading on error
      });
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load clinics from database. Showing sample data.'),
            backgroundColor: AppColors.warning,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }
  

  
  /// Fallback mock data
  List<ClinicRegistration> _getMockClinics() {
    return [
      ClinicRegistration(
        id: '1',
        clinicName: 'Happy Paws Veterinary Clinic',
        adminName: 'Dr. John Smith',
        adminId: 'admin1',
        email: 'info@happypaws.com',
        phone: '+1234567890',
        address: '123 Main Street, City, State',
        licenseNumber: 'VET-2024-001',
        status: ClinicStatus.pending,
        applicationDate: DateTime.now().subtract(Duration(days: 3)),
      ),
      ClinicRegistration(
        id: '2',
        clinicName: 'Animal Care Center',
        adminName: 'Dr. Jane Doe',
        adminId: 'admin2',
        email: 'contact@animalcare.com',
        phone: '+1234567891',
        address: '456 Oak Avenue, City, State',
        licenseNumber: 'VET-2024-002',
        status: ClinicStatus.approved,
        applicationDate: DateTime.now().subtract(Duration(days: 15)),
      ),
      ClinicRegistration(
        id: '3',
        clinicName: 'Pet Health Clinic',
        adminName: 'Dr. Mike Johnson',
        adminId: 'admin3',
        email: 'admin@pethealth.com',
        phone: '+1234567892',
        address: '789 Pine Road, City, State',
        licenseNumber: 'VET-2024-003',
        status: ClinicStatus.rejected,
        applicationDate: DateTime.now().subtract(Duration(days: 7)),
      ),
    ];
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _currentPage = 1; // Reset to first page
    });
    _saveState(); // Save state when search changes
    
    // Debounce search to avoid excessive API calls
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      _loadClinics(); // Reload with new search after debounce (will clear cache)
    });
  }

  void _onStatusFilterChanged(String status) {
    setState(() {
      _selectedStatus = status;
      _currentPage = 1; // Reset to first page
    });
    _saveState(); // Save state when filter changes
    _loadClinics(); // Reload with new filter immediately (will clear cache)
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    _saveState(); // Save state when page changes
    _loadClinics(isPagination: true); // Load new page data from server with pagination flag
  }

  /// Map a [ClinicStatus] enum to the key name used in [_clinicStats]
  String _statusKey(ClinicStatus status) {
    return status.toString().split('.').last; // e.g. ClinicStatus.pending -> 'pending'
  }

  /// Update local [_clinicStats] to reflect a status change for [clinic].
  /// This updates the counts immediately for a snappy UI while we still call
  /// `_loadClinics()` to re-sync with the backend.
  void _updateLocalClinicStatsForStatusChange(ClinicRegistration clinic, ClinicStatus newStatus) {
    final oldStatus = clinic.status;
    if (oldStatus == newStatus) return;

    final oldKey = _statusKey(oldStatus);
    final newKey = _statusKey(newStatus);

    setState(() {
      // Safely decrement the old status count (don't go below 0)
      final oldCount = _clinicStats[oldKey] ?? _clinics.where((c) => c.status == oldStatus).length;
      _clinicStats[oldKey] = (oldCount > 0) ? oldCount - 1 : 0;

      // Increment the new status count
      final newCount = _clinicStats[newKey] ?? 0;
      _clinicStats[newKey] = newCount + 1;
    });
  }

  void _onViewDetails(ClinicRegistration clinic) {
    // TODO: Show clinic details dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('View details for ${clinic.clinicName}')),
    );
  }

  Future<void> _onUpdateClinic(ClinicRegistration updatedClinic) async {
    try {
      // Call the SuperAdminService to update the clinic in Firestore
      final success = await SuperAdminService.updateClinic(updatedClinic);
      
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${updatedClinic.clinicName} updated successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        }
        
        // Update local list and cache
        setState(() {
          final index = _clinics.indexWhere((c) => c.id == updatedClinic.id);
          if (index != -1) {
            _clinics[index] = updatedClinic;
          }
        });
        
        // Update cache without reloading
        _cacheService.updateClinicInCache(updatedClinic);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update ${updatedClinic.clinicName}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating clinic: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _onApprove(ClinicRegistration clinic) async {
    final isReapproval = clinic.status == ClinicStatus.suspended;
    final actionText = isReapproval ? 'Re-approve' : 'Approve';
    final messageText = isReapproval 
        ? 'Are you sure you want to re-approve ${clinic.clinicName}? This will restore their access.'
        : 'Are you sure you want to approve ${clinic.clinicName}?';
        
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$actionText Clinic'),
        content: Text(messageText),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: AppColors.white,
            ),
            child: Text(actionText),
          ),
        ],
      ),
    );
    
    if (result == true) {
      try {
        final isReapproval = clinic.status == ClinicStatus.suspended;
        final success = await SuperAdminService.updateClinicStatus(
          clinic.id,
          ClinicStatus.approved,
        );
        
        if (success) {
          // Update local summary counts immediately for snappy UI
          _updateLocalClinicStatsForStatusChange(clinic, ClinicStatus.approved);

          final successMessage = isReapproval 
              ? '${clinic.clinicName} re-approved successfully'
              : '${clinic.clinicName} approved successfully';
              
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(successMessage),
              backgroundColor: AppColors.success,
            ),
          );
          
          // Update the local clinic item
          final updatedClinic = clinic.copyWith(
            status: ClinicStatus.approved,
            approvedDate: DateTime.now(),
            rejectionReason: null,
            suspensionReason: null,
          );
          
          setState(() {
            final idx = _clinics.indexWhere((c) => c.id == clinic.id);
            if (idx != -1) {
              _clinics[idx] = updatedClinic;
            }
          });
          
          // Update cache without full reload
          _cacheService.updateClinicInCache(updatedClinic);
        } else {
          throw Exception('Failed to approve clinic');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to approve clinic: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _onReject(ClinicRegistration clinic) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        final reasonController = TextEditingController();
        return AlertDialog(
          title: Text('Reject Clinic'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Are you sure you want to reject ${clinic.clinicName}?'),
              SizedBox(height: 16),
              Text('Reason for rejection:'),
              SizedBox(height: 8),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Enter reason for rejection...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, {
                'confirmed': true,
                'reason': reasonController.text.trim().isNotEmpty 
                    ? reasonController.text.trim() 
                    : 'Rejected by admin',
              }),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.white,
              ),
              child: Text('Reject'),
            ),
          ],
        );
      },
    );
    
    if (result != null && result['confirmed'] == true) {
      try {
        final success = await SuperAdminService.updateClinicStatus(
          clinic.id, 
          ClinicStatus.rejected,
          reason: result['reason'],
        );
        
        if (success) {
          // Update local summary counts immediately for snappy UI
          _updateLocalClinicStatsForStatusChange(clinic, ClinicStatus.rejected);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${clinic.clinicName} rejected'),
              backgroundColor: AppColors.error,
            ),
          );
          
          // Update the local clinic item
          final updatedClinic = clinic.copyWith(
            status: ClinicStatus.rejected,
            approvedDate: null,
            rejectionReason: result['reason'] ?? 'Rejected by admin',
            suspensionReason: null,
          );
          
          setState(() {
            final idx = _clinics.indexWhere((c) => c.id == clinic.id);
            if (idx != -1) {
              _clinics[idx] = updatedClinic;
            }
          });
          
          // Update cache without full reload
          _cacheService.updateClinicInCache(updatedClinic);
        } else {
          throw Exception('Failed to reject clinic');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reject clinic: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _onSuspend(ClinicRegistration clinic) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        final reasonController = TextEditingController();
        return AlertDialog(
          title: Text('Suspend Clinic'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Are you sure you want to suspend ${clinic.clinicName}?'),
              SizedBox(height: 16),
              Text('Reason for suspension:'),
              SizedBox(height: 8),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Enter reason for suspension...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, {
                'confirmed': true,
                'reason': reasonController.text.trim().isNotEmpty 
                    ? reasonController.text.trim() 
                    : 'Suspended by admin',
              }),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
                foregroundColor: AppColors.white,
              ),
              child: Text('Suspend'),
            ),
          ],
        );
      },
    );
    
    if (result != null && result['confirmed'] == true) {
      try {
        final success = await SuperAdminService.updateClinicStatus(
          clinic.id, 
          ClinicStatus.suspended,
          reason: result['reason'],
        );
        
        if (success) {
          // Update local summary counts immediately for snappy UI
          _updateLocalClinicStatsForStatusChange(clinic, ClinicStatus.suspended);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${clinic.clinicName} suspended'),
              backgroundColor: AppColors.warning,
            ),
          );
          
          // Update the local clinic item
          final updatedClinic = clinic.copyWith(
            status: ClinicStatus.suspended,
            approvedDate: null,
            rejectionReason: null,
            suspensionReason: result['reason'] ?? 'Suspended by admin',
          );
          
          setState(() {
            final idx = _clinics.indexWhere((c) => c.id == clinic.id);
            if (idx != -1) {
              _clinics[idx] = updatedClinic;
            }
          });
          
          // Update cache without full reload
          _cacheService.updateClinicInCache(updatedClinic);
        } else {
          throw Exception('Failed to suspend clinic');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to suspend clinic: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(kSpacingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header
            PageHeader(
              title: 'Clinic Management',
              subtitle: 'Manage and approve clinic registrations',
            ),
            
            SizedBox(height: kSpacingLarge),
            
            // Summary Cards
            Builder(
              builder: (context) {
                final totalClinics = _clinicStats['total'] ?? _clinics.length;
                final pendingClinics = _clinicStats['pending'] ?? _clinics.where((c) => c.status == ClinicStatus.pending).length;
                final approvedClinics = _clinicStats['approved'] ?? _clinics.where((c) => c.status == ClinicStatus.approved).length;
                final rejectedClinics = _clinicStats['rejected'] ?? _clinics.where((c) => c.status == ClinicStatus.rejected).length;
                final suspendedClinics = _clinicStats['suspended'] ?? _clinics.where((c) => c.status == ClinicStatus.suspended).length;
      
                return ClinicSummaryCards(
                  totalClinics: totalClinics,
                  pendingClinics: pendingClinics,
                  approvedClinics: approvedClinics,
                  rejectedClinics: rejectedClinics,
                  suspendedClinics: suspendedClinics,
                );
              },
            ),
            
            SizedBox(height: kSpacingLarge),
            
            // Search and Filters
            ClinicSearchAndFilter(
              searchQuery: _searchQuery,
              selectedStatus: _selectedStatus,
              onSearchChanged: _onSearchChanged,
              onStatusChanged: _onStatusFilterChanged,
              onExportData: () {
                // TODO: Implement export functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Export functionality coming soon')),
                );
              },
            ),
            
            SizedBox(height: kSpacingLarge),
            
            // Clinics List with pagination loading overlay
            Stack(
              children: [
                ClinicsList(
                  clinics: _clinics,
                  totalClinics: _totalClinics,
                  isLoading: _isLoading,
                  onViewDetails: _onViewDetails,
                  onApprove: _onApprove,
                  onReject: _onReject,
                  onSuspend: _onSuspend,
                  onUpdateClinic: _onUpdateClinic,
                ),
                
                // Show loading overlay during pagination
                if (_isPaginationLoading)
                  Positioned.fill(
                    child: Container(
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
                                'Loading page $_currentPage...',
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
            
            if (!_isLoading && _clinics.isNotEmpty) ...[
              SizedBox(height: kSpacingLarge),
              
              // Pagination with loading state
              PaginationWidget(
                currentPage: _currentPage,
                totalPages: _totalPages,
                totalItems: _totalClinics,
                onPageChanged: _onPageChanged,
                isLoading: _isPaginationLoading,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
