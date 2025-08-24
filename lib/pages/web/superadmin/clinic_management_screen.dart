import 'package:flutter/material.dart';
import 'package:pawsense/core/models/clinic_registration_model.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';
import 'package:pawsense/core/widgets/shared/page_header.dart';
import '../../../core/widgets/super_admin/clinic_management/clinic_summary_cards.dart';
import '../../../core/widgets/super_admin/clinic_management/clinic_search_and_filter.dart';
import '../../../core/widgets/super_admin/clinic_management/clinics_list.dart';
import '../../../core/widgets/shared/pagination_widget.dart';
import '../../../core/services/super_admin/super_admin_service.dart';

class ClinicManagementScreen extends StatefulWidget {
  const ClinicManagementScreen({Key? key}) : super(key: key);

  @override
  State<ClinicManagementScreen> createState() => _ClinicManagementScreenState();
}

class _ClinicManagementScreenState extends State<ClinicManagementScreen> {
  List<ClinicRegistration> _clinics = [];
  bool _isLoading = true;
  Map<String, int> _clinicStats = {};
  
  // Pagination - fixed at 5 items per page
  int _currentPage = 1;
  int _totalClinics = 0;
  int _totalPages = 0;
  final int _itemsPerPage = 5; // Fixed at 5 items per page
  
  // Filters
  String _searchQuery = '';
  String _selectedStatus = ''; // Start with empty string to match "All Status" behavior

  @override
  void initState() {
    super.initState();
    _loadClinics();
  }

  Future<void> _loadClinics() async {
    setState(() => _isLoading = true);
    
    try {
      print('Loading paginated clinics from Firestore...');
      print('Selected Status: "$_selectedStatus"');
      
      // Convert filter strings to API format
      String? statusFilter;
      if (_selectedStatus.isNotEmpty && _selectedStatus != 'All Status') {
        statusFilter = _selectedStatus.toLowerCase();
      }
      
      print('Filters - Status: $statusFilter, Search: $_searchQuery');
      
      // Load paginated data from Firestore
      final result = await SuperAdminService.getPaginatedClinicRegistrations(
        page: _currentPage,
        itemsPerPage: _itemsPerPage,
        statusFilter: statusFilter,
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
      );
      
      // Load clinic statistics
      final stats = await SuperAdminService.getClinicStatistics();
      
      setState(() {
        _clinics = result['clinics'] as List<ClinicRegistration>;
        _totalClinics = result['totalClinics'] as int;
        _totalPages = result['totalPages'] as int;
        _currentPage = result['currentPage'] as int;
        _clinicStats = stats;
        _isLoading = false;
      });
      
      print('Loaded ${_clinics.length} clinics for page $_currentPage of $_totalPages (Total: $_totalClinics)');
    } catch (e) {
      print('Error loading clinics: $e');
      
      // Fallback to mock data if Firebase fails
      setState(() {
        _clinics = _getMockClinics().take(_itemsPerPage).toList();
        _totalClinics = _getMockClinics().length;
        _totalPages = (_totalClinics / _itemsPerPage).ceil();
        _clinicStats = {
          'total': _totalClinics,
          'pending': _getMockClinics().where((c) => c.status == ClinicStatus.pending).length,
          'approved': _getMockClinics().where((c) => c.status == ClinicStatus.approved).length,
          'rejected': _getMockClinics().where((c) => c.status == ClinicStatus.rejected).length,
          'suspended': _getMockClinics().where((c) => c.status == ClinicStatus.suspended).length,
        };
        _isLoading = false;
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
    _loadClinics(); // Reload with new search
  }

  void _onStatusFilterChanged(String status) {
    setState(() {
      _selectedStatus = status;
      _currentPage = 1; // Reset to first page
    });
    _loadClinics(); // Reload with new filter
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    _loadClinics(); // Load new page
  }

  void _onViewDetails(ClinicRegistration clinic) {
    // TODO: Show clinic details dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('View details for ${clinic.clinicName}')),
    );
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
          final successMessage = isReapproval 
              ? '${clinic.clinicName} re-approved successfully'
              : '${clinic.clinicName} approved successfully';
              
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(successMessage),
              backgroundColor: AppColors.success,
            ),
          );
          _loadClinics(); // Reload to get updated data
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${clinic.clinicName} rejected'),
              backgroundColor: AppColors.error,
            ),
          );
          _loadClinics(); // Reload to get updated data
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${clinic.clinicName} suspended'),
              backgroundColor: AppColors.warning,
            ),
          );
          _loadClinics(); // Reload to get updated data
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
            ClinicSummaryCards(
              totalClinics: _clinicStats['total'] ?? _clinics.length,
              pendingClinics: _clinicStats['pending'] ?? _clinics.where((c) => c.status == ClinicStatus.pending).length,
              approvedClinics: _clinicStats['approved'] ?? _clinics.where((c) => c.status == ClinicStatus.approved).length,
              rejectedClinics: _clinicStats['rejected'] ?? _clinics.where((c) => c.status == ClinicStatus.rejected).length,
              suspendedClinics: _clinicStats['suspended'] ?? _clinics.where((c) => c.status == ClinicStatus.suspended).length,
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
            
            // Clinics List
            ClinicsList(
              clinics: _clinics,
              totalClinics: _totalClinics,
              isLoading: _isLoading,
              onViewDetails: _onViewDetails,
              onApprove: _onApprove,
              onReject: _onReject,
              onSuspend: _onSuspend,
            ),
            
            if (!_isLoading && _clinics.isNotEmpty) ...[
              SizedBox(height: kSpacingLarge),
              
              // Pagination
              PaginationWidget(
                currentPage: _currentPage,
                totalPages: _totalPages,
                totalItems: _totalClinics,
                onPageChanged: _onPageChanged,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
