import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';
import 'package:pawsense/core/config/app_router.dart';
import 'package:pawsense/core/services/admin/schedule_setup_guard.dart';
import 'package:go_router/go_router.dart';
import 'nav_item.dart';

class SideNavigation extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final String userRole; // Add user role parameter

  // Admin contact details
  final String? adminName;
  final String? adminEmail;
  final String? adminPhone;

  const SideNavigation({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    this.userRole = 'admin', // Default to admin role
    this.adminName,
    this.adminEmail,
    this.adminPhone,
  });

  @override
  State<SideNavigation> createState() => _SideNavigationState();
}

class _SideNavigationState extends State<SideNavigation> {
  bool _setupRequired = false;
  bool _isLoadingSetupStatus = true;

  @override
  void initState() {
    super.initState();
    _checkSetupStatus();
  }

  Future<void> _checkSetupStatus() async {
    // Only check for admin users
    if (widget.userRole != 'admin') {
      setState(() {
        _isLoadingSetupStatus = false;
      });
      return;
    }

    try {
      final setupStatus = await ScheduleSetupGuard.checkScheduleSetupStatus();
      if (mounted) {
        setState(() {
          _setupRequired = setupStatus.needsSetup;
          _isLoadingSetupStatus = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _setupRequired = false;
          _isLoadingSetupStatus = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: Offset(2, 0), // Shadow to the right
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        children: [
          _buildLogo(context),
          Divider(height: 1, color: AppColors.textSecondary.withOpacity(0.2)),
          SizedBox(height: 24),
          _buildNavItems(),
          if (_setupRequired && widget.userRole == 'admin') _buildSetupWarning(),
          Divider(height: 1, color: AppColors.textSecondary.withOpacity(0.2)),
          _buildEmergencyContact(),
        ],
      ),
    );
  }

  Widget _buildLogo(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          // Navigate to role-specific dashboard
          if (widget.userRole == 'super_admin') {
            GoRouter.of(context).go('/super-admin/system-analytics');
          } else {
            GoRouter.of(context).go('/admin/dashboard');
          }
        },
        child: Container(
          padding: EdgeInsets.fromLTRB(32, 24, 24, 16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Image.asset(
                  'assets/img/logo.png',
                  width: 60,
                  height: 60,
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'PawSense',
                style: TextStyle(
                  fontSize: kFontSizeLarge,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItems() {
    // Get role-based routes from router configuration
    final routes = AppRouter.getRoutesForRole(widget.userRole);

    return Expanded(
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemCount: routes.length,
        itemBuilder: (context, index) {
          final route = routes[index];
          final isDisabled = _setupRequired && 
                           widget.userRole == 'admin' && 
                           route.path != '/admin/dashboard' &&
                           route.path != '/admin/clinic-schedule' &&
                           route.path != '/admin/vet-profile';
          
          return NavItem(
            icon: route.icon,
            title: route.title,
            isActive: widget.selectedIndex == index,
            isDisabled: isDisabled,
            onTap: isDisabled ? null : () => widget.onItemSelected(index),
          );
        },
      ),
    );
  }

  Widget _buildSetupWarning() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber, color: AppColors.warning, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Complete clinic setup to access all features',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContact() {
    // Show different content based on role
    if (widget.userRole == 'super_admin') {
      return _buildSuperAdminInfo();
    } else {
      return _buildAdminContactInfo();
    }
  }

  Widget _buildSuperAdminInfo() {
    return Container(
      padding: EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'System Information',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.admin_panel_settings, size: 16, color: AppColors.textSecondary),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Super Administrator',
                  style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.security, size: 16, color: AppColors.textSecondary),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Full System Access',
                  style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdminContactInfo() {
    return Container(
      padding: EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Admin Contact',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 8),
          if (widget.adminName != null && widget.adminName!.isNotEmpty)
            SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.person, size: 16, color: AppColors.textSecondary),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.adminName!,
                  style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
          if (widget.adminPhone != null && widget.adminPhone!.isNotEmpty) ...[
            SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.phone, size: 16, color: AppColors.textSecondary),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.adminPhone!,
                    style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
          ],
          if (widget.adminEmail != null && widget.adminEmail!.isNotEmpty) ...[
            SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.email, size: 16, color: AppColors.textSecondary),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.adminEmail!,
                    style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
