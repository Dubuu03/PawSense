import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pawsense/core/services/auth/auth_service.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/config/app_router.dart';
import 'package:pawsense/core/services/optimization/role_manager.dart';
import 'side_navigation.dart';
import 'top_nav_bar.dart';

class AdminShell extends StatefulWidget {
  final Widget child;
  
  const AdminShell({
    super.key,
    required this.child,
  });

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  String _userRole = 'admin';
  bool _isLoading = true;
  String _userName = 'User';
  String _userInitials = 'U';
  String _clinicName = 'Veterinary Clinic';
  String? _userEmail;
  String? _userPhone;
  String? _userFullName;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    try {
      final authService = AuthService();
      
      // Make a single call to get current user first
      final currentUser = await authService.getCurrentUser();
      
      if (currentUser == null) {
        // Redirect to login if no user
        if (mounted) {
          context.go('/web_login');
          return;
        }
      }
      
      // Check roles based on the user data we already have
      final userRole = currentUser!.role;
      final hasAdminPrivileges = ['admin', 'super_admin'].contains(userRole);
      
      if (!hasAdminPrivileges) {
        // Redirect to login if no admin privileges
        if (mounted) {
          context.go('/web_login');
          return;
        }
      }
      
      if (mounted) {
        setState(() {
          _userRole = userRole == 'super_admin' ? 'super_admin' : 'admin';
          _userName = currentUser.username;
          _userInitials = _generateInitials(currentUser.username);
          _userEmail = currentUser.email;
          _userPhone = currentUser.contactNumber;
          
          // Build full name from first and last name if available
          if (currentUser.firstName != null && currentUser.lastName != null) {
            _userFullName = '${currentUser.firstName} ${currentUser.lastName}';
          } else {
            _userFullName = currentUser.username;
          }
          
          _isLoading = false;
        });

        // Load clinic information for admin users
        if (_userRole == 'admin') {
          await _loadClinicInfo();
        }

        // Redirect to appropriate dashboard if on wrong role path
        _redirectIfNeeded();
      }
    } catch (e) {
      if (mounted) {
        context.go('/web_login');
      }
    }
  }

  Future<void> _loadClinicInfo() async {
    try {
      final authService = AuthService();
      final clinic = await authService.getUserClinic();
      
      if (clinic != null && mounted) {
        setState(() {
          _clinicName = clinic.clinicName;
        });
        print('✅ Loaded clinic info: ${clinic.clinicName}');
      } else {
        print('⚠️ No clinic found for admin user');
      }
    } catch (e) {
      print('❌ Error loading clinic info: $e');
      // Keep default clinic name if error occurs
    }
  }

  void _redirectIfNeeded() {
    final currentLocation = GoRouterState.of(context).uri.path;
    
    // Only redirect if user is on a completely wrong path
    // Don't redirect if they're already on a valid path for their role
    if (_userRole == 'super_admin' && currentLocation.startsWith('/admin/')) {
      // Super admin trying to access admin routes - redirect to super admin system analytics
      if (currentLocation != '/super-admin/system-analytics') {
        context.go('/super-admin/system-analytics');
      }
    } else if (_userRole == 'admin' && currentLocation.startsWith('/super-admin/')) {
      // Admin trying to access super admin routes - redirect to admin dashboard
      if (currentLocation != '/admin/dashboard') {
        context.go('/admin/dashboard');
      }
    } else if (currentLocation == '/admin' || currentLocation == '/super-admin') {
      // On root admin path - redirect to appropriate dashboard
      final dashboardPath = _userRole == 'super_admin' ? '/super-admin/system-analytics' : '/admin/dashboard';
      if (currentLocation != dashboardPath) {
        context.go(dashboardPath);
      }
    }
  }

  int _getCurrentIndex() {
    final currentLocation = GoRouterState.of(context).uri.path;
    final routes = AppRouter.getRoutesForRole(_userRole);
    
    for (int i = 0; i < routes.length; i++) {
      final routePath = routes[i].path;
      
      // Check for exact match first
      if (routePath == currentLocation) {
        return i;
      }
      
      // Check if current location starts with the route path (for parameterized routes)
      // For example: '/admin/messaging' should match '/admin/messaging/conversationId'
      if (currentLocation.startsWith('$routePath/') || currentLocation.startsWith(routePath)) {
        return i;
      }
    }
    return 0; // Default to first item (dashboard)
  }

  void _onNavItemSelected(int index) {
    final routes = AppRouter.getRoutesForRole(_userRole);
    if (index >= 0 && index < routes.length) {
      final targetPath = routes[index].path;
      final currentLocation = GoRouterState.of(context).uri.path;
      
      // Only navigate if we're not already on the target path
      if (currentLocation != targetPath) {
        context.go(targetPath);
      }
    }
  }

  String _generateInitials(String name) {
    if (name.isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  Future<void> _handleSignOut() async {
    try {
      final authService = AuthService();
      await authService.signOut();
      if (mounted) {
        context.go('/web_login');
      }
    } catch (e) {
      // Handle sign out error
      if (mounted) {
        context.go('/web_login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          SideNavigation(
            key: ValueKey(_userRole), // Prevent unnecessary rebuilds
            selectedIndex: _getCurrentIndex(),
            onItemSelected: _onNavItemSelected,
            userRole: _userRole,
            adminName: _userFullName,
            adminEmail: _userEmail,
            adminPhone: _userPhone,
          ),
          Expanded(
            child: Column(
              children: [
                TopNavBar(
                  key: ValueKey('topnav_$_userRole'), // Prevent unnecessary rebuilds
                  clinicTitle: _userRole == 'super_admin' 
                      ? 'Super Administrator Dashboard'
                      : _clinicName.isNotEmpty 
                          ? _clinicName
                          : 'Veterinary Clinic Dashboard',
                  userInitials: _userInitials,
                  userName: _userName,
                  userRole: _userRole, // Use actual role, not display name
                  userRoleDisplay: RoleManager.getRoleDisplayName(_userRole), // Add display name separately
                  onSignOut: _handleSignOut,
                ),
                Expanded(
                  child: PageStorage(
                    bucket: PageStorageBucket(),
                    child: Container(
                      color: AppColors.background,
                      child: widget.child,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

