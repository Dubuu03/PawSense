import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pawsense/core/utils/file_downloader.dart' as file_downloader;
import 'package:pawsense/core/models/user/user_model.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';
import 'package:pawsense/core/widgets/shared/page_header.dart';
import '../../../core/widgets/super_admin/user_management/user_summary_cards.dart';
import '../../../core/widgets/super_admin/user_management/user_search_and_filter.dart';
import '../../../core/widgets/super_admin/user_management/users_list.dart';
import '../../../core/widgets/shared/pagination_widget.dart';
import '../../../core/services/super_admin/super_admin_service.dart';
import '../../../core/services/super_admin/user_cache_service.dart';
import '../../../core/services/super_admin/screen_state_service.dart';
import '../../../core/widgets/super_admin/user_management/add_user_modal.dart';
import '../../../core/services/super_admin/user_pdf_service.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({Key? key}) : super(key: key ?? const PageStorageKey('user_management'));

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> _usersWithStatus = [];
  bool _isLoading = true;
  bool _isInitialLoad = true;
  bool _isPaginationLoading = false; // Separate loading state for pagination
  Map<String, int> _userStats = {};
  
  // Pagination
  int _currentPage = 1;
  final int _itemsPerPage = 5; // Changed to 5 items per page
  int _totalUsers = 0;
  int _totalPages = 0;
  
  // Filters
  String _searchQuery = '';
  String _selectedRole = 'All Roles';
  String _selectedStatus = 'All Status';
  
  // Services
  final _cacheService = UserCacheService();
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
    _loadUsers();
  }
  
  @override
  void dispose() {
    _saveState();
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// Restore state from ScreenStateService
  void _restoreState() {
    _currentPage = _stateService.userCurrentPage;
    _searchQuery = _stateService.userSearchQuery;
    _selectedRole = _stateService.userSelectedRole;
    _selectedStatus = _stateService.userSelectedStatus;
    print('🔄 Restored user management state: page=$_currentPage, role="$_selectedRole", status="$_selectedStatus", search="$_searchQuery"');
  }

  /// Save current state to ScreenStateService
  void _saveState() {
    _stateService.saveUserState(
      currentPage: _currentPage,
      searchQuery: _searchQuery,
      selectedRole: _selectedRole,
      selectedStatus: _selectedStatus,
    );
  }

  Future<void> _loadUsers({bool forceRefresh = false, bool isPagination = false}) async {
    // Check if filters changed (clear cache if so)
    final filtersChanged = _cacheService.hasFiltersChanged(
      _selectedRole,
      _selectedStatus,
      _searchQuery,
    );
    if (filtersChanged && !_isInitialLoad) {
      _cacheService.invalidateCacheForFilterChange();
    }
    
    // Try to load from multi-page cache first
    if (!forceRefresh && !_isInitialLoad) {
      final cachedPage = _cacheService.getCachedPage(
        roleFilter: _selectedRole,
        statusFilter: _selectedStatus,
        searchQuery: _searchQuery,
        page: _currentPage,
      );
      
      if (cachedPage != null) {
        print('📦 Using cached user page data - no network call needed');
        setState(() {
          _usersWithStatus = cachedPage.usersWithStatus;
          _totalUsers = cachedPage.totalUsers;
          _totalPages = cachedPage.totalPages;
          _isPaginationLoading = false;
        });
        
        // Load stats from cache if available
        final cachedStats = _cacheService.cachedStats;
        if (cachedStats != null) {
          setState(() {
            _userStats = cachedStats;
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
      // Convert filter strings to API format
      String? roleFilter;
      if (_selectedRole != 'All Roles' && _selectedRole.isNotEmpty) {
        roleFilter = _selectedRole.toLowerCase().replaceAll(' ', '_');
      }
      
      String? statusFilter;
      if (_selectedStatus != 'All Status' && _selectedStatus.isNotEmpty) {
        if (_selectedStatus == 'Active') {
          statusFilter = 'active';
        } else if (_selectedStatus == 'Suspended') statusFilter = 'suspended';
      }
      
      // Fetch statistics and paginated users in parallel for better performance
      final results = await Future.wait([
        SuperAdminService.getUserStatistics(),
        SuperAdminService.getPaginatedUsersWithStatus(
          page: _currentPage,
          itemsPerPage: _itemsPerPage,
          roleFilter: roleFilter,
          statusFilter: statusFilter,
          searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
        ),
      ]);
      
      final stats = results[0] as Map<String, int>;
      final result = results[1];
      
      final usersWithStatus = result['users'] as List<Map<String, dynamic>>;
      final totalUsers = result['totalUsers'] as int;
      final totalPages = result['totalPages'] as int;
      final currentPage = result['currentPage'] as int;
      
      // Update cache with current page data
      _cacheService.updateCache(
        usersWithStatus: usersWithStatus,
        totalUsers: totalUsers,
        totalPages: totalPages,
        stats: stats,
        roleFilter: _selectedRole,
        statusFilter: _selectedStatus,
        searchQuery: _searchQuery,
        page: _currentPage,
      );
      
      setState(() {
        _usersWithStatus = usersWithStatus;
        _totalUsers = totalUsers;
        _totalPages = totalPages;
        _currentPage = currentPage;
        _userStats = stats;
        _isLoading = false;
        _isInitialLoad = false;
        _isPaginationLoading = false; // Clear pagination loading
      });
      
      print('✅ Loaded ${usersWithStatus.length} users on page $_currentPage of $_totalPages (total: $totalUsers)');
    } catch (e) {
      print('Error loading users: $e');
      
      // Fallback to mock data if Firebase fails
      setState(() {
        _usersWithStatus = _getMockUsersWithStatus().take(_itemsPerPage).toList();
        _totalUsers = _getMockUsersWithStatus().length;
        _totalPages = (_totalUsers / _itemsPerPage).ceil();
        _userStats = {
          'total': _totalUsers,
          'active': _getMockUsersWithStatus().where((u) => u['isActive'] == true).length,
          'suspended': _getMockUsersWithStatus().where((u) => u['isActive'] == false).length,
          'admins': _getMockUsersWithStatus().where((u) => (u['user'] as UserModel).role == 'admin').length,
          'users': _getMockUsersWithStatus().where((u) => (u['user'] as UserModel).role == 'user').length,
        };
        _isLoading = false;
        _isInitialLoad = false;
        _isPaginationLoading = false; // Clear pagination loading on error
      });
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load users from database. Showing sample data.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
  
  /// Fallback mock data with suspension status
  List<Map<String, dynamic>> _getMockUsersWithStatus() {
    final mockUsers = [
      UserModel(
        uid: '1',
        username: 'johndoe',
        firstName: 'John',
        lastName: 'Doe',
        email: 'john.doe@example.com',
        role: 'user',
        profileImageUrl: '',
        createdAt: DateTime.now().subtract(Duration(days: 30)),
      ),
      UserModel(
        uid: '2',
        username: 'janesmith',
        firstName: 'Jane',
        lastName: 'Smith',
        email: 'jane.smith@example.com',
        role: 'admin',
        profileImageUrl: '',
        createdAt: DateTime.now().subtract(Duration(days: 15)),
      ),
      UserModel(
        uid: '3',
        username: 'bobjohnson',
        firstName: 'Bob',
        lastName: 'Johnson',
        email: 'bob.johnson@example.com',
        role: 'user',
        profileImageUrl: '',
        createdAt: DateTime.now().subtract(Duration(days: 7)),
      ),
    ];
    
    return mockUsers.map((user) => {
      'user': user,
      'isActive': true, // All mock users are active by default
      'suspensionReason': null,
    }).toList();
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
      _loadUsers(); // Reload with new search after debounce (will clear cache)
    });
  }

  void _onRoleFilterChanged(String? role) {
    setState(() {
      _selectedRole = role ?? '';
      _currentPage = 1; // Reset to first page
    });
    _saveState(); // Save state when role filter changes
    _loadUsers(); // Reload with new filter immediately (will clear cache)
  }

  void _onStatusFilterChanged(String? status) {
    setState(() {
      _selectedStatus = status ?? '';
      _currentPage = 1; // Reset to first page
    });
    _saveState(); // Save state when status filter changes
    _loadUsers(); // Reload with new filter immediately (will clear cache)
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    _saveState(); // Save state when page changes
    _loadUsers(isPagination: true); // Load new page data from server with pagination flag
  }

  void _onEditUser(UserModel user) {
    final fullName = '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit user: $fullName')),
    );
  }

  Future<void> _onUpdateUser(UserModel updatedUser) async {
    try {
      // Call the SuperAdminService to update the user in Firestore
      final success = await SuperAdminService.updateUser(updatedUser);
      
      if (success) {
        final fullName = '${updatedUser.firstName ?? ''} ${updatedUser.lastName ?? ''}'.trim();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('User $fullName updated successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        }
        
        // Reload users to get updated data
        _loadUsers();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update user'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update user: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _onToggleUserStatus(UserModel user) async {
    // Find current status from our data
    final userWithStatus = _usersWithStatus.firstWhere(
      (u) => (u['user'] as UserModel).uid == user.uid,
      orElse: () => {'user': user, 'isActive': true, 'suspensionReason': null},
    );
    
    final currentStatus = userWithStatus['isActive'] as bool;
    final newStatus = !currentStatus;
    
    if (!newStatus) {
      // Suspending user - show reason dialog
      await _showSuspendDialog(user);
    } else {
      // Activating user
      await _activateUser(user);
    }
  }

  Future<void> _showSuspendDialog(UserModel user) async {
    final reasonController = TextEditingController();
    final fullName = '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Suspend User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to suspend $fullName?'),
            SizedBox(height: kSpacingMedium),
            Text(
              'Reason for suspension:',
              style: kTextStyleSmall.copyWith(fontWeight: FontWeight.w500),
            ),
            SizedBox(height: kSpacingSmall),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                hintText: 'Enter reason for suspension...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(kSpacingMedium),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isNotEmpty) {
                Navigator.pop(context, true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Please provide a reason for suspension'),
                    backgroundColor: AppColors.warning,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: AppColors.white,
            ),
            child: Text('Suspend'),
          ),
        ],
      ),
    );
    
    if (result == true && reasonController.text.trim().isNotEmpty) {
      await _suspendUser(user, reasonController.text.trim());
    }
  }

  Future<void> _suspendUser(UserModel user, String reason) async {
    final fullName = '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim();
    
    try {
      final success = await SuperAdminService.suspendUser(user.uid, reason);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User $fullName suspended successfully'),
            backgroundColor: AppColors.warning,
          ),
        );
        
        // Reload users to get updated data
        _loadUsers();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to suspend user'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to suspend user: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _activateUser(UserModel user) async {
    final fullName = '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim();
    
    try {
      final success = await SuperAdminService.activateUser(user.uid);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User $fullName activated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        
        // Reload users to get updated data
        _loadUsers();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to activate user'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to activate user: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _showAddUserModal() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AddUserModal(
        onCreateUser: (newUser) {
          // Handle the new user creation
          _handleNewUserCreation(newUser);
        },
      ),
    );
  }

  Future<void> _handleNewUserCreation(UserModel newUser) async {
    try {
      // In a real implementation, this would call the SuperAdminService
      // to create the user in the database
      // final success = await SuperAdminService.createUser(newUser);
      
      // For now, show success message and reload users
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User ${newUser.firstName} ${newUser.lastName} created successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
      
      // Reload users to refresh the list
      _loadUsers();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create user: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleExportCSV() async {
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
      // Convert filter strings to API format
      String? roleFilter;
      if (_selectedRole != 'All Roles' && _selectedRole.isNotEmpty) {
        roleFilter = _selectedRole.toLowerCase().replaceAll(' ', '_');
      }
      
      String? statusFilter;
      if (_selectedStatus != 'All Status' && _selectedStatus.isNotEmpty) {
        if (_selectedStatus == 'Active') {
          statusFilter = 'active';
        } else if (_selectedStatus == 'Suspended') statusFilter = 'suspended';
      }

      // Fetch ALL filtered users (not just current page)
      final result = await SuperAdminService.getPaginatedUsersWithStatus(
        page: 1,
        itemsPerPage: 999999, // Get all matching records
        roleFilter: roleFilter,
        statusFilter: statusFilter,
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      final allFilteredUsers = result['users'] as List<Map<String, dynamic>>;

      if (allFilteredUsers.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No users to export'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Get current admin name
      String? adminName = 'Super Admin';

      // Generate PDF
      final Uint8List pdfBytes = await UserPdfService.generateUserReport(
        usersWithStatus: allFilteredUsers,
        roleFilter: _selectedRole != 'All Roles' ? _selectedRole : null,
        statusFilter: _selectedStatus != 'All Status' ? _selectedStatus : null,
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
        generatedBy: adminName,
      );

      // Download PDF
      final fileName = 'user_report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      file_downloader.downloadFile(fileName, pdfBytes);

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ PDF report generated with ${allFilteredUsers.length} users'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      print('📊 Exported ${allFilteredUsers.length} users to PDF');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      print('❌ Error generating PDF: $e');
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
              title: 'User Management',
              subtitle: 'Manage and monitor all users in the system',
              // actions: [
              //   ElevatedButton.icon(
              //     onPressed: _showAddUserModal,
              //     icon: const Icon(Icons.person_add, size: kIconSizeMedium),
              //     label: const Text('Add User'),
              //     style: ElevatedButton.styleFrom(
              //       backgroundColor: AppColors.primary,
              //       foregroundColor: AppColors.white,
              //       padding: const EdgeInsets.symmetric(horizontal: kSpacingMedium, vertical: kSpacingSmall),
              //       shape: RoundedRectangleBorder(
              //         borderRadius: BorderRadius.circular(8),
              //       ),
              //     ),
              //   ),
              // ],
            ),
            
            SizedBox(height: kSpacingLarge),
            
            // Summary Cards
            UserSummaryCards(
              totalUsers: _userStats['total'] ?? _usersWithStatus.length,
              activeUsers: _userStats['active'] ?? _usersWithStatus.where((u) => u['isActive'] == true).length,
              inactiveUsers: _userStats['suspended'] ?? _usersWithStatus.where((u) => u['isActive'] == false).length,
              adminUsers: _userStats['admins'] ?? _usersWithStatus.where((u) {
                final user = u['user'] as UserModel;
                return user.role == 'admin';
              }).length,
            ),
            
            SizedBox(height: kSpacingLarge),
            
            // Search and Filters
            UserSearchAndFilter(
              searchQuery: _searchQuery,
              selectedRole: _selectedRole,
              selectedStatus: _selectedStatus,
              onSearchChanged: _onSearchChanged,
              onRoleChanged: _onRoleFilterChanged,
              onStatusChanged: _onStatusFilterChanged,
              onExportData: _handleExportCSV,
            ),
            
            SizedBox(height: kSpacingLarge),
            
            // Users List with pagination loading overlay
            Stack(
              children: [
                UsersList(
                  users: _usersWithStatus,
                  isLoading: _isLoading,
                  totalUsers: _totalUsers,
                  onEditUser: _onEditUser,
                  onStatusToggle: (user, status) => _onToggleUserStatus(user),
                  onUpdateUser: _onUpdateUser,
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
            
            if (!_isLoading && _totalUsers > 0) ...[
              SizedBox(height: kSpacingLarge),
              
              // Pagination with loading state
              PaginationWidget(
                currentPage: _currentPage,
                totalPages: _totalPages,
                totalItems: _totalUsers,
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
